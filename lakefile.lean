import Lake
open Lake DSL

package «FulcrumNotesSNL» where
  version := v!"0.1.0"
  keywords := #["mathematics", "snl"]

require mathlib from git "https://github.com/leanprover-community/mathlib4" @ "v4.28.0"
require Paperproof from git "https://github.com/Paper-Proof/paperproof.git" @ "69401f7d9348699e1532194734b5dda0771278b7" / "lean"
require SNL4Lean from "Lean4/SNL4Lean"

@[default_target]
lean_lib «FulcrumNotesSNL»
