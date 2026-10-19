import Mathlib.CategoryTheory.Category.Basic
import Mathlib.Logic.Basic
import Mathlib.MeasureTheory.MeasurableSpace.Defs

/-!
# 2A · Curry–Howard Correspondence and Term Proofs (Draft)

We first present each logical operator's introduction and elimination rules as sequents, then give
course-local definitions with correspondingly shaped constructors and eliminators. These rules are
metalevel inference rules rather than extra Lean axioms. Equality is treated separately as an indexed relation in the impredicative
proposition-type chapter, not as a logical operator.
-/


universe u v


-------------------------------------------------------------------------------
/-! ## 1. Implication "→" -/
-------------------------------------------------------------------------------

namespace Course2A

/-! The sequent-style introduction and elimination rules for implication are recorded in SNL. -/
-- Γ, P ⊢ Q / Γ ⊢ P → Q
-- Γ ⊢ P → Q    Γ ⊢ P / Γ ⊢ Q
-- They are metalevel rules, not additional Lean declarations.
--

/-! Implementation through Lean's function type: -/
def Implies (P Q : Prop) : Prop := P → Q
#check Implies
#print Implies

end Course2A
#check (fun P Q : Prop ↦ P → Q)

-------------------------------------------------------------------------------
/-! ## 2. Universal quantification "∀" -/
-------------------------------------------------------------------------------

namespace Course2A

/-! The sequent-style rules for universal quantification are recorded in SNL. -/
-- Γ ⊢ P x / Γ ⊢ ∀ x, P x, with x fresh for Γ
-- Γ ⊢ ∀ x, P x / Γ ⊢ P x
-- They are metalevel rules, not additional Lean declarations.
--

/-! Implementation through Lean's dependent function type: -/
def Forall {α : Sort u} (P : α → Prop) : Prop := ∀ x, P x
#check Forall
#print Forall

end Course2A
section
variable {α : Sort u}
#check (fun P : α → Prop ↦ ∀ x, P x)
end

-------------------------------------------------------------------------------
/-! ## 3. Truth and falsehood -/
-------------------------------------------------------------------------------

namespace Course2A

/-! The sequent-style truth rules are recorded in SNL, not declared as Lean axioms. -/
-- / Γ ⊢ ⊤
-- Γ ⊢ P / Γ ⊢ ⊤
--

inductive True : Prop where
  | intro : True
#check True
#check True.intro
#check True.rec

/-- Every proposition has the unique terminal map into truth. -/
def True.elim {P : Prop} (_ : P) : True := .intro
#check True.elim
#print True
#print True.elim

/-! The sequent-style false-elimination rule Γ ⊢ ⊥ / Γ ⊢ P is recorded in SNL. -/
-- It is a metalevel rule, not an additional Lean axiom.

inductive False : Prop
#check False
#check False.rec

def False.elim {P : Sort u} (h : False) : P := nomatch h
#check False.elim
#print False
#print False.elim

end Course2A

#print True
#check True.intro
#print False
#check False.elim

example : Course2A.True := .intro
example {P : Prop} (h : Course2A.False) : P := Course2A.False.elim h


-------------------------------------------------------------------------------
/-! ## 4. Conjunction "∧" -/
-------------------------------------------------------------------------------

namespace Course2A

/-! The sequent-style introduction and elimination rules for conjunction are recorded in SNL. -/
-- Γ ⊢ P    Γ ⊢ Q / Γ ⊢ P ∧ Q
-- Γ ⊢ P ∧ Q / Γ ⊢ P
-- Γ ⊢ P ∧ Q / Γ ⊢ Q
-- They are metalevel rules, not additional Lean declarations.
--
--

/-! Implementation through inductive types: -/
inductive And (P Q : Prop) : Prop
  | intro : P → Q → And P Q
#check And

#print And
#print And.intro
#print And.rec

/-! Implementation through structure types: -/
structure And_Struct (P Q : Prop) : Prop where
  intro ::  -- rename default constructor name with "intro"
  left : P
  right : Q
#check And_Struct

#print And_Struct
#print And_Struct.intro
#print And_Struct.left
#print And_Struct.right
#print And_Struct.rec

/-! Implementation directly through product types is banned due to Impredicativity of `Prop`: -/
#check Prod  -- `Prop` does not fit pattern `Type u`!
-- def And_Prod (P Q : Prop) : Prop := P × Q

end Course2A

