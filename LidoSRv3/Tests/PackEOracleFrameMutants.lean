import LidoSRv3.Audit.Spec
import LidoSRv3.Audit.Spec.OracleFrameCorrespondence
import LidoSRv3.Audit.Source.AccountingCorrespondence

/-!
# Pack E fail-closed vectors

A mutant that treats `sharesMinted` as a computed sum of balances disagrees
with the `sharesToMintAsFees` argument.
-/

namespace LidoSRv3.Tests.PackEOracleFrameMutants

open LidoSRv3.Audit.Spec
open LidoSRv3.Audit.Spec.OracleFrameCorrespondence
open LidoSRv3.Audit.SolidityAccounting

private def report : ReportInput :=
  { registeredModuleIds := [1, 2]
    reportedModuleIds := [1, 2]
    balancesGwei := [10, 20] }

/-- Mutant: mint equals the balance sum, not the fee argument. -/
def specOfOracleSumBalances (i : ReportInput) (_sharesToMintAsFees : Nat) :
    OracleFrame where
  balances := i.balancesGwei
  sharesMinted := i.balancesGwei.sum
  shareRateDelta := 0

/-- Kill-line: on balances `[10, 20]` and argument `7`, the honest frame
mints `7` and the sum-mutant mints `30`. -/
theorem computed_fee_kill_line_refutes_oracle_frame :
    (specOfOracle report 7).sharesMinted = 7 ∧
      (specOfOracleSumBalances report 7).sharesMinted = 30 ∧
      specOfOracle report 7 ≠ specOfOracleSumBalances report 7 := by
  decide

end LidoSRv3.Tests.PackEOracleFrameMutants
