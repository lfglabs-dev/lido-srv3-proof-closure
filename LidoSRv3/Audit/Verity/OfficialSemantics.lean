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

def checkedFold : FunctionSpec :=
  { name := "checkedFold"
    params := []
    returnType := some .uint256
    body :=
      [ .letVar "total" (.literal 0)
      , .forEach "i" (.storageArrayLength "modules")
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
      , .return (.localVar "total") ] }

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

def denote (fn : FunctionSpec) (values : List Verity.Core.Uint256) : DenoteResult :=
  denoteFunction unusedOracle { checkedFoldSpec with functions := [fn] }
    fn tx (initialWorld values)

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

/-- The same run observes router order and the per-module updates, not only the
returned accumulator. -/
theorem checkedFold_updates_modules_in_order :
    observedModuleValues
      (execStmtList unusedOracle [modulesField]
        { world := initialWorld [4, 7], bindings := [], selector := tx.functionSelector }
        checkedFold.body) = some [5, 8] := by
  decide +kernel

/-- The same official denotation observes the Solidity-style overflow guard as
failure, rather than silently accepting wrapped arithmetic. -/
theorem checkedFold_overflow_reverts :
    (denote checkedFold [Verity.Core.MAX_UINT256, 1]).success = false := by
  decide +kernel

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

attribute [local cbv_eval] fold_forEach exprAny_literal exprAny_localVar exprAny_storageArrayLength exprAny_storageArrayElement exprAny_add exprAny_sub exprAny_le stmtAny_forEach stmtAny_letVar fold_letVar stmtAny_assignVar fold_assignVar stmtAny_require fold_require stmtAny_return fold_return stmtAny_setStorageArrayElement fold_setStorageArrayElement

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

