import Compiler.CompilationModel
import Verity.Core.Model.Denote

/-!
# Official Verity semantics smoke test

This file uses the concrete semantic path at the compiler revision pinned in
`lake-manifest.json` and `proofs/LOCKFILE.md`:

* `Compiler.CompilationModel` is the official deep EDSL/IR compiler;
* `Compiler.CompilationModel.Denote` is the canonical denotation exported by
  module `Verity.Core.Model.Denote`;
The denotation takes an oracle only for mapping-slot hashing and Keccak.  This
experiment uses neither operation; `unusedOracle` merely fills those structurally
required fields and is not an interpretation of any operation in the program.

The program below is deliberately nontrivial. It traverses a router-ordered
storage array, checks addition before performing it, updates each element in
place, and returns the sum. The overflow case reverts, while the mutant that
omits the check exhibits EVM word wraparound.
-/

namespace LidoSRv3.Audit.Verity.OfficialSemantics

open Compiler
open Compiler.CompilationModel
open Compiler.CompilationModel.Denote

def modulesField : Field :=
  { name := "modules", ty := .dynamicArray .uint256, «slot» := some 7 }

private def checkedFoldLoopBody : List Stmt :=
  [ .letVar "value" (.storageArrayElement "modules" (.localVar "i"))
  -- `.add` is wrapping in the official denotation.  Solidity 0.8
  -- checked addition is therefore expressed in source order as this
  -- guard followed by the arithmetic operation.
  , .require
      (.le (.localVar "value")
        (.sub (.literal Verity.Core.MAX_UINT256) (.localVar "total")))
      "Panic(0x11): arithmetic overflow"
  , .assignVar "total" (.add (.localVar "total") (.localVar "value"))
  , .setStorageArrayElement "modules" (.localVar "i")
      (.add (.localVar "value") (.literal 1)) ]

def checkedFold : FunctionSpec :=
  { name := "checkedFold"
    params := []
    returnType := some .uint256
    body :=
      [ .letVar "total" (.literal 0)
      , .forEach "i" (.storageArrayLength "modules") checkedFoldLoopBody
      , .return (.localVar "total") ]
    localObligations :=
      [ { name := "checkedFold.overflow-guard"
          obligation :=
            "Solidity 0.8 checked addition is the require-then-add sequence; no unguarded low-level mechanic."
          proofStatus := .proved } ] }

def checkedFoldSpec : CompilationModel :=
  { name := "OfficialSemanticsCheckedFold"
    fields := [modulesField]
    constructor := none
    functions := [checkedFold] }

def wrappingMutant : FunctionSpec :=
  { checkedFold with
    name := "wrappingMutant"
    body :=
      [ .letVar "total" (.literal 0)
      , .forEach "i" (.storageArrayLength "modules")
          [ .letVar "value" (.storageArrayElement "modules" (.localVar "i"))
          , .assignVar "total" (.add (.localVar "total") (.localVar "value")) ]
      , .return (.localVar "total") ] }

def initialWorld (values : List Verity.Core.Uint256) : Verity.ContractState :=
  { Verity.defaultState with
    storageArray := fun slot => if slot = 7 then values else [] }

def tx : DenoteTransaction :=
  { sender := 1, functionSelector := 0x7a110c01, args := [] }

private def unusedOracle : DenoteOracle :=
  { mappingSlot := fun _ _ => 0
    keccakMemorySlice := fun _ _ _ => 0 }

run_cmd do
  IO.println "OFFSEM-MARKER 01 defs"
  (← IO.getStdout).flush

def denote (fn : FunctionSpec) (values : List Verity.Core.Uint256) : DenoteResult :=
  denoteFunction unusedOracle { checkedFoldSpec with functions := [fn] }
    fn tx (initialWorld values)

run_cmd do
  IO.println "OFFSEM-MARKER 02 checkedFold_evaluates"
  (← IO.getStdout).flush

/-- A concrete official-denotation evaluation: ordered iteration reads
`[4, 7]`, performs both checked additions, and returns `11`. -/
theorem checkedFold_evaluates :
    (denote checkedFold [4, 7]).success = true ∧
      (denote checkedFold [4, 7]).returnValue = some 11 := by
  decide +kernel

private def observedModuleValues : StmtOutcome → Option (List Nat)
  | .continue state | .stop state | .return _ state =>
      some ((state.world.readArray 7).map (fun value => value.val))
  | .revert => none

run_cmd do
  IO.println "OFFSEM-MARKER 03 updates_in_order"
  (← IO.getStdout).flush

/-- The same run observes router order and the per-module updates, not only the
returned accumulator. -/
theorem checkedFold_updates_modules_in_order :
    observedModuleValues
      (execStmtList unusedOracle [modulesField]
        { world := initialWorld [4, 7], bindings := [], selector := tx.functionSelector }
        checkedFold.body) = some [5, 8] := by
  decide +kernel

run_cmd do
  IO.println "OFFSEM-MARKER 04 overflow_reverts"
  (← IO.getStdout).flush

/-- The same official denotation observes the Solidity-style overflow guard as
failure, rather than silently accepting wrapped arithmetic. -/
theorem checkedFold_overflow_reverts :
    (denote checkedFold [Verity.Core.MAX_UINT256, 1]).success = false := by
  decide +kernel

