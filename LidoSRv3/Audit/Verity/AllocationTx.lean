import LidoSRv3.Audit.Model.AllocCapacity
import LidoSRv3.Audit.Verity.AllocCapacityPhase3
import Verity.Core

/-!
# P-ALLOC-1 allocation transaction

Handwritten model of `SRLib._getModulesAllocationAndCapacity` from
`lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`, `SRLib.sol:493-559`,
wrapped as the storage-counted transaction `StakingRouter.getDepositAllocations`
(`StakingRouter.sol:929-936`, see the `getDepositAllocations` abbrev below).

## Name table (C4)

| Solidity (`SRLib.sol`)                      | Lean                                   |
|---------------------------------------------|----------------------------------------|
| `_allocations[i]` (line 531)                | `Row.currentAllocation`, `Result.allocations` |
| `_capacities[i]` (line 557)                 | `Row.capacity`, `Result.capacities`    |
| `totalValidators` (lines 506, 532)          | `total` in `sourceExecute`, `Result.totalValidators` |
| `cache[i].activeCount` (line 525)           | `Row.activeCount`                      |
| `targetValidators` (line 552)               | `Row.targetValidators`                 |
| `depositsToAllocate` (line 493)             | `depositsToAllocate`                   |

## Not transcribed: SRLib.sol:403-427

`_getDepositAllocations` (`SRLib.sol:391-431`) is the caller of the transcribed
function. Its wei-to-validator conversion `depositsToAllocate = _allocateAmount / initialDeposit`
(line 404), the `modulesCount == 0` early return (lines 397-399), the
`MinFirstAllocationStrategy.allocate(allocated, capacities, depositsToAllocate)`
call (line 415, guarantee P-ALLOC-2), and the validator-to-wei conversions of
lines 417-421 and 424-429 are outside this transaction: the model takes
`depositsToAllocate` already in validator units and returns the validator-unit
columns of `_getModulesAllocationAndCapacity`.

One interpreter (`AllocCapacity.firstLoop` / `secondLoop`). Binding follows
`getModuleIdAt` then the packed `moduleState.config`. `isActive` is
`StakingModuleStatus.Active` (`status == 0`); `isType2` is
`WithdrawalCredentials.isType2` (`wcType == 2`). The registered live path
executes the mapped selector-only summary static call, ABI-decodes its three
uint256 return words, and on type-2 rows executes the distinct pinned
`getTotalModuleStake` static call before entering the allocation loop.

Computed columns persist as storage arrays; `observe` reads those arrays.
-/

namespace LidoSRv3.Audit.Verity.AllocationTx

open _root_.Verity
open LidoSRv3.Audit.AllocCapacity

abbrev Word := Uint256

/-! ## Router storage read by SRLib.sol:498-522 -/

/-- `SRStorage.getModulesCount()` (`SRLib.sol:498`). The source caps this count by
`MAX_STAKING_MODULES_COUNT = 32` before walking router indices. -/
def modulesCountSlot : Nat := 29
/-- `SRStorage.getModuleIdAt(i)` (`SRLib.sol:509`), map from router index to module id. -/
def moduleIdSlot : Nat := 30
/-- Packed `ModuleStateConfig` keyed by module id. Solidity packs the address
in bits 0..159, then four uint16 fields, status in bits 224..231, and
withdrawal-credentials type in bits 232..239. -/
def moduleConfigSlot : Nat := 31
/-- `moduleState.accounting.exitedValidatorsCount` (`SRLib.sol:522`). -/
def accountingExitedSlot : Nat := 35
/-- Planted summaries remain only for the legacy/free-count sibling path and
test seeding. The registered live path does not read these three maps. -/
def summaryExitedSlot : Nat := 36
def summaryDepositedSlot : Nat := 37
def summaryDepositableSlot : Nat := 38
def summaryStakeSlot : Nat := 39
/-- Observation slots, no Solidity storage counterpart: `_allocations`,
`_capacities` and `totalValidators` are memory in `SRLib.sol:499,534,506`;
the model persists them so `observe` can read the committed columns. -/
def allocationSlot : Nat := 40
def capacitySlot : Nat := 41
def boundAddressSlot : Nat := 42
def totalSlot : Nat := 43

