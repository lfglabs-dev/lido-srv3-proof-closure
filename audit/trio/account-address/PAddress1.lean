import Std

/-!
Independent P-ADDRESS-1 source model for the four pinned entrypoints. Errors
are distinct and guards retain source order. Withdrawal request word 1 follows
`WithdrawalQueueBase.WithdrawalRequest`: address owner in bits 0..159,
timestamp in 160..199, claimed at bit 200, seven padding bits, and report
timestamp in 208..247. No earlier address model is imported.
-/

namespace AccountAddress.PAddress1

def two160 : Nat := 2 ^ 160
def two200 : Nat := 2 ^ 200
def two201 : Nat := 2 ^ 201

instance : NeZero two160 := ⟨by simp [two160]⟩

/-- Solidity `address`: exactly the values representable in 160 bits. -/
abbrev Address := Fin two160

def addressPart (word : Nat) : Nat := word % two160
def claimedPart (word : Nat) : Bool := (word / two200) % 2 = 1

/-- ABI-facing conversion rejects integers which are not Solidity addresses. -/
def addressOfNat? (value : Nat) : Option Address :=
  if h : value < two160 then some ⟨value, h⟩ else none

def storedOwner (word : Nat) : Address :=
  ⟨addressPart word, Nat.mod_lt _ (by simp [two160])⟩

/-- Packed assignment `request.owner = _to`; all bits at and above 160 stay. -/
def writeOwner (word : Nat) (owner : Address) : Nat :=
  (word / two160) * two160 + owner.val

/-- Checked boundary for callers starting with an untyped natural number. -/
def writeOwnerChecked (word owner : Nat) : Option Nat :=
  (addressOfNat? owner).map (writeOwner word)

/-- Packed assignment `request.claimed = true`; all fields other than bit 200
stay unchanged. -/
def setClaimed (word : Nat) : Nat :=
  (word / two201) * two201 + two200 + word % two200

inductive Error where
  | transferToZeroAddress
  | transferToThemselves
  | invalidRequestId (id : Nat)
  | requestAlreadyClaimed (id : Nat)
  | transferFromIncorrectOwner (supplied actual : Address)
  | notOwnerOrApproved (caller : Address)
  | queuePaused
  | requestAmountTooSmall (amount : Nat)
  | requestAmountTooLarge (amount : Nat)
  | tokenTransferFailed
  | queueArithmeticOverflow
  | zeroRecipient
  | arraysLengthMismatch (ids hints : Nat)
  | requestNotFoundOrNotFinalized (id : Nat)
  | notOwner (caller owner : Address)
  | invalidHint (hint : Nat)
  | lockedEtherUnderflow
  | etherTransferFailed
  | zeroUnwrap
  | insufficientWstETH
  | stETHTransferFailed
  deriving Repr, DecidableEq

inductive Result (State : Type) (Value : Type) where
  | reverted (error : Error) (rollback : State)
  | committed (post : State) (value : Value)
  deriving Repr, DecidableEq

structure TransferState where
  lastRequestId : Nat
  requestWord : Nat
  tokenApproval : Address
  ownerSetRemoveSucceeds : Bool
  ownerSetAddSucceeds : Bool
  deriving Repr, DecidableEq

structure TransferInput where
  caller : Address
  fromAddr : Address
  to : Address
  requestId : Nat
  approvedForAll : Bool
  deriving Repr, DecidableEq

/-- `transferFrom -> _transfer`, including the two source `assert`s. -/
def transferFrom (i : TransferInput) (before : TransferState) :
    Result TransferState Unit :=
  if i.to = 0 then .reverted .transferToZeroAddress before
  else if i.to = i.fromAddr then .reverted .transferToThemselves before
  else if i.requestId = 0 || i.requestId > before.lastRequestId then
    .reverted (.invalidRequestId i.requestId) before
  else if claimedPart before.requestWord then
    .reverted (.requestAlreadyClaimed i.requestId) before
  else if i.fromAddr != storedOwner before.requestWord then
    .reverted (.transferFromIncorrectOwner i.fromAddr
      (storedOwner before.requestWord)) before
  else if !(i.fromAddr = i.caller || i.approvedForAll ||
      before.tokenApproval = i.caller) then
    .reverted (.notOwnerOrApproved i.caller) before
  else if !before.ownerSetRemoveSucceeds || !before.ownerSetAddSucceeds then
    .reverted .queueArithmeticOverflow before
  else .committed (TransferState.mk before.lastRequestId
      (writeOwner before.requestWord i.to) 0 before.ownerSetRemoveSucceeds
      before.ownerSetAddSucceeds) ()

