import Mathlib.Algebra.Field.Defs
import Mathlib.LinearAlgebra.LinearIndependent.Basic
import Mathlib.Algebra.Module.Torsion.Field
import Lean4.«Linear Algebra».term_macros_CN

/-! # 向量和线性空间 -/

universe u v

namespace Fulcrum

/-- Textbook vector space: inherit operations for notation, but state all laws here. -/
class VectorSpace (𝕂 : outParam (Type u)) (V : Type v) [Field 𝕂]
    extends Add V, Zero V, SMul 𝕂 V where
  add_comm : ∀ a b : V, a + b = b + a
  add_assoc : ∀ a b c : V, a + (b + c) = (a + b) + c
  add_zero : ∀ a : V, a + 0 = a
  exists_add_inverse : ∀ a : V, ∃ b : V, a + b = 0
  smul_smul : ∀ (k l : 𝕂) (a : V), k • (l • a) = (k * l) • a
  smul_add : ∀ (k : 𝕂) (a b : V), k • (a + b) = k • a + k • b
  add_smul : ∀ (k l : 𝕂) (a : V), (k + l) • a = k • a + l • a
  one_smul : ∀ a : V, (1 : 𝕂) • a = a

#snl_print VectorSpace
#snl_print VectorSpace.toAdd
#snl_print VectorSpace.toZero
#snl_print VectorSpace.toSMul
#snl_print VectorSpace.add_comm
#snl_print VectorSpace.add_assoc
#snl_print VectorSpace.add_zero
#snl_print VectorSpace.exists_add_inverse
#snl_print VectorSpace.smul_smul
#snl_print VectorSpace.smul_add
#snl_print VectorSpace.add_smul
#snl_print VectorSpace.one_smul

namespace VectorSpace

variable {𝕂 : Type u} {V : Type v} [Field 𝕂] [s : VectorSpace 𝕂 V]

/-- Left zero follows from commutativity and the textbook right-zero axiom. -/
theorem zero_add (a : V) : s.add s.zero a = a := by
  exact (s.add_comm s.zero a).trans (s.add_zero a)

#snl_print zero_add

/-- Cancellation uses the existential inverse only inside a proposition;
no choice operation or classical inverse is introduced. -/
theorem add_left_cancel (a b c : V) (h : s.add a b = s.add a c) : b = c := by
  obtain ⟨d, hd⟩ := s.exists_add_inverse a
  have hda : s.add d a = s.zero := (s.add_comm d a).trans hd
  calc
    b = s.add s.zero b := (zero_add b).symm
    _ = s.add (s.add d a) b := by rw [hda]
    _ = s.add d (s.add a b) := (s.add_assoc d a b).symm
    _ = s.add d (s.add a c) := congrArg (s.add d) h
    _ = s.add (s.add d a) c := s.add_assoc d a c
    _ = c := by rw [hda, zero_add]

#snl_print add_left_cancel

/-- Derived before any additive group or Module is installed. -/
theorem zero_smul (a : V) : s.smul 0 a = s.zero := by
  have h : s.smul 0 a = s.add (s.smul 0 a) (s.smul 0 a) := by
    simpa only [_root_.zero_add] using s.add_smul 0 0 a
  apply (add_left_cancel (𝕂 := 𝕂) (s.smul 0 a) (s.smul 0 a) s.zero)
  exact h.symm.trans (s.add_zero _).symm

#snl_print zero_smul

/-- Derived before any additive group or Module is installed. -/
theorem smul_zero (k : 𝕂) : s.smul k s.zero = s.zero := by
  have h : s.smul k s.zero = s.add (s.smul k s.zero) (s.smul k s.zero) := by
    exact (congrArg (s.smul k) (s.add_zero s.zero)).symm.trans
      (s.smul_add k s.zero s.zero)
  apply (add_left_cancel (𝕂 := 𝕂) (s.smul k s.zero) (s.smul k s.zero) s.zero)
  exact h.symm.trans (s.add_zero _).symm

#snl_print smul_zero

/-- The additive inverse is constructively the original scalar action of `-1`. -/
theorem neg_one_smul_add (a : V) : s.add (s.smul (-1) a) a = s.zero := by
  calc
    s.add (s.smul (-1) a) a = s.add (s.smul (-1) a) (s.smul 1 a) := by
      exact congrArg (s.add (s.smul (-1) a)) (s.one_smul a).symm
    _ = s.smul (-1 + 1) a := (s.add_smul (-1) 1 a).symm
    _ = s.zero := by rw [_root_.neg_add_cancel, zero_smul]

