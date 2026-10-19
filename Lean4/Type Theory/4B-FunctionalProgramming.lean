import Mathlib

/-!
# 4B · Functional Programming (Draft)

Starting from the detailed `Option` example, we derive context-specific composition, lifting, and
`bind` for Reader, State, Writer, IO, and List. A minimal TypeScript example separately illustrates
JavaScript promises. We then inspect Lean's real `Monad` interface, `do` notation, lawful Monad
properties, and Monad transformers.
-/

namespace Course4B

universe u v w
variable {α β γ δ : Type}

-------------------------------------------------------------------------------
/-! ## 1. Concrete Effect Contexts -/
-------------------------------------------------------------------------------

---------------------------------------
/-! ### 1. Functions that may fail (`Option`) -/

section

def find1 [Inhabited α] (xs : List α) (n : Nat) : α :=
  match xs with
  | .nil => panic! "index out of bounds"
  | .cons x xs => if n = 0 then x else find1 xs (n - 1)

/- In JavaScript, this function would return `undefined`. -/

inductive Undefined | undefined export Undefined (undefined)

def find2 (xs : List α) (n : Nat) : Sum α Undefined :=
  match xs with
  | .nil => .inr undefined
  | .cons x xs => if n = 0 then .inl x else find2 xs (n - 1)

/- Writing `Sum α Undefined` is annoying, why not make a type constructor? -/

def Option1 (α : Type) := Sum α Undefined

def find3 (xs : List α) (n : Nat) : Option1 α :=
  match xs with
  | .nil => .inr undefined
  | .cons x xs => if n = 0 then .inl x else find3 xs (n - 1)

/- Why do we even need `Undefined`? -/

inductive Option (α : Type)
  | none : Option α
  | some : α → Option α

#check _root_.Option
#check List.get?Internal

/- Now consider a bunch of such functions -/

variable (f1? : α -> Option α) (f2? : α -> Option β) (f3? : β -> Option γ)

def f4? (x : α) : Option γ :=
  match f1? x with
    | .none => .none  -- If one fails, the whole thing fails.
    | .some y => match f2? y with
      | .none => .none  -- again
      | .some z => f3? z

/-
  We can't repeat doing this all the time.
  How to λ-abstract the concept "if one fails, the whole thing fails"?
  We must compose the functions in a better way.
-/

def option_comp {α β γ : Type} (f2? : β -> Option γ) (f1? : α -> Option β) : α -> Option γ :=
  fun x => match f1? x with
    | .none => .none
    | .some y => match f2? y with
      | .none => .none
      | .some z => .some z

/-- Give it a nice notation -/
infixr:50 " ∘? " => option_comp

def f5? (x : α) : Option γ := (f3? ∘? f2? ∘? f1?) x

/- What if pure functions get involved? Simply lift them into `Option`. -/

variable (g : γ -> δ)

def option_lift_pure_fun (f : α -> β) : α -> Option β := fun x => .some (f x)
prefix:50 "?↑ " => option_lift_pure_fun

def f6? (x : α) : Option δ := ((?↑ g) ∘? f3? ∘? f2? ∘? f1?) x

/- Why even bother with functions? Dealing with terms are much easier: -/

def option_lift_pure_obj (x : α) : Option α := .some x
postfix:50 " ?↑" => option_lift_pure_obj

def option_bind (x : Option α) (f : α → Option β) : Option β :=
  match x with
  | .none => .none
  | .some a => f a
infixl:50 " >?>= " => option_bind

def f7? (x : α) : Option δ := (x ?↑) >?>= f1? >?>= f2? >?>= f3? >?>= (?↑ g)

/- In fact, `option_lift_pure_obj` and `option_lift_pure_fun` define each other regardless of the definition of `Option`: -/

example : option_lift_pure_fun =
  (fun pure_obj => fun f : α -> β => fun x => pure_obj (f x))
  option_lift_pure_obj
:= rfl

example : option_lift_pure_obj =
  (fun pure_fun => fun x : α => pure_fun id x)
  option_lift_pure_fun
:= rfl

/- Similarly, `option_bind` and `option_comp` define each other regardless of the definition of `Option`. -/

