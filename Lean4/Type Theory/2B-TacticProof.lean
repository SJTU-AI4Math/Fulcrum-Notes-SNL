import Mathlib.Tactic.Linarith
import Mathlib.Tactic.Ring
import Aesop

/-!
# 2B · Tactics and Proof Methods (Draft)

This file turns contexts, targets, proof states, and tactics into examples that can be
stepped through one command at a time. Course declarations remain in their own namespace;
native Lean and Mathlib objects are inspected at the end.

Only the tactic modules needed below are imported. `native_decide`, `grind`, `apply?`,
`exact?`, and `simp?` are available from Lean itself; `norm_num` is re-exported by the
`linarith` tactic module.
-/

namespace Course2B

universe u
variable {α : Type u} {p q r : Prop} {P : α → Prop}

-------------------------------------------------------------------------------
/-! ## 1. Tactic Proof Basics -/
-------------------------------------------------------------------------------

---------------------------------------
/-! ## 1.1. `by`, `sorry` and `exact` -/

/-! Term proof -/
example (hp : p) : p := hp

/-!
`by` opens tactic mode. During exploration, `sorry` can temporarily stand for an unfinished
proof; finished course examples replace every such placeholder with an actual proof.
-/
example (hp : p) : p := by
  exact hp

/-! `exact` re-opens term mode and supplies a term with the current target type. -/
example (hp : p) : p := by
  exact hp

/-! `assumption` closes a goal using a matching hypothesis from the local context. -/
example (hp : p) : p := by
  assumption

/-! `rfl` proves reflexive equality after definitional reduction. -/
example (n : Nat) : (fun x ↦ x) n = n := by
  rfl

example (hp : p) (hq : q) : p ∧ q := by
  exact And.intro hp hq

example (hp : p) (hq : q) : p ∧ q := by
  exact ⟨hp, hq⟩

/-! Tactic mode can be opened anywhere expecting a term, whether a proof or a regular term. -/
example : Nat → Nat := by
  exact fun n => n + 1

example (hp : p) (hq : q) : p ∧ q := And.intro (by exact hp) (by exact hq)
example (hp : p) (hq : q) : p ∧ q := ⟨by exact hp, by exact hq⟩

/-! Write this if you want more homework: -/
example (hp : p) : p := by exact by exact by exact by exact hp

---------------------------------------
/-! ## 1.2. `let` & `have` -/

/-! Tactic `let` introduces a local definition. -/
example : Nat := by
  let n : Nat := 41
  exact n + 1

/-! Tactic `have` records an intermediate proof in the local context. -/
example (hpq : p → q) (hqr : q → r) (hp : p) : r := by
  have hq : q := hpq hp
  exact hqr hq

-------------------------------------------------------------------------------
/-! ## 2. Semi-Auto Tactics -/
-------------------------------------------------------------------------------

-- Semi-auto tactics do very little work, but help organize proofs in a step-by-step manner.
-- By "very little work", we mean they don't perform significant meta-programming-based automation.

---------------------------------------
/-! ### 2.1. `intro` -/

example (h : p → r) : p → q → r :=
  fun hp ↦ fun _ ↦ h hp

example (h : p → r) : p → q → r := by
  intro hp _
  exact h hp

example : Nat → Nat :=
  fun n => n * n + 1

example : Nat → Nat := by
  intro n
  exact n * n + 1

---------------------------------------
/-! ### 2.2. `apply` & `refine`-/

/-! `apply` uses a function backwards, replacing its conclusion by the required arguments. -/
example (hpq : p → q) (hqr : q → r) (hp : p) : r := by
  apply hqr
  apply hpq
  exact hp

/-!
`refine` submits a partial term. Unresolved placeholders become goals, and `?_` explicitly
requests a new goal; an inferred `_` may instead be solved during elaboration.
-/
example (hp : p) (hq : q) : p ∧ q := by
  refine And.intro hp ?_
  exact hq

example : ∃ n : Nat, n * n = 16 := by
  refine ⟨4, ?_⟩
  norm_num

---------------------------------------
/-! ### 2.3. `cases` & `rcases` -/

/-! `cases` applies an inductive eliminator and creates one goal for each possible constructor. -/
example (h : p ∨ q) : q ∨ p := by
  cases h with
  | inl hp =>
      exact Or.inr hp
  | inr hq =>
      exact Or.inl hq

