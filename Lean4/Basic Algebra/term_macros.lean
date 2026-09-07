import Lean4.Functions.term_macros
import Mathlib.Algebra.Group.Defs
import Mathlib.Algebra.Ring.Defs
import Mathlib.Algebra.Field.Defs
import Mathlib.Algebra.Group.Units.Defs
import Mathlib.Algebra.Group.Hom.Defs
import Mathlib.Algebra.Ring.Hom.Defs

/-! Basic algebra terminology, using native Mathlib declarations only.
All operand indices refer to FULL Lean applications, including instance arguments.
The sixteen structure classes each have exactly one type operand, #0.
Units has [type, Monoid instance]; the hom types have [domain, codomain,
domain structure, codomain structure]. Prose deliberately hides those instances.
No infix formulas are introduced, so no precedence metadata is needed.
-/

snl_notation Semigroup => %#0 is a semigroup%
snl_notation CommSemigroup => %#0 is a commutative semigroup%
snl_notation Monoid => %#0 is a monoid%
snl_notation CommMonoid => %#0 is a commutative monoid%
snl_notation Group => %#0 is a group%
snl_notation CommGroup => %#0 is a commutative group%
snl_notation AddSemigroup => %#0 is an additive semigroup%
snl_notation AddCommSemigroup => %#0 is a commutative additive semigroup%
snl_notation AddMonoid => %#0 is an additive monoid%
snl_notation AddCommMonoid => %#0 is a commutative additive monoid%
snl_notation AddGroup => %#0 is an additive group%
snl_notation AddCommGroup => %#0 is a commutative additive group%
snl_notation Semiring => %#0 is a semiring%
snl_notation Ring => %#0 is a ring%
snl_notation CommRing => %#0 is a commutative ring%
snl_notation Field => %#0 is a field%
snl_notation Units => %units of #0%
snl_notation MonoidHom => $\Hom_{\mathsf{Monoid}}(#0, #1)$
snl_notation RingHom => $\Hom_{\mathsf{Ring}}(#0, #1)$
