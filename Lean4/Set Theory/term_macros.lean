import Lean4.Functions.term_macros
import Mathlib.Data.Nat.Cast.Defs
import Mathlib.Logic.Denumerable
import Mathlib.Logic.Encodable.Basic
import Mathlib.Logic.Equiv.Set
import Mathlib.Order.RelIso.Basic
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
snl_macro { name := "setOf", kind := "const", mode := "formula_inline", template := "\\operatorname{setOf}\\left(#1\\right)" }
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


-- Canonical authoring alignment: native full slots and retained named styles.
snl_macro { name := "Fulcrum.BinaryOperation", style := "default", kind := "const", mode := "formula_inline", template := "\\operatorname{Bop}(#0)" }
snl_macro { name := "Fulcrum.BinaryOperation", style := "authored", kind := "const", mode := "formula_inline", template := "\\operatorname{Bop}(#0)" }
snl_macro { name := "Fulcrum.BinaryOperation.apply", style := "default", kind := "const", mode := "formula_inline", template := "#2#1#3" }
snl_macro { name := "Fulcrum.BinaryOperation.apply", style := "conj", kind := "const", mode := "formula_inline", template := "#2#1#3" }
snl_macro { name := "Fulcrum.BinaryOperation.apply", style := "paren", kind := "const", mode := "formula_inline", template := "\\left(#2#1#3\\right)" }
snl_macro { name := "SetRel", style := "default", kind := "const", mode := "formula_inline", template := "\\operatorname{SetRel}(#0,#1)" }
snl_macro { name := "SetRel", style := "authored", kind := "const", mode := "formula_inline", template := "\\operatorname{Rl}(#0, #1)" }
snl_macro { name := "Set", style := "text", kind := "const", mode := "formula_inline", template := "\\operatorname{Set}#0" }
snl_macro { name := "Set", style := "paren", kind := "const", mode := "formula_inline", template := "\\operatorname{Set}\\left(#0\\right)" }
snl_macro { name := "Set.Mem", style := "authored", kind := "const", mode := "formula_inline", template := "#2 \\in #1" }
snl_macro { name := "Set.Mem", style := "single", kind := "const", mode := "formula_inline", template := "\\in" }
snl_macro { name := "Set.Subset", style := "infix", kind := "const", mode := "formula_inline", template := "#1 \\subseteq #2" }
snl_macro { name := "EmptyCollection.emptyCollection", style := "round", kind := "const", mode := "formula_inline", template := "\\varnothing" }
snl_macro { name := "EmptyCollection.emptyCollection", style := "slim", kind := "const", mode := "formula_inline", template := "\\emptyset" }
snl_macro { name := "Set.univ", style := "typed", kind := "const", mode := "formula_inline", template := "\\mathcal{U}_{#0}" }
snl_macro { name := "Set.univ", style := "untyped", kind := "const", mode := "formula_inline", template := "\\mathcal{U}" }
snl_macro { name := "Set.union", style := "authored", kind := "const", mode := "formula_inline", template := "#1 \\cup #2" }
snl_macro { name := "Set.inter", style := "authored", kind := "const", mode := "formula_inline", template := "#1 \\cap #2" }
snl_macro { name := "Set.compl", style := "sup", kind := "const", mode := "formula_inline", template := "#1^{\\mathrm{C}}" }
snl_macro { name := "Set.compl", style := "prefix", kind := "const", mode := "formula_inline", template := "\\complement #1" }
snl_macro { name := "Set.compl", style := "overline", kind := "const", mode := "formula_inline", template := "\\overline{#1}" }
snl_macro { name := "Set.diff", style := "backslash", kind := "const", mode := "formula_inline", template := "#1 \\setminus #2" }
snl_macro { name := "Set.diff", style := "sub", kind := "const", mode := "formula_inline", template := "#1 - #2" }
snl_macro { name := "Set.diff", style := "relative_sup", kind := "const", mode := "formula_inline", template := "#2^{\\mathrm{C}}" }
snl_macro { name := "Set.diff", style := "relative_prefix", kind := "const", mode := "formula_inline", template := "\\complement #2" }
snl_macro { name := "Set.diff", style := "relative_overline", kind := "const", mode := "formula_inline", template := "\\overline{#2}" }
snl_macro { name := "Set.powerset", style := "script", kind := "const", mode := "formula_inline", template := "\\mathcal{P}(#1)" }
snl_macro { name := "Set.powerset", style := "exponential", kind := "const", mode := "formula_inline", template := "2^{#1}" }
snl_macro { name := "Set.prod", style := "authored", kind := "const", mode := "formula_inline", template := "#2 \\times #3" }
snl_macro { name := "symmDiff", style := "default", kind := "const", mode := "formula_inline", template := "#3\\mathbin{\\triangle}#4" }
snl_macro { name := "symmDiff", style := "infix", kind := "const", mode := "formula_inline", template := "#3 \\triangle #4" }
snl_macro { name := "Fulcrum.SetFunction.domain", style := "default", kind := "const", mode := "formula_inline", template := "\\operatorname{dom}(#4)" }
snl_macro { name := "Fulcrum.SetFunction.domain", style := "authored", kind := "const", mode := "formula_inline", template := "\\operatorname{dom}#4" }
snl_macro { name := "Fulcrum.SetFunction.codomain", style := "default", kind := "const", mode := "formula_inline", template := "\\operatorname{codom}(#4)" }
snl_macro { name := "Fulcrum.SetFunction.codomain", style := "authored", kind := "const", mode := "formula_inline", template := "\\operatorname{codom}#4" }
snl_macro { name := "Set.range", style := "op_im", kind := "const", mode := "formula_inline", template := "\\operatorname{im}#2" }
snl_macro { name := "Set.range", style := "op_ran", kind := "const", mode := "formula_inline", template := "\\operatorname{ran}#2" }
snl_macro { name := "Set.image", style := "authored", kind := "const", mode := "formula_inline", template := "#2(#3)" }
snl_macro { name := "Set.preimage", style := "authored", kind := "const", mode := "formula_inline", template := "#2^{-1}(#3)" }
snl_macro { name := "Function.graph", style := "default", kind := "const", mode := "formula_inline", template := "\\operatorname{graph}(#2)" }
snl_macro { name := "Function.graph", style := "authored", kind := "const", mode := "formula_inline", template := "\\Gamma(#2)" }
snl_macro { name := "Function.Injective", style := "authored", kind := "const", mode := "formula_inline", template := "#2\\text{ 是单射}" }
snl_macro { name := "Function.Surjective", style := "authored", kind := "const", mode := "formula_inline", template := "#2\\text{ 是满射}" }
snl_macro { name := "Function.Surjective", style := "arrow", kind := "const", mode := "formula_inline", template := "#2:#0\\twoheadrightarrow #1" }
snl_macro { name := "Function.Bijective", style := "authored", kind := "const", mode := "formula_inline", template := "#2\\text{ 是双射}" }
snl_macro { name := "Equiv.symm", style := "default", kind := "const", mode := "formula_inline", template := "#2^{-1}" }
snl_macro { name := "Equiv.symm", style := "authored", kind := "const", mode := "formula_inline", template := "#2 ^{-1}" }
snl_macro { name := "Equiv.symm", style := "paren", kind := "const", mode := "formula_inline", template := "(#2)^{-1}" }
snl_macro { name := "Cardinal.mk", style := "default", kind := "const", mode := "formula_inline", template := "\\# #0" }
snl_macro { name := "Cardinal.mk", style := "op_card", kind := "const", mode := "formula_inline", template := "\\operatorname{card}#0" }
snl_macro { name := "Cardinal.mk", style := "vert", kind := "const", mode := "formula_inline", template := "\\left\\lvert #0 \\right\\rvert" }
snl_macro { name := "Set.Finite", style := "text", kind := "const", mode := "formula_inline", template := "#1\\text{ 是有限集}" }
snl_macro { name := "Set.Countable", style := "default", kind := "const", mode := "formula_inline", template := "#1\\text{ is at most countable}" }
snl_macro { name := "Prod.mk", style := "authored", kind := "const", mode := "formula_inline", template := "\\left(#2, #3\\right)" }
snl_macro { name := "RelIso", style := "default", kind := "const", mode := "formula_inline", template := "\\operatorname{RelIso}(#2,#3)" }
snl_macro { name := "IsStrictOrder", style := "default", kind := "const", mode := "formula_inline", template := "\\operatorname{IsStrictOrder}(#0,#1)" }
snl_macro { name := "IsStrictOrder", style := "variant", kind := "const", mode := "formula_inline", template := "\\operatorname{IsStrictOrder}(#0,#1)" }
snl_macro { name := "IsStrictTotalOrder", style := "default", kind := "const", mode := "formula_inline", template := "\\operatorname{IsStrictTotalOrder}(#0,#1)" }
snl_macro { name := "IsStrictTotalOrder", style := "variant", kind := "const", mode := "formula_inline", template := "\\operatorname{IsStrictTotalOrder}(#0,#1)" }
snl_macro { name := "IsGreatest", style := "default", kind := "const", mode := "formula_inline", template := "#3\\text{ is greatest in }#2" }
snl_macro { name := "IsGreatest", style := "text", kind := "const", mode := "formula_inline", template := "#3\\text{ is greatest in }#2" }
snl_macro { name := "IsGreatest", style := "simple", kind := "const", mode := "formula_inline", template := "#3\\text{ is greatest in }#2" }
snl_macro { name := "IsLeast", style := "default", kind := "const", mode := "formula_inline", template := "#3\\text{ is least in }#2" }
snl_macro { name := "IsLeast", style := "text", kind := "const", mode := "formula_inline", template := "#3\\text{ is least in }#2" }
snl_macro { name := "IsLeast", style := "simple", kind := "const", mode := "formula_inline", template := "#3\\text{ is least in }#2" }
snl_macro { name := "Maximal", style := "default", kind := "const", mode := "formula_inline", template := "#3\\text{ is maximal in }#2" }
snl_macro { name := "Maximal", style := "full", kind := "const", mode := "formula_inline", template := "#3\\text{ is maximal in }#2" }
snl_macro { name := "Minimal", style := "default", kind := "const", mode := "formula_inline", template := "#3\\text{ is minimal in }#2" }
snl_macro { name := "Minimal", style := "full", kind := "const", mode := "formula_inline", template := "#3\\text{ is minimal in }#2" }
snl_macro { name := "upperBounds", style := "default", kind := "const", mode := "formula_inline", template := "\\operatorname{upperBounds}(#2)" }
snl_macro { name := "upperBounds", style := "simple", kind := "const", mode := "formula_inline", template := "\\operatorname{upperBounds}(#2)" }
snl_macro { name := "lowerBounds", style := "default", kind := "const", mode := "formula_inline", template := "\\operatorname{lowerBounds}(#2)" }
snl_macro { name := "lowerBounds", style := "simple", kind := "const", mode := "formula_inline", template := "\\operatorname{lowerBounds}(#2)" }
snl_macro { name := "IsLUB", style := "default", kind := "const", mode := "formula_inline", template := "#3\\text{ is a least upper bound of }#2" }
snl_macro { name := "IsLUB", style := "full", kind := "const", mode := "formula_inline", template := "#3\\text{ is a least upper bound of }#2" }
snl_macro { name := "IsGLB", style := "default", kind := "const", mode := "formula_inline", template := "#3\\text{ is a greatest lower bound of }#2" }
snl_macro { name := "IsGLB", style := "full", kind := "const", mode := "formula_inline", template := "#3\\text{ is a greatest lower bound of }#2" }
snl_macro { name := "setOf", style := "builder", kind := "const", mode := "formula_inline", template := "\\left\\{#0\\mid #2\\right\\}" }
snl_macro { name := "setOf", style := "typedBuilder", kind := "const", mode := "formula_inline", template := "\\left\\{#0:#1\\mid #2\\right\\}" }
snl_macro { name := "Cardinal", style := "default", kind := "const", mode := "formula_inline", template := "\\operatorname{Cardinal}" }
snl_macro { name := "Countable", style := "default", kind := "const", mode := "formula_inline", template := "#0\\text{ is at most countable}" }
snl_macro { name := "Denumerable", style := "default", kind := "const", mode := "formula_inline", template := "\\operatorname{Denumerable}(#0)" }
snl_macro { name := "Rel", style := "default", kind := "const", mode := "formula_inline", template := "\\operatorname{Rel}(#0,#1)" }
snl_macro { name := "sSup", style := "default", kind := "const", mode := "formula_inline", template := "\\sup #2" }
snl_macro { name := "Nat.succ", style := "function", kind := "const", mode := "formula_inline", template := "\\operatorname{succ}" }
snl_macro { name := "PSet.ofNat", style := "default", kind := "const", mode := "formula_inline", template := "\\operatorname{PSet.ofNat}(#0)" }
snl_macro { name := "Set.Elem", style := "coerce", kind := "const", mode := "formula_inline", template := "#1" }
snl_macro { name := "Set.insert", style := "enumOuter", kind := "const", mode := "formula_inline", template := "\\left\\{#1,#2\\right\\}" }
snl_macro { name := "Set.insert", style := "enumInner", kind := "const", mode := "formula_inline", template := "#1,#2" }
snl_macro { name := "Set.singleton", style := "enumInner", kind := "const", mode := "formula_inline", template := "#1" }

