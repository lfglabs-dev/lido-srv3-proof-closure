import LidoSRv3.Audit.Model.AllocCapacity
import Verity.Core

/-!
# P-ALLOC-1 allocation transaction

Handwritten model of `SRLib._getModulesAllocationAndCapacity` from
`lidofinance/core@af095e48bbc1c3841c2c9936219c8461af01056b`, lines 493--559.

One interpreter (`AllocCapacity.firstLoop` / `secondLoop`). Binding follows
`getModuleIdAt` then `moduleState.config`. `isActive` is
`StakingModuleStatus.Active` (`status == 0`); `isType2` is
`WithdrawalCredentials.isType2` (`wcType == 2`). Summaries are planted maps
keyed by `moduleAddress` (no live summary CALL).

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
/-- `ModuleStateConfig.moduleAddress` keyed by module id. -/
def moduleAddressSlot : Nat := 31
def shareLimitSlot : Nat := 32
def statusSlot : Nat := 33
def wcTypeSlot : Nat := 34
def accountingExitedSlot : Nat := 35
/-- Summaries are keyed by the bound module address, not the module id. -/
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
  let moduleAddress := state.readMapUint moduleAddressSlot moduleId
  { moduleId := moduleId
    moduleAddress := moduleAddress
    shareLimit := state.readMapUint shareLimitSlot moduleId
    isActive := state.readMapUint statusSlot moduleId == 0
    isType2 := state.readMapUint wcTypeSlot moduleId == 2
    accountingExitedCount := state.readMapUint accountingExitedSlot moduleId
    depositableCount := state.readMapUint summaryDepositableSlot moduleAddress
    depositedCount := state.readMapUint summaryDepositedSlot moduleAddress
    summaryExitedCount := state.readMapUint summaryExitedSlot moduleAddress
    totalModuleStake := state.readMapUint summaryStakeSlot moduleAddress }

def sourceBindAll (state : ContractState) (count : Nat) : List BoundModule :=
  (List.range count).map (sourceBindOne state)

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

theorem revert_restores_snapshot
    (count : Nat) (cfg : Config) (depositsToAllocate : Word) (isTopUp : Bool)
    (inject : Bool) (state rollback : ContractState) (reason : String)
    (h : (allocate count cfg depositsToAllocate isTopUp inject).run state =
      .revert reason rollback) : rollback = state := by
  unfold Contract.run at h
  split at h <;> simp_all

def seedOne (state : ContractState) (index : Nat) (m : BoundModule) : ContractState :=
  let state := state.writeMapUint moduleIdSlot index m.moduleId
  let state := state.writeMapUint moduleAddressSlot m.moduleId m.moduleAddress
  let state := state.writeMapUint shareLimitSlot m.moduleId m.shareLimit
  let state := state.writeMapUint statusSlot m.moduleId (if m.isActive then 0 else 1)
  let state := state.writeMapUint wcTypeSlot m.moduleId (if m.isType2 then 2 else 1)
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
