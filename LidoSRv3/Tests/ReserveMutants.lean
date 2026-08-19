import LidoSRv3.Audit.Guarantees.PReserve1

namespace LidoSRv3.Tests.ReserveMutants

open Verity
open LidoSRv3.Audit.SolidityReserve

private def word (n : Nat) : Word := Verity.Core.Uint256.ofNat n

private def vector : ReserveState :=
  { buffered := word 100
    storedDepositsReserve := word 20
    unfinalizedStETH := word 50
    depositedPostReport := word 3
    depositedNextReportAdjusted := word 2 }

private def allowed : WithdrawInputs := ⟨true, true⟩

/-- Meaningful source mutant: a deposit spend illegally decrements withdrawal
demand as well as the deposits reserve. -/
private def reserveChangingMutant (before : ReserveState) (amount : Word) : SourceOutcome :=
  match spendDepositableEther before amount with
  | .reverted reason => .reverted reason
  | .committed after => .committed { after with
      unfinalizedStETH := after.unfinalizedStETH - amount }

/-- A subtler forbidden mutant consumes withdrawals-reserved buffer while
leaving withdrawal demand untouched. -/
private def withdrawalPartitionMutant (before : ReserveState) (amount : Word) : SourceOutcome :=
  match spendDepositableEther before amount with
  | .reverted reason => .reverted reason
  | .committed after => .committed { after with buffered := after.storedDepositsReserve }

/-- The guard-checking wrapper around `withdrawalPartitionMutant`, mirroring
`modelWithdrawDepositableEther` guard-for-guard (`canDeposit`,
`authorizedRouter`, nonzero amount) so that the Wave 4 kill-line below targets
the registered parent's own predicate shape with only the spend step
mutated. -/
private def mutantWithdraw (inputs : WithdrawInputs)
    (before : ReserveState) (amount : Word) : SourceOutcome :=
  if !inputs.canDeposit then .reverted "CAN_NOT_DEPOSIT"
  else if !inputs.authorizedRouter then .reverted "APP_AUTH_FAILED"
  else if amount = 0 then .reverted "ZERO_AMOUNT"
  else withdrawalPartitionMutant before amount

/-- Post-state the mutated spend commits to on the standard vector:
`withdrawalPartitionMutant` overwrites `buffered` with the post-spend
`storedDepositsReserve` (10), not the legal `buffered - amount` (90). -/
private def partitionMutantAfter : ReserveState :=
  { vector with
    buffered := word 10
    storedDepositsReserve := word 10
    depositedPostReport := word 13
    depositedNextReportAdjusted := word 12 }

example : spendDepositableEther vector (word 10) = .committed
    { vector with
      buffered := word 90
      storedDepositsReserve := word 10
      depositedPostReport := word 13
      depositedNextReportAdjusted := word 12 } := by decide

/-- This falsifier fails exactly if the prohibited transition is admitted. -/
example : reserveChangingMutant vector (word 10) = .committed
    { vector with
      buffered := word 90
      storedDepositsReserve := word 10
      unfinalizedStETH := word 40
      depositedPostReport := word 13
      depositedNextReportAdjusted := word 12 } := by decide

example : reserveChangingMutant vector (word 10) ≠
    spendDepositableEther vector (word 10) := by decide

example : withdrawalPartitionMutant vector (word 10) = .committed
    { vector with
      buffered := word 10
      storedDepositsReserve := word 10
      depositedPostReport := word 13
      depositedNextReportAdjusted := word 12 } := by decide

example : effectiveWithdrawalsReserve
      { vector with
        buffered := word 10
        storedDepositsReserve := word 10
        depositedPostReport := word 13
        depositedNextReportAdjusted := word 12 } ≠
    effectiveWithdrawalsReserve vector := by decide

/-! ## Wave 4 parent kill-line: mutated spend transition under a fresh cache

`stale_queue_cache_mutant_counterexample` below only shows the parent's
`freshQueueCache` hypothesis cannot be dropped — the registered parent cannot
even be instantiated on that witness. The transition-mutant parent kill-line
is this section's `mutantWithdraw`: it keeps every guard of
`modelWithdrawDepositableEther` and commits like `spendDepositableEther`, but
`withdrawalPartitionMutant` then overwrites `buffered` with the post-spend
`storedDepositsReserve`. With a FRESH live value (`live = 50`, exactly the
cached `unfinalizedStETH`), the mutated call commits while the live
queue-facing reserve drops 50 → 0.