run_cmd do
  IO.println "OFFSEM-MARKER 05 wrappingMutant"
  (← IO.getStdout).flush

/-- Negative mutant: removing the guard changes the overflow observation to a
successful wrapped result. -/
theorem wrappingMutant_is_detected :
    (denote wrappingMutant [Verity.Core.MAX_UINT256, 1]).success = true ∧
      (denote wrappingMutant [Verity.Core.MAX_UINT256, 1]).returnValue = some 0 := by
  decide +kernel

private def exceptUnitDecEq : DecidableEq (Except String Unit) := fun x y =>
  match x, y with
  | .ok _, .ok _ => isTrue rfl
  | .error a, .error b =>
    if h : a = b then isTrue (h ▸ rfl)
    else isFalse (by intro heq; cases heq; exact h rfl)
  | .ok _, .error _ => isFalse (by intro h; cases h)
  | .error _, .ok _ => isFalse (by intro h; cases h)

local instance : DecidableEq (Except String Unit) := exceptUnitDecEq

private theorem fold_leaf {α : Type} (f : α → Stmt → StmtMetadata → α)
    (initial : α) (stmt : Stmt) (h : stmt.childLists = []) :
    stmt.fold f initial = f initial stmt stmt.directMetadata := by
  rw [Stmt.fold]
  simp [h]
  rw [h]
  rfl

private theorem fold_forEach {α : Type} (f : α → Stmt → StmtMetadata → α)
    (initial : α) (name : String) (count : Expr) (body : List Stmt) :
    (Stmt.forEach name count body).fold f initial =
      body.foldl (fun acc stmt => stmt.fold f acc)
        (f initial (.forEach name count body) (Stmt.forEach name count body).directMetadata) := by
  rw [Stmt.fold]
  simp only [Stmt.childLists, List.attach_cons, List.attach_nil, List.foldl_cons,
    List.foldl_nil, List.foldl_map]
  all_goals exact List.foldl_attach

private theorem templates_leaf (stmt : Stmt) (h : stmt.childLists = []) :
    collectTemplateIntrinsicsFromStmt stmt =
      stmt.directMetadata.subexpressions.flatMap collectTemplateIntrinsicsFromExpr := by
  rw [collectTemplateIntrinsicsFromStmt]
  simp [h]

private theorem templates_forEach (name : String) (count : Expr) (body : List Stmt) :
    collectTemplateIntrinsicsFromStmt (.forEach name count body) =
      collectTemplateIntrinsicsFromExpr count ++
        body.flatMap collectTemplateIntrinsicsFromStmt := by
  rw [collectTemplateIntrinsicsFromStmt]
  simp [Stmt.directMetadata, Stmt.childLists]

private theorem templates_literal (n : Nat) :
    collectTemplateIntrinsicsFromExpr (.literal n) = [] := by
  rw [collectTemplateIntrinsicsFromExpr]
  simp [Expr.children]
  all_goals (intro _ _ _ _ _ _ _ h; cases h)

private theorem templates_localVar (name : String) :
    collectTemplateIntrinsicsFromExpr (.localVar name) = [] := by
  rw [collectTemplateIntrinsicsFromExpr]
  simp [Expr.children]
  all_goals (intro _ _ _ _ _ _ _ h; cases h)

private theorem templates_storageArrayLength (name : String) :
    collectTemplateIntrinsicsFromExpr (.storageArrayLength name) = [] := by
  rw [collectTemplateIntrinsicsFromExpr]
  simp [Expr.children]
  all_goals (intro _ _ _ _ _ _ _ h; cases h)

private theorem templates_storageArrayElement (name : String) (index : Expr) :
    collectTemplateIntrinsicsFromExpr (.storageArrayElement name index) = collectTemplateIntrinsicsFromExpr index := by
  rw [collectTemplateIntrinsicsFromExpr]
  simp [Expr.children]
  all_goals (intro _ _ _ _ _ _ _ h; cases h)

private theorem templates_add (a b : Expr) :
    collectTemplateIntrinsicsFromExpr (.add a b) = collectTemplateIntrinsicsFromExpr a ++ collectTemplateIntrinsicsFromExpr b := by
  rw [collectTemplateIntrinsicsFromExpr]
  simp [Expr.children]
  all_goals (intro _ _ _ _ _ _ _ h; cases h)

private theorem templates_sub (a b : Expr) :
    collectTemplateIntrinsicsFromExpr (.sub a b) = collectTemplateIntrinsicsFromExpr a ++ collectTemplateIntrinsicsFromExpr b := by
  rw [collectTemplateIntrinsicsFromExpr]
  simp [Expr.children]
  all_goals (intro _ _ _ _ _ _ _ h; cases h)

private theorem templates_le (a b : Expr) :
    collectTemplateIntrinsicsFromExpr (.le a b) = collectTemplateIntrinsicsFromExpr a ++ collectTemplateIntrinsicsFromExpr b := by
  rw [collectTemplateIntrinsicsFromExpr]
  simp [Expr.children]
  all_goals (intro _ _ _ _ _ _ _ h; cases h)

