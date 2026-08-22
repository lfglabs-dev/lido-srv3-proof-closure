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
The composed parent's own hypotheses bound the source deployment it can speak
about.  `LinksSource` forces the two executable legs to carry
`actualDepositsCount cfg inp` keys at `cfg.depositSize` wei each, and
`Preconditions.noWrap` forces their sum into one 256-bit word, so the whole pull
of any linked deployment is below `2 ^ 256`.

This is the arithmetic half of the executable plane's finiteness, and it is
stated rather than left implicit: the registered abstract parent is an unbounded
`∀ (cfg, inp)` with no word bound at all, so every deployment above this bound is
covered by the abstract plane and by no executable transaction.
`abstract_parent_covers_deployments_the_verity_plane_omits` exhibits one.
-/
theorem linked_deployment_is_word_bounded
    (cfg : SourceDepositConfig) (inp : SourceDepositInput)
    (inputs : Inputs) (hLink : LinksSource cfg inp inputs)
    (hNoWrap : inputs.first.amount.val + inputs.second.amount.val
      < _root_.Verity.Core.Uint256.modulus) :
    actualDepositsCount cfg inp * cfg.depositSize
      < _root_.Verity.Core.Uint256.modulus := by
  have hSum : inputs.first.amount.val + inputs.second.amount.val
      = actualDepositsCount cfg inp * cfg.depositSize := by
    rw [hLink.firstAmount, hLink.secondAmount, ← Nat.add_mul, hLink.keys]
  omega

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
`linked_deployment_is_word_bounded`: the hypotheses admit only deployments whose
whole pull fits one 256-bit word.

Scope, stated rather than hidden: the executable plane is a Verity-EDSL
transaction (`A-VERITY-SCAFFOLD`), not an EVM execution, and the source plane is
`A-SOURCE-SHAPED`.  `LinksSource` is a hypothesis about the caller's allocation,
not a proof that the pinned Solidity produces those two legs.  The transaction
executes exactly two batches; it does not encode a universally quantified loop,
and no ALLOC composition into `LinksSource` is claimed (see the private
counterexample below).  Conjunct *(a)* is therefore the only unbounded half of
this theorem: it holds for every `(cfg, inp)`, while *(b)*, *(c)* and *(d)* speak
only about the fixed two-leg executable shape, and
`abstract_parent_covers_deployments_the_verity_plane_omits` exhibits a
deployment *(a)* covers and no executable transaction can represent.
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
        actualDepositsCount cfg inp * cfg.depositSize
          < _root_.Verity.Core.Uint256.modulus) := by
  refine ⟨source_deposit_conserves_and_rolls_back cfg inp,
    fun reason rollback hRevert =>
      ⟨revert_after_intermediate_writes_restores_snapshot inputs entry rollback reason hRevert,
        revert_observes_idle inputs entry rollback reason hRevert⟩,
    ⟨execute_observes_source inputs entry hPre, ?_⟩,
    rfl, rfl, linked_deployment_is_word_bounded cfg inp inputs hLink hPre.noWrap⟩
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

/-! ## The quantifier gap between the two planes

Non-vacuity above says the composed hypotheses are satisfiable somewhere.  It
says nothing about *where they are not*, and the registered abstract parent is an
unbounded `∀ (cfg, inp)`.  The witness below closes that reading in the opposite
direction: it names a deployment the abstract parent covers and for which no
executable transaction exists at all, so `verity: CHECKED` on this row must not
be read as an executable claim about every deployment the abstract row states. -/

/-- The pinned conserving deployment scaled to `2 ^ 256` keys: `2 ^ 256` public
keys of `PUBKEY_LENGTH = 48` bytes each.  Nothing else changes. -/
def oversizedSourceInput : SourceDepositInput :=
  { canonicalSourceInput with publicKeysBatchLength := 48 * 2 ^ 256 }

/-- That deployment's pull, `actualDepositsCount * DEPOSIT_SIZE`, is `2 ^ 261`
wei: above the 256-bit word the executable ledger is built on. -/
theorem oversized_deployment_exceeds_word :
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
The registered abstract parent is total; the registered Verity parent is not.

The first conjunct is `source_deposit_conserves_and_rolls_back` instantiated at
`oversizedSourceInput` -- the abstract plane states commit-branch conservation
and non-conserving-deployment revert there exactly as it does everywhere else.
The second says no executable transaction reaches that deployment: every
`inputs` satisfying `LinksSource` violates the composed parent's own
`Preconditions.noWrap` premise, so the hypotheses of
`verity_tx_composes_deposit_conservation_and_rollback` are jointly unsatisfiable
at this `(cfg, inp)` for *every* `inputs` and *every* entry state.

The gap is therefore not an artifact of the chosen witnesses: it is where the
executable plane's finiteness -- two legs, one 256-bit ledger word -- stops
short of the abstract plane's `∀`.  Closing it needs an `n`-frame executable
transaction, not a metadata change.
-/
theorem abstract_parent_covers_deployments_the_verity_plane_omits :
    ((∀ keys pulled pushed balanceAfter,
        run canonicalSourceConfig oversizedSourceInput
            = .committedDeposits keys pulled pushed balanceAfter →
          pulled = pushed ∧
            depositsValue canonicalSourceConfig oversizedSourceInput
              = pushedValue canonicalSourceConfig oversizedSourceInput) ∧
        (¬ ConservingConfig canonicalSourceConfig →
          0 < actualDepositsCount canonicalSourceConfig oversizedSourceInput →
          (run canonicalSourceConfig oversizedSourceInput).reverts = true)) ∧
      ∀ inputs : Inputs,
        LinksSource canonicalSourceConfig oversizedSourceInput inputs →
          ¬ inputs.first.amount.val + inputs.second.amount.val
            < _root_.Verity.Core.Uint256.modulus := by
  refine ⟨source_deposit_conserves_and_rolls_back _ _, fun inputs hLink hNoWrap => ?_⟩
  exact absurd
    (linked_deployment_is_word_bounded canonicalSourceConfig oversizedSourceInput
      inputs hLink hNoWrap)
    (Nat.not_lt.2 oversized_deployment_exceeds_word.2)

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

end LidoSRv3.Audit.Guarantees.PDeposit1
