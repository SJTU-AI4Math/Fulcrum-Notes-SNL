import Lean

/-!
# Convincer: explicit evidence and kernel-checked conditional inference

`Convincing p` is data, never a proof of `p`. No interpreter may turn an
unverified evidence leaf into a Lean proof. The applicative spine stores *both*
inputs of every inference, so its provenance is inspectable without supplying
any unproved proposition to a continuation.
-/
namespace Convincer

/-- Authored justification, not a kernel certificate or authenticated identity. -/
structure Evidence where
  id : String
  explanation : String
  source : String := ""
  deriving Repr, BEq

/-- Intensional, proof-relevant arguments about propositions. -/
inductive Convincing : Prop → Type 1 where
  | proof {p : Prop} (term : p) : Convincing p
  | evidence {p : Prop} (source : Evidence) : Convincing p
  | mp {p q : Prop} (rule : Convincing (p → q)) (premise : Convincing p) : Convincing q
  | named {p : Prop} (name : String) (argument : Convincing p) : Convincing p

namespace Convincing

/-- Apply a genuine Lean implication without erasing its argument's evidence. -/
def map {p q : Prop} (f : p → q) (argument : Convincing p) : Convincing q :=
  .mp (.proof f) argument

/-- Combine independent arguments, preserving their complete ordered provenance. -/
def both {p q : Prop} (left : Convincing p) (right : Convincing q) : Convincing (p ∧ q) :=
  .mp (left.map And.intro) right

/-- All evidence occurrences, including duplicates and explicitly unused citations. -/
def evidenceLeaves {p : Prop} : Convincing p → List Evidence
  | .proof _ => []
  | .evidence e => [e]
  | .mp f x => f.evidenceLeaves ++ x.evidenceLeaves
  | .named _ x => x.evidenceLeaves

/-- What must additionally be true for this argument to establish its conclusion. -/
def Valid {p : Prop} : Convincing p → Prop
  | .proof _ => True
  | .evidence (_ : Evidence) => p
  | .mp f x => f.Valid ∧ x.Valid
  | .named _ x => x.Valid

/-- Conditional soundness. This does not assert that any Evidence is valid. -/
theorem sound {p : Prop} (argument : Convincing p) : argument.Valid → p := by
  induction argument with
  | proof h => exact fun _ => h
  | evidence _ => exact id
  | mp _ _ ihf ihx => exact fun h => ihf h.1 (ihx h.2)
  | named _ _ ih => exact ih

/-- Proof-only extraction is explicit and fails if *any* evidence leaf occurs. -/
def checked? {p : Prop} : Convincing p → Option (PLift p)
  | .proof h => some ⟨h⟩
  | .evidence _ => none
  | .mp f x => do
    let hf ← f.checked?
    let hx ← x.checked?
    return ⟨hf.down hx.down⟩
  | .named _ x => x.checked?

end Convincing
end Convincer

export Convincer (Evidence Convincing)

-- Exporting a type name alone does not export its qualified constructor names.
namespace Convincing
export Convincer.Convincing (proof evidence mp named map both evidenceLeaves Valid sound checked?)
end Convincing

namespace Evidence
export Convincer.Evidence (mk id explanation source)
end Evidence



open Lean Meta Elab Term Tactic Command

namespace Convincer

/-- Elaboration-only journal. Its metavariable tail participates in tactic rollback. -/
private inductive Pending where
  | nil
  | cons {p : Prop} (source : Convincing p) (hole : p) (tail : Pending)

-- Store only the key in the local context. Putting Pending itself there lets
-- `subst` abstract its unresolved holes into delayed metavariable applications.
private structure Journal where
  key : Name

