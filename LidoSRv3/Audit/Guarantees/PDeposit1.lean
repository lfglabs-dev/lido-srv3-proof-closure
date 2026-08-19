import LidoSRv3.Audit.Trace
import LidoSRv3.Audit.Source.DepositCorrespondence
import LidoSRv3.Audit.Verity.DepositParentTx
import LidoSRv3.Audit.Guarantees.Registry

namespace LidoSRv3.Audit.Guarantees.PDeposit1

open LidoSRv3.Audit
open LidoSRv3.Audit.SolidityDeposit

/-- The registry exposes the abstract/source proof and the composed bounded
executable Verity transaction evidence. -/
def guarantee : Guarantee := ⟨.pDeposit1, [.model, .abstractTx, .source, .verityTx]⟩

/-- Abstract transaction rollback, not an executable EVM trace.  This fact is
definitional in the `TxObservation` model -- `committedState`/`committedTrace`
of `.reverted` are `before`/`⟨[], [], []⟩` by definition, and `observation`
maps every reverting outcome to `.reverted` -- so it is kept as an
unregistered child rather than as a conjunct of the registered parent
`source_deposit_conserves_and_rolls_back`.  The load-bearing rollback evidence
is on the executable plane (conjunct (b) of
`verity_tx_composes_deposit_conservation_and_rollback`). -/
theorem revert_restores_state_value_and_logs {State : Type} :
    ∀ (tx : LidoSRv3.Audit.TxObservation State),
      tx.result = LidoSRv3.Audit.TxResult.reverted →
        tx.committedState = tx.before ∧ tx.committedTrace.ethMoves = [] ∧
          tx.committedTrace.logs = [] :=
  @LidoSRv3.Audit.revert_restores_state_value_and_logs State

/--
Commit-branch-explicit conservation, and rollback of the deployments that
would break it, for the SRv3 deposit push at
`lidofinance/core@af095e48bbc1c3841c2c9936219c8461af01056b`:

* `contracts/0.8.25/sr/StakingRouter.sol`, `deposit`, lines 942--997;
* `contracts/0.4.24/Lido.sol`, `withdrawDepositableEther`, lines 869--886;
* `contracts/0.4.24/Lido.sol`, `_spendDepositableEther`, lines 839--859;
* `contracts/0.8.25/lib/BeaconChainDepositor.sol`,
  `makeBeaconChainDeposits32ETH`, lines 36--64.

Two conjuncts, one per half of the guarantee wording; neither is definitional.

*Conservation.* On the committed-push branch -- the only branch that moves wei
-- the wei pulled from Lido at line 983 equals the wei pushed to the beacon
deposit contract by the loop at `BeaconChainDepositor.sol` lines 53--63, and
the two independently written source formulas agree: line 972's
`depositsValue = actualDepositsCount * MAX_EFFECTIVE_BALANCE_WC_TYPE_01` and
the loop's `pushedValue`.  This is exactly the invariant the `assert` at line
996 checks, and it is proved from the source-shaped guard structure, not
assumed: `committedDeposits` carries arbitrary `Nat`s, and only the assert
gate forces the equality.  The claim is deliberately restricted to the
committed branch because `Outcome.pulled`/`Outcome.pushed` are defined as `0`
on every other branch, so a whole-path accessor equality would be mostly
`0 = 0`.  The kill-line
`LidoSRv3.Tests.DepositVectors.dropped_conservation_assert_breaks_pulled_eq_pushed`
shows this conjunct is load-bearing: dropping the line 996 assert branch from
`run` (`SolidityDeposit.mutantRun`) lets a skewed deployment commit with
`pulled ≠ pushed`.

*Rollback.* A deployment whose `MAX_EFFECTIVE_BALANCE_WC_TYPE_01`
(`StakingRouter.sol` line 65) differs from `DEPOSIT_SIZE`
(`BeaconChainDepositor.sol` line 24) never commits a mismatched push: on any
nonempty key batch the whole transaction reverts -- the failing line 996
`assert` is a Solidity 0.8 `Panic(0x01)`, and the pinned span contains no
`try`/`catch` and no failure-swallowing low-level call.  This is the
source-plane rollback content, and it is not definitional either: it needs the
empty-batch early return at line 978 excluded (`committedNoDeposits`) and the
assert gate to exclude a mismatched commit (`committed_implies_conserving`).