def option_bind_from_comp (x : Option α) (f : α → Option β) : Option β :=
  option_comp f (fun _ : Unit => x) ()

def option_comp_from_bind (f2? : β → Option γ) (f1? : α → Option β) : α → Option γ :=
  fun x => option_bind (f1? x) f2?

theorem option_rebuild (x : Option α) :
    (match x with | .none => .none | .some a => .some a) = x := by
  cases x <;> rfl

example (x : Option α) (f : α → Option β) : option_bind_from_comp x f = option_bind x f := by
  unfold option_bind_from_comp option_comp option_bind
  cases x with
  | none => rfl
  | some a => exact option_rebuild (f a)

example (f2? : β → Option γ) (f1? : α → Option β) (x : α) :
    option_comp_from_bind f2? f1? x = option_comp f2? f1? x := by
  unfold option_comp_from_bind option_comp option_bind
  cases h : f1? x with
  | none => rfl
  | some y => exact (option_rebuild (f2? y)).symm

end
---------------------------------------
/-! ### 2. Reading external context (`ReaderM`) -/

section Reader

/- Step 1: expose the hidden read-only dependency in the result type.
A `CourseReader ρ α` is just a function waiting for one shared environment `ρ`. -/
def CourseReader (ρ α : Type) := ρ → α

/- Step 2: define two concrete computations that both inspect the same environment. -/
def readerAddEnvironment (x : Nat) : CourseReader Nat Nat :=
  fun environment => x + environment

def readerMultiplyEnvironment (x : Nat) : CourseReader Nat Nat :=
  fun environment => x * environment

#eval readerAddEnvironment 5 10
#eval readerMultiplyEnvironment 15 10

/- Step 3: sequence them manually. Notice that `environment` must be passed twice. -/
def readerPipelineManual (x : Nat) : CourseReader Nat Nat :=
  fun environment =>
    let afterAdd := readerAddEnvironment x environment
    readerMultiplyEnvironment afterAdd environment

#eval readerPipelineManual 5 10

/- Step 4: abstract "run both computations in the same environment" as composition. -/
def reader_comp (f₂ : β → CourseReader ρ γ) (f₁ : α → CourseReader ρ β) :
    α → CourseReader ρ γ :=
  fun x environment => f₂ (f₁ x environment) environment

infixr:50 " ∘ᴿ " => reader_comp

/- Step 5: lift a pure function; it ignores the environment. -/
def reader_lift_pure_fun (f : α → β) : α → CourseReader ρ β :=
  fun x _ => f x

/- Step 6: lift one pure value into the Reader context. -/
def reader_lift_pure_obj (x : α) : CourseReader ρ α :=
  fun _ => x

/- Step 7: switch from composing functions to sequencing context-bearing values. -/
def reader_bind (x : CourseReader ρ α) (f : α → CourseReader ρ β) : CourseReader ρ β :=
  fun environment => f (x environment) environment

infixl:50 " >R>= " => reader_bind

/- Step 8: the concrete program now states only data dependencies; `reader_bind` shares the environment. -/
def readerPipeline (x : Nat) : CourseReader Nat Nat :=
  (reader_lift_pure_obj x) >R>= readerAddEnvironment >R>= readerMultiplyEnvironment

#eval readerPipeline 5 10

/- As for `Option`, Reader composition and Reader bind define each other. -/
def reader_bind_from_comp (x : CourseReader ρ α) (f : α → CourseReader ρ β) :
    CourseReader ρ β :=
  reader_comp f (fun _ : Unit => x) ()

def reader_comp_from_bind (f₂ : β → CourseReader ρ γ) (f₁ : α → CourseReader ρ β) :
    α → CourseReader ρ γ :=
  fun x => reader_bind (f₁ x) f₂

example (x : CourseReader ρ α) (f : α → CourseReader ρ β) (environment : ρ) :
    reader_bind_from_comp x f environment = reader_bind x f environment := rfl

end Reader

---------------------------------------
/-! ### 3. Maintaining a mutable state (`StateM`) -/

section State

/- Step 1: make both the incoming and outgoing state explicit. -/
def CourseState (σ α : Type) := σ → α × σ

