import LidoSRv3.Audit.Guarantees.PAccount1ActualFeeCasts
import ReportFeeCheckedSplit

namespace LidoSRv3.Audit.Guarantees.PAccount1

/-- The fee actually consumed by the successful bounded mint is partitioned
exactly: checked module floors plus treasury equal the same minted quantity.
This preserves the existing report/mint and derived cast conclusions. No
later distribution transfer or reward callback is included. -/
theorem actual_report_fee_mint_checked_split
    (x : AccountAddress.ReportFeeMint.Input)
    (before post : AccountAddress.ReportFeeMint.World)
    (fee : AccountAddress.ReportWriteFee.FeeResult)
    (events : List AccountAddress.StETHMintShares.Event)
    (h : AccountAddress.ReportFeeMint.handleOracleReportFromCommittedFeeProducts x before =
      .committed post fee events) :
    AccountAddress.ReportFeeCheckedSplit.Success x before post fee events :=
  AccountAddress.ReportFeeCheckedSplit.committed_checked_split x before post fee events h

#print axioms actual_report_fee_mint_checked_split
end LidoSRv3.Audit.Guarantees.PAccount1