private theorem exprAny_literal (p : Expr → Bool) (n : Nat) :
    Expr.anyDeep p (.literal n) = (p (.literal n) || false) := by
  rw [Expr.anyDeep]
  simp [Expr.children, Bool.or_assoc]

private theorem exprAny_localVar (p : Expr → Bool) (name : String) :
    Expr.anyDeep p (.localVar name) = (p (.localVar name) || false) := by
  rw [Expr.anyDeep]
  simp [Expr.children, Bool.or_assoc]

private theorem exprAny_storageArrayLength (p : Expr → Bool) (name : String) :
    Expr.anyDeep p (.storageArrayLength name) = (p (.storageArrayLength name) || false) := by
  rw [Expr.anyDeep]
  simp [Expr.children, Bool.or_assoc]

private theorem exprAny_storageArrayElement (p : Expr → Bool) (name : String) (index : Expr) :
    Expr.anyDeep p (.storageArrayElement name index) = (p (.storageArrayElement name index) || index.anyDeep p) := by
  rw [Expr.anyDeep]
  simp [Expr.children, Bool.or_assoc]

private theorem exprAny_add (p : Expr → Bool) (a b : Expr) :
    Expr.anyDeep p (.add a b) = (p (.add a b) || (a.anyDeep p || b.anyDeep p)) := by
  rw [Expr.anyDeep]
  simp [Expr.children, Bool.or_assoc]

private theorem exprAny_sub (p : Expr → Bool) (a b : Expr) :
    Expr.anyDeep p (.sub a b) = (p (.sub a b) || (a.anyDeep p || b.anyDeep p)) := by
  rw [Expr.anyDeep]
  simp [Expr.children, Bool.or_assoc]

private theorem exprAny_le (p : Expr → Bool) (a b : Expr) :
    Expr.anyDeep p (.le a b) = (p (.le a b) || (a.anyDeep p || b.anyDeep p)) := by
  rw [Expr.anyDeep]
  simp [Expr.children, Bool.or_assoc]

private theorem stmtAny_leaf (p : Stmt → Bool) (stmt : Stmt)
    (h : stmt.childLists = []) : stmt.anyDeep p = p stmt := by
  rw [Stmt.anyDeep]
  simp [h]

private theorem stmtAny_forEach (p : Stmt → Bool)
    (name : String) (count : Expr) (body : List Stmt) :
    (Stmt.forEach name count body).anyDeep p =
      (p (.forEach name count body) || body.any (Stmt.anyDeep p)) := by
  rw [Stmt.anyDeep]
  simp [Stmt.childLists]

private theorem stmtAny_letVar (p : Stmt → Bool) (name : String) (value : Expr) :
    Stmt.anyDeep p (.letVar name value) = p (.letVar name value) := by
  apply stmtAny_leaf
  rfl

private theorem fold_letVar {α : Type} (f : α → Stmt → StmtMetadata → α)
    (initial : α) (name : String) (value : Expr) :
    Stmt.fold f initial (.letVar name value) = f initial (.letVar name value) (Stmt.directMetadata (.letVar name value)) := by
  apply fold_leaf
  rfl

private theorem stmtAny_assignVar (p : Stmt → Bool) (name : String) (value : Expr) :
    Stmt.anyDeep p (.assignVar name value) = p (.assignVar name value) := by
  apply stmtAny_leaf
  rfl

private theorem fold_assignVar {α : Type} (f : α → Stmt → StmtMetadata → α)
    (initial : α) (name : String) (value : Expr) :
    Stmt.fold f initial (.assignVar name value) = f initial (.assignVar name value) (Stmt.directMetadata (.assignVar name value)) := by
  apply fold_leaf
  rfl

private theorem stmtAny_require (p : Stmt → Bool) (condition : Expr) (message : String) :
    Stmt.anyDeep p (.require condition message) = p (.require condition message) := by
  apply stmtAny_leaf
  rfl

private theorem fold_require {α : Type} (f : α → Stmt → StmtMetadata → α)
    (initial : α) (condition : Expr) (message : String) :
    Stmt.fold f initial (.require condition message) = f initial (.require condition message) (Stmt.directMetadata (.require condition message)) := by
  apply fold_leaf
  rfl

private theorem stmtAny_return (p : Stmt → Bool) (value : Expr) :
    Stmt.anyDeep p (.return value) = p (.return value) := by
  apply stmtAny_leaf
  rfl

private theorem fold_return {α : Type} (f : α → Stmt → StmtMetadata → α)
    (initial : α) (value : Expr) :
    Stmt.fold f initial (.return value) = f initial (.return value) (Stmt.directMetadata (.return value)) := by
  apply fold_leaf
  rfl

private theorem stmtAny_setStorageArrayElement (p : Stmt → Bool) (name : String) (index value : Expr) :
    Stmt.anyDeep p (.setStorageArrayElement name index value) = p (.setStorageArrayElement name index value) := by
  apply stmtAny_leaf
  rfl

private theorem fold_setStorageArrayElement {α : Type} (f : α → Stmt → StmtMetadata → α)
    (initial : α) (name : String) (index value : Expr) :
    Stmt.fold f initial (.setStorageArrayElement name index value) = f initial (.setStorageArrayElement name index value) (Stmt.directMetadata (.setStorageArrayElement name index value)) := by
  apply fold_leaf
  rfl

