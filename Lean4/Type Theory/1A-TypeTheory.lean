/-!
# 1A - Type Theory
-/

-------------------------------------------------------------------------------
/-! ## 1. Inspecting terms -/
-------------------------------------------------------------------------------

---------------------------------------
/-! ### 1.1. The `#check` command -/

/-! `#check` command checks the type of a term. -/

#check "Hello, World!"                 -- "Hello, World!" : String
#check 0                               -- 0 : Nat
#check 1 + 1                           -- 1 + 1 : Nat
#check 1 + 1 = 2                       -- 1 + 1 = 2 : Prop
#check true                            -- true : Bool

/-! Some funny syntax are elaborated as terms. -/
#check ()
#check []
#check {}
#check _
#check (·)
#check (· × ·)
#check (· : _)
#check (_ × _)

---------------------------------------
/-! ### 1.2. The `#print` command -/

/-! `#print` command prints the detailed declaration info of a constant. -/

#print id

---------------------------------------
/-! ### 1.3. The `#eval` command -/

/-! `#eval` command evaluates a term and prints the result if its type signature is representable. -/

#eval 1 + 1                            -- 2
#eval id 42                            -- 42

-------------------------------------------------------------------------------
/-! ## 2. λ-abstraction and application -/
-------------------------------------------------------------------------------

---------------------------------------
/-! ### 2.1. λ-abstraction -/

/-!
  A typed lambda abstraction `λ(x : A). t` is written as `fun x : A ↦ t` in Lean.
  Unicode characters can be typed by entering `\<name>`, which resemble $\LaTeX$ commands.
-/

#check fun x : Nat ↦ x                 -- fun x ↦ x : ℕ → ℕ
#check λ x => x + 1                    -- fun x ↦ x + 1 : ℕ → ℕ

/-!
  * `fun` can be replaced by `λ`; `λ` is deprecated in Mathlib and gives a warning.
  * `↦` can be replaced by `=>`.
  * A type annotation may be omitted when Lean can infer it.
-/

---------------------------------------
/-! ### 2.2. Application -/

#check fun (x : Nat) (y : Nat) ↦ x + y -- fun x y ↦ x + y : Nat → Nat → Nat
#check fun (f : Nat → Nat) ↦ f 0       -- fun f ↦ f 0 : (Nat → Nat) → Nat
#check id ((fun x ↦ x) (fun x ↦ x + 1)) 42

/-!
  * Application is written as `f x`.
  * The separating space is required: `f (x)` works, while `f(x)` does not parse as an application.
-/

-------------------------------------------------------------------------------
/-! ## 3. The `def` command: defining constants -/
-------------------------------------------------------------------------------

---------------------------------------
/-! ### 3.1. Defining constants -/

namespace Course1A

/-- `λx : Nat. x`; the identity function on natural numbers. -/
def id_Nat : Nat → Nat := fun x ↦ x
#print id_Nat                          -- def Course1A.id_Nat : Nat → Nat := fun x ↦ x
#eval id_Nat 42                        -- 42

/-- Context declarations can be brought ahead of `:`. -/
def id_Nat' (x : Nat) : Nat := x
#print id_Nat'                         -- def Course1A.id_Nat' : Nat → Nat := fun x ↦ x
#eval id_Nat' 42                       -- 42

/-- Composition of `Nat → Nat` functions. -/
def compose_Nat (f : Nat → Nat) (g : Nat → Nat) : Nat → Nat := fun x ↦ g (f x)
#print compose_Nat
#eval compose_Nat (fun x ↦ x + 2) (fun x ↦ x * 7) 4        -- 30

/-- Curry a function on pairs. -/
def curryNat (f : Nat × Nat → Nat) : Nat → Nat → Nat :=
  fun a b ↦ f (a, b)
#print curryNat
#check (· × ·)

end Course1A

---------------------------------------
/-! ### 3.2. Noncomputable definitions -/

namespace Course1A

noncomputable def nc_f : Nat → Nat := fun x ↦ x
-- #eval nc_f 42                       -- Error

end Course1A

---------------------------------------
/-! ### 3.3. Opaque definitions and axioms -/

