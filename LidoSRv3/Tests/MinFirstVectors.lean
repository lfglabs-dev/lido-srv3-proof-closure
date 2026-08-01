import LidoSRv3.Audit.StrategyProofs
import LidoSRv3.Audit.Guarantees.PAlloc1
import LidoSRv3.Audit.Guarantees.PAlloc2

namespace LidoSRv3.Tests.MinFirstVectors

open LidoSRv3.Audit
open LidoSRv3.Audit.MinFirst

private def word (n : Nat) : Word := Verity.Core.Uint256.ofNat n
private def b (id allocation capacity : Nat) (active := true)
    (credentialType := CredentialType.wc02) : Bucket :=
  ⟨word id, active, credentialType, allocation, capacity⟩

private def activeEmptyModule : LidoSRv3.Module :=
  ⟨0, .active, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, false, 0, 0, 0⟩

private def allocationConfig : LidoSRv3.AllocationConfig := ⟨32, 64⟩

/- An active module whose share target exceeds its available capacity. -/
private def capacityLimitedModule : LidoSRv3.Module :=
  ⟨1, .active, 10000, 0, 1, 0, 0, 0, 0, 0, 0, 0, false, 0, 0, 0⟩

/- Positive MODEL vector: an active zero-share module has zero capacity. -/
example :
    (LidoSRv3.allocationCapacityRow allocationConfig [activeEmptyModule] 1 false
      activeEmptyModule).capacity = 0 := by decide

/- A capacity above the share target is a plausible broken row and is rejected. -/
example :
    ¬ (LidoSRv3.allocationCapacityRow allocationConfig [activeEmptyModule] 1 false
      activeEmptyModule).targetValidators <
      (LidoSRv3.allocationCapacityRow allocationConfig [activeEmptyModule] 1 false
        activeEmptyModule).capacity := by decide

/- This vector independently exercises the available-capacity (not target) arm. -/
example :
    let row := LidoSRv3.allocationCapacityRow allocationConfig [capacityLimitedModule] 10 false
      capacityLimitedModule
    row.capacity = LidoSRv3.moduleAvailableCapacityEquivalent allocationConfig false
      capacityLimitedModule ∧
    row.capacity < row.targetValidators := by decide

/- A row exceeding available capacity is rejected even where the target is larger. -/
example :
    ¬ LidoSRv3.moduleAvailableCapacityEquivalent allocationConfig false capacityLimitedModule <
      (LidoSRv3.allocationCapacityRow allocationConfig [capacityLimitedModule] 10 false
        capacityLimitedModule).capacity := by decide

/-!
Pinned-source allocation-capacity vectors for
`SRLib._getModulesAllocationAndCapacity` (`lidofinance/core@af095e48`,
`contracts/0.8.25/sr/SRLib.sol`, lines 493--559).  Each negative vector names the
source line whose mutation it detects.
-/

open LidoSRv3.Audit.SolidityAllocCapacity in
/- Source record: 10 deposited, summary/accounting exited 1 and 4, 50 depositable,
   50% share limit, type-1 credentials. -/
private def srcRow : SourceModule := ⟨5000, true, false, 50, 10, 1, 4, 0⟩

/- The `LidoSRv3.Module` this source record corresponds to. -/
private def modelRow : LidoSRv3.Module :=
  ⟨1, .active, 5000, 0, 50, 0, 0, 0, 10, 4, 0, 0, false, 0, 0, 0⟩

private theorem rowsCorrespond :
    LidoSRv3.Audit.SolidityAllocCapacity.RowsCorrespond allocationConfig [modelRow] [srcRow] := by
  refine ⟨⟨?_, ?_, ?_, ?_, ?_, ?_⟩, trivial⟩ <;> decide

/- Positive SRC vector, discharged through the correspondence theorem rather than
   by evaluating both sides independently. -/
