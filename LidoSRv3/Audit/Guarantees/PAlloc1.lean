import LidoSRv3.Audit.Model.AllocCapacity
import LidoSRv3.Audit.Source.AllocCapacityCorrespondence
import LidoSRv3.Audit.Guarantees.Registry
import LidoSRv3.Audit.Verity.AllocCapacityPhase3
import LidoSRv3.Audit.Verity.AllocationTx

namespace LidoSRv3.Audit.Guarantees.PAlloc1

open Verity.Stdlib.Math
open LidoSRv3.Audit.AllocCapacity

def guarantee : Guarantee := ⟨.pAlloc1, [.model, .source, .verityTx]⟩

def mappedSummaryTransaction (moduleAddress : Nat) : Prop :=
  (Compiler.CompilationModel.compile
      _root_.LidoSRv3.Audit.Verity.AllocCapacityPhase3.spec
      [_root_.LidoSRv3.Audit.Verity.AllocCapacityPhase3.entrySelector]).isOk = true ∧
  _root_.LidoSRv3.Audit.Verity.AllocCapacityPhase3.SourceCallStorageABI
      _root_.LidoSRv3.Audit.Verity.AllocCapacityPhase3.consumedSummaryEntry moduleAddress ∧
  Compiler.CompilationModel.DenoteExternalCalls.CallsIn
      (_root_.LidoSRv3.Audit.Verity.AllocCapacityPhase3.sourceCallProgram
        _root_.LidoSRv3.Audit.Verity.AllocCapacityPhase3.consumedSummaryEntry moduleAddress)
      { stateTransition := fun _ world => world
        result := fun _ _ => .success (List.replicate
          _root_.LidoSRv3.Audit.Verity.AllocCapacityPhase3.summaryReturnBytes 0)
        gasUsed := fun _ _ => 0 }
      _root_.LidoSRv3.Audit.Verity.AllocCapacityPhase3.canonicalCallState =
        [_root_.LidoSRv3.Audit.Verity.AllocCapacityPhase3.sourceSummarySite moduleAddress] ∧
  _root_.LidoSRv3.Audit.Verity.AllocCapacityPhase3.summaryCalldata = [0x9a, 0xbd, 0xdf, 0x09] ∧
  (∀ adversary data (depositable : Verity.Uint256) state,
    adversary.result (_root_.LidoSRv3.Audit.Verity.AllocCapacityPhase3.sourceSummarySite moduleAddress)
      (state.writeSlot
        _root_.LidoSRv3.Audit.Verity.AllocCapacityPhase3.lastCapacitySlot.slot depositable) = .revert data →
    ∃ reason, (_root_.LidoSRv3.Audit.Verity.AllocCapacityPhase3.executeObservedSummary
      adversary moduleAddress depositable).run state =
        Verity.ContractResult.revert reason state) ∧
  (∀ adversary data (depositable : Verity.Uint256) state,
    adversary.result (_root_.LidoSRv3.Audit.Verity.AllocCapacityPhase3.sourceSummarySite moduleAddress)
      (state.writeSlot
        _root_.LidoSRv3.Audit.Verity.AllocCapacityPhase3.lastCapacitySlot.slot depositable) = .success data →
    ¬ _root_.LidoSRv3.Audit.Verity.AllocCapacityPhase3.summaryReturnBytes <= data.length →
    (_root_.LidoSRv3.Audit.Verity.AllocCapacityPhase3.executeObservedSummary
      adversary moduleAddress depositable).run state =
        Verity.ContractResult.revert "StakingModuleSummaryMalformedReturn" state) ∧
  (∀ adversary data (depositable : Verity.Uint256) state,
    adversary.result (_root_.LidoSRv3.Audit.Verity.AllocCapacityPhase3.sourceSummarySite moduleAddress)
      (state.writeSlot
        _root_.LidoSRv3.Audit.Verity.AllocCapacityPhase3.lastCapacitySlot.slot depositable) = .success data →
    _root_.LidoSRv3.Audit.Verity.AllocCapacityPhase3.summaryReturnBytes <= data.length →
    (_root_.LidoSRv3.Audit.Verity.AllocCapacityPhase3.executeObservedSummary
      adversary moduleAddress depositable).run state =
        Verity.ContractResult.success ()
          (state.writeSlot
            _root_.LidoSRv3.Audit.Verity.AllocCapacityPhase3.lastCapacitySlot.slot depositable))