namespace Course1A

axiom f : Nat → Nat
#print f

opaque g : Nat → Nat := fun x ↦ x + 1
#print g

-------------------------------------------------------------------------------
/-! ## Exercises -/
-------------------------------------------------------------------------------

/- Preparations -/

axiom A : Type
axiom B : Type
axiom C : Type

inductive BaseDimension | Length | Mass | Time
instance : ToString BaseDimension where toString | .Length => "m" | .Mass => "kg" | .Time => "s"
def Dimension := BaseDimension → Int
def m : Dimension | .Length => 1 | _ => 0
def s : Dimension | .Time => 1 | _ => 0
def mps : Dimension | .Length => -1 | .Time => 1 | _ => 0
def kg : Dimension | .Mass => 1 | _ => 0

instance : ToString Dimension where
  toString d :=
    let l := d .Length
    let str_l := if l = 0 then "" else if l = 1 then " m" else s!" m^{l}"
    let m := d .Mass
    let str_m := if m = 0 then "" else if m = 1 then " kg" else s!" kg^{m}"
    let t := d .Time
    let str_t := if t = 0 then "" else if t = 1 then " s" else s!" s^{t}"
    s!"{str_m}{str_l}{str_t}"

instance : Add Dimension where add d1 d2 := fun b ↦ d1 b + d2 b
instance : Sub Dimension where sub d1 d2 := fun b ↦ d1 b - d2 b
def Quantity := Float × Dimension
instance : SMul Float Quantity where smul a q := (a * q.1, q.2)
instance : HMul Float Dimension Quantity where hMul a d := (a, d)
instance : Repr Quantity where reprPrec q _ := s!"{q.1} {q.2}"
instance : Add Quantity where add q1 q2 := ⟨q1.1 + q2.1, q1.2⟩
instance : Sub Quantity where sub q1 q2 := ⟨q1.1 - q2.1, q1.2⟩
instance : Mul Quantity where mul q1 q2 := ⟨q1.1 * q2.1, q1.2 + q2.2⟩
instance : Div Quantity where div q1 q2 := ⟨q1.1 / q2.1, q1.2 - q2.2⟩

---------------------------------------
/-! ### 1. Write down the fully curried form of the functions, so that `(· × ·)` does not appear in the type: -/

def P1_1 : A × B × C → C := fun (_, _, c) ↦ c
def A1_1 : sorry := sorry

def P1_2 : (A × B) × (A → C) × (B → C) → C × C := fun ((a, b), f, g) ↦ (f a, g b)
def A1_2 : sorry := sorry

def P1_3 : ((A → C) → (B → C) → (A × B) → C) × (A → C) × (B → C) × A × B → C :=
  fun (c, f, g, a, b) ↦ c f g (a, b)
def A1_3 : sorry := sorry

---------------------------------------
/-! ### 2. Define simply typed SKI combinators: fill in the `sorry`s. -/

def I : sorry := sorry                 -- In UTLC, I := λx.x
def K : sorry := sorry                 -- In UTLC, K := λxy.x
def S : sorry := sorry                 -- In UTLC, S := λxyz.xz(yz)

#print I
#print K
#print S

-- Tip: Without Π-types, you will have to define a separate combinator for each type combination.
-- If you notice the incovenience, you are motivated for Π-types in lesson 1B.

---------------------------------------
/-! ### 3. Use `#eval` to calculate physical quantities: -/

-- You can create physical quantities by multiplying a float with a dimension.
def q1 : Quantity := 1.0 * m
def q2 : Quantity := 2.0 * s

-- You can evaluate formulae of physical quantities.
#eval q1 * q2
#eval q1 / q2
#eval 2.0 • q1

-- Sums / Differences for quantities with different dimensions return bad results, be careful with them.
#eval q1 + q2
#eval q1 - q2

-- Calculate the answer to the questions:

-- 1. What is the speed of a car that travels 100 m in 10 s?
def d_car : Quantity := sorry
def t_car : Quantity := sorry
def v_car : Quantity := sorry
-- #eval v_car

-- 2. How much distance is 1 light year?
def d_ly : Quantity := sorry
-- #eval d_ly