example :
    LidoSRv3.Audit.SolidityAllocCapacity.capacities allocationConfig.maxEBType1
        allocationConfig.maxEBType2 false 0 [srcRow]
      = LidoSRv3.allocatedCapacityValues
          (LidoSRv3.modulesAllocationAndCapacity allocationConfig [modelRow] 0 false) :=
  LidoSRv3.Audit.Guarantees.PAlloc1.source_capacities_match_model
    allocationConfig [modelRow] [srcRow] 0 false (by decide) rowsCorrespond

/- The clamped capacity is the share target, not the raw available capacity. -/
example :
    LidoSRv3.Audit.SolidityAllocCapacity.capacityEntry 32 64 false
      (LidoSRv3.Audit.SolidityAllocCapacity.totalValidators 32 0 [srcRow]) srcRow = 3 := by decide

/- Dropping the `Math.min` clamp at source line 554 is a plausible mutant and is
   rejected: the uncapped capacity differs from the returned one. -/
example :
    LidoSRv3.Audit.SolidityAllocCapacity.capacityEntry 32 64 false
        (LidoSRv3.Audit.SolidityAllocCapacity.totalValidators 32 0 [srcRow]) srcRow
      ≠ LidoSRv3.Audit.SolidityAllocCapacity.uncappedCapacity 32 64 false srcRow := by decide

/- Taking only the module-summary exited count instead of `Math.max` with the
   accounting count at source line 522 is rejected: 10 - max 1 4 ≠ 10 - 1. -/
example :
    LidoSRv3.Audit.SolidityAllocCapacity.activeCount srcRow = 6 ∧
      srcRow.depositedCount - srcRow.summaryExitedCount = 9 := by decide

open LidoSRv3.Audit.SolidityAllocCapacity in
/- Type-2 credentials, 320 wei total module stake, 5 depositable, 100% share. -/
private def srcType2Row : SourceModule := ⟨10000, true, true, 5, 10, 0, 0, 320⟩

/- The type-2 top-up arm at source line 546 is load-bearing: collapsing it into
   the line 548 arm changes the capacity (20 vs 15). -/
example :
    LidoSRv3.Audit.SolidityAllocCapacity.capacityEntry 32 64 true
        (LidoSRv3.Audit.SolidityAllocCapacity.totalValidators 32 100 [srcType2Row])
        srcType2Row = 20 ∧
      LidoSRv3.Audit.SolidityAllocCapacity.capacityEntry 32 64 false
        (LidoSRv3.Audit.SolidityAllocCapacity.totalValidators 32 100 [srcType2Row])
        srcType2Row = 15 := by decide

/- An inactive module keeps `_allocations[i]` and ignores the share target
   entirely (source lines 541 and 557). -/
example :
    LidoSRv3.Audit.SolidityAllocCapacity.capacityEntry 32 64 false 0
      { srcRow with isActive := false } = 6 := by decide

example : candidate? [b 0 5 10, b 1 0 10] = some (b 1 0 10) := by decide
/- A later, fuller bucket is a plausible broken MinFirst choice and is rejected. -/
example : candidate? [b 0 0 10, b 1 2 10] ≠ some (b 1 2 10) := by decide
example : candidate? [b 0 0 10, b 1 0 10] = some (b 0 0 10) := by decide
example : candidate? [b 0 10 10, b 1 1 10] = some (b 1 1 10) := by decide
example : candidate? [b 0 0 10 false, b 1 1 10] = some (b 1 1 10) := by decide
example : candidate? [b 0 0 10 true .wc01, b 1 1 10] = some (b 0 0 10 true .wc01) := by decide
example : allocate 1 [b 0 11 10, b 1 0 1] = [b 0 11 10, b 1 1 1] := by decide
example : allocate 3 [b 0 0 1, b 1 0 1] = [b 0 1 1, b 1 1 1] := by decide
example :
    allocate 1 [b 0 0 10, b 1 0 10] = [b 0 1 10, b 1 0 10] ∧
    allocate 1 [b 1 0 10, b 0 0 10] = [b 1 1 10, b 0 0 10] := by decide

end LidoSRv3.Tests.MinFirstVectors
