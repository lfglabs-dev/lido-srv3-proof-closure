import LidoSRv3.Audit.Allocation
import LidoSRv3.Audit.Trace
import LidoSRv3.Audit.Source.TopupCorrespondence
import LidoSRv3.Audit.Verity.TopupHybrid
import LidoSRv3.Audit.Guarantees.Registry

namespace LidoSRv3.Audit.Guarantees.PTopup1

open LidoSRv3.Audit
open LidoSRv3.Audit.SolidityTopup

def guarantee : Guarantee := ⟨.pTopup1, [.model, .source, .verityTx]⟩

/-- Source-shaped allocation-model ordering fact; extraction is not established. -/
theorem valid_result_preserves_router_order
    {snapshot : LidoSRv3.Audit.AllocationSnapshot}
    {result : LidoSRv3.Audit.AllocationResult} :
    LidoSRv3.Audit.validAllocationResult snapshot result →
      List.map LidoSRv3.Audit.AllocationResultRow.moduleId result.rows =
        List.map LidoSRv3.Audit.AllocationRow.moduleId snapshot.rows :=
  @LidoSRv3.Audit.valid_result_preserves_router_order snapshot result

/-- Abstract transaction rollback, not an executable EVM trace. -/
theorem revert_restores_state_value_and_logs {State : Type} :
    ∀ (tx : LidoSRv3.Audit.TxObservation State),
      tx.result = LidoSRv3.Audit.TxResult.reverted →
        tx.committedState = tx.before ∧ tx.committedTrace.ethMoves = [] ∧
          tx.committedTrace.logs = [] :=
  @LidoSRv3.Audit.revert_restores_state_value_and_logs State

/--
Pinned-source conservation and rollback correspondence for the SRv3 beacon-chain
top-up push at `lidofinance/core@af095e48bbc1c3841c2c9936219c8461af01056b`:

* `contracts/0.8.25/sr/StakingRouter.sol`, `topUp`, lines 679--759;
* `contracts/0.8.25/sr/StakingRouter.sol`, `_validateTopUpInputs`, lines 761--782;
* `contracts/0.8.25/sr/StakingRouter.sol`, `_checkAppAuth`, lines 1177--1179;
* `contracts/0.8.25/sr/StakingRouter.sol`, `_getTopUpGateway`, lines 1169--1171;
* `contracts/0.8.25/sr/StakingRouter.sol`, `_getModuleState`, lines 1099--1107;
* `contracts/0.8.25/sr/SRUtils.sol`, `_requireWCType2`, lines 41--43;
* `contracts/0.8.25/sr/SRUtils.sol`, `_requireModuleIdExists`, lines 45--47;
* `contracts/0.8.25/sr/StakingRouter.sol`, `PUBKEY_LENGTH`, line 57;
* `contracts/0.8.25/lib/BeaconChainDepositor.sol`, `PUBLIC_KEY_LENGTH`, line 21;
* `contracts/0.8.25/lib/BeaconChainDepositor.sol`, `MIN_DEPOSIT`, line 28;
* `contracts/0.4.24/Lido.sol`, `withdrawDepositableEther`, lines 869--886;
* `contracts/0.4.24/Lido.sol`, `_spendDepositableEther`, lines 839--859;
* `contracts/0.8.25/lib/BeaconChainDepositor.sol`, `makeBeaconChainTopUp`,
  lines 66--108.

Two claims, one per half of the guarantee wording.

*Conservation.* On every branch of the source-shaped path -- each authorization,
input-validation, module-status, allocation-loop, Lido-side and per-key guard, the
empty-top-up early commit at source line 741, and the full push -- the wei pulled
from Lido at source line 744 equals the wei pushed to the beacon deposit contract
by the loop at `BeaconChainDepositor.sol` lines 79--107.

Unlike the 32-ETH deposit path (P-DEPOSIT-1), this holds *unconditionally*, with
no deployment-configuration side condition. The reason is structural: the pulled
`amount` accumulated at source line 732 and the pushed sum at
`BeaconChainDepositor.sol` line 106 are two readings of the *same* `_amounts`
array, not a count multiplied by two separately-configured constants.
`SolidityTopup.pulled_eq_pushed` records that, and
`SolidityTopup.loopPushed_eq_allocSum` records that the `if (amount == 0) continue`
skip at `BeaconChainDepositor.sol` line 89 loses nothing, because a skipped entry
contributes zero to the pull as well.

