import LidoSRv3.Audit.Source.AddressCorrespondence
import Contracts.Common

/-!
# P-ADDRESS-1 live claim-batch transaction slice

This module models the pinned
`WithdrawalQueue.claimWithdrawalsTo(uint256[],uint256[],address)` loop at
`lidofinance/core@af095e48bbc1c3841c2c9936219c8461af01056b`.

The unstructured-storage constants are the exact keccak positions from
`WithdrawalQueueBase.sol`. `ContractState.mapUint` is used as Verity's keyed
mapping abstraction: the two consecutive words of each Solidity mapping value
are represented by channels at `POSITION` and `POSITION + 1`. This does not
claim a keccak/machine-storage refinement. Within the second request word, the
owner, timestamp, claimed byte, and report timestamp use the pinned Solidity
packing exactly.

The transaction checks the parallel-array lengths, iterates every request,
reads the current and previous cumulative request words and checkpoint words,
sets the packed claimed byte, decrements locked ETH, and executes a real
value-bearing empty-calldata `externalCallBindTo` frame to the recipient.
Consequently the payout destination, value, order, and rollback boundary are
execution-derived. EnumerableSet removal and events remain outside this slice.
-/

namespace LidoSRv3.Audit.Verity.AddressClaimBatchTx

open _root_.Verity
open _root_.Verity.EVM.Uint256
open Contracts

def queuePosition : Nat :=
  0xe21b95c4eb1b99fd548b219e3b5c175a8efb31f910cb76456b20e14eba8cfe43
def checkpointsPosition : Nat :=
  0x445f3cbbc114a35d080f2a1953516d74e74d5106860bc2317840ba265f03b51a
def lastFinalizedRequestIdPosition : Nat :=
  0x992f2e0c24ce59a21f2dab8bba13b25c2f872129df7f4d45372155e717db0c48
def lastCheckpointIndexPosition : Nat :=
  0x9d8be19d6a54e40bd767aa61b0f462241f5562ef6967d7045485bccac825b240
def lockedEtherAmountPosition : Nat :=
  0x0e27eaa2e71c8572ab988fef0b54cd45bbd1740de1e22343fb6cda7536edc12f

def E27 : Nat := 1000000000000000000000000000

def requestAmountsWord (state : ContractState) (requestId : Nat) : Uint256 :=
  state.readMapUint queuePosition (.ofNat requestId)

def requestMetadataWord (state : ContractState) (requestId : Nat) : Uint256 :=
  state.readMapUint (queuePosition + 1) (.ofNat requestId)

def checkpointFromWord (state : ContractState) (hint : Nat) : Uint256 :=
  state.readMapUint checkpointsPosition (.ofNat hint)

def checkpointRateWord (state : ContractState) (hint : Nat) : Uint256 :=
  state.readMapUint (checkpointsPosition + 1) (.ofNat hint)

def cumulativeStETH (word : Uint256) : Nat := word.val % 2 ^ 128
def cumulativeShares (word : Uint256) : Nat := word.val / 2 ^ 128 % 2 ^ 128
def requestOwner (word : Uint256) : Address := Core.Address.ofNat (word.val % 2 ^ 160)
def requestClaimed (word : Uint256) : Bool := word.val / 2 ^ 200 % 256 != 0

def packAmounts (stETH shares : Nat) : Uint256 :=
  .ofNat (stETH + shares * 2 ^ 128)

def packMetadata (owner : Address) (timestamp : Nat) (claimed : Bool)
    (reportTimestamp : Nat) : Uint256 :=
  .ofNat (owner.toNat + timestamp * 2 ^ 160 +
    (if claimed then 1 else 0) * 2 ^ 200 + reportTimestamp * 2 ^ 208)

def markClaimed (word : Uint256) : Uint256 := .ofNat (word.val + 2 ^ 200)

structure RequestRead where
  requestId : Nat
  hint : Nat
  owner : Address
  claimed : Bool
  cumulativeStETH : Nat
  cumulativeShares : Nat
  previousCumulativeStETH : Nat
  previousCumulativeShares : Nat
  checkpointFrom : Nat
  checkpointMaxShareRate : Nat
  deriving DecidableEq, Repr

/-- Storage-backed request/checkpoint read used by each loop iteration. -/
def readRequest (state : ContractState) (requestId hint : Nat) : RequestRead :=
  let current := requestAmountsWord state requestId
  let previous := requestAmountsWord state (requestId - 1)
  let metadata := requestMetadataWord state requestId
  { requestId := requestId
    hint := hint
    owner := requestOwner metadata
    claimed := requestClaimed metadata
    cumulativeStETH := cumulativeStETH current
    cumulativeShares := cumulativeShares current
    previousCumulativeStETH := cumulativeStETH previous
    previousCumulativeShares := cumulativeShares previous
    checkpointFrom := (checkpointFromWord state hint).val
    checkpointMaxShareRate := (checkpointRateWord state hint).val }

/-- Pinned `_calcBatch` and checkpoint discount arithmetic, after its monotonic
storage premises have been checked. -/
def claimableEther (request : RequestRead) : Option Nat :=
  let eth := request.cumulativeStETH - request.previousCumulativeStETH
  let shares := request.cumulativeShares - request.previousCumulativeShares
  if shares = 0 then none
  else
    let batchShareRate := eth * E27 / shares
    some (if batchShareRate > request.checkpointMaxShareRate
      then shares * request.checkpointMaxShareRate / E27 else eth)

