import Mathlib

/-!
# 4A · Effects, Computation Contexts, and Monads

The lesson begins with observable effects, pure functions, and concrete sequencing rules for `Option`,
`List`, `IO`, explicit state, and Promise-like asynchronous tasks. Only after these examples do we
define a small Monad interface, state its laws, revisit every example uniformly, and use the `List`
Monad for multivalued mathematics before finally combining effects with Monad transformers.
-/

set_option autoImplicit false

namespace Course4A

variable {α β γ σ : Type}

/-! ## 1. Effects, Pure Functions, and Concrete Sequencing -/

/-! ### Hidden State versus Explicit State -/

/-- A pure state transition: the old counter is an input and the new counter is an output. -/
def nextTicket (label : String) (counter : Nat) : String × Nat :=
  let next := counter + 1
  (s!"{label}-{next}", next)

#eval nextTicket "A" 0
#eval let first := nextTicket "A" 0; nextTicket "A" first.2

/-- Replaying a pure function on the same input gives the same result. -/
example : nextTicket "A" 0 = ("A-1", 1) := rfl

/-! ### Exceptions versus Explicit Failure -/

/-- Division that records failure in its result type. -/
def safeDiv (x y : Int) : Option Int :=
  if y = 0 then none else some (x / y)

/-- A second partial step. -/
def requirePositive (x : Int) : Option Int :=
  if 0 < x then some x else none

/-- Before any abstraction, sequencing `Option` means explicit case analysis and short-circuiting. -/
def optionPipelineManual (x y : Int) : Option Int :=
  match safeDiv x y with
  | none => none
  | some q => requirePositive q

#eval optionPipelineManual 20 4
#eval optionPipelineManual 20 0
#eval optionPipelineManual (-20) 4

/-! ### Multiple Results -/

/-- A finite multivalued function. -/
def signChoices (n : Nat) : List Int :=
  if n = 0 then [0] else [Int.ofNat n, -Int.ofNat n]

/-- Every branch continues, and the nested lists are flattened. -/
def neighboringChoicesManual (n : Nat) : List Int :=
  (signChoices n).flatMap fun x => [x - 1, x + 1]

#eval neighboringChoicesManual 3

/-! ### Input and Output -/

/-- Pure core: constructing a message does not print it. -/
def greeting (name : String) : String := s!"Hello, {name}!"

/-- Pure core: both the result and the intended output are ordinary data. -/
def greetingPlan (name : String) : Nat × List String :=
  let message := greeting name
  (message.length, [message])

#eval greetingPlan "Lean"

/-- Effectful boundary: this function actually writes to standard output. -/
def printGreeting (name : String) : IO Nat := do
  let message := greeting name
  IO.println message
  pure message.length

#eval printGreeting "Lean"

/-! ### Explicit State -/

/-- A stateful computation represented by a pure function. -/
def PureState (σ : Type) (α : Type) := σ → α × σ

/-- Read the current state without changing it. -/
def getState : PureState σ σ := fun state => (state, state)

/-- Replace the current state. -/
def putState (state : σ) : PureState σ Unit := fun _ => ((), state)

/-- Withdraw money; failure is a value, and the balance remains explicit. -/
def withdraw (amount : Nat) : PureState Nat (Option Nat) := fun balance =>
  if amount ≤ balance then
    let next := balance - amount
    (some next, next)
  else
    (none, balance)

/-- Manual state sequencing must thread the state returned by the first action. -/
def twoWithdrawalsManual (first second : Nat) : PureState Nat (Option Nat) := fun initial =>
  let (firstResult, afterFirst) := withdraw first initial
  match firstResult with
  | none => (none, afterFirst)
  | some _ => withdraw second afterFirst

#eval twoWithdrawalsManual 30 50 100
#eval twoWithdrawalsManual 30 50 60

/-! ### Promise-like Asynchronous Computations -/

/-- Lean's `Task` is the Promise-like object used in this lesson. -/
abbrev Promise (α : Type) := Task α

/-- An already resolved Promise. -/
def promisePure (value : α) : Promise α := Task.pure value

/-- Continue after a Promise resolves. `Task` exposes this operation even though it is not registered
as Lean's standard `Monad Task` instance. -/
def promiseThen (promise : Promise α) (next : α → Promise β) : Promise β :=
  Task.bind promise next

/-- Promise sequencing without Monad notation. -/
def promiseExample : Promise Nat :=
  promiseThen (promisePure 20) fun x =>
    promiseThen (promisePure (x + 1)) fun y =>
      promisePure (y * 2)

#eval IO.wait promiseExample

/-- Launch an actual `IO` action as an asynchronous task. -/
def delayedDoubleTask (x : Nat) : BaseIO (Task (Except IO.Error Nat)) :=
  IO.asTask do
    IO.sleep 5
    pure (2 * x)

/-! ### Five Concrete Sequencing Rules -/

/-! At this point we still study the concrete types directly. Each type answers the same question:
how should a computation continue after producing a value in its own context? -/

