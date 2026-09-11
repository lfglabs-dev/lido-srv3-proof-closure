import ReportFeeTreasuryCall
namespace LidoSRv3.Audit.Guarantees.PAccount1
set_option autoImplicit false
open AccountAddress AccountAddress.ReportWriteFee AccountAddress.StETHMintShares
open AccountAddress.ReportFeeTreasuryCall

/-- Actual typed ACCOUNT report/mint/distribution plus a readonly treasury
request on the exact post-module World; decoded recipient is actually paid.
The locator immutable/code context is supplied, not a deployment proof. -/
theorem actual_report_fee_mint_treasury_call (e : TreasuryCall.Environment) (x : ReportFeeMint.Input)
    (before post : ReportFeeMint.World) (fee : FeeResult) (events : List Event) (payments : Payments) (attempts : Attempts)
    (h : execute e x before = .committed post fee events payments attempts) :
    ∃ minted mintEvents,
      ReportFeeMint.handleOracleReportFromCommittedFeeProducts x before = .committed minted fee mintEvents ∧
      ReportFeeDistribution.Success (TreasuryCall.read e x.accountingAddress minted.router) x before post fee events payments ∧
      ReportFeeDistribution.Ledger x before post fee payments ∧
      ((fee.sharesToMintAsFees = 0 ∧ attempts = []) ∨
       (0 < fee.sharesToMintAsFees ∧ ∃ distributionEvents,
         distribute e x.accountingAddress fee minted = .committed post distributionEvents payments attempts ∧
         ReadEffects e x.accountingAddress fee minted post distributionEvents payments attempts ∧
         events = mintEvents++distributionEvents)) :=
  ReportFeeTreasuryCall.execute_success e x before post fee events payments attempts h

theorem actual_report_treasury_failure_restores (e : TreasuryCall.Environment) (x : ReportFeeMint.Input)
    (before rollback : ReportFeeMint.World) (fault : ReportFeeTreasuryCall.Error) (payments : Payments) (attempts : Attempts)
    (h : execute e x before = .reverted fault rollback payments attempts) : rollback = before :=
  ReportFeeTreasuryCall.failure_restores e x before rollback fault payments attempts h

#print axioms actual_report_fee_mint_treasury_call
#print axioms actual_report_treasury_failure_restores
end LidoSRv3.Audit.Guarantees.PAccount1
