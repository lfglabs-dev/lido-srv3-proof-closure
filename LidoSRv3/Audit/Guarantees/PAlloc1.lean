import LidoSRv3.Audit.Model.AllocCapacity
import LidoSRv3.Audit.Source.AllocCapacityCorrespondence
import LidoSRv3.Audit.Source.MinFirstCorrespondence
import LidoSRv3.Audit.Guarantees.Registry

namespace LidoSRv3.Audit.Guarantees.PAlloc1

open Verity
open Verity.Stdlib.Math
open LidoSRv3.Audit.AllocCapacity

def guarantee : Guarantee := ⟨.pAlloc1, [.model, .source]⟩

/-- The canonical active capacity is bounded by both operands of the pinned
`Math.min` clamp. -/
theorem active_capacity_bounded
    (cfg : Config) (modules : List Module) (depositsToAllocate : Uint256)
    (isTopUp : Bool) (module : Module) (hActive : module.isActive = true) :
    MathView.capacity cfg modules depositsToAllocate isTopUp module ≤
        MathView.targetValidators cfg modules depositsToAllocate module ∧
      MathView.capacity cfg modules depositsToAllocate isTopUp module ≤
        MathView.availableCapacity cfg isTopUp module :=
  AllocCapacity.active_capacity_bounded cfg modules depositsToAllocate isTopUp module hActive

/-- Under the exact checked-`uint256` bounds, the pinned source interpreter
succeeds and its capacity column equals the independent Audit model. -/
theorem source_capacities_match_canonical
    (cfg : Config) (modules : List Module) (depositsToAllocate : Uint256)
    (isTopUp : Bool) (hBounds : CheckedBounds cfg modules depositsToAllocate isTopUp) :
    ∃ rows, SolidityAllocCapacity.execute cfg modules depositsToAllocate isTopUp = some rows ∧
      rows.map (fun row => (row.capacity : Nat)) =
        MathView.capacities cfg modules depositsToAllocate isTopUp :=
  SolidityAllocCapacity.source_execute_refines_audit_model
    cfg modules depositsToAllocate isTopUp hBounds

/-- Successful execution retains router index order. -/
theorem router_order_preserved {cfg : Config} {modules : List Module}
    {depositsToAllocate : Uint256} {isTopUp : Bool} {rows : List Row}
    (h : SolidityAllocCapacity.execute cfg modules depositsToAllocate isTopUp = some rows) :
    rows.map Row.moduleId = modules.map Module.moduleId :=
  SolidityAllocCapacity.router_order_preserved h

/-- The whole checked executor, not merely its arithmetic primitives, succeeds
under the named Solidity bounds and returns the mathematical capacities. -/
theorem checked_uint256_execution_refines_math
    (cfg : Config) (modules : List Module) (depositsToAllocate : Uint256)
    (isTopUp : Bool) (hBounds : CheckedBounds cfg modules depositsToAllocate isTopUp) :
    ∃ rows, SolidityAllocCapacity.execute cfg modules depositsToAllocate isTopUp = some rows ∧
      rows.map (fun row => (row.capacity : Nat)) =
        MathView.capacities cfg modules depositsToAllocate isTopUp :=
  source_capacities_match_canonical cfg modules depositsToAllocate isTopUp hBounds

/-- Bounded official-Verity transaction closure for the merged source/capacity
lane.  The observation fixes the returned checked amount and the full
router-ordered allocation column, including additive conservation. -/
theorem verity_tx_refines_source_capacity_and_conservation :
    SolidityMinFirst.observeAllocationTx
      ((SolidityMinFirst.AllocationContract.allocate 60).run
        SolidityMinFirst.conservationReceiptState) =
      SolidityMinFirst.sourceCapacityObservation :=
  SolidityMinFirst.verity_tx_refines_source_capacity_and_conservation

end LidoSRv3.Audit.Guarantees.PAlloc1