/-- One router-ordered module after the `getIStakingModule` binding. -/
structure BoundModule where
  moduleId : Word
  moduleAddress : Word
  shareLimit : Word
  isActive : Bool
  isType2 : Bool
  depositableCount : Word
  depositedCount : Word
  summaryExitedCount : Word
  accountingExitedCount : Word
  totalModuleStake : Word
  deriving DecidableEq, Repr

structure DecodedSummary where
  exitedCount : Word
  depositedCount : Word
  depositableCount : Word
  deriving DecidableEq, Repr

/-- `bytes4(keccak256("getTotalModuleStake()"))`, pinned to
`IStakingModuleV2` at the source revision named in `audit/source-map.yaml`.
Unlike the summary tuple, this call is made only for WC type-2 rows. -/
def totalStakeSelector : Nat := 0x0c852f5c
def totalStakeCalldata : List Nat := [0x0c, 0x85, 0x2f, 0x5c]
def totalStakeReturnBytes : Nat := 32

/-- The second source call in the WC02 branch. It is deliberately a distinct
site from `getStakingModuleSummary`: sharing the address does not make the
returndata interchangeable. -/
def sourceTotalStakeSite (moduleAddress : Nat) :
    Compiler.CompilationModel.DenoteExternalCalls.CallSite :=
  { siteId := 1, kind := .staticcall, target := moduleAddress, value := 0
    calldata := totalStakeCalldata
    gas := _root_.LidoSRv3.Audit.Verity.AllocCapacityPhase3.maxGas }

/-- ABI uint256 decoding is big-endian over one 32-byte returndata word.
`ExternalCallResult` exposes bytes as `Nat`, so `% 256` records their byte
semantics explicitly. -/
def decodeUint256At (data : List Nat) (offset : Nat) : Word :=
  Verity.Core.Uint256.ofNat (((data.drop offset).take 32).foldl
    (fun acc byte => acc * 256 + byte % 256) 0)

/-- `IStakingModule.getStakingModuleSummary()` returns exactly three ABI
uint256 words in source order: exited, deposited, depositable. Solidity accepts
trailing returndata, so the checked guard is `96 ≤ returndata.length`. -/
def decodeSummary (data : List Nat) : Option DecodedSummary :=
  if 96 ≤ data.length then
    some
      { exitedCount := decodeUint256At data 0
        depositedCount := decodeUint256At data 32
        depositableCount := decodeUint256At data 64 }
  else none

/-- ABI-decode the one `uint256` returned by `getTotalModuleStake`. Solidity
accepts trailing bytes, but a short result fails closed. -/
def decodeTotalStake (data : List Nat) : Option Word :=
  if totalStakeReturnBytes ≤ data.length then some (decodeUint256At data 0) else none

def configModuleAddress (packed : Word) : Word :=
  Verity.Core.Uint256.ofNat (packed.val % 2 ^ 160)

def configShareLimit (packed : Word) : Word :=
  Verity.Core.Uint256.ofNat (packed.val / 2 ^ 192 % 2 ^ 16)

def configStatus (packed : Word) : Nat :=
  packed.val / 2 ^ 224 % 2 ^ 8

def configWcType (packed : Word) : Nat :=
  packed.val / 2 ^ 232 % 2 ^ 8

def packConfig (m : BoundModule) : Word :=
  Verity.Core.Uint256.ofNat
    (m.moduleAddress.val % 2 ^ 160 +
      (m.shareLimit.val % 2 ^ 16) * 2 ^ 192 +
      (if m.isActive then 0 else 1) * 2 ^ 224 +
      (if m.isType2 then 2 else 1) * 2 ^ 232)