example (h : p ∧ q) : q ∧ p := by
  cases h with
  | intro hp hq =>
      exact ⟨hq, hp⟩

example (h : False) : p := by
  cases h

/-! `rcases` combines elimination with constructor-pattern destructuring. -/
example (h : ∃ x, P x) : ∃ x, P x := by
  rcases h with ⟨x, hx⟩
  exact ⟨x, hx⟩

---------------------------------------
/-! ### 2.4. `induction` -/

/-! `induction` adds induction hypotheses to the constructor cases. -/
example (xs : List α) : xs ++ [] = xs := by
  induction xs with
  | nil =>
      rfl
  | cons x xs ih =>
      change x :: (xs ++ []) = x :: xs
      rw [ih]

example (n : Nat) : 0 + n = n := by
  induction n with
  | zero =>
      rfl
  | succ n ih =>
      rw [Nat.add_succ, ih]

#check List.rec
#check Nat.rec

---------------------------------------
/-! ### 2.5. `unfold`, `change` & `show` -/
-- `unfold` exposes selected transparent definitions in the goal or hypotheses.

/-- A course-local predicate used to expose definitional unfolding. -/
def Even (n : Nat) : Prop := ∃ k, n = 2 * k
#check Even

/-- A course-local divisibility relation used by the `show` example. -/
def Divides (a b : Nat) : Prop := ∃ k, b = a * k
#check Divides

/-! `unfold` exposes one named transparent definition in a goal or hypothesis. -/
example {n : Nat} (h : Even n) : ∃ k, n = 2 * k := by
  unfold Even at h
  exact h

/-! `change` selects a definitionally equal presentation of the target. -/
example (n : Nat) : Even (2 * n) := by
  change ∃ k, 2 * n = 2 * k
  exact ⟨n, rfl⟩

/-! `show` restates the current target without changing what must be proved. -/
example (n : Nat) : Divides n n := by
  show ∃ k, n = n * k
  exact ⟨1, by simp⟩

/-!
Kernel conversion often unfolds transparent definitions automatically. These tactics are useful
when a human or a syntax-directed tactic needs to see a particular target shape.
-/

---------------------------------------
/-! ### 2.6. Proof by contradiction -/
-- There are different ways to prove by contradiction -- some constructive, some not.

/-! This constructive proof turns `p → q` and `¬q` into `¬p`. -/
example (h : p → q) (hnq : ¬q) : ¬p := by
  unfold Not at *
  intro hp
  have hq := h hp
  exact hnq hq

/-! From an explicit contradiction, `exfalso` proves any proposition constructively. -/
example (hp : p) (hnp : ¬p) : q := by
  exfalso
  exact hnp hp

/-! `by_cases` is constructive when an explicit decision procedure is available. -/
example (p : Prop) [Decidable p] : p ∨ ¬p := by
  by_cases hp : p
  · exact Or.inl hp
  · exact Or.inr hp

/-! `by_contra` proves a general proposition by classical contradiction. -/
example (h : ¬p → q) (hnq : ¬q) : p := by
  by_contra hnp
  exact hnq (h hnp)

/-! The classical boundary is represented by these theorems. -/
#check Classical.em
#check Classical.byContradiction

---------------------------------------
/-! ### 2.7. `constructor`, `left`, `right` & `use` -/

example (hp : p) (hq : q) : p ∧ q := by
  constructor
  · exact hp
  · exact hq

example (hp : p) : p ∨ q := by
  left
  exact hp

example (hq : q) : p ∨ q := by
  right
  exact hq

example : ∃ n : Nat, n + 1 = 3 := by
  use 2

---------------------------------------
/-! ### 2.8. Term rewriting -/

/-! `rw` transports the goal along a propositional equality. -/
example (a b : Nat) (h : a = b) : a + 1 = b + 1 := by
  rw [h]

/-! A left arrow reverses the rewrite direction. -/
example (a b : Nat) (h : a = b) : b + 1 = a + 1 := by
  rw [← h]

/-! Rewriting can target a hypothesis instead of the goal. -/
example (a b : Nat) (h : a = b) (ha : a = 0) : b = 0 := by
  rw [h] at ha
  exact ha

/-! `subst` removes a variable identified by an equality. -/
example (a b : Nat) (h : a = b) : a + b = b + b := by
  subst a
  rfl

