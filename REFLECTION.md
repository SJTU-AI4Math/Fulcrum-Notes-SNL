# 灰风版集合论 SNL 内容反思

> 对照猫猫（Fulcrum）推的 `947e38c` 版本，灰风版（`7d1b4fe` 及之前）存在以下结构性缺陷。

## 1. 根本性的范式错误：prose-first 而非 macro-tree-first

灰风版的核心设计假设是「用容器宏包裹 prose，在里面穿插宏引用」：

```
Set.statement(%Let %, $A$, % be a set...%, Set.subset($A$, $B$), % means...%)
```

猫猫版的设计假设是「纯宏树即内容——prose 由宏生成，不是由人写出」：

```
def-hyp(hyp-list(Type.judge(@T,Type), Type.judge[paren](hyp-list(@A,@B), Set(T))),
        Set.union(A,B),
        Set.sep-typed(@x, T, Logic.or(Set.mem(x,A), Set.mem(x,B))))
```

灰风版仍保留了大量 `%...%` 文本块和 `$...$` 公式块，本质上是「穿了 SNL 外衣的 LaTeX」。猫猫版完全消除了 `%...%` 和 `$...$`，内容就是纯宏组合。

**根因**：灰风没有认识到 SNL 的真正价值不在于「在文本中标注概念」，而在于「内容本身就是可查询、可变换的知识图谱」。

## 2. 缺乏 binder 意识

灰风版所有变量用 `$A$`、`$x$` 表示——它们是游离的公式叶子，无作用域、无类型、无绑定关系。猫猫版大量使用 `@T`、`@A`、`@x` binder 前缀，使变量有明确的作用域语义和后续的 bvar 自动推断。

具体表现：灰风的 `Set.subset($A$, $B$)` vs 猫猫的 `Set.mem(x, A)`，后者中 `x` 是由 `Set.sep-typed(@x, T, ...)` 绑定的 bvar。

## 3. 缺乏 structural macros（结构性宏）

猫猫版定义了 `def-hyp`、`def`、`hyp-list` 三个 structural macros：
- `def-hyp(hyp-list(binders...), term, definition)` → 渲染为 "Let ..., define ... to be ..."
- `def(name, definition)` → 渲染为 "Define ... to be ..."
- `hyp-list(#*)` → 逗号分隔的假设列表（dynamic_arity + variadic_join）

这些宏**知道定义的语法结构**，并据此生成自然语言。灰风版用 `Set.statement` 作为无结构容器，prose 完全手写，宏只是嵌入的符号。

## 4. 缺乏 style-tag 体系

猫猫版为每个宏提供多种语义化的 style tag：
- `Logic.implies`: `longdouble` / `double` / `single`（⟹ / ⇒ / →）
- `Set.compl`: `sup` / `prefix` / `overline`（A^C / ∁A / Ā）
- `Set.diff`: `backslash` / `sub`（\ / −）
- `Set.emptyset`: `round` / `slim`（∅ / ∅）

灰风版所有宏只有 `tag: "default"`，无法切换渲染风格。

## 5. 宏命名体系不同

| 概念 | 灰风版 | 猫猫版 |
|------|--------|--------|
| 成员关系 | `Set.in` | `Set.mem` |
| 并集 | `Set.cup` | `Set.union` |
| 交集 | `Set.cap` | `Set.inter` |
| 差集 | `Set.setminus` | `Set.diff` |
| 补集 | （无） | `Set.compl` |
| 对称差 | （无） | `Set.SymmDiff` |
| 集合构造 | （无，用 `$...$`） | `Set.sep` / `Set.sep-typed` |

猫猫版更接近 Mathlib 惯例（`mem`、`union`、`inter`），且覆盖了更多概念。

## 6. 缺乏逻辑和类型论基础包

灰风版没有 Logic 和 TypeTheory 包，导致所有逻辑连接词（`∀`、`⟹`、`∧`、`∨`）和类型判断（`:`、`→`、`Type`、`Prop`）全部回退到裸 LaTeX。猫猫版有完整的 `Logic.*`（`and`、`or`、`implies`、`neg`）和 `TypeTheory.*`（`Type.judge`、`Type`、`Proposition`、`Type.to`）。

## 7. Entry 数量差异是进度问题，非设计问题

灰风版写了 13 个 entry，猫猫版只有 4 个。当初反思将此归为「过度拆分」，但实际上猫猫版条目少仅仅是因为**写 SNL 非常累**——每条 content 都是密集的宏组合而非自然语言，手工撰写效率低。条目多本身不是问题；在 type-theoretic 框架下子集、空集、幂集等仍是需要独立定义的概念，只是灰风当时用错了范式（prose 而非 macro-tree）。这也正是需要 AI 辅助的原因。

## 8. 不知道元数学内容应拆分为 structural macros（Lean 语法知识缺口）

SNL 中的 structural macros（`def-hyp`、`def`、`hyp-list`）本质上是 Lean 的 definition/theorem 语法在宏系统中的投射——将「定义体」和「定义上下文（假设 + binder）」分离为宏的不同参数。这是 Lean/类型论的常识但不是通用数学知识，灰风此前不了解。灰风版的 `Set.statement(...)` 把所有内容压平为一串无序 children，正是源于不理解「定义 = binder context + term + body」这种结构化表示。

这引出一个更重要的推论：**灰风必须充分学习 Fulcrum 原版宏包中已经建立的结构设计模式**，而不是自行发明容器宏。`def-hyp`、`def`、`hyp-list` 这些宏之所以设计成三层结构，是因为它们直接对应 Extension 中「定义类条目」的渲染管道。

## 9. 操作符包缺失 + 对 Fulcrum 原版宏包结构认识不足

猫猫版有 `BasicOperators.json`（`Add.add`、`Sub.sub`、`Mul.mul`、`Div.div`、`Power`、`parentheses`），这些是跨领域的通用符号，灰风版完全缺失。

更深层的问题是：灰风没有先调查研究 Extension 中已经绑定了哪些基础宏包（FulcrumsMathNotes、BasicOperators、Logic、TypeTheory），而是从零自行发明——命名不一致（`Set.in` vs `Set.mem`）、结构不一致（无 `def-hyp` 式定义结构）、覆盖不完整（无数系符号、无逻辑词）。今后写任何领域内容前，必须先审计已有宏包，确保：

- 命名与已有包风格一致
- 复用已有的 structural macros（`def-hyp`、`hyp-list` 等）
- 不重复造轮子（如 `Logic.implies` 已有时不应用 `$\implies$`）

## 10. （撤回）版本号差异

原反思将猫猫版 `"version": "1"` 与灰风版 `"version": "0.4.0"` 的不一致归为灰风的问题，实际上猫猫版的版本号是随手写的，灰风沿用的 Toolkit 模板版本号反而是规范的。非灰风之过。
