# Fulcrum Notes SNL

This repository stores the canonical Fulcrum SNL workspace in `.SNL_Doc/` and provides a Lean project for checked integrations.

## Toolchain and dependencies

- Lean `v4.28.0`
- Mathlib `v4.28.0`
- Paperproof pinned to commit `69401f7d9348699e1532194734b5dda0771278b7`
- SNL4Lean as the Git submodule `Lean4/SNL4Lean`, pinned to commit `1176f5fb49c41e8a6dfb8839ad368f07b1e42829`

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

`BasicAlgebra.lean` enables `snl.macroWorkspaceFallback`: Widget Macro lookup
uses the position-bound Lean environment first, this repository's `.SNL_Doc`
second, and SNL-Basics' `fvar` rendering only after both sources miss. The
`Algebra.def.semigroup` Pointer stays attached to Semigroup's real declaration
in the pinned Mathlib checkout, using an anchored declaration regex rather than
a local `#print` occurrence.

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
