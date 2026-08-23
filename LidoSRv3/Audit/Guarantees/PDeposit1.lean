import LidoSRv3.Audit.Trace
import LidoSRv3.Audit.Source.DepositCorrespondence
import LidoSRv3.Audit.Verity.DepositParentTx
import LidoSRv3.Audit.Verity.DepositNFrameTx
import LidoSRv3.Audit.Guarantees.Registry

namespace LidoSRv3.Audit.Guarantees.PDeposit1

open LidoSRv3.Audit
open LidoSRv3.Audit.SolidityDeposit

/-- The registry exposes the abstract/source proof and the composed bounded
executable Verity transaction evidence. -/
def guarantee : Guarantee := ⟨.pDeposit1, [.model, .abstractTx, .source, .verityTx]⟩

/-! Deployment provenance is deliberately not manufactured by the source
model. `A-DEPOSIT-CONTRACT` pins the immutable `DEPOSIT_CONTRACT` to the
production beacon deposit contract, while `A-DEPOSIT-32-ETHER` pins both the
BeaconChainDepositor literal and the router constructor's
`MAX_EFFECTIVE_BALANCE_WC_TYPE_01` to 32 ether. They remain OPEN assumptions;
`LinksSource` below remains an independent caller hypothesis. -/

def canonicalDepositContractAddress : Nat :=
  0x00000000219ab540356cBB839Cbe05303d7705Fa

def thirtyTwoEtherWei : Nat := 32 * 10 ^ 18

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
smuggle the conclusion in.  In particular, it is an explicit hypothesis for
this *exactly-two-batch* executable model, not a consequence of either ALLOC
parent and not a derived bound for the Solidity allocation loop.  The private
counterexample after `canonical_composition_witness` keeps the executable
allocation premises true while falsifying `keys`.
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
The composed parent's own hypotheses bound the wei the executable beacon legs
**push**, and only that.  `LinksSource` forces the two legs to carry
`actualDepositsCount cfg inp` keys at `cfg.depositSize` wei each, and
`Preconditions.noWrap` forces their sum into one 256-bit word, so
`pushedValue cfg inp` -- the wei the loop at `BeaconChainDepositor.sol` lines
53--63 sends, `actualDepositsCount cfg inp * DEPOSIT_SIZE` -- is below `2 ^ 256`.

This is deliberately *not* a bound on the source pull, and the two are not the
same quantity.  The pull at `StakingRouter.sol` line 983 is the line-972
`depositsValue cfg inp = actualDepositsCount cfg inp * MAX_EFFECTIVE_BALANCE_WC_TYPE_01`,
and neither `LinksSource` nor `Preconditions` relates `cfg.maxEBType1` to
`cfg.depositSize`.  So a deployment admitted by these hypotheses may compute a
pull quantity far above one word while this theorem still holds:
`linked_hypotheses_do_not_bound_the_line_972_product` exhibits one (with a
`uint256`-encodable immutable, so what exceeds the word is only the line-972
*product* read as an unbounded-`Nat` formula: the deployment itself never
evaluates that multiplication, because its zero `maxDepositsCount` turns the
pinned path away at the earlier line-959 guard, checked by
`skewed_pull_witness_turned_away_before_line_972`), and
`linked_conserving_deployment_pull_is_word_bounded` is the extra hypothesis under
which the pull is bounded too.  Nothing here may be quoted as "every admitted
deployment's whole pull fits one word".

This is the arithmetic half of the executable plane's finiteness, and it is
stated rather than left implicit: the registered abstract parent is an unbounded
`∀ (cfg, inp)` with no word bound at all, so every input above this bound is
covered by the abstract plane and by no executable transaction.
`abstract_parent_covers_inputs_the_verity_plane_omits` exhibits one; that
exhibit is an input of the unbounded `Nat` abstraction, deliberately outside the
`uint256` source domain, since under the no-overflow correspondence reading no
realizable deployment settles a pull above one word in the first place.
-/
theorem linked_deployment_push_is_word_bounded
    (cfg : SourceDepositConfig) (inp : SourceDepositInput)
    (inputs : Inputs) (hLink : LinksSource cfg inp inputs)
    (hNoWrap : inputs.first.amount.val + inputs.second.amount.val
      < _root_.Verity.Core.Uint256.modulus) :
    pushedValue cfg inp < _root_.Verity.Core.Uint256.modulus ∧
      actualDepositsCount cfg inp * cfg.depositSize
        < _root_.Verity.Core.Uint256.modulus := by
  have hSum : inputs.first.amount.val + inputs.second.amount.val
      = actualDepositsCount cfg inp * cfg.depositSize := by
    rw [hLink.firstAmount, hLink.secondAmount, ← Nat.add_mul, hLink.keys]
  have hBound : actualDepositsCount cfg inp * cfg.depositSize
      < _root_.Verity.Core.Uint256.modulus := by omega
  refine ⟨?_, hBound⟩
  rw [pushedValue, loopPushed_eq]
  exact hBound

/--
The source pull is word-bounded too, but only under a hypothesis the composed
parent does not carry: a conserving deployment.  When
`MAX_EFFECTIVE_BALANCE_WC_TYPE_01 = DEPOSIT_SIZE` the line-972 `depositsValue`
is the executable push, so `linked_deployment_push_is_word_bounded` transfers to
it.  Off `ConservingConfig` it does not transfer, and does not hold:
`linked_hypotheses_do_not_bound_the_line_972_product`.
-/
theorem linked_conserving_deployment_pull_is_word_bounded
    (cfg : SourceDepositConfig) (inp : SourceDepositInput)
    (inputs : Inputs) (hLink : LinksSource cfg inp inputs)
    (hNoWrap : inputs.first.amount.val + inputs.second.amount.val
      < _root_.Verity.Core.Uint256.modulus)
    (hCons : ConservingConfig cfg) :
    depositsValue cfg inp < _root_.Verity.Core.Uint256.modulus := by
  rw [depositsValue, hCons]
  exact (linked_deployment_push_is_word_bounded cfg inp inputs hLink hNoWrap).2