def minWithdrawalAmount : Nat := 100
def maxWithdrawalAmount : Nat := 1000 * 10 ^ 18
def two128 : Nat := 2 ^ 128
def two256 : Nat := 2 ^ 256

structure RequestState where
  lastRequestId : Nat
  cumulativeStETH : Nat
  cumulativeShares : Nat
  deriving Repr, DecidableEq

structure RequestInput where
  caller : Address
  owner : Address
  amount : Nat
  shares : Nat
  timestamp : Nat
  reportTimestamp : Nat
  resumed : Bool
  transferFromSucceeds : Bool
  ownerSetAddSucceeds : Bool
  deriving Repr, DecidableEq

structure NewRequest where
  id : Nat
  cumulativeStETH : Nat
  cumulativeShares : Nat
  owner : Address
  timestamp : Nat
  reportTimestamp : Nat
  deriving Repr, DecidableEq

/-- Single loop iteration of `requestWithdrawals`; owner-zero fallback occurs
before amount and external transfer checks, as in lines 129-138. Explicit
uint128 casts truncate before the checked cumulative additions. -/
def requestWithdrawal (i : RequestInput) (before : RequestState) :
    Result RequestState NewRequest :=
  if !i.resumed then .reverted .queuePaused before
  else if i.amount < minWithdrawalAmount then
    .reverted (.requestAmountTooSmall i.amount) before
  else if i.amount > maxWithdrawalAmount then
    .reverted (.requestAmountTooLarge i.amount) before
  else if !i.transferFromSucceeds then .reverted .tokenTransferFailed before
  else
    let amount128 := i.amount % two128
    let shares128 := i.shares % two128
    let cumulativeStETH := before.cumulativeStETH + amount128
    let cumulativeShares := before.cumulativeShares + shares128
    if cumulativeShares >= two128 || cumulativeStETH >= two128 then
      .reverted .queueArithmeticOverflow before
    else if before.lastRequestId + 1 >= two256 then
      .reverted .queueArithmeticOverflow before
    else if !i.ownerSetAddSucceeds then .reverted .queueArithmeticOverflow before
    else
      let owner := if i.owner = 0 then i.caller else i.owner
      let post := RequestState.mk (before.lastRequestId + 1)
        cumulativeStETH cumulativeShares
      .committed post (NewRequest.mk post.lastRequestId cumulativeStETH
        cumulativeShares owner (i.timestamp % (2 ^ 40))
        (i.reportTimestamp % (2 ^ 40)))

/-- The checked uint256 increment at WithdrawalQueueBase.sol:374 derives a
representable, strictly increasing request ID from every successful execution.
No request-ID width premise is supplied by the caller. This concerns the
supplementary source model, not physical storage or EVM refinement. -/
theorem requestWithdrawal_success_id (i : RequestInput) (before after : RequestState)
    (request : NewRequest) (h : requestWithdrawal i before = .committed after request) :
    request.id = before.lastRequestId + 1 ∧ after.lastRequestId = request.id ∧
      request.id < two256 ∧ before.lastRequestId < request.id := by
  unfold requestWithdrawal at h
  split at h <;> simp_all
  split at h <;> simp_all
  split at h <;> simp_all
  split at h <;> simp_all
  split at h <;> simp_all
  split at h <;> simp_all
  split at h <;> simp_all
  all_goals rcases h with ⟨rfl, rfl⟩
  all_goals simp_all


structure ClaimState where
  lastFinalizedRequestId : Nat
  requestWord : Nat
  lockedEther : Nat
  ownerSetRemoveSucceeds : Bool
  deriving Repr, DecidableEq

structure ClaimInput where
  caller : Address
  recipient : Address
  requestIds : List Nat
  hints : List Nat
  lastCheckpointIndex : Nat
  checkpointFrom : Nat
  nextCheckpointFrom : Nat
  claimableEther : Nat
  sendSucceeds : Bool
  deriving Repr, DecidableEq

