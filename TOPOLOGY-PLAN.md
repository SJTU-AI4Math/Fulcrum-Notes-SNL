# Point-Set Topology — SNL Plan

> 源：`Fulcrum-Notes-Typst/Mathematics/54-Topology/main.typ` + `export.typ`
> 惯例：`SNL-CONVENTIONS.md` + `SET-THEORY-PLAN.md` 的 type-theoretic 风格

## 设计原则

- **Set(T) := T → Prop**：集合是类型索引的谓词
- **纯宏树**：`content.snl` = 宏组合，无 `%…%` 文本块，无 `$…$` LaTeX 块
- **结构性宏优先**：用 `def-hyp` / `def` / `thm-hyp` / `hyp-list` 表达定义结构
- **Binder 绑定**：所有变量用 `@` 标注作用域
- **复用已有宏**：`Set.mem`、`Set.subset`、`Set.union`、`Set.inter`、`Set.sep-typed`、`Logic.forall-typed`、`Logic.exists-typed`、`Logic.and`、`Logic.or`、`Logic.implies`、`Logic.neg`、`Type.judge`、`Type.to`、`Type.apply`

## 可复用宏一览

| 域 | 宏 | 用途 |
|----|-----|------|
| Set | `Set.mem` | `x ∈ S` |
| Set | `Set.subset` | `A ⊆ B` |
| Set | `Set.union` | `A ∪ B` |
| Set | `Set.inter` | `A ∩ B` |
| Set | `Set.sep-typed` | `{x : T \| P(x)}` |
| Set | `Set.emptyset` | `∅` |
| Set | `Set.compl` | 补集 |
| Set | `Set.powerset` | `𝒫(S)` |
| Logic | `Logic.forall-typed` | `∀ x : T, P(x)` |
| Logic | `Logic.exists-typed` | `∃ x : T, P(x)` |
| Logic | `Logic.and` | `P ∧ Q` |
| Logic | `Logic.or` | `P ∨ Q` |
| Logic | `Logic.implies` | `P ⇒ Q` |
| Logic | `Logic.neg` | `¬P` |
| Logic | `Logic.false` | `⊥` |
| Type | `Type.judge` | `x : T` |
| Type | `Type.to` | `T → Prop` |
| Type | `Type.apply` | `f(x)` 函数应用 |

## 宏包 `Topology.json`

参见 `Topology.json` 文件（Phase 2 产物）——包含所有拓扑学专用的 term macros。

## Library 结构

