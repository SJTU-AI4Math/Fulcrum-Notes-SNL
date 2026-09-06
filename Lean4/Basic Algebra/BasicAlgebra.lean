import Mathlib.Algebra.Field.Defs
import Mathlib.LinearAlgebra.LinearIndependent.Basic
import Mathlib.Algebra.Module.Torsion.Field
import SNL4Lean

/-! Mathlib declarations are imported unchanged; no local Mathlib terminology overrides. -/
#print Semigroup
#snl_const_widget Semigroup

/-! # 向量和线性空间 -/

universe u v

namespace Fulcrum

/-- Textbook vector space, with no parent structures and no hidden Module assumption. -/
class VectorSpace (K : Type u) (V : Type v) [Field K] where
  add : V → V → V
  zero : V
  smul : K → V → V
  add_comm : ∀ a b, add a b = add b a
  add_assoc : ∀ a b c, add a (add b c) = add (add a b) c
  add_zero : ∀ a, add a zero = a
  exists_add_inverse : ∀ a, ∃ b, add a b = zero
  smul_smul : ∀ k l a, smul k (smul l a) = smul (k * l) a
  smul_add : ∀ k a b, smul k (add a b) = add (smul k a) (smul k b)
  add_smul : ∀ k l a, smul (k + l) a = add (smul k a) (smul l a)
  one_smul : ∀ a, smul 1 a = a

namespace VectorSpace

variable {K : Type u} {V : Type v} [Field K] [s : VectorSpace K V]

/-- Left zero follows from commutativity and the textbook right-zero axiom. -/
theorem zero_add (a : V) : s.add s.zero a = a := by
  rw [s.add_comm, s.add_zero]

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

/-- Derived before any additive group or Module is installed. -/
theorem zero_smul (a : V) : s.smul 0 a = s.zero := by
  have h : s.smul 0 a = s.add (s.smul 0 a) (s.smul 0 a) := by
    simpa only [_root_.zero_add] using s.add_smul 0 0 a
  apply (add_left_cancel (K := K) (s.smul 0 a) (s.smul 0 a) s.zero)
  exact h.symm.trans (s.add_zero _).symm

/-- Derived before any additive group or Module is installed. -/
theorem smul_zero (k : K) : s.smul k s.zero = s.zero := by
  have h : s.smul k s.zero = s.add (s.smul k s.zero) (s.smul k s.zero) := by
    simpa only [s.add_zero] using s.smul_add k s.zero s.zero
  apply (add_left_cancel (K := K) (s.smul k s.zero) (s.smul k s.zero) s.zero)
  exact h.symm.trans (s.add_zero _).symm

/-- The additive inverse is constructively the original scalar action of `-1`. -/
theorem neg_one_smul_add (a : V) : s.add (s.smul (-1) a) a = s.zero := by
  calc
    s.add (s.smul (-1) a) a = s.add (s.smul (-1) a) (s.smul 1 a) := by
      rw [s.one_smul]
    _ = s.smul (-1 + 1) a := (s.add_smul (-1) 1 a).symm
    _ = s.zero := by rw [_root_.neg_add_cancel, zero_smul]

variable (K V)

/-! 两个桥只使用同一个 VectorSpace 的数据，不增加公理或更换载体。
使用 Mathlib 时局部安装：
```
letI : AddCommGroup V := VectorSpace.toAddCommGroup K V
letI : Module K V := VectorSpace.toModule K V
```
仅凭 AddCommGroup V 不能推断标量域 K，所以这里不注册全局实例。
-/

/-- Explicit, reducible bridge on the SAME carrier, addition, and zero.
Negation is `(-1)` acting by the original scalar multiplication. -/
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

