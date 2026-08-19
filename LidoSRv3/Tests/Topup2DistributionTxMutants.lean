import LidoSRv3.Audit.Verity.Topup2DistributionTx

/-! P-TOPUP-2 faithful-plane fail-closed vectors. -/

namespace LidoSRv3.Tests.Topup2DistributionTxMutants

open Verity
open LidoSRv3.Audit.Verity.Topup2DistributionTx
open LidoSRv3.Audit.Guarantees.PTopup2 (TopupBatch TopupConfig Validator consumeBudget
  candidates evaluated_topup_limit GWEI aggregate_bounded_by_block_cap)

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


/-! ## Kill-line for the registered parent `aggregate_bounded_by_block_cap`

The previously registered parent `router_require_post_condition` took the
per-validator bound and the aggregate cap bound as *hypotheses* and handed
them straight back as its conclusion, so no assignment of concrete numbers
could ever refute it — the kill-line that used to live here fed numbers into
that same restated conclusion directly, never through the theorem, and so
tested a fact about `Nat` inequalities rather than the router. It has been
removed (see `PTopup2.lean`).

The mutant below instead targets the *registered* parent's own statement.
`aggregate_bounded_by_block_cap` is unconditional in `b`/`cfg`, and its proof
runs `consumeBudget_sum_le` against `transitionBudget`'s
`min (valueGwei) (min moduleLimit maxTopUpPerBlockGwei)`. `mutantTransition`
below is the identical leftover-budget walk with the `maxTopUpPerBlockGwei`
term dropped from that `min` — the Lean analogue of a router that dropped its
block-cap `require`. `block_cap_kill_line_refutes_parent` witnesses that the
mutant walk allocates *above* the real cap, so the registered parent's bound
genuinely depends on that `min` term rather than holding vacuously. -/

/-- Mutant budget: folds in the call value and the module allocation limit
but omits `maxTopUpPerBlockGwei`, modeling a router that dropped the
block-cap `require` before consuming the leftover-budget walk. -/
def mutantTransitionBudget (b : TopupBatch) (cfg : TopupConfig) : Nat :=
  min (b.valueWei / GWEI) cfg.moduleAllocationLimitGwei

/-- The same left-to-right `consumeBudget` walk `transition` uses, run
against the uncapped mutant budget instead of `transitionBudget`. -/
def mutantTransition (b : TopupBatch) (cfg : TopupConfig) : List Nat :=
  consumeBudget (mutantTransitionBudget b cfg) (candidates b cfg)

private def killLineCfg : TopupConfig :=
  { targetBalanceGwei := 32, minTopUpGwei := 1,
    maxTopUpPerBlockGwei := 10, maxValidatorsPerCall := 100,
    moduleAllocationLimitGwei := 100, maxRootAge := 0 }

private def killLineValidators : List Validator :=
  [{ pubkey := ⟨#[1]⟩, index := 0, wc := 2, activated := true,
     slashed := false, exiting := false,
     effectiveBalanceGwei := 12, pendingBalanceGwei := 0 },
   { pubkey := ⟨#[2]⟩, index := 1, wc := 2, activated := true,
     slashed := false, exiting := false,
     effectiveBalanceGwei := 12, pendingBalanceGwei := 0 }]

private def killLineBatch : TopupBatch :=
  { validators := killLineValidators, requestedGwei := [10, 10], allocations := []
    valueWei := 100 * GWEI, beaconRootTimestamp := 0, currentTimestamp := 0 }

/-- Sanity check: each validator's evaluated limit is 20 gwei (`32 - 12`),
each request of 10 gwei clears its own limit independently, so the
per-validator bound alone gives no reason to expect the aggregate to fail. -/
example :
    killLineValidators.map (fun v => evaluated_topup_limit v killLineCfg) = [20, 20] := by
  decide

/-- **Kill-line mutant.** Dropping `maxTopUpPerBlockGwei` from the consumed
budget lets the identical leftover-budget walk commit `[10, 10]`: both
requests clear the uncapped 100-gwei mutant budget in full, summing to 20 gwei
against a 10-gwei `maxTopUpPerBlockGwei`. This is exactly the two-validator
scenario the retracted kill-line described, now driven through the real
`consumeBudget`/`candidates` functions the registered parent's proof uses,
rather than through hand-picked numbers fed straight into a restated
hypothesis. -/
example : mutantTransition killLineBatch killLineCfg = [10, 10] ∧
    (mutantTransition killLineBatch killLineCfg).sum = 20 ∧
    ¬ (mutantTransition killLineBatch killLineCfg).sum ≤ killLineCfg.maxTopUpPerBlockGwei := by
  decide

/-- Named kill-line statement: it is not the case that every mutant-budget
leftover walk respects the per-block cap. The registered parent
`aggregate_bounded_by_block_cap` proves exactly this universal for the real
`transition`/`transitionBudget`; this theorem shows the analogous statement
is false for the mutant that drops the cap from the budget `min`, so the
real `min` term is load-bearing rather than vacuous. -/
theorem block_cap_kill_line_refutes_parent :
    ¬ ∀ (b : TopupBatch) (cfg : TopupConfig),
      (mutantTransition b cfg).sum ≤ cfg.maxTopUpPerBlockGwei := by
  intro h
  exact absurd (h killLineBatch killLineCfg) (by decide)

/-- Contrast: the registered parent holds unconditionally for the *real*
`transition`, including on the very batch/config pair that refutes the
mutant above. -/
example : (LidoSRv3.Audit.Guarantees.PTopup2.transition killLineBatch killLineCfg).sum ≤
    killLineCfg.maxTopUpPerBlockGwei :=
  aggregate_bounded_by_block_cap killLineBatch killLineCfg

end LidoSRv3.Tests.Topup2DistributionTxMutants
