import Mathlib.Algebra.Algebra.Defs
import Mathlib.Algebra.Algebra.Hom
import Mathlib.Algebra.Field.Defs
import Mathlib.Algebra.Order.Ring.Defs
import Mathlib.Data.Countable.Defs
import Mathlib.Data.Fintype.Defs
import Mathlib.Logic.Encodable.Basic
import Mathlib.Logic.Nontrivial.Defs
import Mathlib.Logic.Unique
import Mathlib.Order.Hom.Basic
import Mathlib.Topology.Algebra.MulAction
import Mathlib.Topology.Algebra.Ring.Basic
import Mathlib.Topology.ContinuousMap.Defs
import Mathlib.Topology.MetricSpace.ProperSpace
import Mathlib.Topology.Separation.Connected
import Mathlib.Analysis.InnerProductSpace.Defs
import Mathlib.CategoryTheory.Adjunction.Basic
import Mathlib.CategoryTheory.Limits.IsLimit
import Mathlib.CategoryTheory.Monoidal.Category
import Mathlib.MeasureTheory.Constructions.BorelSpace.Basic
import Mathlib.MeasureTheory.Measure.MeasureSpace
import Mathlib.MeasureTheory.Measure.Typeclasses.Finite
import Mathlib.MeasureTheory.Measure.Typeclasses.Probability
import Mathlib.MeasureTheory.Measure.Typeclasses.SFinite

/-!
# 3B · Typeclasses and Mathematical Structures

This lecture first explains how Lean automates structure inheritance and instance search. It then
maps the principal Mathlib structure families used throughout algebra, order theory, topology,
metric geometry, category theory, and measure theory.

The lists below are deliberately hierarchy spines rather than exhaustive API catalogues: they keep
the canonical structures that introduce new data, laws, or compatibility layers, while leaving
specialized descendants to the relevant later course.
-/

set_option autoImplicit false

namespace Course3B

universe u v

/-! ## Structure Automation -/

/-! ### Class Derivation -/

/-- A course-local addition typeclass. -/
class CourseAdd (α : Type u) where
  add : α → α → α

#print CourseAdd
#print CourseAdd.add
#print Add

/-- A course-local multiplication interface. -/
class CourseMul (α : Type u) where
  mul : α → α → α

#print CourseMul
#print CourseMul.mul
#print Mul

/-- A course-local semigroup extends the operation class with associativity. -/
class CourseSemigroup (α : Type u) extends CourseMul α where
  mul_assoc : ∀ a b c : α, mul (mul a b) c = mul a (mul b c)

#print CourseSemigroup
#print CourseSemigroup.mul_assoc
#print Semigroup

/-- A course-local monoid derives the semigroup and multiplication interfaces automatically. -/
class CourseMonoid (α : Type u) extends CourseSemigroup α where
  one : α
  one_mul : ∀ a : α, mul one a = a
  mul_one : ∀ a : α, mul a one = a

#print CourseMonoid
#print CourseMonoid.toCourseSemigroup
#print Monoid

/-! ### Instance Synthesis -/

/-- Natural-number addition supplies a course-local monoid instance. -/
instance : CourseMonoid Nat where
  mul := Nat.add
  mul_assoc := Nat.add_assoc
  one := 0
  one_mul := Nat.zero_add
  mul_one := Nat.add_zero

-- `#synth T` is a command: it asks the elaborator to synthesize `T` immediately.
#synth CourseMonoid Nat
#synth CourseSemigroup Nat
#synth CourseMul Nat
#synth Monoid Nat

/-- `inferInstance` is a term whose expected type determines which instance Lean searches for. -/
def inferredCourseSemigroup : CourseSemigroup Nat := inferInstance

#print inferInstance
#print inferredCourseSemigroup

/-- The operation is recovered entirely from the synthesized instance. -/
def combine {α : Type u} [CourseMonoid α] (a b : α) : α := CourseMul.mul a b

#print combine
#eval combine 20 22

/-- A value that is not globally registered as an instance. -/
def unitCourseMonoid : CourseMonoid Unit where
  mul := fun _ _ => ()
  mul_assoc := by intros; rfl
  one := ()
  one_mul := by intros; rfl
  mul_one := by intros; rfl

/-- `letI` installs a let-bound value as a local instance for the following term. -/
example : CourseMonoid Unit := by
  letI : CourseMonoid Unit := unitCourseMonoid
  exact inferInstance

/-- `haveI` installs a proof/value as a local instance, commonly inside a proof. -/
example : CourseMul Unit := by
  haveI : CourseMonoid Unit := unitCourseMonoid
  exact inferInstance

/-! ### Output Parameters -/

/-- `outParam` marks `β` as an output inferred after instance search is driven by `α`. -/
class Convert (α : Type u) (β : outParam (Type v)) where
  convert : α → β

#print Convert
#print Convert.convert
#print outParam

instance : Convert Nat Int where
  convert := Int.ofNat

#synth Convert Nat Int
#check (inferInstance : Convert Nat Int)

/-- The result type is selected by the available `Convert` instance. -/
def convert {α : Type u} {β : Type v} [Convert α β] (x : α) : β := Convert.convert x

#print convert
-- `Nat` is the input; instance search fills the output metavariable with `Int`.
#check convert (7 : Nat)
#eval convert (7 : Nat)

/-- Without `outParam`, an unknown `β` remains an input that must be fixed before search. -/
class PlainConvert (α : Type u) (β : Type v) where
  convert : α → β

