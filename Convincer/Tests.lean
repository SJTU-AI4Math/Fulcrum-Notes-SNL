import Convincer

namespace Convincer.Tests

def firstSource : String := "first"
def secondSource : Nat := 37

convince pureTrue : True := by
  exact True.intro

convince fakeFalse : False := by
  evidence firstSource

convince reuseFalse : False := by
  have h ← fakeFalse
  exact h

convince combined : False ∧ True := by
  have h ← fakeFalse
  evidence ht : True := secondSource
  constructor
  · exact h
  · exact ht

example : combined.evidenceLeaves = [Evidence.of firstSource, Evidence.of secondSource] := rfl
example : pureTrue.evidenceLeaves = [] := rfl
example : fakeFalse.checked? = none := rfl
example : (pureTrue.checked?).isSome = true := rfl
example : fakeFalse.Valid ↔ False := ⟨fakeFalse.sound, False.elim⟩

-- Provenance is data, not proof-irrelevant. Same proposition, different sources.
example : (Convincing.evidence (p := False) (Evidence.of true)) ≠
    Convincing.evidence (p := False) (Evidence.of false) := by
  intro h
  cases h

convince duplicate : False := by
  have h₁ ← fakeFalse
  have _h₂ ← fakeFalse
  exact h₁
example : duplicate.evidenceLeaves = [Evidence.of firstSource, Evidence.of firstSource] := rfl

convince unused : True := by
  have _h ← fakeFalse
  trivial
example : unused.evidenceLeaves = [Evidence.of firstSource] := rfl
example : unused.checked? = none := rfl

convince rollback : True := by
  first
  | evidence discarded : False := firstSource
    fail "roll back this branch"
  | exact True.intro
example : rollback.evidenceLeaves = [] := rfl

convince nested : False ∧ True := by
  constructor
  · have h ← fakeFalse
    exact h
  · exact True.intro
example : nested.evidenceLeaves = [Evidence.of firstSource] := rfl

convince parameterized (n : Nat) : n = n := by
  have _h ← fakeFalse
  simp
example : (parameterized 7).evidenceLeaves = [Evidence.of firstSource] := rfl

convince quantified : ∀ n : Nat, n = n := by
  intro n
  have _h ← fakeFalse
  rfl
example : quantified.evidenceLeaves = [Evidence.of firstSource] := rfl

convince caseSplit : ∀ b : Bool, b = b := by
  intro b
  cases b
  · have _h ← fakeFalse
    rfl
  · rfl
example : caseSplit.evidenceLeaves = [Evidence.of firstSource] := rfl

-- Ordinary strict helpers and rewriting still work inside a Convincer body.
convince arithmetic (n : Nat) : 0 + n = n := by
  have hn : 0 + n = n := by simp
  rw [hn]

-- Arguments can also be composed without any metaprogramming.
def direct := Convincing.both fakeFalse pureTrue
example : direct.evidenceLeaves = [Evidence.of firstSource] := rfl
example (h : direct.Valid) : False ∧ True := direct.sound h

-- `do` is usable in an ordinary monad returning argument *handles*. There is
-- deliberately no operation that binds a Convincing P as an actual proof P.
def handles : Id (Convincing (False ∧ True)) := do
  let a := fakeFalse
  let b := pureTrue
  return a.both b
example : handles.evidenceLeaves = [Evidence.of firstSource] := rfl


-- Context rewriting must not turn the effect journal into an uninspectable
-- delayed metavariable application (regression: `subst` between two effects).
convince afterSubst (a b : Nat) (_he : a = b) : True := by
  evidence h : True := firstSource
  subst a
  evidence ht : True := secondSource
  exact ht
example : (afterSubst 0 0 rfl).evidenceLeaves = [Evidence.of firstSource, Evidence.of secondSource] := rfl

convince afterClear : True := by
  evidence h : True := firstSource
  clear h
  evidence ht : True := secondSource
  exact ht
example : afterClear.evidenceLeaves = [Evidence.of firstSource, Evidence.of secondSource] := rfl

convince allBranches : True ∧ True := by
  constructor
  all_goals evidence firstSource
example : allBranches.evidenceLeaves = [Evidence.of firstSource, Evidence.of firstSource] := rfl

