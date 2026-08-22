import LidoSRv3.Audit.Model.AllocCapacity
import LidoSRv3.Audit.Verity.AllocCapacityPhase3
import Verity.Core

/-!
# P-ALLOC-1 allocation transaction

Handwritten model of `SRLib._getModulesAllocationAndCapacity` from
`lidofinance/core@af095e48bbc1c3841c2c9936219c8461af01056b`, lines 493--559.

One interpreter (`AllocCapacity.firstLoop` / `secondLoop`). Binding follows
`getModuleIdAt` then the packed `moduleState.config`. `isActive` is
`StakingModuleStatus.Active` (`status == 0`); `isType2` is
`WithdrawalCredentials.isType2` (`wcType == 2`). The registered live path
executes the mapped selector-only static call, ABI-decodes its three uint256
return words, and threads them into the allocation loop. `getTotalModuleStake`
remains a planted word and is not claimed as a live call here.

Computed columns persist as storage arrays; `observe` reads those arrays.
-/

namespace LidoSRv3.Audit.Verity.AllocationTx

open _root_.Verity
open LidoSRv3.Audit.AllocCapacity

abbrev Word := Uint256

/-- `SRStorage.getModulesCount()`. The source caps this count by
`MAX_STAKING_MODULES_COUNT = 32` before walking router indices. -/
def modulesCountSlot : Nat := 29
/-- `SRStorage.getModuleIdAt(i)` — map from router index to module id. -/
def moduleIdSlot : Nat := 30
/-- Packed `ModuleStateConfig` keyed by module id. Solidity packs the address
in bits 0..159, then four uint16 fields, status in bits 224..231, and
withdrawal-credentials type in bits 232..239. -/
def moduleConfigSlot : Nat := 31
def accountingExitedSlot : Nat := 35
/-- Planted summaries remain only for the legacy/free-count sibling path and
test seeding. The registered live path does not read these three maps. -/
def summaryExitedSlot : Nat := 36
def summaryDepositedSlot : Nat := 37
def summaryDepositableSlot : Nat := 38
def summaryStakeSlot : Nat := 39
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

def sourceBindOne (state : ContractState) (index : Nat) : BoundModule :=
  let moduleId := state.readMapUint moduleIdSlot index
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
        | some summary => .success (withSummary base summary) afterCall
        | none => .revert "StakingModuleSummaryMalformedReturn" afterCall
    | .success _ afterCall => .revert "StakingModuleSummaryCallFailed" afterCall
    | .revert reason afterCall => .revert reason afterCall

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
    (hdecode : decodeSummary data = some summary) :
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
  simp only [bindLiveOne, hcall, hdecode]

/-- The single `_getModulesAllocationAndCapacity` interpreter. -/
def sourceExecute (cfg : Config) (modules : List BoundModule)
    (depositsToAllocate : Word) (isTopUp : Bool) : Option (List Row × Word) := do
  let (entries, total) ← AllocCapacity.firstLoop cfg (modules.map toSourceModule) depositsToAllocate
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

def allocate (count : Nat) (cfg : Config) (depositsToAllocate : Word)
    (isTopUp : Bool) (failAfterWrites : Bool := false) : Contract Result :=
  fun snapshot =>
    let modules := sourceBindAll snapshot count
    match sourceExecute cfg modules depositsToAllocate isTopUp with
    | none => .revert "ALLOC_ARITHMETIC" snapshot
    | some (rows, total) =>
        let addresses := modules.map BoundModule.moduleAddress
        let dirty := persistRows rows addresses snapshot
        let dirty := dirty.writeSlot totalSlot total
        if failAfterWrites then .revert "INJECTED_AFTER_WRITES" dirty
        else
          .success ⟨rows.map Row.currentAllocation, rows.map Row.capacity,
            addresses, total⟩ dirty

/-- Allocation entry point whose loop bound comes from router storage, capped
at the pinned `MAX_STAKING_MODULES_COUNT = 32`. -/
def allocateFromStorage (cfg : Config) (depositsToAllocate : Word)
    (isTopUp : Bool) (failAfterWrites : Bool := false) : Contract Result :=
  fun snapshot =>
    allocate (min (snapshot.readSlot modulesCountSlot).val 32)
      cfg depositsToAllocate isTopUp failAfterWrites snapshot

/-- Storage-counted allocation whose three summary fields come from the live
mapped call. This deliberately leaves the type-2 `getTotalModuleStake` word in
the router-local harness: P-ALLOC-1 does not claim that second call. -/
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
