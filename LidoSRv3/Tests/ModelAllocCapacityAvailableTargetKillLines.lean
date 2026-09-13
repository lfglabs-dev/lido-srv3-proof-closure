import LidoSRv3.Audit.Model.AllocCapacity

/-! # Kill-lines for `Model.AllocCapacity.MathView.availableCapacity` and `targetValidators`

**Chantier 3 (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the P-ALLOC-1 MathView `availableCapacity` branch (WC02+topUp uses
maxEBType2/maxEBType1 ratio) and `targetValidators` formula
(`shareLimit * totalValidators / 10000`). -/

namespace LidoSRv3.Tests.ModelAllocCapacityAvailableTargetKillLines

open LidoSRv3.Audit.AllocCapacity
open LidoSRv3.Audit.AllocCapacity.MathView

/-- WC01 module (activeCount = 180, depositable 100). -/
def wc01Module : Module :=
  { moduleId := 1, shareLimit := 5000, isActive := true, isType2 := false,
    depositableCount := 100, depositedCount := 200,
    summaryExitedCount := 10, accountingExitedCount := 20,
    totalModuleStake := 0 }

/-- WC02 module (activeCount = 180, totalModuleStake = 320). -/
def wc02Module : Module :=
  { wc01Module with isType2 := true, totalModuleStake := 320 }

/-- **Kill-line: WC01 `availableCapacity` = allocationEntry + depositable.** -/
theorem availableCapacity_wc01_composition (cfg : Config) (m : Module)
    (h : m.isType2 = false) :
    availableCapacity cfg false m = allocationEntry cfg m + (m.depositableCount : Nat) := by
  unfold availableCapacity
  simp [h]

/-- **Kill-line: WC01 sample availableCapacity = 180 + 100 = 280.** -/
theorem sample_availableCapacity_wc01 :
    availableCapacity { maxEBType1 := 32, maxEBType2 := 2048 }
      false wc01Module = 280 := by decide

/-- **Kill-line: WC02+topUp `availableCapacity` uses maxEBType2 formula.**

`activeCount * maxEBType2 / maxEBType1`. -/
theorem availableCapacity_wc02_topup_composition (cfg : Config) (m : Module)
    (h : m.isType2 = true) :
    availableCapacity cfg true m =
      activeCount m * (cfg.maxEBType2 : Nat) / (cfg.maxEBType1 : Nat) := by
  unfold availableCapacity
  simp [h]

/-- **Kill-line: WC02+topUp sample availableCapacity = 180 * 2048 / 32 = 11520.** -/
theorem sample_availableCapacity_wc02_topup :
    availableCapacity { maxEBType1 := 32, maxEBType2 := 2048 }
      true wc02Module = 11520 := by decide

/-- **Kill-line: WC02 not-topup still uses allocationEntry + depositable (concrete).**

wc02Module has totalModuleStake=320, maxEBType1=32 → allocationEntry
= ceilDiv(320, 32) = 10. Adding depositableCount=100 = 110. -/
theorem availableCapacity_wc02_deposit :
    availableCapacity { maxEBType1 := 32, maxEBType2 := 2048 }
      false wc02Module = 110 := by decide

/-- **Kill-line: `targetValidators` = shareLimit * totalValidators / 10000.** -/
theorem targetValidators_composition (cfg : Config) (modules : List Module)
    (deposits : Verity.Uint256) (m : Module) :
    targetValidators cfg modules deposits m =
      (m.shareLimit : Nat) * totalValidators cfg modules deposits / 10000 := rfl

/-- **Kill-line: sample targetValidators = 5000 * 180 / 10000 = 90.**

For a singleton WC01 module with deposits = 0. -/
theorem sample_targetValidators :
    targetValidators { maxEBType1 := 32, maxEBType2 := 2048 }
      [wc01Module] 0 wc01Module = 90 := by decide

/-- **Kill-line: `totalValidators` = deposits + sum(allocationEntry).**

For singleton wc01Module with deposits = 0, totalValidators = 0 + 180 = 180. -/
theorem sample_totalValidators :
    totalValidators { maxEBType1 := 32, maxEBType2 := 2048 }
      [wc01Module] 0 = 180 := by decide

#print axioms availableCapacity_wc01_composition
#print axioms sample_availableCapacity_wc01
#print axioms availableCapacity_wc02_topup_composition
#print axioms sample_availableCapacity_wc02_topup
#print axioms availableCapacity_wc02_deposit
#print axioms targetValidators_composition
#print axioms sample_targetValidators
#print axioms sample_totalValidators

end LidoSRv3.Tests.ModelAllocCapacityAvailableTargetKillLines