/- Step 2: each concrete action returns a value together with its updated state. -/
def stateAdd (amount : Nat) : CourseState Nat Nat :=
  fun state =>
    let next := state + amount
    (next, next)

def stateMultiply (factor : Nat) : CourseState Nat Nat :=
  fun state =>
    let next := state * factor
    (next, next)

#eval stateAdd 5 10
#eval stateMultiply 15 15

/- Step 3: manual sequencing must unpack the first pair and pass `state₁` onward. -/
def statePipelineManual (amount : Nat) : CourseState Nat Nat :=
  fun state₀ =>
    let (afterAdd, state₁) := stateAdd amount state₀
    stateMultiply afterAdd state₁

#eval statePipelineManual 5 10

/- Step 4: abstract state-threading as composition. -/
def state_comp (f₂ : β → CourseState σ γ) (f₁ : α → CourseState σ β) :
    α → CourseState σ γ :=
  fun x state₀ =>
    let (y, state₁) := f₁ x state₀
    f₂ y state₁

infixr:50 " ∘ˢ " => state_comp

/- Step 5: a lifted pure function changes the value but leaves the state untouched. -/
def state_lift_pure_fun (f : α → β) : α → CourseState σ β :=
  fun x state => (f x, state)

/- Step 6: a lifted pure value also leaves the state untouched. -/
def state_lift_pure_obj (x : α) : CourseState σ α :=
  fun state => (x, state)

/- Step 7: `state_bind` is exactly the reusable unpack-and-thread operation. -/
def state_bind (x : CourseState σ α) (f : α → CourseState σ β) : CourseState σ β :=
  fun state₀ =>
    let (a, state₁) := x state₀
    f a state₁

infixl:50 " >S>= " => state_bind

/- Step 8: the same pipeline no longer mentions intermediate states. -/
def statePipeline (amount : Nat) : CourseState Nat Nat :=
  (state_lift_pure_obj amount) >S>= stateAdd >S>= stateMultiply

#eval statePipeline 5 10

/- State composition and State bind also recover one another. -/
def state_bind_from_comp (x : CourseState σ α) (f : α → CourseState σ β) :
    CourseState σ β :=
  state_comp f (fun _ : Unit => x) ()

def state_comp_from_bind (f₂ : β → CourseState σ γ) (f₁ : α → CourseState σ β) :
    α → CourseState σ γ :=
  fun x => state_bind (f₁ x) f₂

example (x : CourseState σ α) (f : α → CourseState σ β) (state : σ) :
    state_bind_from_comp x f state = state_bind x f state := rfl

end State

---------------------------------------
/-! ### 4. Writing into external context (`WriterM`) -/

section Writer

/- Step 1: a Writer result carries an ordinary value and an accumulated log. -/
def CourseWriter (α : Type) := α × List String

/- Step 2: concrete actions produce one value and one fresh log fragment. -/
def writerIncrement (x : Nat) : CourseWriter Nat :=
  (x + 1, [s!"increment {x} to {x + 1}"])

def writerDouble (x : Nat) : CourseWriter Nat :=
  (2 * x, [s!"double {x} to {2 * x}"])

#eval writerIncrement 10
#eval writerDouble 11

/- Step 3: manual sequencing must concatenate logs in execution order. -/
def writerPipelineManual (x : Nat) : CourseWriter Nat :=
  let (afterIncrement, log₁) := writerIncrement x
  let (afterDouble, log₂) := writerDouble afterIncrement
  (afterDouble, log₁ ++ log₂)

#eval writerPipelineManual 10

/- Step 4: abstract "continue and append the logs" as composition. -/
def writer_comp (f₂ : β → CourseWriter γ) (f₁ : α → CourseWriter β) :
    α → CourseWriter γ :=
  fun x =>
    let (y, log₁) := f₁ x
    let (z, log₂) := f₂ y
    (z, log₁ ++ log₂)

infixr:50 " ∘ᵂ " => writer_comp

/- Step 5: lifted pure functions produce no log entries. -/
def writer_lift_pure_fun (f : α → β) : α → CourseWriter β :=
  fun x => (f x, [])

/- Step 6: lifted pure values also start with an empty log. -/
def writer_lift_pure_obj (x : α) : CourseWriter α :=
  (x, [])

