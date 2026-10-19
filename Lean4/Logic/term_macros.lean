import Lean4.Basics.term_macros
import Mathlib.Logic.Unique
import Mathlib.Logic.ExistsUnique
import Mathlib.Logic.Nontrivial.Defs
import Mathlib.Logic.IsEmpty.Defs

/-!
Logic and elementary properties of types, pinned to Lean 4.28.0.

Basics imports SNL4Lean.TermMacros (Builtin and Std). Keep the imported defaults
for True, Not, Eq, And, Or, Iff, Exists and Nonempty; do not register them again.
Prop, implication and universal quantification are Sort/forall Expr syntax, not
additional native constants. See Logic.lean for scoped, real term examples.

Slots below are zero-based FULL native arguments, including implicit parameters,
proofs and explicit arrows in a projection result. Every new constructor retains
all constructor fields. Recursor slots are checked with native forallTelescope and constructor metadata. No full/explicit diagnostic Style competes with default.
-/

-- Init/Prelude.lean:184-187. True: no parameters; intro: no fields.
snl_notation True.intro => %The canonical proof of true%
-- Generated True.rec: #0 motive, #1 introduction case, #2 major proof.
snl_notation True.rec => %Eliminate the proof #2 of true with motive #0 and introduction case #1%

-- Init/Prelude.lean:197. False has no constructors.
snl_notation False => $\bot$
-- Generated False.rec: #0 motive, #1 major proof; no constructor cases.
snl_notation False.rec => %Eliminate the contradiction #1 with motive #0%
-- Init/Prelude.lean:235. #0 C : Sort u, #1 h : False; result C.
snl_notation False.elim => %Derive an inhabitant of #0 from the contradiction #1%