private def emptyUnsafeYulAcc (acc : Bool) (s : Stmt) (_ : StmtMetadata) : Bool :=
  match s with
  | Stmt.unsafeYul fragment => acc || fragment.obligations.isEmpty
  | _ => acc

private theorem fold_emptyUnsafeYul_letVar (name : String) (value : Expr) :
    Stmt.fold emptyUnsafeYulAcc false (.letVar name value) = false := by
  rw [fold_letVar]; rfl

private theorem fold_emptyUnsafeYul_assignVar (name : String) (value : Expr) :
    Stmt.fold emptyUnsafeYulAcc false (.assignVar name value) = false := by
  rw [fold_assignVar]; rfl

private theorem fold_emptyUnsafeYul_require (condition : Expr) (message : String) :
    Stmt.fold emptyUnsafeYulAcc false (.require condition message) = false := by
  rw [fold_require]; rfl

private theorem fold_emptyUnsafeYul_return (value : Expr) :
    Stmt.fold emptyUnsafeYulAcc false (.return value) = false := by
  rw [fold_return]; rfl

private theorem fold_emptyUnsafeYul_setStorageArrayElement (name : String) (index value : Expr) :
    Stmt.fold emptyUnsafeYulAcc false (.setStorageArrayElement name index value) = false := by
  rw [fold_setStorageArrayElement]; rfl

private theorem fold_emptyUnsafeYul_forEachBody :
    checkedFoldLoopBody.foldl (fun acc stmt => stmt.fold emptyUnsafeYulAcc acc) false = false := by
  unfold checkedFoldLoopBody
  simp [List.foldl_cons, List.foldl_nil, fold_letVar, fold_require, fold_assignVar,
    fold_setStorageArrayElement, emptyUnsafeYulAcc]

private theorem fold_emptyUnsafeYul_forEach :
    Stmt.fold emptyUnsafeYulAcc false
      (.forEach "i" (.storageArrayLength "modules") checkedFoldLoopBody) = false := by
  rw [fold_forEach]
  change checkedFoldLoopBody.foldl (fun acc stmt => stmt.fold emptyUnsafeYulAcc acc) false = false
  exact fold_emptyUnsafeYul_forEachBody

private theorem checkedFold_no_empty_unsafeYul :
    (checkedFold.body.any fun stmt =>
      stmt.fold
        (fun acc s _ =>
          match s with
          | Stmt.unsafeYul fragment => acc || fragment.obligations.isEmpty
          | _ => acc)
        false) = false := by
  have h : (fun acc s _ =>
      match s with
      | Stmt.unsafeYul fragment => acc || fragment.obligations.isEmpty
      | _ => acc) = emptyUnsafeYulAcc := rfl
  simp only [h]
  unfold checkedFold
  rw [List.any_cons, fold_emptyUnsafeYul_letVar, Bool.false_or]
  rw [List.any_cons, fold_emptyUnsafeYul_forEach, Bool.false_or]
  rw [List.any_cons, fold_emptyUnsafeYul_return, Bool.false_or]
  rfl

-- `Stmt.fold` is already `[irreducible]` (well-founded recursion), so only the
-- non-recursive wrappers need the local marker.
attribute [local irreducible] Stmt.foldList collectUnguardedUnsafeBoundaryMechanicsFromStmts

attribute [local cbv_eval] fold_forEach exprAny_literal exprAny_localVar exprAny_storageArrayLength exprAny_storageArrayElement exprAny_add exprAny_sub exprAny_le stmtAny_forEach stmtAny_letVar fold_letVar stmtAny_assignVar fold_assignVar stmtAny_require fold_require stmtAny_return fold_return stmtAny_setStorageArrayElement fold_setStorageArrayElement

private theorem stmtCheck_letVar (check : Stmt → Except String Unit) (name : String) (value : Expr) :
    Stmt.forDeepM check (.letVar name value) = check (.letVar name value) := by
  rw [Stmt.forDeepM]
  simp [Stmt.childLists]

private theorem stmtCheck_assignVar (check : Stmt → Except String Unit) (name : String) (value : Expr) :
    Stmt.forDeepM check (.assignVar name value) = check (.assignVar name value) := by
  rw [Stmt.forDeepM]
  simp [Stmt.childLists]

private theorem stmtCheck_require (check : Stmt → Except String Unit) (condition : Expr) (message : String) :
    Stmt.forDeepM check (.require condition message) = check (.require condition message) := by
  rw [Stmt.forDeepM]
  simp [Stmt.childLists]

private theorem stmtCheck_return (check : Stmt → Except String Unit) (value : Expr) :
    Stmt.forDeepM check (.return value) = check (.return value) := by
  rw [Stmt.forDeepM]
  simp [Stmt.childLists]

private theorem stmtCheck_setStorageArrayElement (check : Stmt → Except String Unit) (name : String) (index value : Expr) :
    Stmt.forDeepM check (.setStorageArrayElement name index value) = check (.setStorageArrayElement name index value) := by
  rw [Stmt.forDeepM]
  simp [Stmt.childLists]

