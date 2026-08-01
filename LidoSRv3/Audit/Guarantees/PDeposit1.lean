import LidoSRv3.Audit.Trace
import LidoSRv3.Audit.Source.DepositCorrespondence
import LidoSRv3.Audit.Guarantees.Registry

namespace LidoSRv3.Audit.Guarantees.PDeposit1

open LidoSRv3.Audit
open LidoSRv3.Audit.SolidityDeposit

def guarantee : Guarantee := ⟨.pDeposit1, [.model, .abstractTx, .source]⟩

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
* `contracts/0.8.25/lib/BeaconChainDepositor.sol`,
  `makeBeaconChainDeposits32ETH`, lines 36--64.

Two claims, one per half of the guarantee wording.

*Conservation.* On every branch of the source-shaped path -- each of the nine
`revert` guards, the empty-batch early return at line 978, and the full push --
the wei pulled from Lido at line 983 equals the wei pushed to the beacon deposit
contract by the loop at `BeaconChainDepositor.sol` lines 53--63. This is exactly
the invariant the `assert` at line 996 checks, and it is proved, not assumed,
from the source-shaped code.

*Rollback.* Every guard on that path is a whole-transaction `revert` -- the
pinned span contains no `try`/`catch` and no failure-swallowing low-level call
-- so a reverting outcome maps onto the abstract-transaction model's `.reverted`
result, and `revert_restores_state_value_and_logs` restores the pre-state and
erases all committed ETH moves and logs.

Caveats, stated rather than hidden:

* `ConservingConfig` is a genuine hypothesis, not a tautology. The pull at line
  972 scales by `MAX_EFFECTIVE_BALANCE_WC_TYPE_01`, which is a constructor
  `immutable` (`StakingRouter.sol` line 65, assigned line 105), while the push
  is the literal `32 ether` `DEPOSIT_SIZE` (`BeaconChainDepositor.sol` line 24).
  `SolidityDeposit.pulled_eq_pushed_iff_conserving` shows the two agree *exactly
  when* the deployment sets them equal, so a misconfigured deployment is a real
  falsifier rather than something this proof papers over.
* Arithmetic is read as unbounded `Nat` (`A-SOURCE-SHAPED`): truncating `Nat`
  division matches EVM `DIV`, but no overflow reasoning is performed.
* The rollback half is stated against the abstract transaction model
  (`A-ABSTRACT-TX`), so the EVM plane stays open.
-/
theorem source_deposit_conserves_and_rolls_back {State : Type}
    (cfg : SourceDepositConfig) (inp : SourceDepositInput)
    (before after : State) (attempts : List CallAttempt) (trace : CommitTrace)
    (hCfg : ConservingConfig cfg) :
    (run cfg inp).pulled = (run cfg inp).pushed ∧
      ((run cfg inp).reverts = true →
        (observation before after attempts trace (run cfg inp)).committedState = before ∧
          (observation before after attempts trace (run cfg inp)).committedTrace.ethMoves = [] ∧
          (observation before after attempts trace (run cfg inp)).committedTrace.logs = []) :=
  ⟨run_conserves cfg inp hCfg, fun h => reverting_outcome_rolls_back before after attempts trace h⟩

/--
The `assert(etherBalanceBeforeDeposits == etherBalanceAfterDeposits)` at
`StakingRouter.sol` line 996 holds on the committing push branch: the router
forwards every pulled wei and retains none.
-/
theorem source_router_balance_unchanged
    (cfg : SourceDepositConfig) (inp : SourceDepositInput)
    {keys pulled pushed balanceAfter : Nat}
    (hCfg : ConservingConfig cfg)
    (hRun : run cfg inp = .committedDeposits keys pulled pushed balanceAfter) :
    balanceAfter = inp.routerBalanceBefore :=
  (committed_balance_preserved hCfg hRun).2

/--
A reverting branch of the pinned path moves no wei in either direction: the pull
at line 983 is strictly after every guard at lines 946--978.
-/
theorem source_reverting_branch_moves_no_ether
    {o : SolidityDeposit.Outcome} (h : o.reverts = true) :
    o.pulled = 0 ∧ o.pushed = 0 :=
  reverting_moves_no_ether h

end LidoSRv3.Audit.Guarantees.PDeposit1