/-- Child of `MathView`: if `module.isActive`, `MathView.capacity` is defined as
`min(targetValidators, availableCapacity)`, so it is ≤ both operands. -/
theorem active_capacity_bounded
    (cfg : Config) (modules : List Module) (depositsToAllocate : Verity.Uint256)
    (isTopUp : Bool) (module : Module) (hActive : module.isActive = true) :
    MathView.capacity cfg modules depositsToAllocate isTopUp module ≤
        MathView.targetValidators cfg modules depositsToAllocate module ∧
      MathView.capacity cfg modules depositsToAllocate isTopUp module ≤
        MathView.availableCapacity cfg isTopUp module :=
  AllocCapacity.active_capacity_bounded cfg modules depositsToAllocate isTopUp module hActive

/-- Under the exact checked-`uint256` bounds, the pinned source interpreter
succeeds and its capacity column equals the independent Audit model. -/
theorem source_capacities_match_canonical
    (cfg : Config) (modules : List Module) (depositsToAllocate : Verity.Uint256)
    (isTopUp : Bool) (hBounds : CheckedBounds cfg modules depositsToAllocate isTopUp) :
    ∃ rows, SolidityAllocCapacity.execute cfg modules depositsToAllocate isTopUp = some rows ∧
      rows.map (fun row => (row.capacity : Nat)) =
        MathView.capacities cfg modules depositsToAllocate isTopUp :=
  SolidityAllocCapacity.source_execute_refines_audit_model
    cfg modules depositsToAllocate isTopUp hBounds

/-- **Wave 1 registered parent.**  Under `CheckedBounds`:
- the source-shaped executor succeeds,
- its capacity column equals the independent `MathView` model,
- AND for every active module the executed capacity is bounded by both
  `targetValidators` (from the row) and `MathView.availableCapacity`. -/
theorem checked_execute_and_active_capacity_bounded
    (cfg : Config) (modules : List Module) (depositsToAllocate : Verity.Uint256)
    (isTopUp : Bool) (hBounds : CheckedBounds cfg modules depositsToAllocate isTopUp)
    (module : Module) (hActive : module.isActive = true) :
    (∃ rows, SolidityAllocCapacity.execute cfg modules depositsToAllocate isTopUp = some rows ∧
      rows.map (fun row => (row.capacity : Nat)) =
        MathView.capacities cfg modules depositsToAllocate isTopUp) ∧
    MathView.capacity cfg modules depositsToAllocate isTopUp module ≤
        MathView.targetValidators cfg modules depositsToAllocate module ∧
      MathView.capacity cfg modules depositsToAllocate isTopUp module ≤
        MathView.availableCapacity cfg isTopUp module :=
  ⟨source_capacities_match_canonical cfg modules depositsToAllocate isTopUp hBounds,
   AllocCapacity.active_capacity_bounded cfg modules depositsToAllocate isTopUp module hActive⟩


/-- Successful execution retains router index order. -/
theorem router_order_preserved {cfg : Config} {modules : List Module}
    {depositsToAllocate : Verity.Uint256} {isTopUp : Bool} {rows : List Row}
    (h : SolidityAllocCapacity.execute cfg modules depositsToAllocate isTopUp = some rows) :
    rows.map Row.moduleId = modules.map Module.moduleId :=
  SolidityAllocCapacity.router_order_preserved h

