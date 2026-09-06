import Mathlib.Algebra.Group.Defs
import SNL4Lean

snl_macro "Semigroup" "const" "text" "#0 has Semigroup structure"
snl_macro "Semigroup.mul_assoc" "const" "text" "Associativity"
snl_macro "outParam" "const" "text" "#0"
snl_macro "HMul" "const" "text" "HMul #0 #1 #2"
snl_macro "Mul.mul" "const" "formula_inline" "#0 \\cdot #1"
snl_macro "Lean.proj" "rule" "text" "#0.#1"

/-! Semigroup defined in Mathlib -/
#print Semigroup
#snl_const_widget Semigroup

/-!
Consumer acceptance examples: these are real declarations, not fabricated SNL trees.
The commands below inspect `declarationToSnlEntry` through the public import.
They intentionally reject the old declaration macros; run RED/GREEN with the
old/new SNL4Lean dependency respectively. No serialized display string is an oracle.
-/
namespace BasicAlgebra

def naturalUnit : Nat := 1

-- An alias has no outer lambda; its declaration view eta-applies the RHS.
def successorAlias : Nat → Nat := Nat.succ

def square {α : Type} [Mul α] (x : α) : α := x * x

theorem naturalUnit_eq : naturalUnit = 1 := rfl

theorem square_eq {α : Type} [Mul α] (x : α) : square x = x * x := rfl

structure FactorPair (α : Type) where
  left : α
  right : α

inductive ProductExpr (α : Type) where
  | atom (value : α)
  | mul (left right : ProductExpr α)

meta section
open Lean Meta Elab Command SNL4Lean

private def requireTree (ok : Bool) (message : String) : MetaM Unit := do
  unless ok do throwError "BasicAlgebra SNL acceptance: {message}"

private def stringField? (node : SnlSyntaxTree) (key : String) : Option String := do
  let value ← (node.mdata.getObjVal? key).toOption
  value.getStr? |>.toOption

private def expectNode (tree : SnlSyntaxTree) (name : String) (arity : Nat) : MetaM Unit :=
  requireTree (tree.macro_name == name && tree.children.size == arity)
    s!"expected {name}/{arity}, got {tree.macro_name}/{tree.children.size}"

private partial def nodes (tree : SnlSyntaxTree) : Array SnlSyntaxTree :=
  #[tree] ++ tree.children.foldl (fun acc child => acc ++ nodes child) #[]

