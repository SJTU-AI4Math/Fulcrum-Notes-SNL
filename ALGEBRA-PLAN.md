# Basic Algebra — SNL Plan

> 源：Fulcrum-Notes-Typst `08-BasicAlgebra/main.typ` + `export.typ`

## 宏包 `Algebra.json`

| 宏 | 模板 | 来源 |
|----|------|------|
| `Algebra.Semigroup` | 半群谓词 | 08-BasicAlgebra export |
| `Algebra.Monoid` | 幺半群谓词 | 同上 |
| `Algebra.Group` | 群谓词 | 同上 |
| `Algebra.mul` | `#0 · #1`（群乘法） | 约定 |
| `Algebra.inv` | `#0^{-1}`（逆元） | 约定 |
| `Algebra.identity` | `e`（单位元） | 约定 |
| `Algebra.GHom` | Hom(G,H) | 同态记号 |
| `Algebra.Subgroup` | ≤ 符号 | 子群记号 |
| `Algebra.Ker` | Ker(f) | 核 |
| `Algebra.Im` | Im(f) | 像 |

可复用：`Logic.forall-typed`、`Eq`、`Set.sep-typed`、`Mul.mul`

## Library 结构

```
Algebra.sec.groupTheory (section)
├── Algebra.ctxt.1 (context: G, dot)
│   ├── Algebra.ctxt.G  (Type.judge(@G, Type))
│   └── Algebra.ctxt.mul (Type.judge(@dot, Type.to(G, Type.to(G, G))))
├── Algebra.subsec.definitions (subsection)
│   ├── Algebra.def.semigroup
│   ├── Algebra.def.monoid
│   │   └── Algebra.prop.identityUnique (property sub)
│   └── Algebra.def.group
└── Algebra.subsec.homomorphism (subsection)
    ├── Algebra.def.groupHom
    ├── Algebra.def.groupMono
    ├── Algebra.def.groupEpi
    ├── Algebra.def.groupIso
    └── Algebra.def.kernel + Algebra.def.image
```

## Phase 1 (本次): 群论基础

- Semigroup, Monoid, Group 定义
- 单位元唯一性（property）
- 宏包 Algebra.json（Semigroup, Monoid, Group, mul, inv, identity）
- Library + graph