#snl_print neg_one_smul_add

variable (𝕂 V)

/-! 两个桥只使用同一个 VectorSpace 的数据，不增加公理或更换载体。
`𝕂` 是 outParam：在当前选定的 VectorSpace 实例中推断标量域，
并自动获得 AddCommGroup 和 Module，下文不必反复写 letI。
这不表示载体 V 唯一决定标量域；多个标量结构或已有不一致的运算并存时，
仍须显式选择结构，不能假定自动搜索会让它们相容。
-/

/-- Reducible instance bridge on the SAME carrier, addition, and zero.
Negation is `(-1)` acting by the original scalar multiplication. -/
@[instance]
abbrev toAddCommGroup : AddCommGroup V where
  add := s.add
  zero := s.zero
  neg := s.smul (-1)
  add_assoc := fun a b c => (s.add_assoc a b c).symm
  add_comm := s.add_comm
  zero_add := zero_add
  add_zero := s.add_zero
  neg_add_cancel := neg_one_smul_add
  nsmul := @nsmulRec V ⟨s.zero⟩ ⟨s.add⟩
  zsmul := @zsmulRec V ⟨s.zero⟩ ⟨s.add⟩ ⟨s.smul (-1)⟩
    (@nsmulRec V ⟨s.zero⟩ ⟨s.add⟩)

#snl_print toAddCommGroup

/-- The inferred additive structure is exactly `toAddCommGroup 𝕂 V`.
The scalar action and all proofs come from the same textbook instance. -/
@[instance]
abbrev toModule : Module 𝕂 V where
  smul := s.smul
  one_smul := s.one_smul
  mul_smul := fun k l a => (s.smul_smul k l a).symm
  smul_add := s.smul_add
  smul_zero := smul_zero
  add_smul := s.add_smul
  zero_smul := zero_smul

#snl_print toModule

end VectorSpace

end Fulcrum

namespace Fulcrum
section Elementary
variable {𝕂 V : Type*} [Field 𝕂] [s : VectorSpace 𝕂 V]

-- An element of V is a vector; no wrapper type is introduced.
variable (v : V)

/-- The textbook additive-inverse predicate. -/
def IsAdditiveInverse (w v : V) : Prop := s.add v w = s.zero

#snl_print IsAdditiveInverse

/-- Literal statement of the existing SNL zero-uniqueness Entry. -/
theorem zero_unique (z₁ z₂ : V) (h : z₁ = s.zero ∧ z₂ = s.zero) : z₁ = z₂ :=
  h.1.trans h.2.symm

#snl_print zero_unique

theorem additive_inverse_unique (v w₁ w₂ : V)
    (h : IsAdditiveInverse (𝕂 := 𝕂) w₁ v ∧ IsAdditiveInverse (𝕂 := 𝕂) w₂ v) : w₁ = w₂ :=
  VectorSpace.add_left_cancel v w₁ w₂ (h.1.trans h.2.symm)

#snl_print additive_inverse_unique

-- These statements are already supplied by Mathlib. The builders above provide their instances.
#print add_right_cancel
#snl_print add_right_cancel
#print zero_smul
#snl_print zero_smul
#print smul_zero
#snl_print smul_zero
#print neg_one_smul
#snl_print neg_one_smul
#print smul_eq_zero
#snl_print smul_eq_zero
end Elementary
end Fulcrum

/-! # 向量的线性关系 -/
#print Fin
#snl_print Fin

namespace Fulcrum

open scoped BigOperators

variable {𝕂 V : Type*} [Field 𝕂] [s : VectorSpace 𝕂 V]
variable {n m : ℕ}

/-- A represented vector admits a finite coefficient family. -/
def IsLinearRepresentation (β : V) (α : Fin n → V) : Prop :=
  ∃ c : Fin n → 𝕂, β = ∑ i, c i • α i

#snl_print IsLinearRepresentation

/-- A relation is a coefficient family whose finite combination vanishes. -/
def IsLinearRelation (c : Fin n → 𝕂) (α : Fin n → V) : Prop :=
  ∑ i, c i • α i = 0

#snl_print IsLinearRelation

