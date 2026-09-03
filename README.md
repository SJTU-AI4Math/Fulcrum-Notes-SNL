# Fulcrum Notes SNL

This repository stores the canonical Fulcrum SNL workspace in `.SNL_Doc/` and provides a Lean project for checked integrations.

## Toolchain and dependencies

- Lean `v4.28.0`
- Mathlib `v4.28.0`
- Paperproof pinned to commit `69401f7d9348699e1532194734b5dda0771278b7`
- SNL4Lean as the Git submodule `Lean4/SNL4Lean`, pinned to commit `65014d939378a55f7116d7ffec654d2685ba9353`

Lean sources use one fixed, module-valid hierarchy. Do not introduce spaces or
ad-hoc roots beneath `Lean4/`:

```text
Lean4/
├── FulcrumNotesSNL.lean
├── FulcrumNotesSNL/
│   ├── BasicAlgebra.lean
│   └── BasicAlgebra/
│       └── TermMacros.lean
└── SNL4Lean/                  # pinned Git submodule
```

Widget Macro lookup uses the position-bound Lean environment. A miss is returned
in an always-object RPC envelope and uses SNL-Basics' native presentation
fallback; explicit Lean node kinds remain intact. Project-root `.SNL_Doc`
lookup is deliberately disabled until it can reuse a fully validated and
symlink-confined canonical topology reader. The `Algebra.def.semigroup` Pointer
stays attached to Semigroup's real declaration in the pinned Mathlib checkout,
using an anchored declaration regex rather than a local `#print` occurrence.

## Clone

```bash
git clone --recurse-submodules git@github.com:SJTU-AI4Math/Fulcrum-Notes-SNL.git
cd Fulcrum-Notes-SNL
git submodule update --init --recursive
```

Access to the SNL4Lean repository is required when cloning its submodule.

## Resolve and build

```bash
lake update
lake exe cache get
lake build FulcrumNotesSNL
```

`lake-manifest.json` and the SNL4Lean gitlink pin the resolved dependency graph. Do not commit `.lake/` build artifacts.
