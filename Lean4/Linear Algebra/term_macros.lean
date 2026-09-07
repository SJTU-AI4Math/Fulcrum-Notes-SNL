import Lean4.«Basic Algebra».term_macros
import Lean4.«Set Theory».term_macros

/-! ## Fulcrum 自有术语
模板索引对应完整 Lean 参数，包括隐式类型和实例；不重定义 Mathlib 术语宏。
默认 Style 只展示教材所需的参数；完整参数保留在树中，不另加抢占匹配的 Style。
-/
-- Lean4/
--   Linear Algebra/
--     LinearAlgebra.lean
snl_notation Fulcrum.VectorSpace => %#1 is a vector space over #0%
snl_notation Fulcrum.VectorSpace.add_comm => %Commutativity of addition%
snl_notation Fulcrum.VectorSpace.add_assoc => %Associativity of addition%
snl_notation Fulcrum.VectorSpace.add_zero => %Additive identity%
snl_notation Fulcrum.VectorSpace.exists_add_inverse => %Existence of additive inverses%
snl_notation Fulcrum.VectorSpace.smul_smul => %Associativity of scalar multiplication%
snl_notation Fulcrum.VectorSpace.smul_add => %Distributivity over vector addition%
snl_notation Fulcrum.VectorSpace.add_smul => %Distributivity over scalar addition%
snl_notation Fulcrum.VectorSpace.one_smul => %Identity scalar action%
snl_notation Fulcrum.IsAdditiveInverse => %#4 is the negation of #5%
snl_notation Fulcrum.IsLinearRepresentation => %#5 is a linear combination of #6%
snl_notation Fulcrum.IsLinearRelation => $\sum_{i\in [#4]} #5_i\,#6_i=\mathbf{0}_{#1}$
snl_notation Fulcrum.NontrivialCoefficients => $\exists i\in [#2],\;#3_i\ne 0$
snl_notation Fulcrum.LinearlyDependent => %#5 is linearly dependent in #1%
snl_notation Fulcrum.LinearlyIndependent => %#5 is linearly independent in #1%
snl_notation Fulcrum.RepresentableByOthers => %#5(#6) is a linear combination of the remaining family after deleting the entry at index #6%
snl_notation Fulcrum.UniqueRepresentation => %#5 in #1 has unique coefficients for every representable vector%
snl_notation Fulcrum.Subfamily => %The family #3 (length #2) is a subfamily of #4 (length #1)%
snl_notation Fulcrum.Contains => %#3 occurs in the length-#1 family #2%
snl_notation Fulcrum.HasRepeat => %The length-#1 family #2 has equal vectors at distinct indices%
