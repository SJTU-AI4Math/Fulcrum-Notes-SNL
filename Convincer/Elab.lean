import Lean
import Convincer.Core

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
  rejectSorry e
  let lines ← report e
  let axioms ← argumentAxioms e
  logInfo (String.intercalate "\n" (lines.toList ++ [s!"axioms: {axioms}"]))

end Convincer
