import LidoSRv3.Audit.Source.AddressCorrespondence
import Compiler.Proofs.MappingSlot
import Contracts.Common

/-!
# P-ADDRESS-1 live claim-batch transaction slice

This module models the pinned
`WithdrawalQueue.claimWithdrawalsTo(uint256[],uint256[],address)` loop at
`lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`.

The unstructured-storage constants are the exact keccak positions from
`WithdrawalQueueBase.sol`. `ContractState.mapUint` is the live keyed
channel: `POSITION` / `POSITION + 1` hold the two consecutive words of
each mapping value. Those channels inhabit the physical keccak slots
`mappingSlotLocation POSITION key 0 = keccak256(abi.encode(key, POSITION))`
and `mappingSlotLocation POSITION key 1` (the next word), not the
unstructured constant plus a raw channel offset and not a second map at
`POSITION + 1`. The named correspondence is
`LidoSRv3.Audit.Spec.AddressClaimKeccakSlots.PhysicalClaimSlots`.
Within the second request word, the owner, timestamp, claimed byte, and
report timestamp use the pinned Solidity packing exactly.

The transaction checks the parallel-array lengths, iterates every request,
reads the current and previous cumulative request words and checkpoint words,
and sets the packed claimed byte and locked-ETH scalar.  The recipient CALL is
executed exactly once by `AddressRecipientCallBridge`, against its callee
world; it is deliberately not duplicated here by a stub-side CALL journal.
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
def requestsByOwnerPosition : Nat :=
  0x4b9bfe0774f05ab288bd50bd23f74ae80a797f1d0c82d419d43ebda4fdc2fe1f

/-- The `EnumerableSet.UintSet` stored at `_requestsByOwner[owner]` has its
array length at the outer mapping value, its array cells at `keccak(length
slot) + i`, and its `_indexes` mapping at the next struct word.  Keeping
these three locations separate is important: `remove` swaps a real array cell
and fixes the moved member's index before deleting the removed index. -/
def ownerRequestSetBase (owner : Address) : Nat :=
  Compiler.Proofs.mappingSlotLocation requestsByOwnerPosition owner.toNat 0
def ownerRequestValuesLengthSlot (owner : Address) : Nat := ownerRequestSetBase owner
def ownerRequestValueSlot (owner : Address) (index : Nat) : Nat :=
  Compiler.Proofs.mappingSlotLocation (ownerRequestSetBase owner) index 0
def ownerRequestIndexSlot (owner : Address) (requestId : Nat) : Nat :=
  Compiler.Proofs.mappingSlotLocation (ownerRequestSetBase owner + 1) requestId 0

/-- Executable lenses for the set's three disjoint components. The key is a
pair encoding only within an array/index component; unlike the old model it
cannot turn `remove` into a single membership-map zeroing operation. -/
def ownerRequestValuesPosition : Nat := requestsByOwnerPosition + 1
def ownerRequestIndexesPosition : Nat := requestsByOwnerPosition + 2
def ownerRequestCellKey (owner : Address) (index : Nat) : Uint256 :=
  .ofNat (owner.toNat * 2 ^ 128 + index)

def ownerRequestValuesLength (state : ContractState) (owner : Address) : Nat :=
  (state.readMapUint requestsByOwnerPosition (.ofNat owner.toNat)).val
def ownerRequestValue (state : ContractState) (owner : Address) (index : Nat) : Nat :=
  (state.readMapUint ownerRequestValuesPosition (ownerRequestCellKey owner index)).val
def ownerRequestIndex (state : ContractState) (owner : Address) (requestId : Nat) : Nat :=
  (state.readMapUint ownerRequestIndexesPosition (ownerRequestCellKey owner requestId)).val

/-- OpenZeppelin `EnumerableSet.remove`, including its swap-and-pop writes.
`none` is the source `assert(remove(...))` failure, not a synthetic
membership guard. -/
def removeOwnerRequest (state : ContractState) (owner : Address) (requestId : Nat) :
    Option ContractState :=
  let indexPlusOne := ownerRequestIndex state owner requestId
  if indexPlusOne = 0 then none
  else
    let lastIndex := ownerRequestValuesLength state owner - 1
    let toDeleteIndex := indexPlusOne - 1
    let lastValue := ownerRequestValue state owner lastIndex
    let after := ((state.writeMapUint ownerRequestValuesPosition
      (ownerRequestCellKey owner toDeleteIndex) (.ofNat lastValue)).writeMapUint
        ownerRequestIndexesPosition (ownerRequestCellKey owner lastValue)
          (.ofNat (toDeleteIndex + 1))).writeMapUint requestsByOwnerPosition
            (.ofNat owner.toNat) (.ofNat lastIndex)
    some (after.writeMapUint ownerRequestIndexesPosition (ownerRequestCellKey owner requestId) 0)

