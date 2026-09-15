import LidoSRv3.Audit.Source.DepositCorrespondence
import LidoSRv3.Audit.Guarantees.PDeposit1
import LidoSRv3.Audit.Verity.DepositParentTx
import LidoSRv3.Audit.Verity.DepositNFrameTx
import Verity.Core

/-!
# P-DEPOSIT-1 router-derived `firstAmount` / `publicKeysBatchLength`

Additive consumer beside the registered parents.  `PDeposit1.LinksSource`
and `PDeposit1.NFrame.LinksSource` remain explicit hypotheses on those
parents.  This module does **not** derive either link from ALLOC.  Wave 4
`alloc_derived_linkssource_kill_line_refutes_bridge` stays true: ALLOC
key counts do not constrain per-batch wei or the module's returned byte
length.

It derives the two fields ALLOC leaves free from the pinned
`StakingRouter.deposit` / `makeBeaconChainDeposits32ETH` path and then
obtains `LinksSource` from those router fields.

Pinned `lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`:

* `StakingRouter.sol:966` `if (publicKeysBatch.length % PUBKEY_LENGTH != 0)
  revert WrongPubkeyLength();`
* `StakingRouter.sol:967` `actualDepositsCount = publicKeysBatch.length /
  PUBKEY_LENGTH`
* `StakingRouter.sol:985-991` passes that count as `_keysCount`
* `BeaconChainDepositor.sol:43-45` `_publicKeysBatch.length ==
  PUBLIC_KEY_LENGTH * _keysCount`
* `BeaconChainDepositor.sol:53-63` / `:57` each key sends `DEPOSIT_SIZE`

The Spec router's per-allocation unit multiply stays explicit
(`derivedBatchAmount` = `loopPushed`).  The registered n-frame parent is
not edited.
-/

namespace LidoSRv3.Audit.Source.DepositLinksSource

open LidoSRv3.Audit.SolidityDeposit
open LidoSRv3.Audit.Guarantees.PDeposit1
open LidoSRv3.Audit.Verity.DepositParentTx
open _root_.Verity.Core

abbrev Word := Verity.Core.Uint256
abbrev modulus := Verity.Core.Uint256.modulus

/-! ## `publicKeysBatchLength` — StakingRouter.sol:966-967 + BCD:43-45 -/

/-- Fail-closed key count from the module's returned pubkey batch.
    `none` is `WrongPubkeyLength` (line 966), modulo-by-zero on
    `PUBKEY_LENGTH`, or `InvalidPublicKeysBatchLength` (BCD:43-45).
    Not an always-success stub: a free `Nat` length is not a key count. -/
def derivedKeys (cfg : SourceDepositConfig) (publicKeysBatchLength : Nat) :
    Option Nat :=
  if cfg.pubkeyLength = 0 then
    none
  else if publicKeysBatchLength % cfg.pubkeyLength ≠ 0 then
    none
  else if publicKeysBatchLength ≠
      cfg.publicKeyLength * (publicKeysBatchLength / cfg.pubkeyLength) then
    none
  else
    some (publicKeysBatchLength / cfg.pubkeyLength)

theorem derivedKeys_spec {cfg : SourceDepositConfig}
    {publicKeysBatchLength n : Nat}
    (h : derivedKeys cfg publicKeysBatchLength = some n) :
    cfg.pubkeyLength ≠ 0 ∧
      publicKeysBatchLength % cfg.pubkeyLength = 0 ∧
      n = publicKeysBatchLength / cfg.pubkeyLength ∧
      publicKeysBatchLength = cfg.publicKeyLength * n := by
  unfold derivedKeys at h
  by_cases hZero : cfg.pubkeyLength = 0
  · rw [if_pos hZero] at h; cases h
  rw [if_neg hZero] at h
  by_cases hMis : publicKeysBatchLength % cfg.pubkeyLength ≠ 0
  · rw [if_pos hMis] at h; cases h
  rw [if_neg hMis] at h
  by_cases hLen : publicKeysBatchLength ≠
      cfg.publicKeyLength * (publicKeysBatchLength / cfg.pubkeyLength)
  · rw [if_pos hLen] at h; cases h
  rw [if_neg hLen] at h
  have hn : n = publicKeysBatchLength / cfg.pubkeyLength := (Option.some.inj h).symm
  refine ⟨hZero, Decidable.of_not_not hMis, hn, ?_⟩
  rw [hn]
  exact Decidable.of_not_not hLen