*Rollback.* Every guard on that path is a whole-transaction abort -- the pinned
span contains no `try`/`catch` and no failure-swallowing low-level call, and a
failing `assert` is a Solidity 0.8 `Panic(0x01)` -- so a reverting outcome maps
onto the abstract-transaction model's `.reverted` result, and
`revert_restores_state_value_and_logs` restores the pre-state and erases all
committed ETH moves and logs. That includes the
`_checkAppAuth(_getTopUpGateway())` at source line 686 -- whose helper bodies at
lines 1169--1171 and 1177--1179 are pinned above rather than assumed -- which is
modelled as the
*first* guard: `SolidityTopup.unauthorized_reverts` shows an unauthorized caller
reverts before the line 687 input validation, and
`SolidityTopup.committing_implies_authorized` shows neither committing branch is
reachable without the gateway. The branch correspondence therefore covers every
source execution rather than silently assuming an authorized caller.

Caveats, stated rather than hidden:

* Arithmetic is read as unbounded `Nat` (`A-SOURCE-SHAPED`): truncating `Nat`
  division matches EVM `DIV`, but no overflow reasoning is performed. This
  matters here specifically: source line 722 opens an `unchecked` block, so the
  `amount += _amounts[i]` at line 732 wraps mod 2^256 on chain rather than
  reverting. Under such a wrap the pull would be strictly less than the push and
  the line 755 `assert` would become load-bearing again. The corresponding
  `Outcome` constructors are deliberately *retained* rather than deleted, and
  `source_balance_guards_discharged` takes the no-wrap fact as an explicit
  hypothesis (`A-TOPUP-NOWRAP`) rather than a bounded-arithmetic proof.
* The empty-top-up branch at source line 741 is a *commit*, not a revert:
  `SolidityTopup.committedNoTopUp_is_not_a_rollback` records this, so no reader
  can mistake the rollback theorem for a claim that a zero-amount top-up aborts.
* The rollback half is stated against the abstract transaction model
  (`A-ABSTRACT-TX`), so the EVM plane stays open.
* Out of scope here and left open: the per-validator top-up *amount computation*
  and limit accounting (P-TOPUP-2), the allocation algorithm producing
  `_amounts` (P-ALLOC-1/2), and the SSZ deposit-data-root construction at
  `BeaconChainDepositor.sol` lines 120--146 (P-SSZ-1).
-/
theorem source_topup_conserves_and_rolls_back {State : Type}
    (cfg : SourceTopupConfig) (inp : SourceTopupInput)
    (before after : State) (attempts : List CallAttempt) (trace : CommitTrace) :
    (run cfg inp).pulled = (run cfg inp).pushed ∧
      ((run cfg inp).reverts = true →
        (observation before after attempts trace (run cfg inp)).committedState = before ∧
          (observation before after attempts trace (run cfg inp)).committedTrace.ethMoves = [] ∧
          (observation before after attempts trace (run cfg inp)).committedTrace.logs = []) :=
  ⟨run_conserves cfg inp, fun h => reverting_outcome_rolls_back before after attempts trace h⟩

/--
The `assert(etherBalanceBeforeTopUp == etherBalanceAfterTopUp)` at
`StakingRouter.sol` line 755 holds on the committing push branch: the router
forwards every pulled wei and retains none.
-/
theorem source_router_balance_unchanged
    (cfg : SourceTopupConfig) (inp : SourceTopupInput)
    {keys pulled pushed balanceAfter : Nat}
    (hRun : run cfg inp = .committedTopUp keys pulled pushed balanceAfter) :
    balanceAfter = inp.routerBalanceBefore :=
  (committed_balance_preserved hRun).2

/--
A reverting branch of the pinned path moves no wei in either direction: the pull
at source line 744 is strictly after every guard at lines 686--741, and the line
755 `assert` rolls the whole transaction back.
-/
theorem source_reverting_branch_moves_no_ether
    {o : SolidityTopup.Outcome} (h : o.reverts = true) :
    o.pulled = 0 ∧ o.pushed = 0 :=
  reverting_moves_no_ether h

