import LidoSRv3.Audit.Guarantees.POracleSupply1
import LidoSRv3.Audit.Verity.HandleOracleReportTx

/-!
# Node 3 fail-closed vectors

Parent-shaped negations for P-ORACLE-SUPPLY-1. Spec mutants keep every
premise of `oracle_supply_mint_and_cap` (including the
`shareRate ≤ maxShareRate` cap). The live mutant keeps every premise of
`oracle_supply_live_computed_mint` and substitutes a free
`sharesToMintAsFees` argument for the computed mint.

1. `specOfMintSumBalances`: `sharesMinted` is `sum balances`
   (the Pack E vector).
2. `specOfMintRawFee`: `sharesMinted` is raw `feeWei * shareRate`
   without the `/ E27` normalization.
3. `handleOracleReportStillFree`: live path still takes a free mint
   argument, so `observe` need not equal `sourceView` at
   `mintedShares feeWei shareRate`.
-/

namespace LidoSRv3.Tests.PackN3OracleMintMutants

open _root_.Verity
open LidoSRv3.Audit.SolidityAccounting
open LidoSRv3.Audit.Spec
open LidoSRv3.Audit.Spec.OracleMintCorrespondence
open LidoSRv3.Audit.Guarantees
open LidoSRv3.Audit.Verity.HandleOracleReportTx

private def report : ReportInput :=
  { registeredModuleIds := [1, 2]
    reportedModuleIds := [1, 2]
    balancesGwei := [10, 20] }

/-- Mutant frame: `sharesMinted` is the balance sum, not the fee/shareRate
mint. -/
def specOfMintSumBalances (i : ReportInput) (_feeWei shareRate : Nat) :
    OracleFrame where
  balances := i.balancesGwei
  sharesMinted := i.balancesGwei.sum
  shareRateDelta := shareRate

/-- Mutant mint: raw fee-times-rate with the `E27` normalization dropped. -/
def mintedSharesRaw (feeWei shareRate : Nat) : Nat :=
  feeWei * shareRate

/-- Mutant frame built from the raw mint. -/
def specOfMintRawFee (i : ReportInput) (feeWei shareRate : Nat) :
    OracleFrame where
  balances := i.balancesGwei
  sharesMinted := mintedSharesRaw feeWei shareRate
  shareRateDelta := shareRate

/-- Kill-line 1: the sum-balances mutant does not satisfy the parent shape.
Premises retained (`shareRate ≤ maxShareRate` binder kept). On balances
`[10, 20]` with `feeWei = 0`, `shareRate = maxShareRate = 0`, the mutant
mints `30` while the parent demands both `mintedShares 0 0 = 0` and the cap
bound `≤ 0`. -/
theorem sum_balances_mutant_killed :
    ¬ ∀ (i : ReportInput) (feeWei shareRate maxShareRate : Nat),
        shareRate ≤ maxShareRate →
        (((specOfMintSumBalances i feeWei shareRate).sharesMinted
            = mintedShares feeWei shareRate ∧
          (specOfMintSumBalances i feeWei shareRate).shareRateDelta
            = shareRate) ∧
          (specOfMintSumBalances i feeWei shareRate).sharesMinted
            ≤ feeWei * maxShareRate / E27) := by
  intro h
  exact absurd ((h report 0 0 0 (Nat.le_refl 0)).2) (by decide)

/-- Kill-line 2: the raw-fee mutant does not satisfy the parent shape.
Premises retained. With `feeWei = shareRate = maxShareRate = 1`, the raw
mutant mints `1` while `mintedShares 1 1 = 1 / E27 = 0`, refuting the mint
conjunct. -/
theorem raw_fee_mutant_killed :
    ¬ ∀ (i : ReportInput) (feeWei shareRate maxShareRate : Nat),
        shareRate ≤ maxShareRate →
        (((specOfMintRawFee i feeWei shareRate).sharesMinted
            = mintedShares feeWei shareRate ∧
          (specOfMintRawFee i feeWei shareRate).shareRateDelta = shareRate) ∧
          (specOfMintRawFee i feeWei shareRate).sharesMinted
            ≤ feeWei * maxShareRate / E27) := by
  intro h
  exact absurd ((h report 1 1 1 (Nat.le_refl 1)).1.1) (by decide)

