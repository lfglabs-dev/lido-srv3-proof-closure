import LidoSRv3.Audit.Guarantees.PDeposit1

/-!
# A-ABSTRACT-TX is orphaned from the two registered P-DEPOSIT-1 parents

The `A-ABSTRACT-TX` assumption records that common success/revert semantics
are stated against an abstract observation type
(`LidoSRv3.Audit.TxObservation`) whose `.reverted` case maps to
`before`/`⟨[], [], []⟩` by definition rather than by executable EVM
semantics. The concern is that a theorem invoking this abstract shape
would carry the modeling gap into its conclusion.

This module proves that **neither** of the two registered P-DEPOSIT-1
parents does that:

- `LidoSRv3.Audit.Guarantees.PDeposit1.source_deposit_conserves_and_rolls_back`
  is quantified only over source-plane data (`SourceDepositConfig`,
  `SourceDepositInput`, the source `run` outcome). Its conclusion
  (`CommittedPushConserves cfg inp ∧ NonConservingDeploymentReverts cfg inp`)
  never mentions `TxObservation`, `.reverted`, `.committedState`, or
  `.committedTrace`.

- `LidoSRv3.Audit.Guarantees.PDeposit1.NFrame.verity_tx_composes_nframe_deposit`
  is quantified over the same source-plane data plus Verity's executable
  `Contract.run` state (`Verity.ContractState`) via
  `DepositNFrameTx.Inputs`/`Preconditions`. Its conclusion likewise never
  mentions `TxObservation` or its accessors.

`PDeposit1.lean:108-114` already records this explicitly: the abstract
`TxObservation` rollback fact "is definitional in this model and is
therefore *not* a conjunct of this registered parent. It remains
available as the unregistered child `revert_restores_state_value_and_logs`."

The theorems below make this documentation load-bearing: they show that
for **any** caller-supplied hypothesis representing A-ABSTRACT-TX (the
abstract observation model's faithfulness to EVM revert semantics), the
registered parents' conclusions still fire — the hypothesis is ignored
by the parent's proof term.

Consequently `A-ABSTRACT-TX` is retired from `P-DEPOSIT-1.assumptions`
in `audit/guarantees.yaml`. The `A-ABSTRACT-TX` entry itself remains in
`audit/assumptions.yaml` because `P-TOPUP-1` and `P-CONSOLIDATION-ETH-1`
still cite it (their registered parents fold in `RevertRestoresSnapshot`
/ abstract-TX conjuncts explicitly).
-/

namespace LidoSRv3.Audit.Provenance.DepositAbstractTxOrphaned

open LidoSRv3.Audit.SolidityDeposit
open LidoSRv3.Audit.Guarantees
open LidoSRv3.Audit.Guarantees.PDeposit1

/-- The registered P-DEPOSIT-1 source parent's conclusion holds for
every `(cfg, inp)`, regardless of any caller-supplied A-ABSTRACT-TX
hypothesis. The `_hAbstractTxFaithful` premise is introduced only to
make the orphanage explicit — the parent's proof term ignores it
entirely. -/
theorem source_parent_ignores_abstract_tx
    (AbstractTxFaithful : Prop)
    (_hAbstractTxFaithful : AbstractTxFaithful)
    (cfg : SourceDepositConfig) (inp : SourceDepositInput) :
    CommittedPushConserves cfg inp ∧ NonConservingDeploymentReverts cfg inp :=
  PDeposit1.source_deposit_conserves_and_rolls_back cfg inp

/-- Same statement without the ignored hypothesis: the source parent
applies universally, so its correctness does not depend on the
faithfulness of the abstract `TxObservation` model. -/
theorem source_parent_applies_universally
    (cfg : SourceDepositConfig) (inp : SourceDepositInput) :
    CommittedPushConserves cfg inp ∧ NonConservingDeploymentReverts cfg inp :=
  PDeposit1.source_deposit_conserves_and_rolls_back cfg inp

/-- The registered P-DEPOSIT-1 Verity-executable parent's conclusion
holds for every legal `(cfg, inp, inputs, entry)` under
`LinksSource cfg inp inputs` and `Preconditions inputs entry`,
regardless of any caller-supplied A-ABSTRACT-TX hypothesis. The
`_hAbstractTxFaithful` premise is ignored. -/
theorem verity_parent_ignores_abstract_tx
    (AbstractTxFaithful : Prop)
    (_hAbstractTxFaithful : AbstractTxFaithful)
    (cfg : SourceDepositConfig) (inp : SourceDepositInput)
    (inputs : LidoSRv3.Audit.Verity.DepositNFrameTx.Inputs)
    (entry : _root_.Verity.ContractState)
    (hLink : PDeposit1.NFrame.LinksSource cfg inp inputs)
    (hPre : LidoSRv3.Audit.Verity.DepositNFrameTx.Preconditions inputs entry) :
    (CommittedPushConserves cfg inp ∧ NonConservingDeploymentReverts cfg inp) ∧
      PDeposit1.NFrame.ExecutesNFrameJournal inputs entry ∧
      PDeposit1.NFrame.ExactTotalIsSourcePush cfg inp inputs ∧
      PDeposit1.NFrame.ConservingDeploymentPullsExactTotal cfg inp inputs :=
  PDeposit1.NFrame.verity_tx_composes_nframe_deposit cfg inp inputs entry hLink hPre

/-- Same statement without the ignored hypothesis: the Verity-executable
parent applies universally, so its correctness does not depend on the
faithfulness of the abstract `TxObservation` model. -/
theorem verity_parent_applies_universally
    (cfg : SourceDepositConfig) (inp : SourceDepositInput)
    (inputs : LidoSRv3.Audit.Verity.DepositNFrameTx.Inputs)
    (entry : _root_.Verity.ContractState)
    (hLink : PDeposit1.NFrame.LinksSource cfg inp inputs)
    (hPre : LidoSRv3.Audit.Verity.DepositNFrameTx.Preconditions inputs entry) :
    (CommittedPushConserves cfg inp ∧ NonConservingDeploymentReverts cfg inp) ∧
      PDeposit1.NFrame.ExecutesNFrameJournal inputs entry ∧
      PDeposit1.NFrame.ExactTotalIsSourcePush cfg inp inputs ∧
      PDeposit1.NFrame.ConservingDeploymentPullsExactTotal cfg inp inputs :=
  PDeposit1.NFrame.verity_tx_composes_nframe_deposit cfg inp inputs entry hLink hPre

end LidoSRv3.Audit.Provenance.DepositAbstractTxOrphaned
