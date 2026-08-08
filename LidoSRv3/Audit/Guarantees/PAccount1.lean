import LidoSRv3.Audit.Source.AccountingCorrespondence
import LidoSRv3.Audit.Guarantees.Registry

namespace LidoSRv3.Audit.Guarantees.PAccount1

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

/-- SOURCE -> VERITY_TX, including checked-word refinement. -/
theorem source_to_verityTx
    (fullReportSucceeds :
      LidoSRv3.Audit.SolidityAccounting.ReportInput → Nat → Prop)
    (i : LidoSRv3.Audit.SolidityAccounting.ReportInput)
    (sharesToMintAsFees : Nat)
    (hSuccess : fullReportSucceeds i sharesToMintAsFees)
    (accepted : LidoSRv3.Audit.SolidityAccounting.AcceptedReport)
    (h : LidoSRv3.Audit.SolidityAccounting.accept i = some accepted) :
    LidoSRv3.Audit.SolidityAccounting.checkedTotal256 accepted.balancesGwei =
        some (Verity.Core.Uint256.ofNat accepted.totalBalanceGwei) ∧
      LidoSRv3.Audit.SolidityAccounting.verityTxAccept i = some accepted ∧
      LidoSRv3.Audit.SolidityAccounting.verityTxTrace fullReportSucceeds i
        sharesToMintAsFees hSuccess =
          LidoSRv3.Audit.SolidityAccounting.sourceTrace fullReportSucceeds i
            sharesToMintAsFees hSuccess :=
  LidoSRv3.Audit.SolidityAccounting.source_to_verityTx
    fullReportSucceeds i sharesToMintAsFees hSuccess accepted h

/-- SOURCE -> actual typed-storage `verity_contract` execution for the
accounting-relevant prefix. Full-report success and external calls remain
outside this narrower executable theorem. -/
theorem verity_contract_run_commits_accepted
    (state : Verity.ContractState)
    (i : LidoSRv3.Audit.SolidityAccounting.ReportInput)
    (accepted : LidoSRv3.Audit.SolidityAccounting.AcceptedReport)
    (h : LidoSRv3.Audit.SolidityAccounting.accept i = some accepted) :
    ∃ after,
      (LidoSRv3.Audit.SolidityAccounting.AccountingContract.submitReportBalances i).run state =
        .success accepted after ∧
      after.storage
          LidoSRv3.Audit.SolidityAccounting.AccountingContract.lastTotalBalanceGwei.slot =
        Verity.Core.Uint256.ofNat accepted.totalBalanceGwei ∧
      after.storage
          LidoSRv3.Audit.SolidityAccounting.AccountingContract.lastModuleCount.slot =
        Verity.Core.Uint256.ofNat accepted.moduleIds.length :=
  LidoSRv3.Audit.SolidityAccounting.accounting_run_commits_accepted state i accepted h

end LidoSRv3.Audit.Guarantees.PAccount1
