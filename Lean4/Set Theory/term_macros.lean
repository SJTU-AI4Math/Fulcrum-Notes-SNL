import Lean4.Functions.term_macros
import Mathlib.Data.Set.Operations
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

snl_notation Set.Finite => %#1 is finite%
snl_notation Set.Infinite => %#1 is infinite%
snl_notation Set.InjOn => %#2 is injective on #3%
snl_notation Set.SurjOn => %every element of #4 is the image under #2 of an element of #3%
snl_notation Set.BijOn => %#2 is a bijection from #3 onto #4%
snl_notation Set.MapsTo => %#2 maps #3 into #4%
snl_notation Set.Pairwise => %#2 holds for every ordered pair of distinct elements of #1%

snl_notation Set.range => $\operatorname{range}(#2)$
-- Match Mathlib.Data.SProd's right-associative binding power 82; the full
-- child vector includes the two implicit carrier types.
snl_notation Set.prod => $#2 \times #3$ : [0, 0, 83, 82] -> 82
-- Surface syntax `s ×ˢ t` elaborates to the overloaded projection, not Set.prod.
snl_notation SProd.sprod => $#4 \times #5$ : [0, 0, 0, 0, 83, 82] -> 82
snl_notation Set.diagonal => $\Delta_{#0}$
snl_notation Set.offDiag => $\operatorname{offDiag}(#1)$
snl_notation Set.EqOn => %#2 and #3 agree on #4%
snl_notation Set.graphOn => $\operatorname{graph}_{#3}(#2)$
snl_notation Set.LeftInvOn => %#2 is a left inverse of #3 on #4%
snl_notation Set.RightInvOn => %#2 is a right inverse of #3 on #4%
snl_notation Set.InvOn => %#2 is a left inverse of #3 on #4 and a right inverse of #3 on #5%

-- Existing upstream formula defaults remain intact; only named styles are new.
snl_notation Set.Subset[english] => %#1 is a subset of #2%
snl_notation Set.Nonempty[english] => %#1 is nonempty%

end SNL4Lean