/-- Hypothesis-free executable rollback theorem. Unlike the composed parent,
this statement takes neither `LinksSource` nor success `Preconditions`: every
actual `execute` revert restores the exact entry snapshot and observes the idle
boundary. -/
theorem verity_tx_revert_restores_snapshot
    (inputs : Inputs) (entry rollback : _root_.Verity.ContractState)
    (reason : String)
    (hRevert : (execute inputs).run entry = .revert reason rollback) :
    rollback = entry ∧
      observe entry (probes inputs) ((execute inputs).run entry) =
        idleObservables entry (probes inputs) :=
  ⟨revert_after_intermediate_writes_restores_snapshot
      inputs entry rollback reason hRevert,
    revert_observes_idle inputs entry rollback reason hRevert⟩

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

*(d)* is the finite scope of *(b)* and *(c)*, in the registered statement rather
than only in this docstring, so the row cannot be quoted as an unbounded loop
claim.  The executable journal is the same five frames for every `inputs` --
two `obtainDepositData` module legs, one `withdrawDepositableEther` pull and
exactly two `depositToBeacon` legs -- and exactly two module ids are probed,
however many keys the source batch holds; the pinned loop at
`BeaconChainDepositor.sol` lines 53--63 instead performs one frame per key.
The third component is the arithmetic bound of
`linked_deployment_push_is_word_bounded`: the hypotheses admit only deployments
whose executable **push** -- `pushedValue cfg inp`, the wei the two beacon legs
send -- fits one 256-bit word.  The fourth is the matching bound on the source
**pull** `depositsValue cfg inp`, and it is stated with the hypothesis it
actually needs, `ConservingConfig cfg`: off that hypothesis the pull scale
`MAX_EFFECTIVE_BALANCE_WC_TYPE_01` is unrelated to `DEPOSIT_SIZE` and the pull is
genuinely unbounded here (`linked_hypotheses_do_not_bound_the_line_972_product`).  So
this conjunct must not be read as bounding the whole pull of every admitted
deployment.

Scope, stated rather than hidden: the executable plane is a Verity-EDSL
transaction (`A-VERITY-SCAFFOLD`), not an EVM execution, and the source plane is
`A-SOURCE-SHAPED`.  `LinksSource` is a hypothesis about the caller's allocation,
not a proof that the pinned Solidity produces those two legs.  The transaction
executes exactly two batches; it does not encode a universally quantified loop,
and no ALLOC composition into `LinksSource` is claimed (see the private
counterexample below).  Conjunct *(a)* is therefore the only unbounded half of
this theorem: it holds for every `(cfg, inp)`, while *(b)*, *(c)* and *(d)* speak
only about the fixed two-leg executable shape, and
`abstract_parent_covers_inputs_the_verity_plane_omits` exhibits an
abstract-model input *(a)* covers -- one deliberately outside the `uint256`
source domain (`oversized_input_is_outside_the_source_domain`) -- that no
executable transaction can represent.
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
              (sourceObservables inputs entry).pushed = (run cfg inp).pushed) ∧
      ((sourceObservables inputs entry).callNames
          = ["obtainDepositData", "obtainDepositData", "withdrawDepositableEther",
             "depositToBeacon", "depositToBeacon"] ∧
        (probes inputs).length = 2 ∧
        pushedValue cfg inp < _root_.Verity.Core.Uint256.modulus ∧
        (ConservingConfig cfg →
          depositsValue cfg inp < _root_.Verity.Core.Uint256.modulus)) := by
  refine ⟨source_deposit_conserves_and_rolls_back cfg inp,
    fun reason rollback hRevert =>
      ⟨revert_after_intermediate_writes_restores_snapshot inputs entry rollback reason hRevert,
        revert_observes_idle inputs entry rollback reason hRevert⟩,
    ⟨execute_observes_source inputs entry hPre, ?_⟩,
    rfl, rfl, (linked_deployment_push_is_word_bounded cfg inp inputs hLink hPre.noWrap).1,
    fun hCons =>
      linked_conserving_deployment_pull_is_word_bounded cfg inp inputs hLink hPre.noWrap hCons⟩
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
  obtain ⟨-, -, ⟨hObs, hAgg⟩, -⟩ :=
    verity_tx_composes_deposit_conservation_and_rollback
      canonicalSourceConfig canonicalSourceInput
      canonicalInputs canonicalState canonical_links_source canonical_preconditions
  exact ⟨canonical_links_source, canonical_preconditions, hRun, hObs,
    (hAgg 5 160 160 0 hRun).1, (hAgg 5 160 160 0 hRun).2⟩

/-! ## The line-972 product the composed hypotheses do not bound

`linked_deployment_push_is_word_bounded` bounds the wei the two executable beacon
legs push.  It says nothing about the wei the source formula computes, and the
gap between them is not academic: the witness below keeps `LinksSource` and the
composed parent's own `Preconditions` true while the line-972 `depositsValue`
product runs past the 256-bit word -- and it does so with every field of the
configuration still inside the `uint256` source domain.  The product is a
standalone unbounded-`Nat` formula here, never a settled source pull: no
admitted execution of this witness reaches the line-972 multiplication at all. -/

/-- A skewed deployment: the router's `MAX_EFFECTIVE_BALANCE_WC_TYPE_01`
(`StakingRouter.sol` line 65) is the largest value one `uint256` word can
encode, `2 ^ 256 - 1`, while the depositor's `DEPOSIT_SIZE`
(`BeaconChainDepositor.sol` line 24) is the pinned 32.  `LinksSource`
constrains only `DEPOSIT_SIZE`, so the bridge accepts this unchanged, and the
immutable itself is encodable -- the first conjunct of the witness below checks
it.  What leaves the word is the line-972 *product*
`actualDepositsCount * maxEBType1`, not any stored quantity. -/
def skewedPullConfig : SourceDepositConfig :=
  { canonicalSourceConfig with maxEBType1 := 2 ^ 256 - 1 }

/--
The composed parent's hypotheses do not bound the line-972 product.

At `skewedPullConfig` the canonical five-key deployment still satisfies
`LinksSource`, and `canonicalInputs`/`canonicalState` still satisfy
`Preconditions`, so this `(cfg, inp, inputs, entry)` is admitted by
`verity_tx_composes_deposit_conservation_and_rollback` exactly as the conserving
one is.  The executable push is the same 160 wei as ever, comfortably inside one
word, precisely as `linked_deployment_push_is_word_bounded` states.  The
immutable `maxEBType1 = 2 ^ 256 - 1` is itself `uint256`-encodable -- the first
conjunct checks it -- and yet the line-972 product
`depositsValue = 5 * (2 ^ 256 - 1) = 5 * 2 ^ 256 - 5` is at or above
`Uint256.modulus`.

