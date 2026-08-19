import LidoSRv3.Audit.Source.AccountingCorrespondence
import LidoSRv3.Audit.Verity.HandleOracleReportTx
import LidoSRv3.Audit.Guarantees.Registry

namespace LidoSRv3.Audit.Guarantees.PAccount1

open LidoSRv3.Audit.SolidityAccounting
open LidoSRv3.Audit.Verity.HandleOracleReportTx

def guarantee : Guarantee := ⟨.pAccount1, [.model, .source, .verityTx]⟩

/-- If an independently supplied `fullReportSucceeds` premise lets
`sourceTrace` return `some trace`, and fee shares are strictly positive,
then that trace is exactly
`[balancesWritten b, accountingCalled, rewardsRead b, rewardsMinted]`
for one shared `b`. This is the constructor order of `successfulSteps`,
not `submitReportData`. -/
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

/-- `observe` of `handleOracleReport` (balance array + total/flag slots)
equals the independently stated `sourceView`. Not `submitReportData`;
`sharesToMintAsFees` is an argument, not a computed fee. -/
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