def toSourceModule (m : BoundModule) : Module :=
  { moduleId := m.moduleId
    shareLimit := m.shareLimit
    isActive := m.isActive
    isType2 := m.isType2
    depositableCount := m.depositableCount
    depositedCount := m.depositedCount
    summaryExitedCount := m.summaryExitedCount
    accountingExitedCount := m.accountingExitedCount
    totalModuleStake := m.totalModuleStake }

/-! ## First-loop bindings (SRLib.sol:509-518, hoisted out of the loop) -/

/-- Planted-summary binding of one router row (`SRLib.sol:509-517` with the
summary tuple read from seeded maps instead of a call). -/
def sourceBindOne (state : ContractState) (index : Nat) : BoundModule :=
  -- SRLib.sol:509  uint256 moduleId = SRStorage.getModuleIdAt(i);
  let moduleId := state.readMapUint moduleIdSlot index
  -- SRLib.sol:510-511  moduleState = moduleId.getModuleState(); stateConfig = moduleState.config;
  let packed := state.readMapUint moduleConfigSlot moduleId
  let moduleAddress := configModuleAddress packed
  { moduleId := moduleId
    moduleAddress := moduleAddress
    shareLimit := configShareLimit packed
    isActive := configStatus packed == 0
    isType2 := configWcType packed == 2
    accountingExitedCount := state.readMapUint accountingExitedSlot moduleId
    depositableCount := state.readMapUint summaryDepositableSlot moduleAddress
    depositedCount := state.readMapUint summaryDepositedSlot moduleAddress
    summaryExitedCount := state.readMapUint summaryExitedSlot moduleAddress
    totalModuleStake := state.readMapUint summaryStakeSlot moduleAddress }

def sourceBindAll (state : ContractState) (count : Nat) : List BoundModule :=
  (List.range count).map (sourceBindOne state)

/-- Bind only router-owned fields. The summary fields are overwritten from
live returndata before this value can reach the allocation loop. -/
def sourceBindConfigOne (state : ContractState) (index : Nat) : BoundModule :=
  let moduleId := state.readMapUint moduleIdSlot index
  let packed := state.readMapUint moduleConfigSlot moduleId
  { moduleId := moduleId
    moduleAddress := configModuleAddress packed
    shareLimit := configShareLimit packed
    isActive := configStatus packed == 0
    isType2 := configWcType packed == 2
    accountingExitedCount := state.readMapUint accountingExitedSlot moduleId
    depositableCount := 0
    depositedCount := 0
    summaryExitedCount := 0
    totalModuleStake := state.readMapUint summaryStakeSlot (configModuleAddress packed) }

def withSummary (m : BoundModule) (summary : DecodedSummary) : BoundModule :=
  { m with
    depositableCount := summary.depositableCount
    depositedCount := summary.depositedCount
    summaryExitedCount := summary.exitedCount }

def withTotalStake (m : BoundModule) (stake : Word) : BoundModule :=
  { m with totalModuleStake := stake }

/-- Execute the exact type-2 static-call boundary and retain its returndata.
The wrapper is separate from the summary-call adapter because the pinned
source makes this second call only on the WC02 branch. -/
def executeMappedTotalStakeResult
    (adversary : Compiler.CompilationModel.DenoteExternalCalls.AdversaryModel)
    (moduleAddress : Nat) : Contract (Option Compiler.CompilationModel.DenoteExternalCalls.ExternalCallResult) :=
  fun state => .success (some (adversary.result (sourceTotalStakeSite moduleAddress) state)) state

