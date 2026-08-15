import LidoSRv3.Audit.Trace
import LidoSRv3.Audit.Source.DepositCorrespondence
import LidoSRv3.Audit.Verity.DepositTx
import LidoSRv3.Audit.Guarantees.Registry

namespace LidoSRv3.Audit.Guarantees.PDeposit1

open LidoSRv3.Audit
open LidoSRv3.Audit.SolidityDeposit

def guarantee : Guarantee := ⟨.pDeposit1, [.model, .abstractTx, .source, .verityTx]⟩

/-- Public P-DEPOSIT-1 transaction-plane closure for one bounded deposit unit.
The result is an actual `Verity.Contract.run` observation at the summarized-call
boundary: Lido loses exactly `amount`, the modeled beacon sink gains exactly
`amount`, and router ETH plus the withdrawal reserve are unchanged. -/
theorem tx_one_unit_exact_transfer
    {cfg : SourceDepositConfig} {inp : SourceDepositInput}
    {snapshot : _root_.Verity.ContractState}
    {balances : LidoSRv3.Audit.Verity.DepositTx.Balances} {amount : Nat}
    (hRun : run cfg inp = .committedDeposits 1 amount amount inp.routerBalanceBefore)
    (hBound : amount ≤ _root_.Verity.Core.MAX_UINT256)
    (hFunds : amount ≤ balances.lidoDepositable) :
    let tx := LidoSRv3.Audit.Verity.DepositTx.observe snapshot balances
      ((LidoSRv3.Audit.Verity.DepositTx.executeOutcome cfg inp balances).run snapshot)
    tx.status = .committed ∧
      (_root_.Verity.Core.Uint256.ofNat amount).val = amount ∧
      tx.balancesAfter.lidoDepositable + amount = balances.lidoDepositable ∧
      tx.balancesAfter.beaconSink = balances.beaconSink + amount ∧
      tx.balancesAfter.routerEth = balances.routerEth ∧
      tx.balancesAfter.withdrawalReserve = balances.withdrawalReserve :=
  LidoSRv3.Audit.Verity.DepositTx.one_unit_exact_transfer hRun hBound hFunds

/-- Public transaction-plane rollback theorem: any source revert restores the
exact Verity snapshot and exposes no committed modeled balance effects. -/
theorem tx_revert_restores_snapshot_and_effects
    (cfg : SourceDepositConfig) (inp : SourceDepositInput)
    (snapshot : _root_.Verity.ContractState)
    (balances : LidoSRv3.Audit.Verity.DepositTx.Balances)
    (h : (run cfg inp).reverts = true) :
    let tx := LidoSRv3.Audit.Verity.DepositTx.observe snapshot balances
      ((LidoSRv3.Audit.Verity.DepositTx.executeOutcome cfg inp balances).run snapshot)
    tx.status = .reverted ∧ tx.after = snapshot ∧ tx.balancesAfter = balances :=
  LidoSRv3.Audit.Verity.DepositTx.source_revert_restores_committed_effects
    cfg inp snapshot balances h

/-- Abstract transaction rollback, not an executable EVM trace. -/
theorem revert_restores_state_value_and_logs {State : Type} :
    ∀ (tx : LidoSRv3.Audit.TxObservation State),
      tx.result = LidoSRv3.Audit.TxResult.reverted →
        tx.committedState = tx.before ∧ tx.committedTrace.ethMoves = [] ∧
          tx.committedTrace.logs = [] :=
  @LidoSRv3.Audit.revert_restores_state_value_and_logs State

/--
Pinned-source conservation and rollback correspondence for the SRv3 deposit
push at `lidofinance/core@af095e48bbc1c3841c2c9936219c8461af01056b`:

* `contracts/0.8.25/sr/StakingRouter.sol`, `deposit`, lines 942--997;
* `contracts/0.4.24/Lido.sol`, `withdrawDepositableEther`, lines 869--886;
* `contracts/0.4.24/Lido.sol`, `_spendDepositableEther`, lines 839--859;
* `contracts/0.8.25/lib/BeaconChainDepositor.sol`,
  `makeBeaconChainDeposits32ETH`, lines 36--64.

Two claims, one per half of the guarantee wording.

*Conservation.* On every branch of the source-shaped path -- each source
`revert` or arithmetic-panic guard, the failing line 996 `assert`, the empty-batch early return at
line 978, and the full push -- the wei pulled from Lido at line 983 equals the wei
pushed to the beacon deposit contract by the loop at `BeaconChainDepositor.sol`
lines 53--63. This is exactly the invariant the `assert` at line 996 checks, and
it is proved, not assumed, from the source-shaped code.

