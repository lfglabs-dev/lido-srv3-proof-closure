import LidoSRv3.Audit.Guarantees.PAccount1CheckedFeeSplit
import ReportFeeDistribution

namespace LidoSRv3.Audit.Guarantees.PAccount1

/-- Existing actual checked fee/mint followed by the source-corresponding typed
transferShares distribution. Keeps the mint/split/cast certificate at its actual
intermediate world, and derives funding, unchanged packed words, exact ordered
module transfers and conditional treasury transfer on their returned world.
Every minted share is paid, and each final account share balance equals its
initial balance plus the actual payments to that account, including aliases.
TreasuryRead is an explicitly supplied read-only typed locator boundary; this
statement does not prove its STATICCALL/ABI implementation or later callbacks. -/
theorem actual_report_fee_mint_distribution
    (read : AccountAddress.FeeDistribution.TreasuryRead)
    (x : AccountAddress.ReportFeeMint.Input) (before post : AccountAddress.ReportFeeMint.World)
    (fee : AccountAddress.ReportWriteFee.FeeResult) (events : List AccountAddress.StETHMintShares.Event)
    (trace : List (Nat × Nat))
    (h : AccountAddress.ReportFeeDistribution.execute read x before = .committed post fee events trace) :
    AccountAddress.ReportFeeDistribution.Success read x before post fee events trace ∧
    AccountAddress.ReportFeeDistribution.Ledger x before post fee trace :=
  AccountAddress.ReportFeeDistribution.execute_success_ledger read x before post fee events trace h

theorem actual_report_fee_distribution_failure_restores
    (read : AccountAddress.FeeDistribution.TreasuryRead)
    (x : AccountAddress.ReportFeeMint.Input) (before rollback : AccountAddress.ReportFeeMint.World)
    (error : AccountAddress.ReportFeeDistribution.Error) (trace : List (Nat × Nat))
    (h : AccountAddress.ReportFeeDistribution.execute read x before = .reverted error rollback trace) :
    rollback = before :=
  AccountAddress.ReportFeeDistribution.failure_restores read x before rollback error trace h

#print axioms actual_report_fee_mint_distribution
#print axioms actual_report_fee_distribution_failure_restores
end LidoSRv3.Audit.Guarantees.PAccount1
