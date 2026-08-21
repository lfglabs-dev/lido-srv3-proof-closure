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

/-- **MathView-definitional fact, excluded from the registered parent.**
If `module.isActive`, `MathView.capacity` is *defined* as
`min(targetValidators, availableCapacity)`, so it is ≤ both operands by
`Nat.min_le_left`/`Nat.min_le_right`. This holds for any two `Nat`s — it
restates the definition of `min`, not a property of `execute`'s arithmetic or
of any router — so Wave 2 removed it from the registered parent
`checked_execute` below (P-ALLOC-1 audit issue 1: the Wave 1 parent
`checked_execute_and_active_capacity_bounded` conjoined this tautology with
the meaningful executable content, so a mutant that only broke this conjunct
could never be written; the kill-line in `AllocationTxMutants.lean` targets
`checked_execute`'s actual content instead). Retained here, unregistered, as
an explicit, separately labeled fact for a reader who wants to cite the
`min` shape of `MathView.capacity`. -/
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

/-- **Wave 2 registered parent.**  Under `CheckedBounds`, the source-shaped
executor succeeds and its capacity column equals the independent `MathView`
model.  This restates `source_capacities_match_canonical` above under the
parent's public name: it is exactly the executable content of the retired
Wave 1 parent `checked_execute_and_active_capacity_bounded`, with the
`active_capacity_bounded` conjunct dropped. That conjunct is a
`Nat.min_le_left`/`Nat.min_le_right` tautology on the `MathView.capacity`
*definition* that holds for any two `Nat`s regardless of whether `execute`
computed the right target or headroom (P-ALLOC-1 audit issue 1). Folding a
definitional tautology into the parent meant no mutant could ever be written
that broke only that conjunct, so the registered parent is narrowed here to
the one conjunct a kill-line can actually falsify; `active_capacity_bounded`
remains available above as an explicit, unregistered MathView-definitional
child. -/
theorem checked_execute
    (cfg : Config) (modules : List Module) (depositsToAllocate : Verity.Uint256)
    (isTopUp : Bool) (hBounds : CheckedBounds cfg modules depositsToAllocate isTopUp) :
    ∃ rows, SolidityAllocCapacity.execute cfg modules depositsToAllocate isTopUp = some rows ∧
      rows.map (fun row => (row.capacity : Nat)) =
        MathView.capacities cfg modules depositsToAllocate isTopUp :=
  source_capacities_match_canonical cfg modules depositsToAllocate isTopUp hBounds

/-- Successful execution retains router index order. -/
theorem router_order_preserved {cfg : Config} {modules : List Module}
    {depositsToAllocate : Verity.Uint256} {isTopUp : Bool} {rows : List Row}
    (h : SolidityAllocCapacity.execute cfg modules depositsToAllocate isTopUp = some rows) :
    rows.map Row.moduleId = modules.map Module.moduleId :=
  SolidityAllocCapacity.router_order_preserved h

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
`AllocCapacity` interpreter. This is not a live summary CALL: returndata is
not decoded into the rows. The packed `ModuleStateConfig` word is represented
by separate model-local maps, and `n` is a harness argument rather than a
count reread from `SRStorage.getModulesCount()`. Those three gaps remain OPEN
and are intentionally not widened into P-ALLOC-2. -/
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

/-- Storage-backed P-ALLOC-1 transaction closure. The router module count is
read from `modulesCountSlot`, capped at the pinned maximum of 32, and the same
storage-selected prefix drives both the executable observation and source
view. Live summary returndata and packed `ModuleStateConfig` remain separate
OPEN obligations. -/
theorem verity_tx_simulates_allocation_count_from_storage
    (cfg : Config) (depositsToAllocate : Verity.Uint256) (isTopUp : Bool)
    (state : Verity.ContractState) :
    let count := min
      (state.readSlot
        _root_.LidoSRv3.Audit.Verity.AllocationTx.modulesCountSlot).val 32
    let modules :=
      _root_.LidoSRv3.Audit.Verity.AllocationTx.sourceBindAll state count
    _root_.LidoSRv3.Audit.Verity.AllocationTx.observe modules
        ((_root_.LidoSRv3.Audit.Verity.AllocationTx.allocateFromStorage
          cfg depositsToAllocate isTopUp).run state) =
      _root_.LidoSRv3.Audit.Verity.AllocationTx.sourceView
        cfg modules depositsToAllocate isTopUp :=
  _root_.LidoSRv3.Audit.Verity.AllocationTx.verity_tx_simulates_allocation_count_from_storage
    cfg depositsToAllocate isTopUp state

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
