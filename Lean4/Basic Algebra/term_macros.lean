import Lean4.Functions.term_macros
import Mathlib.Algebra.Group.Defs
import Mathlib.Algebra.Ring.Defs
import Mathlib.Algebra.Field.Defs
import Mathlib.Algebra.Group.Units.Defs
import Mathlib.Algebra.Group.Hom.Defs
import Mathlib.Algebra.Ring.Hom.Defs
import Mathlib.Algebra.BigOperators.Group.Finset.Defs
import Mathlib.Data.Fintype.Defs
import SNL4Lean.Delab.Registry

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

/-! Consumer-owned notation. SNL4Lean production has no Mathlib dependency.
The raw Finset.sum remains a five-argument constant application. Only a fully
applied genuine lambda gets this view; filter remains an ordinary index set. -/
open Lean Meta SNL4Lean

snl_notation sum => $\sum_{#0\in #1} #2$
snl_notation sum[univ] => $\sum_{#0} #2$

namespace SNL4LeanConsumer

@[snl_app_delab Finset.sum]
meta def delabFinsetSum : SnlAppDelab := fun expr tree => do
  let expr := expr.consumeMData
  unless expr.getAppFn.isConstOf ``Finset.sum do return none
  let args := expr.getAppArgs
  unless args.size == 5 do return none
  let .lam .. := args[4]! | return none
  unless tree.children.size == 5 do return none
  let lambda := tree.children[4]!
  unless lambda.macro_name == "Type.lambda" && lambda.children.size == 3 do return none
  let indexSet := args[3]!
  let univ := indexSet.getAppFn.isConstOf ``Finset.univ
  return some {
    macro_name := "sum"
    kind := "rule"
    style_name? := if univ then some "univ" else none
    mdata := Json.mkObj [
      ("leanDelabOrigin", toJson "Finset.sum"),
      ("leanBinderScope", Json.mkObj [("binder", toJson (0 : Nat)), ("bodies", toJson (#[2] : Array Nat))])]
    children := #[
      withLeanSourcePath lambda.children[0]! #[4, 0],
      withLeanSourcePath tree.children[3]! #[3],
      withLeanSourcePath lambda.children[2]! #[4, 2]]
  }

end SNL4LeanConsumer