/-- The whole checked executor, not merely its arithmetic primitives, succeeds
under the named Solidity bounds and returns the mathematical capacities. -/
theorem checked_uint256_execution_refines_math
    (cfg : Config) (modules : List Module) (depositsToAllocate : Verity.Uint256)
    (isTopUp : Bool) (hBounds : CheckedBounds cfg modules depositsToAllocate isTopUp) :
    ∃ rows, SolidityAllocCapacity.execute cfg modules depositsToAllocate isTopUp = some rows ∧
      rows.map (fun row => (row.capacity : Nat)) =
        MathView.capacities cfg modules depositsToAllocate isTopUp :=
  source_capacities_match_canonical cfg modules depositsToAllocate isTopUp hBounds

/-- Canonical P-ALLOC-1 evidence retains the allocation-capacity
MODEL→SOURCE correspondence and adds only the bounded mapped-summary
SOURCE→VERITY_TX slice.  It makes no Yul/EVM/deployment claim. -/
theorem source_capacities_and_mapped_summary_transaction
    (cfg : Config) (modules : List Module) (depositsToAllocate : Verity.Uint256)
    (isTopUp : Bool) (hBounds : CheckedBounds cfg modules depositsToAllocate isTopUp)
    (moduleAddress : Nat) :
    (∃ rows, SolidityAllocCapacity.execute cfg modules depositsToAllocate isTopUp = some rows ∧
      rows.map (fun row => (row.capacity : Nat)) =
        MathView.capacities cfg modules depositsToAllocate isTopUp) ∧
    mappedSummaryTransaction moduleAddress := by
  exact ⟨source_capacities_match_canonical cfg modules depositsToAllocate isTopUp hBounds,
    _root_.LidoSRv3.Audit.Verity.AllocCapacityPhase3.consumed_summary_phase3_transaction moduleAddress⟩

/-- One handwritten bind+execute: if `sourceBindAll state n` recovers
`modules`, then `observe` of `allocate n` (which reads the persisted
allocation/capacity/address arrays) equals `sourceView` of the same
`AllocCapacity` interpreter. Not a live summary CALL. -/
theorem verity_tx_simulates_allocation
    (cfg : Config) (modules : List _root_.LidoSRv3.Audit.Verity.AllocationTx.BoundModule)
    (depositsToAllocate : Verity.Uint256) (isTopUp : Bool)
    (state : Verity.ContractState)
    (hBind : _root_.LidoSRv3.Audit.Verity.AllocationTx.sourceBindAll
      state modules.length = modules) :
    _root_.LidoSRv3.Audit.Verity.AllocationTx.observe modules
        ((_root_.LidoSRv3.Audit.Verity.AllocationTx.allocate
          modules.length cfg depositsToAllocate isTopUp).run state) =
      _root_.LidoSRv3.Audit.Verity.AllocationTx.sourceView
        cfg modules depositsToAllocate isTopUp :=
  _root_.LidoSRv3.Audit.Verity.AllocationTx.verity_tx_simulates_pinned_source
    cfg modules depositsToAllocate isTopUp state hBind

/-- Every revert of the allocation transaction, including the injected
failure after intermediate map/slot writes, restores the pre-call snapshot. -/
theorem verity_tx_revert_restores_snapshot
    (count : Nat) (cfg : Config) (depositsToAllocate : Verity.Uint256)
    (isTopUp inject : Bool) (state rollback : Verity.ContractState)
    (reason : String)
    (h : (_root_.LidoSRv3.Audit.Verity.AllocationTx.allocate
        count cfg depositsToAllocate isTopUp inject).run state =
      Verity.ContractResult.revert reason rollback) :
    rollback = state :=
  _root_.LidoSRv3.Audit.Verity.AllocationTx.revert_restores_snapshot
    count cfg depositsToAllocate isTopUp inject state rollback reason h

end LidoSRv3.Audit.Guarantees.PAlloc1
