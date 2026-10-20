import Mathlib.Data.Set.Basic
import Mathlib.Tactic

/-!
# 3A · Mathlib and Lean Library Mechanisms (Draft)

This lecture starts from a small but real Mathlib interface, then studies several ways to design
mathematical objects, and finally treats a large library as a growing global context of constants.
Typeclass inference belongs to 3B. Basic tactic usage belongs to 2B. This file uses both only through
already available interfaces and does not discuss metaprogramming.
-/

namespace Course3A

universe u v
variable {α : Type u} {β : Type v}

-------------------------------------------------------------------------------
/-! ## 1. Mathlib by example -/

---------------------------------------
/-! ### 1.1. A set is a proposition on elements -/

/-- A course-local set is a predicate on elements. -/
def PredSet (α : Type u) := α → Prop

/-- Membership in a course-local set. -/
def predMem (x : α) (s : PredSet α) : Prop := s x

/-- The subset relation between course-local sets. -/
def predSubset (s t : PredSet α) : Prop := ∀ ⦃x⦄, predMem x s → predMem x t

/-- The empty course-local set. -/
def predEmpty : PredSet α := fun _ ↦ False

/-- The universal course-local set. -/
def predUniv : PredSet α := fun _ ↦ True

/-- Union is pointwise disjunction. -/
def predUnion (s t : PredSet α) : PredSet α := fun x ↦ s x ∨ t x

/-- Intersection is pointwise conjunction. -/
def predInter (s t : PredSet α) : PredSet α := fun x ↦ s x ∧ t x

/-- Preimage is function composition at the level of predicates. -/
def predPreimage (f : α → β) (t : PredSet β) : PredSet α := fun x ↦ t (f x)

scoped[CoursePredSet] infix:50 " ∈₀ " => Course3A.predMem
scoped[CoursePredSet] notation "∅₀" => Course3A.predEmpty
scoped[CoursePredSet] infix:50 " ⊆₀ " => Course3A.predSubset
scoped[CoursePredSet] infixl:65 " ∪₀ " => Course3A.predUnion
scoped[CoursePredSet] infixl:70 " ∩₀ " => Course3A.predInter

open scoped CoursePredSet

#check PredSet
#check _root_.Set
#check predPreimage

example (x : α) : ¬ x ∈₀ (∅₀ : PredSet α) := by
  intro h
  exact h

example (x : α) (s t : PredSet α) : x ∈₀ s ∩₀ t ↔ x ∈₀ s ∧ x ∈₀ t := Iff.rfl

example (x : α) (s t : PredSet α) : x ∈₀ s ∪₀ t ↔ x ∈₀ s ∨ x ∈₀ t := Iff.rfl

example (f : α → β) (t : PredSet β) (x : α) :
    x ∈₀ predPreimage f t ↔ f x ∈₀ t := Iff.rfl

---------------------------------------
/-! ### 1.2. From definitions to a Mathlib API -/

#check _root_.Set.mem_union
#check _root_.Set.mem_inter_iff
#check _root_.Set.mem_preimage
#check _root_.Set.ext
#check _root_.Set.inter_subset_left

example (s t : _root_.Set α) : s ∩ t ⊆ s := _root_.Set.inter_subset_left

example (s t : _root_.Set α) (h : ∀ x, x ∈ s ↔ x ∈ t) : s = t := by
  ext x
  exact h x

/-- Membership in a course-local union is a useful normalization rule. -/
@[simp] theorem mem_predUnion (x : α) (s t : PredSet α) :
    x ∈₀ s ∪₀ t ↔ x ∈₀ s ∨ x ∈₀ t := Iff.rfl

/-- Course-local sets are equal when they contain the same elements. -/
@[ext (iff := false)] theorem PredSet.ext {s t : PredSet α} (h : ∀ x, x ∈₀ s ↔ x ∈₀ t) : s = t := by
  funext x
  exact propext (h x)

example (s : PredSet α) : s ∪₀ ∅₀ = s := by
  ext x
  simp [predUnion, predEmpty, predMem]

---------------------------------------
/-! ### 1.3. When a set must become a type -/

variable (s : _root_.Set α)

#check s
#check (fun x : α ↦ x ∈ s)
#check {x : α // x ∈ s}