theorem derivedKeys_eq_actual {cfg : SourceDepositConfig}
    {inp : SourceDepositInput} {n : Nat}
    (h : derivedKeys cfg inp.publicKeysBatchLength = some n) :
    n = actualDepositsCount cfg inp := by
  have ⟨_, _, hDiv, _⟩ := derivedKeys_spec h
  rw [hDiv, actualDepositsCount]

/-- StakingRouter.sol:966 misaligned batch is `none`, not a truncated
    key count. `actualDepositsCount` would still be `length / 48`. -/
theorem derivedKeys_misaligned {cfg : SourceDepositConfig}
    {publicKeysBatchLength : Nat}
    (hZero : cfg.pubkeyLength ≠ 0)
    (hMis : publicKeysBatchLength % cfg.pubkeyLength ≠ 0) :
    derivedKeys cfg publicKeysBatchLength = none := by
  unfold derivedKeys
  rw [if_neg hZero, if_pos hMis]

/-- BeaconChainDepositor.sol:43-45: length must equal
    `PUBLIC_KEY_LENGTH * keys`. -/
theorem derivedKeys_length_mismatch {cfg : SourceDepositConfig}
    {publicKeysBatchLength : Nat}
    (hZero : cfg.pubkeyLength ≠ 0)
    (hAligned : publicKeysBatchLength % cfg.pubkeyLength = 0)
    (hLen : publicKeysBatchLength ≠
      cfg.publicKeyLength * (publicKeysBatchLength / cfg.pubkeyLength)) :
    derivedKeys cfg publicKeysBatchLength = none := by
  unfold derivedKeys
  have hNotMis : ¬ (publicKeysBatchLength % cfg.pubkeyLength ≠ 0) :=
    fun hneq => hneq hAligned
  rw [if_neg hZero, if_neg hNotMis, if_pos hLen]

theorem derivedKeys_of_guards {cfg : SourceDepositConfig}
    {publicKeysBatchLength : Nat}
    (hZero : cfg.pubkeyLength ≠ 0)
    (hAligned : publicKeysBatchLength % cfg.pubkeyLength = 0)
    (hLen : publicKeysBatchLength =
      cfg.publicKeyLength * (publicKeysBatchLength / cfg.pubkeyLength)) :
    derivedKeys cfg publicKeysBatchLength =
      some (publicKeysBatchLength / cfg.pubkeyLength) := by
  unfold derivedKeys
  have hNotMis : ¬ (publicKeysBatchLength % cfg.pubkeyLength ≠ 0) :=
    fun hneq => hneq hAligned
  have hNotLen : ¬ (publicKeysBatchLength ≠
      cfg.publicKeyLength * (publicKeysBatchLength / cfg.pubkeyLength)) :=
    fun hneq => hneq hLen
  rw [if_neg hZero, if_neg hNotMis, if_neg hNotLen]

/-- The committed push (`StakingRouter.sol:980-996`) has already passed
    both pubkey-length guards, so `publicKeysBatchLength` determines the
    committed key count. -/
