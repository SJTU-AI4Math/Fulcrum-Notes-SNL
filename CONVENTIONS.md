# Fulcrum-Notes-SNL CONVENTIONS

本文件是本仓库的**唯一规范入口**，供作者与 Agent 共用。它合并并取代此前的
`FMNeco.md`、`SNL-CONVENTIONS.md` 与 `.SNL_Doc/CONVENTIONS.md` 三份文件。

- **唯一权威**：任何文档、注释或历史提交中与本文件冲突的命名、身份或写法约定，
  一律以本文件为准。
- **适用范围**：`.SNL_Doc/` 工作区内的 Entry、Macro、Package、Library、Style，
  以及围绕它们的提交、验证、版本管理与书写行为。
- **本文件只写规则**，以及规则所针对的失败模式；不记录具体个案或事故复盘。

全文分四层：纪律（§1–§2）、身份与命名（§3–§11）、书写语法（§12–§13）、
SNL-Lean 同步（§14），外加本仓内容纪律（§15）与调研附录。

---

## 目录

1. [提交与验证纪律](#1-提交与验证纪律)
2. [版本管理纪律（branch 与 worktree）](#2-版本管理纪律branch-与-worktree)
3. [命名原则（总纲）](#3-命名原则总纲)
4. [Entry ID 命名规范](#4-entry-id-命名规范)
5. [Macro ID 命名规范](#5-macro-id-命名规范)
6. [Library 命名规范](#6-library-命名规范)
7. [Entry kind 词表](#7-entry-kind-词表)
8. [Macro kind 词表](#8-macro-kind-词表)
9. [Package 归属](#9-package-归属)
10. [Style 命名](#10-style-命名)
11. [语义来源 / I18N / 构造子](#11-语义来源--i18n--构造子)
12. [书写规范（SNL 语法层）](#12-书写规范snl-语法层)（含 §12.11 定义必须是显式的、
    §12.12 人名书写）
13. [标签（tags）](#13-标签tags)
14. [SNL-Lean 同步](#14-snl-lean-同步)
15. [本仓内容纪律：不写习题与引导](#15-本仓内容纪律不写习题与引导)
- [附录：Mathlib 调研参考](#附录mathlib-调研参考)

---

## 1. 提交与验证纪律

### 1.1 提交前最低要求

1. `snl validate --json` 返回 `ok: true`、`issues: []`。
2. **`validate` 通过不等于阅读器能载。** 改动过内容的，必须上浏览器看一次受影响
   Library 的渲染。
3. 执行 `snl` 的二进制必须是当前 Toolkit 树构建出的那一份，否则现场会出现
   「代码对、Spec 全，但结果对不上」的矛盾。核查方法与修法见 §1.3。

主分支上任何提交都必须保证能通过 `snl validate` 检查；做不到就先开任务分支
（见 §2），由 Agent 完成检查再合入。

### 1.2 验证纪律

1. `snl validate --json` 必须返回 `ok: true` 且 `issues: []`，并且 `counts.entry`
   按预期变化——这能抓住静默失败。
2. **`validate` 通过不代表阅读器能载。** 每次内容改动都要在阅读器 URL 上以截图确认。
   阅读器监听工作区、保存即重载，无需重启。
3. Library 页面显示的是 **Entry** 树，宏不在其中。写了宏却看到空白的
   `0 entries` 页面是预期现象，不是缺陷。
4. `macro rename` 之后，**逐一复核每个调用点的实参次序**。改名只动名字、从不动实参，
   `validate` 也不会报告由此产生的错配。用 `snl entry latex` 逐 Entry 确认。
5. 当现象与源码矛盾时，先确认**执行的是哪个二进制**（见 §1.3），再怀疑代码。

### 1.3 工具契约：执行的是哪个 snl

本节所有规则都假设：真正执行的 CLI 是当前 Toolkit 树构建出的那一份。否则 `PATH`
可能解析到过期副本，它会静默接受当前校验器拒绝的数据，表现为「源码与行为对不上」
且无法解释。

```bash
which snl; readlink -f $(which snl)
```

典型失败：某份手工拷贝的旧 bundle 早于某个校验器，它接受当前构建拒绝的数据，
并报告 `valid: true`、零 issue。

Toolkit 仓库**自带构建产物**；`git pull` 即可交付当前 CLI，无需构建步骤。
把启动器指向随仓库交付的 bundle，而不是自己保留一份拷贝：

```bash
cp -p ~/.local/bin/snl.mjs ~/.local/bin/snl.mjs.bak-$(date +%Y%m%d)
ln -sfn ~/workspace/cat/SNL-Agent-Toolkit/dist/cli/snl.mjs ~/.local/bin/snl.mjs
readlink -f ~/.local/bin/snl.mjs
```

`snl` 启动器保持为薄包装，只负责 `exec` `snl.mjs`；要替换的是符号链接，不是包装器。

### 1.4 阅读器看目录，不看分支

阅读器服务的是 `--root` 目录**磁盘上**的内容。它监听文件系统、保存即重载，
因此永不需要重启；但同样无法知道该目录当时 checkout 的分支是不是你刚推上去的那一个。
由此产生一类「看起来像阅读器坏了、其实是 checkout 错了」的失败模式：阅读器以
`--root <repo>` 长期运行，某个 agent 在同一目录 checkout 了任务分支，成果落在别处
的 `main` 上，于是页面不变——什么都没坏，阅读器只是在忠实地服务一棵较旧的树。

**诊断。** 先定位服务进程及其 `--root`，再问该目录当前在哪个 commit：

```bash
ps aux | grep "snl.mjs --root" | grep -v grep
cd <root> && git log --oneline -1 && git branch --show-current
```

**确认。** 把服务中的树与期望的 commit 对比：

```bash
git merge-base --is-ancestor <expected-commit> HEAD && echo current || echo stale
```

**规则。**
- 不得把阅读器的 `--root` 目录当作临时 checkout。分支工作放到独立 worktree 或
  独立 clone 里做（见 §2.2）。
- 长期运行的阅读器应指向一个始终停在其应展示分支上的目录。分支必须移动时，
  要显式地对账阅读器根目录——一个已经跑了几小时的阅读器，不构成「它的树是新的」的证据。
- 在阅读器根目录里跑 `validate` 只报告那棵树，因此那里的干净结果只能证明阅读器
  当前服务的内容是干净的。

**复核：** 在声称「页面没更新」之前，按序定位服务进程、它的 `--root`、
以及该目录的当前 commit。

---

## 2. 版本管理纪律（branch 与 worktree）

> 总原则：**改前先拉 main + 建 branch，改后过核验，推 main，清理 branch，
> 下次要改再重开同名 branch。**

### 2.1 分支生命周期（一次性）

1. **改前**：`git pull` 更新 `main`，再从 `main` 建一个任务分支。
2. **改中**：在任务分支上完成全部编辑；`main` 上不直接积累未验证的改动。
3. **改后**：过核验——`snl validate --json` 加上浏览器渲染确认（见 §1）。
4. **推 main**：核验通过后，把成果推回 `main`。
5. **清理 branch**：推完即删除该任务分支（本地与远端）。
6. **下次要改**：**重新开一个同名任务分支**，从最新的 `main` 起。

- 任务分支**一次性使用**：一根分支只承载一轮任务，不在旧分支上反复叠加多轮改动。
- 因为「下次重开同名分支」，分支名必须表达**任务**而非人，且可复用、可预期。
- `main` 任何提交都必须能通过 `snl validate`（§1.1）。

### 2.2 worktree 与多 agent 协作

- 本仓库同时存在多个 worktree（`git worktree list` 可查）。不同 agent 各占一个
  worktree，互不切换、互不代管对方的目录。
- 每个 worktree 只在分配给它的任务上工作；不要跨 worktree 改内容。
- 因为分支是一次性的、任务完成即清理，**同一分支名在任意时刻至多被一个 worktree
  占用**。某 worktree 正使用分支 `B` 时，其他 worktree 不得再 checkout `B`：
  要么等它推完 `main`、清理分支后重开，要么改用另一个分支名。
- 谁在哪干活由 worktree 归属决定：**一个 worktree 对应一个任务、一个 agent**。
- 阅读器的 `--root` 不得用作临时 checkout（见 §1.4）；分支工作一律放到独立
  worktree 或独立 clone。

### 2.3 并发探测

动手前先探测当前占用，再决定在哪里、开哪根分支：

- `git worktree list`——看有哪些 worktree、各自在什么分支、指向什么 commit。
- 在自己所在目录 `git branch --show-current`——确认确实在预期分支上。
- `git status --porcelain`——确认没有未清理的改动。
- 若目标分支已被别的 worktree checkout，按 §2.2 处理，不要强行复用。
- 若 `main` 在动手期间被他人推进，先 `git pull` 对齐再继续。

---

## 3. 命名原则（总纲）

本规范区分 Library 身份名、Entry ID、Macro name、entry kind 和 macro kind。
显示标题可以使用中英文，不代替机器身份名。

- Library 按文档或学科组织；Entry 和 Macro 按概念的语义归属组织。
  Library、Package、命名空间不必同名，也不要求一一对应。
- Entry 和 Macro 尽量兼容 Mathlib 的命名风格，不另造与之平行的学科缩写命名体系。
- kind 表达类别，Tag 表达来源，Pointer 定位 Lean 源码；不把这些信息混入概念身份名。
- 允许 Entry 与 Macro 同名，例如两者都叫 `Set.union`。这不允许同一种实体内部出现
  重复身份，也不自动建立两者的语义关联；关联仍需显式记录。
- 命名空间与磁盘目录是不同层次。本规范不要求重排 Lean 文件；
  `Lean4/Basic Algebra/` 保持为 `Lean4/` 的直属子目录。

### 3.1 规范与迁移的边界

本文件确立后续命名规范，不声称现有 `.SNL_Doc` 已完成迁移。旧 kind ID、实体 ID
和引用须另行通过 Toolkit 公共 API 做完整迁移并验证，不因修改本文件而自动改变。
未经单独确认，不批量改动实体、引用、Package、Library 或磁盘目录。

---

## 4. Entry ID 命名规范

### 4.1 概念类 Entry：id 与 Macro 名逐字相同

**概念类 Entry 的 id 必须与它对应 Macro 的名字同步**，逐字相同，包括命名空间与大小写。
不做「宏用裸名、条目带 `Domain.kindAbbrev.` 前缀」的两套写法。

例：概念与 Mathlib 重合时，宏名取 Mathlib 裸名 `MetricSpace`（见 §5.1），
**条目 id 也就是 `MetricSpace`**，不写成 `Topology.def.metricSpace`。

- 概念类 Entry 的类别由 `kind` 字段承载（§7），不由 id 承载。
- **概念类 Entry 的 id 不含 kind 段。** `def`、`thm`、`ppt`、`rmk` 是 `kind`
  字段的取值，不是名字成分。`Foo.def.bar`（有概念宏、却把类别焊进名字）不是合规
  的新概念 id：有概念宏就应是 `Foo.bar`；属于结构性 Entry 才用 §4.2 的
  `Foo.<kindAbbrev>.bar`。§4.3 列出的旧身份是兼容基线，不是模板。
- Macro 名称对齐不代表模板参数已对齐；隐式类型参数、实例参数和显式参数的次序
  需另行核对（§5.1）。

### 4.2 结构性 Entry：`Domain.kindAbbrev.slug`

**只有**没有对应数学概念宏的结构性 Entry 才使用 kindAbbrev 段；凡有概念宏的
Entry 一律走 §4.1，id 与宏名逐字相同、不含类别段。结构性 Entry 不参与同步，
仍用 `Domain.kindAbbrev.slug` 形：

```text
entryId := Domain "." kindAbbrev "." slug ("." facet)*
```

| kind | kindAbbrev |
|---|---|
| section | `sec` |
| subsection | `subsec` |
| example | `xmp` |
| counterexample | `cxmp` |
| remark | `rmk` |
| problem | `pbm` |
| context | `ctxt` |
| proof | `prf` |

（`kindAbbrev` 取 §7 词表中的 kind ID。）

上表是最常见的一批，**不是 kind 的穷举**。任何结构性 Entry 的 `kindAbbrev` 都取 §7
词表里该 kind 的 ID——包括表中未列出的 `ppt`、`lma`、`crl`、`cstr`、`axm` 等。
仓库里既有的旧缩写（`DG.lem.*` 的 `lem`、`Measure.prop.*` 的 `prop`、`Type.rl.*`）
属 §4.3 的兼容基线，**不得复制进新 id**。

失败模式：同一 Library 里既有旧 `X.prop.foo`、又有规范要求的新 `X.ppt.foo`，id 的
`kindAbbrev` 段不再指示 kind，检索与归类同时失效。

**复核：** 对新 id，把 `kindAbbrev` 段与 §7 词表逐字比对；旧缩写只允许出现在 §4.3
列出的兼容身份上。

- `Domain` 是按语义归属的稳定拥有者（`BasicAnalysis`、`Type`、`Lambda`、`Set`、
  `Logic`、`Algebra` 等），与其存储或展示所在的 Entry Package、Library 无关。
- `slug` 与每个额外 `facet` 都是 ASCII `lowerCamelCase`；缩写按单词归一
  （`utlcDesign`、`skiComplete`）。显示用的大写留在本地化标题里，绝不进 id。
- 新 id 各段之间用点，`slug` / `facet` 内部用 `lowerCamelCase`；已有的连字符 id
  是兼容身份，不是模板。
- proof Entry 使用配置的 proof kind；其父陈述由图中边记录，而不是一个错配的
  定理段：`BasicAnalysis.prf.bolzanoWeierstrass`。

### 4.3 迁移边界与渐进采纳

- 已存在的旧式概念类 id（如 `Topology.def.IsOpen`、`Lambda.ppt.*`、`Type.cxmp.*`、
  `Type.rl.*`）属**兼容基线**，只在其整个语义族被显式、原子地迁移时一并改掉；
  不为此单独批量重命名。不要把这些旧缩写复制进新 id。
- 规范语法先约束**新**身份。迁移某旧身份时，若任何图、关系、`source.entries`、
  Package、SNL 调用或引用、权威快照仍指向旧名，则**失败关闭**（fail closed），
  不得放行。
- id 是终身身份。当前 Extension 没有通用的 Entry / Macro 改名命令，因此改名是本仓库
  特定的迁移：要在一次受评审的改动里枚举并更新规范记录与 hash 路径、
  Entry Package manifest、Library 图、relationships、Macro 的 `source.entries`、
  每一处 SNL 调用或引用，以及全部权威快照。**绝不做盲目的文本替换**，也绝不由
  id 前缀推断归属。
- 目前没有原生别名（alias）字段；除非有外部受检的迁移映射或契约相同的 Macro 包装
  真正提供兼容，否则不要声称向后兼容。

---

## 5. Macro ID 命名规范

### 5.1 Mathlib 同名原则（含裸名白名单）

*此处 Mathlib 泛指 v4.28.0 下的 Lean 标准库 + Mathlib。*

1. 若 Entry 或 Macro 所指称的概念与某个 Lean 常量精确对应，采用该常量的
   **完整 Lean 名称，包括命名空间和大小写**；不另加 `Mathlib.` 前缀、领域缩写或
   kind 段。

   例：`TopologicalSpace.IsSeparable`、`TopologicalSpace.IsTopologicalBasis`、
   `Bornology.IsBounded`、`Set.Frontier`——命名空间是该常量完整名的一部分，
   **不得省略**。

   与 §4.1 同步条款的关系：Entry id 与 Macro 名逐字相同，两者**都**取 Mathlib 的
   完整名。故裸名 `IsBounded` 是错的，应为 `Bornology.IsBounded`。

   **例外（裸名白名单）**：当且仅当 Mathlib 该常量本身就在**根命名空间**下
   （无前缀）时，才取裸名。已确认的根级常量包括 `IsOpen`、`IsClosed`、
   `Continuous`、`ContinuousAt`、`IsConnected`、`IsPathConnected`、
   `TopologicalSpace`、`T2Space`、`T0Space`、`T1Space`、`Dense`、`IsOpenMap`、
   `IsClosedMap`、`IsCompact`、`closure`、`frontier`、`interior`、`ClusterPt`、
   `MetricSpace`、`Homeomorph`、`diam`、`heineBorel`。
2. 是否来自或精确对应 Mathlib，用 Tag 区分（§13），不用命名空间区分。
   具体来源 Tag 的键名另行统一，本规范不据此创建新 Tag。
3. 精确对应须核对对象、参数及其语义、假设和陈述；中文标题相同、数学上相关或
   存在某种等价，均不足以判定精确对应。
4. 不允许语义不同的概念占用已有 Lean 常量的完整名称并冒充该常量；此时应取能
   说明差异的自有名称。
5. **有数学语义的「记号实体」可取自 Mathlib 的记号名（文件 / 语法设施名），
   即便它不是常量。** 例如 `VecNotation` 对应 Mathlib 的
   `Mathlib/Data/Fin/VecNotation.lean`（那个文件定义的是
   `syntax "![" term,* "]"` 与 `vecCons` / `vecEmpty` 一族，**本身不是一个常量**）。
   判据有两条，**须同时满足**：
   - **该概念在数学上有实质语义**，不是纯实现细节——`VecNotation` 记的是
     「有限序列 / 向量组」这一数学对象，故可作实体名。
   - **不与任何 Mathlib 常量重名。** 与常量撞名时，第 4 条优先：改取自有名称。

   与第 1 条的区别：第 1 条管**精确对应某个常量**的概念（名字照抄常量全名）；
   本条管**对应 Mathlib 的记号设施而非常量**的概念（名字取自该设施的所在名）。
   两者都要求挂 `pointer` 指出处；本条指的就是那个记号设施所在的文件或声明。
6. 沿用实际名称，包括现有例外，不为统一外观修改 Lean 名称。Macro 名称对齐不代表
   模板参数已对齐；隐式类型参数、实例参数和显式参数的次序需另行核对。

例如：集合并的 Entry 和 Macro 均可名为 `Set.union`，其 Entry kind 为 `def`，
Macro kind 为 `const`；并的结合律 Entry 使用 `Set.union_assoc`。类别从 `thm`
调整为 `ppt` 不应导致身份改名。

**宏名语法：**

```text
macroName := Namespace "." slug ("." qualifier)?
```

- **点号限定对任何领域概念都是强制的。** 命名空间是拥有该概念的数学理论，而不是
  它恰巧所在的那个文件——两者通常一致；不一致时以理论为准。
- `slug` 在命名运算、关系或性质时为 `lowerCamelCase`
  （`Measure.countablyAdditive`、`Set.subset`、`Logic.forall`）。
- `slug` 在命名类型、结构或对象类时为 `UpperCamelCase`
  （`Algebra.Group`、`Measure.SigmaAlgebra`、`FP.Monad`）。
- 连字符（hyphen）合法，但仅保留给限定后缀，例如类型标注变体
  `Logic.forall` 对 `Logic.forall-typed`。不要在 slug 内部用连字符分词，分词用
  camelCase。

### 5.2 命名空间、大小写与词形

新名称参考 Mathlib 的规则；已有常量以其实际名称为准：

| 名称所表达的对象 | 风格 | 示例 |
|---|---|---|
| 类型、结构、类、谓词 | `UpperCamelCase` | `Group`、`LinearMap`、`Function.Injective` |
| 普通对象、运算、函数 | `lowerCamelCase` | `Set.union`、`MonoidHom.toOneHom` |
| 定理、引理等证明 | `snake_case`，保留引用名称中必要的大小写 | `Set.union_assoc`、`mul_assoc`、`MonoidHom.toOneHom_injective` |

函数按返回值的类别命名；不能仅凭 Entry kind 为 `def` 就认定使用小驼峰。名称用点
表达语义命名空间，用下划线连接定理名称中的成分，**不插入 `def`、`thm`、`ppt`、
`rmk` 等 kind 段**：kind 是实体字段，不是名字成分（§4.1、§7、§8）。

### 5.3 特化前缀（强制）

若某概念显然存在一个更一般的形式、且本文档终将收录，则**窄形式**必须在名字里
说明，一般名保留给一般形式。这是命名义务，不是风格偏好：窄概念不得霸占一般名。

- Riemann 积分被 Lebesgue 积分涵盖，故写作 `Analysis.rIntIcc` /
  `Analysis.rIndefInt`（`r` = Riemann），把 `Analysis.int` /
  `RealAnalysis.lebesgueIntegral` 留给一般形式。
- 群同态被范畴态射涵盖，故写作 `Algebra.GrpHom` 而非 `Algebra.Hom`。同理
  `Algebra.GrpMono`、`Algebra.GrpEpi`、`Algebra.GrpIso`、`Algebra.GrpKer`、
  `Algebra.GrpIm`、`Algebra.GrpAction`。
- 前缀风格随 slug 的大小写：`UpperCamelCase` 的 slug 用大写结构前缀
  （`GrpHom`），`lowerCamelCase` 的 slug 用小写字母前缀（`rIntIcc`）。
- 前缀取自**拥有该特化**的理论（`Grp`、`Ring`、`Top`，`r` / `l` 对应
  Riemann / Lebesgue 共存），不取自它所在的文件。
- **不要**对一般形式不可预见的概念施用此规则。过度加前缀与霸占名字一样糟：
  它让每个名字都为一种永不到来的 generality 变得难读。

### 5.4 结构体成员命名

结构的 property 宏命名为 `<Structure>.<property>`（带点），对应 Mathlib 的
`Structure.property` 约定。结构是 slug，property 是点号限定词，property 保留
自己的大小写，宏留在拥有该结构的 Package 中。

| macro | content (en) | zh-CN | owning package |
|---|---|---|---|
| `DG.SpaceCurve.smoothness` | `Smoothness` | 光滑性 | `DifferentialGeometry` |
| `DG.SpaceCurve.regularity` | `Regularity` | 正则性 | `DifferentialGeometry` |

### 5.5 Unnamespaced（裸名）三类

只有以下三类可以带裸名：

1. **结构性宏**：描述数学陈述的形状而非任何数学对象——`def`、`def-hyp`、
   `thm-hyp`、`def-struct`、`def-inductive`、`constructor`、`member`、`struct`、
   `list-partial`。它们由 `FulcrumsMathNotes` 拥有，设计上理论中立。其名采用
   kebab-case，故 §5.1 的连字符规则不适用于它们。
2. **跨领域初等记号**，由 `BasicOperators` 拥有：`Eq`、`Power`、`parentheses`、
   `Icc`、`let`、`quotient`，以及数系 `Nat`、`Real`、`ENNReal`、`EReal`。
   这些记号每个理论都会用到，给它们加命名空间只会让公式更吵，而不消除任何歧义。

   **数系等原始对象天然全局。** `\mathbb{N}` 在群论与测度论里意思相同，所以只有
   一个 `Nat`，就住在这里。不要因为你恰好第一个需要它，就在自己的包里另定义一份
   带命名空间的副本——「两个不相关理论首次需要」规则说的是**是否把某个领域概念
   一般化**，不适用于本就不属于任何领域的初等记号。若你发现自己写下 `Foo.Nat`、
   `Foo.Int`、`Foo.Real`、`Foo.Complex` 之类，该宏属于 `BasicOperators` 的裸名。
3. **与 Mathlib 同名的宏**：逐字复用 Mathlib 名字（见 §5.1）：`norm`、`inner`、
   `crossProduct`、`ContDiff`、`deriv`。这里名字根本不是选出来的，而是从 Mathlib
   抄来的，好让两套术语能互相 grep；归属仍随拥有该概念的理论。

除这三类外，其他一切都要命名空间：三类之外的裸名不被接受。

### 5.6 Lean 语法与常量：命名边界

1. 若概念对应 Lean 的语法、命令或元编程提供的语法构造，而不是环境中的数学常量，
   优先使用该语法的关键字或保留词作为 Macro 名称，尽量避免与常量名冲突。
2. 在本笔记中，`def`、`theorem`、`inductive`、`structure`、`variable` 等名称留给
   相应语法宏，不用于命名数学常量宏。语法宏仍与数学常量宏区分；名字相同不意味着
   已实现 Lean 的解析或 elaboration 语义。
3. 复刻 Lean 语法时先区分语法构造与其声明出来的常量。例如 `def` 是声明语法，
   被声明对象另有自己的语义名称。具体对应关系须按固定版本 Lean 的语法与
   elaborator 核对。

### 5.7 未直接对应 Lean 常量的概念

1. 先调研邻近概念在固定版本 Mathlib 中的命名，再采用相容的语义命名空间和名称。
   不要机械套用 `<学科缩写>.<类别>.<名称>`。
2. 优先按具体对象组织，而非要求一门学科的所有内容共用一个前缀。根级名字也可以是
   合法的完整名称。
3. `Set.*` 适合集合相关概念；`Type.*` 可以作为 Fulcrum 自有类型论语法、判断及
   元概念的组织方向，但它不是 Mathlib 统一的类型论命名空间。具体自有名称仍应
   逐项设计，不把候选名称当作已有 Lean 声明。
4. 其他领域命名空间同样先调研再定；此前按英文首字母统一缩写领域的方案，不再作为
   Entry 或 Macro 的强制规则。

### 5.8 命名规范不替代运行时参数契约

具体模板、参数及 Style 格式另行补充；命名规范不替代运行时参数契约。

### 5.9 立宏的判据：全局概念，不是局部组合

一个 Macro 只能代表**在整部笔记里可独立命名、可被无关条目复用**的概念——理想情况是
与某个 Lean 常量精确对应（§5.1）。**为某一个陈述临时拼出的组合命题不立宏。**

```snl
DG.def.arcLengthParam[math]($\gamma$)      ← 错：宏把 ‖γ'‖ ≡ 1 焊成一个常量
Set.EqOn(norm(Analysis.deriv($\gamma$)), Function.const(…,$1$), Icc(a,b))
                                            ← 对：三个概念三个节点
```

「范数」「恒等于」「1」各自是可复用的概念（`norm`、`Set.EqOn`、`Function.const`）；
合起来的 `‖γ'‖ ≡ 1` 不是：它只在弧长参数这一处出现，焊成宏后全局命名空间被一个
不再复用的常量污染。

- **判据：** 去掉这个宏，别的条目还能不能引用它所指称的对象？不能，就拆成节点。
- **自指的征兆：** 组合宏的定义体往往只能写回它自己（新宏 `<X>` 的 `content.snl` 里
  出现 `<X>[math]`）。看到这种自指，就说明该宏不是概念，应连同它的 style 一并废弃。
- **代价：** 组合宏以一个新的全局名字占用 §5.1 的命名归属与 §9 的包归属，收益却只是
  一次性写法变短。

**复核：** 对每个新宏，问「它对应哪个 Lean 常量」与「有哪些无关条目会引用它」；
两问答不出，就改用已有概念节点组合。已存在的组合 style 随所属条目重写时废弃。

### 5.10 术语宏的简洁性（默认模板不承担定义）

术语宏是**简洁、可复用的术语或记号**，不是定义本身，也不是类型说明的存放处。默认
Style 只提供该术语在语境中的最小可读形式；把定义、完整类型解释或“所成的类型”之类
结构性赘语塞进默认模板，会让每次调用都重复一遍定义，并挤压真正需要区分的参数。

1. **省略由语境固定的成分。** 参数已经写明的对象不再用散文复述。语境明确时，可以
   只留下术语的核心：例如「`#2` 的基」而不写「`#2` 上的线性空间所成的类型中张成整个
   空间且线性无关的族」。省掉「所成的类型」「这样的一个」「其元素」等赘语。
2. **不省略区分性参数。** 所谓「不省略」约束的是**调用契约**，不是**显示**：只要某个
   参数改变术语所指，宏就必须接受对应的 `#n`，调用点也必须按 canonical 次序传给它——
   基的索引集、线性映射的定义域与值域、内积的标量域都属于此类。但当事先已由语境固定、
   显示时不增加区分度时，默认 Style 可以不打印该参数；省略只发生在渲染层，调用点仍
   传参。不要把「调用必须收全参数」误读成「每个参数都必须在渲染中出现」。
3. **完整条件、索引与类型签名放定义正文。** 线性无关且张成、保加法与数乘、双线性
   与正定等展开，属于定义型 Entry 的 `content.markdown` / 定义体，或另行具名的详细
   Style；默认 Style 不承载它们。
4. **简洁只在渲染层。** 不得为省字而改动 canonical 名（§5.1）、`source.entries`、
   arity 或语义参数顺序；省略后的 `#n` 仍与运行时参数契约逐一对应。
5. **需要展开时另设具名 Style**（如 `full`、`predicate`），不覆盖默认 Style 的身份，
   也不改变调用点的实参次序。

正反例（反例把定义或类型解释塞进默认模板；正例给出简洁、可复用的**对象术语**，
并保持对象类别：基是基、线性映射是线性映射、内积是内积）：

| 概念 | 反例（默认模板塞入定义 / 类型） | 正例（简洁；调用仍传全部语义参数） |
|---|---|---|
| 基 | `%#0 是 #1 上线性空间 #2 中张成整个空间且线性无关的族所成的类型%` | `%以 #0 为索引的 #2 的基%`；索引集已由语境确定时显示 `%#2 的基%` |
| 线性映射 | `%#0 是从 #1 到 #2、保持加法与数乘的映射所成的类型的元素%` | `%#0 : #1 → #2 是线性映射%` |
| 内积 | `%#0 是定义在 #2 上、取值于 #1、满足双线性与正定性的二元函数%` | `$\langle #0, #1\rangle$` 或 `%#0 与 #1 的内积%` |

上表「基」的正例即 `Module.Basis` 的默认模板：参数次序是 `(ι, R, M)`，术语本身指
「`M` 的基」，而不是关于某个已有族的「`#0` 是一组基」命题——`Module.Basis` 是类型
构造子，第四个「族」参数不存在。

---

## 6. Library 命名规范

Library **身份名**使用大驼峰 `UpperCamelCase`，例如 `LinearAlgebra`、
`SetTheory`、`TypeTheory`。章节编排和显示标题独立于身份名。

Library **slug** 是 `.SNL_Doc/libraries/` 下的目录名，两种拼写并存：

- `UpperCamelCase_With_Underscores`，如 `Basic_Analysis`、`Functional_Programming`；
- 小写连字符，如 `measure-theory`、`set-theory`、`basic-algebra`。

**新 Library 使用小写连字符形式**；两个遗留的下划线名字保持不动。

### 6.1 线性代数的长期教材目录与渐进填充

`Linear_Algebra` Library **始终按完整线性代数教材的长期目录组织**，不按当时已写的
少数条目临时拼装。长期章节为：

```text
向量和线性空间 / 线性映射 / 矩阵与线性方程组 / 行列式 /
多项式与多项式矩阵 / 特征理论与标准形 / 双线性与二次型 / 内积空间
```

并沿用旧源教材（`Fulcrum-Notes-Typst`、`Fulcrum-Notes` 的 15-LinearAlgebra）中的
多项式与多项式矩阵、奇异值分解等章节。多项式的标准形工具（初等因子、多项式矩阵的
相抵标准型）是 Jordan 标准形等「特征理论与标准形」的前置，因此在目录中排在标准形
章节之前，而不是作为末尾补丁。

张量积、外代数（含一般楔积与外幂）是长期完整教材应有的章节，本阶段**暂不写正文**，
也暂不作为其他章节的前置；这是渐进填充的**阶段性策略**，不是对章节的永久禁止。
需要时按其长期归属补入章节，并同步调整目录次序与前置关系。楔积当前寄居在
「双线性与二次型」一节，待外代数章节建立后再迁移。

- **目录与填充顺序分离。** 章节与标题骨架按长期归属一次建立；正文按需求渐进填充，
  填充优先级独立于目录，去服务当时的下游需求（例如微分几何）。
- **未填条目只建真实标题骨架。** `section` / `subsection` 的 `content` 保持 `{}`；
  未撰写的正文条目不得伪造完成内容，也不得以空壳冒充已定义。
- **按长期归属定位。** 新增或移动条目以其在教材中的长期归属为准，而不是以它首次
  被填写时恰好所在的位置为准；移动保留 Entry ID 与标题不变。

---

## 7. Entry kind 词表

下表为约定的 kind ID，类别不再进入概念类 Entry 的 ID（见 §4）。

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

构造子（constructor）归入 `def`，不设独立 `ctor` kind。构造过程（construction）
仍保留 `cstr`，二者不混同。

---

## 8. Macro kind 词表

Macro kind 使用简短小写名字。当前配置中的词表为 `rule`、`const`、`sub`、
`binder`、`bvar`、`fvar`；它与 Entry kind 词表相互独立。

kind 不只是展示标签：其中绑定、变量和辅助子树等 kind 具有运行时行为。修改名称或
另增数学概念分类前，须核对当前 SNL-Basics 契约，不得假设重命名后行为自动保留。
`fvar` 不表示已证明某种数学或 Lean 意义上的 `sorry`。

---

## 9. Package 归属

- 一个理论一个包，按理论命名（`MeasureTheory.json`），不按体量命名。
- **一个命名空间恰好有一个拥有包。** `Set.foo` 存在即住在 `SetTheory.json`，
  不在别处。
- 两个理论都能声称某概念时，**更原始的理论拥有它**，下游理论复用该宏。集合论
  拥有 `Set.mem`；测度论不重定义它。
- 只有当**至少两个不相关理论**已经需要某概念时，才把它加进 `BasicOperators`；
  不要预先一般化。
- **是符号，不是概念。** `BasicOperators` 只放 §5.5 列出的初等记号——`Eq`、
  `Power`、`Icc`、数系，以及算术 `Add.add` / `Sub.sub` / `Mul.mul` / `Div.div`。
  数学概念即使再一般、再被广泛复用，也留在拥有它的理论里：范数与内积是
  `LinearAlgebra` 的宏（§5.1），不是 `BasicOperators` 的。判据是
  **「这是符号，还是概念？」**
- 每个包都必须列在 `config.json#active_macro_packages` 中。

**在用命名空间：**

| namespace | owning package | scope |
|---|---|---|
| `Type` | `TypeTheory` | 类型判断、Π/Σ、application、lambda |
| `Logic` | `Logic` | 联结词、量词、真值 |
| `Set` | `SetTheory` | 作为类型值谓词的集合及其运算 |
| `Algebra` | `Algebra` | 群论及其同态 |
| `Measure` | `MeasureTheory` | 集系、σ-代数、测度 |
| `RealAnalysis` | `RealAnalysis` | 测度论的实分析（Lebesgue 层） |
| `Analysis` | `BasicAnalysis` | 初等实分析（极限、导数、Riemann 积分） |
| `FP` | `FunctionalProgramming` | monad、格、标准实例 |
| `DG` | `DifferentialGeometry` | 空间曲线、Frenet 标架、曲率与挠率、曲面 |

**已知偏差。** `Type.pair` 目前住在 `SetTheory.json`，而 `Type` 命名空间归
`TypeTheory` 拥有。这是遗留放置，不是先例。不要再往 `SetTheory.json` 加 `Type.*`
宏；迁移既有的那个需要 `snl-find-refs` + `snl-rename-id`，推迟处理。

---

## 10. Style 命名

`style_name` 必须匹配 `[A-Za-z_][A-Za-z0-9_]*`；括号、连字符、点号会被
`snl-lint-package` 拒绝。多词 style 名用 `lowerCamelCase`（`fracInline`、
`predicateDisplay`）。

`styles[0]` 是隐式默认——调用点未写 `[style]` 标签时使用的那个。把最常见的渲染
排在前面。

保留 style 词汇表；复用下列拼写，不要另造同义词：

| style | meaning |
|---|---|
| `default` | 该宏唯一拥有的 style |
| `inline` / `display` | 相同内容，行内 vs 展示数学或块布局 |
| `paren` | 判断或应用的带括号形式 |
| `juxt` | 以并置代替显式运算符或括号 |
| `infix` / `prefix` | 运算符位置 |
| `text` | 符号概念的自然语言渲染 |
| `bind` | 引入变量的 binder 形式 |
| `cases` | 多行 `\begin{cases}` 布局 |
| `predicate` | 定义型宏的「… 当且仅当 …」措辞 |
| `sup` / `sub` | 上标 / 下标记号变体 |

---

## 11. 语义来源 / I18N / 构造子

### 11.1 语义来源

`source.entries` 指向**定义**该概念的 Entry，而不是它的派生或应用。概念若没有
定义型 Entry，`source.entries` 保持 `[]`——纯记号如 `Add.add` 就没有 source。
填这些是在 Phase 5，不是造名字的时候。

Entry Package、Macro Package、Library 是三条独立轴。一个 Macro 可以引用来自另一个
Entry Package 的定义型 Entry；一个 Entry 可以出现在多个 Library 图位置。仓库验证
检查声明的归属与引用；SNL-Basics 不得由前缀猜测 ontology。

### 11.2 英文与简体中文本地化

- Entry 标题与 Markdown 正文使用完整的 `I18n` 值，恰好含 `en` 与 `zh-CN`；
  默认投影为英文，除非既有实体显式使用另一种默认。
- 只有当 Macro Style 解析出的 template mode 为 `text` 时，该 Style 才本地化。
  公式与块模板保持语言无关的结构数据。
- 每个本地化的 Macro Style 在两种语言中保持相同的 `#0`、`#1`、… 或 `#*`
  占位符契约。Macro 名、style 身份、描述、arity、包归属与 source 索引不因翻译而变。
- 直接写在 SNL 树里的字面 `%…%` 文本**没有语言投影**；不要假装它被本地化了，
  具体写法见 §12.8。

**一次性本地化宏。** 仅用于让某一棵作者手写的 SNL 树可本地化的自然语言片段，属于
专用的活跃 Macro Package `FulcrumNotesOneOffI18N`，不属于任何领域包、也不属于任何
Entry Package。使用带 owner 的长名：

```text
FulcrumNotes.OneOffI18N.<Domain>.<EntryOrFamily>.<Purpose>
```

此类宏恰好带一个本地化 text style，`en` 与 `zh-CN` 的占位符契约相同，
`source.entries` 指向它所属的 Entry。Extension 的共享包注册表仍要求活跃 Macro
Package 有 manifest；其 `entry_ids` 为空，这明确表示没有 Entry 指派给它。该注册
记录不会把 Macro 归属坍缩成 Entry 成员关系。它是 I18N 的实现细节，不是可复用的
公共 ontology。短的、一次性的名字与被翻译的名字都会被拒绝。稳定的语义记号留在其
领域 Macro Package，并在其 style 为散文时就地本地化。

### 11.3 构造子与递归子

- 每个受审的归纳类型，为其每个构造子拥有一个空的 `definition` 子条目，并为其
  per-type 递归子拥有一个空的 `definition` 子条目。
- 构造子 id 以 `.ctor.<slug>` 限定父项；递归子 id 以 `.recursor` 限定。语义相同的
  既有空 Entry 要复用而非重复。
- 这些 Entry 与其归纳父项同 Package，并用 Library 的 `Subentry` 计数器挂在每一处
  预期的父项出现之下。其 `content` 保持 `{}`，直到相应定义被撰写。

### 11.4 子条目的适用范围与计数器挂载

**范围。** §11.3 只讲了归纳类型的构造子与递归子；同一机制适用于一切**围绕某个主条目
派生、离开它就没有意义**的条目：主定义的性质、例子、反例、推论、注、证明。它们与
主条目同 Package，并在 Library 图里 **`branch` 到主条目节点之下**。

- 反例（**不**挂子条目）：有独立生命周期的条目——自己的定义、自己的定理——即使
  引用某个主定义，也留在章节层级，不挂到它下面。
- 子条目 id 仍按 §4.2 独立命名（`DG.ppt.arcLengthParamUniqueness`、
  `DG.xmp.straightLineCurvature`），**不**把父 id 前缀拼进去。

**计数器挂载。** `Subentry` 不是关系标签，而是一个 **Library 计数器**。要让
「父项编号 + 子序号」这样的编号真正出现，三件事必须**在同一次 `library update`**
里一起写入：

1. `counters.counters` 里有一条 `Section > Subsection > Entry > Subentry` 的计数器树
   （`counters` 是**对象** `{"counters":[…]}`，不是数组）；
2. 主条目节点 `props.counterId` 指向 `Entry` 计数器的 id，子条目节点指向 `Subentry`
   计数器的 id（两级 id 必须能在计数器树里按 id 找到）；
3. 子条目节点已在池中，且有一条 `branch` 关系从主条目节点指向它。

只加 `branch` 而不写计数器，条目会嵌在正确的父项下但**没有编号**（`point-set-topology`
即如此）；只写计数器而没有 `branch`，编号存在但树位置不对。计数器树里每个 `name`
必须唯一，否则整个 Library 载入失败。

**复核：** `snl validate --json` 通过只说明图能载，编号要到阅读器确认——取
`http://<reader>/__snl/api/snapshot?library=<slug>`，检查 `library.outline` 里子条目
节点的 `counterLabel` 形如 `<父编号>.<n>`。

---

## 12. 书写规范（SNL 语法层）

> 本节每条规则都带失败模式：说明禁止什么、该写什么、以及复核者如何确认。

### 12.0 书写宗旨：简短、结构化、概念优先、可读性优先

1. **术语宏保持简短，不重复类型信息。** 默认措辞只表达概念或操作，不附加由语境
   已知的“函数”“向量”等自然语言类型标签；例如写“#0 在 #1 处的值”，而非
   “函数 #0 在向量 #1 处的值”。不为措辞额外增加类型参数；必要的类型与假设由
   语境、声明或定义承载，不因显示简化而删掉已有的语义约束。
2. **长合取优先结构化。** 三个及以上命题的合取，尽量按带名称的性质逐行列出，
   不写成大段嵌套合取。合取宏采用 dynamic arity：普通 style 用结合算子的并列写法
   （`P ∧ Q ∧ R`）；`structure` style 用 `cases` 环境的左大括号布局，调用时包裹
   `__enum__`，每行呈现“性质名 : 性质内容”（`* : *`）。两种 style 都表示所有
   性质同时成立；大括号不是分段函数，也不是析取。已有命题的结构化展示不等于
   声明一个新的结构类型（区别见 §12.5）。
3. **使用已封装概念，不无故展开定义。** 已有概念宏时优先复用其记号与语义索引；
   例如表达正交用 `a ⟂ b`，不改写成内积为零。仅在给出定义、展开证明或确有必要
   解释该概念时展开，并保留其成立条件。
4. **数学语义与自然语言可读性优先，不强行对齐 Mathlib。** Mathlib 的 TypeClass /
   Instance 组织方式不直接决定笔记的条目结构；对象、数据与性质混写时，通常拆成
   独立的定义与性质条目，并显式关联。精确对应的概念仍遵守 §5.1 的完整名称规则；
   有语义偏差时采用自有名称、说明差异，不为复用名称扭曲内容，也不冒充精确对应。

**失败模式：** 宏模板复述参数类型而冗长；多条性质挤成一段 `∧`；已有概念被反复
展开而失去语义索引；为了照搬 TypeClass / Instance 把对象定义与性质断言混为一条。

**复核：** 核对默认模板是否有可省的类型标签、长合取是否逐行具名、已有概念是否
被复用，以及定义与性质是否各自清楚。合取宏的具体身份与样式须经实现、读回和渲染
验证；本条确立目标契约，不表示现有宏已实现或既有内容已迁移。

### 12.1 根唯一——每个 `content.snl` 一个根节点

SNL 解析器必须在根节点之后到达 EOF。因此一棵树**恰好有一个根**。

推论：顶层并列写出的连续 `%…%` 文本节点**不是**多句树。第二个 `%…%` 是第二个根，
解析失败。

```snl
%First sentence.%(%Second sentence.%)   ← 非法：第二个根
```

多句散文使用文本模式的可变宏 `__list__`，其 body 为 `#*`，且是单一根：

```snl
__list__(%First sentence.%, %Second sentence.%, %Third sentence.%)
```

`__list__` 由 `BasicMacros` 拥有，是多段文本唯一被认可的根。嵌套 `__list__` 合法，
但一棵**实质上**是 `__list__(%a%, %b%, %c%)`、其下再无结构的树，是把字符串写成树——
见 §12.7。

**复核：** `snl entry latex <id>` 能渲染；根计数错误会以
`snl.parse: Expected EOF but got PERCENT_DELIMITED at position N` 暴露。

### 12.2 标点留在文本节点内

`%…%` 是文本**叶子**。写在定界符之外的标点会被当作语法，从而失败：

```snl
%Identity%: %a tag is exact.%   ← 非法：叶子之间的裸 `:`
%Identity: a tag is exact.%     ← 正确
```

终结标点（`.` `,` `:`）属于它所终结的那个 `%…%`。`$…$` 公式节点同理：能在节点
内部生存的运算符，不要停放在两个节点之间。

**复核：** 解析期 `snl.parse: Unexpected character "." at position N`。

### 12.3 数学符号是公式节点，绝不是裸 Unicode

`content.snl` 里裸写的 `γ` 是**标识符字符**，不是公式。它会作为字面码点进入生成的
代码与 LaTeX，并打断下游链接。

```snl
Type.annotation(@γ, Real)              ← 错：裸 Unicode 标识符
Type.annotation(@$\gamma$, Real)       ← 对：公式节点
```

一切数学符号——希腊字母、`𝕂`、`ℝ`、`‖`、`∈`——都写成 `$…$`（行内）或 `$$…$$`
（展示）。binder 与 source 语法保留 `@` 前缀：`@$\gamma$`、
`$\gamma$@Project.ctxt.family`。

上面两种形式的**渲染输出完全相同**，这正是该错误能躲过目视评审的原因——必须在
源码里找它。

**复核：** 先剥掉每一处合法的 `$…$`，再断言 `content.snl` 中不再有非 ASCII：

```python
stripped = snl.replace('$\\gamma$', '')   # 对每个用到的符号重复
assert stripped.count('γ') == 0
```

注意 `(γ)`、`(γ,`、`,γ)`、`@γ` 是互不相同的实参形状；只处理其中一种会漏掉其他。

### 12.4 `variable` 载语境，声明载自身

- 语境用 `variable(语境, 正文)` 表达。第一个子树保留变量声明及假设，第二个子树是
  处于该语境中的正文；多个声明可用 `__list__` 组织。
- `def`、`theorem`、`inductive`、`structure` 只表达**声明本体**，不再为「附带语境」
  另造 `def-hyp`、`thm-hyp`、`def-struct-hyp`、`def-inductive-hyp` 等组合宏。
- `def` 固定为三元宏：`def(被定义对象陈述, 类型, 内容)`。三个子树的位置和含义不因
  Style 改变；语境仍放在外层 `variable` 中。第一个子树可以是结构化的对象陈述，
  不强制简化为一个名字。
- 旧内容未写明类型时，先保留显式空槽，例如 `def(A, , B)`；连内容也未给出的声明
  使用 `def(A, , )`。空槽表示待补信息，不以猜测的 `Type`、`Prop` 或虚构定义体代替。
- 旧 `def-hyp(H, A, B)` 迁移为 `variable(H, def(A, , B))`。谓词定义等差异仍由 Style
  表达，但类型槽不能挪作记号槽；不删除假设，也不改变原有子树的次序、来源与绑定关系。
- `variable` 是本笔记的显式语境容器；不能仅凭名称对齐就声称它等同于 Lean 命令对
  后续声明的自动参数收集。跨 Entry 的变量来源仍显式使用现有 Context 引用机制。

#### 12.4.1 Context 条目分两层

Context 条目内部**分两层**，两层各司其职：

- **外层（大 Context）** —— 供人阅读。人不展开就能看到这条语境说的是什么，
  标题与整体形态按语义命名（`DG.ctxt.gammaCurve`：一条空间曲线及其定义域）。
- **内层（小声明）** —— 主要供引用。每个可引用的变量是内层的一条**具名声明**
  （`a : Real`、`b : Real`、`$\gamma$ : …`），供其他 Entry 用 **`名@条目id`** 链到。

**引用语法是 `名@条目id`**——名字在前，一个 `@`，随后是提供该声明的 Context 条目 id：

```snl
$\gamma$@DG.ctxt.gammaCurve
a@DG.ctxt.abReal
```

因此引用方**不再重复声明**被 Context 覆盖的变量：那些声明已经在 Context 里。
引用方删去重复的 `Type.annotation`，把变量直接链到提供它的 Context。

```snl
variable(
  DG.ctxt.abReal,        ← 引用，不再本地声明 a、b
  DG.ctxt.gammaCurve,    ← 引用，不再本地声明 γ
  def(DG.def.curvature($\gamma$),, norm(Analysis.deriv2($\gamma$))))
```

反例（本地重声明，等于 Context 白抽）：

```snl
variable(__list__(
    Type.annotation(@a, Real),                     ← 本地声明，只是注了出处
    Type.annotation(@b, Real),
    Type.annotation(@$\gamma$, …)),
  def(…))
```

Context 的作用在于**免除**该声明；把变量写成带 `@条目id` 后缀的本地 binder
**不构成引用**。

- Context 条目本身要被 Library 图收录，否则阅读器看不到（见 §1.2 与 §12.10）。
- 参考实例：`LinearAlgebra.def.vector` 的 `variable` 第一个子树直接是
  `LA.VectorSpace(V@LinearAlgebra.ctxt.vectorSpace, …)`，而不是重新 `Type.annotation`。

> **实现状态（2026-09-18）**：`名@条目id` 这条引用在 SNL-Basics 侧的**实现当前有问题**，
> 实测渲染上尚不产生与本地声明不同的效果。规范条款先按此语法立；实现修复另案跟进。
>
> **在此之前，条目暂不挂 `@条目id`**：Context 已经声明过的变量，引用方**既不重新声明、
> 也不挂源**，直接用名字写。理由是挂源当前不生效，只会让源码更密而无收益。
> 代价是渲染器暂时铺不出开头的 `Let …` 声明行（它取不到声明）——这是同一处实现缺口的
> 表现，等修复后自动恢复。**不要为了好看而退回本地重声明。**

**复核：** 对每个引用了 Context 的 Entry，确认其 `variable` 的第一子树是 Context
条目的引用，而非同名变量的 `Type.annotation`；渲染应与引用前逐字相同。

**复核：** grep 被禁的组合宏名；检查每个 `def` 恰好有三个实参节点。

#### 12.4.2 定义谓词用 `def[prop]`

`def` 的 `[prop]` style 渲染「定义【X】**当且仅当** …」（与 §12.5 的
`structure[prop]` 同源）。当被定义的对象是**命题**——一个谓词、性质、满足关系——用
`def[prop]`；当它是对象或函数，用默认 `def`（「定义【X】**为** …」）。

```snl
def[prop](DG.def.arcLengthParam[text]($\gamma$),,
    Set.EqOn(norm(Analysis.deriv($\gamma$)), Function.const(…,$1$), Icc(a,b)))
def(DG.def.curvature($\gamma$),, norm(Analysis.deriv2($\gamma$)))
```

失败模式：谓词写成普通 `def`，渲染成「定义【γ 是以弧长为参数的】**为** ‖γ'‖ ≡ 1」——
把命题塞进「为」的宾语槽，读者以为在命名一个对象，而不是在陈述一个条件。

**复核：** 看 `snl entry latex <id>` 的措辞：命题应出现「当且仅当 / if and only if」，
对象应出现「为 / to be」。

### 12.5 结构用 `structure` 声明，不用 `And(...)`

本节针对结构声明；一般命题的长合取采用 §12.0 的合取宏 `structure` style，
不为排版另造结构类型。

多子句定义（「一个群是……」「一条空间曲线是……」）写成嵌套 `And(...)` 会渲染成一串
`∧`，摧毁读者需要的带标签结构。

```snl
structure[prop](
  Name,
  __enum__[enumerate](
    member[colon](%label%, condition),
    …
  )
)
```

渲染为「定义【X】当且仅当可提供以下所有信息： ① 标签 : 条件 ② …」。

- `[prop]` style = 上面的「当且仅当」措辞。`[default]` / `[localized_default]` =
  「定义结构类型【X】包含以下信息：」。
- 参考条目是 `Algebra.def.group`——撰写新结构前先用
  `snl entry get Algebra.def.group --json` 读它。
- 结构 **property** 宏命名为 `<Structure>.<property>`（带点，如
  `DG.SpaceCurve.smoothness`），并留在拥有该结构的包中。身份规则见 §5.4。

**复核：** 对代表性结构跑 `snl entry latex`，应显示带标签的成员，而不是 `∧`。

### 12.5.1 函数应用与参数外层括号

- `Type.apply` 默认保持首位 `paren` 样式，模板为 `#0(#1)`；`none` 的模板为
  `#0#1`，只作显式备选，不调整宏样式的默认顺序。一般的 `Type.apply(f,x)`
  仍显示 `f(x)`，不得为消括号而一律改成 `[none]`。
- 当参数子树已经提供覆盖整个参数的完整外层括号，且 `paren` 再包一层造成重复时，
  在该调用点显式使用 `Type.apply[none]`。保留参数自己的括号，不删参数结构。
  例如 `Type.apply(f,Prod.pair(a,b))` 改为 `Type.apply[none](f,Prod.pair(a,b))`，
  由参数节点提供 `(a,b)`，显示 `f(a,b)`。
- 若旧调用由 `Type.apply[paren]` 包裹 `VecNotation[bare]`，可等义改为
  `Type.apply[none](f,VecNotation[default](a,b))`：完整序列括号归序列节点所有。
  `VecNotation` 仍表示 `Fin n → T` 的有限序列，不改成 `Prod`，不改变元素次序。
- 元组、序列及其嵌套边界必须保留；仅消除最外层重复包裹，不自动扁平化。
  例如 `f((a,b),c)` 中 `(a,b)` 是内部元组边界，不得改成 `f(a,b,c)`；
  `f(g(x))` 中函数应用的边界也不是冗余括号。函数位置及参数内部因作用域、
  优先级而需要的括号不在删除范围内。

**失败模式：** 全局改默认样式导致普通 `f(x)` 变成并置；把序列的括号借给外层
应用后独立使用时丢失分组；按字符删除括号而混淆嵌套元组与多个参数。

**复核：** 逐调用点核对参数子树及实际模板，确认只改重复外壳；逐 Entry 读回
`snl entry latex` 并在阅读器展开检查。校验通过不能代替括号边界与数学语义检查。

### 12.6 点态 vs 函数级陈述

DSL 语法是 `node := name ("(" args? ")")?`——**一个节点至多带一对实参括号**。
因此像 `γ'(s)` 这样的点态表达式（先对函数求导，再在 `s` 取值）必须写成**两层节点**，
不能压进一个节点。

```snl
Type.apply(Analysis.deriv($\gamma$), t)      ← 对：γ' 再作用于 t，渲染 γ'(t)
Analysis.deriv($\gamma$)(t)                   ← 错：一个节点带了两对括号
```

- **默认**把 Entry 级陈述写在函数级：`κ_γ`、`t_γ`；纯点态公式放进 `content.markdown`。
- **点态定义写进 `content.snl` 的条件**：点变量由
  `variable(Type.annotation(@t, Real), 正文)` 语境引入，正文里的点态值写成
  `Type.apply(F, t)`。此时渲染出「设 t : ℝ，定义【κ_γ(t)】为 ‖γ''(t)‖」——既保住点态，
  又让 `‖·‖` 有明确的作用对象，不必依赖隐式类型推理。
- 例外是 binder：当变量本身被绑定（`@γ`）时，首次应用 `Type.apply(γ, t)` 合法，
  因为 binder 就是绑定位置。
- 粒度由**数学结构**决定，不由书的呈现顺序决定。点态事实通过 `Type.apply` 提供
  实参来恢复，而不是把定义压平。
- 把 `(t)` 焊进概念宏模板、专为某一处点态陈述服务的 style 是 §5.9 禁止的组合宏；
  点态一律由**调用处**的 `Type.apply` 表达，不由宏模板预置。

失败模式：点态定义退成函数级（`def(κ_γ, , ‖γ''‖)`）时 `‖·‖` 的操作数类型含糊，
渲染器只能靠隐式推理补齐——这正是加 `t : Real` 语境要消除的。

**复核：** `snl entry latex <id>` 应显示 `设 t : ℝ…` 的语境行，且被定义的点态值带
实参 `(t)`。

### 12.7 不把字符串写成树

一棵形状是字符串的语法树——根是一个文本宏、携带整句话，或 `__list__` 套着若干散
文片段而其下再无结构——不是细化。它背离了记号法，且 SSI 抓不到它：字符串形状的树
可以得高分却毫无结构。

当语料确实无法做出语法判定时，把该段当作整体、**诚实地接受低 SSI**，而不是做盲目
分解。同样的禁令也适用于伪造高 SSI：把每个短语都提升为 `source.entries` 错误或
为空的常量宏，这会让宏管理变成负债，却不增加任何意义。

**复核：** 对每个新 Entry，确认根之下有真实结构。`snl entry latex` 与 SSI 是必要
条件，但不充分。

### 12.8 `%…%` 文本无语言投影

嵌在树里的字面 `%…%` 文本**不可本地化**。不要声称它被本地化了。某片段必须翻译时，
要么复用一个既有本地化文本宏，要么在 `FulcrumNotesOneOffI18N` 里引入一个一次性宏
（命名与 manifest 规则见 §11.2）。

在 `%…%` 内部，`#0` / `#1` 是引用 params 表的**参数占位符**，不是字面量。纯文本
渲染不在此处替换占位符；填充发生在 KaTeX/React 层。`Skill.SNLeco.cpt.EntryTitle`
行为相同；这是既有约定，不是缺陷。

### 12.9 区间：是谓词，不是类型

值本应落在 `[a, b]` 中的 binder，声明其原始类型并单独陈述隶属：

```snl
s : Real   with   s ∈ [a, b]      ← 正确
s : Icc(a, b)                     ← 错误：Icc 不是类型构造子
```

**函数**的**定义域**若确实是区间，仍可以 `Icc(a, b)` 作其定义域类型
（`γ : Icc(a, b) → ℝ³`）。本条规则管的是 binder：区间在那里约束一个点，而不是给它
定类型。`Ioo`、`Ico`、`Ioc` 同理。（`Icc` 是 §5.5 的初等区间记号。）

### 12.10 Entry 内容形状

- `section` / `subsection` Entry 的 `content` 保持 `{}`——只有标题外壳。参考
  `Topology.sec.topology`。
- Entry 的 `content.snl` 可以为空；空 Entry 合法，并被刻意用于尚未落定的构造子与
  递归子（§11.3）。
- `content` 的方言是语言无关的 `snl`，外加可选的 `markdown` / `latex` / `typst` /
  `text`。始终是散文的内容——动机、阅读笔记，以及无法用 §12.6 的 binder 语境结构化的
  点态公式——放进 `markdown`，不要硬塞进 `snl`。

### 12.11 定义必须是显式的

**被定义的概念不得出现在自己的定义式里。** 一个把被定义者同时写在等号两边的式子
是**隐式定义**，它陈述的是性质而非定义，用 `def` 承载就是错的：

```snl
def(τ_γ(t), , Eq(b_γ'(t), τ_γ(t)·n_γ(t)))      ← 错：τ_γ 出现在定义体里
def(τ_γ(t), , ⟨b_γ'(t), n_γ(t)⟩)                ← 对：显式给出 τ_γ 是什么
```

- 判据：**把定义体的右侧化简后，能否只由已知量算出被定义者？** 不能 → 是隐式定义。
- 隐式定义的常见来源是照搬书本排版——书用「由 b' = τn 定义 τ」这种**由性质唯一确定对象**
  的写法，形式化时须**解出被定义者**，写作显式表达式。
- 若该陈述本身有价值（它是性质/定理，不是定义），用相应的 kind 立**另一条** Entry，
  而不是把它塞进定义体。

**复核：** 逐条看 `def` 的定义体，确认被定义者的名字不在其中。

### 12.12 人名书写

- **人名按原文拼写，不加原文没有的重音符号。** `Frenet` 就是 `Frenet`，
  `Serret` 就是 `Serret`——法文姓氏本身无变音，不要凭「看着像法文」补 `é`。
- 需要核对时查**人名本身的拼写**，而不要从其他语言的转写反推。
- **带连字符的复合人名保持连字符**：`Frenet–Serret`（公式）、`Cauchy–Schwarz`（不等式）。
- **中文标题里的人名用通行中译**，或直接保留原文；**同一份文档内保持一致**。
- 人名的**拼写不进入宏名与 Entry id**（宏名按 §5 的 Mathlib 命名规则走，
  `frenetFrame` 是小驼峰，不带人名）。人名只出现在标题与正文里。

**复核：** grep 标题与正文里的人名，逐个对照其原文拼写；确认没有加原文不存在的变音符号。

---

## 13. 标签（tags）

`.SNL_Doc` 的 Entry 存储默认没有 `tags` 字段。存在时它是一个**可选的字符串数组**，
每个元素是用于查找该 Entry 的短关键词。

```json
"tags": ["mathlib-divergence"]                ← 正确
"tags": [{"key": "...", "value": "..."}]      ← 错误：不是元数据槽
"tags": null                                  ← 错误：应缺省，而非 null
```

- 解释属于 `title` 或 `content.markdown`，绝不放进 tag。
- 缺省即无标签。不要写 `[]` 去「清空」它，也不要给从未有该字段的 Entry 加上它。
  一次**省略**该字段的更新会保留已存的 tags；显式 `[]` 才会清空。
- 出现的非字符串数组 tag 会在**发布前被拒**；若已被存储，则会在读取时
  **拒绝整个工作区**——不是一个 Entry。因此 `validate` 通过**不是**工作区可读的
  证据。

**复核：** 客户端检查，外加对受影响 Library 做一次浏览器加载——见 §1.2。

---

## 14. SNL-Lean 同步

1. 一个条目被 Fulcrum 笔记收容的标准是存在 SNL 条目。Lean 是可选项，而非必须项。
2. Lean 文件中的代码必须在 SNL 文件中有恰当的条目指向该位置。这不仅包括常量声明，
   也包括记号、语境、元编程程序等等。即：**接受有 SNL 而无 Lean，但不接受有 Lean
   而无 SNL。**

---

## 15. 本仓内容纪律：不写习题与引导

> **作用域。** 本节只约束本仓库（Fulcrum-Notes-SNL）。它不改变 Homework 仓或任何
> 其他仓库的内容范围：其他仓库是否收录习题，由各仓自己的规范决定，本节不越界。

### 15.1 不写习题，不写引导性条目

1. 本仓**不写习题**，也不写习题的配套提示、解答、答案——禁止对象是练习册
   （problem set）形式的语料。需要练习的语料放进 Homework 仓。§7 的 `problem`
   kind 仍在词表中，但在本仓不用于收录练习。
   **本条不禁数学证明与例子。** `theorem`、`proof`、`construction`、`example`、
   `counterexample` 等正式数学内容照常收录；一个数学上完整的证明，哪怕结论显然、
   读起来像「解答」，也不因本条被删除。用户要的是正式数学标题与内容，而不是删掉
   证明。
2. 本仓**不写引导性条目**——凡是以「带读者一步步认识某个概念」「先铺垫动机再引出
   定义」为目的、靠叙事推进的条目，都不是本仓的收录对象。本仓收录的是数学内容本身。
3. 一条内容若只有靠「它是为了引出后面某个定义」才成立，那它不构成独立条目；应把其中
   真正的数学内容并入它所属的定义或结果，把叙述性文字按 §15.4 处理。

### 15.2 条目标题直接命名数学对象

- 条目标题直接使用**正式数学概念、对象、构造或结果本身的名称**。例：用「参数化圆」，
  不用「通过投影认识参数化圆」，也不用「参数化圆一例」。
- 标题里不出现「认识」「理解」「了解」「初识」「探秘」「引子」「漫谈」等描述学习过程的
  词：这些词描述读者的状态，不描述数学内容。
- 标题命名的是被定义的数学对象或结果，而不是它在某段行文里扮演的角色。

### 15.3 section / subsection 直接标识数学内容

- `section` / `subsection` 的标题直接标识该层级覆盖的**数学主题**（如「平面二次曲线」
  「射影平面」），不写学习动机，不写「为什么学」「读完能收获什么」。
- 章、节的作用是给数学内容分组，不是给读者设定学习路径。

### 15.4 动机与导读独立为 remark

- 动机、背景、导读、几何直观、历史说明等**自然语言**，尽可能独立成 `remark` 条目，
  而不是塞进定义式、假设或章节壳里。
- 判据：从定义、假设与证明中移除这些自然语言后，数学内容必须仍然完整——定义仍给出
  真实的数学右侧（§12.11），假设与证明仍然闭合。若移除后出现缺口，说明那里混入的是
  数学内容而非动机，应当留在原处。
- 与 §12.10 一致：始终是散文的内容放进 `content.markdown`，不硬塞进 `content.snl`。

**复核：** 逐条检查新条目：标题是否只是概念名；依赖动机才读得懂的内容是否已移出定义、
假设与证明；移出后 `snl entry latex` 的定义陈述是否仍然自足。

---

## 附录：Mathlib 调研参考

### Mathlib 命名空间调研参考

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

### 参考来源

- [Mathlib 官方命名指南](https://leanprover-community.github.io/contribute/naming.html)（在线指南可能继续更新）。
- 本项目固定 Mathlib v4.28.0，revision `8f9d9cff6bd728b17a24e163c9402775d9e6a365`。
- [Set 定义](https://github.com/leanprover-community/mathlib4/blob/8f9d9cff6bd728b17a24e163c9402775d9e6a365/Mathlib/Data/Set/Defs.lean)、[Set 定理](https://github.com/leanprover-community/mathlib4/blob/8f9d9cff6bd728b17a24e163c9402775d9e6a365/Mathlib/Data/Set/Basic.lean)。
- [代数结构](https://github.com/leanprover-community/mathlib4/blob/8f9d9cff6bd728b17a24e163c9402775d9e6a365/Mathlib/Algebra/Group/Defs.lean)、[Module.Basis](https://github.com/leanprover-community/mathlib4/blob/8f9d9cff6bd728b17a24e163c9402775d9e6a365/Mathlib/LinearAlgebra/Basis/Defs.lean)。
- [拓扑基本定义](https://github.com/leanprover-community/mathlib4/blob/8f9d9cff6bd728b17a24e163c9402775d9e6a365/Mathlib/Topology/Defs/Basic.lean)、[可测空间](https://github.com/leanprover-community/mathlib4/blob/8f9d9cff6bd728b17a24e163c9402775d9e6a365/Mathlib/MeasureTheory/MeasurableSpace/Defs.lean)、[测度](https://github.com/leanprover-community/mathlib4/blob/8f9d9cff6bd728b17a24e163c9402775d9e6a365/Mathlib/MeasureTheory/Measure/MeasureSpaceDef.lean)。
- [导数](https://github.com/leanprover-community/mathlib4/blob/8f9d9cff6bd728b17a24e163c9402775d9e6a365/Mathlib/Analysis/Calculus/Deriv/Basic.lean)、[范畴](https://github.com/leanprover-community/mathlib4/blob/8f9d9cff6bd728b17a24e163c9402775d9e6a365/Mathlib/CategoryTheory/Category/Basic.lean)、[函子](https://github.com/leanprover-community/mathlib4/blob/8f9d9cff6bd728b17a24e163c9402775d9e6a365/Mathlib/CategoryTheory/Functor/Basic.lean)。
