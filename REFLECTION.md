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

## 7. Entry 过度拆分

灰风版 13 个 entry（chapter + 2 sections + 9 definitions + 1 axiom），粒度太细。猫猫版 4 个 entry（1 section + 3 definitions），更紧凑。在 type-theoretic 框架下，subset、emptyset、powerset 等概念是 `Set(T) = T → Prop` 的直接推论，不需要独立定义。

## 8. content.snl 中的逗号噩梦

灰风版 `Set.statement(...)` 的每个 child 需要显式逗号分隔，导致 `$...$, %.%` 这类脆弱写法，极易出现 `$...$%.%` 缺逗号的解析错误。猫猫版 `def-hyp(hyp-list(...), term, body)` 用固定 arity 的结构化宏，逗号只在固定位置出现，大大减少了出错可能。

## 9. 操作符包缺失

猫猫版有 `BasicOperators.json`（`Add.add`、`Sub.sub`、`Mul.mul`、`Div.div`、`Power`、`parentheses`），这些是跨领域的通用符号。灰风版完全缺失。

## 10. 版本号不一致

猫猫版用 `"version": "1"`，灰风版用 `"version": "0.4.0"`。应统一。