theorem committed_publicKeysBatchLength_guards
    {cfg : SourceDepositConfig} {inp : SourceDepositInput}
    {keys pulled pushed balanceAfter : Nat}
    (hRun : run cfg inp = .committedDeposits keys pulled pushed balanceAfter) :
    cfg.pubkeyLength ≠ 0 ∧
      inp.publicKeysBatchLength % cfg.pubkeyLength = 0 ∧
      inp.publicKeysBatchLength =
        cfg.publicKeyLength * actualDepositsCount cfg inp := by
  rw [run] at hRun
  by_cases hModule : inp.moduleActive = false
  · rw [if_pos hModule] at hRun; cases hRun
  rw [if_neg hModule] at hRun
  by_cases hMaxEB : cfg.maxEBType1 = 0
  · rw [if_pos hMaxEB] at hRun; cases hRun
  rw [if_neg hMaxEB] at hRun
  by_cases hMax : maxDepositsCount cfg inp = 0
  · rw [if_pos hMax] at hRun; cases hRun
  rw [if_neg hMax] at hRun
  by_cases hPubkeyZero : cfg.pubkeyLength = 0
  · rw [if_pos hPubkeyZero] at hRun; cases hRun
  rw [if_neg hPubkeyZero] at hRun
  by_cases hAligned : inp.publicKeysBatchLength % cfg.pubkeyLength ≠ 0
  · rw [if_pos hAligned] at hRun; cases hRun
  rw [if_neg hAligned] at hRun
  by_cases hOver : maxDepositsCount cfg inp < actualDepositsCount cfg inp
  · rw [if_pos hOver] at hRun; cases hRun
  rw [if_neg hOver] at hRun
  by_cases hKeys : actualDepositsCount cfg inp = 0
  · rw [if_pos hKeys] at hRun; cases hRun
  rw [if_neg hKeys] at hRun
  by_cases hCanDeposit : inp.lidoCanDeposit = false
  · rw [if_pos hCanDeposit] at hRun; cases hRun
  rw [if_neg hCanDeposit] at hRun
  by_cases hZeroAmount : depositsValue cfg inp = 0
  · rw [if_pos hZeroAmount] at hRun; cases hRun
  rw [if_neg hZeroAmount] at hRun
  by_cases hLiquidity : inp.lidoDepositableEther < depositsValue cfg inp
  · rw [if_pos hLiquidity] at hRun; cases hRun
  rw [if_neg hLiquidity] at hRun
  by_cases hPublicKeys :
      inp.publicKeysBatchLength ≠ cfg.publicKeyLength * actualDepositsCount cfg inp
  · rw [if_pos hPublicKeys] at hRun; cases hRun
  rw [if_neg hPublicKeys] at hRun
  exact ⟨hPubkeyZero, Decidable.of_not_not hAligned, Decidable.of_not_not hPublicKeys⟩

theorem committed_implies_derivedKeys
    {cfg : SourceDepositConfig} {inp : SourceDepositInput}
    {keys pulled pushed balanceAfter : Nat}
    (hRun : run cfg inp = .committedDeposits keys pulled pushed balanceAfter) :
    derivedKeys cfg inp.publicKeysBatchLength = some keys := by
  have ⟨hZero, hAligned, hLen⟩ := committed_publicKeysBatchLength_guards hRun
  have ⟨hKeysEq, _, _, _, _, _⟩ := committed_deposits_spec hRun
  have hDerived :=
    derivedKeys_of_guards (publicKeysBatchLength := inp.publicKeysBatchLength)
      hZero hAligned (by
        simpa [actualDepositsCount] using hLen)
  rw [hDerived, hKeysEq, actualDepositsCount]

/-! ## `firstAmount` — BeaconChainDepositor.sol:53-63 / :57 -/

/-- Per-batch wei the depositor loop sends for `keys` validators:
    `loopPushed` at `BeaconChainDepositor.sol:53-63`, one `DEPOSIT_SIZE`
    transfer per key at line 57.  This is the unit multiply ALLOC does
    not perform. -/
def derivedBatchAmount (cfg : SourceDepositConfig) (keys : Nat) : Nat :=
  loopPushed cfg keys

theorem derivedBatchAmount_eq (cfg : SourceDepositConfig) (keys : Nat) :
    derivedBatchAmount cfg keys = keys * cfg.depositSize :=
  loopPushed_eq cfg keys

/-- A Verity batch is router-shaped when its wei field is the depositor
    loop total, not a free `Nat`. -/
def routerShapedAmount (cfg : SourceDepositConfig) (batch : Batch) : Prop :=
  batch.amount.val = derivedBatchAmount cfg batch.keys.val

theorem routerShapedAmount_iff (cfg : SourceDepositConfig) (batch : Batch) :
    routerShapedAmount cfg batch ↔
      batch.amount.val = batch.keys.val * cfg.depositSize := by
  simp [routerShapedAmount, derivedBatchAmount_eq]

/-- On a committed push the observed wei is the depositor-loop amount
    for the committed key count — not a caller-supplied `firstAmount`. -/
theorem committed_pushed_is_derived_amount
    {cfg : SourceDepositConfig} {inp : SourceDepositInput}
    {keys pulled pushed balanceAfter : Nat}
    (hRun : run cfg inp = .committedDeposits keys pulled pushed balanceAfter) :
    pushed = derivedBatchAmount cfg keys := by
  have ⟨hKeysEq, _, _, hPushed, _, _⟩ := committed_deposits_spec hRun
  rw [hPushed, pushedValue, hKeysEq, derivedBatchAmount]

