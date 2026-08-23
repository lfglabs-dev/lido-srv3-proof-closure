import LidoSRv3.Audit.Spec.OracleMintCorrespondence

/-!
# Node P3: pinned `submitReportData` fee / share-rate computation

Natural-number source semantics for the fee pipeline of the pinned oracle
entry `AccountingOracle.submitReportData` → `_handleConsensusReportData` →
`Accounting.handleOracleReport` → `_simulateOracleReport` →
`_calculateProtocolFees` → `_calculateTotalProtocolFeeShares` at
`lidofinance/core@af095e48bbc1c3841c2c9936219c8461af01056b`.

The entry *computes* the fee/share-rate pair from report data and entry
state.  `entryFeeWei` is the pinned LIP-12-guarded
`totalRewards * totalFee / precisionPoints`; `entryShareRate` is the
`E27`-scaled shares-per-ether rate
`internalSharesBeforeFees * E27 / (postInternalEther - feeEther)` of the same
"share rate that takes fees into account" division the pinned
`_calculateTotalProtocolFeeShares` performs.  Feeding that pair into
`handleOracleReportComputed` yields
`mintedShares feeWei shareRate = feeWei * shareRate / E27`, which
under-approximates the pinned
`feeEther * internalShares / (postInternalEther - feeEther)` by at most the
`E27` quantization remainder (`entry_mint_le_pinned_shares`) and equals it
exactly whenever the rate divides exactly (`entry_mint_eq_pinned_of_exact`).

Honesty boundary:

* `dataHash` / `consensusHash` are opaque words standing for
  `keccak256(abi.encode(data))` and the last consensus hash; no keccak is
  claimed.  Contract-version, consensus-version, ref-slot, and deadline
  checks are not modeled.
* `withdrawalsVaultTransfer`, `elRewardsVaultTransfer`, `totalSharesToBurn`,
  and `etherToFinalizeWQ` are the outputs of the sanity checker's
  `smoothenTokenRebase` and the withdrawal queue's `prefinalize`; they enter
  as report-data fields, not as modeled external executions.  Bad-debt
  internalization terms are out.
* `Nat` subtraction truncates where the pinned checked arithmetic would
  revert; the profitability guard mirrors the pinned
  `unifiedClBalance > principalClBalance` branch (LIP-12).
-/

namespace LidoSRv3.Audit.SolidityAccounting.SubmitReportEntry

open LidoSRv3.Audit.Spec.OracleMintCorrespondence

/-- Report data plus the entry state the pinned fee pipeline reads.  The
router vector is the existing `ReportInput` shape; the remaining fields are
the pinned `PreReportState` snapshot, the `ReportValues` the oracle entry
forwards, the smoothened rebase/withdrawal terms (taken as inputs, see the
module docstring), and the `getStakingRewardsDistribution` fee parameters.
There is deliberately no `sharesToMintAsFees` field: the mint is computed
below, never supplied. -/
structure SubmitReportData where
  report : ReportInput
  /-- Stand-in word for `keccak256(abi.encode(data))`. -/
  dataHash : Nat
  /-- Stand-in word for the last hash reported by the hash consensus. -/
  consensusHash : Nat
  /-- `_checkMsgSenderIsAllowedToSubmitData`: consensus member or
  `SUBMIT_DATA_ROLE`. -/
  senderIsMemberOrHasRole : Bool
  preTotalPooledEther : Nat
  preExternalEther : Nat
  preTotalShares : Nat
  preExternalShares : Nat
  preClValidatorsBalance : Nat
  preClPendingBalance : Nat
  depositedBalance : Nat
  clValidatorsBalance : Nat
  clPendingBalance : Nat
  withdrawalsVaultTransfer : Nat
  elRewardsVaultTransfer : Nat
  totalSharesToBurn : Nat
  etherToFinalizeWQ : Nat
  totalFee : Nat
  precisionPoints : Nat
  deriving Repr, DecidableEq

