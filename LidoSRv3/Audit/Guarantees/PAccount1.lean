import LidoSRv3.Audit.Source.AccountingCorrespondence
import LidoSRv3.Audit.Guarantees.Registry

namespace LidoSRv3.Audit.Guarantees.PAccount1

def guarantee : Guarantee := ⟨.pAccount1, [.model, .source, .verityTx]⟩

/-- MODEL -> SOURCE: an accepted report has one balance snapshot for rewards. -/
theorem source_report_before_reward
    (i : LidoSRv3.Audit.SolidityAccounting.ReportInput)
    (trace : List LidoSRv3.Audit.SolidityAccounting.Step)
    (h : LidoSRv3.Audit.SolidityAccounting.sourceTrace i = some trace) :
    ∃ balances, trace = [
      .balancesWritten balances, .accountingCalled,
      .rewardsRead balances, .rewardsMinted] :=
  LidoSRv3.Audit.SolidityAccounting.source_report_before_reward i trace h

/-- SOURCE -> VERITY_TX, including checked-word refinement. -/
theorem source_to_verityTx
    (i : LidoSRv3.Audit.SolidityAccounting.ReportInput)
    (accepted : LidoSRv3.Audit.SolidityAccounting.AcceptedReport)
    (h : LidoSRv3.Audit.SolidityAccounting.accept i = some accepted) :
    LidoSRv3.Audit.SolidityAccounting.checkedTotal256 accepted.balancesGwei =
        some (Verity.Core.Uint256.ofNat accepted.totalBalanceGwei) ∧
      LidoSRv3.Audit.SolidityAccounting.sourceTrace i = some [
        .balancesWritten accepted.balancesGwei, .accountingCalled,
        .rewardsRead accepted.balancesGwei, .rewardsMinted] :=
  LidoSRv3.Audit.SolidityAccounting.source_to_verityTx i accepted h

end LidoSRv3.Audit.Guarantees.PAccount1