/--
The two value-conservation guards on the pinned path are *discharged*, not
assumed: no input reaches the line 755 `assert` failure, and no input reaches a
push that exceeds the router's funded balance. This is strictly stronger than the
32-ETH deposit path, where the analogous assert is load-bearing and only holds
under a deployment-configuration side condition.

The honest reading of this pair is: given that the accumulation at source line
732 does not wrap, a top-up can never strand wei in the router *and* can never
attempt to push wei it does not hold. That no-wrap fact is carried as the
explicit `SolidityTopup.NoUncheckedWrap` hypothesis rather than left implicit,
because it is not derivable from the pinned P-TOPUP-1 spans -- the per-index cap
at source line 728 comes from `TopUpGateway` (P-TOPUP-2) and the key count is
unbounded here. It is recorded as `A-TOPUP-NOWRAP` in `audit/assumptions.yaml`,
and `SolidityTopup.totalAllocated_faithful` proves that under exactly this
hypothesis the source's `unchecked` accumulation and the model's `Nat` sum are
the same number, which is what makes the discharge a statement about line 732.
-/
theorem source_balance_guards_discharged
    (cfg : SourceTopupConfig) (inp : SourceTopupInput)
    (hNoWrap : NoUncheckedWrap inp) :
    run cfg inp ≠ .revertAssertBalanceUnchanged ∧
      run cfg inp ≠ .revertInsufficientRouterBalance :=
  ⟨run_ne_revertAssertBalanceUnchanged cfg inp hNoWrap,
    run_ne_revertInsufficientRouterBalance cfg inp hNoWrap⟩

/--
The bridge that makes `source_balance_guards_discharged` a claim about the
`unchecked` accumulation at `StakingRouter.sol` line 732 rather than only about
this module's `Nat` sum: under `NoUncheckedWrap` the two readings coincide.

This is the proved half of `A-TOPUP-NOWRAP`. The assumption is exactly the
`inp.NoUncheckedWrap` premise; everything downstream of it is checked.
-/
theorem source_unchecked_accumulation_faithful
    (inp : SourceTopupInput) (hNoWrap : NoUncheckedWrap inp) :
    allocSumUnchecked inp.allocations = totalAllocated inp :=
  totalAllocated_faithful hNoWrap

/--
In the pinned deployment the router's own pubkey-length validation at source
lines 777--779 discharges `BeaconChainDepositor`'s per-key check at
`BeaconChainDepositor.sol` lines 82--84, because `StakingRouter.PUBKEY_LENGTH`
(source line 57) and `BeaconChainDepositor.PUBLIC_KEY_LENGTH`
(`BeaconChainDepositor.sol` line 21) are both 48.

The hypothesis is discharged by `SolidityTopup.pinnedConfig_pubkey_lengths_agree`
rather than assumed, so a hypothetical redeployment that split the two constants
is a real falsifier and is not papered over.
-/
theorem source_pinned_config_discharges_pubkey_guard (inp : SourceTopupInput) :
    run pinnedConfig inp ≠ .revertInvalidPublicKeyLength :=
  run_ne_revertInvalidPublicKeyLength pinnedConfig_pubkey_lengths_agree

/-- Hybrid SOURCE-to-VERITY_TX closure under the explicit source-line-732
no-wrap premise. The independent source interpreter then supplies the full
faithful guard/loop outcome; the typed Verity suffix contains the two
value-bearing call sites and `Contract.run` supplies snapshot rollback. Yul,
EVM and deployed multi-contract call semantics remain explicitly open. -/
theorem verity_tx_simulates_source
    (cfg : SourceTopupConfig) (inp : SourceTopupInput)
    (hNoWrap : NoUncheckedWrap inp)
    (state : _root_.Verity.ContractState) :
    LidoSRv3.Audit.Verity.TopupHybrid.observeVerity state
        ((LidoSRv3.Audit.Verity.TopupHybrid.executeSource cfg inp).run state) =
      LidoSRv3.Audit.Verity.TopupHybrid.sourceTx cfg inp state :=
  LidoSRv3.Audit.Verity.TopupHybrid.verity_tx_simulates_source cfg inp hNoWrap state

end LidoSRv3.Audit.Guarantees.PTopup1
