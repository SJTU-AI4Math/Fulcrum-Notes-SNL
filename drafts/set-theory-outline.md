# Set Theory — Draft Outline

> Scratch outline for SNL set theory chapter. Kept outside `.SNL_Doc/`.

## 1. Basic Concepts

### 1.1 Set
- **Kind:** definition
- A set is a collection of distinct objects. Denoted by capital letters $A, B, C, \ldots$.

### 1.2 Element Relation
- **Kind:** definition
- $x \in A$ means $x$ is an element of $A$. $x \notin A$ otherwise.

### 1.3 Empty Set
- **Kind:** definition
- Unique set with no elements. Denoted $\emptyset$.

### 1.4 Axiom of Extensionality
- **Kind:** axiom
- Two sets are equal iff they have the same elements.

### 1.5 Subset
- **Kind:** definition
- $A \subseteq B$ means every element of $A$ is in $B$.

### 1.6 Proper Subset
- **Kind:** definition
- $A \subsetneq B$ = $A \subseteq B \land A \neq B$.

### 1.7 Power Set
- **Kind:** definition
- $\mathcal{P}(A)$ = set of all subsets of $A$.

## 2. Set Operations

### 2.1 Union
- **Kind:** definition
- $A \cup B = \{x \mid x \in A \lor x \in B\}$.

### 2.2 Intersection
- **Kind:** definition
- $A \cap B = \{x \mid x \in A \land x \in B\}$. Disjoint if empty.

### 2.3 Set Difference
- **Kind:** definition
- $A \setminus B = \{x \in A \mid x \notin B\}$.

## Terminology to extract (Phase 2)

| Concept     | Proposed Macro      | Kind    | Arity |
|-------------|---------------------|---------|-------|
| empty set   | `Set.emptyset`      | const   | 0     |
| natural nos | `Set.N`             | const   | 0     |
| integers    | `Set.Z`             | const   | 0     |
| rationals   | `Set.Q`             | const   | 0     |
| reals       | `Set.R`             | const   | 0     |
| complex     | `Set.C`             | const   | 0     |
| element     | `Set.in`            | const   | 2     |
| not element | `Set.notin`         | const   | 2     |
| subset      | `Set.subset`        | const   | 2     |
| proper sub  | `Set.subsetneq`     | const   | 2     |
| superset    | `Set.supset`        | const   | 2     |
| proper sup  | `Set.supsetneq`     | const   | 2     |
| union       | `Set.cup`           | const   | 2     |
| intersection| `Set.cap`           | const   | 2     |
| set diff    | `Set.setminus`      | const   | 2     |
| power set   | `Set.powerset`      | const   | 1     |
| cardinality | `Set.card`          | const   | 1     |