Stated honestly and not further: this deployment never even reaches the
line-972 multiplication, let alone settles a pull.  Its module allocation is
the canonical 256 wei, so the computed cap is
`maxDepositsCount = min 8 (256 / (2 ^ 256 - 1)) = 0`, and the pinned path turns
away at the earlier line-959 `ZeroDeposits` guard, on chain and inside the
model alike: `skewed_pull_witness_turned_away_before_line_972` below checks that
`run` returns `revertZeroDeposits`, so no wei moves and no later guard -- line
972, line 983, line 996 -- is ever evaluated.  That guard structure is not
accidental: whenever the over-target guard at line 969 passes, the product is
bounded by the module allocation itself (`line_972_product_le_module_allocation`),
so a `uint256`-encodable allocation keeps the line-972 product inside one word
(`encodable_allocation_bounds_line_972_product`).  A Solidity 0.8
checked-arithmetic panic at line 972 is therefore unreachable from the
encodable domain, and the word-exceeding quantity this witness exhibits exists
only as the unbounded-`Nat` formula that `LinksSource` together with
`Preconditions` fails to bound.  The claim here is about the *hypotheses* and the
abstraction's arithmetic, not about a settled transfer or a reached
multiplication: `LinksSource` together with `Preconditions` admits
configurations whose line-972 product exceeds a word, so neither
`linked_deployment_push_is_word_bounded` nor conjunct (d) of the registered
parent may be paraphrased as "every admitted deployment's whole pull fits one
256-bit word".  `linked_conserving_deployment_pull_is_word_bounded`
is the statement that does bound the pull, and it carries exactly the
`ConservingConfig` hypothesis this witness violates.
-/
theorem linked_hypotheses_do_not_bound_the_line_972_product :
    skewedPullConfig.maxEBType1 < _root_.Verity.Core.Uint256.modulus ∧
      LinksSource skewedPullConfig canonicalSourceInput canonicalInputs ∧
      Preconditions canonicalInputs canonicalState ∧
      pushedValue skewedPullConfig canonicalSourceInput
        < _root_.Verity.Core.Uint256.modulus ∧
      _root_.Verity.Core.Uint256.modulus
        ≤ depositsValue skewedPullConfig canonicalSourceInput ∧
      ¬ ConservingConfig skewedPullConfig := by
  refine ⟨?_, ⟨by decide, by decide, by decide, by decide⟩,
    canonical_preconditions, ?_, ?_, by decide⟩
  · show 2 ^ 256 - 1 < _root_.Verity.Core.Uint256.modulus
    decide
  · show loopPushed skewedPullConfig (240 / 48) < _root_.Verity.Core.Uint256.modulus
    decide
  · show _root_.Verity.Core.Uint256.modulus ≤ 240 / 48 * (2 ^ 256 - 1)
    decide

/-! ## The guards the skewed witness never passes

The kill-line above is a statement about an unbounded-`Nat` formula, and an
earlier revision of its prose over-claimed the on-chain reading: it asserted
that an admitted source execution "panics at the line-972 multiplication".
That is false, and it is now pinned shut twice.  The first theorem below is
the executable regression: the skewed witness's computed cap is zero, so `run`
turns away at the line-959 guard and never reaches line 972 at all.  The two
after it are the general reason no sound witness of this shape can ever reach
an overflowing line-972 product: the over-target guard at line 969 bounds the
product by the module allocation, so an encodable allocation keeps it inside
one word.  The fourth is the commit-level dual that closes the alternative
repair route the review raised: an in-range input cannot commit a
word-exceeding push at all.  -/

/-- The executable regression for the corrected claim: the skewed witness never
reaches the line-972 multiplication.  `canonicalSourceInput`'s module
allocation is 256 wei, so with `skewedPullConfig.maxEBType1 = 2 ^ 256 - 1` the
computed cap is `maxDepositsCount = min 8 (256 / (2 ^ 256 - 1)) = 0`, and the
pinned path's first-guard-wins `run` returns `revertZeroDeposits` at the
line-959 guard (`StakingRouter.sol`), exactly as on chain.  The earlier
revision's on-chain story -- an admitted source execution panicking at the
line-972 checked multiplication -- is refuted by guard order on the exact
witness the kill-line quotes, by kernel evaluation. -/
theorem skewed_pull_witness_turned_away_before_line_972 :
    maxDepositsCount skewedPullConfig canonicalSourceInput = 0 ∧
      run skewedPullConfig canonicalSourceInput = .revertZeroDeposits := by
  refine ⟨?_, ?_⟩
  · show min 8 (256 / (2 ^ 256 - 1)) = 0
    decide
  · decide

/-- Why the over-claimed line-972 panic cannot be reinstated with a different
witness: whenever the pinned path passes its over-target guard at line 969
(`actualDepositsCount ≤ maxDepositsCount`, `StakingRouter.sol`), the line-972
product `actualDepositsCount * MAX_EFFECTIVE_BALANCE_WC_TYPE_01` is at most the
module allocation, because `maxDepositsCount` is capped by
`moduleDepositableEth / maxEBType1` and the truncated division satisfies
`(a / b) * b ≤ a`. -/
theorem line_972_product_le_module_allocation
    (cfg : SourceDepositConfig) (inp : SourceDepositInput)
    (hCap : actualDepositsCount cfg inp ≤ maxDepositsCount cfg inp) :
    depositsValue cfg inp ≤ inp.moduleDepositableEth := by
  have hDiv : actualDepositsCount cfg inp
      ≤ inp.moduleDepositableEth / cfg.maxEBType1 :=
    hCap.trans (Nat.min_le_right _ _)
  have hMul : actualDepositsCount cfg inp * cfg.maxEBType1
      ≤ (inp.moduleDepositableEth / cfg.maxEBType1) * cfg.maxEBType1 :=
    Nat.mul_le_mul hDiv (Nat.le_refl _)
  exact hMul.trans (Nat.div_mul_le_self _ _)

/-- The `uint256` reading of the same bound: a module allocation one word can
encode keeps the line-972 product inside that word, so Solidity 0.8 checked
arithmetic cannot panic at line 972 for an encodable input.  A word-exceeding
line-972 quantity needs a non-encodable allocation, which is the oversized
witness's territory (`oversized_input_is_outside_the_source_domain`), not a
deployment. -/
theorem encodable_allocation_bounds_line_972_product
    (cfg : SourceDepositConfig) (inp : SourceDepositInput)
    (hCap : actualDepositsCount cfg inp ≤ maxDepositsCount cfg inp)
    (hAlloc : inp.moduleDepositableEth < _root_.Verity.Core.Uint256.modulus) :
    depositsValue cfg inp < _root_.Verity.Core.Uint256.modulus :=
  Nat.lt_of_le_of_lt (line_972_product_le_module_allocation cfg inp hCap) hAlloc

