import LidoSRv3.Audit.Spec
import LidoSRv3.Audit.Source.AccountingCorrespondence
import LidoSRv3.Audit.MinFirstAllocation
import LidoSRv3.Audit.Guarantees.PAccount1
import LidoSRv3.Audit.Guarantees.PAlloc1EugeneBound
import LidoSRv3.Audit.Verity.HandleOracleReportTx

/-!
# Pack E: OracleFrame fee/share projection

Unregistered children. They do not replace the registered P-ACCOUNT-1
parent, do not compute fees, and do not invent a supply-bound ID.
-/

namespace LidoSRv3.Audit.Spec.OracleFrameCorrespondence

open LidoSRv3.Audit.SolidityAccounting
open LidoSRv3.Audit.Guarantees

/-- Honest Spec frame: minted shares are the transaction argument;
`shareRateDelta` is unmodeled (`0`). -/
def specOfOracle (i : ReportInput) (sharesToMintAsFees : Nat) : OracleFrame where
  balances := i.balancesGwei
  sharesMinted := sharesToMintAsFees
  shareRateDelta := 0

/-- Unregistered child: Spec `sharesMinted` is the argument, not a fee
computed from balances. Share-rate delta is named as unmodeled. -/
theorem oracle_frame_shares_are_the_argument
    (i : ReportInput) (sharesToMintAsFees : Nat) :
    (specOfOracle i sharesToMintAsFees).sharesMinted = sharesToMintAsFees ∧
      (specOfOracle i sharesToMintAsFees).shareRateDelta = 0 ∧
      (specOfOracle i sharesToMintAsFees).balances = i.balancesGwei :=
  ⟨rfl, rfl, rfl⟩

/-- P-ACCOUNT-1 stays order-only. Pack E cites the registered parent rather
than folding it into a supply bound. -/
theorem account_parent_remains_order_only :
    LidoSRv3.Audit.Verity.HandleOracleReportTx.mintAfterReadDiscipline :=
  PAccount1.mint_after_read_discipline

/-- Citation of the existing Eugene child. Not re-homed. Not a stETH supply
bound and not a fee-computation theorem. -/
theorem eugene_bound_cited
    (rows : List MinFirstAllocation.Source.Row)
    (allocationSize : MinFirstAllocation.Source.Word)
    (best : MinFirstAllocation.Source.Row)
    (bond allocated : MinFirstAllocation.Source.Word)
    (hBond : Verity.Stdlib.Math.safeSub best.capacity best.allocation = some bond)
    (hAmount :
      MinFirstAllocation.Source.checkedAmount rows allocationSize best = some allocated) :
    allocated ≤ bond :=
  PAlloc1EugeneBound.checked_amount_le_bond
    rows allocationSize best bond allocated hBond hAmount

end LidoSRv3.Audit.Spec.OracleFrameCorrespondence
