# Measure Theory (测度论基础) — SNL 起稿

> Sources:
> - `Fulcrum-Notes-Typst/Mathematics/28-MeasureTheory/main.typ`
> - `Fulcrum-Notes/Mathematics/26-Real-Analysis/26-Real Analysis.tex` § Lebesgue 测度

## Construction blueprint

### Section: Measure Theory Foundations

| id | kind | title | parent |
|---|---|---|---|
| `Measure.sec.foundations` | section | Measure Theory Foundations | root |
| `Measure.ctxt.1` | context | Shared measure-theory context | section |
| `Measure.ctxt.X` | context | X | ctxt.1 |
| `Measure.ctxt.Sigma` | context | Sigma | ctxt.1 |
| `Measure.ctxt.mu` | context | mu | ctxt.1 |
| `Measure.ctxt.AB` | context | A, B | ctxt.1 |
| `Measure.subsec.setSystems` | subsection | Set Systems and Sigma-Algebras | section |
| `Measure.def.setSemiring` | definition | Set Semiring | setSystems |
| `Measure.def.sigmaAlgebra` | definition | Sigma-Algebra | setSystems |
| `Measure.prop.sigmaIntersection` | property | Intersection of Sigma-Algebras | sigmaAlgebra |
| `Measure.def.generatedSigma` | definition | Generated Sigma-Algebra | setSystems |
| `Measure.def.borel` | definition | Borel Sigma-Algebra | setSystems |
| `Measure.subsec.measures` | subsection | Measures and Measure Spaces | section |
| `Measure.def.measure` | definition | Measure | measures |
| `Measure.def.measureSpace` | definition | Measure Space | measures |
| `Measure.prop.emptyZero` | property | Empty Set Has Measure Zero | measure |
| `Measure.prop.monotone` | property | Monotonicity of Measures | measure |
| `Measure.prop.finiteAdditivity` | property | Finite Additivity | measure |
| `Measure.prop.continuityBelow` | property | Continuity from Below | measure |
| `Measure.def.regularity` | definition | Regular Measure | measures |
| `Measure.subsec.borelLebesgue` | subsection | Borel and Lebesgue Measure | section |
| `Measure.def.borelMeasure` | definition | Borel Measure on R | borelLebesgue |
| `Measure.prop.borelUnique` | property | Uniqueness of Borel Measure | borelMeasure |
| `Measure.prop.singletonZero` | property | Singletons Have Measure Zero | borelMeasure |
| `Measure.def.complete` | definition | Complete Measure Space | borelLebesgue |
| `Measure.def.outerMeasure` | definition | Outer Measure | borelLebesgue |
| `Measure.def.lebesgueMeasurable` | definition | Lebesgue-Measurable Set | borelLebesgue |
| `Measure.thm.lebesgueSigmaAlgebra` | theorem | Lebesgue-Measurable Sets Form a Sigma-Algebra | lebesgueMeasurable |
| `Measure.def.lebesgueMeasure` | definition | Lebesgue Measure | borelLebesgue |
| `Measure.prop.lebesgueComplete` | property | Lebesgue Measure is Complete | lebesgueMeasure |
| `Measure.prop.lebesgueTranslationInvariant` | property | Translation Invariance | lebesgueMeasure |
| `Measure.subsec.almostEverywhere` | subsection | Almost Everywhere | section |
| `Measure.def.almostEverywhere` | definition | Almost Everywhere | almostEverywhere |
| `Measure.prop.aeImplication` | property | Pointwise Implication Preserves a.e. Truth | almostEverywhere |
| `Measure.prop.aeConjunction` | property | a.e. Conjunction | almostEverywhere |
| `Measure.prop.aeCountable` | property | Countable Intersection of a.e. Properties | almostEverywhere |

## Scope notes

- The SNL model is type-theoretic: `Set(X) := X -> Proposition`.
- A measure is defined on a sigma-algebra `Sigma : Set(Set(X))`, not on all subsets by default.
- The foundational library stops before measurable functions and integration; those belong to the existing RealAnalysis package/library.
- The almost-everywhere quantifier uses the standard complete-measure interpretation: the exceptional set is contained in a measurable null set.
