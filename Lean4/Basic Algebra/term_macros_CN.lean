import Lean4.«Basic Algebra».term_macros
import Lean4.Functions.term_macros_CN

/-! Chinese projections of the existing text Styles; names, Styles and operand
indices are unchanged. Import after the base; select with `snl.language CN`. -/

-- Mathlib/
--   Algebra/
--     Field/
--       Defs.lean
snl_notation "Field" CN => %#0 是域%

-- Mathlib/
--   Algebra/
--     Group/
--       Defs.lean
snl_notation "Semigroup" CN => %#0 是半群%
snl_notation "AddSemigroup" CN => %#0 是加法半群%
snl_notation "CommSemigroup" CN => %#0 是交换半群%
snl_notation "AddCommSemigroup" CN => %#0 是交换加法半群%
snl_notation "AddMonoid" CN => %#0 是加法幺半群%
snl_notation "Monoid" CN => %#0 是幺半群%
snl_notation "AddCommMonoid" CN => %#0 是交换加法幺半群%
snl_notation "CommMonoid" CN => %#0 是交换幺半群%
snl_notation "Group" CN => %#0 是群%
snl_notation "AddGroup" CN => %#0 是加法群%
snl_notation "AddCommGroup" CN => %#0 是交换加法群%
snl_notation "CommGroup" CN => %#0 是交换群%

-- Mathlib/
--   Algebra/
--     Group/
--       Units/
--         Defs.lean
snl_notation "Units" CN => %#0 的可逆元%

-- Mathlib/
--   Algebra/
--     Ring/
--       Defs.lean
snl_notation "Semiring" CN => %#0 是半环%
snl_notation "Ring" CN => %#0 是环%
snl_notation "CommRing" CN => %#0 是交换环%
