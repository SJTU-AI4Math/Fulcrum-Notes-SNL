import Mathlib.Algebra.Group.Defs
import SNL4Lean

snl_notation Semigroup => %#0 has Semigroup structure%
snl_notation Semigroup.mul_assoc => %Associativity%
snl_notation outParam => %#0%
snl_notation HMul => %HMul #0 #1 #2%
snl_notation Mul.mul => $#0 \cdot #1$
snl_macro { name := "Lean.proj", kind := "rule", mode := "text", template := "#0.#1" }

/-! Semigroup defined in Mathlib -/
#print Semigroup
#snl_const_widget Semigroup
