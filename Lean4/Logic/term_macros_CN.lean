import Lean4.Logic.term_macros
import Lean4.Basics.term_macros_CN

/-! Chinese projections of the existing text Styles; names, Styles and operand
indices are unchanged. Import after the base; select with `snl.language CN`. -/

-- Init/Prelude.lean
snl_notation Nonempty[english] CN => %#0 非空%
snl_notation Decidable CN => %#0 可判定%
snl_notation DecidableEq CN => %#0 上等式可判定%

-- Init/Core.lean
snl_notation Subsingleton CN => %#0 是单元素类型%

-- Mathlib/Logic/IsEmpty/Defs.lean
snl_notation IsEmpty CN => %#0 为空%

-- Mathlib/Logic/Nontrivial/Defs
snl_notation Nontrivial CN => %#0 非单元素类型%

-- Mathlib/Logic/Unique
snl_notation Unique CN => %#0 是构造性单元素类型%
