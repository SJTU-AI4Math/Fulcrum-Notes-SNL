# Fulcrum's Math Notes Ecosystem

本文件作为 Fulcrum 数学笔记的规范，保留在仓库根目录，作为作者和 Agent 的统一 convention 入口。其他文档中的命名约定与本文件冲突时，以本文件为准。

写作的基本规范是，主分支任何提交必须保证可以通过 `snl validate` 检查，否则请先开分支后让 Agent 完成检查再提交。

## SNL-Lean 同步规范

1. 一个条目被 Fulcrum 笔记收容的标准是存在 SNL 条目。Lean 是可选项，而非必须项。
2. Lean 文件中的代码必须在 SNL 文件中有恰当的条目指向该位置。这不仅包括常量声明，也包括记号、语境、元编程程序等等。即：接受有 SNL 而无 Lean，但不接受有 Lean 而无 SNL。

## 命名原则

本规范区分 Library 身份名、Entry ID、Macro name、entry kind 和 macro kind。显示标题可以使用中英文，不代替机器身份名。

- Library 按文档或学科组织；Entry 和 Macro 按概念的语义归属组织。Library、Package、命名空间不必同名，也不要求一一对应。
- Entry 和 Macro 尽量兼容 Mathlib 的命名风格，不另造与之平行的学科缩写命名体系。
- kind 表达类别，Tag 表达来源，Pointer 定位 Lean 源码；不把这些信息混入概念身份名。
- 允许 Entry 与 Macro 同名，例如两者都叫 `Set.union`。这不允许同一种实体内部出现重复身份，也不自动建立两者的语义关联；关联仍需显式记录。
- 命名空间与磁盘目录是不同层次。本规范不要求重排 Lean 文件；`Lean4/Basic Algebra/` 保持为 `Lean4/` 的直属子目录。

## Library 命名规范

Library 身份名使用大驼峰 `UpperCamelCase`，例如 `LinearAlgebra`、`SetTheory`、`TypeTheory`。章节编排和显示标题独立于身份名。

## Entry 与 Macro 命名规范

*此处 Mathlib 泛指 v4.28.0 下的 Lean 标准库 + Mathlib。*

### Mathlib 兼容边界

1. 若 Entry 或 Macro 所指称的概念与某个 Lean 常量精确对应，采用该常量的完整 Lean 名称，包括命名空间和大小写；不另加 `Mathlib.` 前缀、领域缩写或 kind 段。
2. 是否来自或精确对应 Mathlib，使用 Tag 区分，不通过命名空间区分。具体来源 Tag 的键名另行统一，本规范不据此创建新 Tag。
3. 精确对应须核对对象、参数及其语义、假设和陈述；中文标题相同、数学上相关或存在某种等价，均不足以判定精确对应。
4. 不允许语义不同的概念占用已有 Lean 常量的完整名称并冒充该常量。此时应取能说明差异的自有名称。
5. 沿用实际名称，包括现有例外，不为统一外观修改 Lean 名称。Macro 名称对齐不代表模板参数已对齐；隐式类型参数、实例参数和显式参数的次序需另行核对。

例如：集合并的 Entry 和 Macro 均可名为 `Set.union`，其 Entry kind 为 `def`，Macro kind 为 `const`；并的结合律 Entry 使用 `Set.union_assoc`。类别从 `thm` 调整为 `ppt` 不应导致身份改名。

### 未直接对应 Lean 常量的概念

1. 先调研邻近概念在固定版本 Mathlib 中的命名，再采用相容的语义命名空间和名称。不要机械套用 `<学科缩写>.<类别>.<名称>`。
2. 优先按具体对象组织，而非要求一门学科的所有内容共用一个前缀。根级名字也可以是合法的完整名称。
3. `Set.*` 适合集合相关概念；`Type.*` 可以作为 Fulcrum 自有类型论语法、判断及元概念的组织方向，但它不是 Mathlib 统一的类型论命名空间。具体自有名称仍应逐项设计，不把候选名称当作已有 Lean 声明。
4. 其他领域命名空间同样先调研再定；此前按英文首字母统一缩写领域的方案，不再作为 Entry 或 Macro 的强制规则。

### 大小写与词形

新名称参考 Mathlib 的规则；已有常量以其实际名称为准：

| 名称所表达的对象 | 风格 | 示例 |
|---|---|---|
| 类型、结构、类、谓词 | `UpperCamelCase` | `Group`、`LinearMap`、`Function.Injective` |
| 普通对象、运算、函数 | `lowerCamelCase` | `Set.union`、`MonoidHom.toOneHom` |
| 定理、引理等证明 | `snake_case`，保留引用名称中必要的大小写 | `Set.union_assoc`、`mul_assoc`、`MonoidHom.toOneHom_injective` |

函数按返回值的类别命名；不能仅凭 Entry kind 为 `def` 就认定使用小驼峰。名称用点表达语义命名空间，用下划线连接定理名称中的成分，不插入 `def`、`thm` 等类别段。

## Entry kind 词表

下表为约定的 kind ID，类别不再进入 Entry ID。

