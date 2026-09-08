import Mathlib.Data.Rat.Defs
import SNL4Lean

/-! Elementary types and number systems not yet assigned a narrower chapter.
`Nat` is already provided by SNL4Lean. `[n]` denotes the zero-based finite type
`Fin n`, including the empty type when n = 0. -/
/-! Primitive operation interfaces carry data only: no associativity, identity,
inverse, distributivity, or action laws are asserted here. Algebraic structures
and logical properties remain in their own chapters. All indices include the
full native type and instance arguments. Surface `+` remains HAdd.hAdd;
surface scalar multiplication uses HSMul.hSMul, not SMul.smul.
Only full-application default styles are added; bare and partial operation
values retain their complete trees but are not promised a complete display. -/

-- A second superscript inverse must group the first one: (x⁻¹)⁻¹.

/-! Elementary type construction and projections, with ordered pair operands. -/

/-! Numeric conversion operations, not homomorphism or injectivity claims.
Int.toNat sends negative integers to zero; it is not an inverse on all Int. -/

-- Init/
--   Prelude.lean
snl_notation Unit => $\mathbf{1}$
snl_notation Prod => $#0 \times #1$ : [71, 71] -> 70
snl_notation Prod.mk => $\left(#2, #3\right)$
snl_notation Prod.fst => $#2.1$
snl_notation Prod.snd => $#2.2$
snl_notation Bool => $\mathsf{Bool}$
snl_notation OfNat.ofNat => $#1$
snl_notation HSMul.hSMul => $#4#5$ : [0, 0, 0, 0, 74, 73] -> 73
snl_notation Zero => $0_{#0}$
snl_notation Zero.zero => $0_{#0}$
snl_notation One => $1_{#0}$
snl_notation Add => $+_{#0}$
snl_notation Add.add => $#2 + #3$ : [0, 0, 65, 66] -> 65
snl_notation Sub => $-_{#0}$
snl_notation Mul => $\cdot_{#0}$
snl_notation Neg => $-_{#0}()$
snl_notation Neg.neg => $-#2$ : [0, 0, 75] -> 75
snl_notation Div => $\div_{#0}$
snl_notation Inv => ${}^{-1}_{#0}$
snl_notation Inv.inv => $#2^{-1}$ : [0, 0, 1025] -> 1024
snl_notation Pow => $\text{\textasciicircum}_{#0,#1}$
snl_notation SMul => $\cdot_{#0,#1}$
snl_notation SMul.smul => $#3#4$ : [0, 0, 0, 74, 73] -> 73
snl_notation Fin => $[#0]$
snl_notation Fin[english] => %The type of natural numbers less than #0%
snl_notation Option => $\operatorname{Option}(#0)$

-- Init/
--   Core.lean
snl_notation Sum => $#0 \sqcup #1$ : [66, 66] -> 65

-- Init/
--   Data/
--     Cast.lean
snl_notation Nat.cast => $\left(#2 : #0\right)$

-- Init/
--   Data/
--     Int/
--       Basic.lean
snl_notation Int => $\mathbb{Z}$
snl_notation Int.ofNat => $\operatorname{ofNat}_{\mathbb{Z}}(#0)$
snl_notation Int.toNat => $\operatorname{toNat}(#0)$
snl_notation Int.cast => $\left(#2 : #0\right)$

-- Init/
--   Data/
--     Rat/
--       Basic.lean
snl_notation Rat => $\mathbb{Q}$

-- Mathlib/
--   Algebra/
--     BigOperators/
--       Group/
--         Finset/
--           Defs.lean
snl_notation Finset.sum => $\sum_{#3} #4$