/- Step 7: `writer_bind` hides the repeated pair unpacking and log concatenation. -/
def writer_bind (x : CourseWriter α) (f : α → CourseWriter β) : CourseWriter β :=
  let (a, log₁) := x
  let (b, log₂) := f a
  (b, log₁ ++ log₂)

infixl:50 " >W>= " => writer_bind

/- Step 8: only the value dependencies remain visible in the final program. -/
def writerPipeline (x : Nat) : CourseWriter Nat :=
  (writer_lift_pure_obj x) >W>= writerIncrement >W>= writerDouble

#eval writerPipeline 10

/- Writer composition and Writer bind are the same abstraction at function and value level. -/
def writer_bind_from_comp (x : CourseWriter α) (f : α → CourseWriter β) : CourseWriter β :=
  writer_comp f (fun _ : Unit => x) ()

def writer_comp_from_bind (f₂ : β → CourseWriter γ) (f₁ : α → CourseWriter β) :
    α → CourseWriter γ :=
  fun x => writer_bind (f₁ x) f₂

example (x : CourseWriter α) (f : α → CourseWriter β) :
    writer_bind_from_comp x f = writer_bind x f := rfl

end Writer

---------------------------------------
/-! ### 5. Printing (`IO`) -/

section IO

/- Step 1: an `IO α` is a description of an action that may interact with the outside world
before producing an `α`. Unlike the previous contexts, Lean keeps its runtime representation abstract. -/

/- Step 2: these concrete actions print what they receive before returning the next value. -/
def ioIncrement (x : Nat) : IO Nat := do
  IO.println s!"increment received {x}"
  pure (x + 1)

def ioDouble (x : Nat) : IO Nat := do
  IO.println s!"double received {x}"
  pure (2 * x)

#eval ioIncrement 10

/- Step 3: manual sequencing names and forwards every intermediate result. -/
def ioPipelineManual (x : Nat) : IO Nat := do
  let afterIncrement ← ioIncrement x
  let afterDouble ← ioDouble afterIncrement
  pure afterDouble

#eval ioPipelineManual 10

/- Step 4: IO composition runs the second action only after the first has completed. -/
def io_comp (f₂ : β → IO γ) (f₁ : α → IO β) : α → IO γ :=
  fun x => do
    let y ← f₁ x
    f₂ y

infixr:50 " ∘ᴵᴼ " => io_comp

/- Step 5: lifting a pure function computes without adding observable IO actions. -/
def io_lift_pure_fun (f : α → β) : α → IO β :=
  fun x => pure (f x)

/- Step 6: `pure` lifts one value into IO without printing, reading, or writing anything. -/
def io_lift_pure_obj (x : α) : IO α :=
  pure x

/- Step 7: IO bind is the reusable wait-for-a-result-then-continue operation. -/
def io_bind (x : IO α) (f : α → IO β) : IO β := do
  let a ← x
  f a

infixl:50 " >IO>= " => io_bind

/- Step 8: the final pipeline has the same data-flow shape as the preceding Monads. -/
def ioPipeline (x : Nat) : IO Nat :=
  (io_lift_pure_obj x) >IO>= ioIncrement >IO>= ioDouble

#eval ioPipeline 10

/- These definitions show the two directions without exposing IO's runtime representation. -/
def io_bind_from_comp (x : IO α) (f : α → IO β) : IO β :=
  io_comp f (fun _ : Unit => x) ()

def io_comp_from_bind (f₂ : β → IO γ) (f₁ : α → IO β) : α → IO γ :=
  fun x => io_bind (f₁ x) f₂

end IO

---------------------------------------
/-! ### 6. Indefinite output (`List`) -/

section List

/- Step 1: `List α` represents a finite computation with zero, one, or several possible values. -/

/- Step 2: the first action branches; the second continues from every branch. -/
def listSigns (n : Nat) : List Int :=
  if n = 0 then [0] else [Int.ofNat n, -Int.ofNat n]

def listNeighbors (x : Int) : List Int :=
  [x - 1, x + 1]

#eval listSigns 3
#eval listNeighbors 3