/-- The commit-level dual, and the regression that closes the in-range repair
route: no input whose module allocation is `uint256`-encodable can *commit* a
push that leaves the 256-bit word.  A committing `run` passed the line-969
over-target guard, so the line-972 product is bounded by the allocation
(`line_972_product_le_module_allocation`), and it passed the line-996 assert, so
the deployment is conserving (`committed_implies_conserving`) and the loop's
committed push `pushedValue` equals that bounded product.  So the
word-exceeding commit `oversized_run_commits` exhibits cannot be moved inside
the `uint256` domain by any witness choice: the abstract/Verity quantifier gap
at a word-exceeding commit *requires* an input outside the source domain,
exactly what `oversized_input_is_outside_the_source_domain` checks for the
pinned exhibit.  The witness there is a quantifier gap of the unbounded `Nat`
model because it has no alternative: the in-range, no-overflow witness does not
exist. -/
theorem in_range_commit_is_word_bounded
    (cfg : SourceDepositConfig) (inp : SourceDepositInput)
    {keys pulled pushed balanceAfter : Nat}
    (hRun : run cfg inp = .committedDeposits keys pulled pushed balanceAfter)
    (hAlloc : inp.moduleDepositableEth < _root_.Verity.Core.Uint256.modulus) :
    depositsValue cfg inp < _root_.Verity.Core.Uint256.modulus ∧
      pushedValue cfg inp < _root_.Verity.Core.Uint256.modulus := by
  have hCap : actualDepositsCount cfg inp ≤ maxDepositsCount cfg inp := by
    by_contra hNotLe
    have hLt : maxDepositsCount cfg inp < actualDepositsCount cfg inp := by omega
    rw [run] at hRun
    by_cases hModule : inp.moduleActive = false
    · rw [if_pos hModule] at hRun; cases hRun
    rw [if_neg hModule] at hRun
    by_cases hMaxEB : cfg.maxEBType1 = 0
    · rw [if_pos hMaxEB] at hRun; cases hRun
    rw [if_neg hMaxEB] at hRun
    by_cases hMax : maxDepositsCount cfg inp = 0
    · rw [if_pos hMax] at hRun; cases hRun
    rw [if_neg hMax] at hRun
    by_cases hPubkeyZero : cfg.pubkeyLength = 0
    · rw [if_pos hPubkeyZero] at hRun; cases hRun
    rw [if_neg hPubkeyZero] at hRun
    by_cases hAligned : inp.publicKeysBatchLength % cfg.pubkeyLength ≠ 0
    · rw [if_pos hAligned] at hRun; cases hRun
    rw [if_neg hAligned] at hRun
    rw [if_pos hLt] at hRun
    cases hRun
  have hCons : ConservingConfig cfg := committed_implies_conserving hRun
  have hDep : depositsValue cfg inp ≤ inp.moduleDepositableEth :=
    line_972_product_le_module_allocation cfg inp hCap
  have hPush : pushedValue cfg inp = depositsValue cfg inp := by
    rw [pushedValue, loopPushed_eq, ← hCons, depositsValue]
  exact ⟨Nat.lt_of_le_of_lt hDep hAlloc, hPush ▸ Nat.lt_of_le_of_lt hDep hAlloc⟩

/-! ## The quantifier gap between the two planes

Non-vacuity above says the composed hypotheses are satisfiable somewhere.  It
says nothing about *where they are not*, and the registered abstract parent is an
unbounded `∀ (cfg, inp)`.  The witness below closes that reading in the opposite
direction: it names an input the abstract parent covers and for which no
executable transaction exists at all, so `verity: CHECKED` on this row must not
be read as an executable claim about every input the abstract row states. -/

/-- The pinned conserving deployment scaled to `2 ^ 256` keys, with every cap the
pinned path checks scaled with it so the model's `run` is not turned away by a
guard: `2 ^ 256` public keys of `PUBKEY_LENGTH = 48` bytes, the matching
`SIGNATURE_LENGTH = 96` signature bytes per key, a per-block cap
(`maxDepositsPerBlock`) and module allocation (`moduleDepositableEth`) that admit
all `2 ^ 256` keys, and Lido depositable ether covering the whole
`2 ^ 256 * DEPOSIT_SIZE` pull.

Scaling the caps is the point.  With the pinned `maxDepositsPerBlock = 8` and
`moduleDepositableEth = 256` this input would stop at `ModuleReturnExceedTarget`
(`StakingRouter.sol` line 969) before pulling any ether or executing a single
per-key frame, and every statement about it would be vacuous.
`oversized_run_commits` checks that it does not stop there.

Domain honesty: several of these quantities -- the per-block cap, the module
allocation, both batch lengths, and the Lido depositable ether -- sit at or above
`2 ^ 256`, so `oversizedSourceInput` is *not* a `uint256`-encodable call and is
not offered as one; `oversized_input_is_outside_the_source_domain` records that
in a checked statement.  `DepositCorrespondence` reads its unbounded `Nat`
arithmetic as the pinned Solidity only under the no-overflow reading, and this
input is outside that domain by construction.  What the witness below exhibits
is therefore a quantifier gap of the abstract `Nat` model itself -- the
registered parent quantifies over every `(cfg, inp)` with no word bound and no
encodability premise -- and not a pinned-source deployment executing the path. -/
def oversizedSourceInput : SourceDepositInput :=
  { moduleActive := true, maxDepositsPerBlock := 2 ^ 256,
    moduleDepositableEth := 32 * 2 ^ 256,
    publicKeysBatchLength := 48 * 2 ^ 256, signaturesBatchLength := 96 * 2 ^ 256,
    routerBalanceBefore := 0, lidoCanDeposit := true,
    lidoDepositableEther := 32 * 2 ^ 256 }

