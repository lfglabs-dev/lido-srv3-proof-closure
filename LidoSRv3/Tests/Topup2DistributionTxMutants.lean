import LidoSRv3.Audit.Verity.Topup2DistributionTx

/-! P-TOPUP-2 faithful-plane fail-closed vectors. -/

namespace LidoSRv3.Tests.Topup2DistributionTxMutants

open Verity
open LidoSRv3.Audit.Verity.Topup2DistributionTx

private def word (n : Nat) : Word := Verity.Core.Uint256.ofNat n

private def words (xs : List Nat) : List Word := xs.map word

private def runView (effective pending requested : List Word)
    (target minTopUp remainingCap moduleLimit valueGwei : Word) : View :=
  let before := stateFor effective pending requested defaultState
  observe (List.replicate requested.length 0) remainingCap
    ((allocate requested.length target minTopUp remainingCap moduleLimit valueGwei).run
      before)

/-- Happy path: two validators share a 10-gwei block/share budget left to
right.  The first takes its 6-gwei request; the second is capped at 4. -/
example :
    runView (words [32, 40]) (words [0, 0]) (words [6, 8])
      (word 64) (word 1) (word 10) (word 100) (word 100) =
      ⟨.committed, words [6, 4], word 0, word 10⟩ := by native_decide

/-- Off-by-one allocation is rejected: the certified second share is 4, not
5. -/
example :
    runView (words [32, 40]) (words [0, 0]) (words [6, 8])
      (word 64) (word 1) (word 10) (word 100) (word 100) ≠
      ⟨.committed, words [6, 5], word 0, word 11⟩ := by native_decide

/-- Two-batch chaining: the second top-up batch starts from the first
batch's remaining block cap and the first batch's pending balances. -/
example :
    let first := runView (words [32, 40]) (words [0, 0]) (words [6, 8])
      (word 64) (word 1) (word 10) (word 100) (word 100)
    first = ⟨.committed, words [6, 4], word 0, word 10⟩ ∧
      runView (words [32, 40]) first.allocations (words [6, 8])
        (word 64) (word 1) first.remaining (word 100) (word 100) =
        ⟨.committed, words [0, 0], word 0, word 0⟩ := by native_decide

/-- A second batch with leftover cap continues the same left-to-right
share consumption against the updated pending snapshot. -/
example :
    let first := runView (words [32]) (words [0]) (words [4])
      (word 64) (word 1) (word 10) (word 100) (word 100)
    first = ⟨.committed, words [4], word 6, word 4⟩ ∧
      runView (words [32]) first.allocations (words [8])
        (word 64) (word 1) first.remaining (word 100) (word 100) =
        ⟨.committed, words [6], word 0, word 6⟩ := by native_decide

/-- Overflow on checked uint256 addition of effective + pending reverts
instead of wrapping into a Nat gap. -/
example :
    runView [word _root_.Verity.Core.MAX_UINT256] [word 1] [word 10]
      (word 64) (word 1) (word 100) (word 100) (word 100) =
      ⟨.reverted, [word 0], word 100, word 0⟩ := by native_decide

/-- The total-Nat model would compute a value on the overflowing addition;
the faithful transaction refuses that wrap. -/
example :
    runView [word _root_.Verity.Core.MAX_UINT256] [word 1] [word 10]
      (word 64) (word 1) (word 100) (word 100) (word 100) ≠
      ⟨.committed, [word 0], word 100, word 0⟩ := by native_decide

/-- Failure after allocation and budget writes is rolled back by
`Contract.run`, not merely hidden by the observation. -/
example :
    let before := stateFor (words [32]) (words [0]) (words [4]) defaultState
    (allocate 1 (word 64) (word 1) (word 10) (word 100) (word 100) true).run before =
      .revert "INJECTED_AFTER_WRITES" before := by rfl


/-- Kill-line mutant for `router_require_post_condition`: two validators each
independently within their 20-gwei limits, but sum 20 > maxTopUpPerBlockGwei 10.
If the sum `require` is removed the parent post-condition is false. -/
example :
    let cfg : LidoSRv3.Audit.Guarantees.PTopup2.TopupConfig :=
      { targetBalanceGwei := 32, minTopUpGwei := 1,
        maxTopUpPerBlockGwei := 10, maxValidatorsPerCall := 100,
        moduleAllocationLimitGwei := 100, maxRootAge := 0 }
    let validators : List LidoSRv3.Audit.Guarantees.PTopup2.Validator :=
      [{ pubkey := ⟨#[1]⟩, index := 0, wc := 2, activated := true,
         slashed := false, exiting := false,
         effectiveBalanceGwei := 12, pendingBalanceGwei := 0 },
       { pubkey := ⟨#[2]⟩, index := 1, wc := 2, activated := true,
         slashed := false, exiting := false,
         effectiveBalanceGwei := 12, pendingBalanceGwei := 0 }]
    let limits := validators.map (fun v =>
      LidoSRv3.Audit.Guarantees.PTopup2.evaluated_topup_limit v cfg)
    let alloc := [10, 10]
    let share := 100
    -- Each alloc[i] ≤ limits[i] (both 10 ≤ 20), but sum 20 > min(100,10) = 10.
    -- This witnesses that removing the sum require falsifies the parent.
    (∀ i : Fin alloc.length, alloc[i] ≤ limits[i.val]'(by omega)) ∧
    ¬ (alloc.sum ≤ min share cfg.maxTopUpPerBlockGwei) := by native_decide

end LidoSRv3.Tests.Topup2DistributionTxMutants