/-- Nontriviality means that at least one indexed coefficient is nonzero. -/
def NontrivialCoefficients (c : Fin n → 𝕂) : Prop := ∃ i, c i ≠ 0

#snl_print NontrivialCoefficients

def LinearlyDependent (α : Fin n → V) : Prop :=
  ∃ c : Fin n → 𝕂, IsLinearRelation c α ∧ ∃ i, c i ≠ 0

#snl_print LinearlyDependent

def LinearlyIndependent (α : Fin n → V) : Prop :=
  ∀ c : Fin n → 𝕂, IsLinearRelation c α → ∀ i, c i = 0

#snl_print LinearlyIndependent

/-- Excludes the occurrence at `i`, not every occurrence of the value `α i`. -/
def RepresentableByOthers (α : Fin n → V) (i : Fin n) : Prop :=
  ∃ c : Fin n → 𝕂, α i = ∑ j ∈ Finset.univ.erase i, c j • α j

#snl_print RepresentableByOthers

/-- Uniqueness is conditional on representability; it does not assert spanning. -/
def UniqueRepresentation (α : Fin n → V) : Prop :=
  ∀ β : V, IsLinearRepresentation (𝕂 := 𝕂) β α →
    ∃! c : Fin n → 𝕂, β = ∑ i, c i • α i

#snl_print UniqueRepresentation

/-- A subfamily is obtained by injective reindexing, preserving occurrences. -/
def Subfamily (γ : Fin m → V) (α : Fin n → V) : Prop :=
  ∃ f : Fin m → Fin n, Function.Injective f ∧ ∀ i, γ i = α (f i)

#snl_print Subfamily

def Contains (α : Fin n → V) (v : V) : Prop := ∃ i, α i = v

#snl_print Contains

/-- Repetition requires two distinct indices, even when all values coincide. -/
def HasRepeat (α : Fin n → V) : Prop :=
  ∃ i j, i ≠ j ∧ α i = α j

#snl_print HasRepeat

-- Context of a finite indexed family; Fin n means indices 0, ..., n - 1.
variable (α : Fin n → V)

theorem dependent_iff_nontrivial_relation :
  LinearlyDependent (𝕂 := 𝕂) α ↔
      ∃ c : Fin n → 𝕂, IsLinearRelation c α ∧ NontrivialCoefficients c := by
  exact Iff.rfl

#snl_print dependent_iff_nontrivial_relation

theorem linearly_independent_iff_mathlib :
  LinearlyIndependent (𝕂 := 𝕂) α ↔ _root_.LinearIndependent 𝕂 α := by
  exact Fintype.linearIndependent_iff.symm

#snl_print linearly_independent_iff_mathlib

theorem linearly_dependent_iff_not_mathlib :
  LinearlyDependent (𝕂 := 𝕂) α ↔ ¬ _root_.LinearIndependent 𝕂 α := by
  exact Fintype.not_linearIndependent_iff.symm

#snl_print linearly_dependent_iff_not_mathlib

theorem linearly_dependent_iff_not_independent :
  LinearlyDependent (𝕂 := 𝕂) α ↔ ¬ LinearlyIndependent (𝕂 := 𝕂) α := by
  rw [linearly_independent_iff_mathlib, linearly_dependent_iff_not_mathlib]

#snl_print linearly_dependent_iff_not_independent

theorem representable_by_others_of_relation {c : Fin n → 𝕂} {i : Fin n}
    (hc : IsLinearRelation c α) (hi : c i ≠ 0) :
  RepresentableByOthers (𝕂 := 𝕂) α i := by
  have hsum : (∑ j ∈ Finset.univ.erase i, c j • α j) = -(c i • α i) := by
    apply eq_neg_iff_add_eq_zero.mpr
    rw [Finset.sum_erase_add _ _ (Finset.mem_univ i)]
    exact hc
  refine ⟨fun j => -(c i)⁻¹ * c j, ?_⟩
  calc
    α i = (-(c i)⁻¹) • (-(c i • α i)) := by
      simp [smul_smul, hi]
    _ = (-(c i)⁻¹) • (∑ j ∈ Finset.univ.erase i, c j • α j) := by rw [hsum]
    _ = ∑ j ∈ Finset.univ.erase i, (-(c i)⁻¹ * c j) • α j := by
      rw [Finset.smul_sum]
      simp only [smul_smul]