/-- The regression that pins the domain honesty: the oversized witness is
deliberately an input of the unbounded `Nat` abstraction only.  Its per-block
cap, module allocation, both batch lengths, and the Lido depositable ether all
sit at or above `Uint256.modulus`, so no `uint256` deployment can encode this
call and the witness must never be quoted as one.  Statements about
`oversizedSourceInput` -- `oversized_run_commits`,
`abstract_parent_covers_inputs_the_verity_plane_omits` -- are statements
about the abstract model's quantifier reach, not about the pinned Solidity
source executing an oversized batch. -/
theorem oversized_input_is_outside_the_source_domain :
    _root_.Verity.Core.Uint256.modulus ≤ oversizedSourceInput.maxDepositsPerBlock ∧
      _root_.Verity.Core.Uint256.modulus ≤ oversizedSourceInput.moduleDepositableEth ∧
      _root_.Verity.Core.Uint256.modulus ≤ oversizedSourceInput.publicKeysBatchLength ∧
      _root_.Verity.Core.Uint256.modulus ≤ oversizedSourceInput.signaturesBatchLength ∧
      _root_.Verity.Core.Uint256.modulus ≤ oversizedSourceInput.lidoDepositableEther := by
  decide

/-- That input's committed push in the unbounded model -- the loop's own
accumulation `actualDepositsCount * DEPOSIT_SIZE` -- is `2 ^ 261` wei: above
the 256-bit word the executable ledger is built on.  No pull is settled
anywhere: the input is outside the `uint256` source domain, and inside that
domain `in_range_commit_is_word_bounded` keeps every committed push below one
word. -/
theorem oversized_input_exceeds_word :
    actualDepositsCount canonicalSourceConfig oversizedSourceInput = 2 ^ 256 ∧
      _root_.Verity.Core.Uint256.modulus
        ≤ actualDepositsCount canonicalSourceConfig oversizedSourceInput
            * canonicalSourceConfig.depositSize := by
  have hCount : actualDepositsCount canonicalSourceConfig oversizedSourceInput = 2 ^ 256 := by
    show 48 * 2 ^ 256 / 48 = 2 ^ 256
    exact Nat.mul_div_cancel_left _ (by omega)
  refine ⟨hCount, ?_⟩
  rw [hCount]
  show 2 ^ 256 ≤ 2 ^ 256 * 32
  exact Nat.le_mul_of_pos_right _ (by omega)

/--
The oversized input is not turned away by a guard: the unbounded model's `run`
reaches its committed push at `StakingRouter.sol` lines 980--996, moving
`2 ^ 256 * DEPOSIT_SIZE` wei through `2 ^ 256` per-key deposit frames and
retaining nothing.

This is what makes the witness below substantive rather than vacuous.  Every
`run` guard is passed rather than dodged: the module is active, the per-block cap
and module allocation both admit `2 ^ 256` keys so line 969's
`ModuleReturnExceedTarget` does not fire, the pubkey and signature batch lengths
are the exact multiples `BeaconChainDepositor.sol` lines 43--48 demand, Lido
holds the whole pull, and the line-996 `assert` passes because the deployment is
conserving.  So `run` returns `committedDeposits`, and the abstract parent's
conservation implication has an actual outcome to fire on.

Scope, stated rather than hidden: this is a theorem about the unbounded `Nat`
model's `run`, not about the pinned Solidity source.  The input is outside the
`uint256` source domain (`oversized_input_is_outside_the_source_domain`), so no
realizable deployment can even encode the call; and inside the domain there is
no fallback route to this commit either, because a `uint256`-encodable module
allocation keeps the line-972 product inside one word
(`encodable_allocation_bounds_line_972_product`) and an in-range input cannot
commit a word-exceeding push at all
(`in_range_commit_is_word_bounded`), so Solidity 0.8 checked
arithmetic never panics at line 972 from an encodable input.  No realizable
deployment executes what the model commits here.
-/
theorem oversized_run_commits :
    run canonicalSourceConfig oversizedSourceInput
      = .committedDeposits (2 ^ 256) (2 ^ 256 * 32) (2 ^ 256 * 32) 0 := by
  have hCount : actualDepositsCount canonicalSourceConfig oversizedSourceInput = 2 ^ 256 := by
    show 48 * 2 ^ 256 / 48 = 2 ^ 256
    exact Nat.mul_div_cancel_left _ (by omega)
  have hMax : maxDepositsCount canonicalSourceConfig oversizedSourceInput = 2 ^ 256 := by
    show min (2 ^ 256) (32 * 2 ^ 256 / 32) = 2 ^ 256
    rw [Nat.mul_div_cancel_left _ (by omega : 0 < 32), Nat.min_self]
  have hPull : depositsValue canonicalSourceConfig oversizedSourceInput = 2 ^ 256 * 32 := by
    rw [depositsValue, hCount]
    rfl
  have hPush : pushedValue canonicalSourceConfig oversizedSourceInput = 2 ^ 256 * 32 := by
    rw [pushedValue, loopPushed_eq, hCount]
    rfl
  have hAfter : routerBalanceAfter canonicalSourceConfig oversizedSourceInput = 0 := by
    rw [routerBalanceAfter, hPull, hPush]
    show 0 + 2 ^ 256 * 32 - 2 ^ 256 * 32 = 0
    rw [Nat.zero_add, Nat.sub_self]
  unfold run
  rw [hMax, hCount, hPull, hPush, hAfter]
  decide +kernel

/--
The registered abstract parent is total; the registered Verity parent is not.

The witness is an input of the unbounded `Nat` abstraction whose `run` the model
commits rather than turns away -- Conjunct 1 is `oversized_run_commits`: at
`oversizedSourceInput` the model's path commits a push of `2 ^ 256` per-key
deposit frames carrying `2 ^ 256 * DEPOSIT_SIZE` wei.  Conjunct 2 is the
registered abstract parent's conservation conclusion *fired* on that model-level
outcome: its antecedent is discharged by conjunct 1, so the line-972 pull formula
and the loop's own accumulation are proved equal at that committed push rather
than agreed on vacuously.  Conjunct 3 records that the wei so moved is at or
above `Uint256.modulus`.

Conjunct 4 is the gap: no executable transaction reaches that input at all.
Every `inputs` satisfying `LinksSource` violates the composed parent's own
`Preconditions.noWrap` premise, so the hypotheses of
`verity_tx_composes_deposit_conservation_and_rollback` are jointly unsatisfiable
at this `(cfg, inp)` for *every* `inputs` and *every* entry state.

