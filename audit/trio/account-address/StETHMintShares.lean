import ReportWriteFee

/-!
# StETH `mintShares` physical consumer

Pinned to `lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`:
`Lido.sol:894-900` and `StETH.sol:68,92-98,518-527,559-571`.

This is deliberately an ACCOUNT-only continuation of `ReportWriteFee`: a
mint quantity is obtained only from an already committed
`calculateProtocolFees` result.  The model does not manufacture a second fee
arithmetic error or assume anything about the subsequent router callback.
`shares` is a conventional Solidity mapping (slot 17/18 are not asserted to
be Lido storage); the total-share word is the pinned unstructured slot.
-/

namespace AccountAddress.StETHMintShares

open AccountAddress.ReportWriteFee

def two128 : Nat := 2 ^ 128
def uint256Max : Nat := two256 - 1
def uint128Max : Nat := two128 - 1

/-- `keccak256("lido.StETH.totalAndExternalShares")`, StETH.sol:92-93. -/
def totalSharesPosition : Nat :=
  0x6038150aecaa250d524370a0fdcdec13f2690e0723eaf277f41d7cae26b359e6

/-- Lido.sol:130-132, whose low/high uint128 fields are buffered ether and
deposited post-report ether respectively. -/
def bufferedEtherAndDepositedPostReportPosition : Nat :=
  0x81a11fa1111afa59b50051f60ccf604a39d96acb484dc467ad8eadb4a63f0a5f

/-- Lido.sol:143-145, whose low/high uint128 fields are CL validator and
pending balances respectively. -/
def clValidatorsAndPendingPosition : Nat :=
  0x096e465397f38e659238ccd5d5a2c434ced54a63fd8d694045bfb058ab9d8112

/-- The conventional `mapping(address => uint256) shares` at StETH.sol:68.
The key derivation is intentionally not claimed here; it is a mapping, not a
pair of invented sequential storage slots. -/
abbrev Shares := Nat → Nat

structure State where
  /-- StETH's own physical storage. The total/external packed word is read
  only at `totalSharesPosition`; `shares` remains a Solidity mapping below. -/
  storage : Core
  shares : Shares
  accounting : Nat
  steth : Nat
  stopped : Bool

inductive Error where
  | notAccounting
  | stopped
  | mintToZeroAddr
  | mintToStethContract
  | safeMathAddOverflow
  | sharesOverflow
  | sharesTooLargeForEvent
  | zeroShareRateDenominator
  deriving Repr, DecidableEq

inductive Event where
  | transfer (sender recipient amount : Nat)
  | transferShares (sender recipient shares : Nat)
  deriving Repr, DecidableEq

inductive Outcome where
  | reverted (error : Error) (rollback : State)
  | committed (post : State) (events : List Event)

/-- StETH's `_getTotalShares`: low 128 bits only (StETH.sol:473-475). -/
def totalAndExternalShares (s : State) : StorageWord :=
  s.storage.read totalSharesPosition

def totalShares (s : State) : Nat := (totalAndExternalShares s).val % two128

/-- The external-share payload in the high half is not token total shares. -/
def externalShares (s : State) : Nat := (totalAndExternalShares s).val / two128

private def low128 (word : StorageWord) : Nat := word.val % two128
private def high128 (word : StorageWord) : Nat := word.val / two128

/-- Lido.sol:1271-1277.  Unlike the raw arithmetic in the event conversion,
these four additions are Solidity 0.4 AragonSafeMath additions over values
read from their two packed storage words. -/
def getInternalEther (s : State) : Except Error Nat :=
  let bufferedDeposited := s.storage.read bufferedEtherAndDepositedPostReportPosition
  let clBalances := s.storage.read clValidatorsAndPendingPosition
  let buffered := low128 bufferedDeposited
  let deposited := high128 bufferedDeposited
  let validators := low128 clBalances
  let pending := high128 clBalances
  if uint256Max < buffered + validators then .error .safeMathAddOverflow
  else if uint256Max < buffered + validators + pending then .error .safeMathAddOverflow
  else if uint256Max < buffered + validators + pending + deposited then .error .safeMathAddOverflow
  else .ok (buffered + validators + pending + deposited)

/-- `UnstructuredStorageExt.setLowUint128`: replace only the low half. -/
def setLowUint128 (word : StorageWord) (value : Nat) : StorageWord :=
  ⟨(word.val / two128) * two128 + value % two128, by
    have hpow : two256 = two128 * two128 := by decide
    have hhigh : word.val / two128 < two128 := by
      apply Nat.div_lt_of_lt_mul
      simpa [hpow, Nat.mul_comm] using word.isLt
    have hval : value % two128 < two128 := Nat.mod_lt _ (by decide)
    have : (word.val / two128) * two128 + value % two128 < two128 * two128 := by
      calc
        (word.val / two128) * two128 + value % two128 <
            (word.val / two128) * two128 + two128 := Nat.add_lt_add_left hval _
        _ = (word.val / two128 + 1) * two128 := by simp [Nat.succ_mul]
        _ ≤ two128 * two128 := Nat.mul_le_mul_right _ (Nat.succ_le_iff.mpr hhigh)
    simpa [hpow] using this⟩

