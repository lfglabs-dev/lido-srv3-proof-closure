import LidoSRv3.Audit.Spec.OracleMintCorrespondence
import LidoSRv3.Audit.Verity.SubmitReportEntryTx
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

Node P3 discharges the previously named OPEN "`submitReportData` split
remains out": `oracle_supply_submit_report_data_computed_entry` below is
the new parent conjunct over the modeled entry
(`AccountingOracle.submitReportData` → `_handleConsensusReportData` →
`Accounting.handleOracleReport` / `_simulateOracleReport` /
`_calculateProtocolFees`), which *computes* `entryFeeWei` /
`entryShareRate` from report data and entry state and feeds that pair into
the existing wrapper — no free `sharesToMintAsFees` argument at the entry.

P-ACCOUNT-1 stays order-only (cited below, not widened). No second
mint/cap ID is minted.
-/

namespace LidoSRv3.Audit.Guarantees.POracleSupply1

open _root_.Verity
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

/-- P-ORACLE-SUPPLY-1 wrapper parent. Universal over report input, `feeWei`,
`shareRate`, the named cap `maxShareRate`, and the entry `ContractState`.
Live conjunct: the computed wrapper's `observe` equals `sourceView` at
`mintedShares feeWei shareRate`. Spec conjuncts: the frame mint is that
computed conversion and is bounded under `shareRate ≤ maxShareRate`.
The modeled `submitReportData` entry that computes this pair is the
registered parent `oracle_supply_submit_report_data_computed_entry`
below; this wrapper theorem is the mint path it feeds. -/
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

open LidoSRv3.Audit.SolidityAccounting.SubmitReportEntry
open LidoSRv3.Audit.Verity.SubmitReportEntryTx

/-- P-ORACLE-SUPPLY-1 entry parent (node P3): the modeled
`submitReportData` entry computes the fee/shareRate pair and feeds it into
the already-proved computed wrapper.  Universal over the report datum `d`
(report vector, consensus-hash words, sender gate, pre-state snapshot,
report values, smoothened rebase terms, and fee parameters), the named cap
`maxShareRate`, and the entry `ContractState`, under exactly the premises
the entry checks (`senderAllowed`, `consensusHashMatches`) plus the named
cap on the computed rate:

1. the entry run *is* the `handleOracleReportComputed` run at
   `entryFeeWei d` / `entryShareRate d` — the mint is computed from the
   report data; the entry signature has no free `sharesToMintAsFees`;
2. that path has the observables of the pinned source view at
   `mintedShares (entryFeeWei d) (entryShareRate d)` — the mint path
   already proved by `oracle_supply_live_computed_mint`, instantiated at
   the entry-computed pair;
3. the computed mint never exceeds the pinned
   `_calculateTotalProtocolFeeShares` division
   `feeEther * internalShares / (postInternalEther - feeEther)`
   (`E27` quantization only shrinks it; exact under divisibility via
   `entry_mint_eq_pinned_of_exact`);
4. the computed mint respects the named cap at the computed fee.

This discharges the named OPEN "`submitReportData` split remains out"
without splitting the ID: same row, same wrapper, same kill-line family. -/
theorem oracle_supply_submit_report_data_computed_entry
    (d : SubmitReportData) (maxShareRate : Nat) (state : ContractState)
    (hSender : senderAllowed d = true)
    (hHash : consensusHashMatches d = true)
    (hCap : entryShareRate d ≤ maxShareRate) :
    (submitReportDataTx d).run state =
        (handleOracleReportComputed d.report (entryFeeWei d)
          (entryShareRate d)).run state ∧
      observe d.report ((submitReportDataTx d).run state) =
        sourceView d.report
          (mintedShares (entryFeeWei d) (entryShareRate d)) ∧
      mintedShares (entryFeeWei d) (entryShareRate d)
          ≤ pinnedSharesToMintAsFees d ∧
      mintedShares (entryFeeWei d) (entryShareRate d)
          ≤ entryFeeWei d * maxShareRate / E27 :=
  ⟨entry_is_computed_wrapper d state hSender hHash,
    entry_observe_simulates_source_at_computed_mint d state hSender hHash,
    entry_mint_le_pinned_shares d,
    minted_shares_le_cap (entryFeeWei d) (entryShareRate d) maxShareRate hCap⟩

/-- Source-domain strengthened entry parent: under `EntryDomainValid` the
existing four conjuncts hold AND, when the E27 scaling divides exactly, the
computed-pair mint *equals* the pinned `_calculateTotalProtocolFeeShares`
formula — upgrading the third conjunct from `≤` to `=`.  The
`0 < feeShareRateDenominator` prerequisite of `entry_mint_eq_pinned_of_exact`
is absorbed: domain validity gives it when the fee is positive, and when the
fee is zero both sides are trivially zero.

`EntryDomainValid` captures the Solidity checked-arithmetic non-underflow
conditions at `af095e48`; see the source module for the pinned source-span
mapping.  uint256 overflow on intermediate products remains unmodeled. -/
theorem oracle_supply_entry_source_domain
    (d : SubmitReportData) (maxShareRate : Nat) (state : ContractState)
    (hSender : senderAllowed d = true)
    (hHash : consensusHashMatches d = true)
    (hCap : entryShareRate d ≤ maxShareRate)
    (hDom : EntryDomainValid d)
    (hExact : feeShareRateDenominator d ∣ internalSharesBeforeFees d * E27)
    (hDiv : feeShareRateDenominator d
      ∣ entryFeeWei d * internalSharesBeforeFees d) :
    (submitReportDataTx d).run state =
        (handleOracleReportComputed d.report (entryFeeWei d)
          (entryShareRate d)).run state ∧
      observe d.report ((submitReportDataTx d).run state) =
        sourceView d.report
          (mintedShares (entryFeeWei d) (entryShareRate d)) ∧
      mintedShares (entryFeeWei d) (entryShareRate d)
          ≤ pinnedSharesToMintAsFees d ∧
      mintedShares (entryFeeWei d) (entryShareRate d)
          ≤ entryFeeWei d * maxShareRate / E27 ∧
      mintedShares (entryFeeWei d) (entryShareRate d)
          = pinnedSharesToMintAsFees d :=
  let base := oracle_supply_submit_report_data_computed_entry
    d maxShareRate state hSender hHash hCap
  ⟨base.1, base.2.1, base.2.2.1, base.2.2.2,
    entry_mint_eq_pinned_of_domain d hDom hExact hDiv⟩

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
