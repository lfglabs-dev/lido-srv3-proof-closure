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
  native_decide

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
  native_decide

/-- The same official denotation observes the Solidity-style overflow guard as
failure, rather than silently accepting wrapped arithmetic. -/
theorem checkedFold_overflow_reverts :
    (denote checkedFold [Verity.Core.MAX_UINT256, 1]).success = false := by
  native_decide

/-- Negative mutant: removing the guard changes the overflow observation to a
successful wrapped result. -/
theorem wrappingMutant_is_detected :
    (denote wrappingMutant [Verity.Core.MAX_UINT256, 1]).success = true ∧
      (denote wrappingMutant [Verity.Core.MAX_UINT256, 1]).returnValue = some 0 := by
  native_decide

/-- The same EDSL program genuinely enters Verity's official compiler and
produces its IR; this theorem fixes the concrete compiler entrypoint and rules
out a source-only local interpreter experiment. -/
theorem checkedFold_compiles_to_official_ir :
    (CompilationModel.compile checkedFoldSpec [tx.functionSelector]).isOk = true := by
  native_decide

end LidoSRv3.Audit.Verity.OfficialSemantics