```
Topology.sec.topology (section — 拓扑空间基础)
├── Topology.ctxt.1 (context: S, τ)
│   ├── Topology.ctxt.S  (Type.judge(@S, Type))
│   └── Topology.ctxt.tau (Type.judge(@τ, Set(Set(S))))
├── Topology.subsec.basicConcepts (subsection — 基本概念)
│   ├── Topology.def.topology (拓扑 — 定义)
│   ├── Topology.def.topologicalSpace (拓扑空间 — 定义)
│   ├── Topology.def.openSet (开集 — 定义)
│   ├── Topology.def.closedSet (闭集 — 定义)
│   ├── Topology.def.neighborhood (邻域 — 定义)
│   ├── Topology.def.neighborhoodFamily (邻域系 — 定义)
│   ├── Topology.def.interior (内部 — 定义)
│   │   ├── Topology.prop.interiorPoint (内部点 ⇔ 邻域)
│   │   └── Topology.prop.openIffInteriorSelf (A 开 ⇔ A = Int(A))
│   ├── Topology.def.closure (闭包 — 定义)
│   │   ├── Topology.prop.closureClosed (闭包是闭集)
│   │   └── Topology.prop.closedIffClosureSelf (A 闭 ⇔ A = Cl(A))
│   ├── Topology.def.closurePoint (闭包点 — 定义)
│   ├── Topology.def.boundary (边界 — 定义)
│   ├── Topology.def.generatedTopology (生成拓扑 — 定义)
│   ├── Topology.def.topologicalBasis (拓扑基 — 定义)
│   ├── Topology.def.subspaceTopology (子空间拓扑 — 定义)
│   └── Topology.def.productTopology (积拓扑 — 定义)
├── Topology.subsec.limit (subsection — 极限)
│   ├── Topology.def.deletedNeighborhood (去心邻域 — 定义)
│   ├── Topology.def.limitPoint (极限点/聚点 — 定义)
│   ├── Topology.def.derivedSet (导集 — 定义)
│   ├── Topology.def.isolatedPoint (孤立点 — 定义)
│   │   └── Topology.prop.derivedClosure (E ∪ E' = Cl(E))
│   │   └── Topology.prop.closedIffContainsLimitPoints (E 闭 ⇔ E' ⊆ E)
│   ├── Topology.def.denseSet (稠密集 — 定义)
│   ├── Topology.def.nowhereDense (稀疏集/无处稠密集 — 定义)
│   ├── Topology.def.selfDense (自稠密集 — 定义)
│   ├── Topology.def.perfectSet (完美集 — 定义)
│   ├── Topology.def.seqLimit (序列极限 — 定义)
│   ├── Topology.def.seqConvergence (序列收敛 — 定义)
│   └── Topology.def.sequentialCompactness (序列紧性 — 定义)
├── Topology.subsec.connectedness (subsection — 连通性)
│   ├── Topology.def.connected (连通性 — 定义)
│   ├── Topology.def.pathConnected (道路连通 — 定义)
│   └── Topology.prop.pathConnectedImpliesConnected (道路连通 ⇒ 连通)
├── Topology.subsec.compactness (subsection — 紧致性)
│   ├── Topology.def.openCover (开覆盖 — 定义)
│   ├── Topology.def.compactness (紧致性 — 定义)
│   ├── Topology.def.countablyCompact (可数紧性 — 定义)
│   ├── Topology.prop.compactImpliesCountablyCompact (紧致 ⇒ 可数紧)
│   ├── Topology.prop.seqCompactImpliesCountablyCompact (序列紧 ⇒ 可数紧)
│   ├── Topology.thm.heineBorel (Heine-Borel 定理)
│   └── Topology.prop.closedSubsetOfCompact (紧致集的闭子集紧致)
├── Topology.subsec.examples (subsection — 拓扑空间的例子)
│   ├── Topology.example.trivialTopology (平凡拓扑)
│   ├── Topology.example.discreteTopology (离散拓扑)
│   ├── Topology.example.orderTopology (序拓扑)
│   └── Topology.example.usualTopologyR (实数上的通常拓扑)
├── Topology.example.sierpinskiSpace (Sierpinski 空间 — 在 T0 处)

Topology.sec.continuousMap (section — 连续映射)
├── Topology.ctxt.map (context: X, Y, τ_X, τ_Y, f)
│   ├── Topology.ctxt.X (Type.judge(@X, Type))
│   ├── Topology.ctxt.Y (Type.judge(@Y, Type))
│   ├── Topology.ctxt.tauX (Type.judge(@τ_X, Set(Set(X))))
│   ├── Topology.ctxt.tauY (Type.judge(@τ_Y, Set(Set(Y))))
│   └── Topology.ctxt.f (Type.judge(@f, Type.to(X, Y)))
├── Topology.subsec.mapLimit (subsection — 映射的极限与连续性)
│   ├── Topology.def.mapLimit (映射极限 — 定义)
│   ├── Topology.def.mapConvergence (映射收敛 — 定义)
│   ├── Topology.prop.heineReduction (Heine 归结原理)
│   ├── Topology.def.continuityAtPoint (点处连续性 — 定义)
│   ├── Topology.def.continuousMap (连续映射 — 定义)
│   ├── Topology.prop.continuityViaNeighborhood (邻域定义)
│   ├── Topology.prop.continuityViaPreimage (原像定义)
│   ├── Topology.prop.compositionPreservesContinuity (复合保持连续性)
│   ├── Topology.prop.continuousPreservesConnectedness (保持连通性)
│   ├── Topology.prop.continuousPreservesCompactness (保持紧致性)
│   └── Topology.def.lipschitzContinuity (Lipschitz 连续性)
├── Topology.subsec.homeomorphism (subsection — 同胚映射)
│   ├── Topology.def.openMap (开映射 — 定义)
│   ├── Topology.def.homeomorphism (同胚映射 — 定义)
│   ├── Topology.def.homeomorphic (同胚 — 定义)
│   └── Topology.prop.inverseOfContinuousOnCompact (紧空间上连续逆映射)
└── Topology.subsec.separation (subsection — 分离性)
    ├── Topology.def.T0 (T0/Kolmogorov 空间 — 定义)
    ├── Topology.def.T1 (T1/Frechet 空间 — 定义)
    │   └── Topology.prop.T1Equivalent (T1 ⇔ 单点集闭)
    ├── Topology.def.T2 (T2/Hausdorff 空间 — 定义)
    │   ├── Topology.prop.limitUniqueInT2 (T2 中极限唯一)
    │   ├── Topology.prop.compactClosedInT2 (T2 中紧致集是闭集)
    │   ├── Topology.prop.nestedCompactInT2 (紧集套定理)
    │   └── Topology.prop.continuousPreservesConvergenceInT2 (连续保持收敛)
    └── Topology.example.sierpinskiSpace (Sierpinski 空间)

## 条目数量估算

- **Section**: 2
- **Context**: 6 (ctxt.1, ctxt.S, ctxt.tau, ctxt.map, ctxt.XY...)
- **Subsection**: 7
- **Definition**: ~30
- **Property/Theorem**: ~18
- **Example**: ~5
- **Remark**: ~8 (作为 remark 条目)

**总计约 70-75 个条目**。

## 关键语义映射

| Typst 元素 | SNL 条目 kind | SNL 宏 |
|-----------|-------------|-------|
| `#结构(uuid: "Topology", ...)` | `definition` | `def-hyp` 以谓词形式定义 |
| `#结构(uuid: "TopologicalSpace", ...)` | `definition` | `def-hyp` 以结构体形式定义 |
| `#定义(uuid: "OpenSet", ...)` | `definition` | `def-hyp` |
| `#性质(uuid: "InteriorPoint", ...)` | `property` | `thm-hyp` |
| `#定理(uuid: "HeineBorel", ...)` | `theorem` | `thm-hyp` |
| `#注[...]` | `remark` | `remark` 条目 |
| `#例(uuid: "TrivialTopology", ...)` | `example` | `example` 条目 |
| `optionLink("Topology", [拓扑])` | 宏 `Topology.topology` | — |
| `optionLink("NeighborhoodFamily", ...)` | 宏 `Topology.Nbr` | — |
| 式中的 `Nbr(x)` | `Topology.Nbr(x)` | 算子宏 |