/-! Lean's native conjunction: -/
#print And
#check (· ∧ ·)
#print And.intro
#print And.left
#print And.right

/-! Term proofs for conjunction: -/
example {P Q : Prop} (hP : P) (hQ : Q) : And P Q := And.intro hP hQ
example {P Q : Prop} (hP : P) (hQ : Q) : And P Q := ⟨hP, hQ⟩

example {P Q : Prop} (hPQ : And P Q) : P := And.left hPQ
example {P Q : Prop} (hPQ : And P Q) : P := hPQ.left

example {P Q : Prop} (hPQ : And P Q) : Q := And.right hPQ
example {P Q : Prop} (hPQ : And P Q) : Q := hPQ.right

-------------------------------------------------------------------------------
/-! ## 5. Disjunction "∨" -/
-------------------------------------------------------------------------------

namespace Course2A

/-! The sequent-style introduction and elimination rules for disjunction are recorded in SNL. -/
-- Γ ⊢ P / Γ ⊢ P ∨ Q
-- Γ ⊢ Q / Γ ⊢ P ∨ Q
-- Γ ⊢ P ∨ Q    Γ, P ⊢ R    Γ, Q ⊢ R / Γ ⊢ R
-- They are metalevel rules, not additional Lean declarations.
--
--

inductive Or (P Q : Prop) : Prop where
  | inl : P → Or P Q
  | inr : Q → Or P Q
#check Or
#check Or.inl
#check Or.inr
#check Or.rec

def Or.elim {P Q R : Prop} (h : Or P Q) (hP : P → R) (hQ : Q → R) : R :=
  match h with
  | .inl hp => hP hp
  | .inr hq => hQ hq
#check Or.elim
#print Or
#print Or.elim

end Course2A

#print Or
#check Or.inl
#check Or.inr
#check Or.elim

example {P Q : Prop} (hP : P) : Course2A.Or P Q := .inl hP
example {P Q : Prop} (hQ : Q) : Course2A.Or P Q := .inr hQ
example {P Q R : Prop} (h : Course2A.Or P Q) (hP : P → R) (hQ : Q → R) : R :=
  Course2A.Or.elim h hP hQ

-------------------------------------------------------------------------------
/-! ## 6. Negation "¬" -/
-------------------------------------------------------------------------------

namespace Course2A

/-! The sequent-style introduction and elimination rules for negation are recorded in SNL. -/
-- Γ, P ⊢ ⊥ / Γ ⊢ ¬P
-- Γ ⊢ ¬P    Γ ⊢ P / Γ ⊢ ⊥
-- They are metalevel rules, not additional Lean declarations.
--

/-- Course-local negation uses the course-local false proposition. -/
def Not (P : Prop) : Prop := P → False
#check Not

def Not.elim {P : Prop} (hP : P) (hnP : Not P) : False := hnP hP
#check Not.elim
#print Not
#print Not.elim

end Course2A

#check _root_.Not
#check not_congr

example {P : Prop} (hP : P) (hnP : Course2A.Not P) : Course2A.False := hnP hP


-------------------------------------------------------------------------------
/-! ## 7. Logical equivalence "↔" -/
-------------------------------------------------------------------------------

namespace Course2A

/-!
This structure mirrors native `Iff`. Its fields use Lean's ambient function type; they do not
implement the deferred course-local implication/arrow operator.
-/

/-! The sequent-style introduction and elimination rules for equivalence are recorded in SNL. -/
-- Γ, P ⊢ Q    Γ, Q ⊢ P / Γ ⊢ P ↔ Q
-- Γ ⊢ P ↔ Q / Γ ⊢ P → Q
-- Γ ⊢ P ↔ Q / Γ ⊢ Q → P
-- They are metalevel rules, not additional Lean declarations.
--

structure Iff (P Q : Prop) : Prop where
  intro ::
  mp : P → Q
  mpr : Q → P
#check Iff
#check Iff.intro
#check Iff.mp
#check Iff.mpr
#check Iff.rec
#print Iff

end Course2A

#check _root_.Iff
#check _root_.Iff.intro
#check _root_.Iff.mp
#check _root_.Iff.mpr

example {P Q : Prop} (forward : P → Q) (backward : Q → P) : Course2A.Iff P Q :=
  ⟨forward, backward⟩


-------------------------------------------------------------------------------
/-! ## 8. Existential quantification "∃" -/
-------------------------------------------------------------------------------

