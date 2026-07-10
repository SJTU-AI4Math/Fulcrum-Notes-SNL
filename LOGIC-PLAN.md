# 数理逻辑章节分配计划（Plan）

> 基于 Fulcrum-Notes-Typst `03-TypeTheory/main.typ` 和已有宏包（Logic.json, TypeTheory.json）。

## 设计原则

- **类型论为元语言**：所有逻辑概念在类型论框架下表达（`Proposition`、`Type.judge`、`Type.to`）
- **复用已有宏**：`Logic.*` 已覆盖命题连接词和量词，`TypeTheory.*` 已覆盖类型判断
- **结构宏优先**：定义用 `def-hyp`/`def`，定理用 `thm-hyp`
- **Binder 作用域**：用 `@` 绑定变量，后续条目通过 context 共享 binder

## 当前已有宏

| 包 | 宏 | 用途 | 状态 |
|----|-----|------|------|
| Logic | `Logic.and` | ∧ | ✅ |
| Logic | `Logic.or` | ∨ | ✅ |
| Logic | `Logic.implies` | ⟹/⇒/→ | ✅ |
| Logic | `Logic.neg` | ¬ | ✅ |
| Logic | `Logic.iff` | ↔ | ✅ |
| Logic | `Logic.forall` | ∀ | ✅ |
| Logic | `Logic.forall-typed` | ∀ x : T, | ✅ |
| Logic | `Logic.exists` | ∃ | ✅ |
| Logic | `Logic.false` | False | ✅ |
| TypeTheory | `Type.judge` | x : T | ✅ |
| TypeTheory | `Type` | Type universe | ✅ |
| TypeTheory | `Proposition` | Prop | ✅ |
| TypeTheory | `Type.to` | → | ✅ |
| BasicOperators | `Eq` | = | ✅ |

## 需要新增的宏

| 宏 | 用途 | 模板 |
|----|------|------|
| `Logic.true` | True / ⊤ | `True` |
| `Logic.forall-typed` | ∀ x : T, P(x) | 已有，确认无误 |
| `Logic.exists-typed` | ∃ x : T, P(x) | `\exists #0 : #1, #2` |
| `Logic.not` | ¬ (prefix) | 别名 `Logic.neg`，便于可读 |

## 章节结构

### Section: Logic（`Logic.sec.logic`）

```
libraries/logic/
├── meta.json
└── graph.json
```

Context entries:
- `Logic.ctxt.T` — `Type.judge(@T,Type)` （类型变量）
- `Logic.ctxt.PQ` — `Type.judge(hyp-list(@P,@Q),Type.to(T,Proposition))` （命题变量）

---

#### Phase 1 — 命题逻辑基础（4-6 entry）

| ID | Kind | Title | SNL 概要 |
|----|------|-------|---------|
| `Logic.def.proposition` | definition | Proposition | `P : Type` 称为命题，当 `P : Proposition`（已由 TypeTheory 提供） |
| `Logic.def.true` | definition | True | `True := ∀ P : Prop, P → P` 或作为原子常量 |
| `Logic.def.and` | definition | Conjunction | `P ∧ Q := ∀ R : Prop, (P → Q → R) → R` |
| `Logic.def.or` | definition | Disjunction | `P ∨ Q := ∀ R : Prop, (P → R) → (Q → R) → R` |
| `Logic.def.implies` | definition | Implication | `P → Q : Prop`（由 Type.to 提供类型） |
| `Logic.def.neg` | definition | Negation | `¬P := P → False` |
| `Logic.def.iff` | definition | Equivalence | `P ↔ Q := (P → Q) ∧ (Q → P)` |

**依赖**：`Logic.true` 宏需新增。`Logic.and`/`Logic.or`/`Logic.implies`/`Logic.neg`/`Logic.iff` 宏已存在，只需定义条目。

---

#### Phase 2 — 谓词逻辑（3-5 entry）

| ID | Kind | Title | SNL 概要 |
|----|------|-------|---------|
| `Logic.def.forall` | definition | Universal Quantifier | `∀ x : T, P(x) : Prop` |
| `Logic.def.exists` | definition | Existential Quantifier | `∃ x : T, P(x) : Prop` |
| `Logic.def.eq` | definition | Equality | `Eq(a, b) : Prop`（已在 BasicOperators 中） |
| `Logic.thm.eq_refl` | theorem | Reflexivity of = | `∀ a : T, a = a` |
| `Logic.thm.eq_subst` | theorem | Substitution | `a = b → P(a) → P(b)` |

**依赖**：`Logic.exists-typed` 需新增。

---

#### Phase 3 — 自然演绎规则（6-10 theorem entry）

| ID | Kind | Title | SNL 概要 |
|----|------|-------|---------|
| `Logic.thm.and_intro` | theorem | ∧-引入 | `P → Q → P ∧ Q` |
| `Logic.thm.and_elim_left` | theorem | ∧-消去左 | `P ∧ Q → P` |
| `Logic.thm.and_elim_right` | theorem | ∧-消去右 | `P ∧ Q → Q` |
| `Logic.thm.or_intro_left` | theorem | ∨-引入左 | `P → P ∨ Q` |
| `Logic.thm.or_intro_right` | theorem | ∨-引入右 | `Q → P ∨ Q` |
| `Logic.thm.or_elim` | theorem | ∨-消去 | `P ∨ Q → (P → R) → (Q → R) → R` |
| `Logic.thm.implies_elim` | theorem | →-消去 (MP) | `(P → Q) → P → Q` |
| `Logic.thm.neg_elim` | theorem | ¬-消去 | `¬P → P → Q` (ex falso) |
| `Logic.thm.excluded_middle` | axiom | 排中律 | `P ∨ ¬P` (classical only) |

---

#### Phase 4 — λ-演算 / 类型论基础（3-5 entry，可选后延）

| ID | Kind | Title | SNL 概要 |
|----|------|-------|---------|
| `TypeTheory.def.lambda` | definition | λ-抽象 | `λ x : A, b` |
| `TypeTheory.def.app` | definition | 应用 | `f(a)` |
| `TypeTheory.rule.beta` | rule | β-规约 | `(λ x, b)(a) → b[x:=a]` |
| `TypeTheory.def.Pi` | definition | Π-类型 | `Π x : A, B(x)` |
| `TypeTheory.def.Sigma` | definition | Σ-类型 | `Σ x : A, B(x)` |

**依赖**：需新增 `Lambda` 或 `Pi` 宏包。此阶段可延后到 TypeTheory 独立章节。

---

## 优先级建议

1. **P0**：Phase 1 命题逻辑定义（true, and, or, implies, neg, iff）
2. **P1**：Phase 2 谓词逻辑（forall, exists, eq）
3. **P2**：Phase 3 自然演绎规则（作为 theorem，不写证明）
4. **P3**：Phase 4 λ-演算（延后到 TypeTheory 独立章节）

## 与已有 SetTheory 的关系

SetTheory 的 context（`Set.ctxt.T`）与 Logic 的 context（`Logic.ctxt.T`）是独立的命名空间。Logic 的 `T` 是任意类型，SetTheory 的 `T` 是集合的基类型——语义上不同，但在类型论框架下两者统一为 `Type.judge(@T, Type)`。
