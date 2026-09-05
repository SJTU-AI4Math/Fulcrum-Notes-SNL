# Fulcrum Notes SNL

This repository stores the canonical Fulcrum SNL workspace in `.SNL_Doc/` and provides a Lean project for checked integrations.

The experimental [Convincer](Convincer/README.md) implementation, examples and checks are contained in `Convincer/`.

## Toolchain and dependencies

- Lean `v4.28.0`
- Mathlib `v4.28.0`
- Paperproof pinned to commit `69401f7d9348699e1532194734b5dda0771278b7`
- SNL4Lean as the Git submodule `Lean4/SNL4Lean`, pinned to commit `1dd708a9a5328c99f59d6054258c8cd52768b536`

Lean sources keep the repository's shallow authored layout. `Basic Algebra` is a
direct child of `Lean4/`; do not reorganize it into a namespace-shaped directory:

```text
Lean4/
├── Basic Algebra/
│   ├── BasicAlgebra.lean
│   └── term_macros.lean
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
lake env lean 'Lean4/Basic Algebra/BasicAlgebra.lean'
```

`lake-manifest.json` and the SNL4Lean gitlink pin the resolved dependency graph. Do not commit `.lake/` build artifacts.