Kill-line division of labor for the registered parent's three conjuncts:
`partition_spend_mutant_kill_line_refutes_parent` (this section) kills
conjuncts (2)-(3) — the partition invariant and the live-reserve invariance —
with freshness retained; `guard_drop_kill_line_refutes_parent` (Wave 5
section below) kills conjunct (1) — `scopedWithdrawGuards` guard liveness —
which this section's guard-preserving mutant cannot reach. The stale-cache
theorems remain premise-necessity evidence for `freshQueueCache`. -/

/-- Concrete witness for the Wave 4 kill-line: freshness holds, the mutated
spend commits, and the live queue-facing reserve the parent says is preserved
falls from 50 to 0. This is the negation of the registered parent's
conjunction on one instance, with the `freshQueueCache` premise retained. -/
theorem partition_spend_mutant_witness :
    freshQueueCache vector (word 50) ∧
    mutantWithdraw allowed vector (word 10) = .committed partitionMutantAfter ∧
    liveEffectiveWithdrawalsReserve partitionMutantAfter (word 50) ≠
      liveEffectiveWithdrawalsReserve vector (word 50) :=
  ⟨rfl, by decide, by decide⟩

/-- Wave 4 parent kill-line for P-RESERVE-1: refutes the registered parent
`PReserve1.source_spend_preserves_withdrawal_reserve`'s own predicate shape —
same hypotheses, INCLUDING `freshQueueCache` — when the spend transition is
mutated to `mutantWithdraw`. The negated statement is the parent's statement
with `mutantWithdraw` in place of `modelWithdrawDepositableEther`; the witness
above (fresh cache, committing mutated spend, live reserve 50 → 0)
instantiates the existential counterexample.

