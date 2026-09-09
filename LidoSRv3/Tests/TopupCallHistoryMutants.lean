import LidoSRv3.Audit.Source.TopupCallHistory

namespace LidoSRv3.Tests.TopupCallHistoryMutants
open LidoSRv3.Audit.Source.TopupCallHistory
open LidoSRv3.Audit.Source.TopupWeiBounds

def timing : TimingState :=
  ⟨⟨0, by decide⟩, ⟨0, by decide⟩, ⟨1, by decide⟩⟩

example : setDistance emptyTiming 0 = none := by decide
example : setDistance emptyTiming uint16Modulus = none := by decide
example : setDistance emptyTiming 1 = some timing := by decide
example : Configured timing := .initialized 1 timing (by decide)

/-- A guard sees old state until the external call returns. Two admitted
checks witness the gap; they are NOT a full authorized reentrancy trace. -/
example : distancePassed timing 100 = some true ∧
    distancePassed timing 100 = some true ∧
    distancePassed (finish timing 100 1000 1) 100 = some false := by decide

/-- Truncation is load-bearing. At the uint32 horizon the stored zero sentinel
reopens admission even immediately after a positive-limit return. -/
example : (finish timing uint32Modulus 1000 1).lastBlock.val = 0 ∧
    distancePassed (finish timing uint32Modulus 1000 1) uint32Modulus = some true := by decide
example : distancePassed (finish timing (uint32Modulus + 100) 1000 1)
    (uint32Modulus + 100) = some true := by decide
example : (finish timing 100 uint32Modulus 1).lastTimestamp.val = 0 := by decide

/-- At block zero the last-block sentinel also prevents same-block rejection. -/
example : distancePassed (finish timing 0 1000 1) 0 = some true := by decide

/-- Zero allocations do not suppress the update when limits are positive. -/
example : allocationGuards [0] [gwei] ∧
    uncheckedSum 0 [0] = 0 ∧ uncheckedSum 0 [gwei] > 0 ∧
    (finish timing 100 1000 (uncheckedSum 0 [gwei])).lastBlock.val = 100 := by decide

/-- Checked subtraction does not silently truncate a negative distance. -/
example : distancePassed (finish timing 100 1000 1) 99 = none := by decide

end LidoSRv3.Tests.TopupCallHistoryMutants

#print axioms LidoSRv3.Audit.Source.TopupCallHistory.configured_positive
#print axioms LidoSRv3.Audit.Source.TopupCallHistory.same_block_rejects_after_setter
#print axioms LidoSRv3.Audit.Source.TopupCallHistory.zero_limits_zero_allocations
