# SNL 书写约定

> 基于灰风（gray-hermes）与猫猫（Fulcrum）在集合论和数理逻辑笔记中的协作实践总结。
> 应与 `AGENT.md`（Toolkit 方法论）配合阅读。

---

## 一、类型论优先

- 集合定义为类型上的谓词：`Set(T) := T → Prop`（非 ZFC 公理集合论）
- 成员关系即函数应用：`x ∈ A := A(x)`
- 量词使用 typed 版本：`∀ x : T, P(x)`，`∃ x : T, P(x)`
- 类型判断：`Type.judge(x, T)` 渲染为 `x : T`
- 逻辑命题：`P : Prop`（非 `P : T → Prop`，那是谓词）

---

## 二、宏与条目约定

### 2.1 宏命名

- Namespaced：`Set.mem`、`Logic.and`、`Type.apply`
- 遵循 `[A-Za-z_][A-Za-z0-9_.-]*`（连字符合法）
- 多词用连字符：`def-hyp`、`hyp-list`、`Set.sep-typed`

### 2.2 模板反斜杠

JSON 中的 `template` 字段仅需 **一层** 反斜杠：
```json
{"template": "\\forall #0 : #1, #2"}     ← 正确
{"template": "\\\\forall #0 : #1, #2"}   ← 错误（KaTeX 当换行符）
```

### 2.3 Phase 5 语义索引

每个宏必须绑定到其定义条目：
```json
"Set.mem": { "source": { "entries": ["Set.def.mem"], "urls": [] } }
```
无定义条目的工具宏（如 `Type.apply`、`hyp-list`）可留空。

### 2.4 只写宏不写条目

- Curry-Howard 同构相关内容（Pi、Sigma、inductive、structure、constructor）只定义宏，不在 Logic/SetTheory 章节写定义条目
- Lambda calculus、Type Theory 的条目留到独立 `TypeTheory` 章节

---

## 三、条目 ID 与 Library 结构

### 3.1 ID 格式

`<domain>.<kind>.<slug>`，用点号分隔，**不用连字符**：

```
Set.def.set          ✓
set-def-set          ✗ （连字符可能被 KaTeX 当成减号）
```

### 3.2 Library 三级结构

```
section → subsection → entry
Set.sec.set → Set.subsec.basic → Set.def.set
            → Set.subsec.relations → Set.def.subset
                                   → Set.def.ext（property, sub of subset）
            → Set.subsec.operations → Set.def.union
```

### 3.3 Context 条目

Context 条目声明跨条目共享的 binder 变量，组织为：

```
section → ctxt.1（parent context）
              → ctxt.T（Type.judge(@T, Type)）
              → ctxt.AB（Type.judge(hyp-list(@A, @B), Set(T))）
```

### 3.4 Property / Theorem 作为 sub-entry

一个 property/theorem 应挂在定义条目下，当它是该定义的 **核心内蕴行为**（"一提到概念就应想到的性质"）：
```
Set.subsec.relations → Set.def.subset → Set.def.ext（外延性是子集定义的核心性质）
Logic.subsec.predicate → Logic.def.eq → Logic.thm.eq_refl（自反性是等式的定义性行为）
```

---

## 四、跨条目 Binder 作用域

### 4.1 Context 声明变量

在 context 条目中用 `@` 绑定变量：
```snl
Set.ctxt.T:   Type.judge(@T, Type)
Set.ctxt.AB:  Type.judge(hyp-list(@A, @B), Set(T@Set.ctxt.T))
```

### 4.2 其他条目引用

使用 `x@srcEntry` 语法引用 context 中绑定的变量（**不带 `@` 前缀**）：
```snl
Set.def.union: def(
  Type.judge[paren](hyp-list(A@Set.ctxt.AB, B@Set.ctxt.AB), Set(T@Set.ctxt.T)),
  Set.union(A@Set.ctxt.AB, B@Set.ctxt.AB),
  Set.sep-typed(@x, T@Set.ctxt.T, Logic.or(Set.mem(x, A@Set.ctxt.AB), Set.mem(x, B@Set.ctxt.AB)))
)
```

- **不带 `@`**：`A@Set.ctxt.AB`（引用），不是 `@A@Set.ctxt.AB`（语法错误）
- 局部 binder 保留 `@`：`@x`、`@P`、`@a`、`@b`

### 4.3 def vs def-hyp

| 条件 | 宏 | 示例 |
|------|-----|------|
| 全部变量来自 context，无局部假设 | `def` | `def(Set(T@...), ...)` |
| 有局部 `@` binder | `def-hyp` | `def-hyp(Type.judge(@x, T@...), ...)` |
| 定理，有局部 binder | `def-hyp` 或 `thm-hyp` | `thm-hyp(Type.judge[paren](...))` |

---

## 五、Bvar 命名统一

Context 声明的变量名必须全局一致：

- Set theory：集合变量统一用 `A`, `B`（不对同一概念用 `s`, `t`, `S`）
- Logic propositional：命题变量统一用 `P`, `Q`
- 元素变量（`x`、`a`）作为局部 binder 保留

---

## 六、Content.snl 书写规约

### 6.1 纯宏树

`content.snl` 必须是单个宏树，不使用 `%...%` 文本块或 `$...$` LaTeX 块：

```snl
def-hyp(hyp-list(Type.judge(@T,Type),...), Set.union(A,B), Set.sep-typed(@x,T,...))
```

不是：
```snl
Set.statement(%Let A, B be sets. Their union is %, Set.union(A, B), %...%)
```

### 6.2 结构宏

- `def-hyp(hypotheses, term, body)` — 带假设的定义
- `def(term, body)` — 无局部假设的定义
- `thm-hyp(hypotheses, statement, witness)` — 定理（带假设）
- `hyp-list(#*)` — 逗号分隔的假设列表（dynamic_arity）

### 6.3 逻辑算子

使用类型论原语声明，**不写 Church 编码**：

```snl
Logic.def.and: def(Logic.and(P@Logic.ctxt.PQ, Q@Logic.ctxt.PQ),
                   Type.judge(Logic.and(P@..., Q@...), Proposition))
```

不是：
```snl
Logic.def.and: def-hyp(..., Logic.and(P,Q), ∀R:Prop, (P→Q→R)→R)
```

---

## 七、完整流程速查

1. **Phase 1**：起稿（scratch `.md` outline）
2. **Phase 2**：术语化（`term_macros/*.json` + `config.json`）
3. **Phase 3**：条目预制（`entries.json`，语义 ID）
4. **Phase 4**：库建构（`libraries/<slug>/{meta,graph}.json`，三级 branch 树）
5. **Phase 5**：语义索引（macro `source.entries` 回填）
6. **Lint**：`snl-lint-entry` / `snl-lint-package` / `snl-lint-graph`
7. **Push**：`git commit && git push`（每次写完立即推送）
