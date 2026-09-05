/-!
# Convincer: explicit evidence and kernel-checked conditional inference

`Convincing p` is data, never a proof of `p`. No interpreter may turn an
unverified evidence leaf into a Lean proof. The applicative spine stores *both*
inputs of every inference, so its provenance is inspectable without supplying
any unproved proposition to a continuation.
-/
namespace Convincer

/-- Authored justification, not a kernel certificate or authenticated identity. -/
structure Evidence where
  id : String
  explanation : String
  source : String := ""
  deriving Repr, BEq

/-- Intensional, proof-relevant arguments about propositions. -/
inductive Convincing : Prop → Type 1 where
  | proof {p : Prop} (term : p) : Convincing p
  | evidence {p : Prop} (source : Evidence) : Convincing p
  | mp {p q : Prop} (rule : Convincing (p → q)) (premise : Convincing p) : Convincing q
  | named {p : Prop} (name : String) (argument : Convincing p) : Convincing p

namespace Convincing

/-- Apply a genuine Lean implication without erasing its argument's evidence. -/
def map {p q : Prop} (f : p → q) (argument : Convincing p) : Convincing q :=
  .mp (.proof f) argument

/-- Combine independent arguments, preserving their complete ordered provenance. -/
def both {p q : Prop} (left : Convincing p) (right : Convincing q) : Convincing (p ∧ q) :=
  .mp (left.map And.intro) right

/-- All evidence occurrences, including duplicates and explicitly unused citations. -/
def evidenceLeaves {p : Prop} : Convincing p → List Evidence
  | .proof _ => []
  | .evidence e => [e]
  | .mp f x => f.evidenceLeaves ++ x.evidenceLeaves
  | .named _ x => x.evidenceLeaves

/-- What must additionally be true for this argument to establish its conclusion. -/
def Valid {p : Prop} : Convincing p → Prop
  | .proof _ => True
  | .evidence (_ : Evidence) => p
  | .mp f x => f.Valid ∧ x.Valid
  | .named _ x => x.Valid

/-- Conditional soundness. This does not assert that any Evidence is valid. -/
theorem sound {p : Prop} (argument : Convincing p) : argument.Valid → p := by
  induction argument with
  | proof h => exact fun _ => h
  | evidence _ => exact id
  | mp _ _ ihf ihx => exact fun h => ihf h.1 (ihx h.2)
  | named _ _ ih => exact ih

/-- Proof-only extraction is explicit and fails if *any* evidence leaf occurs. -/
def checked? {p : Prop} : Convincing p → Option (PLift p)
  | .proof h => some ⟨h⟩
  | .evidence _ => none
  | .mp f x => do
    let hf ← f.checked?
    let hx ← x.checked?
    return ⟨hf.down hx.down⟩
  | .named _ x => x.checked?

end Convincing
end Convincer

export Convincer (Evidence Convincing)

-- Exporting a type name alone does not export its qualified constructor names.
namespace Convincing
export Convincer.Convincing (proof evidence mp named map both evidenceLeaves Valid sound checked?)
end Convincing

namespace Evidence
export Convincer.Evidence (mk id explanation source)
end Evidence
