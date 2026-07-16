# Real Analysis (实分析) — SNL 起稿

> Source: Fulcrum-Notes-Typst/Mathematics/26-RealAnalysis/main.typ
> Route: Royden 4th ed Part I (Lebesgue framework)
> Date: 2026-07-13

## §1 Lebesgue 可测函数 (Lebesgue Measurable Functions)

### 基本定义
- **def**: Lebesgue 可测函数 — f 可测 iff ∀c:EReal, {x | f(x) <= c} 可测 [entry: real-analysis.def.measurable]
- **prop**: 等价定义 (≤, <, ≥, >, 开集原像, =) [entry: real-analysis.prop.measurable-iff]
- **prop**: 可测函数代数 (加法/数乘/乘法封闭) [entry: real-analysis.prop.measurable-algebra]
- **counterexample**: 可测函数的复合不一定可测 [entry: real-analysis.cex.measurable-composite]

### 常见的可测函数
- **example**: 连续函数 Lebesgue 可测 [entry: real-analysis.ex.continuous-measurable]
- **example**: 单调函数 Lebesgue 可测 [entry: real-analysis.ex.monotone-measurable]

### 几乎处处相等与依测度等价
- **def**: 几乎处处相等 (f, g ae equal) [entry: real-analysis.def.ae-equal]
- **def**: 依测度等价 [entry: real-analysis.def.measure-equiv]
- **prop**: 依测度等价是等价关系 [entry: real-analysis.prop.measure-equiv-equiv]
- **prop**: 可测性沿依测度等价传递 [entry: real-analysis.prop.measure-equiv-measurable]

### 简单逼近定理
- **def**: 简单函数 (simple function) [entry: real-analysis.def.simple-function]
- **lemma**: 简单逼近引理 [entry: real-analysis.lem.simple-approximation]
- **thm**: 简单逼近定理 [entry: real-analysis.thm.simple-approximation]

## §2 可测函数列的收敛 (Convergence of Measurable Functions)

### 几乎处处收敛
- **def**: 几乎处处收敛 [entry: real-analysis.def.ae-convergence]
- **def**: 几乎一致收敛 [entry: real-analysis.def.au-convergence]
- **prop**: 几乎一致收敛 ⟹ 几乎处处 + 依测度收敛 [entry: real-analysis.prop.au-implies-ae-measure]
- **def**: 依测度收敛 [entry: real-analysis.def.measure-convergence]
- **prop**: 有限测度集上 ae ⟹ 依测度收敛 [entry: real-analysis.prop.ae-implies-measure-finite]

### 三大经典定理
- **thm**: Egorov 定理 [entry: real-analysis.thm.egorov]
- **counterexample**: Egorov 有限测度条件不可去 [entry: real-analysis.cex.egorov-finite]
- **construction**: Egorov 反例构造 [entry: real-analysis.con.egorov-counterexample]
- **thm**: Lusin 定理 [entry: real-analysis.thm.lusin]
- **thm**: Riesz 定理 [entry: real-analysis.thm.riesz]

## §3 Lebesgue 积分 (Lebesgue Integral)

### 简单函数的积分
- **def**: 简单函数积分 [entry: real-analysis.def.simple-integral]
- **prop**: 线性/单调性 [entry: real-analysis.prop.simple-integral-properties]

### 非负可测函数的积分
- **def**: 非负可测函数积分 [entry: real-analysis.def.nonnegative-integral]
- **prop**: 线性/单调/可数可加 [entry: real-analysis.prop.nonnegative-integral-properties]

### 一般可测函数的积分
- **def**: Lebesgue 积分 [entry: real-analysis.def.lebesgue-integral]
- **def**: Lebesgue 可积 [entry: real-analysis.def.lebesgue-integrable]
- **prop**: 有限测度集上有界可测 ⟹ 可积 [entry: real-analysis.prop.bounded-finite-integrable]
- **prop**: 线性 [entry: real-analysis.prop.lebesgue-integral-linearity]
- **prop**: 单调性 [entry: real-analysis.prop.lebesgue-integral-monotone]
- **prop**: 三角不等式 [entry: real-analysis.prop.lebesgue-integral-triangle]
- **thm**: Riemann 可积的 Lebesgue 刻画 [entry: real-analysis.thm.riemann-lebesgue-char]
- **prop**: Riemann 与 Lebesgue 积分兼容 [entry: real-analysis.prop.riemann-lebesgue-compat]

### 收敛定理
- **lemma**: 一致收敛下积分极限交换 [entry: real-analysis.lem.uniform-convergence-swap]
- **thm**: 有界收敛定理 [entry: real-analysis.thm.bounded-convergence]
- **thm**: Levi 单调收敛定理 [entry: real-analysis.thm.monotone-convergence]
- **lemma**: Fatou 引理 [entry: real-analysis.lem.fatou]
- **thm**: Lebesgue 控制收敛定理 [entry: real-analysis.thm.dominated-convergence]
- **cor**: 广义控制收敛定理 [entry: real-analysis.cor.generalized-dominated-convergence]

## §4 微分与不定积分 (Differentiation & Indefinite Integral)