/- Step 3: manual sequencing maps the second action over all branches, then flattens one List layer. -/
def listPipelineManual (n : Nat) : List Int :=
  (listSigns n).flatMap fun sign => listNeighbors sign

#eval listPipelineManual 3

/- Step 4: List composition packages that branch-and-flatten rule. -/
def list_comp (f₂ : β → List γ) (f₁ : α → List β) : α → List γ :=
  fun x => (f₁ x).flatMap f₂

infixr:50 " ∘ᴸ " => list_comp

/- Step 5: lifting a pure function gives exactly one result. -/
def list_lift_pure_fun (f : α → β) : α → List β :=
  fun x => [f x]

/- Step 6: lifting a pure value creates one successful branch. -/
def list_lift_pure_obj (x : α) : List α :=
  [x]

/- Step 7: List bind is `flatMap`. -/
def list_bind (x : List α) (f : α → List β) : List β :=
  x.flatMap f

infixl:50 " >L>= " => list_bind

/- Step 8: the final program mentions branching functions but not flattening. -/
def listPipeline (n : Nat) : List Int :=
  (list_lift_pure_obj n) >L>= listSigns >L>= listNeighbors

#eval listPipeline 3

/- List composition and List bind recover one another. -/
def list_bind_from_comp (x : List α) (f : α → List β) : List β :=
  list_comp f (fun _ : Unit => x) ()

def list_comp_from_bind (f₂ : β → List γ) (f₁ : α → List β) : α → List γ :=
  fun x => list_bind (f₁ x) f₂

example (x : List α) (f : α → List β) :
    list_bind_from_comp x f = list_bind x f := rfl

end List

---------------------------------------
/-! ### 7. A Minimal TypeScript Promise Example -/

/-!
TypeScript's `Promise.resolve` plays the role of lifting a pure value, while `.then` sequences a
continuation that depends on the previous result. Unlike the Lean contexts above, this example is
TypeScript rather than a new Lean type alias.

```typescript
const answer: Promise<number> = Promise.resolve(10)
  .then(x => x + 1)
  .then(x => x * 2);

answer.then(console.log); // 22
```
-/

end Course4B

-------------------------------------------------------------------------------
/-! ## 2. Lean's Monad Interface -/
-------------------------------------------------------------------------------

/-! ### 2.1 The Real Definitions and Instances -/

/-! `#print` shows that Lean's `Monad` extends `Applicative` and `Bind`. The two operations central
in this lesson are inherited `pure` and `bind`; the other fields support mapping and sequencing. -/

#print Monad

/-! These are Lean's actual context constructors, not the course-local reconstructions above. -/

#print ReaderM
#print StateM
#print WriterT
#check IO
#check Option
#check List

/-! Instance synthesis confirms that every constructor below has Lean's real `Monad` interface. -/

#synth Monad Option
#synth Monad (ReaderM Nat)
#synth Monad (StateM Nat)
#synth Monad (WriterT (List String) Id)
#synth Monad IO
#synth Monad List

/-- Monad can be viewed as an effect of gradual approximation -/
local instance : Monad Set where
  pure x := {x}
  bind xs f := ⋃₀ (Set.image f xs)
#synth Monad Set

variable {f g : ℂ -> Set ℂ}
example : ℂ -> Set ℂ := f >=> g

local instance : Monad Filter where
#synth Monad Filter

/-! ### 2.2 `do` Notation -/

universe u v

/-- A generic two-step program written with `do`. -/
def officialDoTwoSteps {M : Type u → Type v} [Monad M] {α β γ : Type u}
    (start : M α) (first : α → M β) (second : β → M γ) : M γ := do
  let x ← start
  let y ← first x
  second y

/-- The same program after expanding the essential `do` syntax into `bind`. -/
def officialBindTwoSteps {M : Type u → Type v} [Monad M] {α β γ : Type u}
    (start : M α) (first : α → M β) (second : β → M γ) : M γ :=
  start >>= fun x => first x >>= second

example {M : Type u → Type v} [Monad M] {α β γ : Type u}
    (start : M α) (first : α → M β) (second : β → M γ) :
    officialDoTwoSteps start first second = officialBindTwoSteps start first second := rfl

/-! The same surface syntax now runs with each official Monad instance. -/

