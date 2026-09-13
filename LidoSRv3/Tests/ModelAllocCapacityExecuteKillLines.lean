import LidoSRv3.Audit.Model.AllocCapacity

/-!
Kill-lines pinning `Model.AllocCapacity.execute` composition of first
and second loops, the Solidity-facing abbrev, `Row` field extraction,
and `Row` constructor identity. These pin the top-level
`_getModulesAllocationAndCapacity` transcription base cases.
-/

namespace LidoSRv3.Tests.ModelAllocCapacityExecuteKillLines

open LidoSRv3.Audit.AllocCapacity

private def m0 : Module :=
  { moduleId := 7
    shareLimit := 5000
    isActive := false
    isType2 := false
    depositableCount := 0
    depositedCount := 0
    summaryExitedCount := 0
    accountingExitedCount := 0
    totalModuleStake := 0 }

private def cfg0 : Config := { maxEBType1 := 32, maxEBType2 := 2048 }

/-! ## `execute` — no modules yields empty rows. -/

theorem execute_empty_modules :
    execute cfg0 [] 0 false = some [] := by decide

theorem execute_empty_modules_topup :
    execute cfg0 [] 0 true = some [] := by decide

/-! ## Solidity-facing name alias. -/

theorem _getModulesAllocationAndCapacity_is_execute :
    @_getModulesAllocationAndCapacity = @execute := rfl

/-! ## `Row` field extraction — one witness per column. -/

private def r0 : Row :=
  { moduleId := 7
    currentAllocation := 3
    capacity := 5
    targetValidators := 11
    activeCount := 13 }

theorem row_moduleId : r0.moduleId = 7 := rfl
theorem row_currentAllocation : r0.currentAllocation = 3 := rfl
theorem row_capacity : r0.capacity = 5 := rfl
theorem row_targetValidators : r0.targetValidators = 11 := rfl
theorem row_activeCount : r0.activeCount = 13 := rfl

/-! ## `Row` decidable equality. -/

theorem row_decEq_self :
    (decide (r0 = r0)) = true := by decide

theorem row_decEq_neg :
    (decide (r0 = { r0 with capacity := 6 })) = false := by decide

/-! ## `Config` field extraction. -/

theorem cfg0_maxEBType1 : cfg0.maxEBType1 = 32 := rfl
theorem cfg0_maxEBType2 : cfg0.maxEBType2 = 2048 := rfl

end LidoSRv3.Tests.ModelAllocCapacityExecuteKillLines
