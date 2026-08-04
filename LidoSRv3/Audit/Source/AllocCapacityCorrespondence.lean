import LidoSRv3.Audit.Model.AllocCapacity

/-!
Pinned Solidity correspondence for Lido core
`af095e48bbc1c3841c2c9936219c8461af01056b`.

The canonical model's `execute` is deliberately source-shaped: `firstLoop`
encodes `SRLib.sol` lines 506--532 and `secondLoop` lines 539--558. The aliases
in this module name the source interpretation separately so the correspondence
claim cannot silently drift to a different implementation.

Pinned transitive spans:

* `StakingRouter.sol:929--936`, `getDepositAllocations` router entry;
* `SRLib.sol:391--431`, `_getDepositAllocations` caller;
* `SRLib.sol:493--559`, `_getModulesAllocationAndCapacity`;
* `SRLib.sol:516--517`, `_getStakingModuleSummary` result interface;
* `SRUtils.sol:17`, `TOTAL_BASIS_POINTS = 10000`;
* `SRStorage.sol`, `getModulesCount` and `getModuleIdAt` router-order helpers;
* `WithdrawalCredentials.sol`, `isType2` credential guard;
* OpenZeppelin Contracts v5.2 `Math.max`, `Math.min`, and `Math.ceilDiv`.

Array allocation, storage/external-call success, and interface fidelity remain
source boundary facts. Arithmetic inside the pinned function is not abstracted:
Solidity checked operations use Verity `safe*`; OpenZeppelin's internally
unchecked `ceilDiv` uses Verity's pinned `ceilDiv` with an explicit zero-divisor
revert boundary.
-/

namespace LidoSRv3.Audit.SolidityAllocCapacity

open LidoSRv3.Audit.AllocCapacity
open Verity
open Verity.Stdlib.Math

abbrev SourceModule := AllocCapacity.Module
abbrev SourceConfig := AllocCapacity.Config

/- The definitions below deliberately restate the pinned function instead of
aliasing the canonical executor.  They share only the narrow input/output
records, so changing either loop independently makes the correspondence proof
fail (and makes the concrete source mutants below observable). -/

def sourceMax (a b : Uint256) : Uint256 := if a ≤ b then b else a
def sourceMin (a b : Uint256) : Uint256 := if a ≤ b then a else b

def sourceActiveCount? (m : SourceModule) : Option Uint256 :=
  safeSub m.depositedCount (sourceMax m.summaryExitedCount m.accountingExitedCount)

def sourceCeilDiv? (a b : Uint256) : Option Uint256 :=
  if b = 0 then none else some (ceilDiv a b)

def sourceAllocationEntry? (cfg : SourceConfig) (m : SourceModule) :
    Option (Uint256 × Uint256) := do
  let active ← sourceActiveCount? m
  let allocation ←
    if m.isType2 then sourceCeilDiv? m.totalModuleStake cfg.maxEBType1 else some active
  pure (allocation, active)

/-- Direct interpretation of source lines 506--532. -/
def sourceFirstLoop (cfg : SourceConfig) : List SourceModule → Uint256 →
    Option (List (Uint256 × Uint256) × Uint256)
  | [], total => some ([], total)
  | m :: ms, total => do
      let entry ← sourceAllocationEntry? cfg m
      let nextTotal ← safeAdd total entry.1
      let (entries, finalTotal) ← sourceFirstLoop cfg ms nextTotal
      pure (entry :: entries, finalTotal)

def sourceAvailableCapacity? (cfg : SourceConfig) (isTopUp : Bool) (m : SourceModule)
    (allocation active : Uint256) : Option Uint256 :=
  if isTopUp && m.isType2 then do
    let weiCapacity ← safeMul active cfg.maxEBType2
    safeDiv weiCapacity cfg.maxEBType1
  else
    safeAdd allocation m.depositableCount

def sourceTargetValidators? (total : Uint256) (m : SourceModule) : Option Uint256 := do
  let numerator ← safeMul m.shareLimit total
  safeDiv numerator 10000

/-- Direct interpretation of source lines 539--558. -/
def sourceSecondLoop (cfg : SourceConfig) (isTopUp : Bool) (total : Uint256) :
    List SourceModule → List (Uint256 × Uint256) → Option (List AllocCapacity.Row)
  | [], [] => some []
  | m :: ms, entry :: entries => do
      let (allocation, active) := entry
      if m.isActive then
        let available ← sourceAvailableCapacity? cfg isTopUp m allocation active
        let target ← sourceTargetValidators? total m
        let rows ← sourceSecondLoop cfg isTopUp total ms entries
        pure ((⟨m.moduleId, allocation, sourceMin target available, target, active⟩ :
          AllocCapacity.Row) :: rows)
      else
        let rows ← sourceSecondLoop cfg isTopUp total ms entries
        pure ((⟨m.moduleId, allocation, allocation, 0, active⟩ : AllocCapacity.Row) :: rows)
  | _, _ => none

