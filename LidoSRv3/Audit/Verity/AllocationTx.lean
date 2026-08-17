import LidoSRv3.Audit.Model.AllocCapacity
import Verity.Core

/-!
# P-ALLOC-1 faithful allocation transaction

This transaction models `SRLib._getModulesAllocationAndCapacity` from
`lidofinance/core@af095e48bbc1c3841c2c9936219c8461af01056b`, lines 493--559,
including the `moduleId → getIStakingModule()` address binding used by the
summary call at lines 512--514 / `SRStorage.sol:34--47`.

Router-ordered module ids and config live in maps keyed by `moduleId`.
Staking-module summaries are keyed by the bound `moduleAddress`. The
transaction therefore cannot observe a module's depositable/exited/stake
words without first reading that module's stored address.

Successful allocations, capacities and bound addresses are persisted through
`writeMapUint`; the accumulated validator total uses `writeSlot`.
-/

namespace LidoSRv3.Audit.Verity.AllocationTx

open _root_.Verity
open LidoSRv3.Audit.AllocCapacity

abbrev Word := Uint256

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

/-! ## Source-shaped binding: index → moduleId → moduleAddress → summary -/

def sourceBindOne (state : ContractState) (index : Nat) : BoundModule :=
  let moduleId := state.readMapUint moduleIdSlot index
  let moduleAddress := state.readMapUint moduleAddressSlot moduleId
  { moduleId := moduleId
    moduleAddress := moduleAddress
    shareLimit := state.readMapUint shareLimitSlot moduleId
    isActive := state.readMapUint statusSlot moduleId != 0
    isType2 := state.readMapUint wcTypeSlot moduleId != 0
    accountingExitedCount := state.readMapUint accountingExitedSlot moduleId
    depositableCount := state.readMapUint summaryDepositableSlot moduleAddress
    depositedCount := state.readMapUint summaryDepositedSlot moduleAddress
    summaryExitedCount := state.readMapUint summaryExitedSlot moduleAddress
    totalModuleStake := state.readMapUint summaryStakeSlot moduleAddress }

def sourceBindAll (state : ContractState) (count : Nat) : List BoundModule :=
  (List.range count).map (sourceBindOne state)

/-- Independent pinned-source executor: project away the address and run the
already-checked `AllocCapacity.execute` interpreter of lines 493--559. -/
def sourceExecute (cfg : Config) (modules : List BoundModule)
    (depositsToAllocate : Word) (isTopUp : Bool) : Option (List Row × Word) := do
  let (entries, total) ← AllocCapacity.firstLoop cfg (modules.map toSourceModule) depositsToAllocate
  let rows ← AllocCapacity.secondLoop cfg isTopUp total (modules.map toSourceModule) entries
  some (rows, total)

/-! ## Transaction-side binding and loops

These are deliberately not `sourceBind*` / `AllocCapacity.*`. The
correspondence theorems, not a shared definition, are the boundary.
-/

def txBindOne (state : ContractState) (index : Nat) : BoundModule :=
  let moduleId := state.readMapUint moduleIdSlot index
  let moduleAddress := state.readMapUint moduleAddressSlot moduleId
  { moduleId := moduleId
    moduleAddress := moduleAddress
    shareLimit := state.readMapUint shareLimitSlot moduleId
    isActive := state.readMapUint statusSlot moduleId != 0
    isType2 := state.readMapUint wcTypeSlot moduleId != 0
    accountingExitedCount := state.readMapUint accountingExitedSlot moduleId
    depositableCount := state.readMapUint summaryDepositableSlot moduleAddress
    depositedCount := state.readMapUint summaryDepositedSlot moduleAddress
    summaryExitedCount := state.readMapUint summaryExitedSlot moduleAddress
    totalModuleStake := state.readMapUint summaryStakeSlot moduleAddress }

def txBindAll (state : ContractState) (count : Nat) : List BoundModule :=
  (List.range count).map (txBindOne state)

def txWordMax (a b : Word) : Word := if a ≤ b then b else a
def txWordMin (a b : Word) : Word := if a ≤ b then a else b

def txActiveCount? (m : BoundModule) : Option Word :=
  Verity.Stdlib.Math.safeSub m.depositedCount
    (txWordMax m.summaryExitedCount m.accountingExitedCount)

def txCeilDiv? (a b : Word) : Option Word :=
  if b = 0 then none else some (Verity.Stdlib.Math.ceilDiv a b)

def txAllocationEntry? (cfg : Config) (m : BoundModule) : Option (Word × Word) := do
  let active ← txActiveCount? m
  let allocation ←
    if m.isType2 then txCeilDiv? m.totalModuleStake cfg.maxEBType1 else some active
  pure (allocation, active)

def txFirstLoop (cfg : Config) : List BoundModule → Word →
    Option (List (Word × Word) × Word)
  | [], total => some ([], total)
  | m :: ms, total => do
      let entry ← txAllocationEntry? cfg m
      let nextTotal ← Verity.Stdlib.Math.safeAdd total entry.1
      let (entries, finalTotal) ← txFirstLoop cfg ms nextTotal
      some (entry :: entries, finalTotal)

