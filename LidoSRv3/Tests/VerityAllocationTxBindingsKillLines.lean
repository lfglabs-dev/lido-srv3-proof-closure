import LidoSRv3.Audit.Verity.AllocationTx

/-!
Kill-lines pinning `Verity.AllocationTx` binding helpers
(`toSourceModule`, `withSummary`, `withTotalStake`, `sourceBindAll`
base case). These are the SRLib.sol:509-518 hoisted binding
functions that build BoundModule records from ContractState.
-/

namespace LidoSRv3.Tests.VerityAllocationTxBindingsKillLines

open LidoSRv3.Audit.Verity.AllocationTx
open LidoSRv3.Audit.AllocCapacity

/-! ## `sourceBindAll` on count = 0 is empty. -/

theorem sourceBindAll_zero (state : Verity.ContractState) :
    sourceBindAll state 0 = [] := rfl

/-! ## `toSourceModule` — projects BoundModule to Module. -/

theorem toSourceModule_moduleId (m : BoundModule) :
    (toSourceModule m).moduleId = m.moduleId := rfl

theorem toSourceModule_shareLimit (m : BoundModule) :
    (toSourceModule m).shareLimit = m.shareLimit := rfl

theorem toSourceModule_isActive (m : BoundModule) :
    (toSourceModule m).isActive = m.isActive := rfl

theorem toSourceModule_isType2 (m : BoundModule) :
    (toSourceModule m).isType2 = m.isType2 := rfl

theorem toSourceModule_depositableCount (m : BoundModule) :
    (toSourceModule m).depositableCount = m.depositableCount := rfl

theorem toSourceModule_depositedCount (m : BoundModule) :
    (toSourceModule m).depositedCount = m.depositedCount := rfl

theorem toSourceModule_summaryExitedCount (m : BoundModule) :
    (toSourceModule m).summaryExitedCount = m.summaryExitedCount := rfl

theorem toSourceModule_accountingExitedCount (m : BoundModule) :
    (toSourceModule m).accountingExitedCount = m.accountingExitedCount := rfl

theorem toSourceModule_totalModuleStake (m : BoundModule) :
    (toSourceModule m).totalModuleStake = m.totalModuleStake := rfl

/-! ## `withSummary` — updates three summary fields (SRLib.sol:513-514). -/

theorem withSummary_depositableCount (m : BoundModule) (s : DecodedSummary) :
    (withSummary m s).depositableCount = s.depositableCount := rfl

theorem withSummary_depositedCount (m : BoundModule) (s : DecodedSummary) :
    (withSummary m s).depositedCount = s.depositedCount := rfl

theorem withSummary_summaryExitedCount (m : BoundModule) (s : DecodedSummary) :
    (withSummary m s).summaryExitedCount = s.exitedCount := rfl

/-! ## `withTotalStake` — updates single field. -/

theorem withTotalStake_updates (m : BoundModule) (stake : Word) :
    (withTotalStake m stake).totalModuleStake = stake := rfl

theorem withTotalStake_preserves_moduleId (m : BoundModule) (stake : Word) :
    (withTotalStake m stake).moduleId = m.moduleId := rfl

end LidoSRv3.Tests.VerityAllocationTxBindingsKillLines