/-- Explicit Module bridge whose type fixes exactly the preceding additive group.
Install `toAddCommGroup K V` first, then this value. Do not replace it with an
unrelated `[AddCommGroup V]`: the operations are intentionally not arbitrary. -/
abbrev toModule : letI := toAddCommGroup K V; Module K V := by
  letI := toAddCommGroup K V
  exact
    { smul := s.smul
      one_smul := s.one_smul
      mul_smul := fun k l a => (s.smul_smul k l a).symm
      smul_add := s.smul_add
      smul_zero := smul_zero
      add_smul := s.add_smul
      zero_smul := zero_smul }

end VectorSpace

end Fulcrum

namespace Fulcrum
section Elementary
variable {K V : Type*} [Field K] [s : VectorSpace K V]

-- An element of V is a vector; no wrapper type is introduced.
variable (v : V)

/-- The textbook additive-inverse predicate. -/
def IsAdditiveInverse (w v : V) : Prop := s.add v w = s.zero

/-- Literal statement of the existing SNL zero-uniqueness Entry. -/
theorem zero_unique (z₁ z₂ : V) (h : z₁ = s.zero ∧ z₂ = s.zero) : z₁ = z₂ :=
  h.1.trans h.2.symm

theorem additive_inverse_unique (v w₁ w₂ : V)
    (h : IsAdditiveInverse (K := K) w₁ v ∧ IsAdditiveInverse (K := K) w₂ v) : w₁ = w₂ :=
  VectorSpace.add_left_cancel v w₁ w₂ (h.1.trans h.2.symm)

-- These statements are already supplied by Mathlib. The builders above provide their instances.
#print add_right_cancel
#print zero_smul
#print smul_zero
#print neg_one_smul
#print smul_eq_zero
end Elementary
end Fulcrum

/-! # 向量的线性关系 -/
#print Fin

namespace Fulcrum

open scoped BigOperators

variable {K V : Type*} [Field K] [s : VectorSpace K V]
variable {n m : ℕ}

/-- A represented vector admits a finite coefficient family. -/
def IsLinearRepresentation (β : V) (α : Fin n → V) : Prop :=
  letI : AddCommGroup V := VectorSpace.toAddCommGroup K V
  letI : Module K V := VectorSpace.toModule K V
  ∃ c : Fin n → K, β = ∑ i, c i • α i

/-- A relation is a coefficient family whose finite combination vanishes. -/
def IsLinearRelation (c : Fin n → K) (α : Fin n → V) : Prop :=
  letI : AddCommGroup V := VectorSpace.toAddCommGroup K V
  letI : Module K V := VectorSpace.toModule K V
  ∑ i, c i • α i = 0

/-- Nontriviality means that at least one indexed coefficient is nonzero. -/
def NontrivialCoefficients (c : Fin n → K) : Prop := ∃ i, c i ≠ 0

def LinearlyDependent (α : Fin n → V) : Prop :=
  ∃ c : Fin n → K, IsLinearRelation c α ∧ ∃ i, c i ≠ 0

def LinearlyIndependent (α : Fin n → V) : Prop :=
  ∀ c : Fin n → K, IsLinearRelation c α → ∀ i, c i = 0

/-- Excludes the occurrence at `i`, not every occurrence of the value `α i`. -/
def RepresentableByOthers (α : Fin n → V) (i : Fin n) : Prop :=
  letI : AddCommGroup V := VectorSpace.toAddCommGroup K V
  letI : Module K V := VectorSpace.toModule K V
  ∃ c : Fin n → K, α i = ∑ j ∈ Finset.univ.erase i, c j • α j

/-- Uniqueness is conditional on representability; it does not assert spanning. -/
def UniqueRepresentation (α : Fin n → V) : Prop :=
  letI : AddCommGroup V := VectorSpace.toAddCommGroup K V
  letI : Module K V := VectorSpace.toModule K V
  ∀ β : V, IsLinearRepresentation (K := K) β α →
    ∃! c : Fin n → K, β = ∑ i, c i • α i