The gap is therefore not an artifact of the chosen witnesses, and not a vacuous
reading of the abstract parent either: the abstract parent is *proved* for
inputs no executable transaction can represent.  Stated strictly, it is a
quantifier gap of the unbounded `Nat` model, not a pinned-source deployment
claim: `oversizedSourceInput` is outside the `uint256` source domain
(`oversized_input_is_outside_the_source_domain`), so no realizable Solidity
deployment encodes the call, let alone settles a `2 ^ 256 * DEPOSIT_SIZE` wei
push, and inside the domain no witness of this word-exceeding shape exists at
all: `in_range_commit_is_word_bounded` keeps every committed push of an
input with a `uint256`-encodable module allocation below one word.

Two separate gaps, deliberately not conflated here.  This witness exhibits the
*quantified-domain* gap -- the abstract parent quantifies over unbounded `Nat`
inputs whose committed aggregates leave the word, and no executable ledger
transaction can follow it there, whatever its frame count, because the
executable `Preconditions.noWrap` bounds the aggregate itself.  The missing
*n-frame* executable model is a different gap with a different witness: at an
in-range input like `manyKeySourceInput` below (nine keys, every field
`uint256`-encodable, the model committing a nine-frame push of 288 wei)
`LinksSource` still assigns the nine keys to the existing two aggregate legs
when the total fits, so the word bound excludes nothing there -- what the
executable plane omits is the per-key frame count, one `depositToBeacon` frame
per key versus the two legs' fixed pair, and that omission is witnessed in
range, not by this oversized exhibit.  Closing the word-domain gap needs a
restriction of the abstract parent to the executable word domain or an
unbounded executable model; closing the frame gap needs an `n`-frame
`execute`; neither substitutes for the other, and neither is a metadata
change.

What this witness does not claim: the deployment is conserving, so the abstract
parent's *rollback* implication is not exercised here and is deliberately left
out of the statement rather than carried as a conjunct that would hold only
because its antecedent is false.
-/
theorem abstract_parent_covers_inputs_the_verity_plane_omits :
    run canonicalSourceConfig oversizedSourceInput
        = .committedDeposits (2 ^ 256) (2 ^ 256 * 32) (2 ^ 256 * 32) 0 ∧
      depositsValue canonicalSourceConfig oversizedSourceInput
          = pushedValue canonicalSourceConfig oversizedSourceInput ∧
      _root_.Verity.Core.Uint256.modulus ≤ 2 ^ 256 * 32 ∧
      (∀ inputs : Inputs,
        LinksSource canonicalSourceConfig oversizedSourceInput inputs →
          ¬ inputs.first.amount.val + inputs.second.amount.val
            < _root_.Verity.Core.Uint256.modulus) := by
  refine ⟨oversized_run_commits,
    ((source_deposit_conserves_and_rolls_back canonicalSourceConfig oversizedSourceInput).1
      _ _ _ _ oversized_run_commits).2,
    ?_, fun inputs hLink hNoWrap => ?_⟩
  · have hCount := oversized_input_exceeds_word.1
    have hBound := oversized_input_exceeds_word.2
    rw [hCount] at hBound
    exact hBound
  · exact absurd
      ((linked_deployment_push_is_word_bounded canonicalSourceConfig oversizedSourceInput
        inputs hLink hNoWrap).2)
      (Nat.not_lt.2 oversized_input_exceeds_word.2)

/-! ## The n-frame gap's in-range witness

The oversized exhibit above is the *quantified-domain* gap's witness, and it is
outside the `uint256` domain by necessity (`in_range_commit_is_word_bounded`:
no in-range input commits a word-exceeding push).  The missing n-frame
executable model is a separate gap, and it deserves a witness of its own, one
inside the source domain: an in-range input whose committed push fits one word
and still executes more per-key frames than the two-leg executable plane has.
The witness below is the pinned conserving deployment scaled to nine keys --
every field `uint256`-encodable, checked -- so the frame-count omission is
exhibited where it actually lives, without borrowing the word-bound exhibit's
out-of-domain scaling.  Nothing here claims the two-leg transaction represents
nine frames: the witness below shows the executable hypothesis bundle remains
satisfiable *in full* at this input -- not just `LinksSource` and the no-wrap
inequality, but the complete `Preconditions` structure (guard health, distinct
modules, `valueMatches`, funding, entry balance and `noWrap`) at the concrete
entry state `canonicalState` the row already pins, so the two-leg composed
parent `verity_tx_composes_deposit_conservation_and_rollback` kernel-checks the
advertised admission exactly as its hypotheses demand -- while the keys still
split 4 + 5 across the two aggregate legs when the total fits, which is
precisely why the n-frame gap is not a word-bound gap: the executable plane
admits the input and still journals only two `depositToBeacon` frames for its
nine per-key source frames.  The two regressions after the witness pin the
entry state down from the other side: an entry ledger one wei short refutes
the whole `Preconditions` bundle at the funding guard, and the executable
transaction then reverts with exactly `NOT_ENOUGH_ETHER` and rolls back to the
entry snapshot, so the admission is load-bearing, not inherited by accident.
Motivating and specifying the n-frame `execute` that closes it is the
registered `classification.work` item, not this witness. -/

/-- Nine public keys, every field `uint256`-encodable: 9 * 48 = 432 pubkey
bytes, 9 * 96 = 864 signature bytes, a per-block cap and module allocation
admitting all nine keys at the pinned scale of 32 wei per key, and Lido
depositable ether covering the whole 288-wei push. -/
def manyKeySourceInput : SourceDepositInput :=
  { moduleActive := true, maxDepositsPerBlock := 16, moduleDepositableEth := 288,
    publicKeysBatchLength := 432, signaturesBatchLength := 864,
    routerBalanceBefore := 0, lidoCanDeposit := true,
    lidoDepositableEther := 1000 }

/-- The n-frame witness is inside the `uint256` source domain, unlike the
oversized exhibit: every field is one word, checked conjunct by conjunct. -/
theorem manyKey_input_is_within_the_source_domain :
    manyKeySourceInput.maxDepositsPerBlock < _root_.Verity.Core.Uint256.modulus ∧
      manyKeySourceInput.moduleDepositableEth < _root_.Verity.Core.Uint256.modulus ∧
      manyKeySourceInput.publicKeysBatchLength < _root_.Verity.Core.Uint256.modulus ∧
      manyKeySourceInput.signaturesBatchLength < _root_.Verity.Core.Uint256.modulus ∧
      manyKeySourceInput.lidoDepositableEther < _root_.Verity.Core.Uint256.modulus := by
  decide

