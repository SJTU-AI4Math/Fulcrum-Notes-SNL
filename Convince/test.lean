import Convincer

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