private def journal : TacticM (LocalDecl × Expr) := do
  for decl in (← getLCtx).decls.toArray.reverse do
    if let some decl := decl then
      if decl.type.isConstOf ``Journal then
        if let some value := decl.value? then
          let key : Name ← reduceEval (← mkAppM ``Journal.key #[value])
          return (decl, mkMVar ⟨key⟩)
  throwError "Convincer effects are only available inside `convincing% by` or `convince ... := by`."

private partial def journalTail (e : Expr) : MetaM Expr := do
  let e ← instantiateMVars e
  if e.isMVar then return e
  if e.isAppOfArity ``Pending.cons 4 then
    journalTail e.getAppArgs[3]!
  else throwError "Convincer: invalid elaboration journal"

/-- Evidence inputs are static: no dependence on a local unproved witness or branch. -/
private def staticInput (scope : LocalDecl) (e : Expr) : TacticM Expr := do
  let lets := (← getLCtx).foldl (init := #[]) fun acc d =>
    if d.index ≥ scope.index && d.isLet then acc.push d.fvarId else acc
  let e ← instantiateMVars (← zetaDeltaFVars e lets)
  if e.hasExprMVar then
    throwError "Convincer evidence must not depend on an unproved hypothesis or unresolved metavariable. Cite a closed implication instead."
  for id in (collectFVars {} e).fvarIds do
    if (← id.getDecl).index ≥ scope.index then
      throwError "Convincer evidence must be independent of tactic-local binders. Move the parameter to the declaration or cite a closed implication."
  return e

private def record (source : Expr) : TacticM Expr := do
  let (scope, head) ← journal
  let source ← staticInput scope source
  let ty ← whnf (← inferType source)
  unless ty.isAppOfArity ``Convincing 1 do
    throwError "Expected a `Convincing p` argument, got {ty}"
  let p ← staticInput scope ty.getAppArgs[0]!
  -- Context-rewriting tactics may instantiate the journal head to a cons.
  -- Its open tail is the stable metavariable, not the head expression.
  let tailGoal ← journalTail head
  let (hole, tail) ← tailGoal.mvarId!.withContext do
    let hole ← mkFreshExprMVar p .syntheticOpaque
    let tail ← mkFreshExprMVar (mkConst ``Pending) .syntheticOpaque
    return (hole, tail)
  tailGoal.mvarId!.assign (← mkAppM ``Pending.cons #[source, hole, tail])
  return hole

/-- Cite an existing argument as a temporary hypothesis in the rigid proof. -/
elab "have " name:ident " ← " source:term : tactic => withMainContext do
  let source ← Term.elabTerm source none
  synthesizeSyntheticMVarsNoPostponing
  let hole ← record (← instantiateMVars source)
  let goal ← getMainGoal
  let (_, next) ← goal.note name.getId hole
  replaceMainGoal [next]

/-- Create and cite an authored evidence leaf. -/
macro "evidence " name:ident " : " p:term " := " e:term : tactic =>
  `(tactic| have $name ← (Convincing.evidence (p := $p) $e))

/-- Close the current proposition using explicit evidence, not a fabricated proof. -/
elab "evidence " e:term : tactic => withMainContext do
  let p ← getMainTarget
  let e ← Term.elabTermEnsuringType e (mkConst ``Evidence)
  synthesizeSyntheticMVarsNoPostponing
  let hole ← record (mkApp2 (mkConst ``Convincing.evidence) p e)
  (← getMainGoal).assign hole
  replaceMainGoal []

private partial def readJournal (head : Expr) : MetaM (Array (Expr × Expr)) := do
  let head ← instantiateMVars head
  if head.isMVar then
    head.mvarId!.assign (mkConst ``Pending.nil)
    return #[]
  if head.isAppOfArity ``Pending.cons 4 then
    let args := head.getAppArgs
    return #[(args[1]!, args[2]!)] ++ (← readJournal args[3]!)
  throwError "Convincer: invalid elaboration journal"

private def argumentAxioms (e : Expr) : MetaM (Array Name) := do
  let mut result := #[]
  for name in e.getUsedConstants do
    for axiomName in (← collectAxioms name) do
      if !result.contains axiomName then result := result.push axiomName
  return result

private def rejectSorry (e : Expr) : MetaM Unit := do
  if (← argumentAxioms e).contains ``sorryAx then
    throwError "Convincer rejects sorryAx; record an explicit Evidence instead."

/-- Run ordinary Lean tactics on `p`, then discharge every effect hypothesis. -/
elab "convincing% " "by " seq:tacticSeq : term <= expectedType? => do
  let expected ← whnf expectedType?
  unless expected.isAppOfArity ``Convincing 1 do
    throwError "Expected type must be `Convincing p`"
  let p := expected.getAppArgs[0]!
  let head ← mkFreshExprMVar (mkConst ``Pending) .syntheticOpaque
  let token := mkApp (mkConst ``Journal.mk) (toExpr head.mvarId!.name)
  let (proof, entries) ← withLetDecl `_convincerJournal (mkConst ``Journal) token (kind := .implDetail) fun _ => do
    let goal ← mkFreshExprMVar p .syntheticOpaque
    let remaining ← Tactic.run goal.mvarId! do
      withoutRecover <| evalTactic seq
    unless remaining.isEmpty do
      throwError "Convincer rigid proof has unsolved goals:{remaining}"
    synthesizeSyntheticMVarsNoPostponing
    let entries ← readJournal head
    let proof ← instantiateMVars goal
    return (proof, entries)
  let binders ← entries.mapM fun (_, hole) => return (`assumption, ← inferType hole)
  withLocalDeclsDND binders fun vars => do
    -- Delayed assignments introduced by `intro`/`have` only unfold after their
    -- proof holes have values. These private holes become bound assumptions;
    -- they never become declarations or escape the final checked lambda.
    for (_, hole) in entries, hypothesis in vars do
      hole.mvarId!.assign hypothesis
    let proof ← instantiateMVars proof
    let rule ← mkLambdaFVars vars proof
    if rule.hasExprMVar then
      throwError "Convincer: unresolved metavariable in conditional proof"
    let mut result ← mkAppM ``Convincing.proof #[rule]
    for (source, _) in entries do
      result ← mkAppM ``Convincing.mp #[result, source]
    discard <| check result
    rejectSorry result
    return result

/-- Validate a direct argument body just as strictly as the tactic form. -/
elab "convincing_term% " body:term : term <= expected => do
  let e ← Term.elabTermEnsuringType body expected
  synthesizeSyntheticMVarsNoPostponing
  let e ← instantiateMVars e
  rejectSorry e
  return e

/-- A declaration is data even when its displayed target is a proposition. -/
syntax (name := convinceDecl) declModifiers "convince " declId (ppSpace bracketedBinder)*
  " : " term " := " term : command
macro_rules
  | `($mods:declModifiers convince $id:declId $[$bs:bracketedBinder]* : $p := by $seq:tacticSeq) => do
    let label := Syntax.mkStrLit id.raw[0].getId.toString
    `($mods:declModifiers def $id $[$bs]* : Convincing $p :=
      Convincing.named $label (convincing% by $seq))
  | `($mods:declModifiers convince $id:declId $[$bs:bracketedBinder]* : $p := $body) => do
    let label := Syntax.mkStrLit id.raw[0].getId.toString
    `($mods:declModifiers def $id $[$bs]* : Convincing $p :=
      Convincing.named $label (convincing_term% $body))

private def stringField (name : Name) (e : Expr) : MetaM String := do
  let value ← whnf (← mkAppM name #[e])
  return (getStringValue? value).getD (toString (← ppExpr value))

private partial def report (e : Expr) (indent : String := "") : MetaM (Array String) := do
  withIncRecDepth do
    let ty ← whnf (← inferType e)
    unless ty.isAppOfArity ``Convincing 1 do throwError "Expected `Convincing p`"
    let p ← ppExpr ty.getAppArgs[0]!
    let e ← withTransparency .all <| whnf e
    let args := e.getAppArgs
    if e.isAppOfArity ``Convincing.proof 2 then
      return #[s!"{indent}rigid : {p}"]
    if e.isAppOfArity ``Convincing.evidence 2 then
      let source := args[1]!
      let id ← stringField ``Evidence.id source
      let text ← stringField ``Evidence.explanation source
      let origin ← stringField ``Evidence.source source
      return #[s!"{indent}evidence [{id}] : {p}", s!"{indent}  {text}", s!"{indent}  source: {origin}"]
    if e.isAppOfArity ``Convincing.named 3 then
      let label := (getStringValue? args[1]!).getD (toString (← ppExpr args[1]!))
      return #[s!"{indent}{label} : {p}"] ++ (← report args[2]! (indent ++ "  "))
    if e.isAppOfArity ``Convincing.mp 4 then
      return #[s!"{indent}infer : {p}"] ++ (← report args[2]! (indent ++ "  ")) ++
        (← report args[3]! (indent ++ "  "))
    throwError "Convincer cannot inspect this argument (opaque, symbolic, or unsupported computation): {e}"

/-- Kernel-reduced structural provenance; unknown/opaque branches fail explicitly. -/
elab "#evidence " term:term : command => runTermElabM fun _ => do
  let e ← elabTerm term none
  synthesizeSyntheticMVarsNoPostponing
  let e ← instantiateMVars e
  if e.hasExprMVar then throwError "Instantiate all argument parameters before querying evidence"
  if e.hasFVar || (← inferType e).hasFVar then
    throwError "Convincer queries require a closed argument: instantiate all parameters and discharge local assumptions."
  rejectSorry e
  let lines ← report e
  let axioms ← argumentAxioms e
  logInfo (String.intercalate "\n" (lines.toList ++ [s!"axioms: {axioms}"]))

end Convincer
