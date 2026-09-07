import Lean4.Functions.term_macros
import Lean4.Logic.term_macros_CN

/-! Chinese projections of the existing text Styles; names, Styles and operand
indices are unchanged. Import after the base; select with `snl.language CN`. -/

-- Init/
--   Data/
--     Function.lean
snl_notation "Function.Injective"[english] CN => %#2 是单射%
snl_notation "Function.Surjective" CN => %#2 是满射%
snl_notation "Function.LeftInverse" CN => %#2 是 #3 的左逆%
snl_notation "Function.HasLeftInverse" CN => %#2 有左逆%
snl_notation "Function.RightInverse" CN => %#2 是 #3 的右逆%
snl_notation "Function.HasRightInverse" CN => %#2 有右逆%

-- Mathlib/
--   Logic/
--     Function/
--       Basic.lean
snl_notation "Function.Involutive" CN => %#1 是对合%

-- Mathlib/
--   Logic/
--     Function/
--       Defs.lean
snl_notation "Function.Bijective" CN => %#2 是双射%