-- Init/Prelude.lean:275-278. Eq.refl: #0 alpha : Sort u, #1 a : alpha.
-- Native Eq.refl has two parameters and no constructor fields.
-- The endpoint a is retained at #1.
snl_notation Eq.refl => $\operatorname{refl}_{#0}(#1)$
-- Generated Eq.rec: #0 alpha, #1 a, #2 motive, #3 reflexivity case,
-- #4 b, #5 h : a = b. Motive is (b : alpha) -> a = b -> Sort v.
-- Full application order is corroborated by Init/Core.lean:978-980 and
-- Lean/Meta/AppBuilder.lean:460; the full slot order is checked against native metadata.
snl_notation Eq.rec => %Equality induction in #0 from #1 to #4 along #5, with motive #2 and reflexivity case #3%
-- Init/Prelude.lean:281. Same six positions; motive : alpha -> Sort v
-- does NOT depend on the equality proof (unlike Eq.rec).
snl_notation Eq.ndrec => %Transport #3 in the family #2 on #0 from #1 to #4 along #5%
-- Init/Prelude.lean:311. #0 alpha, #1 motive : alpha -> Prop,
-- #2 a, #3 b, #4 h1 : a = b, #5 h2 : motive a. Result motive b.
snl_notation Eq.subst => %Substitute #3 for #2 in the predicate #1 on #0, using equality #4 and proof #5%

-- Init/Prelude.lean:555-563. And: #0 a, #1 b.
-- And.intro: #2 left : a, #3 right : b (both constructor fields).
snl_notation And.intro => $\left\langle #2, #3 \right\rangle_{\land}$
-- And.left/right: #0 a, #1 b, #2 self : a /\ b; result a/b.
-- These are proof projections, not the propositions a and b themselves.
snl_notation And.left => $\operatorname{left}_{\land}(#2)$
snl_notation And.right => $\operatorname{right}_{\land}(#2)$
-- Generated And.rec: #0 a, #1 b, #2 motive, #3 constructor case,
-- #4 major proof. Constructor case is at position 3, independently corroborated
-- by Lean/Compiler/LCNF/ToLCNF.lean:733-734. The native dependent motive is retained.
snl_notation And.rec => %Conjunction elimination for #0 and #1 with motive #2, constructor case #3 and proof #4%

-- Init/Prelude.lean:571-575. Or.inl/inr: #0 a, #1 b, #2 h : a/b.
-- Each constructor retains its only field h; target disjunction is explicit.
snl_notation Or.inl => $\operatorname{inl}_{\left(#0\lor #1\right)}(#2)$ : [31, 30, 0] -> 1024
snl_notation Or.inr => $\operatorname{inr}_{\left(#0\lor #1\right)}(#2)$ : [31, 30, 0] -> 1024
-- Generated Or.rec: #0 a, #1 b, #2 motive, #3 left case, #4 right case,
-- #5 major proof. Only Prop elimination; native dependent motive and case functions are retained.
snl_notation Or.rec => %Disjunction elimination for #0 or #1 with motive #2, left case #3, right case #4 and proof #5%

-- Existing English Styles retained unchanged.
snl_notation Nonempty[english] => %#0 has an element%
snl_notation Decidable => %The type of decision procedures for #0%
snl_notation DecidableEq => %The type of equality decision procedures on #0%

-- Init/Core.lean:185-191. Iff: #0 a, #1 b.
-- Iff.intro: #2 mp : a -> b, #3 mpr : b -> a (both fields retained).
snl_notation Iff.intro => $\left\langle #2, #3 \right\rangle_{\leftrightarrow}$
-- Iff.mp: #0 a, #1 b, #2 self : a <-> b, #3 proof of a; result b.
-- Iff.mpr: #0 a, #1 b, #2 self : a <-> b, #3 proof of b; result a.
-- FULL telescope includes the fourth slot from each function-valued field.
-- The receiver at #2 MUST NOT be discarded. Both the receiver and the premise proof are retained.
snl_notation Iff.mp => $\operatorname{mp}(#2)$
snl_notation Iff.mp[applied] => $\operatorname{mp}(#2,#3)$
snl_notation Iff.mpr => $\operatorname{mpr}(#2)$
snl_notation Iff.mpr[applied] => $\operatorname{mpr}(#2,#3)$
-- Generated Iff.rec: #0 a, #1 b, #2 motive, #3 constructor case,
-- #4 major proof. The native dependent motive is retained.
snl_notation Iff.rec => %Equivalence elimination for #0 and #1 with motive #2, constructor case #3 and proof #4%

-- Init/Core.lean:335-338. Exists: #0 alpha : Sort u, #1 p : alpha -> Prop.
-- Exists.intro: #2 w : alpha, #3 h : p w; BOTH witness and proof retained.
-- Exists is inductive, not a structure with data-valued witness projections.
snl_notation Exists.intro => $\left\langle #2, #3 \right\rangle_{\exists}$
-- Generated Exists.rec: #0 alpha, #1 predicate, #2 motive, #3 intro case,
-- #4 major proof. Only Prop elimination; native dependent motive and case functions are retained.
snl_notation Exists.rec => %Existential elimination on #0 for predicate #1 with motive #2, witness-and-proof case #3 and existential proof #4%

-- Existing type-property Styles retained unchanged.
snl_notation Ne => $#1 \ne #2$ : [0, 51, 51] -> 50
snl_notation Subsingleton => %#0 is at most singleton%

-- Mathlib/Logic/ExistsUnique.lean
snl_notation ExistsUnique => $\exists! #1$

-- Mathlib/Logic/IsEmpty/Defs.lean
snl_notation IsEmpty => %#0 is empty%

-- Mathlib/Logic/Nontrivial/Defs.lean
snl_notation Nontrivial => %#0 is non-trivial%

-- Mathlib/Logic/Unique.lean
snl_notation Unique => %A specified element of #0 together with a proof that every element equals it%

namespace SNL4Lean
open Lean Meta

/- Operation views distinguish a bare function from its applications. Every
   original argument and source path is retained; the raw Expr is unchanged. -/
meta def termOperationView (tree : SnlSyntaxTree) (minimumArgs : Nat)
    (appliedAt : Nat := 0) : MetaM (Option SnlSyntaxTree) := do
  let n := tree.children.size
  let args := tree.children.mapIdx fun i child => withLeanSourcePath child #[i]
  if n < minimumArgs then
    let head : SnlSyntaxTree := {
      macro_name := tree.macro_name
      kind := "const"
      style_name? := some "function"
    }
    if n == 0 then return some head
    return some { macro_name := "Type.app", kind := "rule", children := #[
      withLeanSourcePath head #[],
      { macro_name := "__list__", kind := "rule", children := args }] }
  if appliedAt > 0 && n >= appliedAt then
    let applied : SnlSyntaxTree := {
      macro_name := tree.macro_name
      kind := "const"
      style_name? := some "applied"
      children := args[:appliedAt].toArray
    }
    if n == appliedAt then return some applied
    return some { macro_name := "Type.app", kind := "rule", children := #[
      withLeanSourcePath applied #[],
      { macro_name := "__list__", kind := "rule", children := args[appliedAt:].toArray }] }
  return none

snl_notation And.intro[function] => $\mathsf{And.intro}$
snl_notation And.left[function] => $\mathsf{And.left}$
snl_notation And.rec[function] => $\mathsf{And.rec}$
snl_notation And.right[function] => $\mathsf{And.right}$
snl_notation Eq.ndrec[function] => $\mathsf{Eq.ndrec}$
snl_notation Eq.rec[function] => $\mathsf{Eq.rec}$
snl_notation Eq.refl[function] => $\mathsf{Eq.refl}$
snl_notation Eq.subst[function] => $\mathsf{Eq.subst}$
snl_notation Exists.intro[function] => $\mathsf{Exists.intro}$
snl_notation Exists.rec[function] => $\mathsf{Exists.rec}$
snl_notation False.elim[function] => $\mathsf{False.elim}$
snl_notation False.rec[function] => $\mathsf{False.rec}$
snl_notation Iff.intro[function] => $\mathsf{Iff.intro}$
snl_notation Iff.mp[function] => $\mathsf{Iff.mp}$
snl_notation Iff.mpr[function] => $\mathsf{Iff.mpr}$
snl_notation Iff.rec[function] => $\mathsf{Iff.rec}$
snl_notation Or.inl[function] => $\mathsf{Or.inl}$
snl_notation Or.inr[function] => $\mathsf{Or.inr}$
snl_notation Or.rec[function] => $\mathsf{Or.rec}$
snl_notation True.rec[function] => $\mathsf{True.rec}$

@[ snl_delab app And.intro,
   snl_delab app And.left,
   snl_delab app And.rec,
   snl_delab app And.right,
   snl_delab app Eq.ndrec,
   snl_delab app Eq.rec,
   snl_delab app Eq.refl,
   snl_delab app Eq.subst,
   snl_delab app Exists.intro,
   snl_delab app Exists.rec,
   snl_delab app False.elim,
   snl_delab app False.rec,
   snl_delab app Iff.intro,
   snl_delab app Iff.mp,
   snl_delab app Iff.mpr,
   snl_delab app Iff.rec,
   snl_delab app Or.inl,
   snl_delab app Or.inr,
   snl_delab app Or.rec,
   snl_delab app True.rec ]
meta def viewLogicalOperations : SnlDelab := fun request =>
  let tree := request.defaultTree;
  match tree.macro_name with
  | "And.intro" => termOperationView tree 4 0
  | "And.left" => termOperationView tree 3 0
  | "And.rec" => termOperationView tree 5 0
  | "And.right" => termOperationView tree 3 0
  | "Eq.ndrec" => termOperationView tree 6 0
  | "Eq.rec" => termOperationView tree 6 0
  | "Eq.refl" => termOperationView tree 2 0
  | "Eq.subst" => termOperationView tree 6 0
  | "Exists.intro" => termOperationView tree 4 0
  | "Exists.rec" => termOperationView tree 5 0
  | "False.elim" => termOperationView tree 2 0
  | "False.rec" => termOperationView tree 2 0
  | "Iff.intro" => termOperationView tree 4 0
  | "Iff.mp" => termOperationView tree 3 4
  | "Iff.mpr" => termOperationView tree 3 4
  | "Iff.rec" => termOperationView tree 5 0
  | "Or.inl" => termOperationView tree 3 0
  | "Or.inr" => termOperationView tree 3 0
  | "Or.rec" => termOperationView tree 6 0
  | "True.rec" => termOperationView tree 3 0
  | _ => pure none
end SNL4Lean