Caveats, stated rather than hidden:

* The abstract-transaction rollback fact used in earlier revisions --
  `observation` maps a reverting outcome to `.reverted`, whose
  `committedState`/`committedTrace` are `before`/`⟨[], [], []⟩` by definition
  (`A-ABSTRACT-TX`) -- is definitional in this model and is therefore *not* a
  conjunct of this registered parent.  It remains available as the
  unregistered child `revert_restores_state_value_and_logs` (and
  `SolidityDeposit.reverting_outcome_rolls_back`).
* Conservation on the commit branch holds without a `ConservingConfig`
  hypothesis only because the line 996 `assert` is modelled as the revert it
  is; `SolidityDeposit.pulled_eq_pushed_iff_conserving` shows the pull and
  push scales agree *exactly when* the deployment sets them equal.
* Arithmetic is read as unbounded `Nat` (`A-SOURCE-SHAPED`): truncating `Nat`
  division matches EVM `DIV`, but no overflow reasoning is performed.
* Locator-derived DSM authentication at lines 943 and 1173--1179 remains an
  interface fact outside this data-only model, so this is not a claim about
  every possible caller.
-/
theorem source_deposit_conserves_and_rolls_back
    (cfg : SourceDepositConfig) (inp : SourceDepositInput) :
    (∀ keys pulled pushed balanceAfter,
        run cfg inp = .committedDeposits keys pulled pushed balanceAfter →
          pulled = pushed ∧ depositsValue cfg inp = pushedValue cfg inp) ∧
      (¬ ConservingConfig cfg → 0 < actualDepositsCount cfg inp →
        (run cfg inp).reverts = true) := by
  constructor
  · intro keys pulled pushed balanceAfter hRun
    obtain ⟨-, -, hPulled, hPushed, hMoved, -⟩ := committed_deposits_spec hRun
    exact ⟨hMoved, hPulled.symm.trans (hMoved.trans hPushed)⟩
  · intro hCfg hKeys
    exact not_conserving_nonempty_reverts hCfg hKeys

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

/-! ## Composition with the executable Verity transaction

The abstract/source plane above and the executable plane below are joined by
`LinksSource`, which pins the transaction's inputs to the pinned-source
quantities.  Nothing in the composed theorem is a ground term: it quantifies
over every configuration, call input, transaction input and entry state that
the link and the transaction's own guards permit.
-/

open LidoSRv3.Audit.Verity.DepositParentTx

/--
Bridge from the pinned-source deposit model to the executable transaction's
inputs.  Each field names the source quantity it pins:

* `depositSize` -- `BeaconChainDepositor.DEPOSIT_SIZE` (`BeaconChainDepositor.sol`
  line 24), the per-key wei the loop at line 57 sends;
* `keys` -- the two legs partition `actualDepositsCount` from `StakingRouter.sol`
  line 967;
* `firstAmount`/`secondAmount` -- each leg carries exactly `DEPOSIT_SIZE` per key.

The link is data-only: it says nothing about the post-state, so it cannot
smuggle the conclusion in.
-/
structure LinksSource (cfg : SourceDepositConfig) (inp : SourceDepositInput)
    (inputs : Inputs) : Prop where
  depositSize : inputs.depositSize.val = cfg.depositSize
  keys : inputs.first.keys.val + inputs.second.keys.val = actualDepositsCount cfg inp
  firstAmount : inputs.first.amount.val = inputs.first.keys.val * cfg.depositSize
  secondAmount : inputs.second.amount.val = inputs.second.keys.val * cfg.depositSize

/-- The wei the two beacon legs move is exactly the loop total at
`BeaconChainDepositor.sol` lines 53--63. -/
theorem linked_total_eq_pushedValue (cfg : SourceDepositConfig) (inp : SourceDepositInput)
    (inputs : Inputs) (hLink : LinksSource cfg inp inputs)
    (hNoWrap : inputs.first.amount.val + inputs.second.amount.val
      < _root_.Verity.Core.Uint256.modulus) :
    (totalAmount inputs).val = pushedValue cfg inp := by
  rw [total_val inputs hNoWrap, hLink.firstAmount, hLink.secondAmount, ← Nat.add_mul,
    hLink.keys, pushedValue, loopPushed_eq]

