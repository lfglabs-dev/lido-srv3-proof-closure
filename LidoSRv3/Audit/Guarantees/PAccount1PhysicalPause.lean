import ReportFeePhysicalPause
namespace LidoSRv3.Audit.Guarantees.PAccount1
set_option autoImplicit false
open AccountAddress AccountAddress.ReportWriteFee AccountAddress.StETHMintShares
open AccountAddress.ReportFeePhysicalPause

/-- Full324 treasury-call effect on the explicitly projected input, plus the
physical pause-word invariant and actual per-payment physical admission chain.
No assumed flag/storage equality or restricted initial physical-state domain. -/
theorem actual_report_physical_pause (e : TreasuryCall.Environment) (x : ReportFeeMint.Input)
    (before post : ReportFeeMint.World) (fee : FeeResult) (events : List Event)
    (payments : ReportFeeTreasuryCall.Payments) (attempts : ReportFeeTreasuryCall.Attempts)
    (h : execute e x before = .committed post fee events payments attempts) :
    OldEffect e x before post fee events payments attempts ∧ PhysicalEffect x before post fee events payments :=
  ReportFeePhysicalPause.execute_success e x before post fee events payments attempts h

/-- Root rollback restores even the input's untrusted legacy flag metadata. -/
theorem actual_report_physical_pause_failure_restores (e : TreasuryCall.Environment) (x : ReportFeeMint.Input)
    (before rollback : ReportFeeMint.World) (fault : ReportFeeTreasuryCall.Error)
    (payments : ReportFeeTreasuryCall.Payments) (attempts : ReportFeeTreasuryCall.Attempts)
    (h : execute e x before = .reverted fault rollback payments attempts) : rollback = before :=
  ReportFeePhysicalPause.failure_restores e x before rollback fault payments attempts h
end LidoSRv3.Audit.Guarantees.PAccount1
