import LidoSRv3.Audit.Model.AllocCapacity

/-!
Kill-lines pinning `Model.AllocCapacity` first-loop option-monadic
helpers (`activeCount?`, `ceilDiv?`, `allocationEntry?`, `firstLoop`)
on concrete inputs. These pin the SRLib.sol:521-533 checked-arithmetic
transcription base cases.
-/

namespace LidoSRv3.Tests.ModelAllocCapacityFirstLoopKillLines

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

/-! ## `activeCount?` — SRLib.sol:521-522 (deposited − max(exits)) -/

theorem activeCount_zero : activeCount? m0 = some 0 := by decide

theorem activeCount_deposit_100_no_exit :
    activeCount? { m0 with depositedCount := 100 } = some 100 := by decide

theorem activeCount_exit_exceeds_deposit_reverts :
    activeCount?
      { m0 with depositedCount := 5, accountingExitedCount := 10 } = none := by
  decide

/-! ## `ceilDiv?` — divisor zero reverts (OpenZeppelin `Math.ceilDiv`). -/

theorem ceilDiv_by_zero_reverts : ceilDiv? 100 0 = none := by decide

theorem ceilDiv_exact_division :
    ceilDiv? 64 32 = some 2 := by decide

theorem ceilDiv_rounds_up :
    ceilDiv? 65 32 = some 3 := by decide

/-! ## `allocationEntry?` — SRLib.sol:521-531 -/

/-- Type-1 branch: allocation equals activeCount. -/
theorem allocationEntry_type1_zero :
    allocationEntry? cfg0 m0 = some (0, 0) := by decide

/-- Type-2 branch: allocation is `ceilDiv(totalStake, maxEBType1)`. -/
theorem allocationEntry_type2 :
    allocationEntry? cfg0
      { m0 with isType2 := true, depositedCount := 5, totalModuleStake := 64 } =
      some (2, 5) := by decide

/-! ## `firstLoop` empty base case — a definitional identity. -/

theorem firstLoop_empty_zero :
    firstLoop cfg0 [] 0 = some ([], 0) := rfl

end LidoSRv3.Tests.ModelAllocCapacityFirstLoopKillLines