def officialOptionDo (x : Int) : Option Int := do
  let positive ← if 0 < x then some (x + 1) else none
  pure (2 * positive)

#eval officialOptionDo 10
#eval officialOptionDo (-10)

def officialReaderDo (x : Nat) : ReaderM Nat Nat := do
  let environment ← read
  pure ((x + environment) * environment)

#eval officialReaderDo 5 10

def officialStateDo (amount : Nat) : StateM Nat Nat := do
  let state ← get
  let afterAdd := state + amount
  set afterAdd
  let afterMultiply := afterAdd * afterAdd
  set afterMultiply
  pure afterMultiply

#eval (officialStateDo 5).run 10

def officialTell (message : String) : WriterT (List String) Id Unit :=
  WriterT.mk ((), [message])

def officialWriterDo (x : Nat) : WriterT (List String) Id Nat := do
  let afterIncrement := x + 1
  officialTell s!"increment {x} to {afterIncrement}"
  let afterDouble := 2 * afterIncrement
  officialTell s!"double {afterIncrement} to {afterDouble}"
  pure afterDouble

#eval officialWriterDo 10 |>.run

def officialIODo (x : Nat) : IO Nat := do
  IO.println s!"increment received {x}"
  let afterIncrement := x + 1
  IO.println s!"double received {afterIncrement}"
  pure (2 * afterIncrement)

#eval officialIODo 10

def officialListDo (n : Nat) : List Int := do
  let sign ← if n = 0 then [0] else [Int.ofNat n, -Int.ofNat n]
  [sign - 1, sign + 1]

#eval officialListDo 3

/-! ### 2.3 Laws and the Mathematics of Kleisli Composition -/

#print LawfulMonad

/-! Lean has lawful instances for the standard contexts below. Mathlib also provides a lawful
`WriterT` instance under monoid assumptions. However, the `List String` synthesis above selects the
more general empty-and-append Monad dictionary, and `LawfulMonad` must refer to the same dictionary;
instance synthesis therefore does not combine those two choices automatically. -/

#synth LawfulMonad Option
#synth LawfulMonad (ReaderM Nat)
#synth LawfulMonad (StateM Nat)
#synth LawfulMonad IO
#synth LawfulMonad List

section LawfulMonadLaws

variable {M : Type u → Type v} [Monad M] [LawfulMonad M]
variable {α β γ δ : Type u}

/-- Left identity: lifting a value and immediately binding is the same as applying the continuation. -/
example (x : α) (f : α → M β) : pure x >>= f = f x :=
  LawfulMonad.pure_bind x f

/-- Right identity: binding with `pure` does not change a computation. -/
example (mx : M α) : mx >>= pure = mx :=
  bind_pure mx

/-- Associativity: regrouping dependent sequencing does not change the result. -/
example (mx : M α) (f : α → M β) (g : β → M γ) :
    (mx >>= f) >>= g = mx >>= fun x => f x >>= g :=
  LawfulMonad.bind_assoc mx f g

/-- Kleisli composition composes functions whose codomain is a Monad. -/
def kleisliComp (g : β → M γ) (f : α → M β) : α → M γ :=
  fun x => f x >>= g

/-- `pure` is a left identity for Kleisli composition: `pure >=> f = f`. -/
example (f : α → M β) (x : α) : kleisliComp f pure x = f x := by
  simp [kleisliComp]

/-- `pure` is a right identity for Kleisli composition: `f >=> pure = f`. -/
example (f : α → M β) (x : α) : kleisliComp pure f x = f x := by
  simp [kleisliComp]

/-- Kleisli composition is associative. -/
example (f : α → M β) (g : β → M γ) (h : γ → M δ) (x : α) :
    kleisliComp h (kleisliComp g f) x = kleisliComp (kleisliComp h g) f x := by
  unfold kleisliComp
  exact LawfulMonad.bind_assoc (f x) g h

end LawfulMonadLaws

-------------------------------------------------------------------------------
/-! ## 3. Monad Transformers -/
-------------------------------------------------------------------------------

/-! ### 3.1 From Nested Contexts to `OptionT` -/