/-- A function whose input itself certifies membership in `s`. -/
def restrictedIdentity : {x : α // x ∈ s} → α := fun x ↦ x.1

example (x : {x : α // x ∈ s}) : restrictedIdentity s x = x.1 := rfl

/-!
The examples above expose four different needs: selecting elements, restricting a domain, converting
an enriched object back to an underlying type, and identifying different representatives. Chapter 2
separates these constructions.
-/

-------------------------------------------------------------------------------
/-! ## 2. Designing type-theoretic objects -/

---------------------------------------
/-! ### 2.1. Sets and subtypes -/

/-- Natural numbers carrying a proof that they are nonzero. -/
def NonzeroNat := {n : Nat // n ≠ 0}

/-- Natural numbers carrying a proof that they are even. -/
def EvenNat := {n : Nat // Even n}

#check NonzeroNat
#check Subtype
#check Subtype.val
#check Subtype.property

example : NonzeroNat := ⟨1, by decide⟩
example (n : NonzeroNat) : Nat := n.val
example (n : NonzeroNat) : n.val ≠ 0 := n.property

/-- Successor sends every natural number to a nonzero natural number. -/
def nonzeroSucc (n : Nat) : NonzeroNat := ⟨n + 1, Nat.add_one_ne_zero n⟩

#eval (nonzeroSucc 41).val

---------------------------------------
/-! ### 2.2. Functions with a specified domain -/

/-- A function defined by accepting only elements of `s`. -/
def onSubtype (s : _root_.Set α) (f : α → β) : s → β := fun x ↦ f x.1

example (f : α → β) (x : s) : onSubtype s f x = f x.1 := rfl

/-- Alternatively, retain a total function and state that a theorem concerns only `s`. -/
def DoublesOn (f : Nat → Nat) (s : _root_.Set Nat) : Prop :=
  ∀ n ∈ s, f n = 2 * n

#check _root_.Set.EqOn
#check _root_.Set.MapsTo
#check _root_.Set.LeftInvOn
#check _root_.Set.RightInvOn
#check _root_.Set.BijOn

example (f : α → β) (s : _root_.Set α) : _root_.Set.MapsTo f s (f '' s) := by
  intro x hx
  exact ⟨x, hx, rfl⟩

example (f g : α → β) (s : _root_.Set α) :
    _root_.Set.EqOn f g s ↔ ∀ x ∈ s, f x = g x := Iff.rfl

---------------------------------------
/-! ### 2.3. Type conversion and observation -/

/-- Explicitly observe the underlying value stored by a subtype. -/
def underlying (x : NonzeroNat) : Nat := x.val

/-- The same observation can use the subtype's first projection. -/
def underlying' (x : NonzeroNat) : Nat := x.1

example (x : NonzeroNat) : underlying x = underlying' x := rfl

example : (3 : Int) = Int.ofNat 3 := rfl

/-!
The user-visible conversion above does not make `NonzeroNat` definitionally equal to `Nat`, and it
need not be reversible. How conversions are registered and found is part of the typeclass mechanism
and is deferred to 3B.
-/

---------------------------------------
/-! ### 2.4. Equivalence relations and quotient types -/

/-- Natural numbers are equivalent here when they have the same parity. -/
def paritySetoid : Setoid Nat where
  r a b := a % 2 = b % 2
  iseqv := ⟨
    fun _ ↦ rfl,
    fun h ↦ h.symm,
    fun hab hbc ↦ hab.trans hbc
  ⟩

/-- The type containing only the two parity classes. -/
abbrev Parity := Quotient paritySetoid

/-- Place a natural number into its parity class. -/
def toParity (n : Nat) : Parity := Quotient.mk paritySetoid n

#check Setoid
#check Quotient
#check Quotient.mk
#check Quotient.sound
#check Quotient.lift
#check Quotient.inductionOn

example : toParity 0 = toParity 2 := by
  apply Quotient.sound
  change 0 % 2 = 2 % 2
  decide

example : toParity 1 = toParity 3 := by
  apply Quotient.sound
  change 1 % 2 = 3 % 2
  decide

---------------------------------------
/-! ### 2.5. Well-defined functions on a quotient -/

/-- Read the parity class as an element of `Fin 2`; the result is representative-independent. -/
def parityValue : Parity → Fin 2 :=
  Quotient.lift
    (fun n ↦ ⟨n % 2, Nat.mod_lt n (by decide)⟩)
    (fun a b h ↦ by
      change a % 2 = b % 2 at h
      apply Fin.ext
      exact h)

#eval parityValue (toParity 8)
#eval parityValue (toParity 9)

example (q : Parity) : parityValue q = 0 ∨ parityValue q = 1 := by
  refine Quotient.inductionOn q ?_
  intro n
  omega

/-!
A function such as "take the chosen representative" cannot descend to `Parity`: equivalent natural
numbers may be different. `Quotient.lift` admits only observations that respect the relation.
-/

---------------------------------------
/-! ### 2.6. Equality through observable behavior -/

example (f g : α → β) (h : ∀ x, f x = g x) : f = g := by
  funext x
  exact h x

example (s t : _root_.Set α) (h : ∀ x, x ∈ s ↔ x ∈ t) : s = t := by
  exact _root_.Set.ext h

example (x y : NonzeroNat) (h : x.val = y.val) : x = y := by
  exact Subtype.ext h

-------------------------------------------------------------------------------
/-! ## 3. Managing a context of constants -/

---------------------------------------
/-! ### 3.1. Modules, imports, and namespaces -/

#check Course3A.PredSet
#check _root_.Set

namespace Names

def sample : Nat := 7

end Names

#check Names.sample

open Names
#check sample

---------------------------------------
/-! ### 3.2. Public interfaces and visibility -/

/-- A lightweight alias whose purpose is naming rather than abstraction. -/
abbrev Index := Nat

/-- An opaque constant exposes its type while hiding reduction through its implementation. -/
opaque chosenIndex : Index := 7

private def doublePrivate (n : Nat) : Nat := n + n

/-- A public declaration may use a private helper without exposing the helper as public API. -/
def doublePublic (n : Nat) : Nat := doublePrivate n

namespace Label

/-- A protected declaration is normally addressed through its namespace. -/
protected def render (n : Nat) : String := toString n

end Label

#check Label.render
#eval Label.render 42
#eval doublePublic 21

section SharedParameters

variable (f : α → β)
variable (x : α)

/-- Section variables become declaration parameters only when the declaration uses them. -/
def sectionExample : β := f x

end SharedParameters

#check sectionExample

---------------------------------------
/-! ### 3.3. Mathlib naming habits -/

#check _root_.Set.mem_union
#check _root_.Set.mem_inter_iff
#check _root_.Set.inter_subset_left
#check _root_.Set.union_comm
#check _root_.Set.union_assoc
#check _root_.Set.image_image
#check Function.LeftInverse

/-!
Names such as `mem_union`, `inter_subset_left`, `_comm`, `_assoc`, `_iff`, and `_of_` make a large
namespace guessable. The exact declaration name, rather than its notation, remains the stable search
and reference surface.
-/

---------------------------------------
/-! ### 3.4. Notation, precedence, and scope -/

/-- The parser groups this as `(s ∩₀ t) ∪₀ u` because intersection has higher precedence. -/
example (s t u : PredSet α) : s ∩₀ t ∪₀ u = (s ∩₀ t) ∪₀ u := rfl

/-- The relation has lower precedence than both set operations. -/
example (s t u v : PredSet α) :
    s ∩₀ t ∪₀ u ⊆₀ v ↔ ((s ∩₀ t) ∪₀ u) ⊆₀ v := Iff.rfl

/-!
The notation is available only after `open scoped CoursePredSet`. It changes how expressions are
written; the underlying declarations `predInter`, `predUnion`, and `predSubset` remain searchable.
-/

---------------------------------------
/-! ### 3.5. Declaration attributes -/

#check mem_predUnion
#check PredSet.ext

example (x : α) (s t : PredSet α) : x ∈₀ s ∪₀ t ↔ x ∈₀ s ∨ x ∈₀ t := by
  simp

example (s t : PredSet α) (h : ∀ x, x ∈₀ s ↔ x ∈₀ t) : s = t := by
  ext x
  exact h x

/-!
`@[simp]` and `@[ext]` register already checked theorems for tools learned in 2B. They add no new
logical rule. Other interface-oriented attributes include `@[deprecated ...]` and `@[inherit_doc]`.
Custom attributes and attribute handlers are metaprogramming and are outside this course.
-/

---------------------------------------
/-! ### 3.6. Documentation and declaration inspection -/

#check _root_.Set.inter_subset_left
#print _root_.Set.inter_subset_left
#print paritySetoid
#print parityValue

/-!
`/-- ... -/` documents one declaration, `/-! ... -/` documents a module or section, and ordinary
`/- ... -/` comments explain implementation details. Hover and Go to Definition expose the same
public declarations interactively.
-/

---------------------------------------
/-! ### 3.7. Finding declarations -/

/-- Start from the principal object and a guessed Mathlib name. -/
example (s t : _root_.Set α) : s ∩ t ⊆ s := by
  exact _root_.Set.inter_subset_left

/-- Suggestions learned in 2B can also reveal reusable declaration names. -/
example (s t : _root_.Set α) : s ∩ t ⊆ t := by
  exact?

/-!
A practical search ladder is:

1. Identify the principal object and probable namespace.
2. Guess a name from patterns such as `mem_`, `_subset_`, `_comm`, `_assoc`, and `_iff`.
3. Confirm it with `#check`, then inspect it with `#print` or Go to Definition.
4. Use `#find` or the goal-directed suggestions from 2B when only the type shape is known.
5. Use LeanSearch for a natural-language description, Loogle for a type pattern, and the generated
   Mathlib documentation or source search to inspect neighboring API declarations.

These tools find candidates; the kernel still checks the final term.
-/

end Course3A