/-! ## `LinksSource` from router fields, not from ALLOC -/

theorem ofNat_val_of_lt {n : Nat} (h : n < modulus) :
    (Uint256.ofNat n).val = n := by
  simp [Uint256.val_ofNat, Nat.mod_eq_of_lt h]

/-- Two-batch `LinksSource` is a theorem of the router-derived key count
    and the depositor-loop wei, not of ALLOC premises. -/
theorem linksSource_of_router_fields
    (cfg : SourceDepositConfig) (inp : SourceDepositInput) (inputs : Inputs)
    (hSize : inputs.depositSize.val = cfg.depositSize)
    (hDerived : derivedKeys cfg inp.publicKeysBatchLength =
      some (inputs.first.keys.val + inputs.second.keys.val))
    (hFirst : routerShapedAmount cfg inputs.first)
    (hSecond : routerShapedAmount cfg inputs.second) :
    LinksSource cfg inp inputs where
  depositSize := hSize
  keys := derivedKeys_eq_actual hDerived
  firstAmount := by
    simpa [routerShapedAmount_iff] using hFirst
  secondAmount := by
    simpa [routerShapedAmount_iff] using hSecond

/-- Finite-list `NFrame.LinksSource` from the same two router fields.
    The registered parent still takes `NFrame.LinksSource` as a caller
    hypothesis; this consumer does not edit it. -/
theorem nframe_linksSource_of_router_fields
    (cfg : SourceDepositConfig) (inp : SourceDepositInput)
    (inputs : LidoSRv3.Audit.Verity.DepositNFrameTx.Inputs)
    (hSize : inputs.depositSize.val = cfg.depositSize)
    (hDerived : derivedKeys cfg inp.publicKeysBatchLength =
      some (LidoSRv3.Audit.Verity.DepositNFrameTx.exactKeys inputs.batches))
    (hAmounts : ∀ batch ∈ inputs.batches, routerShapedAmount cfg batch) :
    NFrame.LinksSource cfg inp inputs where
  depositSize := hSize
  keys := derivedKeys_eq_actual hDerived
  batchAmounts := by
    intro batch hMem
    simpa [routerShapedAmount_iff] using hAmounts batch hMem

/-! ## Fail-closed two-batch constructor -/

/-- Overwrite each leg's wei with the depositor-loop product.  `none`
    when `publicKeysBatchLength` does not determine the key sum, when
    `PUBKEY_LENGTH` is zero, when BCD:43-45 fails, or when a product
    leaves the word.  Template key counts stay caller-chosen (the
    2+3 split of one `deposit()` call is a Verity aggregation, not a
    Solidity parameter). -/
def derivedTwoBatchInputs (cfg : SourceDepositConfig) (inp : SourceDepositInput)
    (template : Inputs) : Option Inputs :=
  match derivedKeys cfg inp.publicKeysBatchLength with
  | none => none
  | some n =>
    if n ≠ template.first.keys.val + template.second.keys.val then
      none
    else if modulus ≤ cfg.depositSize then
      none
    else if modulus ≤ template.first.keys.val * cfg.depositSize then
      none
    else if modulus ≤ template.second.keys.val * cfg.depositSize then
      none
    else
      some
        { template with
          depositSize := Uint256.ofNat cfg.depositSize
          first :=
            { template.first with
              amount := Uint256.ofNat (template.first.keys.val * cfg.depositSize) }
          second :=
            { template.second with
              amount := Uint256.ofNat (template.second.keys.val * cfg.depositSize) } }