/-! `IO (Option α)` combines effects, but ordinary `IO.bind` exposes an `Option` that must then be
matched manually. -/

def transformerCheckedRaw (value : Int) : IO (Option Nat) := do
  IO.println s!"checking {value}"
  if 0 < value then pure (some value.toNat) else pure none

def transformerManual (value : Int) : IO (Option Nat) := do
  match ← transformerCheckedRaw value with
  | none => pure none
  | some n =>
      IO.println s!"accepted {n}"
      pure (some (n + 1))

#eval transformerManual 4
#eval transformerManual (-4)

/-! `OptionT IO α` packages that nested shape as one Monad. `OptionT.mk` enters the transformed
context; `OptionT.lift` embeds an `IO` action that cannot itself fail with `none`. -/

def transformerChecked (value : Int) : OptionT IO Nat :=
  OptionT.mk (transformerCheckedRaw value)

def transformerProgram (value : Int) : OptionT IO Nat := do
  let n ← transformerChecked value
  OptionT.lift (IO.println s!"accepted {n}")
  pure (n + 1)

#synth Monad (OptionT IO)
#eval (transformerProgram 4).run
#eval (transformerProgram (-4)).run

/-! ### 3.2 Transformer Order Changes Semantics -/

/-- Failure encloses the result-state pair, so failure discards the final state. -/
abbrev AbortStateT (α : Type) := StateT Nat (OptionT IO) α

def transformerAbortAfterUpdate : AbortStateT Nat := do
  set 1
  failure

#eval (transformerAbortAfterUpdate.run 0).run

/-- State encloses the optional result, so the updated state remains observable after failure. -/
abbrev PreserveStateT (α : Type) := OptionT (StateT Nat IO) α

def transformerPreserveAfterUpdate : PreserveStateT Nat := do
  OptionT.lift (set 1 : StateT Nat IO PUnit)
  failure

#eval transformerPreserveAfterUpdate.run.run 0

/-!
The two run types make the difference explicit:

* `StateT Nat (OptionT IO) α` runs as `IO (Option (α × Nat))`;
* `OptionT (StateT Nat IO) α` runs as `IO (Option α × Nat)`.
-/

/-! ### 3.3 Lifting through Several Layers -/

/-- State, possible failure, and observable IO coexist in one transformer stack. -/
def transformerStackedProgram (limit : Nat) : AbortStateT Nat := do
  liftM (IO.println s!"limit = {limit}")
  let current ← get
  set (current + 1)
  if current < limit then pure current else failure

#eval (transformerStackedProgram 5 |>.run 2 |>.run)
#eval (transformerStackedProgram 1 |>.run 2 |>.run)

-------------------------------------------------------------------------------
/-! ## 4. Querying and Exporting Constant Information -/
-------------------------------------------------------------------------------

