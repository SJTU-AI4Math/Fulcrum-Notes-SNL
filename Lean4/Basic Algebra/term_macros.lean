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

snl_notation Semigroup => %#0 has a semigroup structure%
snl_notation CommSemigroup => %#0 has a commutative semigroup structure%
snl_notation Monoid => %#0 has a monoid structure%
snl_notation CommMonoid => %#0 has a commutative monoid structure%
snl_notation Group => %#0 has a group structure%
snl_notation CommGroup => %#0 has a commutative group structure%
snl_notation AddSemigroup => %#0 has an additive semigroup structure%
snl_notation AddCommSemigroup => %#0 has a commutative additive semigroup structure%
snl_notation AddMonoid => %#0 has an additive monoid structure%
snl_notation AddCommMonoid => %#0 has a commutative additive monoid structure%
snl_notation AddGroup => %#0 has an additive group structure%
snl_notation AddCommGroup => %#0 has a commutative additive group structure%
snl_notation Semiring => %#0 has a semiring structure%
snl_notation Ring => %#0 has a ring structure%
snl_notation CommRing => %#0 has a commutative ring structure%
snl_notation Field => %#0 has a field structure%
snl_notation Units => %units of #0%
snl_notation MonoidHom => %multiplication- and identity-preserving maps from #0 to #1%
snl_notation RingHom => %addition-, multiplication-, zero-, and identity-preserving maps from #0 to #1%