/-- Execute and consume the source-derived mapped summary call for one packed
router row. A reverted call or short returndata fails closed. -/
def bindLiveOne
    (adversary : Compiler.CompilationModel.DenoteExternalCalls.AdversaryModel)
    (snapshot : ContractState) (index : Nat) : Contract BoundModule :=
  fun state =>
    let base := sourceBindConfigOne snapshot index
    match
      (_root_.LidoSRv3.Audit.Verity.AllocCapacityPhase3.executeMappedSummaryResult
        adversary base.moduleAddress.val) state with
    | .success (some (.success data)) afterCall =>
        match decodeSummary data with
        | some summary =>
            let bound := withSummary base summary
            if bound.isType2 then
              match (executeMappedTotalStakeResult adversary bound.moduleAddress.val) afterCall with
              | .success (some (.success stakeData)) afterStake =>
                  match decodeTotalStake stakeData with
                  | some stake => .success (withTotalStake bound stake) afterStake
                  | none => .revert "TotalModuleStakeMalformedReturn" afterStake
              | .success _ afterStake => .revert "TotalModuleStakeCallFailed" afterStake
              | .revert reason afterStake => .revert reason afterStake
            else .success bound afterCall
        | none => .revert "StakingModuleSummaryMalformedReturn" afterCall
    | .success _ afterCall => .revert "StakingModuleSummaryCallFailed" afterCall
    | .revert reason afterCall => .revert reason afterCall

/-- Live binding of the router prefix `[index, index + count)`.

Split loop: Solidity makes the `_getStakingModuleSummary` call (`SRLib.sol:516-517`)
and the type-2 `getTotalModuleStake()` call (`SRLib.sol:529`) inside the first
allocation loop (`SRLib.sol:508-533`), interleaved with the arithmetic of lines
521-532. The Lean model runs all the calls first, in the same router order, and
only then executes `sourceExecute` over the bound rows. The two orders are
observationally equal because the calls are `staticcall`s (no state written
between iterations) and the loop arithmetic does not feed back into the call
arguments. -/
def bindLiveAll
    (adversary : Compiler.CompilationModel.DenoteExternalCalls.AdversaryModel)
    (snapshot : ContractState) : Nat → Nat → Contract (List BoundModule)
  | _, 0 => _root_.Verity.pure []
  | index, count + 1 => do
      let module ← bindLiveOne adversary snapshot index
      let rest ← bindLiveAll adversary snapshot (index + 1) count
      _root_.Verity.pure (module :: rest)

/-- One-call decode bridge. The premise names the exact source-derived call
site and the conclusion exposes the `BoundModule` consumed by allocation. -/
theorem bindLiveOne_decodes_summary
    (adversary : Compiler.CompilationModel.DenoteExternalCalls.AdversaryModel)
    (state : ContractState) (index : Nat) (data : List Nat)
    (summary : DecodedSummary)
    (hresult : adversary.result
      (_root_.LidoSRv3.Audit.Verity.AllocCapacityPhase3.sourceSummarySite
        (sourceBindConfigOne state index).moduleAddress.val) state =
      .success data)
    (hdecode : decodeSummary data = some summary)
    (htype1 : (sourceBindConfigOne state index).isType2 = false) :
    (bindLiveOne adversary state index) state =
      .success (withSummary (sourceBindConfigOne state index) summary) state := by
  have hcall :
      (_root_.LidoSRv3.Audit.Verity.AllocCapacityPhase3.executeMappedSummaryResult
        adversary (sourceBindConfigOne state index).moduleAddress.val) state =
      ContractResult.success (some (.success data)) state := by
    change ContractResult.success
      (some (adversary.result
        (_root_.LidoSRv3.Audit.Verity.AllocCapacityPhase3.sourceSummarySite
          (sourceBindConfigOne state index).moduleAddress.val) state)) state = _
    rw [hresult]
  simp [bindLiveOne, hcall, hdecode, withSummary, htype1]

/-! ## SRLib._getModulesAllocationAndCapacity (SRLib.sol:493-559) -/

