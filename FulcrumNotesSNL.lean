import Mathlib
import Paperproof
import SNL4Lean

namespace FulcrumNotesSNL

/-- Build smoke test for the pinned Lean and dependency graph. -/
example : (1 : Nat) + 1 = 2 := by
  norm_num

end FulcrumNotesSNL