| 中文 | 完整名称 | kind ID |
|---|---|---|
| 章 | section | `sec` |
| 节 | subsection | `subsec` |
| 定义 | definition | `def` |
| 公理 | axiom | `axm` |
| 引理 | lemma | `lma` |
| 定理 | theorem | `thm` |
| 推论 | corollary | `crl` |
| 性质 | property | `ppt` |
| 注 | remark | `rmk` |
| 例 | example | `xmp` |
| 反例 | counterexample | `cxmp` |
| 构造 | construction | `cstr` |
| 证明 | proof | `prf` |
| 问题 | problem | `pbm` |
| 语境 | context | `ctxt` |

构造子（constructor）归入 `def`，不设独立 `ctor` kind。构造过程（construction）仍保留 `cstr`，二者不混同。

## Macro kind 命名规范

Macro kind 使用简短小写名字。当前配置中的词表为 `rule`、`const`、`sub`、`binder`、`bvar`、`fvar`；它与 Entry kind 词表相互独立。

kind 不只是展示标签：其中绑定、变量和辅助子树等 kind 具有运行时行为。修改名称或另增数学概念分类前，须核对当前 SNL-Basics 契约，不得假设重命名后行为自动保留。`fvar` 不表示已证明某种数学或 Lean 意义上的 `sorry`。

## Mathlib 命名空间调研参考

以下是固定版本源码中的实际例子，不是要求每门学科统一使用的前缀表：

| 内容 | 实际命名示例 |
|---|---|
| 集合 | `Set`、`Set.union`、`Set.mem_union`、`Set.union_assoc` |
| 逻辑、类型与函数 | `And`、`Eq`、`And.intro`、`Eq.refl`、`Function.Injective`、`Prod.fst` |
| 代数结构 | 根级 `Semigroup`、`Monoid`、`Group`、`mul_assoc` |
| 线性代数 | `Module`、`Submodule`、`LinearIndependent`、`Module.Basis` |
| 拓扑 | 根级 `TopologicalSpace`、`IsOpen`、`Continuous` |
| 测度论 | 根级 `MeasurableSpace`、`Measurable`，以及 `MeasureTheory.Measure` |
| 分析 | 根级 `HasDerivAt`、`deriv` |
| 范畴论 | `CategoryTheory.Category`、`CategoryTheory.Functor` |

参考来源：

- [Mathlib 官方命名指南](https://leanprover-community.github.io/contribute/naming.html)（在线指南可能继续更新）。
- 本项目固定 Mathlib v4.28.0，revision `8f9d9cff6bd728b17a24e163c9402775d9e6a365`。
- [Set 定义](https://github.com/leanprover-community/mathlib4/blob/8f9d9cff6bd728b17a24e163c9402775d9e6a365/Mathlib/Data/Set/Defs.lean)、[Set 定理](https://github.com/leanprover-community/mathlib4/blob/8f9d9cff6bd728b17a24e163c9402775d9e6a365/Mathlib/Data/Set/Basic.lean)。
- [代数结构](https://github.com/leanprover-community/mathlib4/blob/8f9d9cff6bd728b17a24e163c9402775d9e6a365/Mathlib/Algebra/Group/Defs.lean)、[Module.Basis](https://github.com/leanprover-community/mathlib4/blob/8f9d9cff6bd728b17a24e163c9402775d9e6a365/Mathlib/LinearAlgebra/Basis/Defs.lean)。
- [拓扑基本定义](https://github.com/leanprover-community/mathlib4/blob/8f9d9cff6bd728b17a24e163c9402775d9e6a365/Mathlib/Topology/Defs/Basic.lean)、[可测空间](https://github.com/leanprover-community/mathlib4/blob/8f9d9cff6bd728b17a24e163c9402775d9e6a365/Mathlib/MeasureTheory/MeasurableSpace/Defs.lean)、[测度](https://github.com/leanprover-community/mathlib4/blob/8f9d9cff6bd728b17a24e163c9402775d9e6a365/Mathlib/MeasureTheory/Measure/MeasureSpaceDef.lean)。
- [导数](https://github.com/leanprover-community/mathlib4/blob/8f9d9cff6bd728b17a24e163c9402775d9e6a365/Mathlib/Analysis/Calculus/Deriv/Basic.lean)、[范畴](https://github.com/leanprover-community/mathlib4/blob/8f9d9cff6bd728b17a24e163c9402775d9e6a365/Mathlib/CategoryTheory/Category/Basic.lean)、[函子](https://github.com/leanprover-community/mathlib4/blob/8f9d9cff6bd728b17a24e163c9402775d9e6a365/Mathlib/CategoryTheory/Functor/Basic.lean)。

## 宏格式规范

具体模板、参数及 Style 格式另行补充；命名规范不替代运行时参数契约。

## 规范与迁移的边界

本次修订确立后续命名规范，不声称现有 `.SNL_Doc` 已完成迁移。旧 kind ID、实体 ID 和引用须另行通过 Toolkit 公共 API 做完整迁移并验证，不因修改本文件而自动改变。未经单独确认，不批量改动实体、引用、Package、Library 或磁盘目录。