/-- A subfamily is obtained by injective reindexing, preserving occurrences. -/
def Subfamily (γ : Fin m → V) (α : Fin n → V) : Prop :=
  ∃ f : Fin m → Fin n, Function.Injective f ∧ ∀ i, γ i = α (f i)

def Contains (α : Fin n → V) (v : V) : Prop := ∃ i, α i = v

/-- Repetition requires two distinct indices, even when all values coincide. -/
def HasRepeat (α : Fin n → V) : Prop :=
  ∃ i j, i ≠ j ∧ α i = α j

-- Context of a finite indexed family; Fin n means indices 0, ..., n - 1.
variable (α : Fin n → V)

theorem dependent_iff_nontrivial_relation :
  letI : AddCommGroup V := VectorSpace.toAddCommGroup K V
  letI : Module K V := VectorSpace.toModule K V
  LinearlyDependent (K := K) α ↔
      ∃ c : Fin n → K, IsLinearRelation c α ∧ NontrivialCoefficients c := by
  letI : AddCommGroup V := VectorSpace.toAddCommGroup K V
  letI : Module K V := VectorSpace.toModule K V
  exact Iff.rfl

theorem linearly_independent_iff_mathlib :
  letI : AddCommGroup V := VectorSpace.toAddCommGroup K V
  letI : Module K V := VectorSpace.toModule K V
  LinearlyIndependent (K := K) α ↔ _root_.LinearIndependent K α := by
  letI : AddCommGroup V := VectorSpace.toAddCommGroup K V
  letI : Module K V := VectorSpace.toModule K V
  exact Fintype.linearIndependent_iff.symm

theorem linearly_dependent_iff_not_mathlib :
  letI : AddCommGroup V := VectorSpace.toAddCommGroup K V
  letI : Module K V := VectorSpace.toModule K V
  LinearlyDependent (K := K) α ↔ ¬ _root_.LinearIndependent K α := by
  letI : AddCommGroup V := VectorSpace.toAddCommGroup K V
  letI : Module K V := VectorSpace.toModule K V
  exact Fintype.not_linearIndependent_iff.symm

theorem linearly_dependent_iff_not_independent :
  letI : AddCommGroup V := VectorSpace.toAddCommGroup K V
  letI : Module K V := VectorSpace.toModule K V
  LinearlyDependent (K := K) α ↔ ¬ LinearlyIndependent (K := K) α := by
  letI : AddCommGroup V := VectorSpace.toAddCommGroup K V
  letI : Module K V := VectorSpace.toModule K V
  rw [linearly_independent_iff_mathlib, linearly_dependent_iff_not_mathlib]

theorem representable_by_others_of_relation {c : Fin n → K} {i : Fin n}
    (hc : IsLinearRelation c α) (hi : c i ≠ 0) :
  letI : AddCommGroup V := VectorSpace.toAddCommGroup K V
  letI : Module K V := VectorSpace.toModule K V
  RepresentableByOthers (K := K) α i := by
  letI : AddCommGroup V := VectorSpace.toAddCommGroup K V
  letI : Module K V := VectorSpace.toModule K V
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

theorem dependent_of_representable_by_others {i : Fin n}
    (h : RepresentableByOthers (K := K) α i) :
  letI : AddCommGroup V := VectorSpace.toAddCommGroup K V
  letI : Module K V := VectorSpace.toModule K V
  LinearlyDependent (K := K) α := by
  letI : AddCommGroup V := VectorSpace.toAddCommGroup K V
  letI : Module K V := VectorSpace.toModule K V
  classical
  obtain ⟨c, hc⟩ := h
  let d : Fin n → K := Function.update c i (-1)
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

