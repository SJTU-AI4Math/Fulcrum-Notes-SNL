unsafe inductive Bad
  | mk :(Bad -> False) -> Bad

unsafe example : False :=
  have notBad (b : Bad) : False := match b with
    | .mk f => f (.mk f)
  have bad : Bad := .mk notBad
  notBad bad

-----------------------------------------------------------

unsafe inductive UTLC : Type 1 where
  | typed {α : Sort 1} (term : α) : UTLC
  | func (f : UTLC → UTLC) : UTLC

unsafe instance : Inhabited UTLC := ⟨.typed ()⟩

unsafe def UTLC.app : UTLC → UTLC → UTLC
  | .func f, x => f x
  | .typed _, _ => panic! "UTLC: application of a non-function"

unsafe class ToUTLC (α : Sort 1) where
  toUTLC : α → UTLC

unsafe class FromUTLC (α : Sort 1) where
  fromUTLC : UTLC → α

unsafe instance (priority := 100) (α : Sort 1) : ToUTLC α where
  toUTLC a := .typed a

unsafe instance (priority := 100) (α : Sort 1) : FromUTLC α where
  fromUTLC
    | .typed a => unsafeCast a
    | .func f  => unsafeCast f

unsafe instance (priority := 1000) {α β : Type}
    [FromUTLC α] [ToUTLC β] : ToUTLC (α → β) where
  toUTLC f := .func fun x => ToUTLC.toUTLC (f (FromUTLC.fromUTLC x))

unsafe instance (priority := 1000) {α β : Type}
    [ToUTLC α] [FromUTLC β] : FromUTLC (α → β) where
  fromUTLC f := fun x => FromUTLC.fromUTLC (UTLC.app f (ToUTLC.toUTLC x))

unsafe instance {α : Sort 1} [ToUTLC α] : CoeOut α UTLC where
  coe := ToUTLC.toUTLC

unsafe instance {α : Sort 1} [FromUTLC α] : Coe UTLC α where
  coe := FromUTLC.fromUTLC

unsafe instance : CoeFun UTLC (fun _ => UTLC → UTLC) where
  coe := UTLC.app

unsafe def UTLC.get (α : Sort 1) [FromUTLC α] (x : UTLC) : α :=
  FromUTLC.fromUTLC x

syntax "𝜆" ident "." term : term
macro_rules
  | `(𝜆 $x:ident . $body:term) =>
      `(UTLC.func (fun $x : UTLC => ($body : UTLC)))

unsafe def uid : UTLC := 𝜆x. x
unsafe def kU : UTLC := 𝜆x.𝜆_y. x
unsafe def omegaU : UTLC := 𝜆x. (x x)
unsafe def succU : UTLC := (fun n : Nat => n + 1)
unsafe def twiceU : UTLC := (fun f : Nat → Nat => fun x => f (f x))

variable (f : Nat → Nat) (x : UTLC)

#check (f x : UTLC)
#check (x x : UTLC)

#eval UTLC.get Nat (succU (41 : Nat))
#eval UTLC.get Nat (uid (123 : Nat))
#eval UTLC.get Nat ((twiceU succU) (10 : Nat))
#eval UTLC.get Nat ((fun n : Nat => n * 3) (7 : Nat))