private theorem listForMAttach {α : Type} (xs : List α)
    (f : α → Except String Unit) :
    forM xs.attach (fun x => f x.val) = forM xs f := by
  induction xs with
  | nil => rfl
  | cons x xs ih => simp [List.attach_cons, List.forM_map, ih]

private theorem exceptForM_nil {α : Type} (f : α → Except String Unit) :
    ForM.forM ([] : List α) f = .ok () := rfl

private theorem exceptForM_cons {α : Type} (a : α) (as : List α)
    (f : α → Except String Unit) :
    ForM.forM (a :: as) f = Bind.bind (f a) (fun _ => ForM.forM as f) := rfl

private theorem exceptBind_ok (k : Except String Unit) :
    Bind.bind (Except.ok () : Except String Unit) (fun _ => k) = k := rfl

private theorem exceptBind_okVal {α β : Type} (v : α) (k : α → Except String β) :
    Bind.bind (Except.ok v : Except String α) k = k v := rfl

private theorem compileConstructor_none :
    compileConstructor [modulesField] [] [] [] none = .ok [] := rfl

private theorem pickUnique_fallback :
    pickUniqueFunctionByName "fallback" [checkedFold] = .ok none := rfl

private theorem pickUnique_receive :
    pickUniqueFunctionByName "receive" [checkedFold] = .ok none := rfl

private theorem returnShapeNode_forEach (name : String) (count : Expr) (body : List Stmt) :
    validateReturnShapesNode "checkedFold" [] [.uint256] false (.forEach name count body) =
      .ok () := rfl

private theorem paramRefNode_forEach (name : String) (count : Expr) (body : List Stmt) :
    validateStmtParamReferencesNode "checkedFold" [] (.forEach name count body) = .ok () := rfl

private theorem stmtCheck_forEach (check : Stmt → Except String Unit)
    (name : String) (count : Expr) (body : List Stmt) :
    Stmt.forDeepM check (.forEach name count body) =
      (do check (.forEach name count body); body.forM (Stmt.forDeepM check)) := by
  rw [Stmt.forDeepM]
  simp [Stmt.childLists]
  rw [listForMAttach]

private theorem exprCheck_literal (check : Expr → Except String Unit) (n : Nat) :
    Expr.forDeepM check (.literal n) = check (.literal n) := by
  rw [Expr.forDeepM]
  simp [Expr.children]

private theorem exprCheck_localVar (check : Expr → Except String Unit) (name : String) :
    Expr.forDeepM check (.localVar name) = check (.localVar name) := by
  rw [Expr.forDeepM]
  simp [Expr.children]

private theorem exprCheck_storageArrayLength (check : Expr → Except String Unit) (name : String) :
    Expr.forDeepM check (.storageArrayLength name) = check (.storageArrayLength name) := by
  rw [Expr.forDeepM]
  simp [Expr.children]

private theorem exprCheck_storageArrayElement (check : Expr → Except String Unit) (name : String) (index : Expr) :
    Expr.forDeepM check (.storageArrayElement name index) = (do check (.storageArrayElement name index); Expr.forDeepM check index) := by
  rw [Expr.forDeepM]
  simp [Expr.children]

private theorem exprCheck_add (check : Expr → Except String Unit) (a b : Expr) :
    Expr.forDeepM check (.add a b) = (do check (.add a b); Expr.forDeepM check a; Expr.forDeepM check b) := by
  rw [Expr.forDeepM]
  simp [Expr.children]

private theorem exprCheck_sub (check : Expr → Except String Unit) (a b : Expr) :
    Expr.forDeepM check (.sub a b) = (do check (.sub a b); Expr.forDeepM check a; Expr.forDeepM check b) := by
  rw [Expr.forDeepM]
  simp [Expr.children]

private theorem exprCheck_le (check : Expr → Except String Unit) (a b : Expr) :
    Expr.forDeepM check (.le a b) = (do check (.le a b); Expr.forDeepM check a; Expr.forDeepM check b) := by
  rw [Expr.forDeepM]
  simp [Expr.children]

private theorem exprPostCheck_literal (check : Expr → Except String Unit) (n : Nat) :
    Expr.forDeepPostM check (.literal n) = check (.literal n) := by
  rw [Expr.forDeepPostM]
  simp [Expr.children]

private theorem exprPostCheck_localVar (check : Expr → Except String Unit) (name : String) :
    Expr.forDeepPostM check (.localVar name) = check (.localVar name) := by
  rw [Expr.forDeepPostM]
  simp [Expr.children]

private theorem exprPostCheck_storageArrayLength (check : Expr → Except String Unit) (name : String) :
    Expr.forDeepPostM check (.storageArrayLength name) = check (.storageArrayLength name) := by
  rw [Expr.forDeepPostM]
  simp [Expr.children]

private theorem exprPostCheck_storageArrayElement (check : Expr → Except String Unit) (name : String) (index : Expr) :
    Expr.forDeepPostM check (.storageArrayElement name index) = (do Expr.forDeepPostM check index; check (.storageArrayElement name index)) := by
  rw [Expr.forDeepPostM]
  simp [Expr.children]

private theorem exprPostCheck_add (check : Expr → Except String Unit) (a b : Expr) :
    Expr.forDeepPostM check (.add a b) = (do Expr.forDeepPostM check a; Expr.forDeepPostM check b; check (.add a b)) := by
  rw [Expr.forDeepPostM]
  simp [Expr.children]