*Rollback.* Every guard on that path is a whole-transaction abort -- the pinned
span contains no `try`/`catch` and no failure-swallowing low-level call, and a
failing `assert` is a Solidity 0.8 `Panic(0x01)` -- so a reverting outcome maps
onto the abstract-transaction model's `.reverted` result, and
`revert_restores_state_value_and_logs` restores the pre-state and erases all
committed ETH moves and logs. Locator-derived DSM authentication at lines 943
and 1173--1179 remains an interface fact outside this data-only model, so this
is not a claim about every possible caller.

Caveats, stated rather than hidden:

* Conservation is unconditional here only because the line 996 `assert` is
  modelled as the revert it is. The pull at line 972 scales by
  `MAX_EFFECTIVE_BALANCE_WC_TYPE_01`, which is a constructor `immutable`
  (`StakingRouter.sol` line 65, assigned line 105), while the push is the literal
  `32 ether` `DEPOSIT_SIZE` (`BeaconChainDepositor.sol` line 24).
  `SolidityDeposit.pulled_eq_pushed_iff_conserving` shows the two agree *exactly
  when* the deployment sets them equal, and
  `SolidityDeposit.committed_implies_conserving` shows a deployment that sets
  them apart reverts instead of committing. A misconfigured deployment is
  therefore a real falsifier of the *commit*, not something this proof papers
  over -- and not a silent stranding of the difference in the router either.
* Arithmetic is read as unbounded `Nat` (`A-SOURCE-SHAPED`): truncating `Nat`
  division matches EVM `DIV`, but no overflow reasoning is performed.
* The rollback half is stated against the abstract transaction model
  (`A-ABSTRACT-TX`), so the EVM plane stays open.
-/
theorem source_deposit_conserves_and_rolls_back {State : Type}
    (cfg : SourceDepositConfig) (inp : SourceDepositInput)
    (before after : State) (attempts : List CallAttempt) (trace : CommitTrace) :
    (run cfg inp).pulled = (run cfg inp).pushed ∧
      ((run cfg inp).reverts = true →
        (observation before after attempts trace (run cfg inp)).committedState = before ∧
          (observation before after attempts trace (run cfg inp)).committedTrace.ethMoves = [] ∧
          (observation before after attempts trace (run cfg inp)).committedTrace.logs = []) :=
  ⟨run_conserves cfg inp, fun h => reverting_outcome_rolls_back before after attempts trace h⟩

/--
The `assert(etherBalanceBeforeDeposits == etherBalanceAfterDeposits)` at
`StakingRouter.sol` line 996 holds on the committing push branch: the router
forwards every pulled wei and retains none.
-/
theorem source_router_balance_unchanged
    (cfg : SourceDepositConfig) (inp : SourceDepositInput)
    {keys pulled pushed balanceAfter : Nat}
    (hRun : run cfg inp = .committedDeposits keys pulled pushed balanceAfter) :
    balanceAfter = inp.routerBalanceBefore :=
  (committed_balance_preserved hRun).2

/--
A reverting branch of the pinned path moves no wei in either direction: the pull
at line 983 is strictly after every guard at lines 946--978, and the line 996
`assert` rolls the whole transaction back.
-/
theorem source_reverting_branch_moves_no_ether
    {o : SolidityDeposit.Outcome} (h : o.reverts = true) :
    o.pulled = 0 ∧ o.pushed = 0 :=
  reverting_moves_no_ether h

/--
A deployment whose `MAX_EFFECTIVE_BALANCE_WC_TYPE_01` (`StakingRouter.sol` line
65) differs from `DEPOSIT_SIZE` (`BeaconChainDepositor.sol` line 24) reverts on a
nonempty key batch: the `assert` at `StakingRouter.sol` line 996 fails and aborts
the whole transaction, so the difference is not left stranded in the router.

The nonempty hypothesis is load-bearing and is stated rather than hidden.  With a
zero-key batch the call returns at line 978 *before* reaching the line 996
`assert`, and that early return is a commit (`committedNoDeposits`), not a
revert.  So the revert claim holds exactly where the assert is actually reached;
the second conjunct records the unconditional part -- no configuration mismatch
ever produces a committed *push*, batch empty or not.
-/
theorem source_nonconserving_deployment_reverts
    (cfg : SourceDepositConfig) (inp : SourceDepositInput)
    (hCfg : ¬ ConservingConfig cfg) (hKeys : 0 < actualDepositsCount cfg inp) :
    (run cfg inp).reverts = true ∧
      ∀ keys pulled pushed balanceAfter,
        run cfg inp ≠ .committedDeposits keys pulled pushed balanceAfter :=
  ⟨not_conserving_nonempty_reverts hCfg hKeys, not_conserving_reverts hCfg⟩

end LidoSRv3.Audit.Guarantees.PDeposit1
