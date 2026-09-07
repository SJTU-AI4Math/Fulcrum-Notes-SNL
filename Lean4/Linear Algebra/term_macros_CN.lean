import Lean4.«Linear Algebra».term_macros
import Lean4.«Basic Algebra».term_macros_CN
import Lean4.«Set Theory».term_macros_CN

/-! Chinese projections of the existing text Styles; names, Styles and operand
indices are unchanged. Import after the base; select with `snl.language CN`. -/

-- Lean4/
--   Linear Algebra/
--     LinearAlgebra.lean
snl_notation "Fulcrum.VectorSpace" CN => %#1 是 #0 上的向量空间%
snl_notation "Fulcrum.VectorSpace.add_comm" CN => %加法交换律%
snl_notation "Fulcrum.VectorSpace.add_assoc" CN => %加法结合律%
snl_notation "Fulcrum.VectorSpace.add_zero" CN => %加法单位元%
snl_notation "Fulcrum.VectorSpace.exists_add_inverse" CN => %加法逆元的存在性%
snl_notation "Fulcrum.VectorSpace.smul_smul" CN => %数乘结合律%
snl_notation "Fulcrum.VectorSpace.smul_add" CN => %数乘对向量加法的分配律%
snl_notation "Fulcrum.VectorSpace.add_smul" CN => %数乘对标量加法的分配律%
snl_notation "Fulcrum.VectorSpace.one_smul" CN => %单位标量作用%
snl_notation "Fulcrum.IsAdditiveInverse" CN => %#4 是 #5 的加法逆元%
snl_notation "Fulcrum.IsLinearRepresentation" CN => %#5 是 #6 的线性组合%
snl_notation "Fulcrum.LinearlyDependent" CN => %#5 在 #1 中线性相关%
snl_notation "Fulcrum.LinearlyIndependent" CN => %#5 在 #1 中线性无关%
snl_notation "Fulcrum.RepresentableByOthers" CN => %#5(#6) 是从该族中删去索引 #6 处的项后剩余向量的线性组合%
snl_notation "Fulcrum.UniqueRepresentation" CN => %#1 中的 #5 对每个可表示的向量都给出唯一的表示系数%
snl_notation "Fulcrum.Subfamily" CN => %向量族 #3（长度为 #2）是 #4（长度为 #1）的子族%
snl_notation "Fulcrum.Contains" CN => %#3 出现在长度为 #1 的向量族 #2 中%
snl_notation "Fulcrum.HasRepeat" CN => %长度为 #1 的向量族 #2 在不同索引处有相等的向量%
