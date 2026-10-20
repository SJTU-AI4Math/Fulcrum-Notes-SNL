import Init

set_option autoImplicit false

/-!
# 1B · Inductive Types, Structures, and Pattern Matching (Draft)

This file follows the lecture outline directly. It starts from dependent function spaces, then
builds the main data types used throughout Lean, explains structures as one-constructor inductive
types with named projections, and finishes by comparing recursors with pattern matching.

The chapter treats computational data in `Type`. The measure-space example is intentionally
deferred to 2A.

All course declarations live in the single-layer `Course1B` namespace.
-/

-------------------------------------------------------------------------------
/-! ## 1. Dependent Types -/
-------------------------------------------------------------------------------

---------------------------------------
/-! ### 1.1. Type Polymorphism -/

namespace Course1B

/-! In STLC, the identity function must be defined separately for every type. -/
def id_Nat : Nat → Nat := fun n ↦ n
def id_String : String → String := fun s ↦ s
def id_Bool : Bool → Bool := fun b ↦ b

/-! A type polymorphic function can be applied to different types. -/
def id : ∀ α : Type, α → α := fun α ↦ fun x : α ↦ x

/-! Binders can be brought ahead of `:`. This is especially natural for dependent function declarations. -/
def id' (α : Type) : α → α := fun x ↦ x

#check id
#check id Nat
#check id String

end Course1B

---------------------------------------
/-! ### 1.2. Type Constructors -/

namespace Course1B

/-! In STLC, the sequence type must be defined separately for each element type. -/
def Sequence_Nat : Type := Nat → Nat
def Sequence_String : Type := Nat → String
def Sequence_Bool : Type := Nat → Bool

/-! A type constructor accepts types and returns a new type. -/
def Sequence : Type → Type := fun α ↦ Nat → α
def Sequence' (α : Type) : Type := Nat → α

#print Sequence
#check Sequence Nat
#check Sequence String

---------------------------------------
/-! ### 1.3. Dependent Function Types -/

/-! In a dependent function type, the result type may vary depending on the input value. -/

def printStyle : Bool → Type | true => Nat | false => String
def printNum : Nat → (b : Bool) → printStyle b := fun n ↦ fun b ↦ match b with | true => n | false => toString n

---------------------------------------
/-! ### 1.4. General Dependent Types -/

/-! A dependent pair stores an index and a value whose type depends on that index. -/
def PackedFin : Type := Sigma (fun n : Nat ↦ Fin (n + 1))

def packedFin : PackedFin := ⟨2, 1⟩

#check PackedFin
#check packedFin
#check packedFin.fst
#check packedFin.snd

/-! Implicit binders `{· : ·}` can be used when the parameter can be inferred from context. -/
def implicitId {α : Type} (x : α) : α := x

#check implicitId
#check @implicitId

/-! Explicit `@` exposes all implicit parameters of a declaration. -/
def chooseFirst {α : Type} {β : Type} (x : α) (_ : β) : α := x

#check chooseFirst
#check @chooseFirst

end Course1B

/-! Implicit arguments are inferred constraints, not values erased from the type theory. -/

-------------------------------------------------------------------------------
/-! ## 2. Type Universes -/
-------------------------------------------------------------------------------
---------------------------------------
/-! ### 2.1. The Type Universe Hierarchy -/

/-! Regular terms have types. -/
#check 1                               -- Nat
#check "Hello, world!"                 -- String
#check true                            -- Bool

/-! Types are terms too, and therefore have types in a higher universe. -/
#check Nat                             -- Type
#check String                          -- Type
#check Bool                            -- Type

/-! Lean uses an unbounded hierarchy `Type 0`, `Type 1`, ... . -/
#check Type                            -- Type 1
#check Type 1                          -- Type 2
#check Type 32                         -- Type 33

---------------------------------------
/-! ### 2.2. Predicativity -/

/-! Π-types live high enough to contain both their domain and every codomain. -/
#check Nat → Nat                       -- Type
#check Nat → Type                      -- Type 1
#check Type → Nat                      -- Type 1
#check Type → Type                     -- Type 1
#check Type 1 → Type 2                 -- Type 3
#check Type 32 → Type                  -- Type 33

/-! Universe parameters let one declaration work uniformly at every level. -/
#print Course1B.id

/-!
`Prop` has a special impredicative design and is deliberately postponed to 2A.
-/

---------------------------------------
/-! ### 2.3. Universe Polymorphism -/

