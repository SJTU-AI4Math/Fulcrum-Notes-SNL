# Fulcrum-Notes-SNL naming and ownership standard

> This is the authoritative naming standard for this document, required by
> `SNL-Agent-Toolkit/Skills/HowToBuild/Terminologization.md` step 4. Any agent
> or author adding a macro, style, Entry, or Library to this workspace conforms
> to this file. It is reconstructed from the names already on disk and confirmed
> by the author.
>
> Prose conventions for *writing* SNL content (macro-tree-first, binder scoping,
> `def` vs `def-hyp`) live in `../SNL-CONVENTIONS.md`. This file owns
> **identities** only.

## 1. Macro names

Grammar:

```text
macroName := Namespace "." slug ("." qualifier)?
```

- **Dotted qualification is mandatory** for any domain concept. The namespace is
  the mathematical theory that owns the concept, not the file it happens to live
  in — they usually coincide, and where they do not, the theory wins.
- `slug` is `lowerCamelCase` when it names an operation, relation, or property
  (`Measure.countablyAdditive`, `Set.subset`, `Logic.forall`).
- `slug` is `UpperCamelCase` when it names a type, structure, or class of
  objects (`Algebra.Group`, `Measure.SigmaAlgebra`, `FP.Monad`).
- **Specialisation prefix (mandatory).** If a concept obviously has a strictly
  more general form that this document will eventually carry, the *narrow* form
  must say so in its name, and the general name is reserved for the general
  form. This is a naming obligation, not a style preference: the narrow concept
  never gets to squat on the general name.
  - Riemann integral is subsumed by the Lebesgue integral, so it is
    `Analysis.rIntIcc` / `Analysis.rIndefInt` (`r` = Riemann), leaving
    `Analysis.int` / `RealAnalysis.lebesgueIntegral` free.
  - Group homomorphism is subsumed by the categorical morphism, so it is
    `Algebra.GrpHom`, not `Algebra.Hom`. Same for `Algebra.GrpMono`,
    `Algebra.GrpEpi`, `Algebra.GrpIso`, `Algebra.GrpKer`, `Algebra.GrpIm`,
    `Algebra.GrpAction`.
  - Prefix style follows the slug's case: `UpperCamelCase` slugs take a capital
    structural prefix (`GrpHom`), `lowerCamelCase` slugs take a lowercase
    letter prefix (`rIntIcc`).
  - Choose the prefix from the theory that *owns the specialisation*
    (`Grp`, `Ring`, `Top`, `r` for Riemann, `l` for Lebesgue when both coexist),
    not from the file it lives in.
  - Do **not** apply this to concepts whose general form is not foreseeable.
    Over-prefixing is as bad as squatting: it makes every name unreadable for a
    generality that never arrives.
- A trailing `-typed` qualifier marks the type-annotated variant of a
  meta-mathematical binder: `Logic.forall` vs `Logic.forall-typed`.
- Hyphens are legal but reserved for such qualifier suffixes. Do not use a
  hyphen to separate words inside a slug; use camelCase.

### Namespaces in use

| namespace | owning package | scope |
|---|---|---|
| `Type` | `TypeTheory` | type judgements, Π/Σ, application, lambda |
| `Logic` | `Logic` | connectives, quantifiers, truth values |
| `Set` | `SetTheory` | sets as type-valued predicates and their operations |
| `Algebra` | `Algebra` | group theory and its homomorphisms |
| `Measure` | `MeasureTheory` | set systems, σ-algebras, measures |
| `RealAnalysis` | `RealAnalysis` | measure-theoretic real analysis (Lebesgue layer) |
| `Analysis` | `BasicAnalysis` | elementary real analysis (limits, derivative, Riemann integral) |
| `FP` | `FunctionalProgramming` | monads, lattices, standard instances |

### Unnamespaced macros

Exactly two categories may carry a bare name:

1. **Structural macros** that describe the shape of a mathematical statement
   rather than any mathematical object: `def`, `def-hyp`, `thm-hyp`,
   `def-struct`, `def-inductive`, `constructor`, `member`, `struct`,
   `list-partial`. They are owned by `FulcrumsMathNotes` and are theory-neutral
   by design. Their names are kebab-case, which is why the hyphen rule above
   does not apply to them.
2. **Cross-domain elementary notation** owned by `BasicOperators`: `Eq`,
   `Power`, `parentheses`, `Icc`, `let`, `quotient`, and the number systems
   `Nat`, `Real`, `ENNReal`, `EReal`. These are symbols every theory reaches
   for, and namespacing them would make every formula noisier without
   disambiguating anything.

   **Number systems and other primitive objects are global by construction.**
   `\mathbb{N}` means the same thing in group theory and in measure theory, so
   there is exactly one `Nat` and it lives here. Do not define a namespaced copy
   in your own package because it happens to be the first place you need it —
   the "two unrelated theories first" rule below is about *deciding to
   generalise a domain concept*, and does not apply to elementary notation that
   was never domain-specific to begin with. If you catch yourself writing
   `Foo.Nat`, `Foo.Int`, `Foo.Real`, `Foo.Complex` or similar, the macro belongs
   in `BasicOperators` under its bare name.