/-!
The JSON encoding below is adapted from the extraction script in
[`SJTU-AI4Math/Graphic-Mathlib`](https://github.com/SJTU-AI4Math/Graphic-Mathlib),
commit `397db9a9c8ae3fde68a2858435fcc5f1ef9bf3e1`. The theorem proof term is omitted
because it can be much larger than the remaining declaration information.
-/

open Lean

namespace ConstantInfoJson

/-!
There are two ways to obtain the supporting instances below:

* `Level`, `Expr`, `ReducibilityHints`, `TheoremVal`, and `ConstantInfo` use manually written
  encoders because their JSON representation needs customization;
* declarations such as `DefinitionSafety`, `RecursorRule`, and the individual constant-value
  structures use `deriving instance`, which generates an encoder from their constructor fields.

`deriving instance` generates new implementation code. This is distinct from ordinary typeclass
synthesis, which searches for an instance that has already been registered.
-/

instance : ToJson Level where
  toJson level :=
    match level with
    | .param name => Json.str s!"param.{name}"
    | _ => toJson level.depth

deriving instance ToJson for BinderInfo

/-- Recursively encode the kernel expression constructors used by `ConstantInfo`. -/
def exprToJson : Expr → Json
  | .const name levels => Json.mkObj [
      ("r", "const"), ("n", toJson name.toString), ("l", toJson levels)]
  | .bvar index => Json.mkObj [("r", "bvar"), ("i", toJson index)]
  | .app fn arg => Json.mkObj [
      ("r", "app"), ("f", exprToJson fn), ("a", exprToJson arg)]
  | .lam name type body info => Json.mkObj [
      ("r", "lam"), ("n", toJson name.toString), ("t", exprToJson type),
      ("b", exprToJson body), ("i", toJson info)]
  | .forallE name type body info => Json.mkObj [
      ("r", "forallE"), ("n", toJson name.toString), ("t", exprToJson type),
      ("b", exprToJson body), ("i", toJson info),
      ("d", toJson (body.hasLooseBVar 0))]
  | .fvar id => Json.mkObj [("r", "fvar"), ("n", toJson id.name.toString)]
  | .mvar id => Json.mkObj [("r", "mvar"), ("n", toJson id.name.toString)]
  | .sort level => Json.mkObj [("r", "sort"), ("l", toJson level)]
  | .lit (.natVal value) => Json.mkObj [("r", "lit"), ("v", toJson value)]
  | .lit (.strVal value) => Json.mkObj [("r", "lit"), ("v", toJson value)]
  | .mdata data expr => Json.mkObj [
      ("r", "mdata"), ("m", toJson (toString data)), ("e", exprToJson expr)]
  | .letE name type value body nonDependent => Json.mkObj [
      ("r", "letE"), ("n", toJson name.toString), ("t", exprToJson type),
      ("v", exprToJson value), ("b", exprToJson body), ("d", toJson nonDependent)]
  | .proj name index structExpr => Json.mkObj [
      ("r", "proj"), ("n", toJson name.toString), ("i", toJson index),
      ("s", exprToJson structExpr)]

instance : ToJson Expr where
  toJson := exprToJson

instance : ToJson ReducibilityHints where
  toJson
    | .opaque => "opaque"
    | .abbrev => "abbrev"
    | .regular height => Json.mkObj [
        ("kind", "regular"), ("height", toJson height.toNat)]

deriving instance ToJson for DefinitionSafety
deriving instance ToJson for RecursorRule
deriving instance ToJson for QuotKind
deriving instance ToJson for ConstantVal
deriving instance ToJson for AxiomVal
deriving instance ToJson for DefinitionVal
deriving instance ToJson for InductiveVal
deriving instance ToJson for ConstructorVal
deriving instance ToJson for RecursorVal
deriving instance ToJson for QuotVal
deriving instance ToJson for OpaqueVal

/-- Encode theorem metadata without serializing its potentially enormous proof term. -/
instance : ToJson TheoremVal where
  toJson value := Json.mkObj [
    ("name", toJson value.name.toString),
    ("levelParams", toJson (value.levelParams.map Name.toString)),
    ("type", toJson value.type),
    ("value", "skipped"),
    ("all", toJson (value.all.map Name.toString))]

/-- Dispatch to the JSON instance belonging to the actual declaration kind. -/
instance : ToJson ConstantInfo where
  toJson
    | .axiomInfo value => toJson value
    | .defnInfo value => toJson value
    | .thmInfo value => toJson value
    | .inductInfo value => toJson value
    | .ctorInfo value => toJson value
    | .recInfo value => toJson value
    | .quotInfo value => toJson value
    | .opaqueInfo value => toJson value

/-- Output path, resolved relative to the Lean process's current working directory. -/
def constantInfoOutputPath : System.FilePath := "4B-constant-info.json"

/-- Look up a constant, export its information as JSON, and fail when it is absent. -/
def exportConstantInfo : Name → CoreM ConstantInfo := fun name => do
  let env ← getEnv
  let some info := env.find? name
    | throwError m!"unknown constant '{name}'"
  IO.FS.writeFile constantInfoOutputPath (Json.pretty (toJson info))
  return info

#check exportConstantInfo

/-!
`ConstantInfo` has no display instance suitable for `#eval`, so discard the returned value when
running the command only for its JSON side effect:

```lean
#eval show CoreM Unit from do
  let _ ← exportConstantInfo `List.map
  pure ()
```

The command writes `4B-constant-info.json` in the Lean process's current working directory.
`IO.FS.writeFile` replaces an existing file at that path.
-/

end ConstantInfoJson
