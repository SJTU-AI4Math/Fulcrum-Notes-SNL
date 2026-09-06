import Mathlib.Algebra.Group.Defs
import SNL4Lean

snl_macro "Semigroup" "const" "text" "#0 has Semigroup structure"
snl_macro "Semigroup.mul_assoc" "const" "text" "Associativity"
snl_macro "outParam" "const" "text" "#0"
snl_macro "HMul" "const" "text" "HMul #0 #1 #2"
snl_macro "Mul.mul" "const" "formula_inline" "#0 \\cdot #1"
snl_macro "Lean.proj" "rule" "text" "#0.#1"

/-! Semigroup defined in Mathlib -/
#print Semigroup
#snl_const_widget Semigroup