namespace Course2A

/-!
The notation `∃ x, P x` is binder syntax, but Lean's underlying `Exists` declaration is an
inductive constant. Its recursor eliminates only into `Prop`, so it cannot generally extract
computational data from a proof.
-/

/-! The sequent-style introduction and elimination rules for existence are recorded in SNL. -/
-- Γ ⊢ P x / Γ ⊢ ∃ x, P x
-- Γ ⊢ ∃ x, P x    Γ, P x ⊢ Q / Γ ⊢ Q, with x fresh for Γ and Q
-- They are metalevel rules, not additional Lean declarations.
--

inductive Exists {α : Sort u} (P : α → Prop) : Prop where
  | intro (witness : α) : P witness → Exists P
#check Exists
#check Exists.intro
#check Exists.rec

def Exists.elim {α : Sort u} {P : α → Prop} {R : Prop}
    (h : Exists P) (next : (witness : α) → P witness → R) : R :=
  match h with
  | .intro witness proof => next witness proof
#check Exists.elim
#print Exists
#print Exists.elim

end Course2A

#check _root_.Exists
#check _root_.Exists.intro
#check _root_.Exists.elim

example : Course2A.Exists (fun n : Nat ↦ n = 2) := .intro 2 rfl
example {α : Sort u} {P : α → Prop} {R : Prop} (h : Course2A.Exists P)
    (next : (x : α) → P x → R) : R := Course2A.Exists.elim h next


-------------------------------------------------------------------------------
/-! ## 9. Impredicative proposition type -/
-------------------------------------------------------------------------------

namespace Course2A

/-!
Lean places `Prop` in `Type 0`, while `Type u` lives in `Type (u + 1)`. Nevertheless,
a dependent product whose codomain is proposition-valued remains in `Prop`, independently of
the universe level of its domain. This is the impredicative Π-formation rule for `Prop`.
-/
#check Prop

/-! Equality is an indexed relation valued in `Prop`, not a logical operator. -/
inductive Eq {α : Sort u} (a : α) : α → Prop where
  | refl : Eq a a
#check Eq
#check Eq.refl
#check Eq.rec
#print Eq

/-- Impredicative Π-formation: a proposition-valued dependent product remains in `Prop`. -/
def ImpredicativePi {α : Sort u} (P : α → Prop) : Prop := ∀ x : α, P x
#check ImpredicativePi

-- `#check Prop` above reports `Prop : Type`, i.e. `Prop : Type 0`.
#check Type u

section
variable {α : Sort u} (P : α → Prop)
#check (∀ x : α, P x)
end

/-! The smallest family containing `s` and closed under the σ-algebra operations. -/
inductive GenerateMeasurable {α : Type u} (s : Set (Set α)) : Set α → Prop
  | protected basic : ∀ u ∈ s, GenerateMeasurable s u
  | protected empty : GenerateMeasurable s ∅
  | protected compl : ∀ t, GenerateMeasurable s t → GenerateMeasurable s tᶜ
  | protected iUnion : ∀ f : ℕ → Set α, (∀ n, GenerateMeasurable s (f n)) → GenerateMeasurable s (⋃ i, f i)
#check GenerateMeasurable

#print GenerateMeasurable

end Course2A

#print MeasurableSpace.GenerateMeasurable

-------------------------------------------------------------------------------
/-! ## 10. Nonconstructive logic from Lean's standard library -/
-------------------------------------------------------------------------------

#check propext
#check Classical.choice
#check Classical.em
#check Classical.byContradiction

-------------------------------------------------------------------------------
/-! ## Practice: Term proofs in Lean 4 -/
-------------------------------------------------------------------------------

/-!
Replace each `sorry` below with a proof term. Do not use `by` blocks or tactics.

Exercises 1–15 review the introduction and elimination terms presented in this chapter. Exercises
16–20 combine quantifiers, predicates, relations, equality, and function extensionality into more
substantial higher-order logic propositions.
-/

/-!
The exercises use a sibling namespace so that unqualified names such as `And.intro`, `Or.elim`,
and `Exists.elim` resolve to Lean's native propositions rather than the course-local replicas.
-/
namespace Course2AExercises

---------------------------------------
/-! ### 1. Construct the identity proof. -/

theorem A1 (P : Prop) : P → P := sorry

---------------------------------------
/-! ### 2. Construct the constant proof. -/