private theorem derivedTwoBatchInputs_spec
    {cfg : SourceDepositConfig} {inp : SourceDepositInput}
    {template inputs : Inputs}
    (h : derivedTwoBatchInputs cfg inp template = some inputs) :
    derivedKeys cfg inp.publicKeysBatchLength =
        some (template.first.keys.val + template.second.keys.val) ∧
      cfg.depositSize < modulus ∧
      template.first.keys.val * cfg.depositSize < modulus ∧
      template.second.keys.val * cfg.depositSize < modulus ∧
      inputs =
        { template with
          depositSize := Uint256.ofNat cfg.depositSize
          first :=
            { template.first with
              amount := Uint256.ofNat (template.first.keys.val * cfg.depositSize) }
          second :=
            { template.second with
              amount := Uint256.ofNat (template.second.keys.val * cfg.depositSize) } } := by
  unfold derivedTwoBatchInputs at h
  split at h
  · cases h
  next n hn =>
    by_cases hSum : n ≠ template.first.keys.val + template.second.keys.val
    · rw [if_pos hSum] at h; cases h
    rw [if_neg hSum] at h
    by_cases hSize : modulus ≤ cfg.depositSize
    · rw [if_pos hSize] at h; cases h
    rw [if_neg hSize] at h
    by_cases hFirst : modulus ≤ template.first.keys.val * cfg.depositSize
    · rw [if_pos hFirst] at h; cases h
    rw [if_neg hFirst] at h
    by_cases hSecond : modulus ≤ template.second.keys.val * cfg.depositSize
    · rw [if_pos hSecond] at h; cases h
    rw [if_neg hSecond] at h
    refine ⟨by
        rw [hn]
        exact (Decidable.of_not_not hSum).symm ▸ rfl, ?_, ?_, ?_, ?_⟩
    · exact Nat.not_le.mp hSize
    · exact Nat.not_le.mp hFirst
    · exact Nat.not_le.mp hSecond
    · exact (Option.some.inj h).symm

/-- The fail-closed constructor yields two-batch `LinksSource`. -/
theorem derivedTwoBatchInputs_linksSource
    {cfg : SourceDepositConfig} {inp : SourceDepositInput}
    {template inputs : Inputs}
    (h : derivedTwoBatchInputs cfg inp template = some inputs) :
    LinksSource cfg inp inputs := by
  obtain ⟨hDerived, hSize, hFirstW, hSecondW, hEq⟩ := derivedTwoBatchInputs_spec h
  subst hEq
  refine linksSource_of_router_fields cfg inp _ ?_ ?_ ?_ ?_
  · change (Uint256.ofNat cfg.depositSize).val = cfg.depositSize
    exact ofNat_val_of_lt hSize
  · simpa using hDerived
  · change (Uint256.ofNat (template.first.keys.val * cfg.depositSize)).val =
      derivedBatchAmount cfg template.first.keys.val
    rw [ofNat_val_of_lt hFirstW, derivedBatchAmount_eq]
  · change (Uint256.ofNat (template.second.keys.val * cfg.depositSize)).val =
      derivedBatchAmount cfg template.second.keys.val
    rw [ofNat_val_of_lt hSecondW, derivedBatchAmount_eq]

/-! ## ALLOC still does not constrain the two fields -/

/-- ALLOC-style key counts `2` and `3` do not force the depositor-loop
    wei.  Witness amount `65 ≠ 2 * 32`. -/
theorem alloc_key_counts_do_not_constrain_firstAmount :
    ¬ (∀ inputs : Inputs,
        inputs.first.keys.val = 2 →
          inputs.second.keys.val = 3 →
            routerShapedAmount canonicalSourceConfig inputs.first) := by
  intro h
  have hShaped :=
    h { canonicalInputs with first := { batchA with amount := 65 } }
      (by decide) (by decide)
  exact absurd (routerShapedAmount_iff canonicalSourceConfig _ |>.mp hShaped)
    (by decide)

/-- Matching `actualDepositsCount` (the ALLOC composition premise) does
    not force a well-formed `publicKeysBatchLength`.  Length `241`
    truncates to 5 keys (`241 / 48 = 5`) but fails line 966. -/
theorem alloc_matching_count_does_not_constrain_publicKeysBatchLength :
    ¬ (∀ inp : SourceDepositInput,
        actualDepositsCount canonicalSourceConfig inp = 5 →
          derivedKeys canonicalSourceConfig inp.publicKeysBatchLength = some 5) := by
  intro h
  have hDerived :=
    h { canonicalSourceInput with publicKeysBatchLength := 241 } (by decide)
  change derivedKeys canonicalSourceConfig 241 = some 5 at hDerived
  have hNone : derivedKeys canonicalSourceConfig 241 = none := by
    decide
  rw [hNone] at hDerived
  cases hDerived

end LidoSRv3.Audit.Source.DepositLinksSource