/-- On a conserving deployment the same wei is exactly the pull at
`StakingRouter.sol` line 983. -/
theorem linked_total_eq_depositsValue (cfg : SourceDepositConfig) (inp : SourceDepositInput)
    (inputs : Inputs) (hLink : LinksSource cfg inp inputs)
    (hNoWrap : inputs.first.amount.val + inputs.second.amount.val
      < _root_.Verity.Core.Uint256.modulus)
    (hCons : ConservingConfig cfg) :
    (totalAmount inputs).val = depositsValue cfg inp := by
  rw [linked_total_eq_pushedValue cfg inp inputs hLink hNoWrap, pushedValue, loopPushed_eq,
    depositsValue, hCons]

/--
Parent closure for P-DEPOSIT-1.  One theorem, four shared variables: the pinned
source configuration and call input `(cfg, inp)`, the executable transaction
input `inputs`, and the entry `ContractState` -- joined by `LinksSource` and by
the transaction's own executable guards `Preconditions`.

*(a)* is the registered abstract parent
`source_deposit_conserves_and_rolls_back` for `(cfg, inp)`: commit-branch
conservation of the pulled/pushed wei, and rollback (whole-transaction revert)
of every non-conserving deployment on a nonempty batch.

*(b)* is the executable transaction's own boundary: every reverting
`Contract.run` restores the entry snapshot and leaves the observation idle --
no ether moved, no call surviving, every probed mapping word at its entry value.
This holds for arbitrary `inputs` and entry states, including the failure
injections that revert *after* real storage writes and real journalled frames.
This is the load-bearing rollback evidence; the abstract `TxObservation`
rollback fact is definitional in this model and stays demoted to the
unregistered child `revert_restores_state_value_and_logs`.

*(c)* is the correspondence: the executable transaction reproduces the pinned
two-batch source observables -- per-module allocation, dynamic-data and
deposit-data-root words, the guard counter, the Lido ledger, both conservation
aggregates, the router's closing retention, and the call journal down to name,
destination, wei value, argument words and order -- and, whenever the source
model commits its push, its `pulled` and `pushed` are exactly the executable
plane's.

Scope, stated rather than hidden: the executable plane is a Verity-EDSL
transaction (`A-VERITY-SCAFFOLD`), not an EVM execution, and the source plane is
`A-SOURCE-SHAPED`.  `LinksSource` is a hypothesis about the caller's allocation,
not a proof that the pinned Solidity produces those two legs.
-/
theorem verity_tx_composes_deposit_conservation_and_rollback
    (cfg : SourceDepositConfig) (inp : SourceDepositInput)
    (inputs : Inputs) (entry : _root_.Verity.ContractState)
    (hLink : LinksSource cfg inp inputs)
    (hPre : Preconditions inputs entry) :
    ((∀ keys pulled pushed balanceAfter,
        run cfg inp = .committedDeposits keys pulled pushed balanceAfter →
          pulled = pushed ∧ depositsValue cfg inp = pushedValue cfg inp) ∧
        (¬ ConservingConfig cfg → 0 < actualDepositsCount cfg inp →
          (run cfg inp).reverts = true)) ∧
      (∀ reason rollback,
          (execute inputs).run entry = .revert reason rollback →
            rollback = entry ∧
              observe entry (probes inputs) ((execute inputs).run entry)
                = idleObservables entry (probes inputs)) ∧
      (observe entry (probes inputs) ((execute inputs).run entry)
          = sourceObservables inputs entry ∧
        ∀ keys pulled pushed balanceAfter,
          run cfg inp = .committedDeposits keys pulled pushed balanceAfter →
            (sourceObservables inputs entry).pulled = (run cfg inp).pulled ∧
              (sourceObservables inputs entry).pushed = (run cfg inp).pushed) := by
  refine ⟨source_deposit_conserves_and_rolls_back cfg inp,
    fun reason rollback hRevert =>
      ⟨revert_after_intermediate_writes_restores_snapshot inputs entry rollback reason hRevert,
        revert_observes_idle inputs entry rollback reason hRevert⟩,
    execute_observes_source inputs entry hPre, ?_⟩
  intro keys pulled pushed balanceAfter hCommit
  obtain ⟨-, -, hPulled, hPushed, -, -⟩ := committed_deposits_spec hCommit
  have hCons : ConservingConfig cfg := committed_implies_conserving hCommit
  have hTotal : (totalAmount inputs).val = depositsValue cfg inp :=
    linked_total_eq_depositsValue cfg inp inputs hLink hPre.noWrap hCons
  have hTotal' : (totalAmount inputs).val = pushedValue cfg inp :=
    linked_total_eq_pushedValue cfg inp inputs hLink hPre.noWrap
  have hSum : inputs.first.amount.val + inputs.second.amount.val = pushedValue cfg inp := by
    rw [← total_val inputs hPre.noWrap]; exact hTotal'
  have hPulledRun : (run cfg inp).pulled = depositsValue cfg inp := by
    rw [hCommit]; exact hPulled
  have hPushedRun : (run cfg inp).pushed = pushedValue cfg inp := by
    rw [hCommit]; exact hPushed
  exact ⟨hTotal.trans hPulledRun.symm, hSum.trans hPushedRun.symm⟩