/-- Independent checked interpretation of the pinned source span. -/
def execute (cfg : SourceConfig) (modules : List SourceModule)
    (depositsToAllocate : Uint256) (isTopUp : Bool) : Option (List AllocCapacity.Row) := do
  let (entries, total) ← sourceFirstLoop cfg modules depositsToAllocate
  sourceSecondLoop cfg isTopUp total modules entries

private theorem sourceAllocationEntry_eq (cfg : SourceConfig) (m : SourceModule) :
    sourceAllocationEntry? cfg m = AllocCapacity.allocationEntry? cfg m := by
  simp [sourceAllocationEntry?, sourceActiveCount?, sourceMax, sourceCeilDiv?,
    AllocCapacity.allocationEntry?, AllocCapacity.activeCount?, AllocCapacity.wordMax,
    AllocCapacity.ceilDiv?]

private theorem sourceFirstLoop_eq (cfg : SourceConfig) (modules : List SourceModule)
    (total : Uint256) :
    sourceFirstLoop cfg modules total = AllocCapacity.firstLoop cfg modules total := by
  induction modules generalizing total with
  | nil => rfl
  | cons m ms ih =>
      simp [sourceFirstLoop, AllocCapacity.firstLoop, sourceAllocationEntry_eq, ih]

private theorem sourceAvailableCapacity_eq (cfg : SourceConfig) (isTopUp : Bool)
    (m : SourceModule) (allocation active : Uint256) :
    sourceAvailableCapacity? cfg isTopUp m allocation active =
      AllocCapacity.availableCapacity? cfg isTopUp m allocation active := by
  simp [sourceAvailableCapacity?, AllocCapacity.availableCapacity?]

private theorem sourceTargetValidators_eq (total : Uint256) (m : SourceModule) :
    sourceTargetValidators? total m = AllocCapacity.targetValidators? total m := by
  simp [sourceTargetValidators?, AllocCapacity.targetValidators?, AllocCapacity.totalBasisPoints]

private theorem sourceSecondLoop_eq (cfg : SourceConfig) (isTopUp : Bool)
    (total : Uint256) (modules : List SourceModule) (entries : List (Uint256 × Uint256)) :
    sourceSecondLoop cfg isTopUp total modules entries =
      AllocCapacity.secondLoop cfg isTopUp total modules entries := by
  induction modules generalizing entries with
  | nil => cases entries <;> simp [sourceSecondLoop, AllocCapacity.secondLoop]
  | cons m ms ih =>
      cases entries with
      | nil => simp [sourceSecondLoop, AllocCapacity.secondLoop]
      | cons entry entries =>
          obtain ⟨allocation, active⟩ := entry
          simp [sourceSecondLoop, AllocCapacity.secondLoop, sourceAvailableCapacity_eq,
            sourceTargetValidators_eq, sourceMin, AllocCapacity.wordMin, ih]

/-- The independently stated pinned-source interpreter and the minimal
canonical audit model return the same checked result. -/
theorem source_execute_eq_canonical
    (cfg : SourceConfig) (modules : List SourceModule)
    (depositsToAllocate : Uint256) (isTopUp : Bool) :
    execute cfg modules depositsToAllocate isTopUp =
      AllocCapacity.execute cfg modules depositsToAllocate isTopUp := by
  simp [execute, AllocCapacity.execute, sourceFirstLoop_eq, sourceSecondLoop_eq]

/-- Successful execution preserves `SRStorage.getModuleIdAt` order. -/
theorem router_order_preserved {cfg : SourceConfig} {modules : List SourceModule}
    {depositsToAllocate : Uint256} {isTopUp : Bool} {rows : List AllocCapacity.Row}
    (h : execute cfg modules depositsToAllocate isTopUp = some rows) :
    rows.map AllocCapacity.Row.moduleId = modules.map AllocCapacity.Module.moduleId := by
  rw [source_execute_eq_canonical] at h
  simp only [AllocCapacity.execute] at h
  cases hFirst : AllocCapacity.firstLoop cfg modules depositsToAllocate with
  | none => simp [hFirst] at h
  | some result =>
      obtain ⟨entries, total⟩ := result
      simp [hFirst] at h
      exact AllocCapacity.secondLoop_router_order h

end LidoSRv3.Audit.SolidityAllocCapacity
