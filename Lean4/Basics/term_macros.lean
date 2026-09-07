import Mathlib.Data.Rat.Defs
import SNL4Lean

/-! Elementary types and number systems not yet assigned a narrower chapter.
`Nat` is already provided by SNL4Lean. `[n]` denotes the zero-based finite type
`Fin n`, including the empty type when n = 0. -/
snl_notation OfNat.ofNat => $#1$
snl_notation Int => $\mathbb{Z}$
snl_notation Rat => $\mathbb{Q}$
snl_notation Bool => $\mathsf{Bool}$
snl_notation Prod => $#0 \times #1$ : [71, 71] -> 70
snl_notation Sum => $#0 \sqcup #1$ : [66, 66] -> 65
snl_notation Fin => $[#0]$
snl_notation Fin[english] => %The type of natural numbers less than #0%

/-! Primitive operation interfaces carry data only: no associativity, identity,
inverse, distributivity, or action laws are asserted here. Algebraic structures
and logical properties remain in their own chapters. All indices include the
full native type and instance arguments. Surface `+` remains HAdd.hAdd;
surface scalar multiplication uses HSMul.hSMul, not SMul.smul.
Only full-application default styles are added; bare and partial operation
values retain their complete trees but are not promised a complete display. -/
snl_notation Add => %#0 is equipped with a binary addition operation%
snl_notation Zero => %#0 is equipped with a designated zero element%
snl_notation SMul => %#1 is equipped with a scalar multiplication operation by #0%
snl_notation Mul => %#0 is equipped with a binary multiplication operation%
snl_notation One => %#0 is equipped with a designated one element%
snl_notation Sub => %#0 is equipped with a binary subtraction operation%
snl_notation Div => %#0 is equipped with a binary division operation%
snl_notation Neg => %#0 is equipped with a unary negation operation%
snl_notation Inv => %#0 is equipped with a unary inverse operation%
snl_notation Pow => %#0 is equipped with a power operation with exponents in #1%

snl_notation Add.add => $#2 + #3$ : [0, 0, 65, 66] -> 65
snl_notation Zero.zero => $0_{#0}$
snl_notation SMul.smul => $#3 \mathbin{\bullet} #4$ : [0, 0, 0, 74, 73] -> 73
snl_notation HSMul.hSMul => $#4 \mathbin{\bullet} #5$ : [0, 0, 0, 0, 74, 73] -> 73
snl_notation Neg.neg => $-#2$ : [0, 0, 75] -> 75
-- A second superscript inverse must group the first one: (x⁻¹)⁻¹.
snl_notation Inv.inv => $#2^{-1}$ : [0, 0, 1025] -> 1024

/-! Elementary type construction and projections, with ordered pair operands. -/
snl_notation Unit => $\mathsf{Unit}$
snl_notation Option => $\operatorname{Option}(#0)$
snl_notation Prod.mk => $\left(#2, #3\right)$
snl_notation Prod.fst => $\operatorname{fst}(#2)$
snl_notation Prod.snd => $\operatorname{snd}(#2)$

/-! Numeric conversion operations, not homomorphism or injectivity claims.
Int.toNat sends negative integers to zero; it is not an inverse on all Int. -/
snl_notation Int.ofNat => $\operatorname{ofNat}_{\mathbb{Z}}(#0)$
snl_notation Int.toNat => $\operatorname{toNat}(#0)$
snl_notation Nat.cast => $\left(#2 : #0\right)$
snl_notation Int.cast => $\left(#2 : #0\right)$
