import LidoSRv3.Audit.Spec.OracleMintCorrespondence
import LidoSRv3.Audit.Guarantees.PAccount1
import LidoSRv3.Audit.Guarantees.PAlloc1EugeneBound
import LidoSRv3.Audit.Guarantees.Registry

/-!
# P-ORACLE-SUPPLY-1

Strengthened parent: Spec fee/shareRate mint+cap, plus the live
`handleOracleReportComputed` path that feeds
`mintedShares feeWei shareRate` into `handleOracleReport`.

1. Live conjunct: `observe` of the computed wrapper equals `sourceView`
   at that computed mint.
2. Mint conjunct: `sharesMinted` is the computed
   `mintedShares feeWei shareRate = feeWei * shareRate / E27` and
   `shareRateDelta` is the rate. The Pack E leftover
   (`sharesMinted = argument` for a free `sharesToMintAsFees`) is not
   this parent's conclusion.
3. Bound conjunct: under a named cap `maxShareRate` on the rate, the
   minted shares are bounded by the fee converted at the cap.

`submitReportData` remains out. P-ACCOUNT-1 stays order-only (cited
below, not widened). No second mint/cap ID is minted.
-/

namespace LidoSRv3.Audit.Guarantees.POracleSupply1

open LidoSRv3.Audit.SolidityAccounting
open LidoSRv3.Audit.Spec
open LidoSRv3.Audit.Spec.OracleMintCorrespondence

/-- Supplemental mint+cap parent. Abstract/source/verity-tx checked on the
computed `handleOracleReport` wrapper. ACCOUNT stays order-only. -/
def guarantee : Guarantee := ⟨.pOracleSupply1, [.model, .source, .verityTx]⟩

open LidoSRv3.Audit.Verity.HandleOracleReportTx

/-- Spec-only mint+cap lemma, retained so the original Pack N3 kill-lines
keep their exact parent shape. The registered YAML theorem is the live
strengthening below. -/
theorem oracle_supply_mint_and_cap
    (i : ReportInput) (feeWei shareRate maxShareRate : Nat)
    (hCap : shareRate ≤ maxShareRate) :
    ((specOfMint i feeWei shareRate).sharesMinted
        = mintedShares feeWei shareRate ∧
      (specOfMint i feeWei shareRate).shareRateDelta = shareRate) ∧
      (specOfMint i feeWei shareRate).sharesMinted
        ≤ feeWei * maxShareRate / E27 :=
  ⟨⟨rfl, rfl⟩, minted_shares_le_cap feeWei shareRate maxShareRate hCap⟩

/-- P-ORACLE-SUPPLY-1 parent. Universal over report input, `feeWei`,
`shareRate`, the named cap `maxShareRate`, and the entry `ContractState`.
Live conjunct: the computed wrapper's `observe` equals `sourceView` at
`mintedShares feeWei shareRate`. Spec conjuncts: the frame mint is that
computed conversion and is bounded under `shareRate ≤ maxShareRate`.
`submitReportData` is not this path. -/
theorem oracle_supply_live_computed_mint
    (i : ReportInput) (feeWei shareRate maxShareRate : Nat)
    (state : ContractState)
    (hCap : shareRate ≤ maxShareRate) :
    observe i ((handleOracleReportComputed i feeWei shareRate).run state) =
        sourceView i (mintedShares feeWei shareRate) ∧
      ((specOfMint i feeWei shareRate).sharesMinted
          = mintedShares feeWei shareRate ∧
        (specOfMint i feeWei shareRate).shareRateDelta = shareRate) ∧
      (specOfMint i feeWei shareRate).sharesMinted
          ≤ feeWei * maxShareRate / E27 :=
  ⟨computed_tx_simulates_computed_source i feeWei shareRate state,
    oracle_supply_mint_and_cap i feeWei shareRate maxShareRate hCap⟩

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
