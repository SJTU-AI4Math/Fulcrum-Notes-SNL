import Lean4.Logic.term_macros
import Mathlib.Logic.Function.Basic
import Mathlib.Logic.Equiv.Defs

/-! Functions and equivalences. Set-restricted map properties live in Set Theory.
Separate applied styles preserve the final value argument of composition,
identity and constant functions; they do not confuse it with a hidden type.
Type annotations fill every input slot, so automatic Style matching distinguishes
function-valued and applied forms without dropping the final argument. -/
snl_notation Function.Injective[english] => %#2 is injective%
snl_notation Function.Surjective => %#2 is surjective%
snl_notation Function.Bijective => %#2 is bijective%
snl_notation Function.LeftInverse => %#2 is a left inverse of #3%
snl_notation Function.RightInverse => %#2 is a right inverse of #3%
snl_notation Function.HasLeftInverse => %#2 has a left inverse%
snl_notation Function.HasRightInverse => %#2 has a right inverse%
snl_notation Function.Involutive => %#1 is an involution%
snl_notation Equiv => $#0 \simeq #1$ : [51, 51] -> 50
snl_notation Function.comp => $\left(#3 : #1 \to #2\right) \circ \left(#4 : #0 \to #1\right)$ : [0, 0, 0, 91, 90] -> 90
snl_notation Function.comp[applied] => $\left(\left(#3 : #1 \to #2\right) \circ \left(#4 : #0 \to #1\right)\right)(#5)$
snl_notation id => $\mathrm{id}_{#0}$
snl_notation id[applied] => $\mathrm{id}_{#0}(#1)$
snl_notation Function.const => $\operatorname{const}_{#1 \to #0}(#2)$
snl_notation Function.const[applied] => $\operatorname{const}_{#1 \to #0}(#2)(#3)$