namespace Course1B

universe u

/-! A universe-polymorphic identity works for a type in any `Type u`. -/
def universeId {α : Type u} (x : α) : α := x

#print universeId

end Course1B

-------------------------------------------------------------------------------
/-! ## 3. Inductive Types -/
-------------------------------------------------------------------------------

/-! Inductive declaration information. -/

/-! An inductive declaration records its parameter/index context, result type, and constructors. -/

/-! A constructor record consists of its name together with its complete dependent function type. -/

/-! Removing a constructor's leading binders must leave the declared inductive family at the result head. -/

/-! Recursive occurrences are accepted only in positions admitted by Lean's strict-positivity check. -/

/-! Covariant type-former arguments preserve the polarity of recursive occurrences. -/

/-! Contravariant type-former arguments reverse the polarity of recursive occurrences. -/

/-! Variance is useful intuition, but sign parity alone does not characterize strict positivity. -/

/-! Lean generates a recursor from the constructors of every accepted inductive declaration. -/

/-! Reducing a recursor at a constructor application is an iota reduction. -/

/-! A non-strictly-positive declaration is rejected, so Lean never generates its putative recursor. -/

/-! ### 3.1. Enumeration Types -/

namespace Course1B

/-! An enumeration type lists all possible values as nullary constructors. -/
inductive Bool where
  | true
  | false

#print Bool
#print Bool.true
#print Bool.false
#print Bool.rec

#check Bool.noConfusion
#check Bool.noConfusionType

/-! A three-constructor enumeration used by the structured notes. -/
inductive Color where
  | red
  | green
  | blue

#print Color
#print Color.red
#print Color.green
#print Color.blue
#print Color.rec

inductive Weekday where
  | monday
  | tuesday
  | wednesday
  | thursday
  | friday
  | saturday
  | sunday

#print Weekday
#print Weekday.monday
#print Weekday.rec

end Course1B

/-! Compare with Lean's standard enumeration. -/
#print Bool
#print Bool.rec

/-! ### 3.2. Sum Types -/

namespace Course1B

universe u v

/-! A sum contains a value from exactly one of two alternatives. -/
inductive Sum (α : Type u) (β : Type v) where
  | inl : α → Sum α β
  | inr : β → Sum α β

#check Sum
#check Sum.inl
#check Sum.inr
#check Sum.rec

end Course1B

/-! Lean's standard sum has the same constructor shape. -/
#check Sum
#check Sum.inl
#check Sum.inr
#check Sum.rec

/-! ### 3.3. Product Types -/

namespace Course1B

universe u v

/-! A product has one constructor carrying both components. -/
inductive Prod (α : Type u) (β : Type v) where
  | mk : α → β → Prod α β

#check Prod
#check Prod.mk
#check Prod.rec

/-! The unit type has exactly one constructor. -/
inductive Unit where
  | unit

#check Unit
#check Unit.unit
#check Unit.rec

/-! The empty type has no constructors. -/
inductive Void

#check Void
#check Void.rec

/-! Currying converts a function on a product into a two-argument function. -/
def curry {α : Type u} {β : Type v} {γ : Type} (f : Prod α β → γ) : α → β → γ :=
  fun a b ↦ f (.mk a b)

#check curry

end Course1B

#check Prod
#check Prod.mk
#check Prod.fst
#check Prod.snd

/-! ### 3.4. Natural Number Type -/

namespace Course1B

/-! Natural numbers are generated from zero by repeated successor. -/
inductive Nat where
  | zero : Nat
  | succ : Nat → Nat

#check Nat
#check Nat.zero
#check Nat.succ
#check Nat.rec

end Course1B

#check Nat
#check Nat.rec

/-! ### 3.5. List Type -/

namespace Course1B

universe u

/-! A list is either empty or a head followed by a smaller list. -/
inductive List (α : Type u) where
  | nil : List α
  | cons : α → List α → List α

#check List
#check List.nil
#check List.cons
#check List.rec

end Course1B

#check List
#check List.rec

/-! ### 3.6. Binary Tree Type -/

namespace Course1B

universe u

/-! Recursive fields may occur more than once, giving a branching data type. -/
inductive BinTree (α : Type u) where
  | leaf : α → BinTree α
  | node : BinTree α → BinTree α → BinTree α

#check BinTree
#check BinTree.leaf
#check BinTree.node
#check BinTree.rec

end Course1B