/-- The single `_getModulesAllocationAndCapacity` interpreter: transcribes
`SRLib.sol:493-559` (not the caller `_getDepositAllocations`, `SRLib.sol:391-431`).
Same shape as `AllocCapacity.execute`, additionally returning the final
`totalValidators` word. -/
def sourceExecute (cfg : Config) (modules : List BoundModule)
    (depositsToAllocate : Word) (isTopUp : Bool) : Option (List Row × Word) := do
  -- SRLib.sol:505-533  uint256 totalValidators = depositsToAllocate;  then the first loop
  let (entries, total) ← AllocCapacity.firstLoop cfg (modules.map toSourceModule) depositsToAllocate
  -- SRLib.sol:539-558  second loop
  let rows ← AllocCapacity.secondLoop cfg isTopUp total (modules.map toSourceModule) entries
  some (rows, total)

/-- Persist computed columns as `uint256[]`-shaped storage arrays. -/
def persistRows (rows : List Row) (addrs : List Word) (state : ContractState) :
    ContractState :=
  ((state.writeArray allocationSlot (rows.map Row.currentAllocation)
    ).writeArray capacitySlot (rows.map Row.capacity)
    ).writeArray boundAddressSlot addrs

structure Result where
  allocations : List Word
  capacities : List Word
  moduleAddresses : List Word
  totalValidators : Word
  deriving DecidableEq, Repr

/-- `SRLib.sol:493-559` as a transaction over `count` planted router rows.

Not transcribed: `SRLib.sol:498` (`modulesCount` is the `count` argument here;
`allocateFromStorage` reads it), the external calls of lines 516-517 and 529
(planted maps, see `allocateLiveFromStorage` for the live version).

Added by the model: revert string `"ALLOC_ARITHMETIC"` for any checked
arithmetic failure (Solidity panics with `Panic(0x11)`/`Panic(0x12)`),
persisted observation slots, and the `failAfterWrites` rollback hook. -/
def allocate (count : Nat) (cfg : Config) (depositsToAllocate : Word)
    (isTopUp : Bool) (failAfterWrites : Bool := false) : Contract Result :=
  fun snapshot =>
    -- SRLib.sol:508-518  per-row storage reads and summary tuple (hoisted, see bindLiveAll)
    let modules := sourceBindAll snapshot count
    -- SRLib.sol:506-558  both loops
    match sourceExecute cfg modules depositsToAllocate isTopUp with
    | none => .revert "ALLOC_ARITHMETIC" snapshot
    | some (rows, total) =>
        let addresses := modules.map BoundModule.moduleAddress
        -- SRLib.sol:531, 557  _allocations[i] / _capacities[i] (persisted as observation arrays)
        let dirty := persistRows rows addresses snapshot
        let dirty := dirty.writeSlot totalSlot total
        if failAfterWrites then .revert "INJECTED_AFTER_WRITES" dirty
        else
          .success ⟨rows.map Row.currentAllocation, rows.map Row.capacity,
            addresses, total⟩ dirty

/-- Allocation entry point whose loop bound comes from router storage, capped
at the pinned `MAX_STAKING_MODULES_COUNT = 32`. This is the storage-counted
shape of `StakingRouter.getDepositAllocations` (`StakingRouter.sol:929-936`)
restricted to the `_getModulesAllocationAndCapacity` step (see the module
header, "Not transcribed: SRLib.sol:403-427"). -/
def allocateFromStorage (cfg : Config) (depositsToAllocate : Word)
    (isTopUp : Bool) (failAfterWrites : Bool := false) : Contract Result :=
  fun snapshot =>
    -- SRLib.sol:498  uint256 modulesCount = SRStorage.getModulesCount();
    allocate (min (snapshot.readSlot modulesCountSlot).val 32)
      cfg depositsToAllocate isTopUp failAfterWrites snapshot

/-- Solidity-facing name, `StakingRouter.sol:929-936`
`getDepositAllocations(uint256 _depositAmount, bool _isTopUp)`, which forwards to
`SRLib._getDepositAllocations` (`SRLib.sol:391-431`) and through it to
`_getModulesAllocationAndCapacity` (`SRLib.sol:493-559`, line 408). Only the
latter step is modelled; proofs unfold `allocateFromStorage`. -/
abbrev getDepositAllocations := allocateFromStorage