private theorem exprPostCheck_sub (check : Expr → Except String Unit) (a b : Expr) :
    Expr.forDeepPostM check (.sub a b) = (do Expr.forDeepPostM check a; Expr.forDeepPostM check b; check (.sub a b)) := by
  rw [Expr.forDeepPostM]
  simp [Expr.children]

private theorem exprPostCheck_le (check : Expr → Except String Unit) (a b : Expr) :
    Expr.forDeepPostM check (.le a b) = (do Expr.forDeepPostM check a; Expr.forDeepPostM check b; check (.le a b)) := by
  rw [Expr.forDeepPostM]
  simp [Expr.children]

attribute [local cbv_eval] stmtCheck_letVar stmtCheck_assignVar stmtCheck_require stmtCheck_return stmtCheck_setStorageArrayElement stmtCheck_forEach exprCheck_literal exprCheck_localVar exprCheck_storageArrayLength exprCheck_storageArrayElement exprCheck_add exprCheck_sub exprCheck_le exprPostCheck_literal exprPostCheck_localVar exprPostCheck_storageArrayLength exprPostCheck_storageArrayElement exprPostCheck_add exprPostCheck_sub exprPostCheck_le

private theorem no_external_assumptions (spec : CompilationModel)
    (h : spec.externals = []) : collectUsedExternalAssumptions spec = [] := by
  unfold collectUsedExternalAssumptions
  run_tac do
    let env ← Lean.getEnv
    for suffix in ["collectUsedExternalAssumptionsFromStmts", "dedupExternalFunctions"] do
      let candidates := env.constants.toList.filter fun (name, _) =>
        name.toString.startsWith "_private.Compiler.CompilationModel.TrustSurface." &&
          name.toString.endsWith ("." ++ suffix)
      match candidates with
      | [(name, _)] =>
          let id := Lean.mkIdent name
          Lean.Elab.Tactic.evalTactic (← `(tactic| unfold $id:ident))
      | _ => throwError "expected one pinned TrustSurface helper: {suffix}"
  simp [h]

private theorem empty_slot_alias_ranges_valid :
    firstInvalidSlotAliasRange ([] : List SlotAliasRange) = none := by
  simp [firstInvalidSlotAliasRange]

private theorem empty_slot_alias_sources_disjoint :
    firstSlotAliasSourceOverlap ([] : List SlotAliasRange) = none := by
  unfold firstSlotAliasSourceOverlap
  rfl

private theorem checkedFold_no_unsupported_internal_dynamic :
    firstUnsupportedInternalDynamicParam [checkedFold] = none := by
  decide +kernel

private theorem checkedFold_functionReturns :
    functionReturns checkedFold = .ok [.uint256] := rfl

attribute [local cbv_eval] empty_slot_alias_ranges_valid empty_slot_alias_sources_disjoint
  checkedFold_no_unsupported_internal_dynamic checkedFold_functionReturns

private theorem returnShape_letVar (name : String) (value : Expr) :
    validateReturnShapesInStmt "checkedFold" [] [.uint256] false (.letVar name value) = .ok () := by
  unfold validateReturnShapesInStmt Stmt.checkRec
  rw [stmtCheck_letVar]
  simp [validateReturnShapesNode, Pure.pure, Except.pure]

private theorem returnShape_assignVar (name : String) (value : Expr) :
    validateReturnShapesInStmt "checkedFold" [] [.uint256] false (.assignVar name value) = .ok () := by
  unfold validateReturnShapesInStmt Stmt.checkRec
  rw [stmtCheck_assignVar]
  simp [validateReturnShapesNode, Pure.pure, Except.pure]

private theorem returnShape_require (condition : Expr) (message : String) :
    validateReturnShapesInStmt "checkedFold" [] [.uint256] false (.require condition message) = .ok () := by
  unfold validateReturnShapesInStmt Stmt.checkRec
  rw [stmtCheck_require]
  simp [validateReturnShapesNode, Pure.pure, Except.pure]

private theorem returnShape_setStorageArrayElement (name : String) (index value : Expr) :
    validateReturnShapesInStmt "checkedFold" [] [.uint256] false
      (.setStorageArrayElement name index value) = .ok () := by
  unfold validateReturnShapesInStmt Stmt.checkRec
  rw [stmtCheck_setStorageArrayElement]
  simp [validateReturnShapesNode, Pure.pure, Except.pure]

private theorem returnShape_return (value : Expr) :
    validateReturnShapesInStmt "checkedFold" [] [.uint256] false (.return value) = .ok () := by
  unfold validateReturnShapesInStmt Stmt.checkRec
  rw [stmtCheck_return]
  simp [validateReturnShapesNode, Pure.pure, Except.pure]

private theorem returnShape_forEachBody :
    ForM.forM checkedFoldLoopBody
      (validateReturnShapesInStmt "checkedFold" [] [.uint256] false) = .ok () := by
  unfold checkedFoldLoopBody
  rw [exceptForM_cons, returnShape_letVar, exceptBind_ok]
  rw [exceptForM_cons, returnShape_require, exceptBind_ok]
  rw [exceptForM_cons, returnShape_assignVar, exceptBind_ok]
  rw [exceptForM_cons, returnShape_setStorageArrayElement, exceptBind_ok]
  rw [exceptForM_nil]

private theorem returnShape_forEach :
    validateReturnShapesInStmt "checkedFold" [] [.uint256] false
      (.forEach "i" (.storageArrayLength "modules") checkedFoldLoopBody) = .ok () := by
  unfold validateReturnShapesInStmt Stmt.checkRec
  rw [stmtCheck_forEach, returnShapeNode_forEach, exceptBind_ok]
  have h :
      Stmt.forDeepM (validateReturnShapesNode "checkedFold" [] [.uint256] false) =
        validateReturnShapesInStmt "checkedFold" [] [.uint256] false := rfl
  rw [h]
  exact returnShape_forEachBody

private theorem checkedFold_return_shapes :
    ForM.forM checkedFold.body
      (validateReturnShapesInStmt "checkedFold" [] [.uint256] false) = .ok () := by
  unfold checkedFold
  rw [exceptForM_cons, returnShape_letVar, exceptBind_ok]
  rw [exceptForM_cons, returnShape_forEach, exceptBind_ok]
  rw [exceptForM_cons, returnShape_return, exceptBind_ok]
  rw [exceptForM_nil]

private theorem paramRef_letVar (name : String) (value : Expr) :
    validateStmtParamReferences "checkedFold" [] (.letVar name value) = .ok () := by
  unfold validateStmtParamReferences Stmt.checkRec
  rw [stmtCheck_letVar]
  simp [validateStmtParamReferencesNode, Pure.pure, Except.pure]

private theorem paramRef_assignVar (name : String) (value : Expr) :
    validateStmtParamReferences "checkedFold" [] (.assignVar name value) = .ok () := by
  unfold validateStmtParamReferences Stmt.checkRec
  rw [stmtCheck_assignVar]
  simp [validateStmtParamReferencesNode, Pure.pure, Except.pure]

private theorem paramRef_require (condition : Expr) (message : String) :
    validateStmtParamReferences "checkedFold" [] (.require condition message) = .ok () := by
  unfold validateStmtParamReferences Stmt.checkRec
  rw [stmtCheck_require]
  simp [validateStmtParamReferencesNode, Pure.pure, Except.pure]

private theorem paramRef_setStorageArrayElement (name : String) (index value : Expr) :
    validateStmtParamReferences "checkedFold" []
      (.setStorageArrayElement name index value) = .ok () := by
  unfold validateStmtParamReferences Stmt.checkRec
  rw [stmtCheck_setStorageArrayElement]
  simp [validateStmtParamReferencesNode, Pure.pure, Except.pure]

private theorem paramRef_return (value : Expr) :
    validateStmtParamReferences "checkedFold" [] (.return value) = .ok () := by
  unfold validateStmtParamReferences Stmt.checkRec
  rw [stmtCheck_return]
  simp [validateStmtParamReferencesNode, Pure.pure, Except.pure]

private theorem paramRef_forEachBody :
    ForM.forM checkedFoldLoopBody (validateStmtParamReferences "checkedFold" []) = .ok () := by
  unfold checkedFoldLoopBody
  rw [exceptForM_cons, paramRef_letVar, exceptBind_ok]
  rw [exceptForM_cons, paramRef_require, exceptBind_ok]
  rw [exceptForM_cons, paramRef_assignVar, exceptBind_ok]
  rw [exceptForM_cons, paramRef_setStorageArrayElement, exceptBind_ok]
  rw [exceptForM_nil]

private theorem paramRef_forEach :
    validateStmtParamReferences "checkedFold" []
      (.forEach "i" (.storageArrayLength "modules") checkedFoldLoopBody) = .ok () := by
  unfold validateStmtParamReferences Stmt.checkRec
  rw [stmtCheck_forEach, paramRefNode_forEach, exceptBind_ok]
  have h :
      Stmt.forDeepM (validateStmtParamReferencesNode "checkedFold" []) =
        validateStmtParamReferences "checkedFold" [] := rfl
  rw [h]
  exact paramRef_forEachBody

private theorem checkedFold_param_refs :
    ForM.forM checkedFold.body (validateStmtParamReferences "checkedFold" []) = .ok () := by
  unfold checkedFold
  rw [exceptForM_cons, paramRef_letVar, exceptBind_ok]
  rw [exceptForM_cons, paramRef_forEach, exceptBind_ok]
  rw [exceptForM_cons, paramRef_return, exceptBind_ok]
  rw [exceptForM_nil]

private theorem checkedFold_no_unsafe_logical :
    checkedFold.body.any stmtContainsUnsafeLogicalCallLike = false := by
  decide +kernel

run_cmd do
  IO.println "OFFSEM-MARKER 16 validates"
  (← IO.getStdout).flush

/-- `Stmt.fold` is `[irreducible]` (well-founded recursion) and `Stmt.foldList`
is marked locally irreducible above, so the hanging collector stays opaque.
The documented obligation plus the unused-Yul constructor lemma skip it. -/
theorem checkedFold_validates :
    validateFunctionSpec checkedFold = .ok () := by
  have documented : checkedFold.localObligations.isEmpty = false := rfl
  have noEmptyYul := checkedFold_no_empty_unsafeYul
  simp only [validateFunctionSpec, documented, noEmptyYul, Bool.and_false, Bool.false_and]
  decide +kernel

run_cmd do
  IO.println "OFFSEM-MARKER 17 inputs-validate"
  (← IO.getStdout).flush

set_option maxRecDepth 16384 in
set_option maxHeartbeats 4000000 in
theorem checkedFold_inputs_validate :
    validateCompileInputs checkedFoldSpec [tx.functionSelector] = .ok () := by
  unfold validateCompileInputs
  run_tac do
    let env ← Lean.getEnv
    let candidates := env.constants.toList.filter fun (name, _) =>
      name.toString.endsWith ".validateCompileInputsBeforeFieldWriteConflict"
    match candidates with
    | [(name, _)] =>
        let id := Lean.mkIdent name
        Lean.Elab.Tactic.evalTactic (← `(tactic| unfold $id:ident))
    | _ => throwError "expected one pinned compiler precheck definition"
  have hi : checkedFold.isInternal = false := rfl
  have hn : checkedFold.name = "checkedFold" := rfl
  simp [checkedFoldSpec, checkedFold_validates, hi, hn, List.filter_cons,
    Bind.bind, Except.bind, Pure.pure, Except.pure]
  all_goals decide +kernel

