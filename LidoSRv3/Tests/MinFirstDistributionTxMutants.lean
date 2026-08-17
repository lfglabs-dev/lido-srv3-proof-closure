import LidoSRv3.Audit.Verity.MinFirstDistributionTx

/-! P-ALLOC-2 faithful-plane fail-closed vectors. -/

namespace LidoSRv3.Tests.MinFirstDistributionTxMutants

open Verity
open LidoSRv3.Audit.MinFirstAllocation
open LidoSRv3.Audit.Verity.MinFirstDistributionTx

private def words (xs : List Nat) : List Source.Word :=
  xs.map Verity.Core.Uint256.ofNat

private def runView (buckets capacities : List Source.Word)
    (allocationSize : Source.Word) : View :=
  let before := stateFor buckets capacities defaultState
  observe buckets ((allocate buckets.length capacities.length allocationSize).run before)

/-- Odd demand must use ceil division: the first tied bucket receives three,
not the floor mutant's two. -/
example :
    runView (words [0, 0]) (words [100, 100]) 5 =
      ⟨.committed, words [3, 2], 5, 0⟩ := by native_decide

example :
    runView (words [0, 0]) (words [100, 100]) 5 ≠
      ⟨.committed, words [2, 3], 5, 0⟩ := by native_decide

/-- The next-level upper bound prevents the least bucket jumping past ten. -/
example :
    runView (words [0, 10]) (words [100, 100]) 20 =
      ⟨.committed, words [15, 15], 20, 0⟩ := by native_decide

example :
    runView (words [0, 10]) (words [100, 100]) 20 ≠
      ⟨.committed, words [20, 10], 20, 0⟩ := by native_decide

/-- Amount inflation is rejected by both conservation observables. -/
example :
    runView (words [0, 0]) (words [100, 100]) 5 ≠
      ⟨.committed, words [4, 2], 6, 0⟩ := by native_decide

/-- A second batch starts from the first batch's buckets and preserves the
same min-first flow. -/
example :
    let first := runView (words [0, 0]) (words [100, 100]) 5
    first = ⟨.committed, words [3, 2], 5, 0⟩ ∧
      runView first.buckets (words [100, 100]) 3 =
        ⟨.committed, words [4, 4], 3, 0⟩ := by native_decide

/-- Failure after bucket and accumulator writes is rolled back by
`Contract.run`, not merely hidden by the observation. -/
example :
    let before := stateFor (words [0, 0]) (words [100, 100]) defaultState
    (allocate 2 2 5 true).run before =
      .revert "INJECTED_AFTER_WRITES" before := by rfl

end LidoSRv3.Tests.MinFirstDistributionTxMutants
