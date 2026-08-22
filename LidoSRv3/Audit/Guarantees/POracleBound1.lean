import LidoSRv3.Audit.Spec.OracleMintCorrespondence
import LidoSRv3.Audit.Guarantees.PAlloc1EugeneBound

/-!
# P-ORACLE-BOUND-1

Supplemental aggregate sanity parent for the computed oracle mint.  The
existing Eugene allocation child is retained only as a cited operator-bond
fact; it is not this supply parent.
-/

namespace LidoSRv3.Audit.Guarantees.POracleBound1

open LidoSRv3.Audit.Spec.OracleMintCorrespondence
open LidoSRv3.Audit.MinFirstAllocation

/-- Supplemental P-ORACLE-BOUND-1 parent.  A named maximum share rate bounds
the aggregate computed mint.  The cap premise is load-bearing: it supplies
the numerator inequality before division by the common E27 scale. -/
theorem computed_mint_le_aggregate_cap
    (feeWei shareRate maxShareRate : Nat)
    (hShareRate : shareRate ≤ maxShareRate) :
    mintedShares feeWei shareRate ≤
      feeWei * maxShareRate / shareRateScale := by
  unfold mintedShares
  exact Nat.div_le_div_right (Nat.mul_le_mul_left feeWei hShareRate)

/-- Citation only: the existing Eugene child bounds one checked allocation by
its selected operator's checked bond.  It is independent of the aggregate
oracle-mint parent above. -/
theorem eugene_operator_bond_fact_cited
    (rows : List Source.Row) (allocationSize : Source.Word)
    (best : Source.Row) (bond allocated : Source.Word)
    (hBond : Verity.Stdlib.Math.safeSub best.capacity best.allocation = some bond)
    (hAmount : Source.checkedAmount rows allocationSize best = some allocated) :
    allocated ≤ bond :=
  PAlloc1EugeneBound.checked_amount_le_bond
    rows allocationSize best bond allocated hBond hAmount

end LidoSRv3.Audit.Guarantees.POracleBound1