#snl_print representable_by_others_of_relation

theorem dependent_of_representable_by_others {i : Fin n}
    (h : RepresentableByOthers (𝕂 := 𝕂) α i) :
  LinearlyDependent (𝕂 := 𝕂) α := by
  classical
  obtain ⟨c, hc⟩ := h
  let d : Fin n → 𝕂 := Function.update c i (-1)
  refine ⟨d, ?_, i, ?_⟩
  · change (∑ j, d j • α j) = 0
    rw [← Finset.sum_erase_add _ _ (Finset.mem_univ i)]
    have hd : (∑ j ∈ Finset.univ.erase i, d j • α j) =
        ∑ j ∈ Finset.univ.erase i, c j • α j := by
      apply Finset.sum_congr rfl
      intro j hj
      simp [d, Function.update_of_ne (Finset.ne_of_mem_erase hj)]
    rw [hd, ← hc]
    simp [d]
  · simp [d]

#snl_print dependent_of_representable_by_others

theorem dependent_iff_representable_by_others :
  LinearlyDependent (𝕂 := 𝕂) α ↔
      ∃ i : Fin n, RepresentableByOthers (𝕂 := 𝕂) α i := by
  constructor
  · rintro ⟨c, hc, i, hi⟩
    exact ⟨i, representable_by_others_of_relation α hc hi⟩
  · rintro ⟨i, hi⟩
    exact dependent_of_representable_by_others α hi

#snl_print dependent_iff_representable_by_others

theorem independent_iff_unique_representation :
  LinearlyIndependent (𝕂 := 𝕂) α ↔ UniqueRepresentation (𝕂 := 𝕂) α := by
  constructor
  · intro h β hb
    obtain ⟨c, hc⟩ := hb
    refine ⟨c, hc, ?_⟩
    intro d hd
    funext i
    exact ((linearly_independent_iff_mathlib α).mp h).eq_coords_of_eq
      (hd.symm.trans hc) i
  · intro h c hc i
    have hz : IsLinearRepresentation (𝕂 := 𝕂) (0 : V) α :=
      ⟨fun _ => 0, by simp⟩
    obtain ⟨d, hd, hu⟩ := h 0 hz
    have hcd : c = d := hu c hc.symm
    have hzd : (fun _ : Fin n => (0 : 𝕂)) = d := hu _ (by simp)
    exact congrFun (hcd.trans hzd.symm) i

#snl_print independent_iff_unique_representation

theorem subfamily_independent {γ : Fin m → V}
    (h : LinearlyIndependent (𝕂 := 𝕂) α) (hs : Subfamily γ α) :
  LinearlyIndependent (𝕂 := 𝕂) γ := by
  obtain ⟨f, hf, heq⟩ := hs
  have hg : γ = α ∘ f := funext heq
  rw [hg, linearly_independent_iff_mathlib]
  exact ((linearly_independent_iff_mathlib α).mp h).comp f hf

#snl_print subfamily_independent

theorem superfamily_dependent {γ : Fin m → V}
    (h : LinearlyDependent (𝕂 := 𝕂) α) (hs : Subfamily α γ) :
  LinearlyDependent (𝕂 := 𝕂) γ := by
  rw [linearly_dependent_iff_not_independent] at h ⊢
  intro hg
  exact h (subfamily_independent γ hg hs)

#snl_print superfamily_dependent

theorem singleton_independent (v : V) :
  LinearlyIndependent (𝕂 := 𝕂) (fun _ : Fin 1 => v) ↔ v ≠ 0 := by
  rw [linearly_independent_iff_mathlib]
  exact linearIndependent_unique_iff

#snl_print singleton_independent

theorem dependent_of_contains_zero (h : Contains α s.zero) :
  LinearlyDependent (𝕂 := 𝕂) α := by
  obtain ⟨i, hi⟩ := h
  rw [linearly_dependent_iff_not_mathlib]
  intro hind
  exact hind.ne_zero i hi

#snl_print dependent_of_contains_zero

theorem dependent_of_repeated_vector (h : HasRepeat α) :
  LinearlyDependent (𝕂 := 𝕂) α := by
  obtain ⟨i, j, hij, heq⟩ := h
  rw [linearly_dependent_iff_not_mathlib]
  intro hind
  exact hij (hind.injective heq)

#snl_print dependent_of_repeated_vector

end Fulcrum
