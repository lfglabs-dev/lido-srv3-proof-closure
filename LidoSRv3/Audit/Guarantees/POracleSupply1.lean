import LidoSRv3.Audit.Spec.OracleMintCorrespondence
import LidoSRv3.Audit.Guarantees.PAccount1
import LidoSRv3.Audit.Guarantees.PAlloc1EugeneBound

/-!
# P-ORACLE-SUPPLY-1

Node 3 parent: one theorem with two conjuncts over a Spec `OracleFrame`
built from `feeWei` and `shareRate`.

1. Mint conjunct: `sharesMinted` is the computed
   `mintedShares feeWei shareRate = feeWei * shareRate / E27` and
   `shareRateDelta` is the rate. This is the fee+shareRate mint; the
   Pack E leftover (`sharesMinted = argument` for a free
   `sharesToMintAsFees`) is not this parent's conclusion.
2. Bound conjunct (sanity / Eugene aggregate): under a named cap
   `maxShareRate` on the rate, the minted shares are bounded by the fee
   converted at the cap. This conjunct is not definitional; dropping the
   cap premise is refuted in `PackN3OracleMintMutants`.

P-ACCOUNT-1 stays order-only (cited below, not widened). The existing
Eugene child is cited only as an operator-bond fact, not re-homed as this
parent.
-/

namespace LidoSRv3.Audit.Guarantees.POracleSupply1

open LidoSRv3.Audit.SolidityAccounting
open LidoSRv3.Audit.Spec
open LidoSRv3.Audit.Spec.OracleMintCorrespondence

/-- P-ORACLE-SUPPLY-1 parent. Universal over `feeWei`, `shareRate`, and the
named cap `maxShareRate`. First conjunct pair: the frame's mint is the
computed fee/shareRate conversion (definitional by construction of
`specOfMint`) and the frame records the rate. Second conjunct: the
non-definitional aggregate bound `sharesMinted ≤ feeWei * maxShareRate / E27`
under the retained premise `shareRate ≤ maxShareRate`. -/
theorem oracle_supply_mint_and_cap
    (i : ReportInput) (feeWei shareRate maxShareRate : Nat)
    (hCap : shareRate ≤ maxShareRate) :
    ((specOfMint i feeWei shareRate).sharesMinted
        = mintedShares feeWei shareRate ∧
      (specOfMint i feeWei shareRate).shareRateDelta = shareRate) ∧
      (specOfMint i feeWei shareRate).sharesMinted
        ≤ feeWei * maxShareRate / E27 :=
  ⟨⟨rfl, rfl⟩, minted_shares_le_cap feeWei shareRate maxShareRate hCap⟩

/-- Citation only: P-ACCOUNT-1 remains the order-only registered parent.
This node does not fold ACCOUNT into supply and does not widen it. -/
theorem account_parent_cited_order_only :
    LidoSRv3.Audit.Verity.HandleOracleReportTx.mintAfterReadDiscipline :=
  PAccount1.mint_after_read_discipline

/-- Citation only: the existing Eugene child as an operator-bond fact. It is
not this parent; the aggregate bound of `oracle_supply_mint_and_cap` is the
fee/shareRate cap, not the per-operator allocation bond. -/
theorem eugene_child_cited_operator_bond
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

end LidoSRv3.Audit.Guarantees.POracleSupply1
