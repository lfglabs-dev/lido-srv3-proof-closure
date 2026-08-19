import LidoSRv3.Audit.Source.ReserveCorrespondence
import LidoSRv3.Audit.Guarantees.Registry

namespace LidoSRv3.Audit.Guarantees.PReserve1

open Verity
open LidoSRv3.Audit.SolidityReserve

def guarantee : Guarantee := ⟨.pReserve1, [.model, .source, .verityTx]⟩

/-- Registered Wave 1 parent for P-RESERVE-1. Strengthened along the three
axes `report/P-RESERVE-1.md` calls out (issues #1, #2, #5):

* the premise is `modelWithdrawDepositableEther`, the full wrapper
  transition that enforces `canDeposit`/`authorizedRouter`
  (`scopedWithdrawGuards`) before ever reaching `_spendDepositableEther`, not
  the bare internal spend helper the original theorem quoted. The conclusion
  now *proves* `scopedWithdrawGuards inputs`, rather than assuming it: a
  guard failure reverts, so it can never reach the `.committed` branch this
  theorem is about;
* the conclusion adds `liveEffectiveWithdrawalsReserve after live =
  liveEffectiveWithdrawalsReserve before live`, the *effective*, min-capped,
  queue-facing reserve computed against an explicit `live` value standing in
  for a `WithdrawalQueue.unfinalizedStETH()` CALL — not merely the restated
  `storedDepositsReserve` field that `withdrawalPartitionSpendInvariant`
  quotes;
* that added conjunct needs `freshQueueCache before live`, naming the
  cache-freshness the original theorem left implicit. Drop that hypothesis
  and the identical spend from `depositsReserve + unreserved` can still raid
  the live reserve — see `staleQueueCacheKillLine_holds` and
  `LidoSRv3.Tests.ReserveMutants.stale_queue_cache_mutant_counterexample` for
  the concrete premise-necessity witness (it refutes the freshness-dropped
  sibling claim, i.e. shows the hypothesis cannot be removed; it does not
  refute this parent, which cannot be instantiated on that stale-cache
  vector).

The parent kill-lines, one per conjunct group, each the negation of this
theorem's full predicate shape — all five binders, `freshQueueCache`
hypothesis retained, same three-conjunct conclusion — applied to a mutant of
`modelWithdrawDepositableEther`:

* `LidoSRv3.Tests.ReserveMutants.guard_drop_kill_line_refutes_parent` kills
  conjunct (1) (`scopedWithdrawGuards` guard liveness): the mutant
  `mutantWithdrawNoCanDeposit` deletes only the `canDeposit` check, so on the
  witness (`canDeposit = false`, `authorizedRouter = true`, nonzero amount,
  fresh cache) the mutated call commits while the first conjunct is false.
* `LidoSRv3.Tests.ReserveMutants.partition_spend_mutant_kill_line_refutes_parent`
  kills conjuncts (2)-(3): the mutant `mutantWithdraw` keeps every guard and
  mutates the spend transition (`withdrawalPartitionMutant` commits the
  spend, then overwrites `buffered` with the post-spend
  `storedDepositsReserve`). On the witness vector the mutated call commits
  under a fresh cache while the live queue-facing reserve drops 50 → 0.

The original `withdrawalPartitionSpendInvariant` conjunct is retained so
existing consumers of this theorem name keep their evidence. -/
theorem source_spend_preserves_withdrawal_reserve
    (inputs : WithdrawInputs) (before after : ReserveState) (amount live : Word)
    (hfresh : freshQueueCache before live)
    (h : modelWithdrawDepositableEther inputs before amount = .committed after) :
    scopedWithdrawGuards inputs ∧
      withdrawalPartitionSpendInvariant before after amount ∧
      liveEffectiveWithdrawalsReserve after live = liveEffectiveWithdrawalsReserve before live := by
  unfold modelWithdrawDepositableEther at h
  split at h
  · contradiction
  · rename_i hcan
    split at h
    · contradiction
    · rename_i hauth
      split at h <;> try contradiction
      refine ⟨⟨?_, ?_⟩, committed_preserves_withdrawal_reserve before after amount h,
        committed_preserves_live_effective_withdrawals_reserve before after amount live hfresh h⟩
      · simpa using hcan
      · simpa using hauth

/--
Faithful VERITY_TX closure for P-RESERVE-1. This theorem starts with the actual
`Verity.Contract.run` result of the source-shaped reserve spend and proves that
its committed/reverted observable transition is the abstract reserve
transaction. In particular, every `safeAdd`/`safeSub` failure and
`NOT_ENOUGH_ETHER` branch observes Verity's pre-call rollback state.

This is not an EVM theorem: storage-slot numbers are a model-local projection,
and no Solidity compiler, Yul, runtime bytecode, proxy layout, deployed code,
or external-call semantics is claimed.
-/
theorem verity_tx_simulates_reserve_spec (inputs : WithdrawInputs)
    (state : ContractState) (amount : Word) :
    observeVerity state ((ReserveContract.withdrawWithGuards inputs amount).run state) =
      specTx inputs (decode state) amount ∧
    ∀ reason rollback,
      (ReserveContract.withdrawWithGuards inputs amount).run state = .revert reason rollback →
      rollback = state :=
  ⟨verity_execution_simulates_spec state amount inputs,
    fun reason rollback h =>
      verity_revert_rolls_back inputs state amount reason rollback h⟩

/-- On a committing executable Verity transition, the prohibited reserve state
is observationally unchanged. -/
theorem verity_tx_preserves_withdrawal_reserve
    (inputs : WithdrawInputs) (state after : ContractState) (amount : Word)
    (h : (ReserveContract.withdrawWithGuards inputs amount).run state = .success () after) :
    withdrawalPartitionSpendInvariant (decode state) (decode after) amount :=
  verity_commit_preserves_withdrawal_reserve inputs state after amount h

end LidoSRv3.Audit.Guarantees.PReserve1