theorem A2 (P Q : Prop) : P → Q → P := sorry

---------------------------------------
/-! ### 3. Compose two implications. -/

theorem A3 (P Q R : Prop) : (P → Q) → (Q → R) → P → R := sorry

---------------------------------------
/-! ### 4. Construct the simply typed `S` combinator. -/

theorem A4 (P Q R : Prop) : (P → Q → R) → (P → Q) → P → R := sorry

---------------------------------------
/-! ### 5. Exchange the two components of a conjunction. -/

theorem A5 (P Q : Prop) : P ∧ Q → Q ∧ P := sorry

---------------------------------------
/-! ### 6. Curry a proof that consumes a conjunction. -/

theorem A6 (P Q R : Prop) : (P ∧ Q → R) → P → Q → R := sorry

---------------------------------------
/-! ### 7. Uncurry a proof with two hypotheses. -/

theorem A7 (P Q R : Prop) : (P → Q → R) → P ∧ Q → R := sorry

---------------------------------------
/-! ### 8. Construct a logical equivalence from its two directions. -/

theorem A8 (P Q : Prop) : (P → Q) → (Q → P) → (P ↔ Q) := sorry

---------------------------------------
/-! ### 9. Eliminate a disjunction by proving the same conclusion in both cases. -/

theorem A9 (P Q R : Prop) : (P → R) → (Q → R) → P ∨ Q → R := sorry

---------------------------------------
/-! ### 10. Refute a disjunction from refutations of both alternatives. -/

theorem A10 (P Q : Prop) : (P → False) → (Q → False) → ¬(P ∨ Q) := sorry

---------------------------------------
/-! ### 11. Map a predicate implication over an existential witness. -/

theorem A11 {α : Type u} (P Q : α → Prop) :
    ((x : α) → P x → Q x) → (∃ x, P x) → ∃ x, Q x := sorry

---------------------------------------
/-! ### 12. Show that applying a function preserves equality. -/

theorem A12 {α : Type u} {β : Type v} (f : α → β) {x y : α} :
    x = y → f x = f y := sorry

---------------------------------------
/-! ### 13. Transport a predicate along an equality. -/

theorem A13 {α : Type u} (P : α → Prop) {x y : α} :
    x = y → P x → P y := sorry

---------------------------------------
/-! ### 14. Reverse a logical equivalence. -/

theorem A14 (P Q : Prop) : (P ↔ Q) → (Q ↔ P) := sorry

---------------------------------------
/-! ### 15. Distribute conjunction over disjunction in the forward direction. -/

theorem A15 (P Q R : Prop) : P ∧ (Q ∨ R) → (P ∧ Q) ∨ (P ∧ R) := sorry

---------------------------------------
/-! ### 16. Distribute universal quantification over conjunction. -/

theorem A16 {α : Type u} (P Q : α → Prop) :
    ((x : α) → P x ∧ Q x) ↔ (((x : α) → P x) ∧ ((x : α) → Q x)) := sorry

---------------------------------------
/-! ### 17. Preserve an original witness while constructing a dependent witness. -/

theorem A17 {α : Type u} {β : Type v} (P : α → Prop) (R : α → β → Prop) :
    ((x : α) → P x → ∃ y, R x y) →
    (∃ x, P x) →
    ∃ x, ∃ y, P x ∧ R x y := sorry

---------------------------------------
/-! ### 18. Reassociate two relational compositions. -/

theorem A18 {α : Type u} {β : Type v} {γ δ : Type}
    (R : α → β → Prop) (S : β → γ → Prop) (T : γ → δ → Prop) (a : α) (d : δ) :
    (∃ b, R a b ∧ ∃ c, S b c ∧ T c d) ↔
    (∃ c, (∃ b, R a b ∧ S b c) ∧ T c d) := sorry

---------------------------------------
/-! ### 19. Characterize equality by substitution into every predicate. -/

theorem A19 {α : Type u} (x y : α) :
    x = y ↔ ((P : α → Prop) → P x → P y) := sorry

---------------------------------------
/-! ### 20. Characterize function equality by pointwise equality. -/

/-!
The reverse direction may use `funext`. After completing the proof, inspect its trusted axiom
dependencies with `#print axioms Course2AExercises.A20`.
-/
theorem A20 {α : Type u} {β : Type v} (f g : α → β) :
    f = g ↔ ((x : α) → f x = g x) := sorry

end Course2AExercises
