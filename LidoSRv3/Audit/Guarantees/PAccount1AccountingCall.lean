import ReportFeeAccountingCall
namespace LidoSRv3.Audit.Guarantees.PAccount1
set_option autoImplicit false
open AccountAddress AccountAddress.ReportWriteFee AccountAddress.StETHMintShares
open AccountAddress.ReportFeeAccountingCall

/-- Actual physical-target legacy CALL, decoded immutable getter response
consumed by mint authorization after report/getter/checked fees, followed by
real payments and treasury STATICCALL. Full340/324 conclusions are retained
on the explicitly derived context. Effective deployed getter identity remains
a boundary; no frame, supplied auth equality or successful-stage premise. -/
theorem actual_report_accounting_call (accounting : AccountingCall.Environment)
    (treasury : TreasuryCall.Environment) (x : Input) (before post : World)
    (fee : FeeResult) (events : List Event) (payments : Payments) (treasuryAttempts : Attempts)
    (h : (execute accounting treasury x before).outcome =
      .committed post fee events payments treasuryAttempts) :
    Success accounting treasury x before post fee events payments treasuryAttempts
      (execute accounting treasury x before).accountingAttempts :=
  ReportFeeAccountingCall.execute_success accounting treasury x before post fee events payments treasuryAttempts h

/-- All failures restore the original World, including both legacy metadata
fields, report writes, physical words and abstract shares. -/
theorem actual_report_accounting_call_failure_restores (accounting : AccountingCall.Environment)
    (treasury : TreasuryCall.Environment) (x : Input) (before rollback : World)
    (fault : ReportFeeTreasuryCall.Error) (payments : Payments) (treasuryAttempts : Attempts)
    (h : (execute accounting treasury x before).outcome =
      .reverted fault rollback payments treasuryAttempts) : rollback = before :=
  ReportFeeAccountingCall.failure_restores accounting treasury x before rollback fault payments treasuryAttempts h
end LidoSRv3.Audit.Guarantees.PAccount1
