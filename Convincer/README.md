# Convincer

把非形式化论证作为数据保存，同时让 Lean 检查其中的刚性推理。
所有文件都在本目录：`Convincer.lean`（完整实现）、`Tests.lean`（示例和测试）、
`check.py`（串行检查）、本说明。公开入口仍是 `import Convincer`。

## 用法

```lean
import Convincer

convince observed : False := by
  evidence "Obvious"

convince conclusion : False ∧ True := by
  have h ← observed
  evidence ht : True := [1, 2, 3]
  exact ⟨h, ht⟩

#evidence conclusion
```

输出只保留非刚性来源及其命名依赖层级：

```text
└─ conclusion : False ∧ True
   ├─ observed : False
   │  └─ False ← "Obvious"
   └─ True ← [1, 2, 3]
```

不显示刚性规则、`infer` 节点或公理表。没有显式 Evidence 时只显示
“无显式 Evidence。”，**这不表示没有 `sorry` 或其他公理**。
需要审计 Lean 的信任基础时使用原生 `#print axioms name`。

## Evidence 是任意载荷，不是元数据格式

`Evidence.of` 可以封装任意 `α : Sort u` 的值。字符串、数、列表、函数、
自定义类型的值、类型本身或证明都可以，不要求 `Repr`、ID、来源字段或结构体字面量。
组合仍遵守 Lean 的 universe 约束；不同 universe 的来源需通常的 universe 对齐。
用户在 tactic 中直接写值，无须自己包装：

```lean
convince functionReason : False := by
  evidence (fun n : Nat => n + 1)

convince typeReason : False := by
  evidence Nat
```

三种写法：

- `evidence value`：关闭当前目标。
- `evidence h : P := value`：引入一个有非形式化依据的前提。
- `have h ← argument`：引用已有的 `Convincing P`。

`#evidence` 按树列出这些显式引用，保留顺序、重复和成功路径上未使用的引用。
失败后回退的 tactic 分支不会留下记录。

## 普通 by 与 Convincer by

两边使用同一套 tactic 语法，底层都是 Lean 原生 `TacticM`：

```lean
convince captured : False := by
  evidence "Obvious"

theorem admitted : False := by
  evidence "Obvious"

convince unfinished : False := by
  sorry
```

但语义有意不同：

- 在 `convince ... := by` / `convincing% by` 中，Evidence 会被捕获为论证数据。
  普通 tactics 检查的是“假设这些前提成立，结论如何得出”。
- 在普通 `by` 中，`evidence` 等效于原生 `sorry`：生成带位置的 `sorryAx`，
  Lean 保留标准 warning。命名 Evidence 和 `have h ← argument` 也采用这个行为。
  此时不会生成可由 `#evidence` 反查的论证对象。
- `sorry` 在两边都保持原生语义，不被禁止，也不会被自动改成 Evidence。
  原生错误和未解决目标仍然报错。

**不能承诺完全兼容所有 tactic 及插件。** 当前验证了普通的引入/应用、
`have`、分支、归纳、重写、简化、`subst`、`clear`、`all_goals`、`first`、
`classical`、嵌套 tactic 和原生 `sorry`，以及同一 tactic 宏分别用于两种声明。
其余 tactics 需要按正常方式 import；本次没有跑遍 Mathlib 或第三方 tactic 库。

捕获模式还有两个明确限制：

1. Evidence 的目标命题、载荷及被引用论证必须独立于当前 tactic 块新引入的
   局部假设/分支变量。可把参数提升到声明参数，或把非形式化步骤写成闭合的
   蕴含/全称命题。普通刚性推理没有这个限制；普通 `by` 的 sorry 式 Evidence 也没有。
2. `Convincing` 的目标是 `Prop`。普通 `by` 的 `evidence` 可以像 `sorry` 一样
   填充数据目标；捕获模式不支持用 Evidence 生成存在量词的未经证明的数据见证。

所以，这是大部分普通证明脚本可复用的环境，不是两个语义完全相同的证明系统。

## 核心与查询边界

`Convincing P` 位于 `Type`，而非 proof-irrelevant 的 `Prop`。核心保留
`proof`、`evidence`、`mp`、`named` 四种构造；改变显示不会删掉真实依赖。
`map` / `both` 组合论证，`evidenceLeaves` 返回带原始类型和值的全部 Evidence。

`argument.Valid → P` 是条件可靠性定理，不声称每份 Evidence 都正确。
`checked?` 只在没有显式 Evidence 时返回已有的 Lean 证明项；这些项仍可能依赖
用户写的 `sorry` 或公理，它不是额外的公理审计器。

`#evidence` 只接受闭合且适当实例化的论证；开放局部假设、不能展开的 opaque
论证和无法完成的归约会报错，而不是声称给出了完整来源。
刚性叶子不会展开其内部定理依赖；要看某个原论证的 Evidence，应查询该论证，
而不是它在另行证明 `Valid` 后被转换并重新包装的严格证明。

这里采用静态依赖组合，不宣称有通用 `Monad Convincing`：没有真正的 `P` 时，
不能运行任意 `P → Convincing Q` continuation 来取得完整的后续 Evidence。

## 检查

仓库固定 Lean 4.28.0。根目录运行：

```sh
python3 Convincer/check.py
```

Windows 使用 `python Convincer/check.py`。串行检查不下载 Mathlib，产物在
`.lake/convincer-flat/`。原生 sorry warning 在指定兼容性示例中是预期行为。
检查同时验证：捕获模式不自动引入 `sorryAx`，普通模式确实依赖 `sorryAx`，
核心条件可靠性定理无公理，以及精确的精简树输出和负例边界。
已有完整 Lake 依赖时，也可使用有限目标 `lake build Convincer`。

SNL 收录仍未完成：原始工作区存在集合论条目悬空引用，未改动 `.SNL_Doc`，
也未补齐本原型的 SNL 条目/Pointer。本分支不是已通过全库收录门禁的发布。
