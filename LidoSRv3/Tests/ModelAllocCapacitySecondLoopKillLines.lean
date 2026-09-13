import LidoSRv3.Audit.Model.AllocCapacity

/-!
Kill-lines pinning `Model.AllocCapacity` second-loop option-monadic
helpers (`availableCapacity?`, `targetValidators?`, `secondLoop`) on
concrete inputs. These pin the SRLib.sol:539-558 checked-arithmetic
transcription base cases.
-/

namespace LidoSRv3.Tests.ModelAllocCapacitySecondLoopKillLines

open LidoSRv3.Audit.AllocCapacity

private def m0 : Module :=
  { moduleId := 0
    shareLimit := 0
    isActive := false
    isType2 := false
    depositableCount := 0
    depositedCount := 0
    summaryExitedCount := 0
    accountingExitedCount := 0
    totalModuleStake := 0 }

private def cfg0 : Config := { maxEBType1 := 32, maxEBType2 := 2048 }

/-! ## `availableCapacity?` — SRLib.sol:543-549 -/

/-- Not-top-up branch: `allocation + depositableCount`. -/
theorem availableCapacity_not_topup_zero :
    availableCapacity? cfg0 false m0 0 0 = some 0 := by decide

theorem availableCapacity_not_topup_sums :
    availableCapacity? cfg0 false
      { m0 with depositableCount := 5 } 3 0 = some 8 := by decide

/-- Top-up type-1 branch also takes the "else" arm. -/
theorem availableCapacity_topup_type1_takes_else :
    availableCapacity? cfg0 true m0 3 0 = some 3 := by decide

/-- Top-up type-2 branch: `active * maxEBType2 / maxEBType1`. -/
theorem availableCapacity_topup_type2 :
    availableCapacity? cfg0 true
      { m0 with isType2 := true } 0 32 = some 2048 := by decide

/-! ## `targetValidators?` — SRLib.sol:552 (share * total) / 10000. -/

theorem targetValidators_zero_share :
    targetValidators? 100 m0 = some 0 := by decide

theorem targetValidators_5000bp_of_10000 :
    targetValidators? 10000 { m0 with shareLimit := 5000 } = some 5000 := by
  decide

theorem targetValidators_100pct_bp_of_100 :
    targetValidators? 100 { m0 with shareLimit := 10000 } = some 100 := by
  decide

/-! ## `secondLoop` — SRLib.sol:539-558 base cases. -/

theorem secondLoop_empty :
    secondLoop cfg0 false 0 [] [] = some [] := rfl

theorem secondLoop_length_mismatch_left :
    secondLoop cfg0 false 0 [m0] [] = none := rfl

theorem secondLoop_length_mismatch_right :
    secondLoop cfg0 false 0 [] [(0, 0)] = none := rfl

end LidoSRv3.Tests.ModelAllocCapacitySecondLoopKillLines