private def checkVocabulary (tree : SnlSyntaxTree) : MetaM Unit := do
  for node in nodes tree do
    requireTree (!(node.macro_name.endsWith "-hyp") &&
      !(#["def-struct", "def-inductive", "struct", "list-partial"].contains node.macro_name))
      s!"legacy macro {node.macro_name} remains in the actual tree"
    for (name, arity) in #[("variable", 2), ("def", 3), ("theorem", 1),
        ("structure", 2), ("inductive", 2)] do
      if node.macro_name == name then expectNode node name arity
    -- Eq's full expression tree keeps its implicit type; a renderer may hide it.
    if node.macro_name == "Eq" then expectNode node "Eq" 3

/-- Member types are independently delaborated closed trees with fresh bindId
supplies. Do not combine their IDs with the declaration's telescope or each other. -/
private partial def declarationScopeNodes (tree : SnlSyntaxTree) : Array SnlSyntaxTree :=
  if tree.macro_name == "member" || tree.macro_name == "constructor" then #[tree]
  else #[tree] ++ tree.children.foldl (fun acc child => acc ++ declarationScopeNodes child) #[]

/-- Identity/closure check, not a general lexical-dominance proof. Duplicate
printed names in separate scopes are allowed; duplicate bindId owners are not. -/
private def checkBindings (scopeNodes : Array SnlSyntaxTree) : MetaM Unit := do
  let mut ids : Array String := #[]
  for node in scopeNodes do
    if node.kind == "binder" then
      let some id := stringField? node "bindId" | throwError "binder lacks bindId"
      requireTree (!ids.contains id) s!"duplicate binder owner {id}"
      ids := ids.push id
  for node in scopeNodes do
    if node.kind == "bvar" then
      requireTree ((stringField? node "bindRef").isSome) "bound variable lacks bindRef"
    if let some ref := stringField? node "bindRef" then
      requireTree (ids.contains ref) s!"dangling bindRef {ref}"

private def checkEntry (declName : Name) (kind : String) (hypCount memberCount : Nat) :
    MetaM Unit := do
  let entry ← declarationToSnlEntry declName
  requireTree (entry.kind == kind) s!"unexpected Entry kind for {declName}"
  let some root := entry.declarationTree? | throwError "missing declaration tree"
  let some hypotheses := entry.hypothesesTree? | throwError "missing hypothesis tree"
  expectNode hypotheses "__list__" hypCount
  for hypothesis in hypotheses.children do
    expectNode hypothesis "Type.annotation" 2
    requireTree (hypothesis.children[0]!.kind == "binder") "H must own its binders"
  if declName == ``square || declName == ``square_eq then
    let infos := hypotheses.children.map fun hypothesis =>
      stringField? hypothesis.children[0]! "binderInfo"
    requireTree (infos == #[some "implicit", some "instImplicit", some "explicit"])
      "the context must retain implicit type, instance, and explicit argument in order"
  let declaration ← if hypCount == 0 then pure root else do
    expectNode root "variable" 2
    requireTree (root.children[0]! == hypotheses) "variable slot 0 must be H"
    pure root.children[1]!
  let head := if kind == "definition" then "def" else if kind == "class" then "structure" else kind
  let arity := if kind == "definition" then 3 else if kind == "theorem" then 1 else 2
  expectNode declaration head arity
  requireTree (entry.members.size == memberCount) "wrong member count"
  if kind == "definition" then
    let subject := declaration.children[0]!
    requireTree (subject.macro_name == declName.toString && subject.kind == "const")
      "def slot 0 must be the defined object, not a Type.judge wrapper"
    requireTree (subject.children.size == hypCount) "definition parameter count changed"
    for i in [:hypCount] do
      let some binder := hypotheses.children[i]!.children[0]?
        | throwError "hypothesis lacks binder"
      let argument := subject.children[i]!
      let id := stringField? binder "bindId"
      requireTree (id.isSome && argument.kind == "bvar" &&
        stringField? argument "bindRef" == id) "subject must reference H, not duplicate its binders"
    requireTree (declaration.children[1]! == entry.typeTree) "def slot 1 must be the type"
    let some value := entry.valueTree? | throwError "definition lost its body"
    let body := declaration.children[2]!
    requireTree (body == value)
      "def slot 2 must contain the complete value tree"
  else if kind == "theorem" then
    requireTree (declaration.children[0]! == entry.typeTree) "theorem slot 0 must be P"
    requireTree (entry.valueTree?.isNone) "theorem unexpectedly contains a proof value"
  else
    requireTree (declaration.children[0]!.macro_name == declName.toString)
      "structure/inductive slot 0 must name the declared object"
    let members := declaration.children[1]!
    expectNode members "__enum__" memberCount
    let memberKind := if kind == "structure" || kind == "class" then "member" else "constructor"
    for i in [:memberCount] do
      let member := members.children[i]!
      expectNode member memberKind 2
      requireTree (member.children[0]!.macro_name == entry.members[i]!.name)
        "member identity mismatch"
      if memberKind == "constructor" then
        requireTree (member.children[1]! == entry.members[i]!.typeTree)
          "constructor type mismatch"
      else
        -- The inline member has H in scope; the independently queried signature
        -- remains closed and is checked separately below.
        let raw ← delabExpr (← getConstInfo entry.members[i]!.name.toName).type
        requireTree (raw == entry.members[i]!.typeTree) "standalone member signature changed"
  checkVocabulary root
  checkVocabulary hypotheses
  checkVocabulary entry.typeTree
  if let some value := entry.valueTree? then checkVocabulary value
  checkBindings (if kind == "structure" || kind == "class" then nodes root else declarationScopeNodes root)
  for member in entry.members do
    checkVocabulary member.typeTree
    checkBindings (nodes member.typeTree)

syntax (name := basicAlgebraEntryGuard)
  "#basic_algebra_entry " ident " => " str ppSpace num ppSpace num : command

@[command_elab basicAlgebraEntryGuard]
def elabBasicAlgebraEntryGuard : CommandElab := fun stx => do
  let `(command| #basic_algebra_entry $name:ident => $kind:str $hyp:num $members:num) := stx
    | throwUnsupportedSyntax
  liftTermElabM do
    checkEntry (← resolveGlobalConstNoOverload name) kind.getString hyp.getNat members.getNat

#basic_algebra_entry naturalUnit => "definition" 0 0
#basic_algebra_entry successorAlias => "definition" 1 0
#basic_algebra_entry Semigroup => "class" 1 2
#basic_algebra_entry square => "definition" 3 0
#basic_algebra_entry naturalUnit_eq => "theorem" 0 0
#basic_algebra_entry square_eq => "theorem" 3 0
#basic_algebra_entry FactorPair => "structure" 1 2
#basic_algebra_entry ProductExpr => "inductive" 1 2

-- Independent Eq assertion: check the returned declaration tree, not only a
-- signature sibling or a string with hidden implicit arguments.
run_elab do
  for name in #[``naturalUnit_eq, ``square_eq] do
    let entry ← declarationToSnlEntry name
    let some root := entry.declarationTree? | throwError "missing Eq declaration"
    let eqs := (nodes root).filter (·.macro_name == "Eq")
    requireTree (eqs.size == 1) "expected exactly one Eq in the full declaration tree"
    let equality := eqs[0]!
    expectNode equality "Eq" 3
    requireTree (equality == entry.typeTree) "Eq changed between signature and declaration"
    let typeArg := equality.children[0]!
    if name == ``naturalUnit_eq then
      requireTree (typeArg.macro_name == "Nat" && typeArg.children.isEmpty)
        "Eq lost its implicit Nat argument"
    else
      let some hypotheses := entry.hypothesesTree? | throwError "missing Eq context"
      let α := hypotheses.children[0]!.children[0]!
      requireTree (typeArg.kind == "bvar" && (stringField? α "bindId").isSome &&
        stringField? typeArg "bindRef" == stringField? α "bindId")
        "Eq's implicit type must refer to the context's α binder"

-- Inherited data and a function-valued alias must not be silently shortened.
run_elab do
  let semigroup ← declarationToSnlEntry ``Semigroup
  requireTree (semigroup.members.any (·.name == "Mul.mul")) "lost inherited multiplication"
  let aliasEntry ← declarationToSnlEntry ``successorAlias
  requireTree (aliasEntry.typeTree.macro_name == "Nat") "eta-applied alias result type"
  let aliasTree ← delabDefinition ``successorAlias
  expectNode aliasTree "variable" 2
  let aliasDef := aliasTree.children[1]!
  expectNode aliasDef "def" 3
  requireTree (aliasDef.children[1]! == aliasEntry.typeTree) "public APIs disagree on alias type"
  let rhs := aliasDef.children[2]!
  expectNode rhs "Nat.succ" 1
  requireTree (rhs.children[0]!.kind == "bvar" &&
    stringField? rhs.children[0]! "bindRef" ==
      stringField? aliasTree.children[0]!.children[0]!.children[0]! "bindId")
    "eta-applied alias must use the new binder on the RHS"
  let product ← declarationToSnlEntry ``square
  let some value := product.valueTree? | throwError "missing multiplication value"
  expectNode value "HMul.hMul" 6
  let some h := product.hypothesesTree? | throwError "missing multiplication context"
  let ref := stringField? h.children[2]!.children[0]! "bindId"
  for i in #[4, 5] do
    requireTree (stringField? value.children[i]! "bindRef" == ref) "wrong multiplication operand"
  let eqMacro ← getSnlMacro "Eq"
  requireTree (eqMacro.styles[0]!.template == "#1 = #2") "Eq renders its implicit type as an operand"
  let mulMacro ← getSnlMacro "HMul.hMul"
  requireTree (mulMacro.styles[0]!.template == "#4 \\cdot #5") "multiplication slots are not full-tree indices"

-- Query registered macro contracts without replacing the actual-tree tests.
run_elab do
  for (name, arity) in #[("variable", 2), ("def", 3), ("theorem", 1),
      ("structure", 2), ("inductive", 2)] do
    let macroDef ← getSnlMacro name
    requireTree (!macroDef.dynamic_arity && macroDef.renderArity 99 == arity)
      s!"registered {name} has the wrong fixed arity"
  for name in #["__list__", "__enum__"] do
    let macroDef ← getSnlMacro name
    requireTree (macroDef.dynamic_arity && macroDef.renderArity 3 == 3)
      s!"registered {name} must preserve a dynamic operand list"

-- The enclosing structure supplies α only once; each projection keeps self.
run_elab do
  let pair ← declarationToSnlEntry ``FactorPair
  let h := pair.hypothesesTree?.get!
  let sharedId := stringField? h.children[0]!.children[0]! "bindId"
  let root := pair.declarationTree?.get!
  let members := root.children[1]!.children[1]!
  for member in members.children do
    let type := member.children[1]!
    expectNode type "Type.forall" 3
    let selfType := type.children[1]!
    expectNode selfType "BasicAlgebra.FactorPair" 1
    requireTree (stringField? selfType.children[0]! "bindRef" == sharedId)
      "projection self type must use the enclosing α"
    requireTree (type.children[2]!.kind == "bvar" &&
      stringField? type.children[2]! "bindRef" == sharedId)
      "projection result must use the enclosing α"
    requireTree (((nodes type).filter (·.kind == "binder")).size == 1)
      "inline projection repeats α or lost self"
  let standalone ← declarationToSnlEntry ``FactorPair.left
  requireTree (standalone.hypothesesTree?.get!.children.size == 2)
    "independent projection must extract α and self despite differing value BinderInfo"
  for getTree in [delabDeclaration ``FactorPair, delabDeclSignature ``FactorPair] do
    let tree ← getTree
    requireTree ({ tree with mdata := .null } == root) "structure APIs disagree"
  let signatureOnly ← collectExport2Snl #[``square, ``square_eq]
    { includeBodies := false, dependencies := .none }
  for entry in signatureOnly.entries do
    expectNode entry.declarationTree?.get! "variable" 2

end
end BasicAlgebra