Anything else gets a namespace. New bare names are not accepted.

## 2. Package ownership

- One package per theory, named after the theory (`MeasureTheory.json`), not
  after size.
- **A namespace has exactly one owning package.** If `Set.foo` exists, it lives
  in `SetTheory.json` and nowhere else.
- When two theories could claim a concept, the **more primitive theory owns it**
  and the downstream theory reuses the macro. Set theory owns `Set.mem`; measure
  theory does not redefine it.
- A concept is added to `BasicOperators` only when at least two unrelated
  theories already need it. Do not pre-emptively generalise.
- Every package must be listed in `config.json#active_macro_packages`.

### Known deviation

`Type.pair` currently lives in `SetTheory.json` although the `Type` namespace is
owned by `TypeTheory`. This is a legacy placement, not a precedent. Do not add
further `Type.*` macros to `SetTheory.json`; migrating the existing one requires
`snl-find-refs` + `snl-rename-id` and is deferred.

## 3. Style names

`style_name` must match `[A-Za-z_][A-Za-z0-9_]*`. Parentheses, hyphens, and dots
are rejected by `snl-lint-package`. Multi-word style names are `lowerCamelCase`
(`fracInline`, `predicateDisplay`).

`styles[0]` is the implicit default — the style used when a call site writes no
`[style]` tag. Order styles so the most common rendering comes first.

Reserved style vocabulary; reuse these spellings rather than inventing synonyms:

| style | meaning |
|---|---|
| `default` | the only style a macro has |
| `inline` / `display` | same content, inline vs display math or block layout |
| `paren` | the parenthesised form of a judgement or application |
| `juxt` | juxtaposition instead of an explicit operator or parentheses |
| `infix` / `prefix` | operator position |
| `text` | natural-language rendering of a symbolic concept |
| `bind` | binder form that introduces a variable |
| `cases` | multi-line `\begin{cases}` layout |
| `predicate` | "… if and only if …" phrasing of a definitional macro |
| `sup` / `sub` | superscript / subscript notation variant |

## 4. Entry ids

```text
entryId := Domain "." kindAbbrev "." slug ("." qualifier)?
```

- Dots only. Hyphens are avoided because KaTeX may read them as minus signs.
- `Domain` matches the macro namespace of the same theory (`BasicAnalysis`,
  `Set`, `Logic`, `Algebra`).
- `kindAbbrev` is a fixed abbreviation of the Entry kind:

  | kind | abbrev | kind | abbrev |
  |---|---|---|---|
  | section | `sec` | property | `prop` |
  | subsection | `subsec` | remark | `rmk` |
  | definition | `def` | example | `ex` |
  | axiom | `ax` | counterexample | `cex` |
  | theorem | `thm` | construction | `constr` |
  | lemma | `lem` | proof | `proof` |
  | corollary | `cor` | problem | `prob` |
  | context | `ctxt` | | |

- `slug` is `lowerCamelCase`.
- A proof Entry qualifies its parent statement's id:
  `BasicAnalysis.thm.bolzanoWeierstrass.proof`.
- Ids are lifetime identities. Renaming goes through `snl-find-refs` then
  `snl-rename-id --dry-run`, never a text substitution.

## 5. Library slugs

Directory name under `.SNL_Doc/libraries/`. Use the theory name in
`UpperCamelCase_With_Underscores` matching the existing `Basic_Analysis` and
`Functional_Programming`, or lowercase-hyphenated matching `measure-theory`,
`set-theory`, `basic-algebra`. Both spellings exist on disk; **new libraries use
the lowercase-hyphenated form** and the two legacy underscore names are left
alone.

## 6. Semantic sources

`source.entries` on a macro points at the Entry that *defines* the concept, not
at derivations or applications of it. A macro whose concept has no defining
Entry keeps `entries: []` — pure notation such as `Add.add` legitimately has no
source. Fill these during Phase 5, not while inventing the name.

## 7. English and Simplified-Chinese localization

- Entry titles and Markdown bodies use complete `I18n` values with exactly `en`
  and `zh-CN`; English is the default projection unless a pre-existing entity
  explicitly uses another default.
- A Macro Style is localized only when its resolved template mode is `text`.
  Formula and block templates remain language-invariant structural data.
- Every localized Macro Style preserves the same `#0`, `#1`, … or `#*`
  placeholder contract in both languages. Macro names, style identities,
  descriptions, arity, package ownership, and source indexes do not change for
  translation.
- Literal `%…%` text embedded directly in an SNL tree has no language projection.
  Do not pretend it is localized; reuse an existing localized text Macro when
  one already exists, or leave it unchanged until a separately reviewed Macro
  is introduced.

## 8. Inductive constructors and recursors

- Each audited inductive type owns one empty `definition` subentry for every
  constructor and one empty `definition` subentry for its per-type recursor.
- Constructor ids qualify the parent as `.ctor.<slug>`; recursor ids qualify it
  as `.recursor`. An existing semantically identical empty Entry is reused
  instead of duplicated.
- These Entries stay in the same Package as their inductive parent and are
  attached below every intended parent occurrence with the Library's
  `Subentry` counter. Their `content` remains `{}` until the corresponding
  definitions are authored.
