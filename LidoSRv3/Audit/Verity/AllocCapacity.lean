import LidoSRv3.Audit.Verity.OfficialSemantics

/-!
# P-ALLOC-1 official-Verity slice

This is the smallest genuine slice of `SRLib._getModulesAllocationAndCapacity`
that exercises every checked arithmetic family needed by the active type-1,
non-top-up path for one router-ordered module.  It is a Verity deep-EDSL
`FunctionSpec`, compiled by Verity and evaluated only by Verity's canonical
`Compiler.CompilationModel.Denote` semantics.

The omitted layers are explicit: multiple modules, type-2 `ceilDiv`, the
top-up branch, and construction/return of both dynamic output arrays.
-/

namespace LidoSRv3.Audit.Verity.AllocCapacity

open Compiler
open Compiler.CompilationModel
open Compiler.CompilationModel.Denote

private def maxWord : Expr := .literal Verity.Core.MAX_UINT256

private def activeBody (applyAvailableMin : Bool) : List Stmt :=
  [ .require
      (.le (.param "depositable") (.sub maxWord (.localVar "allocation")))
      "Panic(0x11): arithmetic overflow"
  , .letVar "available" (.add (.localVar "allocation") (.param "depositable"))
  , .require
      (.logicalOr (.eq (.localVar "total") (.literal 0))
        (.le (.param "shareLimit") (.div maxWord (.localVar "total"))))
      "Panic(0x11): arithmetic overflow"
  , .letVar "numerator" (.mul (.param "shareLimit") (.localVar "total"))
  , .letVar "target" (.div (.localVar "numerator") (.literal 10000))
  , .return
      (if applyAvailableMin then
        .ite (.le (.localVar "target") (.localVar "available"))
          (.localVar "target") (.localVar "available")
       else
        .localVar "target") ]

/-- Active type-1, non-top-up capacity for one module, in Solidity source
order: max/exited subtraction, total addition, available addition, target
multiplication/division, then `min(target, available)`. -/
def oneModule : FunctionSpec :=
  { name := "oneModuleAllocCapacity"
    params :=
      [ { name := "deposits", ty := .uint256 }
      , { name := "shareLimit", ty := .uint256 }
      , { name := "isActive", ty := .bool }
      , { name := "depositable", ty := .uint256 }
      , { name := "deposited", ty := .uint256 }
      , { name := "summaryExited", ty := .uint256 }
      , { name := "accountingExited", ty := .uint256 } ]
    returnType := some .uint256
    body :=
      [ .letVar "exited"
          (.ite (.le (.param "summaryExited") (.param "accountingExited"))
            (.param "accountingExited") (.param "summaryExited"))
      , .require (.le (.localVar "exited") (.param "deposited"))
          "Panic(0x11): arithmetic underflow"
      , .letVar "allocation" (.sub (.param "deposited") (.localVar "exited"))
      , .require
          (.le (.localVar "allocation") (.sub maxWord (.param "deposits")))
          "Panic(0x11): arithmetic overflow"
      , .letVar "total" (.add (.param "deposits") (.localVar "allocation"))
      , .ite (.param "isActive")
          (activeBody true)
          [ .return (.localVar "allocation") ] ] }

def spec : CompilationModel :=
  { name := "LidoAllocCapacityOneModule"
    fields := []
    constructor := none
    functions := [oneModule] }

def selector : Nat := 0x6a70ca01

private def oracle : DenoteOracle :=
  { mappingSlot := fun _ _ => 0
    keccakMemorySlice := fun _ _ _ => 0 }

def run (fn : FunctionSpec) (args : List Nat) : DenoteResult :=
  denoteFunction oracle { spec with functions := [fn] } fn
    { sender := 1, functionSelector := selector, args := args }
    Verity.defaultState

/-- Observation relation used by this slice: successful return of the capacity
word.  Reverts are deliberately not related to any capacity. -/
def ObservesCapacity (result : DenoteResult) (capacity : Nat) : Prop :=
  result.success = true ∧ result.returnValue = some capacity

/-- Concrete active example: total `100`, target `10`, available `2`, hence
capacity `2`. -/
theorem oneModule_observes_minimum :
    ObservesCapacity (run oneModule [100, 1000, 1, 2, 0, 0, 0]) 2 := by
  unfold ObservesCapacity
  native_decide

/-- The checked subtraction fails exactly as the source does when exited
validators exceed deposited validators. -/
theorem oneModule_underflow_reverts :
    (run oneModule [100, 1000, 1, 2, 0, 1, 0]).success = false := by
  native_decide

/-- Mutant: return the target and omit the final `min` with available
capacity. -/
def noAvailableMinMutant : FunctionSpec :=
  { oneModule with
    name := "oneModuleNoAvailableMin"
    body := oneModule.body.take 5 ++
      [.ite (.param "isActive") (activeBody false) [.return (.localVar "allocation")]] }

theorem noAvailableMinMutant_is_detected :
    ObservesCapacity (run oneModule [100, 1000, 1, 2, 0, 0, 0]) 2 ∧
      ¬ ObservesCapacity (run noAvailableMinMutant [100, 1000, 1, 2, 0, 0, 0]) 2 := by
  unfold ObservesCapacity
  native_decide

theorem oneModule_compiles_to_official_ir :
    (CompilationModel.compile spec [selector]).isOk = true := by
  native_decide

end LidoSRv3.Audit.Verity.AllocCapacity
