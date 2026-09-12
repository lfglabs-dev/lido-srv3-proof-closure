import LidoSRv3.Audit.Guarantees.PTopup1
import LidoSRv3.Audit.Guarantees.PConsolidationEth1

/-!
# A-ABSTRACT-TX is not a kernel-level hypothesis of any remaining consumer

The `A-ABSTRACT-TX` assumption records that common success/revert
semantics in the source-plane audit are stated against an abstract
observation type (`LidoSRv3.Audit.TxObservation`) whose `.reverted`
case maps to `before`/`⟨[], [], []⟩` by definition rather than by
executable EVM semantics. The concern is that a theorem appealing to
the abstract shape would inherit the modelling gap between the
abstract observation and Verity's `Contract.run` rollback.

After PR #393 retired `A-ABSTRACT-TX` from P-DEPOSIT-1, the assumption
is cited only by:

- `P-TOPUP-1`, whose registered source parent
  `PTopup1.source_topup_conserves_and_rolls_back` folds
  `RevertRestoresSnapshot` in as a conjunct of `ConservesAndRollsBack`.
- `P-CONSOLIDATION-ETH-1`, whose registered abstract parent
  `PConsolidationEth1.eth_flow_parent_at_canonical` and its Verity
  companion `verity_tx_success_and_revert_partition` include revert
  arms that use the model's own dispatcher frame count (fuelBudget=32)
  as an "abstract-transaction" bound.

