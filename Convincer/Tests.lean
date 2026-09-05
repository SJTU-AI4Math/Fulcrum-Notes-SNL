import Convincer

namespace Convincer.Tests

def firstSource : Evidence := ⟨"first", "First unformalized step", "notes:first"⟩
def secondSource : Evidence := ⟨"second", "Second independent step", "notes:second"⟩

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

example : combined.evidenceLeaves = [firstSource, secondSource] := rfl
example : pureTrue.evidenceLeaves = [] := rfl
example : fakeFalse.checked? = none := rfl
example : (pureTrue.checked?).isSome = true := rfl
example : fakeFalse.Valid ↔ False := ⟨fakeFalse.sound, False.elim⟩

-- Provenance is data, not proof-irrelevant. Same proposition, different sources.
example : (Convincing.evidence (p := False) firstSource) ≠
    Convincing.evidence (p := False) secondSource := by
  intro h
  have h' := congrArg Convincing.evidenceLeaves h
  exact (by decide : firstSource.id ≠ secondSource.id)
    (congrArg Evidence.id (List.cons.inj h').1)

convince duplicate : False := by
  have h₁ ← fakeFalse
  have _h₂ ← fakeFalse
  exact h₁
example : duplicate.evidenceLeaves = [firstSource, firstSource] := rfl

convince unused : True := by
  have _h ← fakeFalse
  trivial
example : unused.evidenceLeaves = [firstSource] := rfl
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
example : nested.evidenceLeaves = [firstSource] := rfl

convince parameterized (n : Nat) : n = n := by
  have _h ← fakeFalse
  simp
example : (parameterized 7).evidenceLeaves = [firstSource] := rfl

convince quantified : ∀ n : Nat, n = n := by
  intro n
  have _h ← fakeFalse
  rfl
example : quantified.evidenceLeaves = [firstSource] := rfl

convince caseSplit : ∀ b : Bool, b = b := by
  intro b
  cases b
  · have _h ← fakeFalse
    rfl
  · rfl
example : caseSplit.evidenceLeaves = [firstSource] := rfl

-- Ordinary strict helpers and rewriting still work inside a Convincer body.
convince arithmetic (n : Nat) : 0 + n = n := by
  have hn : 0 + n = n := by simp
  rw [hn]

-- Arguments can also be composed without any metaprogramming.
def direct := Convincing.both fakeFalse pureTrue
example : direct.evidenceLeaves = [firstSource] := rfl
example (h : direct.Valid) : False ∧ True := direct.sound h

-- `do` is usable in an ordinary monad returning argument *handles*. There is
-- deliberately no operation that binds a Convincing P as an actual proof P.
def handles : Id (Convincing (False ∧ True)) := do
  let a := fakeFalse
  let b := pureTrue
  return a.both b
example : handles.evidenceLeaves = [firstSource] := rfl


-- Context rewriting must not turn the effect journal into an uninspectable
-- delayed metavariable application (regression: `subst` between two effects).
convince afterSubst (a b : Nat) (_he : a = b) : True := by
  evidence h : True := firstSource
  subst a
  evidence ht : True := secondSource
  exact ht
example : (afterSubst 0 0 rfl).evidenceLeaves = [firstSource, secondSource] := rfl

convince afterClear : True := by
  evidence h : True := firstSource
  clear h
  evidence ht : True := secondSource
  exact ht
example : afterClear.evidenceLeaves = [firstSource, secondSource] := rfl

convince allBranches : True ∧ True := by
  constructor
  all_goals evidence firstSource
example : allBranches.evidenceLeaves = [firstSource, firstSource] := rfl

convince simplifyContext (P : Prop) : P := by
  evidence h : P := firstSource
  simp_all only
example : (simplifyContext True).evidenceLeaves = [firstSource] := rfl

#evidence combined
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
  evidence { id := "obvious", explanation := "Obvious", source := "author's assertion" }

convince chained_argument : False ∧ True := by
  have h ← fake_false
  evidence ht : True := {
    id := "second-source"
    explanation := "A second, independently recorded justification"
    source := "notes:second"
  }
  constructor
  · exact h
  · exact ht

#check trivial_true
#check refl_nat
#check implicit_id
#check fake_false
#evidence chained_argument
#print axioms chained_argument