/-- The model commits the nine-key in-range input: nine per-key deposit frames
carrying 9 * DEPOSIT_SIZE = 288 wei in total, retained nothing.  This is the
in-range counterpart of `oversized_run_commits` and the honest motivator of the
n-frame executable gap: the source loop performs nine `deposit` frames, while
the two-leg executable plane below journals exactly two `depositToBeacon` frames
for the same input. -/
theorem manyKey_run_commits :
    run canonicalSourceConfig manyKeySourceInput
      = .committedDeposits 9 288 288 0 := by
  have hCount : actualDepositsCount canonicalSourceConfig manyKeySourceInput = 9 := by
    show 432 / 48 = 9
    decide
  have hMax : maxDepositsCount canonicalSourceConfig manyKeySourceInput = 9 := by
    show min 16 (288 / 32) = 9
    decide
  have hPull : depositsValue canonicalSourceConfig manyKeySourceInput = 288 := by
    rw [depositsValue, hCount]; decide
  have hPush : pushedValue canonicalSourceConfig manyKeySourceInput = 288 := by
    rw [pushedValue, loopPushed_eq, hCount]; decide
  have hAfter : routerBalanceAfter canonicalSourceConfig manyKeySourceInput = 0 := by
    rw [routerBalanceAfter, hPull, hPush]
    decide
  unfold run
  rw [hMax, hCount, hPull, hPush, hAfter]
  decide +kernel

/-- An exactly-two-batch `Inputs` whose legs carry `n` and `n + 1` keys at
`cfg.depositSize` wei each -- the shape `LinksSource` pins, made a definition so
the many-key witness below is a closed term. -/
def nLinks (cfg : SourceDepositConfig) (n : Nat) : Inputs :=
  { canonicalInputs with
    depositSize := _root_.Verity.Core.Uint256.ofNat cfg.depositSize
    first := { batchA with
      keys := _root_.Verity.Core.Uint256.ofNat n
      amount := _root_.Verity.Core.Uint256.ofNat (n * cfg.depositSize) }
    second := { batchB with
      keys := _root_.Verity.Core.Uint256.ofNat (n + 1)
      amount := _root_.Verity.Core.Uint256.ofNat ((n + 1) * cfg.depositSize) } }

/-- The executable hypotheses stay satisfiable *in full* at the nine-key
in-range input: `LinksSource` assigns the nine source keys to the two
aggregate legs (4 + 5) at `DEPOSIT_SIZE` per key, and -- at the concrete entry
state `canonicalState` -- the transaction's own complete precondition bundle
holds: every guard-health flag, the two distinct modules, the
`ALLOCATION_VALUE_MISMATCH` equation `288 = 9 * 32`, the zero entry balance,
the `NOT_ENOUGH_ETHER` funding premise `288 ≤ 1000`, and the no-wrap bound.
This is the full hypothesis set
`verity_tx_composes_deposit_conservation_and_rollback` demands, checked at a
closed entry state, so the two-leg composed parent admits exactly the input
whose nine per-key frames its fixed journal cannot represent.  The word bound
rules nothing out here; the frame count does. -/
theorem manyKey_links_source_two_legs :
    LinksSource canonicalSourceConfig manyKeySourceInput (nLinks canonicalSourceConfig 4) ∧
      Preconditions (nLinks canonicalSourceConfig 4) canonicalState ∧
      (nLinks canonicalSourceConfig 4).first.amount.val
          + (nLinks canonicalSourceConfig 4).second.amount.val
        < _root_.Verity.Core.Uint256.modulus := by
  refine ⟨⟨by decide, by decide, by decide, by decide⟩,
    ⟨by decide, by decide, by decide, by decide, by decide, by decide,
      by decide, by decide, by decide, by decide, by decide, by decide,
      by decide, by decide, by decide, by decide, by decide⟩, ?_⟩
  show 4 * 32 + 5 * 32 < _root_.Verity.Core.Uint256.modulus
  decide

/-- The concrete entry state of the witness with Lido's depositable ledger one
wei short of the 288-wei aggregate: identical to `canonicalState` except
`lidoDepositableSlot = 287`. -/
def manyKeyUnderfundedEntry : _root_.Verity.ContractState :=
  (_root_.Verity.defaultState.writeSlot lidoDepositableSlot 287).writeSlot counterSlot 41

/-- The admission above is load-bearing in the entry state, not inherited by
accident: one wei short on the Lido ledger and the *complete* precondition
bundle is refuted -- the funding premise `totalAmount ≤ readSlot
lidoDepositableSlot` fails as `288 ≤ 287` -- so the witness really does
kernel-check every executable guard it advertises, and an entry state that
stops satisfying any one of them no longer satisfies the bundle. -/
theorem manyKey_entry_state_guards_are_load_bearing :
    ¬ Preconditions (nLinks canonicalSourceConfig 4) manyKeyUnderfundedEntry := by
  intro h
  exact absurd h.funded (by decide)

/-- The real failing path, on the executable plane: at the underfunded entry
state the two-leg transaction runs both `obtainDepositData` module legs and
their storage writes, reaches the `pullFromLido` funding guard, and reverts
with exactly the `NOT_ENOUGH_ETHER` reason at the line-105 `require`
(`DepositParentTx.lean`), with the transaction boundary rolling the world back
to the entry snapshot.  The admission the witness proves is therefore not
vacuous: the same closed input either satisfies every guard and is admitted,
or misses the funding guard by one wei and is turned away on the exact guard
that fails. -/
theorem manyKey_underfunded_entry_reverts_at_not_enough_ether :
    (execute (nLinks canonicalSourceConfig 4)).run manyKeyUnderfundedEntry
      = .revert "NOT_ENOUGH_ETHER" manyKeyUnderfundedEntry := by
  rfl

/-! ## Private non-derivability witness

This witness deliberately leaves the two executable allocation legs unchanged,
so all of their checked guards, arithmetic bounds, distinct-module premise, and
amount-per-key equations still hold.  Only the independent source byte length
changes: it describes one public key while the two legs still contain five.
Thus allocation outputs do not constrain `publicKeysBatchLength`, and the ALLOC
parents cannot manufacture `LinksSource.keys`.

Nor may the two calls to `processBatch` be read as a fake `∀` loop.  Repeating a
leg would violate `Preconditions.distinctModules`; accumulating arbitrary legs
would require a new no-wrap proof; and `execute` itself is, intentionally,
exactly-two-batch. -/