/-- `_checkConsensusData`: the submitted data hash equals the consensus
hash.  Opaque word equality, not keccak. -/
def consensusHashMatches (d : SubmitReportData) : Bool :=
  d.dataHash == d.consensusHash

/-- `_checkMsgSenderIsAllowedToSubmitData` outcome. -/
def senderAllowed (d : SubmitReportData) : Bool :=
  d.senderIsMemberOrHasRole

/-- Pinned `update.principalClBalance = pre.clValidatorsBalance +
pre.clPendingBalance + pre.depositedBalance`. -/
def principalClBalance (d : SubmitReportData) : Nat :=
  d.preClValidatorsBalance + d.preClPendingBalance + d.depositedBalance

/-- Pinned `unifiedClBalance = report.clValidatorsBalance +
report.clPendingBalance + update.withdrawalsVaultTransfer`. -/
def unifiedClBalance (d : SubmitReportData) : Nat :=
  d.clValidatorsBalance + d.clPendingBalance + d.withdrawalsVaultTransfer

/-- Pinned internal ether before the report:
`pre.totalPooledEther - pre.externalEther`. -/
def internalEtherBefore (d : SubmitReportData) : Nat :=
  d.preTotalPooledEther - d.preExternalEther

/-- Pinned `postInternalSharesBeforeFees = pre.totalShares -
pre.externalShares - update.totalSharesToBurn`. -/
def internalSharesBeforeFees (d : SubmitReportData) : Nat :=
  d.preTotalShares - d.preExternalShares - d.totalSharesToBurn

/-- Pinned `update.postInternalEther`: internal ether before, plus the
unified CL balance and EL rewards transfer, minus the principal CL balance
and the ether locked for withdrawal finalization. -/
def postInternalEther (d : SubmitReportData) : Nat :=
  internalEtherBefore d + unifiedClBalance d - principalClBalance d
    + d.elRewardsVaultTransfer - d.etherToFinalizeWQ

/-- Pinned `totalRewards = unifiedClBalance - update.principalClBalance +
update.elRewardsVaultTransfer` on the profitable branch. -/
def totalRewards (d : SubmitReportData) : Nat :=
  unifiedClBalance d - principalClBalance d + d.elRewardsVaultTransfer

/-- Pinned LIP-12-guarded `feeEther = totalRewards * totalFee /
precisionPoints`: zero on the non-profitable report
(`unifiedClBalance ≤ principalClBalance`), where the pinned branch mints
and distributes nothing. -/
def feeEther (d : SubmitReportData) : Nat :=
  if principalClBalance d < unifiedClBalance d then
    totalRewards d * d.totalFee / d.precisionPoints
  else 0

/-- The fee the modeled entry computes and feeds forward, in wei. -/
def entryFeeWei (d : SubmitReportData) : Nat := feeEther d

/-- The pinned mint denominator `update.postInternalEther - feeEther`: the
post-report internal ether with the fee taken as an ether deduction. -/
def feeShareRateDenominator (d : SubmitReportData) : Nat :=
  postInternalEther d - feeEther d

/-- The share rate the modeled entry computes: the `E27`-scaled
shares-per-ether rate `internalSharesBeforeFees * E27 / (postInternalEther -
feeEther)` — the "share rate that takes fees into account" of the pinned
`_calculateTotalProtocolFeeShares` division, in the wei-to-shares
orientation `mintedShares` consumes. -/
def entryShareRate (d : SubmitReportData) : Nat :=
  internalSharesBeforeFees d * E27 / feeShareRateDenominator d

/-- Pinned `sharesToMintAsFees = (feeEther * _internalSharesBeforeFees) /
(_update.postInternalEther - feeEther)`.  On the non-profitable branch
`feeEther = 0`, so this is `0` exactly as the pinned code leaves it. -/
def pinnedSharesToMintAsFees (d : SubmitReportData) : Nat :=
  feeEther d * internalSharesBeforeFees d / feeShareRateDenominator d