/-- Storage-counted allocation whose summary fields and type-2 stake word come
from the live pinned calls (`SRLib.sol:516-517` and `SRLib.sol:529`, executed up
front by `bindLiveAll`). -/
def allocateLiveFromStorage
    (adversary : Compiler.CompilationModel.DenoteExternalCalls.AdversaryModel)
    (cfg : Config) (depositsToAllocate : Word)
    (isTopUp : Bool) (failAfterWrites : Bool := false) : Contract Result :=
  fun snapshot =>
    let count := min (snapshot.readSlot modulesCountSlot).val 32
    match (bindLiveAll adversary snapshot 0 count) snapshot with
    | .revert reason dirty => .revert reason dirty
    | .success modules afterCalls =>
        match sourceExecute cfg modules depositsToAllocate isTopUp with
        | none => .revert "ALLOC_ARITHMETIC" afterCalls
        | some (rows, total) =>
            let addresses := modules.map BoundModule.moduleAddress
            let dirty := persistRows rows addresses afterCalls
            let dirty := dirty.writeSlot totalSlot total
            if failAfterWrites then .revert "INJECTED_AFTER_WRITES" dirty
            else
              .success ⟨rows.map Row.currentAllocation, rows.map Row.capacity,
                addresses, total⟩ dirty

inductive Status where | committed | reverted deriving DecidableEq, Repr

structure View where
  status : Status
  allocations : List Word
  capacities : List Word
  moduleAddresses : List Word
  totalValidators : Word
  deriving DecidableEq, Repr

/-- Success reads the persisted arrays, not the `Result` payload. -/
def observe (before : List BoundModule) : ContractResult Result → View
  | .success _ state =>
      ⟨.committed, state.readArray allocationSlot, state.readArray capacitySlot,
        state.readArray boundAddressSlot, state.readSlot totalSlot⟩
  | .revert _ _ => ⟨.reverted, [], [], before.map BoundModule.moduleAddress, 0⟩

def sourceView (cfg : Config) (modules : List BoundModule)
    (depositsToAllocate : Word) (isTopUp : Bool) : View :=
  match sourceExecute cfg modules depositsToAllocate isTopUp with
  | none => ⟨.reverted, [], [], modules.map BoundModule.moduleAddress, 0⟩
  | some (rows, total) =>
      ⟨.committed, rows.map Row.currentAllocation, rows.map Row.capacity,
        modules.map BoundModule.moduleAddress, total⟩

private theorem persistRows_read (rows : List Row) (addrs : List Word)
    (state : ContractState) :
    (persistRows rows addrs state).readArray allocationSlot =
      rows.map Row.currentAllocation ∧
    (persistRows rows addrs state).readArray capacitySlot =
      rows.map Row.capacity ∧
    (persistRows rows addrs state).readArray boundAddressSlot = addrs := by
  unfold persistRows ContractState.readArray ContractState.writeArray
  simp [allocationSlot, capacitySlot, boundAddressSlot]

theorem verity_tx_simulates_pinned_source
    (cfg : Config) (modules : List BoundModule) (depositsToAllocate : Word)
    (isTopUp : Bool) (state : ContractState)
    (hBind : sourceBindAll state modules.length = modules) :
    observe modules
        ((allocate modules.length cfg depositsToAllocate isTopUp).run state) =
      sourceView cfg modules depositsToAllocate isTopUp := by
  unfold Contract.run allocate sourceView
  simp only [hBind]
  cases hRun : sourceExecute cfg modules depositsToAllocate isTopUp with
  | none => simp [observe]
  | some result =>
      rcases result with ⟨rows, total⟩
      have hread := persistRows_read rows (modules.map BoundModule.moduleAddress) state
      simp [observe, ContractState.readArray, totalSlot,
        ContractState.readSlot_writeSlot_same, ContractState.storageArray_writeSlot]
      exact hread