private def counterexampleLinkInputs : Inputs := canonicalInputs

private def counterexampleSourceInput : SourceDepositInput :=
  { canonicalSourceInput with publicKeysBatchLength := 48 }

private theorem alloc_parents_do_not_imply_linkssource :
    Preconditions counterexampleLinkInputs canonicalState ∧
      counterexampleLinkInputs.depositSize.val = canonicalSourceConfig.depositSize ∧
      counterexampleLinkInputs.first.amount.val =
        counterexampleLinkInputs.first.keys.val * canonicalSourceConfig.depositSize ∧
      counterexampleLinkInputs.second.amount.val =
        counterexampleLinkInputs.second.keys.val * canonicalSourceConfig.depositSize ∧
      ¬ LinksSource canonicalSourceConfig counterexampleSourceInput
        counterexampleLinkInputs := by
  refine ⟨canonical_preconditions, by decide, by decide, by decide, ?_⟩
  intro hLink
  -- The two executable legs carry `2 + 3` keys, while the one-key source input
  -- has `actualDepositsCount = 48 / 48 = 1`; both sides are closed terms.
  exact absurd hLink.keys (by decide)

/-! ## Registered finite list-batch parent -/

namespace NFrame

open LidoSRv3.Audit.Verity
open LidoSRv3.Audit.Verity.DepositNFrameTx

/-- Data-only source link for arbitrary finite arity.  It does not contain a
post-state, journal, or conclusion. -/
structure LinksSource (cfg : SourceDepositConfig) (inp : SourceDepositInput)
    (inputs : DepositNFrameTx.Inputs) : Prop where
  depositSize : inputs.depositSize.val = cfg.depositSize
  keys : exactKeys inputs.batches = actualDepositsCount cfg inp
  batchAmounts : ∀ batch ∈ inputs.batches,
    batch.amount.val = batch.keys.val * cfg.depositSize

theorem exactTotal_eq_exactKeys_mul (batches : List DepositNFrameTx.Batch)
    (depositSize : Nat)
    (h : ∀ batch ∈ batches, batch.amount.val = batch.keys.val * depositSize) :
    exactTotal batches = exactKeys batches * depositSize := by
  induction batches with
  | nil => simp [exactTotal, exactKeys]
  | cons batch batches ih =>
      have hb := h batch (by simp)
      have ht : ∀ b ∈ batches, b.amount.val = b.keys.val * depositSize :=
        fun b hmem => h b (by simp [hmem])
      simp only [exactTotal, exactKeys, List.map_cons, List.sum_cons]
      rw [hb, ih ht, Nat.add_mul]

theorem linked_exactTotal_eq_pushedValue
    (cfg : SourceDepositConfig) (inp : SourceDepositInput)
    (inputs : DepositNFrameTx.Inputs) (h : LinksSource cfg inp inputs) :
    exactTotal inputs.batches = pushedValue cfg inp := by
  rw [exactTotal_eq_exactKeys_mul inputs.batches cfg.depositSize h.batchAmounts,
    h.keys, pushedValue, loopPushed_eq]

theorem linked_exactTotal_eq_depositsValue
    (cfg : SourceDepositConfig) (inp : SourceDepositInput)
    (inputs : DepositNFrameTx.Inputs) (h : LinksSource cfg inp inputs)
    (hCons : ConservingConfig cfg) :
    exactTotal inputs.batches = depositsValue cfg inp := by
  rw [linked_exactTotal_eq_pushedValue cfg inp inputs h, pushedValue, loopPushed_eq,
    depositsValue, hCons]

/--
P-DEPOSIT-1 list-batch product parent.  Universally quantified finite batches
produce the inductive module/pull/beacon journal, a fold equal to its exact
`Nat` total below `2^256`, and exactly `batches.length` module and beacon legs.
The exact total is linked to the source push (and to its pull only under the
explicit conserving-deployment hypothesis).
-/
theorem verity_tx_composes_nframe_deposit
    (cfg : SourceDepositConfig) (inp : SourceDepositInput)
    (inputs : DepositNFrameTx.Inputs) (entry : _root_.Verity.ContractState)
    (hLink : LinksSource cfg inp inputs)
    (hPre : DepositNFrameTx.Preconditions inputs entry) :
    ((∀ keys pulled pushed balanceAfter,
        run cfg inp = .committedDeposits keys pulled pushed balanceAfter →
          pulled = pushed ∧ depositsValue cfg inp = pushedValue cfg inp) ∧
        (¬ ConservingConfig cfg → 0 < actualDepositsCount cfg inp →
          (run cfg inp).reverts = true)) ∧
      DepositNFrameTx.ParentConclusion DepositNFrameTx.execute inputs entry ∧
      exactTotal inputs.batches = pushedValue cfg inp ∧
      (ConservingConfig cfg → exactTotal inputs.batches = depositsValue cfg inp) := by
  exact ⟨source_deposit_conserves_and_rolls_back cfg inp,
    DepositNFrameTx.nframe_deposit_parent inputs entry hPre,
    linked_exactTotal_eq_pushedValue cfg inp inputs hLink,
    linked_exactTotal_eq_depositsValue cfg inp inputs hLink⟩

/-- The old conjunct (d) is exactly this parent's `n = 2` specialization. -/
theorem two_batch_conjunct_d_is_n_eq_two (inputs : DepositParentTx.Inputs) :
    (DepositNFrameTx.ofTwoBatches inputs).batches.length = 2 ∧
      ((DepositNFrameTx.ofTwoBatches inputs).batches.map
        (DepositNFrameTx.moduleEntry (DepositNFrameTx.ofTwoBatches inputs))).length = 2 ∧
      ((DepositNFrameTx.ofTwoBatches inputs).batches.map
        (DepositNFrameTx.pushEntry (DepositNFrameTx.ofTwoBatches inputs))).length = 2 ∧
      DepositNFrameTx.expectedCalls (DepositNFrameTx.ofTwoBatches inputs) =
        DepositParentTx.expectedCalls inputs := by
  obtain ⟨hLength, hModules, hBeacon⟩ := DepositNFrameTx.two_batch_is_n_eq_two inputs
  exact ⟨hLength, hModules, hBeacon, DepositNFrameTx.two_batch_expectedCalls_eq inputs⟩

end NFrame

end LidoSRv3.Audit.Guarantees.PDeposit1
