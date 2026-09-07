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