/-! `StETH.getPooledEthByShares` (329-334) calls virtual share-rate helpers.
For Lido, the source override is `internalEther / (totalShares -
externalShares)` (Lido.sol:1298-1309), not `totalPooledEther / totalShares`.
The multiplication and subtraction use Solidity 0.4's raw `uint256`
operators, not AragonSafeMath; they therefore wrap at 256 bits.
-/
def rawUint256Mul (a b : Nat) : Nat := (a * b) % two256
def rawUint256Sub (a b : Nat) : Nat := (a + two256 - b) % two256

def pooledEthByShares (s : State) (amount : Nat) : Except Error Nat :=
  if amount ≥ uint128Max then .error .sharesTooLargeForEvent
  else
    let denominator := rawUint256Sub (totalShares s) (externalShares s)
    if denominator = 0 then .error .zeroShareRateDenominator
    else
      match getInternalEther s with
      | .error e => .error e
      | .ok internalEther => .ok (rawUint256Mul amount internalEther / denominator)

/-- StETH.sol:518-527.  The `newTotalShares & UINT128_HIGH_MASK == 0`
check is represented by `newTotal < 2^128`; the high half of the existing
unstructured word is retained by `setLowUint128`. -/
def mintShares (caller recipient amount : Nat) (before : State) : Outcome :=
  if caller != before.accounting then .reverted .notAccounting before
  else if before.stopped then .reverted .stopped before
  else if recipient = 0 then .reverted .mintToZeroAddr before
  else if recipient = before.steth then .reverted .mintToStethContract before
  -- `_getTotalShares().add(_sharesAmount)`, before the high-half check.
  else if totalShares before + amount > uint256Max then .reverted .safeMathAddOverflow before
  else if totalShares before + amount ≥ two128 then .reverted .sharesOverflow before
  -- `shares[_recipient].add(_sharesAmount)`, after the packed low-half write.
  else if before.shares recipient + amount > uint256Max then
    .reverted .safeMathAddOverflow before
  else
    let post := { before with
      storage := before.storage.write totalSharesPosition
        (setLowUint128 (totalAndExternalShares before)
        (totalShares before + amount)
        )
      shares := fun account => if account = recipient then before.shares account + amount
        else before.shares account }
    -- Lido.sol:899 invokes this only after `_mintShares` (898), so the
    -- conversion observes the updated packed total and recipient mapping.
    match pooledEthByShares post amount with
    | .error e => .reverted e before
    | .ok pooled =>
      .committed post [.transfer 0 recipient pooled, .transferShares 0 recipient amount]

/-- The `Accounting.sol:403-407` bridge: only a successful getter/fee product
can furnish the amount that is passed to `LIDO.mintShares(address(this), ...)`.
No post-state or independently proposed mint amount is accepted.  The
strict-positive guard is source code, too: a committed zero fee does not call
`mintShares` and emits no mint events. -/
def mintCommittedFee (L : Layout) (registeredIds : List Nat) (core : Core)
    (report : ReportWei) (before : State) : Option Outcome :=
  match calculateProtocolFees L registeredIds core report with
  | .error _ => none
  | .ok fee =>
      if 0 < fee.sharesToMintAsFees then
        some (mintShares before.accounting before.accounting fee.sharesToMintAsFees before)
      else some (.committed before [])

theorem totalShares_setLowUint128 (word : StorageWord) (value : Nat) (h : value < two128) :
    (setLowUint128 word value).val % two128 = value := by
  simp [setLowUint128, Nat.mod_eq_of_lt h]

theorem externalShares_setLowUint128 (word : StorageWord) (value : Nat) :
    (setLowUint128 word value).val / two128 = word.val / two128 := by
  rw [show (setLowUint128 word value).val =
    (word.val / two128) * two128 + value % two128 by rfl]
  rw [Nat.add_div]
  simp [Nat.mod_lt _ (by decide)]

theorem every_revert_restores_snapshot (caller recipient amount : Nat) (before rollback : State)
    (e : Error) (h : mintShares caller recipient amount before = .reverted e rollback) :
    rollback = before := by
  unfold mintShares at h
  split at h <;> simp_all
  split at h <;> simp_all
  split at h <;> simp_all
  split at h <;> simp_all
  split at h <;> simp_all
  split at h <;> simp_all
  cases hPooled : pooledEthByShares before amount <;> simp [hPooled] at h

theorem committed_mint_has_paired_events (caller recipient amount : Nat) (before post : State)
    (events : List Event)
    (h : mintShares caller recipient amount before = .committed post events) :
    ∃ pooled, events = [.transfer 0 recipient pooled, .transferShares 0 recipient amount] := by
  unfold mintShares at h
  split at h <;> try simp_all
  split at h <;> try simp_all
  split at h <;> try simp_all
  split at h <;> try simp_all
  split at h <;> try simp_all
  split at h <;> try simp_all
  split at h <;> try simp_all
  next pooled hpooled => exact ⟨pooled, by simpa using h.2⟩

end AccountAddress.StETHMintShares
