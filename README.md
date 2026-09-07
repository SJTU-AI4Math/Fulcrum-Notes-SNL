# Fulcrum Notes SNL

This repository stores the canonical Fulcrum SNL workspace in `.SNL_Doc/` and provides Lean companions to the authored notes. The root [FMNeco.md](FMNeco.md) is the authoring convention.

The experimental [Convincer](Convincer/README.md) implementation, examples and checks are contained in `Convincer/`.

## Toolchain and dependencies

- Lean `v4.28.0`
- Mathlib `v4.28.0`
- Paperproof pinned to commit `69401f7d9348699e1532194734b5dda0771278b7`
- SNL4Lean pinned by the Git submodule entry at `Lean4/SNL4Lean`

`lake-manifest.json` and the SNL4Lean gitlink are the dependency authority. Do not commit `.lake/` build artifacts or test fixtures.

## Authored Lean layout

Keep subject folders directly below `Lean4/`. Filesystem folders are not a requirement to rename mathematical namespaces or SNL entities.

```text
Lean4/
├── Basics/
│   └── term_macros.lean
├── Logic/
│   └── term_macros.lean
├── Functions/
│   └── term_macros.lean
├── Set Theory/
│   └── term_macros.lean
├── Basic Algebra/
│   ├── BasicAlgebra.lean
│   └── term_macros.lean
├── Linear Algebra/
│   ├── LinearAlgebra.lean
│   └── term_macros.lean
└── SNL4Lean/                  # pinned Git submodule, not authored notes
```

- `Basics` holds elementary material not yet assigned a narrower subject: law-free operation interfaces, primitive operations, elementary types, pairs and projections, numeric conversions and finite index types. Here `[n]` means `Fin n`, with zero-based indices and an empty type at `n = 0`.
- `Logic` covers logical predicates, decidability, emptiness and uniqueness.
- `Functions` covers function properties, inverses, equivalences, composition, identity and constant functions.
- `Set Theory` covers finiteness, restricted maps, pairwise predicates, products and graphs.
- `Basic Algebra` reuses native algebraic structures. `BasicAlgebra.lean` prints Mathlib's Semigroup rather than redefining it.
- `Linear Algebra` contains the textbook `Fulcrum.VectorSpace` (only `Add`, `Zero` and `SMul` parents, with all eight laws declared locally), its operation-preserving Mathlib bridges and the finite-family development. The scalar-field binder is written `𝕂` throughout these notes.

All authored `snl_notation` commands belong in the corresponding folder's `term_macros.lean`. Display prose in these Lean macros is English; canonical `.SNL_Doc` prose keeps its existing languages. Existing upstream default styles remain intact; additional `english` styles are named alternatives. Formula templates preserve complete-argument indices, including hidden type/instance operands. Actual infix formulas carry local binding powers.

The import chain is `Basics → Logic → Functions`, then `Basic Algebra` and `Set Theory`, then the linear-algebra terminology and notes. Each arrow means that the later module imports the earlier one. Shared imports avoid duplicate default-style registrations. The library explicitly lists the authored modules; it does not recursively collect the vendored SNL4Lean tree.

`snl_notation` registers a lexical constant name. This lets `Linear Algebra/term_macros.lean` register `Fulcrum.*` terminology before `LinearAlgebra.lean` declares those constants, without a circular import or a separate duplicate definition file. The consuming file imports its macros before the declarations, so the position-bound Widget environment sees them throughout the notes.

Write and inspect in source order: put `#snl_const_widget Name` immediately after each declaration. After a class, inspect the class and each generated projection before continuing; do not collect these commands into a preview block at the end. These are authored reading aids, not test guards.

In the linear-algebra notes, `VectorSpace` marks `𝕂` as `outParam` and registers its two proved, operation-preserving bridges as instances. A single selected textbook structure supplies `AddCommGroup V` and `Module 𝕂 V` automatically. This removes repeated consumer `letI` bindings without inheriting extra axioms. It is an inference convention, not uniqueness of the scalar field: with competing scalar structures or unrelated existing operations on the same carrier, select the intended structure explicitly.

The `Fulcrum.TermMacros.*` entries catalogue these registrations and point to their source files. Existing linear-algebra Entry identities and Library order are unchanged; their Pointers locate the relocated notes. `Algebra.def.semigroup` still points to the actual native declaration in the pinned Mathlib source, not a local `#print` occurrence.

## Clone

```bash
git clone --recurse-submodules git@github.com:SJTU-AI4Math/Fulcrum-Notes-SNL.git
cd Fulcrum-Notes-SNL
git submodule update --init --recursive
```

Access to the SNL4Lean repository is required when cloning its submodule.

## Resolve and check

After resolving the pinned dependencies and obtaining the Mathlib cache, build the small authored registry chain in order before directly checking the note files. Do not use a broad generated-module aggregate as a substitute for these explicit targets.

```bash
lake update
lake exe cache get
lake build Lean4.Basics.term_macros
lake build Lean4.Logic.term_macros
lake build Lean4.Functions.term_macros
lake build 'Lean4.«Set Theory».term_macros'
lake build 'Lean4.«Basic Algebra».term_macros'
lake build 'Lean4.«Linear Algebra».term_macros'
lake env lean 'Lean4/Basic Algebra/BasicAlgebra.lean'
lake env lean 'Lean4/Linear Algebra/LinearAlgebra.lean'
snl validate --root . --json
```