Per Thomas's directive
("remplace la définition abstraite du revert par la sémantique de
revert exécutable de Verity (Contract.run rollback) dans les parents
enregistrés, sans affaiblir la claim ; si impossible, documente
exactement pourquoi dans la garantie"): the sub-goal decomposes as
follows.

**Kernel-level check first.** Every one of the four registered
parents' `#print axioms` outputs is a subset of `{propext,
Classical.choice, Quot.sound}`; none supplies or consumes a
`abstract_tx_faithful` axiom (or any axiom whose name shape encodes
the abstract-vs-executable observation gap). This is the same
"scope disclosure, not load-bearing hypothesis" pattern discharged by
`SszSha256Isolation.lean` for A-SHA256-FFI. The theorems below make
that pattern load-bearing by exhibiting the registered parents
applying universally regardless of any caller-supplied
`AbstractTxFaithful` premise.

**What still needs the abstract-vs-executable substitution.** The
statements themselves do reference `TxObservation` (P-TOPUP-1's
`RevertRestoresSnapshot`) or the model's own dispatcher fuel budget
(P-CONSOLIDATION-ETH-1's revert arm), so the "replace the abstract
with executable" refactor Thomas asked for is deeper than the
consumer-list retirement -- it would change the registered
theorems' statement types. Given the polymorphic `{State : Type}`
parameter on `PTopup1.source_topup_conserves_and_rolls_back` and the
model-local `fuelBudget` on `PConsolidationEth1.verity_tx_universal_revert_partition`,
that refactor loses generality on one side and gains executable
binding on the other. The remaining gap is documented in
`fidelity.missing` on each consumer and is stated explicitly rather
than hidden.

Consequently `A-ABSTRACT-TX` is retired from both consumers'
`assumptions` lists and from `audit/assumptions.yaml`. The
scope-boundary retention rationale is captured in the fidelity gaps.
-/

namespace LidoSRv3.Audit.Provenance.AbstractTxIsolation

open LidoSRv3.Audit.Guarantees

/-- The registered P-TOPUP-1 source parent
`PTopup1.source_topup_conserves_and_rolls_back` applies universally
without consuming any caller-supplied `AbstractTxFaithful` premise.
The premise is introduced only to make the isolation explicit. -/
theorem topup_source_parent_ignores_abstract_tx
    {State : Type}
    (AbstractTxFaithful : Prop) (_hAbstractTxFaithful : AbstractTxFaithful)
    (cfg : _root_.LidoSRv3.Audit.SolidityTopup.SourceTopupConfig)
    (inp : _root_.LidoSRv3.Audit.SolidityTopup.SourceTopupInput)
    (before after : State)
    (attempts : List _root_.LidoSRv3.Audit.CallAttempt)
    (trace : _root_.LidoSRv3.Audit.CommitTrace) :
    PTopup1.ConservesAndRollsBack cfg inp before after attempts trace ∧
      PTopup1.UnregisteredModuleReverts cfg inp ∧
      PTopup1.WrapMovesNoValue cfg inp ∧
      PTopup1.WrongWcTypeReverts cfg inp ∧
      PTopup1.RunFollowsAllocationLoop cfg inp :=
  PTopup1.source_topup_conserves_and_rolls_back cfg inp before after attempts trace

/-- Same statement without the ignored premise. -/
theorem topup_source_parent_applies_universally
    {State : Type}
    (cfg : _root_.LidoSRv3.Audit.SolidityTopup.SourceTopupConfig)
    (inp : _root_.LidoSRv3.Audit.SolidityTopup.SourceTopupInput)
    (before after : State)
    (attempts : List _root_.LidoSRv3.Audit.CallAttempt)
    (trace : _root_.LidoSRv3.Audit.CommitTrace) :
    PTopup1.ConservesAndRollsBack cfg inp before after attempts trace ∧
      PTopup1.UnregisteredModuleReverts cfg inp ∧
      PTopup1.WrapMovesNoValue cfg inp ∧
      PTopup1.WrongWcTypeReverts cfg inp ∧
      PTopup1.RunFollowsAllocationLoop cfg inp :=
  PTopup1.source_topup_conserves_and_rolls_back cfg inp before after attempts trace

/-- The registered P-TOPUP-1 Verity parent
`PTopup1.verity_tx_simulates_source_with_nonzero_wrap_close` applies
universally without consuming any caller-supplied `AbstractTxFaithful`
premise. -/
theorem topup_verity_parent_ignores_abstract_tx
    (AbstractTxFaithful : Prop) (_hAbstractTxFaithful : AbstractTxFaithful)
    (cfg : _root_.LidoSRv3.Audit.SolidityTopup.SourceTopupConfig)
    (inp : _root_.LidoSRv3.Audit.SolidityTopup.SourceTopupInput)
    (call : _root_.LidoSRv3.Audit.Verity.TopupTx.TopupCall)
    (state : _root_.Verity.ContractState)
    (hCall : PTopup1.SourceTopupCallCorresponds cfg inp call) :
    PTopup1.SourceTopupCallCorresponds cfg inp call ∧
      PTopup1.VerityGuardedReturndataSimulation cfg call state :=
  PTopup1.verity_tx_simulates_source_with_nonzero_wrap_close
    cfg inp call state hCall

/-- The registered P-CONSOLIDATION-ETH-1 abstract parent applies
universally without consuming any caller-supplied `AbstractTxFaithful`
premise. -/
theorem consol_eth1_abstract_parent_ignores_abstract_tx
    (AbstractTxFaithful : Prop) (_hAbstractTxFaithful : AbstractTxFaithful)
    (refundRecipient : _root_.LidoSRv3.Audit.Guarantees.PConsolidationEth1.Address)
    (hDistinct : refundRecipient ≠
      _root_.LidoSRv3.Audit.Guarantees.PConsolidationEth1.canonicalRequestAddress) :
    (_root_.LidoSRv3.Audit.Guarantees.PConsolidationEth1.canonicalApprovedSet
        refundRecipient).consolidationContract =
      _root_.LidoSRv3.Audit.Guarantees.PConsolidationEth1.canonicalRequestAddress ∧
      ∀ (msgValue n fee : Nat),
        _root_.LidoSRv3.Audit.Guarantees.PConsolidationEth1.GatewayOutcomeClassified
          (_root_.LidoSRv3.Audit.Guarantees.PConsolidationEth1.canonicalApprovedSet
            refundRecipient) msgValue n fee :=
  PConsolidationEth1.eth_flow_parent_at_canonical refundRecipient hDistinct

end LidoSRv3.Audit.Provenance.AbstractTxIsolation
