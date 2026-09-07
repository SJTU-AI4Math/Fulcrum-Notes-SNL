import Lean4.Basics.term_macros
import Mathlib.Logic.Unique
import Mathlib.Logic.ExistsUnique
import Mathlib.Logic.Nontrivial.Defs
import Mathlib.Logic.IsEmpty.Defs

/-! Logic and elementary properties of types. Connectives already provided by
SNL4Lean retain their default styles. Full implicit parameters remain in the tree. -/
snl_notation False => $\bot$
snl_notation Ne => $#1 \ne #2$ : [0, 51, 51] -> 50
snl_notation ExistsUnique => $\exists! #1$
snl_notation Decidable => %#0 is decidable%
snl_notation DecidableEq => %Equality on #0 is decidable%
snl_notation Subsingleton => %#0 has at most one element%
snl_notation Nontrivial => %#0 has at least two distinct elements%
snl_notation Unique => %#0 has a unique element%
snl_notation IsEmpty => %#0 is empty%
snl_notation Nonempty[english] => %#0 has an element%