/-- The transaction and specification bind exactly the router prefix selected
by the storage-backed, 32-capped module count. No caller-supplied count
hypothesis is needed. -/
theorem verity_tx_simulates_allocation_count_from_storage
    (cfg : Config) (depositsToAllocate : Word) (isTopUp : Bool)
    (state : ContractState) :
    let count := min (state.readSlot modulesCountSlot).val 32
    let modules := sourceBindAll state count
    observe modules ((allocateFromStorage cfg depositsToAllocate isTopUp).run state) =
      sourceView cfg modules depositsToAllocate isTopUp := by
  dsimp [allocateFromStorage]
  change observe (sourceBindAll state (min (state.readSlot modulesCountSlot).val 32))
      ((allocate (min (state.readSlot modulesCountSlot).val 32)
        cfg depositsToAllocate isTopUp).run state) =
    sourceView cfg (sourceBindAll state (min (state.readSlot modulesCountSlot).val 32))
      depositsToAllocate isTopUp
  simpa [sourceBindAll] using
    (verity_tx_simulates_pinned_source cfg
      (sourceBindAll state (min (state.readSlot modulesCountSlot).val 32))
      depositsToAllocate isTopUp state (by simp [sourceBindAll]))

/-- Live-summary correspondence: when the mapped call loop ABI-decodes to the
source-view module rows, those decoded fields, not planted summary maps, drive
the persisted allocation/capacity observation. -/
theorem verity_tx_simulates_live_summary_from_storage
    (adversary : Compiler.CompilationModel.DenoteExternalCalls.AdversaryModel)
    (cfg : Config) (modules : List BoundModule) (depositsToAllocate : Word)
    (isTopUp : Bool) (state : ContractState)
    (hLength : modules.length =
      min (state.readSlot modulesCountSlot).val 32)
    (hBind : (bindLiveAll adversary state 0 modules.length) state =
      .success modules state) :
    observe modules
        ((allocateLiveFromStorage adversary cfg depositsToAllocate isTopUp).run state) =
      sourceView cfg modules depositsToAllocate isTopUp := by
  unfold Contract.run allocateLiveFromStorage sourceView
  simp only [← hLength, hBind]
  cases hRun : sourceExecute cfg modules depositsToAllocate isTopUp with
  | none => simp [observe]
  | some result =>
      rcases result with ⟨rows, total⟩
      have hread := persistRows_read rows (modules.map BoundModule.moduleAddress) state
      simp [observe, ContractState.readArray, totalSlot,
        ContractState.readSlot_writeSlot_same, ContractState.storageArray_writeSlot]
      exact hread

theorem revert_restores_snapshot
    (count : Nat) (cfg : Config) (depositsToAllocate : Word) (isTopUp : Bool)
    (inject : Bool) (state rollback : ContractState) (reason : String)
    (h : (allocate count cfg depositsToAllocate isTopUp inject).run state =
      .revert reason rollback) : rollback = state := by
  unfold Contract.run at h
  split at h <;> simp_all

/-! ## Test seeding (not source) -/

def seedOne (state : ContractState) (index : Nat) (m : BoundModule) : ContractState :=
  let state := state.writeMapUint moduleIdSlot index m.moduleId
  let state := state.writeMapUint moduleConfigSlot m.moduleId (packConfig m)
  let state := state.writeMapUint accountingExitedSlot m.moduleId m.accountingExitedCount
  let state := state.writeMapUint summaryExitedSlot m.moduleAddress m.summaryExitedCount
  let state := state.writeMapUint summaryDepositedSlot m.moduleAddress m.depositedCount
  let state := state.writeMapUint summaryDepositableSlot m.moduleAddress m.depositableCount
  state.writeMapUint summaryStakeSlot m.moduleAddress m.totalModuleStake

def seedAll : Nat → List BoundModule → ContractState → ContractState
  | _, [], state => state
  | index, m :: rest, state => seedAll (index + 1) rest (seedOne state index m)

def stateFor (modules : List BoundModule) (base : ContractState := defaultState) :
    ContractState :=
  seedAll 0 modules base

end LidoSRv3.Audit.Verity.AllocationTx