def txAvailableCapacity? (cfg : Config) (isTopUp : Bool) (m : BoundModule)
    (allocation active : Word) : Option Word :=
  if isTopUp && m.isType2 then do
    let weiCapacity ← Verity.Stdlib.Math.safeMul active cfg.maxEBType2
    Verity.Stdlib.Math.safeDiv weiCapacity cfg.maxEBType1
  else
    Verity.Stdlib.Math.safeAdd allocation m.depositableCount

def txTargetValidators? (total : Word) (m : BoundModule) : Option Word := do
  let numerator ← Verity.Stdlib.Math.safeMul m.shareLimit total
  Verity.Stdlib.Math.safeDiv numerator totalBasisPoints

def txSecondLoop (cfg : Config) (isTopUp : Bool) (total : Word) :
    List BoundModule → List (Word × Word) → Option (List Row)
  | [], [] => some []
  | m :: ms, entry :: entries => do
      let (allocation, active) := entry
      if m.isActive then
        let available ← txAvailableCapacity? cfg isTopUp m allocation active
        let target ← txTargetValidators? total m
        let rows ← txSecondLoop cfg isTopUp total ms entries
        some (({
          moduleId := m.moduleId
          currentAllocation := allocation
          capacity := txWordMin target available
          targetValidators := target
          activeCount := active
        } : Row) :: rows)
      else
        let rows ← txSecondLoop cfg isTopUp total ms entries
        some (({
          moduleId := m.moduleId
          currentAllocation := allocation
          capacity := allocation
          targetValidators := 0
          activeCount := active
        } : Row) :: rows)
  | _, _ => none

def txExecute (cfg : Config) (modules : List BoundModule)
    (depositsToAllocate : Word) (isTopUp : Bool) : Option (List Row × Word) := do
  let (entries, total) ← txFirstLoop cfg modules depositsToAllocate
  let rows ← txSecondLoop cfg isTopUp total modules entries
  some (rows, total)

theorem txBindOne_eq_sourceBindOne (state : ContractState) (index : Nat) :
    txBindOne state index = sourceBindOne state index := rfl

theorem txBindAll_eq_sourceBindAll (state : ContractState) (count : Nat) :
    txBindAll state count = sourceBindAll state count := by
  simp [txBindAll, sourceBindAll, txBindOne_eq_sourceBindOne]

theorem txWordMax_eq_wordMax (a b : Word) : txWordMax a b = wordMax a b := rfl
theorem txWordMin_eq_wordMin (a b : Word) : txWordMin a b = wordMin a b := rfl

theorem txActiveCount_eq_source (m : BoundModule) :
    txActiveCount? m = activeCount? (toSourceModule m) := by
  unfold txActiveCount? activeCount? toSourceModule txWordMax wordMax
  rfl

theorem txCeilDiv_eq_source (a b : Word) : txCeilDiv? a b = ceilDiv? a b := rfl

theorem txAllocationEntry_eq_source (cfg : Config) (m : BoundModule) :
    txAllocationEntry? cfg m = allocationEntry? cfg (toSourceModule m) := by
  simp [txAllocationEntry?, allocationEntry?, txActiveCount_eq_source,
    txCeilDiv_eq_source, toSourceModule]

theorem txFirstLoop_eq_source (cfg : Config) (modules : List BoundModule)
    (start : Word) :
    txFirstLoop cfg modules start =
      firstLoop cfg (modules.map toSourceModule) start := by
  induction modules generalizing start with
  | nil => simp [txFirstLoop, firstLoop]
  | cons m ms ih =>
      simp [txFirstLoop, firstLoop, txAllocationEntry_eq_source, ih]

theorem txAvailableCapacity_eq_source (cfg : Config) (isTopUp : Bool)
    (m : BoundModule) (allocation active : Word) :
    txAvailableCapacity? cfg isTopUp m allocation active =
      availableCapacity? cfg isTopUp (toSourceModule m) allocation active := by
  simp [txAvailableCapacity?, availableCapacity?, toSourceModule]

theorem txTargetValidators_eq_source (total : Word) (m : BoundModule) :
    txTargetValidators? total m = targetValidators? total (toSourceModule m) := by
  simp [txTargetValidators?, targetValidators?, toSourceModule]

theorem txSecondLoop_eq_source (cfg : Config) (isTopUp : Bool) (total : Word)
    (modules : List BoundModule) (entries : List (Word × Word)) :
    txSecondLoop cfg isTopUp total modules entries =
      secondLoop cfg isTopUp total (modules.map toSourceModule) entries := by
  induction modules generalizing entries with
  | nil =>
      cases entries with
      | nil => rfl
      | cons _ _ => rfl
  | cons m ms ih =>
      cases entries with
      | nil => rfl
      | cons entry entries =>
          simp [txSecondLoop, secondLoop, txAvailableCapacity_eq_source,
            txTargetValidators_eq_source, toSourceModule, txWordMin, wordMin, ih]

