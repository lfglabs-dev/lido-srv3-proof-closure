import Compiler.CompilationModel
import Verity.Core.Model.Denote

/-!
# Official Verity semantics smoke test

This file pins the concrete semantic path available in Verity revision
`d2d4a18a4d7021adcd90d4b03e619affe506dd54`:

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

set_option maxRecDepth 16384 in
set_option maxHeartbeats 4000000 in
set_option pp.maxSteps 200 in
/-- The same EDSL program genuinely enters Verity's official compiler and
produces its IR; this theorem fixes the concrete compiler entrypoint and rules
out a source-only local interpreter experiment. -/
theorem checkedFold_compiles_to_official_ir :
    (CompilationModel.compile checkedFoldSpec [tx.functionSelector]).isOk = true := by
  letI : DecidableEq (Except String Unit) := fun x y =>
    match x, y with
    | .ok _, .ok _ => isTrue rfl
    | .error a, .error b =>
      if h : a = b then isTrue (h ▸ rfl)
      else isFalse (by intro heq; cases heq; exact h rfl)
    | .ok _, .error _ => isFalse (by intro h; cases h)
    | .error _, .ok _ => isFalse (by intro h; cases h)
  have functionValid : validateFunctionSpec checkedFold = .ok () := by
    simp [validateFunctionSpec, checkedFold, Bind.bind, Except.bind, Pure.pure, Except.pure]
    decide +kernel
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
    simp [checkedFoldSpec, functionValid, checkedFold, modulesField,
      Bind.bind, Except.bind, Pure.pure, Except.pure]
    all_goals decide +kernel
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
    all_goals decide +kernel
  have hi : checkedFold.isInternal = false := rfl
  have hn : checkedFold.name = "checkedFold" := rfl
  have hs : isInteropEntrypointName "checkedFold" = false := by decide +kernel
  have hf : CompilationModel.applySlotAliasRanges [modulesField] [] = [modulesField] := rfl
  have hp : checkedFold.params = [] := rfl
  have hl : checkedFold.nonReentrantLock = none := rfl
  have hr : functionReturns checkedFold = .ok [.uint256] := rfl
  have templates : (templateIntrinsicItems checkedFoldSpec).isEmpty = true := by decide +kernel
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
