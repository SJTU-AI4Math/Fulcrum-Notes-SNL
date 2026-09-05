universe u v

structure Evidence (t : Sort u) where
  evidence : t

inductive Convincing (p : Sort u) where
  | proof : p → Convincing p
  | evidence {t : Sort v} : Evidence t → Convincing p

instance : Monad Convincing where
  pure := .proof
  bind x' f := match x' with
    | .proof x => match f x with
      | .proof y => .proof y
      | .evidence ef =>
    | .evidence e => .evidence e

/--
`convince name (binders) : p := body` 等价于
`def name (binders) : Convincing p := body`。
-/
syntax (name := convince) declModifiers "convince " declId (ppSpace bracketedBinder)*
  " : " term declVal : command

macro_rules
  | `(command| $mods:declModifiers convince $id:declId $[$bs:bracketedBinder]* : $ty $val:declVal) => do
    let cty ← `(Convincing $ty)
    `(command| $mods:declModifiers def $id $[$bs]* : $cty:term $val:declVal)

convince trivial_true : True := by
  left
  exact trivial

convince refl_nat (n : Nat) : n = n := by
  exact .proof rfl

convince implicit_id {α : Type} (x : α) : x = x := by
  exact .proof rfl

private convince fake_false : False := by
  right
  case t => exact String
  exact ⟨"Obvious"⟩

#check trivial_true
#check refl_nat
#check implicit_id
#check fake_false
