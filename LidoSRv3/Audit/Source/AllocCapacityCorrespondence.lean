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

abbrev SourceModule := AllocCapacity.Module
abbrev SourceConfig := AllocCapacity.Config

/-- Direct interpretation of the pinned source span. -/
def execute := AllocCapacity.execute

/-- The pinned source and canonical audit model have the same checked result;
the statement is definitional because the canonical model is the source
translation rather than a second handwritten algorithm. -/
theorem source_execute_eq_canonical
    (cfg : SourceConfig) (modules : List SourceModule)
    (depositsToAllocate : Uint256) (isTopUp : Bool) :
    execute cfg modules depositsToAllocate isTopUp =
      AllocCapacity.execute cfg modules depositsToAllocate isTopUp := rfl

/-- Successful execution preserves `SRStorage.getModuleIdAt` order. -/
theorem router_order_preserved {cfg : SourceConfig} {modules : List SourceModule}
    {depositsToAllocate : Uint256} {isTopUp : Bool} {rows : List AllocCapacity.Row}
    (h : execute cfg modules depositsToAllocate isTopUp = some rows) :
    rows.map AllocCapacity.Row.moduleId = modules.map AllocCapacity.Module.moduleId := by
  simp only [execute, AllocCapacity.execute] at h
  cases hFirst : AllocCapacity.firstLoop cfg modules depositsToAllocate with
  | none => simp [hFirst] at h
  | some result =>
      obtain ⟨entries, total⟩ := result
      simp [hFirst] at h
      exact AllocCapacity.secondLoop_router_order h

end LidoSRv3.Audit.SolidityAllocCapacity
