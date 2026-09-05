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


#evidence combined
#print axioms combined
#print axioms Convincing.sound

end Convincer.Tests