theorem dependent_iff_representable_by_others :
  letI : AddCommGroup V := VectorSpace.toAddCommGroup K V
  letI : Module K V := VectorSpace.toModule K V
  LinearlyDependent (K := K) α ↔
      ∃ i : Fin n, RepresentableByOthers (K := K) α i := by
  letI : AddCommGroup V := VectorSpace.toAddCommGroup K V
  letI : Module K V := VectorSpace.toModule K V
  constructor
  · rintro ⟨c, hc, i, hi⟩
    exact ⟨i, representable_by_others_of_relation α hc hi⟩
  · rintro ⟨i, hi⟩
    exact dependent_of_representable_by_others α hi

theorem independent_iff_unique_representation :
  letI : AddCommGroup V := VectorSpace.toAddCommGroup K V
  letI : Module K V := VectorSpace.toModule K V
  LinearlyIndependent (K := K) α ↔ UniqueRepresentation (K := K) α := by
  letI : AddCommGroup V := VectorSpace.toAddCommGroup K V
  letI : Module K V := VectorSpace.toModule K V
  constructor
  · intro h β hb
    obtain ⟨c, hc⟩ := hb
    refine ⟨c, hc, ?_⟩
    intro d hd
    funext i
    exact ((linearly_independent_iff_mathlib α).mp h).eq_coords_of_eq
      (hd.symm.trans hc) i
  · intro h c hc i
    have hz : IsLinearRepresentation (K := K) (0 : V) α :=
      ⟨fun _ => 0, by simp⟩
    obtain ⟨d, hd, hu⟩ := h 0 hz
    have hcd : c = d := hu c hc.symm
    have hzd : (fun _ : Fin n => (0 : K)) = d := hu _ (by simp)
    exact congrFun (hcd.trans hzd.symm) i

theorem subfamily_independent {γ : Fin m → V}
    (h : LinearlyIndependent (K := K) α) (hs : Subfamily γ α) :
  letI : AddCommGroup V := VectorSpace.toAddCommGroup K V
  letI : Module K V := VectorSpace.toModule K V
  LinearlyIndependent (K := K) γ := by
  letI : AddCommGroup V := VectorSpace.toAddCommGroup K V
  letI : Module K V := VectorSpace.toModule K V
  obtain ⟨f, hf, heq⟩ := hs
  have hg : γ = α ∘ f := funext heq
  rw [hg, linearly_independent_iff_mathlib]
  exact ((linearly_independent_iff_mathlib α).mp h).comp f hf

theorem superfamily_dependent {γ : Fin m → V}
    (h : LinearlyDependent (K := K) α) (hs : Subfamily α γ) :
  letI : AddCommGroup V := VectorSpace.toAddCommGroup K V
  letI : Module K V := VectorSpace.toModule K V
  LinearlyDependent (K := K) γ := by
  letI : AddCommGroup V := VectorSpace.toAddCommGroup K V
  letI : Module K V := VectorSpace.toModule K V
  rw [linearly_dependent_iff_not_independent] at h ⊢
  intro hg
  exact h (subfamily_independent γ hg hs)

theorem singleton_independent (v : V) :
  letI : AddCommGroup V := VectorSpace.toAddCommGroup K V
  letI : Module K V := VectorSpace.toModule K V
  LinearlyIndependent (K := K) (fun _ : Fin 1 => v) ↔ v ≠ 0 := by
  letI : AddCommGroup V := VectorSpace.toAddCommGroup K V
  letI : Module K V := VectorSpace.toModule K V
  rw [linearly_independent_iff_mathlib]
  exact linearIndependent_unique_iff

theorem dependent_of_contains_zero (h : Contains α s.zero) :
  letI : AddCommGroup V := VectorSpace.toAddCommGroup K V
  letI : Module K V := VectorSpace.toModule K V
  LinearlyDependent (K := K) α := by
  letI : AddCommGroup V := VectorSpace.toAddCommGroup K V
  letI : Module K V := VectorSpace.toModule K V
  obtain ⟨i, hi⟩ := h
  rw [linearly_dependent_iff_not_mathlib]
  intro hind
  exact hind.ne_zero i hi