/-! ### 3.7. Vector Type -/

namespace Course1B

universe u
variable {α : Type u}

/-! A vector is a list indexed by its length. Constructors determine the index. -/
inductive Vector (α : Type u) : Nat → Type u where
  | nil : Vector α .zero
  | cons {n : Nat} : α → Vector α n → Vector α (.succ n)

#check Vector
#check Vector.nil
#check Vector.cons
#check Vector.rec

/-! The index rules out the empty constructor, so no impossible branch is needed. -/
def vectorHead {n : Nat} : Vector α (.succ n) → α
  | .cons x _ => x

#check vectorHead

end Course1B

#check Vector
#check Vector.ofFn
#check Vector.get

/-! ### 3.8. W-Types -/

namespace Course1B

universe u v

/-!
A W-type separates each node into a `shape` and a family of recursive positions. Different shapes
may therefore have different branching types.
-/
inductive W (shape : Type u) (position : shape → Type v) where
  | sup (a : shape) (children : position a → W shape position) : W shape position

#check W
#check W.sup
#check W.rec

end Course1B

/-! Equality is an inductive proposition; its proof-oriented treatment remains in 2A. -/
#check Eq
#check Eq.refl
#check Eq.rec

-------------------------------------------------------------------------------
/-! ## 4. Structure Types -/
-------------------------------------------------------------------------------

namespace Course1B

universe u v

/-!
A structure is a one-constructor inductive type with named fields. Lean generates the constructor,
projections, and record syntax.
-/
structure Point where
  x : Int
  y : Int

#check Point
#check Point.mk
#check Point.x
#check Point.y
#print Point.rec

/-! A structure field may depend on an earlier field. -/
structure DependentPair (α : Type u) (β : α → Type v) where
  fst : α
  snd : β fst

#check DependentPair
#check DependentPair.mk
#check DependentPair.fst
#check DependentPair.snd
#print DependentPair.rec

/-!
A structure may store a type and then use that type in later fields. This packages a carrier,
an initial state, and a transition operation without introducing typeclasses or laws.
-/
structure Automation where
  State : Type
  start : State
  step : State → Bool → State

#check Automation
#check Automation.mk
#check Automation.State
#check Automation.start
#check Automation.step
#print Automation.rec

/-!
A structure may also be recursive. Because `Option` supplies the `none` case, this declaration admits
finite linked chains even though the structure itself has only one constructor.
-/
structure LinkedNode (α : Type u) where
  value : α
  next : Option (LinkedNode α)

#check LinkedNode
#check LinkedNode.mk
#check LinkedNode.value
#check LinkedNode.next
#print LinkedNode.rec

/-! Record syntax exposes the finite base case supplied by `Option.none`. -/
def twoNodeChain : LinkedNode Nat :=
  { value := .succ .zero
    next := some { value := .succ (.succ .zero), next := none } }

#check twoNodeChain

/-!
Direct positive self-reference is legal, but the following inductive structure has no finite base
case. It is therefore not a coinductive stream and has no closed value built by a finite constructor
tree.
-/
structure StreamCell (α : Type u) where
  head : α
  tail : StreamCell α

#check StreamCell
#check StreamCell.mk
#print StreamCell.rec

/-!
A recursive occurrence in a function domain is negative and is rejected by Lean's positivity
checker. Activating the declaration below would fail with a non-positive-occurrence error.

```
structure BadStructure (α : Type u) where
  observe : BadStructure α → α
```
-/

end Course1B

-------------------------------------------------------------------------------
/-! ## 5. More on inductive types -/
-------------------------------------------------------------------------------

---------------------------------------
/-! ### 5.1. Pattern Matching -/

namespace Course1B

universe u
variable {α : Type u}

/-! Constructor patterns may be grouped when several branches return the same result. -/
def isWeekend : Weekday → Bool
  | .saturday | .sunday => .true
  | _ => .false

#check isWeekend

/-! Dependent pattern matching refines the vector index in the constructor branch. -/
def vectorTail {n : Nat} : Vector α (.succ n) → Vector α n
  | .cons _ xs => xs

#check vectorTail

end Course1B

---------------------------------------
/-! ### 5.2. Non-structural recursion and termination -/

namespace Course1B

universe u

/-! The recursive call is made on an immediate constructor field. -/
def natAdd : Nat → Nat → Nat
  | .zero, n => n
  | .succ m, n => .succ (natAdd m n)

#check natAdd