run_cmd do
  IO.println "OFFSEM-MARKER 18 compiles-to-ir"
  (← IO.getStdout).flush

set_option maxRecDepth 16384 in
set_option maxHeartbeats 4000000 in
/-- The same EDSL program genuinely enters Verity's official compiler and
produces its IR; this theorem fixes the concrete compiler entrypoint and rules
out a source-only local interpreter experiment. -/
theorem checkedFold_compiles_to_official_ir :
    (CompilationModel.compile checkedFoldSpec [tx.functionSelector]).isOk = true := by
  have functionValid := checkedFold_validates
  have validated := checkedFold_inputs_validate
  have hr : functionReturns checkedFold = .ok [.uint256] := checkedFold_functionReturns
  have fieldSlot : findFieldWithResolvedSlot [modulesField] "modules" = some (modulesField, 7) := by
    rfl
  have fieldType : modulesField.ty = .dynamicArray .uint256 := rfl
  have bodyValid :
      (compileStmtListWithFork [modulesField] [] [] .calldata [] false [] [] .cancun checkedFold.body []).isOk = true := by
    -- `checkedFoldLoopBody` is a separate `private def`; without unfolding it the
    -- `forEach` body stays folded and the compiler equations cannot fire on it.
    simp [checkedFold, checkedFoldLoopBody, fieldSlot, fieldType,
      compileStmtListWithFork, compileStmtWithFork,
      compileExprWithInternals, compileRequireFailCondWithInternals,
      compileSetStorageArrayElement, validateDynamicArrayField,
      Bind.bind, Except.bind, Pure.pure, Except.pure, Except.isOk, Except.toBool]
  have hi : checkedFold.isInternal = false := rfl
  have hn : checkedFold.name = "checkedFold" := rfl
  have hs : isInteropEntrypointName "checkedFold" = false := by decide +kernel
  have hf : CompilationModel.applySlotAliasRanges [modulesField] [] = [modulesField] := rfl
  have hp : checkedFold.params = [] := rfl
  have hl : checkedFold.nonReentrantLock = none := rfl
  have hctor := compileConstructor_none
  have hfb := pickUnique_fallback
  have hrecv := pickUnique_receive
  have templates : (templateIntrinsicItems checkedFoldSpec).isEmpty = true := by
    -- Same reason as `bodyValid`: without `checkedFoldLoopBody` the `forEach`
    -- body stays folded and the collector lemmas cannot fire on it.
    simp [templateIntrinsicItems, checkedFoldSpec, checkedFold, checkedFoldLoopBody,
      collectTemplateIntrinsicsFromStmts, templates_leaf, templates_forEach,
      templates_literal, templates_localVar, templates_storageArrayLength,
      templates_storageArrayElement, templates_add, templates_sub, templates_le,
      Stmt.directMetadata, Stmt.childLists]
  have ht := List.nil_of_isEmpty templates
  unfold CompilationModel.compile
  rw [validated]
  simp only [bind, Except.bind]
  cases hb : compileStmtListWithFork [modulesField] [] [] .calldata [] false [] [] .cancun checkedFold.body []
  · simp [hb, Except.isOk, Except.toBool] at bodyValid
  · unfold compileValidatedCore
    rw [ht]
    simp [checkedFoldSpec, compileGuardedFunctionSpec, compileFunctionSpec,
      functionValid, hi, hn, hs, hf, hp, hl, hr, hb, hctor, hfb, hrecv,
      attachNonReentrantGuard, compileConstructor, pickUniqueFunctionByName,
      exceptBind_okVal, exceptBind_ok,
      List.filter_cons, List.mapM_cons, List.map_cons, List.map_nil,
      Bind.bind, Except.bind, Pure.pure, Except.pure, Except.isOk, Except.toBool]

end LidoSRv3.Audit.Verity.OfficialSemantics
