import LidoSRv3.Audit.Source.AccountingCorrespondence
import LidoSRv3.Audit.Guarantees.Registry

namespace LidoSRv3.Audit.Guarantees.PAccount1

def guarantee : Guarantee := ⟨.pAccount1, [.model, .abstractTx, .source]⟩

/-- MODEL -> SOURCE: a committed pinned-source accounting run implements the
checked abstract accounting transaction. -/
theorem source_refines_model :
    ∀ (before after : LidoSRv3.Audit.SolidityAccounting.AccountingState)
      (input : LidoSRv3.Audit.SolidityAccounting.TxInput),
      LidoSRv3.Audit.SolidityAccounting.sourceRun before input = .committed after →
      LidoSRv3.Audit.SolidityAccounting.abstractTransaction before input.report = some after :=
  LidoSRv3.Audit.SolidityAccounting.source_refines_model

/-- MODEL -> SOURCE -> VERITY_TX, using pinned `Verity.Contract.run`
execution and its rollback/committed-storage observables. -/
theorem verity_tx_refines_model :
    ∀ (before after : LidoSRv3.Audit.SolidityAccounting.AccountingState)
      (input : LidoSRv3.Audit.SolidityAccounting.TxInput),
      (LidoSRv3.Audit.SolidityAccounting.observeVerityTx before input).outcome =
          .committed after →
      LidoSRv3.Audit.SolidityAccounting.abstractTransaction before input.report = some after :=
  LidoSRv3.Audit.SolidityAccounting.verity_tx_refines_model

end LidoSRv3.Audit.Guarantees.PAccount1