set_option maxRecDepth 16384 in
set_option maxHeartbeats 4000000 in
set_option pp.maxSteps 200 in
/-- The same EDSL program genuinely enters Verity's official compiler and
produces its IR; this theorem fixes the concrete compiler entrypoint and rules
out a source-only local interpreter experiment. -/
theorem checkedFold_compiles_to_official_ir :
    (CompilationModel.compile checkedFoldSpec [tx.functionSelector]).isOk = true := by
  have mechanics : collectUnguardedUnsafeBoundaryMechanicsFromStmts checkedFold.body = [] := by
    simp only [checkedFold, collectUnguardedUnsafeBoundaryMechanicsFromStmts]
    run_tac do
      let env ← Lean.getEnv
      for suffix in ["collectUnguardedLowLevelMechanicsFromStmts",
          "collectUnguardedLowLevelStmtMechanics", "collectLowLevelExprMechanics",
          "dedupPreserve"] do
        let candidates := env.constants.toList.filter fun (name, _) =>
          name.toString.startsWith "_private.Compiler.CompilationModel.TrustSurface." &&
            name.toString.endsWith ("." ++ suffix)
        match candidates with
        | [(name, _)] =>
            unless (← Lean.Elab.Tactic.getGoals).isEmpty do
              let id := Lean.mkIdent name
              Lean.Elab.Tactic.evalTactic (← `(tactic| simp [$id:ident]))
        | _ => throwError "expected one pinned TrustSurface helper: {suffix}"
  simp only [checkedFold] at mechanics
  have functionValid : validateFunctionSpec checkedFold = .ok () := by
    simp [validateFunctionSpec, mechanics, checkedFold, fold_leaf, fold_forEach,
      Stmt.foldList, Stmt.directMetadata, Stmt.childLists,
      stmtContainsUnsafeLogicalCallLike, stmtAny_leaf, stmtAny_forEach,
      exprContainsUnsafeLogicalCallLike, exprAny_literal, exprAny_localVar,
      exprAny_storageArrayLength, exprAny_storageArrayElement, exprAny_add,
      exprAny_sub, exprAny_le, exprIsUnsafeLogicalNode,
      Bind.bind, Except.bind, Pure.pure, Except.pure]
    run_tac do
      let env ← Lean.getEnv
      for suffix in ["validateAdtPayloadParamNameCollisions", "adtPayloadParamNames"] do
        let candidates := env.constants.toList.filter fun (name, _) =>
          name.toString.startsWith "_private.Compiler.CompilationModel.Validation." &&
            name.toString.endsWith ("." ++ suffix)
        match candidates with
        | [(name, _)] =>
            let id := Lean.mkIdent name
            Lean.Elab.Tactic.evalTactic (← `(tactic| simp [$id:ident]))
        | _ => throwError "expected one pinned Validation helper: {suffix}"
    all_goals (trace_state; decide_cbv)
  have identifiers : validateIdentifierShapes checkedFoldSpec = .ok () := by
    simp [validateIdentifierShapes, checkedFoldSpec]
    run_tac do
      let env ← Lean.getEnv
      for suffix in ["validateReservedCompilerIdentifiers", "validateFieldIdentifiers",
          "validateFunctionIdentifierList", "validateFunctionYulIdentifiers",
          "validateContractIdentifiers"] do
        let candidates := env.constants.toList.filter fun (name, _) =>
          name.toString.startsWith "_private.Compiler.CompilationModel.ValidationCalls." &&
            name.toString.endsWith ("." ++ suffix)
        match candidates with
        | [(name, _)] =>
            unless (← Lean.Elab.Tactic.getGoals).isEmpty do
              let id := Lean.mkIdent name
              Lean.Elab.Tactic.evalTactic (← `(tactic| simp [$id:ident,
                validateFunctionIdentifiers, checkedFold, modulesField,
                collectStmtListBindNames, collectStmtBindNames,
                collectStmtListAssignedNames, collectStmtAssignedNames,
                Bind.bind, Except.bind, Pure.pure, Except.pure]))
        | _ => throwError "expected one pinned identifier helper: {suffix}"
    all_goals (trace_state; decide_cbv)
  have validated : validateCompileInputs checkedFoldSpec [tx.functionSelector] = .ok () := by
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
    simp [validateNonReentrantForkCompatibility, no_external_assumptions, identifiers, checkedFoldSpec, functionValid,
      checkedFold, modulesField, Bind.bind, Except.bind, Pure.pure, Except.pure]
    all_goals (trace_state; decide_cbv)
  have fieldSlot : findFieldWithResolvedSlot [modulesField] "modules" = some (modulesField, 7) := by
    rfl
  have fieldType : modulesField.ty = .dynamicArray .uint256 := rfl
  have fieldTransient : modulesField.isTransient = false := rfl
  have bodyValid :
      (compileStmtListWithFork [modulesField] [] [] .calldata [] false [] [] .cancun checkedFold.body []).isOk = true := by
    simp [checkedFold, fieldSlot, fieldType, fieldTransient, compileStmtListWithFork, compileStmtWithFork,
      compileExprWithInternals, compileRequireFailCondWithInternals,
      compileSetStorageArrayElement, validateDynamicArrayField,
      Bind.bind, Except.bind, Pure.pure, Except.pure, Except.isOk, Except.toBool]
    all_goals decide_cbv
  have hi : checkedFold.isInternal = false := rfl
  have hn : checkedFold.name = "checkedFold" := rfl
  have hs : isInteropEntrypointName "checkedFold" = false := by decide +kernel
  have hf : CompilationModel.applySlotAliasRanges [modulesField] [] = [modulesField] := rfl
  have hp : checkedFold.params = [] := rfl
  have hl : checkedFold.nonReentrantLock = none := rfl
  have hr : functionReturns checkedFold = .ok [.uint256] := rfl
  have templates : (templateIntrinsicItems checkedFoldSpec).isEmpty = true := by
    simp [templateIntrinsicItems, checkedFoldSpec, checkedFold,
      collectTemplateIntrinsicsFromStmts, templates_leaf, templates_forEach,
      templates_literal, templates_localVar, templates_storageArrayLength,
      templates_storageArrayElement, templates_add, templates_sub, templates_le,
      Stmt.directMetadata, Stmt.childLists]
    all_goals (trace_state; decide_cbv)
  have ht := List.nil_of_isEmpty templates
  unfold CompilationModel.compile
  rw [validated]
  simp only [bind, Except.bind]
  cases hb : compileStmtListWithFork [modulesField] [] [] .calldata [] false [] [] .cancun checkedFold.body []
  · simp [hb, Except.isOk, Except.toBool] at bodyValid
  · unfold compileValidatedCore
    rw [ht]
    simp [checkedFoldSpec, compileGuardedFunctionSpec, compileFunctionSpec,
      functionValid, hi, hn, hs, hf, hp, hl, hr, hb,
      attachNonReentrantGuard, compileConstructor, pickUniqueFunctionByName,
      List.filter_cons, List.mapM_cons, List.map_cons, List.map_nil,
      Bind.bind, Except.bind, Pure.pure, Except.pure, Except.isOk, Except.toBool]

end LidoSRv3.Audit.Verity.OfficialSemantics