/-- A set builder is a presentation view of `setOf`, not a new logical constant.
The original expression and lambda's binding evidence remain on the raw tree. -/
@[snl_delab app setOf]
meta def delabSetBuilder : SnlDelab := fun request => do
  let .expr expr := request.input | return none
  let tree := request.defaultTree
  let args := expr.consumeMData.getAppArgs
  unless args.size == 2 && tree.children.size == 2 do return none
  let .lam .. := args[1]!.consumeMData | return none
  let family := tree.children[1]!
  unless family.kind == "rule" && family.macro_name == "Type.lambda" &&
      family.children.size == 3 do return none
  return some {
    macro_name := "setOf", kind := "const", style_name? := some "typedBuilder"
    children := #[withLeanSourcePath family.children[0]! #[1, 0],
      withLeanSourcePath family.children[1]! #[1, 1],
      withLeanSourcePath family.children[2]! #[1, 2]]
    mdata := Lean.Json.mkObj [
      ("leanDelabOrigin", Lean.toJson "setOf"),
      ("leanBinderScope", Lean.Json.mkObj [
        ("binder", Lean.toJson (0 : Nat)), ("bodies", Lean.toJson (#[2] : Array Nat))])]
  }

-- Structural primitives used in the native set/order declarations.
snl_macro { name := "LE.le", kind := "const", mode := "formula_inline", template := "#2\\le #3" }
snl_macro { name := "LT.lt", kind := "const", mode := "formula_inline", template := "#2<#3" }
snl_macro { name := "LE", kind := "const", mode := "formula_inline", template := "\\operatorname{LE}(#0)" }
snl_macro { name := "LT", kind := "const", mode := "formula_inline", template := "\\operatorname{LT}(#0)" }
snl_macro { name := "Finite", kind := "const", mode := "formula_inline", template := "\\operatorname{Finite}(#0)" }
snl_macro { name := "Equiv.mk", kind := "const", mode := "formula_inline", template := "\\left\\langle #2,#3,#4,#5\\right\\rangle" }
snl_macro { name := "Equiv.toFun", kind := "const", mode := "formula_inline", template := "#2" }
snl_macro { name := "Equiv.invFun", kind := "const", mode := "formula_inline", template := "#2^{-1}" }
snl_macro { name := "Equiv.left_inv", kind := "const", mode := "formula_inline", template := "\\mathsf{left\\_inv}(#2)" }
snl_macro { name := "Equiv.right_inv", kind := "const", mode := "formula_inline", template := "\\mathsf{right\\_inv}(#2)" }
snl_macro { name := "Std.Irrefl", kind := "const", mode := "formula_inline", template := "\\operatorname{Irrefl}(#1)" }
snl_macro { name := "IsTrans", kind := "const", mode := "formula_inline", template := "\\operatorname{IsTrans}(#1)" }
snl_macro { name := "PartialOrder", kind := "const", mode := "formula_inline", template := "\\operatorname{PartialOrder}(#0)" }
snl_macro { name := "LinearOrder", kind := "const", mode := "formula_inline", template := "\\operatorname{LinearOrder}(#0)" }

-- Terminology used by the actual native declaration bodies and members.
-- The complete native telescopes were checked, including instance/proof operands.

-- Init/Core.lean
-- Slots: 0:α
snl_macro { name := "HasSubset", kind := "const", mode := "text", template := "The type of subset-relation structures on #0" }
-- Slots: 0:α
snl_macro { name := "SDiff", kind := "const", mode := "text", template := "The type of set-difference-operation structures on #0, without set-theoretic laws" }
-- Slots: 0:α
snl_macro { name := "EmptyCollection", kind := "const", mode := "text", template := "The type of structures specifying an empty element of #0, without emptiness laws" }
-- Slots: 0:α, 1:emptyCollection
snl_macro { name := "EmptyCollection.mk", kind := "const", mode := "formula_inline", template := "\\{\\mathsf{empty}:=#1\\}" }
-- Slots: 0:α, 1:s
snl_macro { name := "Quotient", kind := "const", mode := "formula_inline", template := "#0/{#1}" }
-- Slots: 0:α, 1:r
snl_macro { name := "Std.Refl", kind := "const", mode := "text", template := "#1 is reflexive" }
-- Slots: 0:α, 1:r
snl_macro { name := "Std.Antisymm", kind := "const", mode := "text", template := "#1 is antisymmetric" }
-- Slots: 0:α, 1:r
snl_macro { name := "Std.Trichotomous", kind := "const", mode := "text", template := "#1 is trichotomous" }

-- Init/Data/Nat/Basic.lean
-- Slots: 0:m, 1:n
snl_macro { name := "Nat.le_total", kind := "const", mode := "formula_inline", template := "\\operatorname{total}_{\\le_{\\mathbb N}}(#0,#1)" }
-- Slots: 0:m, 1:n
snl_macro { name := "Nat.lt_iff_le_not_le", kind := "const", mode := "text", template := "The strict-order characterization for natural numbers #0 and #1" }
-- Slots: 0:n
snl_macro { name := "Nat.instNeZeroSucc", kind := "const", mode := "text", template := "The nonzero witness for the successor of #0" }
-- Slots:
snl_macro { name := "Nat.instMax", kind := "const", mode := "text", template := "The usual maximum-operation structure on natural numbers" }

-- Init/Data/Option/Instances.lean
-- Slots: 0:α
snl_macro { name := "Option.instMembership", kind := "const", mode := "text", template := "The membership structure for values of #0 in optional values" }

-- Init/Data/Ord/Basic.lean
-- Slots:
snl_macro { name := "instOrdNat", kind := "const", mode := "text", template := "The usual comparison-operation structure on natural numbers" }

-- Init/Prelude.lean
-- Slots: 0:α, 1:i
snl_macro { name := "inferInstance", kind := "const", mode := "formula_inline", template := "#1" }
-- Slots: 0:motive, 1:t
snl_macro { name := "Nat.below", kind := "const", mode := "text", template := "The type of course-of-values recursion hypotheses below #1 for motive #0" }
-- Slots: 0:motive, 1:t, 2:F_1
snl_macro { name := "Nat.brecOn", kind := "const", mode := "text", template := "Course-of-values recursion at #1 with motive #0 and step #2" }
-- Slots: 0:n
snl_macro { name := "instOfNatNat", kind := "const", mode := "text", template := "The OfNat instance interpreting the literal #0 in natural numbers" }
-- Slots: 0:α, 1:le
snl_macro { name := "LE.mk", kind := "const", mode := "formula_inline", template := "\\{\\mathsf{le}:=#1\\}" }
-- Slots: 0:α, 1:lt
snl_macro { name := "LT.mk", kind := "const", mode := "formula_inline", template := "\\{\\mathsf{lt}:=#1\\}" }
-- Slots: 0:α, 1:inst._@.Init.Prelude.1048366004._hygCtx._hyg.3
snl_macro { name := "DecidableLT", kind := "const", mode := "text", template := "The type of decision procedures for the supplied strict relation on #0" }
-- Slots: 0:α, 1:inst._@.Init.Prelude.217401435._hygCtx._hyg.3
snl_macro { name := "DecidableLE", kind := "const", mode := "text", template := "The type of decision procedures for the supplied non-strict relation on #0" }
-- Slots: 0:α
snl_macro { name := "Max", kind := "const", mode := "text", template := "The type of binary-operation structures named max on #0, without order laws" }
-- Slots: 0:α, 1:self, 2:a._@._internal._hyg.0, 3:a._@._internal._hyg.0
snl_macro { name := "Max.max", kind := "const", mode := "formula_inline", template := "\\max_{#1}(#2,#3)" }
-- Slots: 0:α, 1:β, 2:inst._@.Init.Prelude.3805852345._hygCtx._hyg.9
snl_macro { name := "instHPow", kind := "const", mode := "text", template := "The heterogeneous-power structure obtained from the power structure #2" }
-- Slots:
snl_macro { name := "instDecidableEqNat", kind := "const", mode := "text", template := "The equality decision procedure on natural numbers" }
-- Slots: 0:n, 1:a._@._internal._hyg.0
snl_macro { name := "Nat.le", kind := "const", mode := "formula_inline", template := "#0\\le #1" }
-- Slots: 0:n, 1:m
snl_macro { name := "Nat.lt", kind := "const", mode := "formula_inline", template := "#0<#1" }
-- Slots: 0:n, 1:m, 2:k, 3:a._@._internal._hyg.0, 4:a._@._internal._hyg.0
snl_macro { name := "Nat.le_trans", kind := "const", mode := "formula_inline", template := "\\operatorname{trans}_{\\le_{\\mathbb N}}(#3,#4)" }
-- Slots: 0:n
snl_macro { name := "Nat.le_refl", kind := "const", mode := "formula_inline", template := "\\operatorname{refl}_{\\le_{\\mathbb N}}(#0)" }
-- Slots: 0:n, 1:m, 2:h₁, 3:h₂
snl_macro { name := "Nat.le_antisymm", kind := "const", mode := "formula_inline", template := "\\operatorname{antisymm}_{\\le_{\\mathbb N}}(#2,#3)" }
-- Slots: 0:n, 1:m
snl_macro { name := "Nat.decLe", kind := "const", mode := "text", template := "The decision procedure for #0 ≤ #1 in natural numbers" }
-- Slots: 0:n, 1:m
snl_macro { name := "Nat.decLt", kind := "const", mode := "text", template := "The decision procedure for #0 < #1 in natural numbers" }
-- Slots:
snl_macro { name := "instMinNat", kind := "const", mode := "text", template := "The usual minimum-operation structure on natural numbers" }
-- Slots: 0:α, 1:val
snl_macro { name := "Option.some", kind := "const", mode := "formula_inline", template := "\\operatorname{some}(#1)" }

-- Mathlib/Data/Finite/Defs.lean
-- Slots: 0:α
snl_macro { name := "Infinite", kind := "const", mode := "text", template := "#0 is infinite" }

-- Mathlib/Data/FunLike/Basic.lean
-- Slots: 0:F, 1:α, 2:β, 3:self, 4:a._@._internal._hyg.0, 5:a
snl_notation DFunLike.coe => $#4$
snl_notation DFunLike.coe[applied] => $#4(#5)$

-- Mathlib/Data/FunLike/Equiv.lean
-- Slots: 0:E, 1:α, 2:β, 3:inst._@.Mathlib.Data.FunLike.Equiv.765310555._hygCtx._hyg.7
snl_macro { name := "EquivLike.toFunLike", kind := "const", mode := "text", template := "The function-like structure underlying #3" }

-- Mathlib/Data/Nat/Basic.lean
-- Slots:
snl_macro { name := "Nat.instLinearOrder", kind := "const", mode := "text", template := "The usual linear-order structure on natural numbers" }

-- Mathlib/Data/Nat/Cast/Defs.lean
-- Slots: 0:R, 1:n, 2:inst._@.Mathlib.Data.Nat.Cast.Defs.1225535627._hygCtx._hyg.6, 3:inst._@.Mathlib.Data.Nat.Cast.Defs.1225535627._hygCtx._hyg.9
snl_macro { name := "instOfNatAtLeastTwo", kind := "const", mode := "text", template := "The OfNat instance interpreting the literal #1 in #0, supplied by the natural-number-cast structure #2 and the at-least-two proof #3" }

-- Mathlib/Data/Nat/Init.lean
-- Slots: 0:n, 1:inst._@.Mathlib.Data.Nat.Init.4148013620._hygCtx._hyg.34
snl_macro { name := "Nat.instAtLeastTwoHAddOfNat", kind := "const", mode := "text", template := "The at-least-two witness for the successor of #0 from its nonzero witness #1" }

-- Mathlib/Data/Set/Defs.lean
-- Slots: 0:α
snl_macro { name := "Set.instMembership", kind := "const", mode := "text", template := "The membership structure between #0 and its sets" }
-- Slots: 0:α
snl_macro { name := "Set.instHasSubset", kind := "const", mode := "text", template := "The subset-relation structure on sets of #0" }
-- Slots: 0:α
snl_macro { name := "Set.instEmptyCollection", kind := "const", mode := "text", template := "The empty-set structure on sets of #0" }

-- Mathlib/Logic/Denumerable.lean
-- Slots: 0:α, 1:self
snl_macro { name := "Denumerable.toEncodable", kind := "const", mode := "text", template := "The encoding underlying #1" }

-- Mathlib/Logic/Encodable/Basic.lean
-- Slots: 0:α
snl_macro { name := "Encodable", kind := "const", mode := "text", template := "An encoding of #0 by natural numbers with a partial inverse" }
-- Slots: 0:α, 1:self, 2:a._@._internal._hyg.0
snl_macro { name := "Encodable.encode", kind := "const", mode := "formula_inline", template := "\\operatorname{encode}_{#1}(#2)" }
-- Slots: 0:α, 1:self, 2:a._@._internal._hyg.0
snl_macro { name := "Encodable.decode", kind := "const", mode := "formula_inline", template := "\\operatorname{decode}_{#1}(#2)" }

-- Mathlib/Logic/Equiv/Defs.lean
-- Slots: 0:α, 1:β
snl_macro { name := "Equiv.instEquivLike", kind := "const", mode := "text", template := "The equivalence-like structure on equivalences from #0 to #1" }

-- Mathlib/Logic/Equiv/Set.lean
-- Slots: 0:α, 1:β, 2:f, 3:f_inv, 4:hf
snl_macro { name := "Equiv.ofLeftInverse", kind := "const", mode := "text", template := "The equivalence from #0 to the range of #2 induced by the family #3 of functions indexed by proofs of nonemptiness of #0, with left-inverse laws #4 for every index" }
-- Slots: 0:α, 1:β, 2:f, 3:hf
snl_macro { name := "Equiv.ofInjective", kind := "const", mode := "text", template := "The equivalence from #0 to the range of #2 induced by injectivity proof #3" }

-- Mathlib/Logic/Function/Basic.lean
-- Slots: 0:α, 1:β, 2:inst._@.Mathlib.Logic.Function.Basic.1170337882._hygCtx._hyg.13, 3:f, 4:a._@._internal._hyg.0
snl_notation Function.invFun => $\operatorname{invFun}(#3)$
snl_notation Function.invFun[applied] => $\operatorname{invFun}(#3)(#4)$
-- Slots: 0:α, 1:β, 2:inst._@.Mathlib.Logic.Function.Basic.2303841002._hygCtx._hyg.4, 3:f, 4:hf
snl_macro { name := "Function.leftInverse_invFun", kind := "const", mode := "text", template := "The left-inverse proof for the choice inverse of #3, from injectivity proof #4" }

-- Mathlib/Order/Defs/LinearOrder.lean
-- Slots: 0:α, 1:toPartialOrder, 2:toMin, 3:toMax, 4:toOrd, 5:le_total, 6:toDecidableLE, 7:toDecidableEq, 8:toDecidableLT, 9:min_def, 10:max_def, 11:compare_eq_compareOfLessAndEq
snl_macro { name := "LinearOrder.mk", kind := "const", mode := "formula_inline", template := "\\left\\{\\begin{array}{ll}\\mathsf{partialOrder}:&#1\\\\\\mathsf{min}:&#2\\\\\\mathsf{max}:&#3\\\\\\mathsf{compare}:&#4\\\\\\mathsf{total}:&#5\\\\\\mathsf{decLe}:&#6\\\\\\mathsf{decEq}:&#7\\\\\\mathsf{decLt}:&#8\\\\\\mathsf{min\\_def}:&#9\\\\\\mathsf{max\\_def}:&#10\\\\\\mathsf{compare\\_def}:&#11\\end{array}\\right\\}" }

-- Mathlib/Order/Defs/PartialOrder.lean
-- Slots: 0:α, 1:toLE, 2:toLT, 3:le_refl, 4:le_trans, 5:lt_iff_le_not_ge
snl_macro { name := "Preorder.mk", kind := "const", mode := "formula_inline", template := "\\left\\{\\begin{array}{ll}\\mathsf{le}:&#1\\\\\\mathsf{lt}:&#2\\\\\\mathsf{refl}:&#3\\\\\\mathsf{trans}:&#4\\\\\\mathsf{lt\\_iff}:&#5\\end{array}\\right\\}" }
-- Slots: 0:α, 1:self
snl_macro { name := "Preorder.toLT", kind := "const", mode := "text", template := "The strict-relation structure underlying #1" }
-- Slots: 0:α, 1:toPreorder, 2:le_antisymm
snl_macro { name := "PartialOrder.mk", kind := "const", mode := "formula_inline", template := "\\{\\mathsf{preorder}:=#1,\\ \\mathsf{antisymm}:=#2\\}" }
-- Slots: 0:α, 1:self
snl_macro { name := "PartialOrder.toPreorder", kind := "const", mode := "text", template := "The preorder underlying #1" }

-- Mathlib/Order/RelClasses.lean
-- Slots: 0:α, 1:r, 2:inst._@.Mathlib.Order.RelClasses.2885470062._hygCtx._hyg.15
snl_macro { name := "partialOrderOfSO", kind := "const", mode := "text", template := "The partial-order structure induced by relation #1 with strict-order proof #2" }

-- Mathlib/Order/RelIso/Basic.lean
-- Slots: 0:α, 1:β, 2:r, 3:s, 4:self
snl_macro { name := "RelIso.toEquiv", kind := "const", mode := "text", template := "The equivalence underlying the relation isomorphism #4" }

-- Mathlib/SetTheory/Cardinal/Defs.lean
-- Slots:
snl_macro { name := "Cardinal.isEquivalent", kind := "const", mode := "text", template := "The setoid of types identified by existence of an equivalence" }
-- Slots:
snl_macro { name := "Cardinal.instNatCast", kind := "const", mode := "text", template := "The natural-number-cast structure on cardinals" }
-- Slots:
snl_macro { name := "Cardinal.instPowCardinal", kind := "const", mode := "text", template := "The exponentiation structure on cardinals" }

-- Mathlib/SetTheory/Cardinal/Order.lean
-- Slots:
snl_macro { name := "Cardinal.partialOrder", kind := "const", mode := "text", template := "The partial-order structure on cardinals" }

-- Mathlib/SetTheory/ZFC/PSet.lean
-- Slots:
snl_macro { name := "PSet", kind := "const", mode := "formula_inline", template := "\\mathsf{PSet}" }
-- Slots:
snl_macro { name := "PSet.instEmptyCollection", kind := "const", mode := "text", template := "The empty-collection structure on pre-sets" }
-- Slots:
snl_macro { name := "PSet.instInsert", kind := "const", mode := "text", template := "The insertion-operation structure on pre-sets" }

/- The implicit-setoid wrapper `Quotient.mk'` and `Quotient.mk` are
 definitionally the same constructor at the complete native argument vector.
 This is a presentation view only: the original name, Expr, and all operands
 remain in the raw tree. No prime-containing identifier is renamed. -/
snl_macro { name := "Quotient.mk", kind := "const", mode := "formula_inline", template := "\\left[#2\\right]_{#1}" }
@[snl_delab app Quotient.mk']
meta def delabImplicitQuotientConstructor : SnlDelab := fun request => do
  let .expr expr := request.input | return none
  let tree := request.defaultTree
  unless expr.consumeMData.getAppArgs.size == 3 && tree.children.size == 3 do return none
  return some {
    macro_name := "Quotient.mk", kind := "const"
    children := tree.children.mapIdx fun i child => withLeanSourcePath child #[i]
  }



snl_notation DFunLike.coe[function] => $\mathsf{DFunLike.coe}$
snl_notation DecidableLE[function] => $\mathsf{DecidableLE}$
snl_notation DecidableLT[function] => $\mathsf{DecidableLT}$
snl_notation Denumerable.toEncodable[function] => $\mathsf{Denumerable.toEncodable}$
snl_notation EmptyCollection[function] => $\mathsf{EmptyCollection}$
snl_notation EmptyCollection.mk[function] => $\mathsf{EmptyCollection.mk}$
snl_notation Encodable[function] => $\mathsf{Encodable}$
snl_notation Encodable.decode[function] => $\mathsf{Encodable.decode}$
snl_notation Encodable.encode[function] => $\mathsf{Encodable.encode}$
snl_notation Equiv.instEquivLike[function] => $\mathsf{Equiv.instEquivLike}$
snl_notation Equiv.ofInjective[function] => $\mathsf{Equiv.ofInjective}$
snl_notation Equiv.ofLeftInverse[function] => $\mathsf{Equiv.ofLeftInverse}$
snl_notation EquivLike.toFunLike[function] => $\mathsf{EquivLike.toFunLike}$
snl_notation Function.invFun[function] => $\mathsf{Function.invFun}$
snl_notation Function.leftInverse_invFun[function] => $\mathsf{Function.leftInverse\_invFun}$
snl_notation HasSubset[function] => $\mathsf{HasSubset}$
snl_notation Infinite[function] => $\mathsf{Infinite}$
snl_notation LE.mk[function] => $\mathsf{LE.mk}$
snl_notation LT.mk[function] => $\mathsf{LT.mk}$
snl_notation LinearOrder.mk[function] => $\mathsf{LinearOrder.mk}$
snl_notation Max[function] => $\mathsf{Max}$
snl_notation Max.max[function] => $\mathsf{Max.max}$
snl_notation Nat.below[function] => $\mathsf{Nat.below}$
snl_notation Nat.brecOn[function] => $\mathsf{Nat.brecOn}$
snl_notation Nat.decLe[function] => $\mathsf{Nat.decLe}$
snl_notation Nat.decLt[function] => $\mathsf{Nat.decLt}$
snl_notation Nat.instAtLeastTwoHAddOfNat[function] => $\mathsf{Nat.instAtLeastTwoHAddOfNat}$
snl_notation Nat.instNeZeroSucc[function] => $\mathsf{Nat.instNeZeroSucc}$
snl_notation Nat.le[function] => $\mathsf{Nat.le}$
snl_notation Nat.le_antisymm[function] => $\mathsf{Nat.le\_antisymm}$
snl_notation Nat.le_refl[function] => $\mathsf{Nat.le\_refl}$
snl_notation Nat.le_total[function] => $\mathsf{Nat.le\_total}$
snl_notation Nat.le_trans[function] => $\mathsf{Nat.le\_trans}$
snl_notation Nat.lt[function] => $\mathsf{Nat.lt}$
snl_notation Nat.lt_iff_le_not_le[function] => $\mathsf{Nat.lt\_iff\_le\_not\_le}$
snl_notation Option.instMembership[function] => $\mathsf{Option.instMembership}$
snl_notation Option.some[function] => $\mathsf{Option.some}$
snl_notation PartialOrder.mk[function] => $\mathsf{PartialOrder.mk}$
snl_notation PartialOrder.toPreorder[function] => $\mathsf{PartialOrder.toPreorder}$
snl_notation Preorder.mk[function] => $\mathsf{Preorder.mk}$
snl_notation Preorder.toLT[function] => $\mathsf{Preorder.toLT}$
snl_notation Quotient[function] => $\mathsf{Quotient}$
snl_notation Quotient.mk[function] => $\mathsf{Quotient.mk}$
snl_notation RelIso.toEquiv[function] => $\mathsf{RelIso.toEquiv}$
snl_notation SDiff[function] => $\mathsf{SDiff}$
snl_notation Set.instEmptyCollection[function] => $\mathsf{Set.instEmptyCollection}$
snl_notation Set.instHasSubset[function] => $\mathsf{Set.instHasSubset}$
snl_notation Set.instMembership[function] => $\mathsf{Set.instMembership}$
snl_notation Std.Antisymm[function] => $\mathsf{Std.Antisymm}$
snl_notation Std.Refl[function] => $\mathsf{Std.Refl}$
snl_notation Std.Trichotomous[function] => $\mathsf{Std.Trichotomous}$
snl_notation inferInstance[function] => $\mathsf{inferInstance}$
snl_notation instHPow[function] => $\mathsf{instHPow}$
snl_notation instOfNatAtLeastTwo[function] => $\mathsf{instOfNatAtLeastTwo}$
snl_notation instOfNatNat[function] => $\mathsf{instOfNatNat}$
snl_notation partialOrderOfSO[function] => $\mathsf{partialOrderOfSO}$

@[ snl_delab app DFunLike.coe,
   snl_delab app DecidableLE,
   snl_delab app DecidableLT,
   snl_delab app Denumerable.toEncodable,
   snl_delab app EmptyCollection,
   snl_delab app EmptyCollection.mk,
   snl_delab app Encodable,
   snl_delab app Encodable.decode,
   snl_delab app Encodable.encode,
   snl_delab app Equiv.instEquivLike,
   snl_delab app Equiv.ofInjective,
   snl_delab app Equiv.ofLeftInverse,
   snl_delab app EquivLike.toFunLike,
   snl_delab app Function.invFun,
   snl_delab app Function.leftInverse_invFun,
   snl_delab app HasSubset,
   snl_delab app Infinite,
   snl_delab app LE.mk,
   snl_delab app LT.mk,
   snl_delab app LinearOrder.mk,
   snl_delab app Max,
   snl_delab app Max.max,
   snl_delab app Nat.below,
   snl_delab app Nat.brecOn,
   snl_delab app Nat.decLe,
   snl_delab app Nat.decLt,
   snl_delab app Nat.instAtLeastTwoHAddOfNat,
   snl_delab app Nat.instNeZeroSucc,
   snl_delab app Nat.le,
   snl_delab app Nat.le_antisymm,
   snl_delab app Nat.le_refl,
   snl_delab app Nat.le_total,
   snl_delab app Nat.le_trans,
   snl_delab app Nat.lt,
   snl_delab app Nat.lt_iff_le_not_le,
   snl_delab app Option.instMembership,
   snl_delab app Option.some,
   snl_delab app PartialOrder.mk,
   snl_delab app PartialOrder.toPreorder,
   snl_delab app Preorder.mk,
   snl_delab app Preorder.toLT,
   snl_delab app Quotient,
   snl_delab app Quotient.mk,
   snl_delab app RelIso.toEquiv,
   snl_delab app SDiff,
   snl_delab app Set.instEmptyCollection,
   snl_delab app Set.instHasSubset,
   snl_delab app Set.instMembership,
   snl_delab app Std.Antisymm,
   snl_delab app Std.Refl,
   snl_delab app Std.Trichotomous,
   snl_delab app inferInstance,
   snl_delab app instHPow,
   snl_delab app instOfNatAtLeastTwo,
   snl_delab app instOfNatNat,
   snl_delab app partialOrderOfSO ]
meta def viewSetOperations : SnlDelab := fun request =>
  let tree := request.defaultTree;
  match tree.macro_name with
  | "DFunLike.coe" => termOperationView tree 5 6
  | "DecidableLE" => termOperationView tree 1 0
  | "DecidableLT" => termOperationView tree 1 0
  | "Denumerable.toEncodable" => termOperationView tree 2 0
  | "EmptyCollection" => termOperationView tree 1 0
  | "EmptyCollection.mk" => termOperationView tree 2 0
  | "Encodable" => termOperationView tree 1 0
  | "Encodable.decode" => termOperationView tree 3 0
  | "Encodable.encode" => termOperationView tree 3 0
  | "Equiv.instEquivLike" => termOperationView tree 2 0
  | "Equiv.ofInjective" => termOperationView tree 4 0
  | "Equiv.ofLeftInverse" => termOperationView tree 5 0
  | "EquivLike.toFunLike" => termOperationView tree 4 0
  | "Function.invFun" => termOperationView tree 4 5
  | "Function.leftInverse_invFun" => termOperationView tree 5 0
  | "HasSubset" => termOperationView tree 1 0
  | "Infinite" => termOperationView tree 1 0
  | "LE.mk" => termOperationView tree 2 0
  | "LT.mk" => termOperationView tree 2 0
  | "LinearOrder.mk" => termOperationView tree 12 0
  | "Max" => termOperationView tree 1 0
  | "Max.max" => termOperationView tree 4 0
  | "Nat.below" => termOperationView tree 2 0
  | "Nat.brecOn" => termOperationView tree 3 0
  | "Nat.decLe" => termOperationView tree 2 0
  | "Nat.decLt" => termOperationView tree 2 0
  | "Nat.instAtLeastTwoHAddOfNat" => termOperationView tree 2 0
  | "Nat.instNeZeroSucc" => termOperationView tree 1 0
  | "Nat.le" => termOperationView tree 2 0
  | "Nat.le_antisymm" => termOperationView tree 4 0
  | "Nat.le_refl" => termOperationView tree 1 0
  | "Nat.le_total" => termOperationView tree 2 0
  | "Nat.le_trans" => termOperationView tree 5 0
  | "Nat.lt" => termOperationView tree 2 0
  | "Nat.lt_iff_le_not_le" => termOperationView tree 2 0
  | "Option.instMembership" => termOperationView tree 1 0
  | "Option.some" => termOperationView tree 2 0
  | "PartialOrder.mk" => termOperationView tree 3 0
  | "PartialOrder.toPreorder" => termOperationView tree 2 0
  | "Preorder.mk" => termOperationView tree 6 0
  | "Preorder.toLT" => termOperationView tree 2 0
  | "Quotient" => termOperationView tree 2 0
  | "Quotient.mk" => termOperationView tree 3 0
  | "RelIso.toEquiv" => termOperationView tree 5 0
  | "SDiff" => termOperationView tree 1 0
  | "Set.instEmptyCollection" => termOperationView tree 1 0
  | "Set.instHasSubset" => termOperationView tree 1 0
  | "Set.instMembership" => termOperationView tree 1 0
  | "Std.Antisymm" => termOperationView tree 2 0
  | "Std.Refl" => termOperationView tree 2 0
  | "Std.Trichotomous" => termOperationView tree 2 0
  | "inferInstance" => termOperationView tree 2 0
  | "instHPow" => termOperationView tree 3 0
  | "instOfNatAtLeastTwo" => termOperationView tree 4 0
  | "instOfNatNat" => termOperationView tree 1 0
  | "partialOrderOfSO" => termOperationView tree 3 0
  | _ => pure none

end SNL4Lean