convince simplifyContext (P : Prop) : P := by
  evidence h : P := firstSource
  simp_all only
example : (simplifyContext True).evidenceLeaves = [Evidence.of firstSource] := rfl

/--
info: └─ combined : False ∧ True
   ├─ fakeFalse : False
   │  └─ False ← firstSource
   └─ True ← secondSource
-/
#guard_msgs in
#evidence combined

/-- info: 无显式 Evidence。 -/
#guard_msgs in
#evidence pureTrue
#print axioms combined
#print axioms Convincing.sound

end Convincer.Tests



/-! The original experiment, now using the checked public Convincer interface. -/

convince trivial_true : True := by
  exact trivial

convince refl_nat (n : Nat) : n = n := by
  rfl

convince implicit_id {α : Type} (x : α) : x = x := by
  rfl

private convince fake_false : False := by
  evidence "Obvious"

convince chained_argument : False ∧ True := by
  have h ← fake_false
  evidence ht : True := [1, 2, 3]
  constructor
  · exact h
  · exact ht

#check trivial_true
#check refl_nat
#check implicit_id
#check fake_false
#evidence chained_argument
#print axioms chained_argument


namespace Convincer.Compatibility

universe v

-- Arbitrary Sort-valued payloads: no Repr, metadata fields or schema required.
def arbitrary {α : Sort v} (value : α) : Convincing False := convincing% by
  evidence value

example {α : Sort v} (value : α) :
    (arbitrary value).evidenceLeaves = [Evidence.of value] := rfl

convince functionPayload : False := by
  evidence (fun n : Nat => n + 1)

convince typePayload : False := by
  evidence Nat

convince tuplePayload : False := by
  evidence ("measurement", [1, 2, 3], true)

#evidence functionPayload
#evidence typePayload
#evidence tuplePayload
#evidence (arbitrary True.intro)

-- One tactic script, executed by both ordinary Lean and Convincer.
macro "sharedArgument" : tactic => `(tactic|
  first
  | fail "try the next branch"
  | evidence h : False := "Obvious"
    exact h)

theorem ordinary : False := by sharedArgument
convince captured : False := by sharedArgument

#evidence captured
#print axioms ordinary
#print axioms captured

-- Citing a Convincing handle is also sorry-like in ordinary tactic proofs.
theorem ordinaryCitation : False := by
  have h ← captured
  exact h
#print axioms ordinaryCitation

-- Outside Convincer, evidence can admit a data goal, just like native sorry.
def ordinaryData : Nat := by
  evidence "temporary witness"
#print axioms ordinaryData

theorem ordinaryDependent : ∀ n : Nat, n = 0 := by
  intro n
  evidence n
#print axioms ordinaryDependent

-- Native sorry remains native, including through referenced declarations.
convince unfinished : False := by
  sorry
convince indirect : False := by
  have h ← unfinished
  exact h
convince directSorry : False := Convincing.proof (by sorry)
/-- info: 无显式 Evidence。 -/
#guard_msgs in
#evidence unfinished
/-- info: 无显式 Evidence。 -/
#guard_msgs in
#evidence indirect
/-- info: 无显式 Evidence。 -/
#guard_msgs in
#evidence directSorry
#print axioms unfinished
#print axioms indirect

-- Ordinary proof tactics still elaborate the proposition goal.
convince inductionProof (n : Nat) : n = n := by
  induction n with
  | zero => rfl
  | succ n ih => exact congrArg Nat.succ ih

convince classicalProof (P : Prop) : P ∨ ¬P := by
  classical
  by_cases h : P
  · exact Or.inl h
  · exact Or.inr h

convince nestedCapture : False := by
  have h ← (show Convincing False from convincing% by evidence "nested")
  exact h

#evidence nestedCapture
#evidence (inductionProof 4)

-- Clearing every clearable local must not turn captured evidence into sorry.
open Lean Elab Tactic in
convince clearedContext : False := by
  have unused : True := True.intro
  run_tac
    let mut goal ← getMainGoal
    for decl in (← getLCtx) do
      goal ← goal.tryClear decl.fvarId
    replaceMainGoal [goal]
  evidence "still captured"

example : clearedContext.evidenceLeaves = [Evidence.of "still captured"] := rfl
#print axioms clearedContext

end Convincer.Compatibility