### Vitali 覆盖与单调函数的可微性
- **def**: Vitali 覆盖 [entry: real-analysis.def.vitali-cover]
- **lemma**: Vitali 覆盖引理 [entry: real-analysis.lem.vitali-covering]
- **thm**: Lebesgue 定理 (单调函数 ae 可微) [entry: real-analysis.thm.monotone-ae-differentiable]

### 有界变差函数
- **def**: 全变差 [entry: real-analysis.def.total-variation]
- **def**: 有界变差 [entry: real-analysis.def.bounded-variation]
- **thm**: Jordan 分解 [entry: real-analysis.thm.jordan-decomposition]
- **prop**: BV ⟹ ae 可微 [entry: real-analysis.prop.bv-ae-differentiable]

### 绝对连续与微积分基本定理
- **def**: 可测集上的全变差 [entry: real-analysis.def.total-variation-measurable]
- **prop**: V_E(f) 是 Borel 测度 [entry: real-analysis.prop.total-variation-borel-measure]
- **def**: 绝对连续 [entry: real-analysis.def.absolutely-continuous]
- **prop**: Royden 刻画 [entry: real-analysis.prop.absolutely-continuous-iff]
- **prop**: Lipschitz ⟹ AC [entry: real-analysis.prop.lipschitz-implies-ac]
- **prop**: AC ⟹ 一致连续 [entry: real-analysis.prop.ac-implies-uniformly-continuous]
- **prop**: AC ⟹ BV [entry: real-analysis.prop.ac-implies-bv]
- **prop**: BV([a,b]) 是 Banach 空间 [entry: real-analysis.prop.bv-banach]
- **def**: 不定积分 [entry: real-analysis.def.indefinite-integral]
- **prop**: 不定积分是绝对连续 [entry: real-analysis.prop.indefinite-integral-ac]
- **thm**: Lebesgue 微分定理 [entry: real-analysis.thm.lebesgue-differentiation]
- **thm**: 微积分基本定理 (Lebesgue 形式) [entry: real-analysis.thm.ftc-lebesgue]

## §5 乘积测度与 Fubini 定理 (Product Measure & Fubini)

- **def**: 乘积 σ-代数 [entry: real-analysis.def.product-sigma-algebra]
- **def**: 截面 [entry: real-analysis.def.cross-section]
- **def**: 乘积测度 [entry: real-analysis.def.product-measure]
- **thm**: Tonelli 定理 [entry: real-analysis.thm.tonelli]
- **thm**: Fubini 定理 [entry: real-analysis.thm.fubini]

## §6 L^p 空间 (L^p Spaces)

- **def**: 本性有界 [entry: real-analysis.def.essentially-bounded]
- **def**: 本性上确界 [entry: real-analysis.def.essential-supremum]
- **def**: L^p 空间 [entry: real-analysis.def.lp-space]
- **thm**: Hölder 不等式 [entry: real-analysis.thm.hoelder]
- **thm**: Minkowski 不等式 [entry: real-analysis.thm.minkowski]
- **thm**: Riesz–Fischer 定理 [entry: real-analysis.thm.riesz-fischer]
- **prop**: L^p 的可分性 [entry: real-analysis.prop.lp-separability]

---

## Terminology list (→ Phase 2 macros)

| Concept | Proposed macro | Kind |
|---------|---------------|------|
| Lebesgue 可测 | `RealAnalysis.measurable` | const |
| 简单函数 | `RealAnalysis.simple` | const |
| 几乎处处 | `RealAnalysis.almostEverywhere` | const |
| 几乎处处收敛 | `RealAnalysis.aeConvergence` | const |
| 几乎一致收敛 | `RealAnalysis.auConvergence` | const |
| 依测度收敛 | `RealAnalysis.measureConvergence` | const |
| 简单函数积分 | `RealAnalysis.simpleIntegral` | const |
| 非负可测函数积分 | `RealAnalysis.nonnegativeIntegral` | const |
| Lebesgue 积分 | `RealAnalysis.lebesgueIntegral` | const |
| Lebesgue 可积 | `RealAnalysis.lebesgueIntegrable` | const |
| Vitali 覆盖 | `RealAnalysis.vitaliCover` | const |
| 全变差 | `RealAnalysis.totalVariation` | const |
| 有界变差 | `RealAnalysis.boundedVariation` | const |
| 绝对连续 | `RealAnalysis.absolutelyContinuous` | const |
| 不定积分 | `RealAnalysis.indefiniteIntegral` | const |
| 乘积σ-代数 | `RealAnalysis.productSigmaAlgebra` | const |
| 截面 | `RealAnalysis.crossSection` | const |
| 乘积测度 | `RealAnalysis.productMeasure` | const |
| 本性有界 | `RealAnalysis.essentiallyBounded` | const |
| 本性上确界 | `RealAnalysis.essentialSupremum` | const |
| L^p 空间 | `RealAnalysis.Lp` | const |
| Hölder 不等式 | `RealAnalysis.hoelder` | const |
| Minkowski 不等式 | `RealAnalysis.minkowski` | const |
