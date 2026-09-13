import LidoSRv3.Audit.Model.AllocCapacity

/-! # Kill-lines for `Model.AllocCapacity.MathView.activeCount` and `capacity`

**Chantier 3 (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the P-ALLOC-1 Audit-model MathView semantics: activeCount subtracts
the max of two exit counters, capacity picks min(target, available)
for active modules, allocationEntry for inactive. -/

namespace LidoSRv3.Tests.ModelAllocCapacityMathViewActiveKillLines

open LidoSRv3.Audit.AllocCapacity
open LidoSRv3.Audit.AllocCapacity.MathView
open Verity

/-- Sample WC01 (type-1) active module. -/
def sampleWc01Module : Module :=
  { moduleId := 1,
    shareLimit := 5000,
    isActive := true,
    isType2 := false,
    depositableCount := 100,
    depositedCount := 200,
    summaryExitedCount := 10,
    accountingExitedCount := 20,
    totalModuleStake := 0 }

/-- **Kill-line: `activeCount` = deposited − max(summaryExited, accountingExited).**

A mutant that used min instead of max, or one of the two exit
counters, would refute. -/
theorem activeCount_composition (m : Module) :
    activeCount m = (m.depositedCount : Nat) -
      max (m.summaryExitedCount : Nat) (m.accountingExitedCount : Nat) := rfl

/-- **Kill-line: sample module's activeCount is 200 − max(10, 20) = 180.** -/
theorem sample_activeCount :
    activeCount sampleWc01Module = 180 := by decide

/-- **Kill-line: activeCount picks the *larger* exit counter (via max).**

If summaryExited=100 and accountingExited=50 with deposited=200,
activeCount = 200 - 100 = 100. -/
theorem activeCount_max_bigger_summary :
    activeCount { sampleWc01Module with
      depositedCount := 200,
      summaryExitedCount := 100,
      accountingExitedCount := 50 } = 100 := by decide

/-- **Kill-line: activeCount picks the *larger* exit counter (accounting).**

If summaryExited=50 and accountingExited=100 with deposited=200,
activeCount = 200 - 100 = 100 (accounting wins). -/
theorem activeCount_max_bigger_accounting :
    activeCount { sampleWc01Module with
      depositedCount := 200,
      summaryExitedCount := 50,
      accountingExitedCount := 100 } = 100 := by decide

/-- **Kill-line: activeCount clamps to zero on subtraction underflow (Nat).** -/
theorem activeCount_underflow :
    activeCount { sampleWc01Module with
      depositedCount := 5,
      summaryExitedCount := 10,
      accountingExitedCount := 0 } = 0 := by decide

/-- **Kill-line: `allocationEntry` on WC01 is `activeCount m`.** -/
theorem allocationEntry_wc01 (cfg : Config) (m : Module) (h : m.isType2 = false) :
    allocationEntry cfg m = activeCount m := by
  unfold allocationEntry
  simp [h]

/-- **Kill-line: `allocationEntry` sample = 180 for WC01 active module.** -/
theorem sample_allocationEntry :
    allocationEntry { maxEBType1 := 32, maxEBType2 := 2048 } sampleWc01Module
      = 180 := by decide

#print axioms activeCount_composition
#print axioms sample_activeCount
#print axioms activeCount_max_bigger_summary
#print axioms activeCount_max_bigger_accounting
#print axioms activeCount_underflow
#print axioms allocationEntry_wc01
#print axioms sample_allocationEntry

end LidoSRv3.Tests.ModelAllocCapacityMathViewActiveKillLines