/-- `Option`: stop when a previous step failed. -/
def optionThen (value : Option α) (next : α → Option β) : Option β :=
  match value with
  | none => none
  | some x => next x

/-- `List`: continue every branch and flatten the results. -/
def listThen (values : List α) (next : α → List β) : List β :=
  values.flatMap next

/-- `IO`: run the first action, then run the action selected by its result. -/
def ioThen (action : IO α) (next : α → IO β) : IO β := do
  let x ← action
  next x

/-- `State`: pass the state produced by the first action to the second. -/
def stateThen (action : PureState σ α) (next : α → PureState σ β) : PureState σ β :=
  fun state =>
    let (x, nextState) := action state
    next x nextState

/-- Promise: wait for the first task, then start the dependent task. -/
def asyncThen (action : Promise α) (next : α → Promise β) : Promise β :=
  promiseThen action next

#eval optionThen (safeDiv 20 4) requirePositive
#eval listThen (signChoices 3) fun x => [x - 1, x + 1]
#eval stateThen (withdraw 30) (fun _ => withdraw 50) 100
#eval IO.wait (asyncThen (promisePure 20) fun x => promisePure (x + 1))

/-! ## 2. The Monad Abstraction -/

/-- The shared interface extracted from the five concrete examples. -/
class CourseMonad (M : Type → Type) where
  pure {α : Type} : α → M α
  bind {α β : Type} : M α → (α → M β) → M β

/-- Put an ordinary value into a computation context. -/
def coursePure {M : Type → Type} [CourseMonad M] {α : Type} (x : α) : M α :=
  CourseMonad.pure x

/-- Sequence two context-bearing computations. -/
def courseBind {M : Type → Type} [CourseMonad M] {α β : Type}
    (mx : M α) (next : α → M β) : M β :=
  CourseMonad.bind mx next

/-- The three Monad laws: left identity, right identity, and associativity. -/
class LawfulCourseMonad (M : Type → Type) [CourseMonad M] : Prop where
  left_identity {α β : Type} (x : α) (f : α → M β) :
    courseBind (coursePure x) f = f x
  right_identity {α : Type} (mx : M α) :
    courseBind mx coursePure = mx
  associativity {α β γ : Type} (mx : M α) (f : α → M β) (g : β → M γ) :
    courseBind (courseBind mx f) g = courseBind mx (fun x => courseBind (f x) g)

/-! ### Instances for the Five Examples -/

instance : CourseMonad Option where
  pure := some
  bind := optionThen

instance : CourseMonad List where
  pure := fun x => [x]
  bind := listThen

instance : CourseMonad IO where
  pure := pure
  bind := ioThen

instance {σ : Type} : CourseMonad (PureState σ) where
  pure := fun x state => (x, state)
  bind := stateThen

instance : CourseMonad Promise where
  pure := promisePure
  bind := promiseThen

/-- A single program that works for every course Monad. -/
def genericTwoSteps {M : Type → Type} [CourseMonad M]
    (start : M α) (first : α → M β) (second : β → M γ) : M γ :=
  courseBind start fun x =>
    courseBind (first x) second

#eval genericTwoSteps (coursePure (M := Option) (20 : Int))
  (fun x => safeDiv x 4) requirePositive

#eval genericTwoSteps (coursePure (M := List) (3 : Nat))
  signChoices (fun x => [x - 1, x + 1])

#eval genericTwoSteps (coursePure (M := PureState Nat) ())
  (fun _ => withdraw 30) (fun _ => withdraw 50) 100

#eval IO.wait <| genericTwoSteps (coursePure (M := Promise) (20 : Nat))
  (fun x => promisePure (x + 1)) (fun x => promisePure (x * 2))

/-- The same generic program with observable `IO` actions at both dependent steps. -/
def genericIOProgram : IO Nat :=
  genericTwoSteps (coursePure (M := IO) (20 : Nat))
    (fun x => do IO.println s!"IO first received {x}"; pure (x + 1))
    (fun x => do IO.println s!"IO second received {x}"; pure (x * 2))

#eval genericIOProgram

/-! ### Lean's Standard Monad Interface -/

#print Monad
#print LawfulMonad

#synth Monad Option
#synth LawfulMonad Option
#synth Monad List
#synth LawfulMonad List
#synth Monad IO
#synth Monad (StateM Nat)

/-- Standard `do` notation for `Option`. -/
def optionProgram (x y : Int) : Option Int := do
  let q ← safeDiv x y
  requirePositive q

/-- Standard `do` notation for nondeterministic `List` computations. -/
def listProgram (n : Nat) : List Int := do
  let root ← signChoices n
  [root - 1, root + 1]

/-- Standard `StateM` program. -/
def tick : StateM Nat Nat := do
  let current ← get
  set (current + 1)
  pure current

#eval optionProgram 20 4
#eval listProgram 3
#eval (do let a ← tick; let b ← tick; pure (a, b)).run 10

/-! ## 3. Mathematical Applications -/

/-! ### Multivalued Functions -/