#print PlainConvert

/-- `outParam` is suitable only when each input has one canonical output. Multiple competing
instances with the same input would overlap because the output does not guide instance selection. -/
def convertDesignRule : String :=
  "Use outParam only when the input type canonically determines the output type."

#print convertDesignRule

/-! ## Mathematical Structures -/

/-! ### Algebraic Structures -/

-- Primitive additive and multiplicative interfaces.
#print Add
#print Mul
#print Zero
#print One
#print Neg
#print Inv
#print Sub
#print Div
#print Pow

-- Additive hierarchy.
#print AddSemigroup
#print AddCommSemigroup
#print AddLeftCancelSemigroup
#print AddRightCancelSemigroup
#print AddZeroClass
#print AddMonoid
#print AddLeftCancelMonoid
#print AddRightCancelMonoid
#print AddCancelMonoid
#print AddCommMonoid
#print AddMonoidWithOne
#print AddGroup
#print AddCommGroup

-- Multiplicative hierarchy.
#print Semigroup
#print CommSemigroup
#print LeftCancelSemigroup
#print RightCancelSemigroup
#print MulOneClass
#print Monoid
#print LeftCancelMonoid
#print RightCancelMonoid
#print CommMonoid
#print CancelMonoid
#print Group
#print CommGroup
#print MulZeroClass
#print MonoidWithZero
#print GroupWithZero
#print CommGroupWithZero

-- Additive and multiplicative operations meet in distributive structures.
#print Distrib
#print NonUnitalNonAssocSemiring
#print NonUnitalSemiring
#print NonAssocSemiring
#print Semiring
#print CommSemiring
#print NonUnitalNonAssocRing
#print NonUnitalRing
#print NonAssocRing
#print Ring
#print CommRing
#print DivisionSemiring
#print Semifield
#print DivisionRing
#print Field

-- Scalar-action structures connect algebraic objects.
#print SMul
#print MulAction
#print DistribMulAction
#print Module
#print Algebra

/-! ### Order Structures -/

-- Primitive relations and finite lattice operations.
#print LE
#print LT
#print Min
#print Max
#print Preorder
#print PartialOrder
#print LinearOrder
#print SemilatticeInf
#print SemilatticeSup
#print Lattice
#print DistribLattice

-- Bounds and completeness.
#print OrderBot
#print OrderTop
#print BoundedOrder
#print CompleteSemilatticeInf
#print CompleteSemilatticeSup
#print CompleteLattice
#print BooleanAlgebra
#print CompleteBooleanAlgebra

-- Compatibility between order and algebra.
#print IsOrderedAddMonoid
#print IsOrderedCancelAddMonoid
#print IsOrderedMonoid
#print IsOrderedCancelMonoid
#print IsOrderedRing
#print IsStrictOrderedRing

/-! ### Topological Structures -/

-- The topology itself and standard separation or compactness properties.
#print TopologicalSpace
#print T0Space
#print T1Space
#print T2Space
#print T25Space
#print T3Space
#print T4Space
#print CompactSpace
#print LocallyCompactSpace
#print ConnectedSpace
#print TotallyDisconnectedSpace

-- Compatibility between topology and algebraic operations.
#print ContinuousAdd
#print ContinuousMul
#print IsTopologicalAddGroup
#print IsTopologicalGroup
#print IsTopologicalSemiring
#print IsTopologicalRing
#print ContinuousSMul

/-! ### Metric Spaces -/

#print UniformSpace
#print PseudoEMetricSpace
#print EMetricSpace
#print PseudoMetricSpace
#print MetricSpace
#print SeminormedAddCommGroup
#print NormedAddCommGroup
#print NormedRing
#print NormedField
#print NormedSpace
#print InnerProductSpace
#print ProperSpace

/-! ### Finiteness and Decidability -/

-- Logical size and cardinality interfaces.
#print Nonempty
#print Inhabited
#print Subsingleton
#print Unique
#print Nontrivial
#print Finite
#print Fintype
#print Countable
#print Encodable

-- Propositions and relations carrying executable decision procedures.
#print Decidable
#print DecidableEq
#print DecidablePred
#print DecidableRel
#print BEq
#print LawfulBEq

/-! ### Category Theory -/

-- Concrete families of structure-preserving morphisms motivate the categorical abstraction.
#print AddMonoidHom
#print MonoidHom
#print RingHom
#print LinearMap
#print AlgHom
#print OrderHom
#print ContinuousMap
#print Measurable

-- Categories package objects and morphisms; functors and natural transformations preserve them.
#print CategoryTheory.CategoryStruct
#print CategoryTheory.Category
#print CategoryTheory.Functor
#print CategoryTheory.NatTrans
#print CategoryTheory.Iso
#print CategoryTheory.Adjunction
#print CategoryTheory.Limits.Cone
#print CategoryTheory.Limits.Cocone
#print CategoryTheory.Limits.IsLimit
#print CategoryTheory.Limits.IsColimit
#print CategoryTheory.MonoidalCategory

/-! ### Measure Spaces -/

#print MeasurableSpace
#print MeasureTheory.Measure
#print MeasureTheory.MeasureSpace
#print BorelSpace
#print MeasurableSingletonClass
#print MeasureTheory.IsFiniteMeasure
#print MeasureTheory.IsProbabilityMeasure
#print MeasureTheory.SFinite
#print MeasureTheory.SigmaFinite

end Course3B
