import Lean

/-!
# Convincer: explicit evidence and kernel-checked conditional inference

`Convincing p` is data, never a proof of `p`. No interpreter may turn an
unverified evidence leaf into a Lean proof. The applicative spine stores *both*
inputs of every inference, so its provenance is inspectable without supplying
any unproved proposition to a continuation.
-/
universe u

namespace Convincer

/-- An arbitrary typed payload, not a certificate of the claimed proposition. -/
inductive Evidence : Type (u + 1) where
  | of {α : Sort u} (value : α)

/-- Intensional, proof-relevant arguments about propositions. -/
inductive Convincing : Prop → Type (u + 1) where
  | proof {p : Prop} (term : p) : Convincing p
  | evidence {p : Prop} (source : Evidence.{u}) : Convincing p
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

/-- Return an existing Lean proof only when no explicit evidence occurs.
The returned proof may still depend on native sorry or other axioms. -/
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
export Convincer.Evidence (of)
end Evidence



open Lean Meta Elab Term Tactic Command

namespace Convincer

/-- Elaboration-only journal. Its metavariable tail participates in tactic rollback. -/
private inductive Pending : Type (u + 1) where
  | nil
  | cons {p : Prop} (source : Convincing.{u} p) (hole : p) (tail : Pending)

-- The active journal key is dynamically scoped, not a hypothesis. Clearing or
-- rewriting local declarations must never silently switch capture to sorry.
private def journal? : TacticM (Option (LocalContext × Expr)) := do
  let key := (← getOptions).get `convincer.journal Name.anonymous
  if key.isAnonymous then return none
  let head := mkMVar ⟨key⟩
  return some ((← head.mvarId!.getDecl).lctx, head)

private partial def journalTail (e : Expr) : MetaM Expr := do
  let e ← instantiateMVars e
  if e.isMVar then return e
  if e.isAppOfArity ``Pending.cons 4 then
    journalTail e.getAppArgs[3]!
  else throwError "Convincer: invalid elaboration journal"

/-- Evidence inputs are static: no dependence on a local unproved witness or branch. -/
private def staticInput (scope : LocalContext) (e : Expr) : TacticM Expr := do
  let lets := (← getLCtx).foldl (init := #[]) fun acc d =>
    if !scope.contains d.fvarId && d.isLet then acc.push d.fvarId else acc
  let e ← instantiateMVars (← zetaDeltaFVars e lets)
  if e.hasExprMVar then
    throwError "Convincer evidence must not depend on an unproved hypothesis or unresolved metavariable. Cite a closed implication instead."
  for id in (collectFVars {} e).fvarIds do
    if !scope.contains id then
      throwError "Convincer evidence must be independent of tactic-local binders. Move the parameter to the declaration or cite a closed implication."
  return e

private def record (source : Expr) : TacticM Expr := do
  let ty ← whnf (← inferType source)
  unless ty.isAppOfArity ``Convincing 1 do
    throwError "Expected a `Convincing p` argument, got {ty}"
  let some (scope, head) ← journal?
    | return ← mkLabeledSorry ty.getAppArgs[0]! (synthetic := false) (unique := true)
  let source ← staticInput scope source
  let p ← staticInput scope ty.getAppArgs[0]!
  let levels := (← inferType head).constLevels!
  unless ← isDefEq ty (mkApp (mkConst ``Convincing levels) p) do
    throwError "Evidence sources must share a compatible Lean universe"
  -- Context-rewriting tactics may instantiate the journal head to a cons.
  -- Its open tail is the stable metavariable, not the head expression.
  let tailGoal ← journalTail head
  let (hole, tail) ← tailGoal.mvarId!.withContext do
    let hole ← mkFreshExprMVar p .syntheticOpaque
    let tail ← mkFreshExprMVar (← inferType tailGoal) .syntheticOpaque
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
  `(tactic| have $name ← (Convincing.evidence (p := $p) (Evidence.of $e)))

/-- Capture evidence in Convincer; outside it, admit the goal exactly as `sorry`. -/
elab "evidence " e:term : tactic => withMainContext do
  let p ← getMainTarget
  let value ← Term.elabTerm e none
  synthesizeSyntheticMVarsNoPostponing
  if (← journal?).isNone then
    admitGoal (← getMainGoal) (synthetic := false)
  else
    let packet ← mkAppM ``Evidence.of #[← instantiateMVars value]
    let source ← mkAppOptM ``Convincing.evidence #[some p, some packet]
    let hole ← record source
    (← getMainGoal).assign hole
  replaceMainGoal []

