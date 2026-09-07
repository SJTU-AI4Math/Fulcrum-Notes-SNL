import Lean4.Logic.term_macros
import Lean4.Basics.term_macros_CN

/-! Chinese projections of the existing text Styles; names, Styles and operand
indices are unchanged. Import after the base; select with `snl.language CN`. -/

-- Init/
--   Prelude.lean
snl_notation "Nonempty"[english] CN => %#0 有一个元素%
snl_notation "Decidable" CN => %#0 是可判定的%
snl_notation "DecidableEq" CN => %#0 上的相等关系是可判定的%

-- Init/
--   Core.lean
snl_notation "Subsingleton" CN => %#0 至多有一个元素%

-- Mathlib/
--   Logic/
--     IsEmpty/
--       Defs.lean
snl_notation "IsEmpty" CN => %#0 为空%

-- Mathlib/
--   Logic/
--     Nontrivial/
--       Defs.lean
snl_notation "Nontrivial" CN => %#0 至少有两个不同的元素%

-- Mathlib/
--   Logic/
--     Unique.lean
snl_notation "Unique" CN => %#0 恰有一个元素%