theorem txExecute_eq_sourceExecute (cfg : Config) (modules : List BoundModule)
    (depositsToAllocate : Word) (isTopUp : Bool) :
    txExecute cfg modules depositsToAllocate isTopUp =
      sourceExecute cfg modules depositsToAllocate isTopUp := by
  simp [txExecute, sourceExecute, txFirstLoop_eq_source, txSecondLoop_eq_source]

/-! ## Storage writes and the executable transaction -/

def writeRows : Nat → List Row → List Word → ContractState → ContractState
  | _, [], [], state => state
  | index, row :: rows, address :: addresses, state =>
      writeRows (index + 1) rows addresses
        (((state.writeMapUint allocationSlot index row.currentAllocation
          ).writeMapUint capacitySlot index row.capacity
          ).writeMapUint boundAddressSlot index address)
  | _, _, _, state => state

structure Result where
  allocations : List Word
  capacities : List Word
  moduleAddresses : List Word
  totalValidators : Word
  deriving DecidableEq, Repr

/-- Executable transaction. Checked-arithmetic failure reverts. `failAfterWrites`
is a test hook placed after the map/slot writes so rollback is proved even
after intermediate effects. -/
def allocate (count : Nat) (cfg : Config) (depositsToAllocate : Word)
    (isTopUp : Bool) (failAfterWrites : Bool := false) : Contract Result :=
  fun snapshot =>
    let modules := txBindAll snapshot count
    match txExecute cfg modules depositsToAllocate isTopUp with
    | none => .revert "ALLOC_ARITHMETIC" snapshot
    | some (rows, total) =>
        let addresses := modules.map BoundModule.moduleAddress
        let dirty := writeRows 0 rows addresses snapshot
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

/-- Outcome observables only. Reverts do not expose the mutated fields. -/
def observe (before : List BoundModule) : ContractResult Result → View
  | .success result state =>
      ⟨.committed, result.allocations, result.capacities, result.moduleAddresses,
        state.readSlot totalSlot⟩
  | .revert _ _ => ⟨.reverted, [], [], before.map BoundModule.moduleAddress, 0⟩

def sourceView (cfg : Config) (modules : List BoundModule)
    (depositsToAllocate : Word) (isTopUp : Bool) : View :=
  match sourceExecute cfg modules depositsToAllocate isTopUp with
  | none => ⟨.reverted, [], [], modules.map BoundModule.moduleAddress, 0⟩
  | some (rows, total) =>
      ⟨.committed, rows.map Row.currentAllocation, rows.map Row.capacity,
        modules.map BoundModule.moduleAddress, total⟩

/-- Composed faithful-plane theorem: the executable address-binding
transaction has the same outcome observables as the independently stated
pinned-source allocation loop. -/
theorem verity_tx_simulates_pinned_source
    (cfg : Config) (modules : List BoundModule) (depositsToAllocate : Word)
    (isTopUp : Bool) (state : ContractState)
    (hBind : sourceBindAll state modules.length = modules) :
    observe modules
        ((allocate modules.length cfg depositsToAllocate isTopUp).run state) =
      sourceView cfg modules depositsToAllocate isTopUp := by
  have hTx : txBindAll state modules.length = modules := by
    rwa [txBindAll_eq_sourceBindAll]
  unfold Contract.run allocate sourceView
  simp only [hTx]
  rw [txExecute_eq_sourceExecute]
  cases hRun : sourceExecute cfg modules depositsToAllocate isTopUp with
  | none => simp [observe]
  | some result =>
      rcases result with ⟨rows, total⟩
      simp [observe, totalSlot, ContractState.readSlot_writeSlot_same]

/-- Any failure, including the injected failure after the intermediate
allocation/capacity/address writes, returns the exact pre-transaction
snapshot. -/
theorem revert_restores_snapshot
    (count : Nat) (cfg : Config) (depositsToAllocate : Word) (isTopUp : Bool)
    (inject : Bool) (state rollback : ContractState) (reason : String)
    (h : (allocate count cfg depositsToAllocate isTopUp inject).run state =
      .revert reason rollback) : rollback = state := by
  unfold Contract.run at h
  split at h <;> simp_all

/-! ## Seeding helper used by mutants and concrete vectors -/

def seedOne (state : ContractState) (index : Nat) (m : BoundModule) : ContractState :=
  let state := state.writeMapUint moduleIdSlot index m.moduleId
  let state := state.writeMapUint moduleAddressSlot m.moduleId m.moduleAddress
  let state := state.writeMapUint shareLimitSlot m.moduleId m.shareLimit
  let state := state.writeMapUint statusSlot m.moduleId (if m.isActive then 1 else 0)
  let state := state.writeMapUint wcTypeSlot m.moduleId (if m.isType2 then 1 else 0)
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
