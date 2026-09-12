import LidoSRv3.Audit.Spec.AllocLoopTermination

/-! P-ALLOC-2 unconditional `sourceAllocateLoop` termination vectors. -/

namespace LidoSRv3.Tests.AllocLoopTerminationMutants

open LidoSRv3.Audit.MinFirstAllocation
open LidoSRv3.Audit.Spec.AllocLoopTermination
open LidoSRv3.Audit.Verity.MinFirstDistributionTx

private def w (n : Nat) : Source.Word := Verity.Core.Uint256.ofNat n

private def rows (allocs caps : List Nat) : List Source.Row :=
  (allocs.zip caps).map fun p => ⟨w p.1, w p.2⟩

/-- Honest residue strictly decreases when a nonzero step fills a bucket
(`MinFirstAllocationStrategy.sol:106`). -/
theorem residue_decreases_on_progress :
    let rs := rows [0, 0] [100, 100]
    allocateToBestCandidate rs (w 5) = some (rows [3, 0] [100, 100], w 3) ∧
      remainingCapacitySum (rows [3, 0] [100, 100]) < remainingCapacitySum rs := by
  native_decide

/-- A row-count measure does not decrease on that same step, so it cannot
justify termination of `allocate`. -/
theorem row_count_measure_does_not_decrease :
    let rs := rows [0, 0] [100, 100]
    allocateToBestCandidate rs (w 5) = some (rows [3, 0] [100, 100], w 3) ∧
      (rows [3, 0] [100, 100]).length = rs.length := by
  native_decide

/-- Fuel-exhaustion mutant that reports leftover `0` instead of the actual
remainder. Conservation fails on a nonempty demand with zero fuel. -/
def mutantFuel0ZeroRemainder : Nat → List Source.Row → Source.Word → Source.Word →
    Option (List Source.Row × Source.Word × Source.Word)
  | 0, rows, _remaining, total => some (rows, total, 0)
  | fuel + 1, rows, remaining, total =>
      sourceAllocateLoop (fuel + 1) rows remaining total

theorem fuel_exhaustion_zero_remainder_mutant_refutes_conservation :
    ¬ (∀ (rows : List Source.Row) (allocationSize allocated leftover : Source.Word)
        (after : List Source.Row),
      mutantFuel0ZeroRemainder 0 rows allocationSize 0 = some (after, allocated, leftover) →
        allocated.val + leftover.val = allocationSize.val) := by
  intro h
  have hrun : mutantFuel0ZeroRemainder 0 (rows [0] [10]) (w 5) 0 =
      some (rows [0] [10], 0, 0) := rfl
  have hcons := h (rows [0] [10]) (w 5) 0 0 (rows [0] [10]) hrun
  simp [w] at hcons

#print axioms LidoSRv3.Audit.Spec.AllocLoopTermination.sourceAllocateLoop_terminates
#print axioms LidoSRv3.Audit.Spec.AllocLoopTermination.source_allocate_conserves_without_fuel
#print axioms fuel_exhaustion_zero_remainder_mutant_refutes_conservation

end LidoSRv3.Tests.AllocLoopTerminationMutants
