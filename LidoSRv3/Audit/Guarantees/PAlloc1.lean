import LidoSRv3.Audit.Model.AllocCapacity
import LidoSRv3.Audit.Source.AllocCapacityCorrespondence
import LidoSRv3.Audit.Source.Alloc1CompositeBoundsSource
import LidoSRv3.Audit.Guarantees.Registry
import LidoSRv3.Audit.Guarantees.PAlloc1TargetMultBounded
import LidoSRv3.Audit.Guarantees.PAlloc1RemainingBoundsScaffold
import LidoSRv3.Audit.Guarantees.PAlloc1TotalAdditionBounded
import LidoSRv3.Audit.Guarantees.PAlloc1AvailableArithmeticBounded
import LidoSRv3.Audit.Verity.AllocCapacityPhase3
import LidoSRv3.Audit.Verity.AllocationTx
import LidoSRv3.Audit.Source.TrioAlloc1.VerityProducer
import LidoSRv3.Audit.Source.TrioComposition.VerityParentResult

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

/-- **Chantier 3 composition (Piste A, Thomas 2026-09-13).**

`CheckedBounds` is derivable from the pinned SRLib/StakingModule shape
premises named in `PAlloc1TargetMultBounded.PinnedStakingModuleTypeBounds`
and `PAlloc1RemainingBoundsScaffold.PinnedSRAllocationBoundsShape` (+ the
config's `maxEBType1 ≠ 0` pinned constant). This composition is the
"CheckedBounds atteignable" step Thomas asked for on 2026-09-13: it
strips the parent's caller-side `CheckedBounds` premise and replaces it
with the two pinned-shape premises that name where each conjunct is
supposed to come from in the pinned Solidity (SRLib.sol type widths and
SRStorage invariants). Callers who supply the pinned shapes get the
executor/MathView correspondence for free.

Residuals — recorded in `fidelity.missing` — are: (a) the two shape
structures still name their invariants as caller premises rather than
proving them from live SRStorage reads, so this is a NAMING composition
of pinned invariants, not a live-storage derivation; (b) `PinnedSR-
AllocationBoundsShape` bundles `active_subtraction`, `total_addition`,
and `available_arithmetic` as premises whose real derivations require
SRStorage monotonicity + `MAX_STAKING_MODULES_COUNT = 32` + per-module
uint64 caps.

The `target_multiplication` conjunct's derivation is not renamed here:
it is reduced to `PinnedStakingModuleTypeBounds` via the already-
registered `PAlloc1TargetMultBounded.target_multiplication_under_pinned
_type_bounds`, which is a REAL derivation (`uint16Max * uint64Max <
MAX_UINT256` closed by `decide`). -/
theorem checked_execute_under_pinned_shape
    (cfg : Config) (modules : List Module) (depositsToAllocate : Verity.Uint256)
    (isTopUp : Bool)
    (hMaxEB : cfg.maxEBType1 ≠ 0)
    (hTypes : PAlloc1TargetMultBounded.PinnedStakingModuleTypeBounds
      cfg modules depositsToAllocate)
    (hShape : PAlloc1RemainingBoundsScaffold.PinnedSRAllocationBoundsShape
      cfg modules depositsToAllocate isTopUp) :
    ∃ rows, SolidityAllocCapacity.execute cfg modules depositsToAllocate isTopUp = some rows ∧
      rows.map (fun row => (row.capacity : Nat)) =
        MathView.capacities cfg modules depositsToAllocate isTopUp :=
  checked_execute cfg modules depositsToAllocate isTopUp
    { maxEBType1_nonzero := hMaxEB
      active_subtraction := hShape.activeSubtractionInvariant
      total_addition := hShape.totalAdditionInvariant
      available_arithmetic := hShape.availableArithmeticInvariant
      target_multiplication :=
        PAlloc1TargetMultBounded.target_multiplication_under_pinned_type_bounds hTypes }

/-- **Chantier 3 (Piste A, Thomas 2026-09-13) SR-allocation-constants
composite bounds bridge.**

Restates `checked_execute` with an added `_hConstantsPremise` premise
NAMING the pinned SRLib allocation constants (`MAX_STAKING_MODULES_COUNT =
32`, `stakeShareLimitMaxBp = 10000`) via
`Alloc1CompositeBoundsSource.PinnedAllocConstantsPremise`.  This
composite premise records the pinned SR constants that ground the
`CheckedBounds` conjuncts alongside the type-width bounds from
`PinnedStakingModuleTypeBounds`.

The bridge parent `checked_execute_under_pinned_shape` (previous
theorem in this file) consumes `PinnedStakingModuleTypeBounds +
PinnedSRAllocationBoundsShape` and derives the `target_multiplication`
conjunct.  This new bridge adds the SRLib constants as a NAMED
composite premise (also inhabited by construction via
`PinnedAllocConstantsPremise_inhabited`), so downstream P-ALLOC-1
consumers can enforce the pinned constant values uniformly at the
ENUNCE.

**NAMING composite composition.**  The registered `checked_execute`
is retained unchanged.  Live-SRStorage derivations of the three
remaining CheckedBounds conjuncts (active_subtraction /
total_addition / available_arithmetic) still remain follow-ups. -/
theorem checked_execute_under_pinned_shape_and_constants
    (cfg : Config) (modules : List Module) (depositsToAllocate : Verity.Uint256)
    (isTopUp : Bool)
    (hMaxEB : cfg.maxEBType1 ≠ 0)
    (hTypes : PAlloc1TargetMultBounded.PinnedStakingModuleTypeBounds
      cfg modules depositsToAllocate)
    (hShape : PAlloc1RemainingBoundsScaffold.PinnedSRAllocationBoundsShape
      cfg modules depositsToAllocate isTopUp)
    (_hConstantsPremise :
      LidoSRv3.Audit.Source.Alloc1CompositeBoundsSource.PinnedAllocConstantsPremise) :
    ∃ rows, SolidityAllocCapacity.execute cfg modules depositsToAllocate isTopUp = some rows ∧
      rows.map (fun row => (row.capacity : Nat)) =
        MathView.capacities cfg modules depositsToAllocate isTopUp :=
  -- The constants premise names the pinned SRLib allocation
  -- constants (MAX_STAKING_MODULES_COUNT = 32, stakeShareLimitMaxBp
  -- = 10000).  The proof delegates to
  -- `checked_execute_under_pinned_shape` since the type-width /
  -- SR-shape bounds already discharge the CheckedBounds
  -- conjuncts; the constants premise records the pinned SR
  -- constants at the ENUNCE for downstream consumers.
  checked_execute_under_pinned_shape cfg modules depositsToAllocate isTopUp
    hMaxEB hTypes hShape

/-- **Chantier 3 (Piste A, Thomas 2026-09-13) `total_addition` real
derivation.**

Analog of `checked_execute_under_pinned_shape` where the
`total_addition` conjunct of `CheckedBounds` is DERIVED from real
arithmetic on `PinnedAllocationEntryBounds` (MAX_STAKING_MODULES_COUNT
= 32, uint64 `depositsToAllocate`, uint64 per-module
`allocationEntry`), not passed through from `PinnedSRAllocation-
BoundsShape.totalAdditionInvariant`.  Via `PAlloc1TotalAdditionBounded.
total_addition_under_pinned_bounds`: `deposits + Σ entries ≤ (32 + 1)
* (2^64 - 1) ≈ 6·10^20 << MAX_UINT256 = 2^256 - 1`.

Two of the four `CheckedBounds` conjuncts are now derived from real
bounds (target_multiplication via `PAlloc1TargetMultBounded`;
total_addition via `PAlloc1TotalAdditionBounded`).  `active_subtraction`
and `available_arithmetic` remain caller-supplied premises for now
(see `fidelity.missing`; live SRStorage monotonicity + per-module uint64
caps derivation is the follow-up). -/
theorem checked_execute_under_type_and_allocation_bounds
    (cfg : Config) (modules : List Module) (depositsToAllocate : Verity.Uint256)
    (isTopUp : Bool)
    (hMaxEB : cfg.maxEBType1 ≠ 0)
    (hTypes : PAlloc1TargetMultBounded.PinnedStakingModuleTypeBounds
      cfg modules depositsToAllocate)
    (hAlloc : PAlloc1TotalAdditionBounded.PinnedAllocationEntryBounds
      cfg modules depositsToAllocate)
    (hActiveSubtr : ∀ m ∈ modules,
      (wordMax m.summaryExitedCount m.accountingExitedCount : Nat)
        ≤ (m.depositedCount : Nat))
    (hAvailArith : ∀ m ∈ modules, m.isActive = true →
      (if isTopUp && m.isType2 then
        MathView.activeCount m * (cfg.maxEBType2 : Nat) ≤ Verity.Core.MAX_UINT256
      else
        MathView.allocationEntry cfg m + (m.depositableCount : Nat) ≤
          Verity.Core.MAX_UINT256)) :
    ∃ rows, SolidityAllocCapacity.execute cfg modules depositsToAllocate isTopUp = some rows ∧
      rows.map (fun row => (row.capacity : Nat)) =
        MathView.capacities cfg modules depositsToAllocate isTopUp :=
  checked_execute cfg modules depositsToAllocate isTopUp
    { maxEBType1_nonzero := hMaxEB
      active_subtraction := hActiveSubtr
      total_addition :=
        PAlloc1TotalAdditionBounded.total_addition_under_pinned_bounds hAlloc
      available_arithmetic := hAvailArith
      target_multiplication :=
        PAlloc1TargetMultBounded.target_multiplication_under_pinned_type_bounds hTypes }

/-- Typed and available-arithmetic bounds plus the remaining shape invariants
yield checked execution and independent capacity equations. -/
theorem checked_execute_under_type_and_available_bounds
    (cfg : Config) (modules : List Module) (depositsToAllocate : Verity.Uint256)
    (isTopUp : Bool)
    (hMaxEB : cfg.maxEBType1 ≠ 0)
    (hTypes : PAlloc1TargetMultBounded.PinnedStakingModuleTypeBounds
      cfg modules depositsToAllocate)
    (hAvail : PAlloc1AvailableArithmeticBounded.PinnedAvailableArithmeticBounds
      cfg modules isTopUp)
    (hShape : PAlloc1RemainingBoundsScaffold.PinnedSRAllocationBoundsShape
      cfg modules depositsToAllocate isTopUp) :
    ∃ rows, SolidityAllocCapacity.execute cfg modules depositsToAllocate isTopUp = some rows ∧
      rows.map (fun row => (row.capacity : Nat)) =
        MathView.capacities cfg modules depositsToAllocate isTopUp :=
  checked_execute cfg modules depositsToAllocate isTopUp
    { maxEBType1_nonzero := hMaxEB
      active_subtraction := hShape.activeSubtractionInvariant
      total_addition := hShape.totalAdditionInvariant
      available_arithmetic :=
        PAlloc1AvailableArithmeticBounded.available_arithmetic_under_pinned_bounds hAvail
      target_multiplication :=
        PAlloc1TargetMultBounded.target_multiplication_under_pinned_type_bounds hTypes }

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

/-- Legacy/free-count sibling: if `sourceBindAll state n` recovers
`modules`, then `observe` of `allocate n` (which reads the persisted
allocation/capacity/address arrays) equals `sourceView` of the same
`AllocCapacity` interpreter. It now reads packed `ModuleStateConfig`, but its
summary fields remain planted and `n` is a harness argument. The registered
theorem below closes those two gaps without widening into P-ALLOC-2. -/
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

open LidoSRv3.Audit.Verity.AllocationTx in
/-- Storage-backed P-ALLOC-1 live-summary transaction closure. The router
module count is read from storage and capped at 32. `bindLiveAll` reads each
packed `ModuleStateConfig`, executes the mapped summary staticcall, ABI-decodes
the returned `(exited, deposited, depositable)` words, and for type-2 rows
executes the distinct pinned `getTotalModuleStake()` staticcall and ABI-decodes
its uint256 word before passing rows to the allocation loop. The premise says
those adversarial call observations decode to the source-view rows. It does
not prove reachable-router `CheckedBounds`. The additional clause consumes the
interleaved source producer in the same physical account/world for every input,
retaining errors and call order without clipping its count. It does not identify
the legacy persisted observations with that producer or discharge deployment,
layout/hash, gas, caller-context or supported-module reachability obligations. -/
theorem verity_tx_simulates_allocation_count_from_storage
    (adversary :
      Compiler.CompilationModel.DenoteExternalCalls.AdversaryModel)
    (cfg : Config)
    (modules : List BoundModule)
    (depositsToAllocate : Verity.Uint256) (isTopUp : Bool)
    (state : Verity.ContractState)
    (hLength : modules.length = min (state.readSlot modulesCountSlot).val 32)
    (hBind : (bindLiveAll adversary state 0 modules.length) state = .success modules state) :
    (observe modules
        ((allocateLiveFromStorage adversary cfg depositsToAllocate isTopUp).run state) =
      sourceView cfg modules depositsToAllocate isTopUp) ∧
    (∀ (layout : LidoSRv3.Audit.Source.TrioAlloc1.Layout)
      (input : LidoSRv3.Audit.Source.TrioAlloc1.CapacityInput)
      (gas : Nat) (before : LidoSRv3.Audit.Source.TrioAlloc1.Transcript),
      let callState : Compiler.CompilationModel.DenoteExternalCalls.CallState :=
        ⟨state, gas, []⟩
      (LidoSRv3.Audit.Source.TrioAlloc1.VerityProducer.executeAccount
        layout input adversary callState before).1 =
        LidoSRv3.Audit.Source.TrioAlloc1.produce layout
          (LidoSRv3.Audit.Source.TrioAlloc1.VerityProducer.accountStorage state)
          (LidoSRv3.Audit.Source.TrioAlloc1.VerityProducer.sourceOracle adversary state)
          input before ∧
      (LidoSRv3.Audit.Source.TrioAlloc1.VerityProducer.executeAccount
        layout input adversary callState before).2.world = state ∧
      (∀ amount,
        (LidoSRv3.Audit.Source.TrioComposition.VerityParentResult.execute
          layout input.config amount input.isTopUp adversary callState before).1 =
          LidoSRv3.Audit.Source.TrioComposition.getDepositAllocationsABI layout
            (LidoSRv3.Audit.Source.TrioAlloc1.VerityProducer.accountStorage state)
            (LidoSRv3.Audit.Source.TrioAlloc1.VerityProducer.sourceOracle adversary state)
            input.config amount input.isTopUp before ∧
        (LidoSRv3.Audit.Source.TrioComposition.VerityParentResult.execute
          layout input.config amount input.isTopUp adversary callState before).2.world = state) ∧
      LidoSRv3.Audit.Source.TrioAlloc1.VerityProducer.AccountMathResult
        layout input adversary callState before) := by
  constructor
  · exact verity_tx_simulates_live_summary_from_storage
      adversary cfg modules depositsToAllocate isTopUp state hLength hBind
  · intro layout input gas before
    have h := LidoSRv3.Audit.Source.TrioAlloc1.VerityProducer.account_producer_correspondence
      layout input adversary ⟨state, gas, []⟩ before
    exact ⟨h.1, h.2, (fun amount =>
      LidoSRv3.Audit.Source.TrioComposition.VerityParentResult.execute_correspondence
        layout input.config amount input.isTopUp adversary ⟨state, gas, []⟩ before),
      LidoSRv3.Audit.Source.TrioAlloc1.VerityProducer.account_math_result
        layout input adversary ⟨state, gas, []⟩ before⟩

/-- Registered account-qualified allocation result. Unlike the retained legacy
observation theorem above, this entry has no assumed successful binding or
clipped count. It preserves all producer outcomes and module-call observations,
derives successful capacity equations from the executed rows, and composes the
public allocation continuation on the same world.

[SRLib allocation](https://github.com/lidofinance/core/blob/17005714f151e5502c559932319a3f2f74ac2436/contracts/0.8.25/sr/SRLib.sol#L391-L431)
and [capacity loops](https://github.com/lidofinance/core/blob/17005714f151e5502c559932319a3f2f74ac2436/contracts/0.8.25/sr/SRLib.sol#L493-L559).
The abstract `checked_execute` remains unchanged. Gas sufficiency, deployed
layout/code identity and compiled library execution are separate obligations. -/
theorem account_allocation_result
    (layout : LidoSRv3.Audit.Source.TrioAlloc1.Layout)
    (input : LidoSRv3.Audit.Source.TrioAlloc1.CapacityInput)
    (adversary : Compiler.CompilationModel.DenoteExternalCalls.AdversaryModel)
    (state : Compiler.CompilationModel.DenoteExternalCalls.CallState)
    (before : LidoSRv3.Audit.Source.TrioAlloc1.Transcript) :
    (LidoSRv3.Audit.Source.TrioAlloc1.VerityProducer.executeAccount
      layout input adversary state before).1 =
      LidoSRv3.Audit.Source.TrioAlloc1.produce layout
        (LidoSRv3.Audit.Source.TrioAlloc1.VerityProducer.accountStorage state.world)
        (LidoSRv3.Audit.Source.TrioAlloc1.VerityProducer.sourceOracle adversary state.world)
        input before ∧
    (LidoSRv3.Audit.Source.TrioAlloc1.VerityProducer.executeAccount
      layout input adversary state before).2.world = state.world ∧
    LidoSRv3.Audit.Source.TrioAlloc1.VerityProducer.AccountMathResult
      layout input adversary state before ∧
    (∀ amount,
      (LidoSRv3.Audit.Source.TrioComposition.VerityParentResult.execute
        layout input.config amount input.isTopUp adversary state before).1 =
        LidoSRv3.Audit.Source.TrioComposition.getDepositAllocationsABI layout
          (LidoSRv3.Audit.Source.TrioAlloc1.VerityProducer.accountStorage state.world)
          (LidoSRv3.Audit.Source.TrioAlloc1.VerityProducer.sourceOracle adversary state.world)
          input.config amount input.isTopUp before ∧
      (LidoSRv3.Audit.Source.TrioComposition.VerityParentResult.execute
        layout input.config amount input.isTopUp adversary state before).2.world = state.world) := by
  have h := LidoSRv3.Audit.Source.TrioAlloc1.VerityProducer.account_producer_correspondence
    layout input adversary state before
  exact ⟨h.1, h.2,
    LidoSRv3.Audit.Source.TrioAlloc1.VerityProducer.account_math_result
      layout input adversary state before,
    fun amount => LidoSRv3.Audit.Source.TrioComposition.VerityParentResult.execute_correspondence
      layout input.config amount input.isTopUp adversary state before⟩

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

open LidoSRv3.Audit.Verity.AllocationTx in
/-- **Chantier 3 (Piste A, 2026-09-13): Contract.run rollback for the
live-summary entry point.**  Every revert of
`allocateLiveFromStorage` — the historical entry point retained in
`verity_tx_simulates_allocation_count_from_storage`
— restores the pre-call snapshot.  Includes the injected late-
failure path exercised by `live_injected_after_writes_rolls_back`,
which fires after every summary/stake staticcall has bound its row
and after the allocation / capacity / address / total observation
writes have been requested; `Contract.run` still returns
`state = rollback` in that case.

This closes the P-ALLOC-1 fidelity.missing entry "Contract.run
rollback after intermediate writes for AllocationTx.allocate; the
cited revert_restores_snapshot theorem does not cover
allocateLiveFromStorage" — the registered parent now cites a
Contract.run rollback theorem that DOES cover
`allocateLiveFromStorage`, alongside the pre-existing coverage for
the legacy `allocate` planted-map entry point.

Underlying proof is `AllocationTx.live_revert_restores_snapshot`; this
theorem re-exports it under the P-ALLOC-1 namespace so downstream
consumers of the P-ALLOC-1 rollback obligation can name a live-plane
theorem without reaching into `Verity.AllocationTx`. -/
theorem verity_tx_live_revert_restores_snapshot
    (adversary :
      Compiler.CompilationModel.DenoteExternalCalls.AdversaryModel)
    (cfg : Config) (depositsToAllocate : Verity.Uint256)
    (isTopUp inject : Bool) (state rollback : Verity.ContractState)
    (reason : String)
    (h : (allocateLiveFromStorage adversary cfg depositsToAllocate isTopUp inject).run state =
      Verity.ContractResult.revert reason rollback) :
    rollback = state :=
  live_revert_restores_snapshot
    adversary cfg depositsToAllocate isTopUp inject state rollback reason h

end LidoSRv3.Audit.Guarantees.PAlloc1
