# 集合论章节分配计划（Plan）

> 基于猫猫（Fulcrum）`947e38c` 版本的 type-theoretic 设计风格（Mathlib.Set.Basics 模式）。

## 设计原则

- **Set(T) := T → Prop**：集合是类型索引的谓词，不是 ZFC 的原子对象
- **纯宏树**：`content.snl` = 宏组合，无 `%…%` 文本块，无 `$…$` LaTeX 块
- **结构性宏优先**：用 `def-hyp` / `def` / `hyp-list` 表达定义结构，prose 由宏生成
- **Binder 绑定**：所有变量用 `@` 标注作用域
- **Lean naming**：宏命名贴近 Mathlib 惯例（`mem`、`union`、`inter`、`diff`、`compl`）

## 当前已完成（`947e38c`）

| ID | Kind | Title | 状态 |
|----|------|-------|------|
| `Set.sec.set` | section | Set | ✅ |
| `Set.def.set` | definition | Set | ✅ |
| `Set.def.union` | definition | Union of sets | ✅ |
| `Set.def.symmetric_difference` | definition | Symmetric Difference of sets | ✅ |

## 扩展计划

### Section: Set（`Set.sec.set`）

继续在同一个 section 下添加定义和定理。所有条目归属同一 library `set-theory`。

---

#### Phase 1 — 补全基础定义（5-6 个新 entry）

| ID | Kind | Title | 内容概要 |
|----|------|-------|---------|
| `Set.def.mem` | definition | Membership | `a ∈ s := s a`（即集合作为谓词的应用） |
| `Set.def.subset` | definition | Subset | `s ⊆ t := ∀ x, x ∈ s → x ∈ t` |
| `Set.def.sep` | definition | Set Comprehension | `{x : T \| P x}`（对应已有的 `Set.sep-typed` 宏） |
| `Set.def.ext` | theorem/axiom | Extensionality | `s = t ↔ s ⊆ t ∧ t ⊆ s`（可从 `Set(T) = T → Prop` 推导，列 theorem） |
| `Set.def.emptyset` | definition | Empty Set | `∅ := {x \| False}` |
| `Set.def.univ` | definition | Universal Set | `univ := {x \| True}` |

**宏需求**：`Set.mem`/`Set.sep-typed`/`Set.emptyset` 已有；需新增 `Set.subset`（可复用 `Logic.implies` + `Set.mem` 组合），`Set.univ`。

---

#### Phase 2 — 补全运算定义（2-3 个新 entry）

| ID | Kind | Title | 内容概要 |
|----|------|-------|---------|
| `Set.def.inter` | definition | Intersection | `s ∩ t := {x \| x ∈ s ∧ x ∈ t}` |
| `Set.def.diff` | definition | Set Difference | `s \ t := {x \| x ∈ s ∧ x ∉ t}` |
| `Set.def.compl` | definition | Complement | `sᶜ := {x \| x ∉ s}` |

**宏需求**：`Set.inter`、`Set.diff`、`Set.compl` 宏已存在于 `SetTheory.json`，无需新增。`Set.notmem` 可能需要添加（或直接使用 `Logic.neg(Set.mem(x, s))`）。

---

#### Phase 3 — 代数律（5-8 个 theorem entry）

| ID | Kind | Title | 使用宏 |
|----|------|-------|--------|
| `Set.thm.union_comm` | theorem | Union Commutativity | `s ∪ t = t ∪ s` |
| `Set.thm.union_assoc` | theorem | Union Associativity | `(s ∪ t) ∪ u = s ∪ (t ∪ u)` |
| `Set.thm.inter_comm` | theorem | Intersection Commutativity | `s ∩ t = t ∩ s` |
| `Set.thm.inter_assoc` | theorem | Intersection Associativity | 同上模式 |
| `Set.thm.union_inter_distrib` | theorem | Distributivity | `s ∪ (t ∩ u) = (s ∪ t) ∩ (s ∪ u)` 和对偶 |
| `Set.thm.de_morgan` | theorem | De Morgan | `(s ∪ t)ᶜ = sᶜ ∩ tᶜ` 和对偶 |
| `Set.thm.diff_eq_inter_compl` | theorem | Difference as Intersection | `s \ t = s ∩ tᶜ` |

**宏需求**：需要等式宏 `Eq`（或直接用 `=`，与现有 `BasicOperators` 风格一致）。可能需要 `Set.notmem` 或直接用 `Logic.neg(Set.mem(...))`。

---

#### Phase 4 — 幂集（1-2 个新 entry）

| ID | Kind | Title | 内容概要 |
|----|------|-------|---------|
| `Set.def.powerset` | definition | Power Set | `𝒫(s) := {t \| t ⊆ s}` |
| `Set.thm.powerset_union` | theorem | Power Set of Union | `𝒫(s ∩ t) = 𝒫(s) ∩ 𝒫(t)` (可选) |

**宏需求**：需新增 `Set.powerset` 宏。

---

#### Phase 5 — 索引族运算（2-4 个新 entry，可选后延）

| ID | Kind | Title | 内容概要 |
|----|------|-------|---------|
| `Set.def.sUnion` | definition | Union of a Family | `⋃₀ S := {x \| ∃ s ∈ S, x ∈ s}` |
| `Set.def.sInter` | definition | Intersection of a Family | `⋂₀ S := {x \| ∀ s ∈ S, x ∈ s}` |
| `Set.def.image` | definition | Image | `f '' s := {y \| ∃ x ∈ s, f x = y}` |

**宏需求**：需新增 `Set.sUnion`、`Set.sInter`、`Set.image`；需要量词宏 `Logic.exists`、`Logic.forall`（`Logic.json` 当前无 `forall`/`exists`，需扩展）。

---

### 不纳入当前计划的内容

- **关系与笛卡尔积**（`Set.prod`、`Set.rel`）→ 独立章节 `Relation`
- **函数**（`Set.map`、`Set.injOn` 等）→ 独立章节 `Function`
- **有限集与基数** → 可能独立章节
- **良序与选择公理** → 需先有 Relation 基础

## 优先级建议

1. **P0（本周）**：Phase 1 基础定义（mem, subset, sep, ext, emptyset, univ）
2. **P1**：Phase 2 运算定义（inter, diff, compl）
3. **P2**：Phase 3 代数律（至少 union/inter 的 commutativity + associativity）
4. **P3**：Phase 4 幂集 + Phase 5 索引族

## 待扩展的宏

| 宏 | 所在包 | 状态 |
|----|--------|------|
| `Set.subset` | SetTheory | 待新增 |
| `Set.univ` | SetTheory | 待新增 |
| `Set.powerset` | SetTheory | 待新增 |
| `Set.notmem` | SetTheory | 待新增（或直接用 `Logic.neg ∘ Set.mem`） |
| `Logic.forall` | Logic | 待新增 |
| `Logic.exists` | Logic | 待新增 |
| `Set.sUnion` / `Set.sInter` / `Set.image` | SetTheory | Phase 5 时新增 |
