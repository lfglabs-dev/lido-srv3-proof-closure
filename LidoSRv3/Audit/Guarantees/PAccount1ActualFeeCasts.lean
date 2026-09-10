import LidoSRv3.Audit.Guarantees.PAccount1
import ReportFeeCastInvariant

namespace LidoSRv3.Audit.Guarantees.PAccount1

/-- The actual bounded report/getter/fee/mint executor also derives that both
uint96 casts in every registered module's post-report fee calculation preserve
the mathematical value. No separated layout, distinct IDs or allocation bound
is supplied. Zero-balance modules are skipped by the actual getter; the Nat
helper's zero case does not assert execution of Solidity division by zero. -/
theorem actual_report_fee_mint_casts
    (x : AccountAddress.ReportFeeMint.Input)
    (before post : AccountAddress.ReportFeeMint.World)
    (fee : AccountAddress.ReportWriteFee.FeeResult)
    (events : List AccountAddress.StETHMintShares.Event)
    (h : AccountAddress.ReportFeeMint.handleOracleReportFromCommittedFeeProducts x before =
      .committed post fee events) :
    AccountAddress.ReportFeeMint.Success x before post fee events ∧
    ∀ id ∈ x.registeredModuleIds,
      AccountAddress.ReportFeeCastInvariant.ExactCasts x.layout post.router id :=
  AccountAddress.ReportFeeCastInvariant.composition_exact_casts x before post fee events h

#print axioms actual_report_fee_mint_casts
end LidoSRv3.Audit.Guarantees.PAccount1