private partial def readJournal (head : Expr) : MetaM (Array (Expr × Expr)) := do
  let head ← instantiateMVars head
  if head.isMVar then
    head.mvarId!.assign (mkConst ``Pending.nil (← inferType head).constLevels!)
    return #[]
  if head.isAppOfArity ``Pending.cons 4 then
    let args := head.getAppArgs
    return #[(args[1]!, args[2]!)] ++ (← readJournal args[3]!)
  throwError "Convincer: invalid elaboration journal"

/-- Run ordinary Lean tactics on `p`, then discharge every effect hypothesis. -/
elab "convincing% " "by " seq:tacticSeq : term <= expectedType? => do
  let expected ← whnf expectedType?
  unless expected.isAppOfArity ``Convincing 1 do
    throwError "Expected type must be `Convincing p`"
  let p := expected.getAppArgs[0]!
  let head ← mkFreshExprMVar (mkConst ``Pending expected.getAppFn.constLevels!) .syntheticOpaque
  let (proof, entries) ← withOptions (fun opts => opts.set `convincer.journal head.mvarId!.name) do
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
    let mut result := mkApp2 (mkConst ``Convincing.proof expected.getAppFn.constLevels!) (← inferType rule) rule
    for (source, _) in entries do
      result ← mkAppM ``Convincing.mp #[result, source]
    discard <| check result
    return result

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
      Convincing.named $label $body)

private inductive ReportTree where
  | node (label : String) (children : Array ReportTree)
  deriving Inhabited

/-- Prune rigid steps, keeping only evidence-bearing named arguments and leaves. -/
private partial def report (e : Expr) : MetaM (Array ReportTree) := do
  withIncRecDepth do
    let ty ← whnf (← inferType e)
    unless ty.isAppOfArity ``Convincing 1 do throwError "Expected `Convincing p`"
    let p ← ppExpr ty.getAppArgs[0]!
    let e ← withTransparency .all <| whnf e
    let args := e.getAppArgs
    if e.isAppOfArity ``Convincing.proof 2 then
      return #[]
    if e.isAppOfArity ``Convincing.evidence 2 then
      let packet ← withTransparency .all <| whnf args[1]!
      unless packet.isAppOfArity ``Evidence.of 2 do
        throwError "Convincer cannot inspect this evidence payload: {packet}"
      let value ← ppExpr packet.getAppArgs[1]!
      return #[.node s!"{p} ← {value}" #[]]
    if e.isAppOfArity ``Convincing.named 3 then
      let children ← report args[2]!
      if children.isEmpty then return #[]
      let label := (getStringValue? args[1]!).getD (toString (← ppExpr args[1]!))
      return #[.node s!"{label} : {p}" children]
    if e.isAppOfArity ``Convincing.mp 4 then
      return (← report args[2]!) ++ (← report args[3]!)
    throwError "Convincer cannot inspect this argument (opaque, symbolic, or unsupported computation): {e}"

private partial def renderForest (trees : Array ReportTree) (indent : String := "") : Array String := Id.run do
  let mut lines := #[]
  for i in [:trees.size] do
    let .node label children := trees[i]!
    let last := i + 1 == trees.size
    lines := lines.push (indent ++ (if last then "└─ " else "├─ ") ++ label)
    lines := lines ++ renderForest children (indent ++ (if last then "   " else "│  "))
  return lines

/-- Only explicit non-rigid evidence is listed. Use `#print axioms` for Lean trust. -/
elab "#evidence " term:term : command => runTermElabM fun _ => do
  let e ← elabTerm term none
  synthesizeSyntheticMVarsNoPostponing
  let e ← instantiateMVars e
  if e.hasExprMVar then throwError "Instantiate all argument parameters before querying evidence"
  if e.hasFVar || (← inferType e).hasFVar then
    throwError "Convincer queries require a closed argument: instantiate all parameters and discharge local assumptions."
  let lines := renderForest (← report e)
  logInfo (if lines.isEmpty then "无显式 Evidence。" else String.intercalate "\n" lines.toList)

end Convincer
