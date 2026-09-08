import Lake
open Lake DSL

package «FulcrumNotesSNL» where
  version := v!"0.1.0"
  keywords := #["mathematics", "snl"]

require mathlib from git "https://github.com/leanprover-community/mathlib4" @ "v4.28.0"
require Paperproof from git "https://github.com/Paper-Proof/paperproof.git" @ "69401f7d9348699e1532194734b5dda0771278b7" / "lean"
require SNL4Lean from "Lean4/SNL4Lean"

@[default_target]
lean_lib «FulcrumNotesSNL» where
  roots := #[
    `Lean4.Basics.term_macros,
    `Lean4.Basics.term_macros_CN,
    `Lean4.Logic.term_macros,
    `Lean4.Logic.term_macros_CN,
    `Lean4.Functions.term_macros,
    `Lean4.Functions.term_macros_CN,
    `Lean4.«Set Theory».term_macros,
    `Lean4.«Set Theory».term_macros_CN,
    `Lean4.«Basic Algebra».term_macros,
    `Lean4.«Basic Algebra».term_macros_CN,
    `Lean4.«Basic Algebra».BasicAlgebra,
    `Lean4.«Linear Algebra».term_macros,
    `Lean4.«Linear Algebra».term_macros_CN,
    `Lean4.«Linear Algebra».LinearAlgebra
  ]

-- Small standalone argument DSL; no Mathlib or SNL4Lean imports.
lean_lib Convincer where
  srcDir := "Convincer"
