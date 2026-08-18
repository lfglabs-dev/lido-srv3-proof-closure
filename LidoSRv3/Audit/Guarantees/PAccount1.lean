import LidoSRv3.Audit.Source.AccountingCorrespondence
import LidoSRv3.Audit.Verity.HandleOracleReportTx
import LidoSRv3.Audit.Guarantees.Registry

namespace LidoSRv3.Audit.Guarantees.PAccount1

open LidoSRv3.Audit.SolidityAccounting
open LidoSRv3.Audit.Verity.HandleOracleReportTx

def guarantee : Guarantee := ⟨.pAccount1, [.model, .source, .verityTx]⟩

/-- MODEL -> SOURCE: an accepted report has one balance snapshot for rewards. -/
theorem source_report_before_reward
    (fullReportSucceeds :
      LidoSRv3.Audit.SolidityAccounting.ReportInput → Nat → Prop)
    (i : LidoSRv3.Audit.SolidityAccounting.ReportInput)
    (sharesToMintAsFees : Nat)
    (hSuccess : fullReportSucceeds i sharesToMintAsFees)
    (hFees : 0 < sharesToMintAsFees)
    (trace : List LidoSRv3.Audit.SolidityAccounting.Step)
    (h : LidoSRv3.Audit.SolidityAccounting.sourceTrace fullReportSucceeds i
      sharesToMintAsFees hSuccess = some trace) :
    ∃ balances, trace = [
      .balancesWritten balances, .accountingCalled,
      .rewardsRead balances, .rewardsMinted] :=
  LidoSRv3.Audit.SolidityAccounting.source_report_before_reward
    fullReportSucceeds i sharesToMintAsFees hSuccess hFees trace h

/--
Faithful VERITY_TX closure for P-ACCOUNT-1. This theorem starts with the
actual `Verity.Contract.run` result of the source-shaped oracle-report
transaction and proves that its committed/reverted observables are the
pinned-source report. Validity and overflow guards execute in the body;
every failure, including overflow after prefix `writeMapUint` stores and
an injected failure after the total/step-flag writes, observes Verity's
pre-call rollback state.

This is not an EVM theorem: storage-slot numbers are a model-local
projection, and no Solidity compiler, Yul, runtime bytecode, proxy layout,
deployed code, or external-call semantics is claimed.
-/
theorem verity_tx_simulates_oracle_report
    (i : ReportInput) (sharesToMintAsFees : Nat) (state : Verity.ContractState) :
    observe i ((handleOracleReport i sharesToMintAsFees).run state) =
      sourceView i sharesToMintAsFees :=
  verity_tx_simulates_pinned_source i sharesToMintAsFees state

/-- On every reverting executable Verity transition the pre-call snapshot
is restored, including after intermediate mapping and slot writes. -/
theorem verity_tx_revert_restores_snapshot
    (i : ReportInput) (sharesToMintAsFees : Nat) (inject : Bool)
    (state rollback : Verity.ContractState) (reason : String)
    (h : (handleOracleReport i sharesToMintAsFees inject).run state =
      .revert reason rollback) :
    rollback = state :=
  revert_restores_snapshot i sharesToMintAsFees inject state rollback reason h

end LidoSRv3.Audit.Guarantees.PAccount1