/-! ## Non-vacuity

A composed theorem with unsatisfiable hypotheses proves nothing.  The witnesses
below discharge `LinksSource` and `Preconditions` simultaneously on a pinned
five-key deployment that the source model actually *commits*, so conjunct (c)'s
aggregate implication fires rather than being vacuously true. -/

/-- A conserving deployment: `MAX_EFFECTIVE_BALANCE_WC_TYPE_01 = DEPOSIT_SIZE`,
with the pinned pubkey/signature lengths. -/
def canonicalSourceConfig : SourceDepositConfig :=
  { maxEBType1 := 32, depositSize := 32, pubkeyLength := 48,
    publicKeyLength := 48, signatureLength := 96 }

/-- Five keys, split 2 + 3 by the executable transaction's two module legs. -/
def canonicalSourceInput : SourceDepositInput :=
  { moduleActive := true, maxDepositsPerBlock := 8, moduleDepositableEth := 256,
    publicKeysBatchLength := 240, signaturesBatchLength := 480,
    routerBalanceBefore := 0, lidoCanDeposit := true, lidoDepositableEther := 1000 }

theorem canonical_links_source :
    LinksSource canonicalSourceConfig canonicalSourceInput canonicalInputs where
  depositSize := by decide
  keys := by decide
  firstAmount := by decide
  secondAmount := by decide

/-- Both hypothesis bundles hold at once, the source model commits, and the two
planes agree on the wei pulled and the wei pushed. -/
theorem canonical_composition_witness :
    LinksSource canonicalSourceConfig canonicalSourceInput canonicalInputs ∧
      Preconditions canonicalInputs canonicalState ∧
      run canonicalSourceConfig canonicalSourceInput = .committedDeposits 5 160 160 0 ∧
      observe canonicalState (probes canonicalInputs)
          ((execute canonicalInputs).run canonicalState)
        = sourceObservables canonicalInputs canonicalState ∧
      (sourceObservables canonicalInputs canonicalState).pulled
          = (run canonicalSourceConfig canonicalSourceInput).pulled ∧
        (sourceObservables canonicalInputs canonicalState).pushed
          = (run canonicalSourceConfig canonicalSourceInput).pushed := by
  have hRun : run canonicalSourceConfig canonicalSourceInput
      = .committedDeposits 5 160 160 0 := by decide
  obtain ⟨-, -, hObs, hAgg⟩ :=
    verity_tx_composes_deposit_conservation_and_rollback
      canonicalSourceConfig canonicalSourceInput
      canonicalInputs canonicalState canonical_links_source canonical_preconditions
  exact ⟨canonical_links_source, canonical_preconditions, hRun, hObs,
    (hAgg 5 160 160 0 hRun).1, (hAgg 5 160 160 0 hRun).2⟩

end LidoSRv3.Audit.Guarantees.PDeposit1