/-- A finite multivalued function from `α` to `β`. -/
def Multi (α : Type) (β : Type) := α → List β

/-- Composition of multivalued functions is `List.bind` pointwise. -/
def multiComp (f : Multi α β) (g : Multi β γ) : Multi α γ :=
  fun x => (f x).flatMap g

/-- The signed integer square roots of a natural number, when they exist. -/
def integerSquareRoots (n : Nat) : List Int :=
  let root := Nat.sqrt n
  if root * root = n then
    if root = 0 then [0] else [Int.ofNat root, -Int.ofNat root]
  else
    []

/-- A second multivalued map used to demonstrate composition. -/
def integerNeighbors (x : Int) : List Int := [x - 1, x + 1]

#eval integerSquareRoots 25
#eval integerSquareRoots 26
#eval multiComp integerSquareRoots integerNeighbors 25

/-- The same multivalued composition written through the course Monad interface. -/
def multiCompMonad (f : Multi α β) (g : Multi β γ) : Multi α γ :=
  fun x => courseBind (f x) g

example : multiCompMonad integerSquareRoots integerNeighbors 25 = [4, 6, -6, -4] := by
  native_decide

/-! ### Relations as Set-valued Functions -/

/-- A finite relation represented by the list of values related to each input. -/
def FiniteRelation (α : Type) (β : Type) := α → List β

/-- Relational composition has exactly the same shape as multivalued-function composition. -/
def relationComp (R : FiniteRelation α β) (S : FiniteRelation β γ) :
    FiniteRelation α γ :=
  multiComp R S

/-- One step in the integer adjacency relation. -/
def adjacent : FiniteRelation Int Int := fun x => [x - 1, x + 1]

#eval relationComp adjacent adjacent 0

/-! The result `[ -2, 0, 0, 2 ]` retains two witnesses for reaching `0`. A `List` models
nondeterministic paths with multiplicity; replacing it by a finite set would forget multiplicity. -/

/-! ## 4. Monad Transformers -/

/-! ### Adding Failure to an Existing Monad -/

/-! A Monad transformer takes an existing Monad `M` and constructs a new Monad `T M` with one
additional computation context. `OptionT IO α`, for example, combines possible failure with `IO`
without manually matching an `Option` after every action. -/

/-- The untransformed computation has two visibly nested contexts. -/
def checkedInputRaw (value : Int) : IO (Option Nat) := do
  IO.println s!"checking {value}"
  if 0 < value then
    pure (some value.toNat)
  else
    pure none

/-- Without a transformer, the caller must unpack the inner `Option` by hand. -/
def optionIOProgramManual (value : Int) : IO (Option Nat) := do
  match ← checkedInputRaw value with
  | none => pure none
  | some n =>
      IO.println s!"accepted {n}"
      pure (some (n + 1))

#eval optionIOProgramManual 4
#eval optionIOProgramManual (-4)

/-- `OptionT.mk` turns the nested representation into one composable computation context. -/
def checkedInput (value : Int) : OptionT IO Nat :=
  OptionT.mk (checkedInputRaw value)

/-- `OptionT.lift` embeds a base `IO` action without introducing a new failure. -/
def optionTProgram (value : Int) : OptionT IO Nat := do
  let n ← checkedInput value
  OptionT.lift (IO.println s!"accepted {n}")
  pure (n + 1)

#eval (optionTProgram 4).run
#eval (optionTProgram (-4)).run

/-! ### Stacking State, Failure, and IO -/

/-- In this order, failure encloses the `(value, state)` pair, so failure discards the final state. -/
abbrev AbortStateStack (α : Type) := StateT Nat (OptionT IO) α

/-- Update the state and then fail. Running the stack returns only `none`. -/
def abortAfterUpdate : AbortStateStack Nat := do
  set 1
  failure

#eval (abortAfterUpdate.run 0).run

/-- In the opposite order, the state encloses the optional value, so it remains observable on failure. -/
abbrev PreserveStateStack (α : Type) := OptionT (StateT Nat IO) α

/-- The same update-then-fail shape now returns `(none, 1)`. -/
def preserveAfterUpdate : PreserveStateStack Nat := do
  OptionT.lift (set 1 : StateT Nat IO PUnit)
  failure

#eval (preserveAfterUpdate.run.run 0)

/-! Transformer order is therefore semantic, not cosmetic:

* `StateT Nat (OptionT IO) α` runs as `IO (Option (α × Nat))`;
* `OptionT (StateT Nat IO) α` runs as `IO (Option α × Nat)`.
-/

/-! ### Lifting through Several Layers -/

/-- Three effects in one stack: explicit state, possible failure, and observable `IO`. -/
def stackedProgram (limit : Nat) : AbortStateStack Nat := do
  liftM (IO.println s!"limit = {limit}")
  let current ← get
  set (current + 1)
  if current < limit then
    pure current
  else
    failure

#eval (stackedProgram 5 |>.run 2 |>.run)
#eval (stackedProgram 1 |>.run 2 |>.run)

end Course4A
