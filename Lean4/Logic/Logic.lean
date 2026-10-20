import Lean4.Logic.term_macros_CN

/-!
# Logic: native declarations and actual expression examples

The logical constants are imported from pinned Lean 4.28.0, not redefined.
Every #snl_print is immediately followed by the matching native #print. Structure
constructors and all declared fields are adjacent to their structure; generated
recursors follow that local group. Exact generated telescope/constructor metadata
are checked against the native environment; raw expression trees retain all operands.

The companion covers the native content behind the authored Logic chapter.
Section/context/remark Entries remain explanatory rather than invented constants.
The chapter's UTLC open-term non-definitional-equality example is metatheory, not
an Eq theorem about all pairs of Lean naturals; it is not assigned a fake constant.
-/

#snl_toc Init.Prelude

namespace Fulcrum.Logic

section PropositionalLogic

-- Logic.def.true; Logic.def.true.ctor.true; Logic.def.true.recursor.
-- True has one nullary constructor. Its proof is not a proof of arbitrary p.
#snl_print True
#print True
#snl_print True.intro
#print True.intro
#snl_print True.rec
#print True.rec

-- Logic.def.false; Logic.def.false.recursor; Logic.ppt.false-rec.
-- False has no constructors. Elimination is conditional on a proof of False;
-- this file does not introduce such a proof as a global axiom.
#snl_print False
#print False
#snl_print False.rec
#print False.rec
#snl_print False.elim
#print False.elim

-- Logic.def.neg: the native definition is p -> False, NOT p -> Prop.
#snl_print Not
#print Not

-- Logic.def.and: constructor and BOTH fields printed locally.
#snl_print And
#print And
#snl_print And.intro
#print And.intro
#snl_print And.left
#print And.left
#snl_print And.right
#print And.right
#snl_print And.rec
#print And.rec

-- Logic.def.or; both constructor Entries; Logic.def.or.recursor.
#snl_print Or
#print Or
#snl_print Or.inl
#print Or.inl
#snl_print Or.inr
#print Or.inr
#snl_print Or.rec
#print Or.rec

-- Logic.def.iff: mp is the forward implication, mpr the reverse implication.
-- Field declaration syntax a -> b is not the full closed projection signature:
-- @Iff.mp and @Iff.mpr additionally take propositions and the equivalence proof.
#snl_print Iff
#print Iff
#snl_print Iff.intro
#print Iff.intro
#snl_print Iff.mp
#print Iff.mp
#snl_print Iff.mpr
#print Iff.mpr
#snl_print Iff.rec
#print Iff.rec

end PropositionalLogic

section PredicateLogic

-- Logic.def.exists. Native Exists is inductive; intro keeps witness AND proof.
-- It has no general data-valued witness projection; its recursor eliminates
-- only into Prop. Do not invent Exists.witness or Exists.property constants.
#snl_print Exists
#print Exists
#snl_print Exists.intro
#print Exists.intro
#snl_print Exists.rec
#print Exists.rec

-- Logic.def.eq; reflexivity constructor/theorem Entries; recursor; substitution.
#snl_print Eq
#print Eq
#snl_print Eq.refl
#print Eq.refl
#snl_print Eq.rec
#print Eq.rec
-- This genuine helper occurs in the native Eq.subst body.
#snl_print Eq.ndrec
#print Eq.ndrec
#snl_print Eq.subst
#print Eq.subst

end PredicateLogic

section SyntaxAndExamples

universe u
-- Logic.ctxt.PQ, Logic.ctxt.T, Logic.ctxt.P, Logic.ctxt.1.
variable (T : Type u)
variable (p q : Prop)
variable (P : T → Prop)
variable (a b : T) (hp : p) (hq : q) (hpq : p ↔ q)
variable (hab : a = b) (hPa : P a)

-- Logic.def.proposition: Prop is Sort 0, not a named native declaration.
#snl_widget Prop
#snl_widget (fun (p : Prop) => (p : Prop))

-- Logic.def.implies: a nondependent forall expression, not a constant Implies.
#snl_widget (fun (p q : Prop) => (p → q))
#snl_widget (fun (p : Prop) => (fun h : p => h))

-- Logic.def.forall: a dependent forall expression with proposition-valued body.
#snl_widget (fun (T : Type u) (P : T → Prop) => (∀ x : T, P x))
#snl_widget (fun (T : Type u) (P : T → Prop) => (∃ x : T, P x))
#snl_widget (fun (p : Prop) => (¬p))
#snl_widget (fun (p q : Prop) => (p ∧ q))
#snl_widget (fun (p q : Prop) => (p ∨ q))
#snl_widget (fun (p q : Prop) => (p ↔ q))
#snl_widget (fun (T : Type u) (a b : T) => (a = b))

-- Real field-complete constructor applications and proof-valued projections.
#snl_widget True.intro
#snl_widget (fun (p q : Prop) (hp : p) (hq : q) => (And.intro hp hq))
#snl_widget (fun (p q : Prop) (hp : p) (hq : q) => (And.left (And.intro hp hq)))
#snl_widget (fun (p q : Prop) (hp : p) (hq : q) => (And.right (And.intro hp hq)))
#snl_widget (fun (p q : Prop) (hp : p) (hq : q) => (Or.inl hp : p ∨ q))
#snl_widget (fun (p q : Prop) (hp : p) (hq : q) => (Or.inr hq : p ∨ q))
#snl_widget (fun (p q : Prop) (hp : p) (hq : q) => (Iff.intro (fun _ : p => hq) (fun _ : q => hp)))
#snl_widget (fun (p q : Prop) (hpq : p ↔ q) (hp : p) (hq : q) => (Iff.mp hpq hp))
#snl_widget (fun (p q : Prop) (hpq : p ↔ q) (hp : p) (hq : q) => (Iff.mpr hpq hq))
#snl_widget (fun (T : Type u) (P : T → Prop) (a b : T) (hab : a = b) (hPa : P a) => (Exists.intro a hPa))
#snl_widget (fun (T : Type u) (a : T) => (Eq.refl a))
#snl_widget (fun (T : Type u) (P : T → Prop) (a b : T) (hab : a = b) (hPa : P a) => (Eq.subst (motive := P) hab hPa))
#snl_widget (fun (p : Prop) => (fun h : False => False.elim (C := p) h))

-- The paired recursor commands expose their actual dependent motives;
-- no fixed or universally data-valued elimination principle is assumed.

end SyntaxAndExamples

end Fulcrum.Logic