Role in the kill-line division of labor: `mutantWithdraw` preserves the guard
chain, so on its witness the parent's first conjunct `scopedWithdrawGuards
inputs` still holds (`allowed = ⟨true, true⟩`) — this kill-line refutes the
parent through conjuncts (2)-(3) (the partition invariant and the
live-reserve invariance) only. Conjunct (1) is killed by the Wave 5
guard-drop kill-line `guard_drop_kill_line_refutes_parent` below. -/
theorem partition_spend_mutant_kill_line_refutes_parent :
    ¬ ∀ (inputs : WithdrawInputs) (before after : ReserveState) (amount live : Word),
        freshQueueCache before live →
        mutantWithdraw inputs before amount = .committed after →
        scopedWithdrawGuards inputs ∧
          withdrawalPartitionSpendInvariant before after amount ∧
          liveEffectiveWithdrawalsReserve after live =
            liveEffectiveWithdrawalsReserve before live := by
  intro hforall
  have hcex := hforall allowed vector partitionMutantAfter (word 10) (word 50)
    partition_spend_mutant_witness.1 partition_spend_mutant_witness.2.1
  exact absurd hcex.2.2 partition_spend_mutant_witness.2.2

/-! ## Wave 5 guard-drop kill-line: `canDeposit` guard liveness

The Wave 4 kill-line above mutates the spend *transition* while keeping every
guard, so it can never falsify the parent's first conjunct: on its witness the
guards hold and `scopedWithdrawGuards inputs` is true. A conjunct no connected
mutant falsifies is dilution, so this section adds the P-TOPUP-1-style
guard-liveness kill-line: `mutantWithdrawNoCanDeposit` is a guard-for-guard
copy of `modelWithdrawDepositableEther` with ONLY the `canDeposit` check
deleted (`authorizedRouter`, the nonzero-amount check, and the honest
`spendDepositableEther` transition are unchanged), and
`guard_drop_kill_line_refutes_parent` refutes the parent's full predicate
shape — all five binders, `freshQueueCache` retained, the same three-conjunct
conclusion — on a witness whose `canDeposit = false` makes the first conjunct
false while the mutant still commits. -/

/-- Guard-drop mutant of `modelWithdrawDepositableEther`: the `canDeposit`
check is deleted; `authorizedRouter`, the nonzero-amount check, and the honest
`spendDepositableEther` spend transition are kept guard-for-guard. -/
private def mutantWithdrawNoCanDeposit (inputs : WithdrawInputs)
    (before : ReserveState) (amount : Word) : SourceOutcome :=
  if !inputs.authorizedRouter then .reverted "APP_AUTH_FAILED"
  else if amount = 0 then .reverted "ZERO_AMOUNT"
  else spendDepositableEther before amount

/-- Witness inputs for the guard-drop kill-line: the dropped `canDeposit`
guard is false, the retained `authorizedRouter` guard passes. -/
private def noCanDeposit : WithdrawInputs := ⟨false, true⟩

/-- Post-state the guard-drop mutant commits to on the standard vector: the
mutation removes a guard, not the transition, so this is exactly the honest
`spendDepositableEther vector (word 10)` post-state (see the `example`
pinning that spend above). -/
private def guardDropAfter : ReserveState :=
  { vector with
    buffered := word 90
    storedDepositsReserve := word 10
    depositedPostReport := word 13
    depositedNextReportAdjusted := word 12 }

/-- The honest model rejects the witness inputs at the deleted guard. -/
example : modelWithdrawDepositableEther noCanDeposit vector (word 10) =
    .reverted "CAN_NOT_DEPOSIT" := by decide

/-- The guard-drop mutant instead commits the honest spend. -/
example : mutantWithdrawNoCanDeposit noCanDeposit vector (word 10) =
    .committed guardDropAfter := by decide

/-- With `canDeposit = true` the mutant is indistinguishable from the honest
model: exactly one guard is deleted. -/
example : mutantWithdrawNoCanDeposit allowed vector (word 10) =
    modelWithdrawDepositableEther allowed vector (word 10) := by decide

/-- Concrete witness for the Wave 5 kill-line: freshness holds (`live = 50` is
exactly the cached `unfinalizedStETH`, as in the Wave 4 witness), the mutated
call COMMITS, and the parent's first conjunct `scopedWithdrawGuards inputs` is
FALSE because `canDeposit = false`. This is the negation of the registered
parent's conjunction on one premise-satisfying instance, with the
`freshQueueCache` premise retained. -/
theorem guard_drop_mutant_witness :
    freshQueueCache vector (word 50) ∧
    mutantWithdrawNoCanDeposit noCanDeposit vector (word 10) = .committed guardDropAfter ∧
    ¬ scopedWithdrawGuards noCanDeposit :=
  ⟨rfl, by decide, fun h => Bool.false_ne_true h.1⟩

/-- Wave 5 guard-drop kill-line for P-RESERVE-1: refutes the registered parent
`PReserve1.source_spend_preserves_withdrawal_reserve`'s own predicate shape —
same five binders, INCLUDING `freshQueueCache`, same three-conjunct conclusion
— with `mutantWithdrawNoCanDeposit` in place of
`modelWithdrawDepositableEther`. The witness above satisfies both premises
(fresh cache, committing mutated call) while falsifying the FIRST conjunct
(`scopedWithdrawGuards`: `canDeposit = false`), so the parent's conjunction
fails at a premise-satisfying witness. Division of labor: this kill-line
kills conjunct (1) (guard liveness);
`partition_spend_mutant_kill_line_refutes_parent` kills conjuncts (2)-(3)
(partition invariant and live-reserve invariance, freshness retained); the
stale-cache theorems remain premise-necessity evidence for `freshQueueCache`. -/
theorem guard_drop_kill_line_refutes_parent :
    ¬ ∀ (inputs : WithdrawInputs) (before after : ReserveState) (amount live : Word),
        freshQueueCache before live →
        mutantWithdrawNoCanDeposit inputs before amount = .committed after →
        scopedWithdrawGuards inputs ∧
          withdrawalPartitionSpendInvariant before after amount ∧
          liveEffectiveWithdrawalsReserve after live =
            liveEffectiveWithdrawalsReserve before live := by
  intro hforall
  have hcex := hforall noCanDeposit vector guardDropAfter (word 10) (word 50)
    guard_drop_mutant_witness.1 guard_drop_mutant_witness.2.1
  exact absurd hcex.1 guard_drop_mutant_witness.2.2

/-- A checked-Uint256 overflow after the source-ordered buffer work is still a
whole Verity transaction rollback. -/
example : specTx allowed
    { vector with depositedNextReportAdjusted := (Verity.Core.MAX_UINT256 : Word) }
    (word 1) =
    ⟨TxOutcome.reverted,
      { vector with depositedNextReportAdjusted := (Verity.Core.MAX_UINT256 : Word) },
      { vector with depositedNextReportAdjusted := (Verity.Core.MAX_UINT256 : Word) }⟩ := by decide

/-- Correspondence mutant: the source transcription swaps the two reserve
inputs before allocation.  The vector makes that source drift observable. -/
private def swappedReserveSourceMutant (before : ReserveState) (amount : Word) : SourceOutcome :=
  sourceSpendDepositableEther
    { before with
      storedDepositsReserve := before.unfinalizedStETH
      unfinalizedStETH := before.storedDepositsReserve }
    amount

example : sourceWithdrawDepositableEther allowed vector (word 10) =
    modelWithdrawDepositableEther allowed vector (word 10) := by decide

example : swappedReserveSourceMutant vector (word 30) ≠
    spendDepositableEther vector (word 30) := by decide

/-- Independence regression: mutating the MODEL transition does not silently
mutate the separately defined pinned-source execution transition. -/
example : reserveChangingMutant vector (word 10) ≠
    sourceSpendDepositableEther vector (word 10) := by decide

/-! ## Wave 1 premise-necessity evidence: stale WithdrawalQueue cache

`before`/`after` are the same vectors as
`LidoSRv3.Audit.SolidityReserve.staleQueueCacheKillLine_holds`. The spend is a
completely ordinary, legal `spendDepositableEther` commit — it satisfies the
*original* `withdrawalPartitionSpendInvariant` (the restated-field version)
with no trouble at all. The observation is that the same commit still shrinks
the *live* queue-facing reserve from 80 to 50 once the cached
`unfinalizedStETH = 50` is stale against a live WQ value of 80: exactly the
raid `report/P-RESERVE-1.md` issue #2 describes, and exactly what
`PReserve1.source_spend_preserves_withdrawal_reserve`'s `freshQueueCache`
hypothesis is there to rule out. This is hypothesis-NECESSITY evidence — it
refutes the freshness-dropped sibling claim, and the registered parent cannot
be instantiated on this witness at all. The parent kill-lines are
`partition_spend_mutant_kill_line_refutes_parent` (a mutated spend transition
with freshness retained, killing conjuncts (2)-(3)) and
`guard_drop_kill_line_refutes_parent` (a dropped `canDeposit` guard with
freshness retained, killing conjunct (1)) above. -/
private def staleCacheBefore : ReserveState :=
  { buffered := word 100
    storedDepositsReserve := word 20
    unfinalizedStETH := word 50
    depositedPostReport := word 3
    depositedNextReportAdjusted := word 2 }

private def staleCacheAfter : ReserveState :=
  { buffered := word 50
    storedDepositsReserve := word 0
    unfinalizedStETH := word 50
    depositedPostReport := word 53
    depositedNextReportAdjusted := word 52 }

/-- Premise-necessity witness: a legal spend that preserves the cached-field
invariant can still raid the live queue-facing reserve (80 -> 50) once the
cache is stale. This shows the parent's `freshQueueCache` hypothesis cannot be
dropped — it does NOT refute the registered parent, which cannot be
instantiated here (its freshness premise forces `live = 50`, where the
conclusion holds). Concrete counterpart to
`LidoSRv3.Audit.SolidityReserve.staleQueueCacheKillLine_holds`, referenced by
name from `PReserve1.source_spend_preserves_withdrawal_reserve`'s
docstring. -/
theorem stale_queue_cache_mutant_counterexample :
    spendDepositableEther staleCacheBefore (word 50) = .committed staleCacheAfter ∧
    withdrawalPartitionSpendInvariant staleCacheBefore staleCacheAfter (word 50) ∧
    liveEffectiveWithdrawalsReserve staleCacheAfter (word 80) ≠
      liveEffectiveWithdrawalsReserve staleCacheBefore (word 80) := by
  refine ⟨by decide, ?_, by decide⟩
  exact committed_preserves_withdrawal_reserve staleCacheBefore staleCacheAfter (word 50) (by decide)

/-- The strengthened registered parent rejects exactly this case: it cannot
be invoked here at all, because the only source of a `live` value in this
mutant is the stale cache itself, and `freshQueueCache staleCacheBefore live`
forces `live = staleCacheBefore.unfinalizedStETH = 50`, not the live `80`
that exposes the raid. Fixing `live := word 50` restores the theorem's
conclusion on this vector. -/
example :
    freshQueueCache staleCacheBefore (word 50) ∧
    modelWithdrawDepositableEther allowed staleCacheBefore (word 50) = .committed staleCacheAfter ∧
    liveEffectiveWithdrawalsReserve staleCacheAfter (word 50) =
      liveEffectiveWithdrawalsReserve staleCacheBefore (word 50) :=
  ⟨rfl, by decide, by decide⟩

end LidoSRv3.Tests.ReserveMutants
