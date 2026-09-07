import Lean4.Functions.term_macros
import Mathlib.Data.Set.Basic
import Mathlib.Data.Set.Operations
import Mathlib.Order.SetNotation
import Mathlib.Data.Finite.Defs
import Mathlib.Logic.Pairwise

/-!
# Set-theory terminology (Lean / Mathlib 4.28.0)

Full Expr child indices include implicit type parameters. These registrations
are for the native declarations, not newly defined mathematical aliases.
`SurjOn` only asserts coverage of the target: unlike `BijOn`, it does not assert
that every source element maps into that target. `InvOn` similarly asserts the
two inverse identities, not additional set-mapping hypotheses.
-/

namespace SNL4Lean

-- Formula defaults formerly supplied by SNL4Lean.TermMacros.Mathlib.
-- Keep these before the consumer-owned named English styles below.
-- Match Mathlib.Data.SProd's right-associative binding power 82; the full
-- child vector includes the two implicit carrier types.

-- Surface syntax `s ×ˢ t` elaborates to the overloaded projection, not Set.prod.

-- Existing upstream formula defaults remain intact; only named styles are new.

-- Mathlib/
--   Data/
--     Finite/
--       Defs.lean
snl_notation Set.Finite => %#1 is finite%
snl_notation Set.Infinite => %#1 is infinite%

-- Mathlib/
--   Data/
--     SProd.lean
snl_notation SProd.sprod => $#4 \times #5$ : [0, 0, 0, 0, 83, 82] -> 82

-- Mathlib/
--   Data/
--     Set/
--       CoeSort.lean
snl_macro { name := "Set.Elem", kind := "const", mode := "formula_inline", template := "\\operatorname{Elem}(#1)" }

-- Mathlib/
--   Data/
--     Set/
--       Defs.lean
snl_notation Set => $\operatorname{Set} #0$
snl_macro { name := "setOf", kind := "const", mode := "formula_inline", template := "\\left\\{#1\\right\\}" }
snl_macro { name := "Set.Mem", kind := "const", mode := "formula_inline", template := "#2 \\in #1" }
snl_notation Set.Subset => $#1 \subseteq #2$
snl_notation Set.Subset[english] => %#1 is a subset of #2%
snl_macro { name := "Set.univ", kind := "const", mode := "formula_inline", template := "\\mathsf{U}" }
snl_macro { name := "Set.insert", kind := "const", mode := "formula_inline", template := "\\left\\{#1\\right\\} \\cup #2" }
snl_macro { name := "Set.singleton", kind := "const", mode := "formula_inline", template := "\\left\\{#1\\right\\}" }
snl_notation Set.union => $#1 \cup #2$
snl_notation Set.inter => $#1 \cap #2$
snl_notation Set.compl => $#1^{\mathsf c}$
snl_notation Set.diff => $#1 \setminus #2$
snl_macro { name := "Set.powerset", kind := "const", mode := "formula_inline", template := "\\mathcal{P}(#1)" }
snl_macro { name := "Set.image", kind := "const", mode := "formula_inline", template := "#2 '' #3" }
snl_macro { name := "Set.Nonempty", kind := "const", mode := "formula_inline", template := "#1 \\ne \\varnothing" }
snl_notation Set.Nonempty[english] => %#1 is nonempty%

-- Mathlib/
--   Data/
--     Set/
--       Operations.lean
snl_macro { name := "Set.preimage", kind := "const", mode := "formula_inline", template := "#2^{-1}(#3)" }
snl_notation Set.range => $\operatorname{range}(#2)$
snl_notation Set.prod => $#2 \times #3$ : [0, 0, 83, 82] -> 82
snl_notation Set.diagonal => $\Delta_{#0}$
snl_notation Set.offDiag => $\operatorname{offDiag}(#1)$
snl_notation Set.EqOn => %#2 and #3 agree on #4%
snl_notation Set.MapsTo => %#2 maps #3 into #4%
snl_notation Set.InjOn => %#2 is injective on #3%
snl_notation Set.graphOn => $\operatorname{graph}_{#3}(#2)$
snl_notation Set.SurjOn => %every element of #4 is the image under #2 of an element of #3%
snl_notation Set.BijOn => %#2 is a bijection from #3 onto #4%
snl_notation Set.LeftInvOn => %#2 is a left inverse of #3 on #4%
snl_notation Set.RightInvOn => %#2 is a right inverse of #3 on #4%
snl_notation Set.InvOn => %#2 is a left inverse of #3 on #4 and a right inverse of #3 on #5%

-- Mathlib/
--   Logic/
--     Pairwise.lean
snl_notation Set.Pairwise => %#2 holds for every ordered pair of distinct elements of #1%

-- Mathlib/
--   Order/
--     Notation.lean
snl_notation Compl.compl => $#2^{\mathsf c}$

-- Mathlib/
--   Order/
--     SetNotation.lean
snl_macro { name := "Set.sInter", kind := "const", mode := "formula_inline", template := "\\bigcap #1" }
snl_macro { name := "Set.sUnion", kind := "const", mode := "formula_inline", template := "\\bigcup #1" }
snl_macro { name := "Set.iUnion", kind := "const", mode := "formula_inline", template := "\\bigcup #2" }
snl_macro { name := "Set.iInter", kind := "const", mode := "formula_inline", template := "\\bigcap #2" }

end SNL4Lean