---------------------------------------
/-! ### 2.9. `calc` -/

/-! A `calc` block records an explicit chain of rewrites. -/
example (a b c : Nat) (hab : a = b) (hbc : b = c) : a = c := by
  calc
    a = b := hab
    _ = c := hbc

-------------------------------------------------------------------------------
/-! ## 3. Full-Auto Tactics -/
-------------------------------------------------------------------------------

---------------------------------------
/-! ### 3.1. `norm_num` -/

/-! `norm_num` proves goals by normalizing concrete numerical expressions. -/
example : (37 : Nat) + 5 = 42 := by
  norm_num

example : (7 : Int) ^ 2 - 4 ^ 2 = 33 := by
  norm_num

---------------------------------------
/-! ### 3.2. `simp` -/

/-! `simp` repeatedly performs directed rewriting with its simplification rules. -/
example (xs : List α) : xs.reverse.reverse = xs := by
  simp

/-! `simp only` locks the proof to the listed rules. -/
example (n : Nat) : n + 0 = n := by
  simp only [Nat.add_zero]

---------------------------------------
/-! ### 3.3. `ring` & `linarith` -/

/-! `ring` normalizes polynomial identities over commutative semirings and rings. -/
example (x y : Int) : (x + y) ^ 2 = x ^ 2 + 2 * x * y + y ^ 2 := by
  ring

/-! `linarith` combines linear equalities and inequalities. -/
example (x y : Rat) (hxy : x ≤ y) (hyx : y ≤ x) : x = y := by
  linarith

/-! `omega` decides Presburger arithmetic over natural numbers and integers. -/
example (a b : Int) (h₁ : a ≤ b) (h₂ : b ≤ a + 1) : b = a ∨ b = a + 1 := by
  omega

---------------------------------------
/-! ### 3.4. `native_decide` -/

/-! `native_decide` compiles and evaluates a closed decidable proposition. -/
example : (12345 : Nat) < 12346 := by
  native_decide

/-!
Unlike `decide`, whose computation is checked through ordinary kernel reduction, `native_decide`
uses Lean's native execution path. It is faster for large computations but additionally trusts
the native compiler and runtime path.
-/

---------------------------------------
/-! ### 3.5. `aesop` -/

/-! `aesop` performs configurable rule-based proof search with backtracking. -/
example (hpq : p → q) (hqr : q → r) : p → r := by
  aesop

---------------------------------------
/-! ### 3.6. `grind` -/

/-! `grind` combines goal-directed proof search, congruence closure, and decision procedures. -/
example (h : p ∨ q) : q ∨ p := by
  grind

-------------------------------------------------------------------------------
/-! ## 4. Helper Tactics -/
-------------------------------------------------------------------------------

---------------------------------------
/-! ### 4.1. `apply?`, `exact?` & `simp?` -/

/-!
These tactics search for, apply, and print a more explicit replacement. They may leave generated
subgoals, although the small examples here close immediately.
-/
example (n m : Nat) (h : n ≤ m) : n + 1 ≤ m + 1 := by
  apply?

example (n : Nat) : n ≤ n := by
  exact?

example (n : Nat) : n + 0 = n := by
  simp?

-------------------------------------------------------------------------------
/-! ## 5. Termination Proofs for Non-structural Recursion -/
-------------------------------------------------------------------------------

/-!
Lean accepts recursive calls that are not visibly made on an immediate constructor subterm when
the author supplies a well-founded measure and proves that every recursive call decreases it.
-/

---------------------------------------
/-! ### 5.1. `termination_by` -/

/-! `termination_by` selects the measure used to justify well-founded recursion. -/
def countdownByTwo : Nat → List Nat
  | 0 => []
  | n + 1 => (n + 1) :: countdownByTwo ((n + 1) - 2)
termination_by n => n
decreasing_by omega

---------------------------------------
/-! ### 5.2. `decreasing_by` -/

/-! `decreasing_by` proves the decrease obligation generated for each recursive call. -/
def euclid (a b : Nat) : Nat :=
  match b with
  | 0 => a
  | b + 1 => euclid (b + 1) (a % (b + 1))
termination_by b
decreasing_by
  exact Nat.mod_lt _ (Nat.succ_pos _)

end Course2B