/-- One pinned `_claim` iteration. The packed claimed write and locked-ETH
decrement occur before the real payout frame, so `Contract.run` must roll both
back if the frame cannot pay. -/
def claimOne (requestId hint : Nat) (recipient : Address) : Contract Unit := fun state =>
  let sender := state.sender
  let request := readRequest state requestId hint
  let lastFinalized := (state.readSlot lastFinalizedRequestIdPosition).val
  let lastCheckpoint := (state.readSlot lastCheckpointIndexPosition).val
  let nextCheckpointFrom := (checkpointFromWord state (hint + 1)).val
  if requestId = 0 then .revert "InvalidRequestId" state
  else if requestId > lastFinalized then .revert "RequestNotFoundOrNotFinalized" state
  else if request.claimed then .revert "RequestAlreadyClaimed" state
  else if request.owner != sender then .revert "NotOwner" state
  else if hint = 0 || hint > lastCheckpoint then .revert "InvalidHint" state
  else if requestId < request.checkpointFrom then .revert "InvalidHint" state
  else if hint < lastCheckpoint && nextCheckpointFrom ≤ requestId then
    .revert "InvalidHint" state
  else if request.previousCumulativeStETH > request.cumulativeStETH ||
      request.previousCumulativeShares > request.cumulativeShares then
    .revert "NonMonotonicRequest" state
  else match claimableEther request with
    | none => .revert "ZeroShares" state
    | some payout =>
        let locked := (state.readSlot lockedEtherAmountPosition).val
        if payout > locked then .revert "LockedEtherUnderflow" state
        else
          let dirty :=
            (state.writeMapUint (queuePosition + 1) (.ofNat requestId)
              (markClaimed (requestMetadataWord state requestId))).writeSlot
                lockedEtherAmountPosition (.ofNat (locked - payout))
          externalCallBindTo recipient (.ofNat payout) []
            "WithdrawalQueue._sendValue" ([] : List Uint256) dirty

def claimLoop : List Nat → List Nat → Address → Contract Unit
  | [], [], _ => Verity.pure ()
  | requestId :: requestIds, hint :: hints, recipient => do
      claimOne requestId hint recipient
      claimLoop requestIds hints recipient
  | _, _, _ => fun state => .revert "ArraysLengthMismatch" state

/-- The live external entrypoint shape: zero-recipient rejection precedes the
parallel-array check and loop, exactly as in pinned `claimWithdrawalsTo`. -/
def executeClaimWithdrawalsTo (requestIds hints : List Nat) (recipient : Address) :
    Contract Unit := do
  require (recipient != zeroAddress) "ZeroRecipient"
  require (requestIds.length == hints.length) "ArraysLengthMismatch"
  claimLoop requestIds hints recipient

inductive Status where | committed | reverted deriving DecidableEq, Repr

structure View where
  status : Status
  claimed : List Bool
  lockedEther : Nat
  calls : List ExternalCall
  deriving DecidableEq, Repr

def observe (requestIds : List Nat) : ContractResult Unit → View
  | .success _ after =>
      ⟨.committed, requestIds.map (requestClaimed ∘ requestMetadataWord after),
        (after.readSlot lockedEtherAmountPosition).val, after.calls⟩
  | .revert _ _ => ⟨.reverted, [], 0, []⟩

def payoutEntry (recipient : Address) (amount : Nat) : ExternalCall :=
  linkedCallEntryTo "WithdrawalQueue._sendValue" recipient (.ofNat amount) []

def twoClaimState : ContractState :=
  let state := { defaultState with sender := (1 : Address), selfBalance := .ofNat 70 }
  let state := state.writeSlot lastFinalizedRequestIdPosition 2
  let state := state.writeSlot lastCheckpointIndexPosition 1
  let state := state.writeSlot lockedEtherAmountPosition 70
  let state := state.writeMapUint queuePosition 0 (packAmounts 0 0)
  let state := state.writeMapUint queuePosition 1 (packAmounts 30 30)
  let state := state.writeMapUint queuePosition 2 (packAmounts 70 70)
  let state := state.writeMapUint (queuePosition + 1) 1
    (packMetadata (1 : Address) 100 false 90)
  let state := state.writeMapUint (queuePosition + 1) 2
    (packMetadata (1 : Address) 101 false 90)
  let state := state.writeMapUint checkpointsPosition 1 1
  state.writeMapUint (checkpointsPosition + 1) 1 (.ofNat E27)

/-- Concrete executable correspondence/observe receipt for a two-item live
batch. Both packed request words are read and marked, the locked scalar reaches
zero, and two payout CALLs are journaled in loop order. -/
theorem two_claim_batch_observe :
    observe [1, 2]
        ((executeClaimWithdrawalsTo [1, 2] [1, 1] (2 : Address)).run twoClaimState) =
      ⟨.committed, [true, true], 0,
        [payoutEntry (2 : Address) 30, payoutEntry (2 : Address) 40]⟩ := by
  native_decide

/-- The transaction boundary restores the entry snapshot after any failed
guard or payout frame, including failures reached during later iterations. -/
theorem every_revert_restores_snapshot (requestIds hints : List Nat) (recipient : Address)
    (state rollback : ContractState) (reason : String)
    (h : (executeClaimWithdrawalsTo requestIds hints recipient).run state =
      .revert reason rollback) : rollback = state := by
  unfold Contract.run at h
  split at h <;> simp_all

end LidoSRv3.Audit.Verity.AddressClaimBatchTx