/-! List recursion has one case for each constructor. -/
def listLength {α : Type u} : List α → Nat
  | .nil => .zero
  | .cons _ xs => .succ (listLength xs)

#check listLength

/-! Non-structural recursion -/
def natDiv2 (n : _root_.Nat) : _root_.Nat := natDiv2 (n - 2) + 1
termination_by n
decreasing_by sorry                    -- This is actually false

partial def natDiv2' (n : _root_.Nat) : _root_.Nat := natDiv2' (n - 2) + 1
-- -- #eval natDiv2' 10 -- DON'T RUN THIS, LEAN CRASHES

partial def natLog2 (n : _root_.Nat) : _root_.Nat := match n with
  | 0 => 0
  | 1 => 0
  | _ => natLog2 (n / 2) + 1

#eval natLog2 10

end Course1B

---------------------------------------
/-! ### 5.3. Mutual and nested inductive types -/

namespace Course1B

mutual

inductive Even
  | zero : Even
  | succ : Odd → Even

inductive Odd
  | succ : Even → Odd

end

#print Even
#print Even.zero
#print Even.succ
#print Even.rec

#print Odd
#print Odd.succ
#print Odd.rec

/-! Chicken comes first or egg comes first? -/

mutual

inductive Chicken
  | hatch : Egg → Chicken

inductive Egg
  | lay : Chicken → Egg

end

end Course1B

-------------------------------------------------------------------------------
/-! ## Exercises -/
-------------------------------------------------------------------------------

-- It's advised to solve the exercises with AI, but not by AI.

---------------------------------------
/-! ### 1. Implement the `Expr` tree of UTLC using W-types or inductive types directly -/

namespace Course1B

inductive Expr_UTLC
def isClosed (e : Expr_UTLC) : Bool := sorry
def substitute (f x : Expr_UTLC) : Option Expr_UTLC := sorry
-- Is `f` legal for substitution?

def isNF (e : Expr_UTLC) : Bool := sorry
def isWNF (e : Expr_UTLC) : Bool := sorry
def isHNF (e : Expr_UTLC) : Bool := sorry
def isWHNF (e : Expr_UTLC) : Bool := sorry

def β (e : Expr_UTLC) (fuel : Nat) : Expr_UTLC × Bool := sorry
-- Did the reduction terminate before fuel ran out?

def S : Expr_UTLC := sorry
def K : Expr_UTLC := sorry
def I : Expr_UTLC := sorry

def ω : Expr_UTLC := sorry
def Ω : Expr_UTLC := sorry
def Y : Expr_UTLC := sorry

-- #eval isClosed S
-- #eval isClosed K
-- #eval isClosed I

-- #eval substitute I I
-- #eval substitute S K
-- #eval substitute ω ω
-- #eval β Ω 100
-- #eval β Y 100

---------------------------------------
/-! ### 2. Rebuild a working model of the physical quantities from 1A -/

/-- Cover all base dimensions. -/
inductive BaseDimension
def Dimension : Type := sorry
structure Quantity where

instance : Add Dimension where add a b := sorry
instance : Sub Dimension where sub a b := sorry

instance : SMul sorry Quantity where smul n a := sorry
instance : Add Quantity where add a b := sorry
instance : Sub Quantity where sub a b := sorry
instance : Mul Quantity where mul a b := sorry
instance : Div Quantity where div a b := sorry

#print BaseDimension
#print Dimension
#print Quantity

#check ((_ : Dimension) + (_ : Dimension))
#check ((_ : Dimension) - (_ : Dimension))


#check ((_ : _) • (_ : Quantity))
#check ((_ : Quantity) + (_ : Quantity))
#check ((_ : Quantity) - (_ : Quantity))
#check ((_ : Quantity) * (_ : Quantity))
#check ((_ : Quantity) / (_ : Quantity))

def g : Quantity := sorry              -- Gravitational acceleration constant
def ℏ : Quantity := sorry              -- Planck constant

---------------------------------------

/-! ### 3. Prove that there are no chickens or eggs in the world -/

def chicken_is_a_lie : Chicken → False :=
  Chicken.rec
    (motive_1 := fun _ ↦ False)
    (motive_2 := fun _ ↦ False)
    sorry
    sorry

def egg_is_a_lie : Egg → False :=
  Egg.rec
    (motive_1 := fun _ ↦ False)
    (motive_2 := fun _ ↦ False)
    sorry
    sorry

end Course1B