/-- LIP-12: a non-profitable report computes a zero fee. -/
theorem fee_zero_of_nonprofitable (d : SubmitReportData)
    (h : unifiedClBalance d ≤ principalClBalance d) :
    entryFeeWei d = 0 := by
  simp [entryFeeWei, feeEther, Nat.not_lt.mpr h]

/-- LIP-12 at the mint: a non-profitable report mints nothing through the
computed pair. -/
theorem entry_mint_zero_of_nonprofitable (d : SubmitReportData)
    (h : unifiedClBalance d ≤ principalClBalance d) :
    mintedShares (entryFeeWei d) (entryShareRate d) = 0 := by
  simp [mintedShares, fee_zero_of_nonprofitable d h]

/-- `E27`-quantization bound: converting a fee through the truncated
`E27`-scaled rate `num * E27 / den` never exceeds the direct `feeWei * num /
den` division.  This is what ties the wrapper mint to the pinned
`_calculateTotalProtocolFeeShares` formula without an exactness premise. -/
theorem minted_shares_quantized_le (feeWei num den : Nat) :
    mintedShares feeWei (num * E27 / den) ≤ feeWei * num / den := by
  by_cases hden : den = 0
  · subst hden
    simp [mintedShares]
  · have hpos : 0 < den := Nat.pos_of_ne_zero hden
    have h1 : feeWei * (num * E27 / den) * den ≤ feeWei * num * E27 := by
      calc feeWei * (num * E27 / den) * den
          = feeWei * (num * E27 / den * den) := by rw [Nat.mul_assoc]
        _ ≤ feeWei * (num * E27) :=
            Nat.mul_le_mul_left feeWei (Nat.div_mul_le_self _ _)
        _ = feeWei * num * E27 := by rw [Nat.mul_assoc]
    have h2 : feeWei * (num * E27 / den) ≤ feeWei * num * E27 / den :=
      (Nat.le_div_iff_mul_le hpos).mpr h1
    have h3 : mintedShares feeWei (num * E27 / den)
        ≤ feeWei * num * E27 / den / E27 :=
      Nat.div_le_div_right h2
    have h4 : feeWei * num * E27 / den / E27 = feeWei * num / den := by
      rw [Nat.div_div_eq_div_mul, Nat.mul_comm den E27,
        ← Nat.div_div_eq_div_mul, Nat.mul_div_cancel _ e27_pos]
    exact h4 ▸ h3

/-- The computed-pair mint never exceeds the pinned
`_calculateTotalProtocolFeeShares` mint: no over-mint relative to the pinned
source formula, for every report datum. -/
theorem entry_mint_le_pinned_shares (d : SubmitReportData) :
    mintedShares (entryFeeWei d) (entryShareRate d)
      ≤ pinnedSharesToMintAsFees d :=
  minted_shares_quantized_le (entryFeeWei d) (internalSharesBeforeFees d)
    (feeShareRateDenominator d)

/-- Exactness child: whenever the `E27`-scaled rate divides exactly, the
computed-pair mint *equals* the pinned mint.  Reuses the existing
`minted_shares_exact_ratio` with `num := internalSharesBeforeFees`,
`den := postInternalEther - feeEther`. -/
theorem entry_mint_eq_pinned_of_exact (d : SubmitReportData)
    (hpos : 0 < feeShareRateDenominator d)
    (hExact : feeShareRateDenominator d ∣ internalSharesBeforeFees d * E27)
    (hDiv : feeShareRateDenominator d
      ∣ entryFeeWei d * internalSharesBeforeFees d) :
    mintedShares (entryFeeWei d) (entryShareRate d)
      = pinnedSharesToMintAsFees d :=
  minted_shares_exact_ratio (entryFeeWei d) (internalSharesBeforeFees d)
    (feeShareRateDenominator d) hpos hExact hDiv

end LidoSRv3.Audit.SolidityAccounting.SubmitReportEntry