def insertOwnerRequest (state : ContractState) (owner : Address) (requestId : Nat) :
    Option ContractState :=
  if ownerRequestIndex state owner requestId != 0 then none
  else
    let index := ownerRequestValuesLength state owner
    let after := (state.writeMapUint ownerRequestValuesPosition
      (ownerRequestCellKey owner index) (.ofNat requestId)).writeMapUint
        ownerRequestIndexesPosition (ownerRequestCellKey owner requestId) (.ofNat (index + 1))
    some (after.writeMapUint requestsByOwnerPosition (.ofNat owner.toNat) (.ofNat (index + 1)))

/-- Physical keccak slot of `queue[requestId]` word 0:
`keccak256(abi.encode(requestId, queuePosition))`. -/
def queueAmountsPhysicalSlot (requestId : Nat) : Nat :=
  Compiler.Proofs.mappingSlotLocation queuePosition requestId 0

/-- Physical keccak slot of `queue[requestId]` word 1: the next word after
`keccak256(abi.encode(requestId, queuePosition))`. -/
def queueMetadataPhysicalSlot (requestId : Nat) : Nat :=
  Compiler.Proofs.mappingSlotLocation queuePosition requestId 1

/-- Physical keccak slot of `checkpoints[hint]` word 0. -/
def checkpointFromPhysicalSlot (hint : Nat) : Nat :=
  Compiler.Proofs.mappingSlotLocation checkpointsPosition hint 0

/-- Physical keccak slot of `checkpoints[hint]` word 1. -/
def checkpointRatePhysicalSlot (hint : Nat) : Nat :=
  Compiler.Proofs.mappingSlotLocation checkpointsPosition hint 1

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

/-- One pinned `_claim` storage iteration.  It returns the exact payout for the
following live recipient CALL; it does not issue a second synthetic CALL. -/
def claimOne (requestId hint : Nat) (_recipient : Address) : Contract Nat := fun state =>
  let sender := state.sender
  let request := readRequest state requestId hint
  let lastFinalized := (state.readSlot lastFinalizedRequestIdPosition).val
  let lastCheckpoint := (state.readSlot lastCheckpointIndexPosition).val
  let nextCheckpointFrom := (checkpointFromWord state (hint + 1)).val
  if requestId = 0 then .revert "InvalidRequestId" state
  else if requestId > lastFinalized then .revert "RequestNotFoundOrNotFinalized" state
  else if request.claimed then .revert "RequestAlreadyClaimed" state
  else if request.owner != sender then .revert "NotOwner" state
  else
    -- Solidity marks the packed byte and then executes
    -- `assert(_requestsByOwner[owner].remove(requestId))`; hint calculation
    -- follows that mutation. A later failure is rolled back by the entry frame.
    let marked := state.writeMapUint (queuePosition + 1) (.ofNat requestId)
      (markClaimed (requestMetadataWord state requestId))
    match removeOwnerRequest marked request.owner requestId with
    | none => .revert "Panic(0x01)" state
    | some removed =>
      if hint = 0 || hint > lastCheckpoint then .revert "InvalidHint" state
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
          let dirty := removed.writeSlot lockedEtherAmountPosition (.ofNat (locked - payout))
          .success payout dirty

def claimLoop : List Nat → List Nat → Address → Contract Unit
  | [], [], _ => Verity.pure ()
  | requestId :: requestIds, hint :: hints, recipient => do
      let _ ← claimOne requestId hint recipient
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
  let state := match insertOwnerRequest state (1 : Address) 1 with
    | some after => after | none => state
  let state := match insertOwnerRequest state (1 : Address) 2 with
    | some after => after | none => state
  let state := state.writeMapUint checkpointsPosition 1 1
  state.writeMapUint (checkpointsPosition + 1) 1 (.ofNat E27)

/-- Concrete storage receipt for a two-item live batch.  The actual recipient
CALLs are represented by the live-world bridge, not a duplicate stub journal. -/
theorem two_claim_batch_observe :
    observe [1, 2]
        ((executeClaimWithdrawalsTo [1, 2] [1, 1] (2 : Address)).run twoClaimState) =
      ⟨.committed, [true, true], 0, []⟩ := by
  decide +kernel

/-- The transaction boundary restores the entry snapshot after any failed
guard or payout frame, including failures reached during later iterations. -/
theorem every_revert_restores_snapshot (requestIds hints : List Nat) (recipient : Address)
    (state rollback : ContractState) (reason : String)
    (h : (executeClaimWithdrawalsTo requestIds hints recipient).run state =
      .revert reason rollback) : rollback = state := by
  unfold Contract.run at h
  split at h <;> simp_all

end LidoSRv3.Audit.Verity.AddressClaimBatchTx
