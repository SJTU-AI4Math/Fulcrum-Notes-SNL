# Fulcrum Notes SNL

This repository stores the canonical Fulcrum SNL workspace in `.SNL_Doc/` and provides a Lean project for checked integrations.

## Toolchain and dependencies

- Lean `v4.28.0`
- Mathlib `v4.28.0`
- Paperproof pinned to commit `69401f7d9348699e1532194734b5dda0771278b7`
- SNL4Lean as the Git submodule `vendor/SNL4Lean`, pinned to commit `27b02bd10c9a67d8ea43bfea730f9f3b008479fd`

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