theorem dependent_of_repeated_vector (h : HasRepeat α) :
  letI : AddCommGroup V := VectorSpace.toAddCommGroup K V
  letI : Module K V := VectorSpace.toModule K V
  LinearlyDependent (K := K) α := by
  letI : AddCommGroup V := VectorSpace.toAddCommGroup K V
  letI : Module K V := VectorSpace.toModule K V
  obtain ⟨i, j, hij, heq⟩ := h
  rw [linearly_dependent_iff_not_mathlib]
  intro hind
  exact hij (hind.injective heq)

end Fulcrum

/-! ## Fulcrum 自有术语
模板索引对应完整 Lean 参数，包括隐式类型和实例；不重定义 Mathlib 术语宏。
`explicit` Style 保留完整参数视图，默认 Style 只展示教材所需的参数。
-/
snl_notation Fulcrum.VectorSpace => %#1 上有 #0 上的向量空间结构%
snl_notation Fulcrum.VectorSpace.add => $#4 + #5$ : [0, 0, 0, 0, 65, 66] -> 65
snl_notation Fulcrum.VectorSpace.zero => $\mathbf{0}_{#1}$
snl_notation Fulcrum.VectorSpace.smul => $#4 \cdot #5$ : [0, 0, 0, 0, 70, 71] -> 70
snl_notation Fulcrum.IsAdditiveInverse => %#4 是 #5 的加法逆元%
snl_notation Fulcrum.IsLinearRepresentation => %#5 可由向量族 #6 线性表示%
snl_notation Fulcrum.IsLinearRelation => $\sum_{i\in [#4]} #5(i)\,#6(i)=\mathbf{0}_{#1}$
snl_notation Fulcrum.NontrivialCoefficients => $\exists i\in [#2],\;#3(i)\ne 0$
snl_notation Fulcrum.LinearlyDependent => %向量族 #5 在 #1 中线性相关%
snl_notation Fulcrum.LinearlyIndependent => %向量族 #5 在 #1 中线性无关%
snl_notation Fulcrum.RepresentableByOthers => %#5(#6) 可由删去第 #6 项后的向量族线性表示%
snl_notation Fulcrum.UniqueRepresentation => %向量族 #5 在 #1 中的线性表示系数唯一%
snl_notation Fulcrum.Subfamily => %有限族 #3（长度 #2）是有限族 #4（长度 #1）的子族%
snl_notation Fulcrum.Contains => %#3 出现在长度为 #1 的有限族 #2 中%
snl_notation Fulcrum.HasRepeat => %长度为 #1 的有限族 #2 含有两个不同下标的相同向量%
snl_notation Fulcrum.VectorSpace.add_comm => %加法交换律%
snl_notation Fulcrum.VectorSpace.add_assoc => %加法结合律%
snl_notation Fulcrum.VectorSpace.add_zero => %加法恒等元%
snl_notation Fulcrum.VectorSpace.exists_add_inverse => %加法逆元存在性%
snl_notation Fulcrum.VectorSpace.smul_smul => %数乘结合律%
snl_notation Fulcrum.VectorSpace.smul_add => %数乘对向量加法的分配律%
snl_notation Fulcrum.VectorSpace.add_smul => %数乘对标量加法的分配律%
snl_notation Fulcrum.VectorSpace.one_smul => %数乘恒等元%
snl_notation Fulcrum.VectorSpace[explicit] => %Fulcrum.VectorSpace(#0, #1, #2)%
snl_notation Fulcrum.VectorSpace.zero[explicit] => %Fulcrum.VectorSpace.zero(#0, #1, #2, #3)%

#print Fulcrum.VectorSpace
#snl_const_widget Fulcrum.VectorSpace
#snl_const_widget Fulcrum.IsLinearRepresentation
#snl_const_widget Fulcrum.LinearlyDependent
#snl_const_widget Fulcrum.LinearlyIndependent
#snl_const_widget Fulcrum.dependent_iff_representable_by_others