/-- Kill-line 2b: the raw-fee mutant also breaches the aggregate cap bound
(second conjunct) on the same vector, so both conjuncts independently refute
it. -/
theorem raw_fee_mutant_breaches_cap :
    ¬ ((specOfMintRawFee report 1 1).sharesMinted ≤ 1 * 1 / E27) := by
  decide

/-- Cap-drop vector for the bound conjunct: without the retained premise
`shareRate ≤ maxShareRate`, the bound conclusion is false even for the
honest frame (`shareRate = E27`, `maxShareRate = 0`), so the cap premise is
load-bearing rather than decorative. -/
theorem cap_premise_is_load_bearing :
    ¬ ∀ (i : ReportInput) (feeWei shareRate maxShareRate : Nat),
        (specOfMint i feeWei shareRate).sharesMinted
          ≤ feeWei * maxShareRate / E27 := by
  intro h
  exact absurd (h report 1 E27 0) (by decide)

/-- Positive control: the honest frame satisfies the Spec mint+cap shape on a
concrete vector, via the Spec lemma. -/
theorem honest_frame_passes_vector :
    (((specOfMint report 7 3).sharesMinted = mintedShares 7 3 ∧
      (specOfMint report 7 3).shareRateDelta = 3) ∧
      (specOfMint report 7 3).sharesMinted ≤ 7 * 5 / E27) :=
  POracleSupply1.oracle_supply_mint_and_cap report 7 3 5 (by decide)

/-- Mutant live path: mint shares remain a free argument, ignoring
`feeWei` / `shareRate`. -/
def handleOracleReportStillFree (i : ReportInput) (_feeWei _shareRate : Nat)
    (sharesToMintAsFees : Nat) : Contract Result :=
  handleOracleReport i sharesToMintAsFees

/-- Kill-line 3: a free mint argument does not satisfy the live parent
shape. Premises retained (`shareRate ≤ maxShareRate`). On the Pack N3
report with `feeWei = shareRate = maxShareRate = 1`, the computed mint
is `0`, so `sourceView` has no `.rewardsMinted` step, while feeding the
free argument `1` journals that step. -/
theorem free_argument_does_not_satisfy_computed_observe :
    ¬ ∀ (i : ReportInput) (feeWei shareRate maxShareRate : Nat)
        (state : ContractState),
        shareRate ≤ maxShareRate →
        observe i ((handleOracleReportStillFree i feeWei shareRate
            feeWei).run state) =
          sourceView i (mintedShares feeWei shareRate) := by
  intro h
  have hEq := h report 1 1 1 defaultState (Nat.le_refl 1)
  have hLeft :
      observe report ((handleOracleReportStillFree report 1 1 1).run
          defaultState) =
        sourceView report 1 :=
    verity_tx_simulates_pinned_source report 1 defaultState
  have hMint : mintedShares 1 1 = 0 := by decide
  rw [hLeft, hMint] at hEq
  have hAcc : accept report = some ⟨[1, 2], [10, 20], 30⟩ := by decide
  have hHas : .rewardsMinted ∈ (sourceView report 1).steps := by
    simp [sourceView, hAcc, successfulSteps]
  have hNone : .rewardsMinted ∉ (sourceView report 0).steps := by
    simp [sourceView, hAcc, successfulSteps]
  exact hNone (hEq ▸ hHas)

/-- Positive control: the computed live parent holds on the same vector. -/
theorem honest_computed_path_passes_vector :
    observe report ((handleOracleReportComputed report 7 3).run defaultState) =
        sourceView report (mintedShares 7 3) ∧
      ((specOfMint report 7 3).sharesMinted = mintedShares 7 3 ∧
        (specOfMint report 7 3).shareRateDelta = 3) ∧
      (specOfMint report 7 3).sharesMinted ≤ 7 * 5 / E27 :=
  POracleSupply1.oracle_supply_live_computed_mint
    report 7 3 5 defaultState (by decide)

end LidoSRv3.Tests.PackN3OracleMintMutants
