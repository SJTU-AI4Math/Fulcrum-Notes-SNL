import Lean4.«Set Theory».term_macros
import Lean4.Functions.term_macros_CN

/-! Chinese projections of the existing text Styles; names, Styles and operand
indices are unchanged. Import after the base; select with `snl.language CN`. -/

-- Mathlib/
--   Data/
--     Finite/
--       Defs.lean
snl_notation "Set.Finite" CN => %#1 是有限集%
snl_notation "Set.Infinite" CN => %#1 是无限集%

-- Mathlib/
--   Data/
--     Set/
--       Defs.lean
snl_notation "Set.Subset"[english] CN => %#1 是 #2 的子集%
snl_notation "Set.Nonempty"[english] CN => %#1 非空%

-- Mathlib/
--   Data/
--     Set/
--       Operations.lean
snl_notation "Set.EqOn" CN => %#2 与 #3 在 #4 上相等%
snl_notation "Set.MapsTo" CN => %#2 将 #3 映入 #4%
snl_notation "Set.InjOn" CN => %#2 在 #3 上是单射%
snl_notation "Set.SurjOn" CN => %#4 的每个元素都是 #3 中某个元素在 #2 下的像%
snl_notation "Set.BijOn" CN => %#2 是从 #3 到 #4 的双射%
snl_notation "Set.LeftInvOn" CN => %#2 在 #4 上是 #3 的左逆%
snl_notation "Set.RightInvOn" CN => %#2 在 #4 上是 #3 的右逆%
snl_notation "Set.InvOn" CN => %#2 在 #4 上是 #3 的左逆，并在 #5 上是 #3 的右逆%

-- Mathlib/
--   Logic/
--     Pairwise.lean
snl_notation "Set.Pairwise" CN => %#2 对 #1 中每一对不同元素组成的有序对成立%