/-- One `_claim` iteration after the public batch-length/zero-recipient guards. -/
def claimOne (i : ClaimInput) (id hint : Nat) (before : ClaimState) :
    Result ClaimState Nat :=
  if id = 0 then .reverted (.invalidRequestId id) before
  else if id > before.lastFinalizedRequestId then
    .reverted (.requestNotFoundOrNotFinalized id) before
  else if claimedPart before.requestWord then
    .reverted (.requestAlreadyClaimed id) before
  else if storedOwner before.requestWord != i.caller then
    .reverted (.notOwner i.caller (storedOwner before.requestWord)) before
  else if !before.ownerSetRemoveSucceeds then
    .reverted .queueArithmeticOverflow before
  else if hint = 0 || hint > i.lastCheckpointIndex || id < i.checkpointFrom ||
      (hint < i.lastCheckpointIndex && i.nextCheckpointFrom <= id) then
    .reverted (.invalidHint hint) before
  else if before.lockedEther < i.claimableEther then
    .reverted .lockedEtherUnderflow before
  else if !i.sendSucceeds then .reverted .etherTransferFailed before
  else .committed (ClaimState.mk before.lastFinalizedRequestId
      (setClaimed before.requestWord) (before.lockedEther - i.claimableEther)
      before.ownerSetRemoveSucceeds) i.claimableEther

/-- Bounded one-item projection of public `claimWithdrawalsTo`. It supports
the exact public prechecks and one `_claim` execution. Empty and multi-item
batches are explicitly outside this executor and use `arraysLengthMismatch`
as the model's unsupported-shape result; this is not attributed to Solidity. -/
def claimWithdrawalsTo (i : ClaimInput) (before : ClaimState) :
    Result ClaimState Nat :=
  if i.recipient = 0 then .reverted .zeroRecipient before
  else if i.requestIds.length != i.hints.length then
    .reverted (.arraysLengthMismatch i.requestIds.length i.hints.length) before
  else match i.requestIds, i.hints with
    | [id], [hint] => claimOne i id hint before
    | _, _ => .reverted (.arraysLengthMismatch i.requestIds.length i.hints.length) before

structure UnwrapState where
  wstBalance : Nat
  stEthBalance : Nat
  deriving Repr, DecidableEq

structure UnwrapInput where
  caller : Nat
  amount : Nat
  stEthQuote : Nat
  transferSucceeds : Bool
  deriving Repr, DecidableEq

/-- `WstETH.unwrap`: zero guard, pooled-ETH quote, burn, then stETH transfer.
Transfer failure rolls the burn back under EVM transaction semantics. -/
def unwrap (i : UnwrapInput) (before : UnwrapState) : Result UnwrapState Nat :=
  if i.amount = 0 then .reverted .zeroUnwrap before
  else if before.wstBalance < i.amount then .reverted .insufficientWstETH before
  else if !i.transferSucceeds then .reverted .stETHTransferFailed before
  else .committed (UnwrapState.mk (before.wstBalance - i.amount)
      (before.stEthBalance + i.stEthQuote)) i.stEthQuote

theorem addressPart_writeOwner (word : Nat) (owner : Address) :
    addressPart (writeOwner word owner) = owner.val := by
  have h := owner.isLt
  change owner.val < 1461501637330902918203684832716283019655932542976 at h
  simp [addressPart, writeOwner, two160, Nat.mod_eq_of_lt h]

theorem upper_writeOwner (word : Nat) (owner : Address) :
    writeOwner word owner / two160 = word / two160 := by
  have h := owner.isLt
  change owner.val < 1461501637330902918203684832716283019655932542976 at h
  simp only [writeOwner, two160]
  omega

theorem writeOwnerChecked_rejects_out_of_range (word owner : Nat)
    (h : two160 ≤ owner) : writeOwnerChecked word owner = none := by
  simp [writeOwnerChecked, addressOfNat?, Nat.not_lt.mpr h]

theorem setClaimed_preserves_owner (word : Nat) :
    addressPart (setClaimed word) = addressPart word := by
  unfold addressPart setClaimed two160 two200 two201
  omega

end AccountAddress.PAddress1
