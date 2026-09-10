import LidoSRv3.Audit.Source.AddressCorrespondence
import Compiler.Proofs.MappingSlot
import Compiler.Proofs.Storage.StructArrayStorage
import Contracts.Common

/-!
# P-ADDRESS-1 live claim-batch transaction slice

This module models the pinned
`WithdrawalQueue.claimWithdrawalsTo(uint256[],uint256[],address)` loop at
`lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`.

The unstructured-storage constants are the exact keccak positions from
`WithdrawalQueueBase.sol`.  The executable readers and writers use the
physical Solidity words directly: `mappingSlotLocation POSITION key 0 =
keccak256(abi.encode(key, POSITION))` and `mappingSlotLocation POSITION key
1` (the next word).  There is no parallel `mapUint` compatibility channel in
the live path.
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
  EvmYul.fromByteArrayBigEndian
    (Compiler.Proofs.Storage.storageArrayElementPointer (ownerRequestSetBase owner) index)
def ownerRequestIndexSlot (owner : Address) (requestId : Nat) : Nat :=
  -- `_indexes` is the second `EnumerableSet.Set` member.  Its mapping base
  -- is `keccak256(abi.encode(owner, requestsByOwnerPosition)) + 1`, before
  -- hashing `requestId`; adding one after a nested-map hash addresses a
  -- different word entirely.
  Compiler.Proofs.mappingSlotLocation (ownerRequestSetBase owner + 1) requestId 0

/-- Executable lenses for the actual `EnumerableSet.UintSet` layout.  The
outer owner mapping, its dynamic values array, and its `_indexes` mapping are
addressed by their Solidity keccak slots. -/

def ownerRequestValuesLength (state : ContractState) (owner : Address) : Nat :=
  (state.readSlot (ownerRequestValuesLengthSlot owner)).val
def ownerRequestValue (state : ContractState) (owner : Address) (index : Nat) : Nat :=
  (state.readSlot (ownerRequestValueSlot owner index)).val
def ownerRequestIndex (state : ContractState) (owner : Address) (requestId : Nat) : Nat :=
  (state.readSlot (ownerRequestIndexSlot owner requestId)).val

/-- OZ 4.4.1 remove, including checked subtraction/indexing and pop.
Errors retain their source panic category; absence is the caller's failed assert.
The post-swap length is read again for pop rather than assumed unchanged. -/
def removeOwnerRequestChecked (state : ContractState) (owner : Address) (requestId : Nat) :
    Except String ContractState :=
  let valueIndex := ownerRequestIndex state owner requestId
  if valueIndex = 0 then .error "Panic(0x01)"
  else
    let length := ownerRequestValuesLength state owner
    if length = 0 then .error "Panic(0x11)"
    else
      let lastIndex := length - 1
      let toDeleteIndex := valueIndex - 1
      let swapped : Except String ContractState := if toDeleteIndex != lastIndex then
        if toDeleteIndex ≥ length then .error "Panic(0x32)"
        else
          let lastValue := ownerRequestValue state owner lastIndex
          .ok ((state.writeSlot (ownerRequestValueSlot owner toDeleteIndex)
            (.ofNat lastValue)).writeSlot (ownerRequestIndexSlot owner lastValue)
              (.ofNat valueIndex))
        else .ok state
      match swapped with
      | .error reason => .error reason
      | .ok swapped =>
        let popLength := ownerRequestValuesLength swapped owner
        if popLength = 0 then .error "Panic(0x31)"
        else
          let after := (swapped.writeSlot (ownerRequestValueSlot owner (popLength - 1)) 0).writeSlot
            (ownerRequestValuesLengthSlot owner) (.ofNat (popLength - 1))
          .ok (after.writeSlot (ownerRequestIndexSlot owner requestId) 0)

/-- Compatibility projection for the legacy storage-only witnesses. The live
claim consumes the error-preserving checked execution directly. -/
def removeOwnerRequest (state : ContractState) (owner : Address) (requestId : Nat) :
    Option ContractState :=
  (removeOwnerRequestChecked state owner requestId).toOption

def insertOwnerRequest (state : ContractState) (owner : Address) (requestId : Nat) :
    Option ContractState :=
  if ownerRequestIndex state owner requestId != 0 then none
  else
    let index := ownerRequestValuesLength state owner
    let after := (state.writeSlot (ownerRequestValueSlot owner index) (.ofNat requestId)).writeSlot
      (ownerRequestIndexSlot owner requestId) (.ofNat (index + 1))
    some (after.writeSlot (ownerRequestValuesLengthSlot owner) (.ofNat (index + 1)))

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
  state.readSlot (queueAmountsPhysicalSlot requestId)

def requestMetadataWord (state : ContractState) (requestId : Nat) : Uint256 :=
  state.readSlot (queueMetadataPhysicalSlot requestId)

def checkpointFromWord (state : ContractState) (hint : Nat) : Uint256 :=
  state.readSlot (checkpointFromPhysicalSlot hint)

def checkpointRateWord (state : ContractState) (hint : Nat) : Uint256 :=
  state.readSlot (checkpointRatePhysicalSlot hint)

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
def prepareClaim (requestId hint : Nat) (_recipient : Address) : Contract Nat := fun state =>
  if requestId = 0 then .revert "InvalidRequestId" state
  else if requestId > (state.readSlot lastFinalizedRequestIdPosition).val then
    .revert "RequestNotFoundOrNotFinalized" state
  else
    let metadata := requestMetadataWord state requestId
    if requestClaimed metadata then .revert "RequestAlreadyClaimed" state
    else if requestOwner metadata != state.sender then .revert "NotOwner" state
    else
      let marked := state.writeSlot (queueMetadataPhysicalSlot requestId) (markClaimed metadata)
      match removeOwnerRequestChecked marked
          (requestOwner (requestMetadataWord marked requestId)) requestId with
      | .error reason => .revert reason state
      | .ok removed =>
        -- All hint, cumulative-pair and locked-ETH reads happen after removal.
        if hint = 0 then .revert "InvalidHint" state
        else
          let lastCheckpoint := (removed.readSlot lastCheckpointIndexPosition).val
          if hint > lastCheckpoint then .revert "InvalidHint" state
          else
            let request := readRequest removed requestId hint
            if requestId < request.checkpointFrom then .revert "InvalidHint" state
            else if hint < lastCheckpoint &&
                (checkpointFromWord removed (hint + 1)).val ≤ requestId then
              .revert "InvalidHint" state
            else if request.previousCumulativeStETH > request.cumulativeStETH then
              .revert "Panic(0x11)" state
            else if request.previousCumulativeShares > request.cumulativeShares then
              .revert "Panic(0x11)" state
            else
              let eth := request.cumulativeStETH - request.previousCumulativeStETH
              let shares := request.cumulativeShares - request.previousCumulativeShares
              if shares = 0 then .revert "Panic(0x12)" state
              else
                let discounted := eth * E27 / shares > request.checkpointMaxShareRate
                if discounted && shares * request.checkpointMaxShareRate ≥ 2 ^ 256 then
                  .revert "Panic(0x11)" state
                else
                  let payout := if discounted then shares * request.checkpointMaxShareRate / E27 else eth
                  .success payout removed

/-- The locked balance is read after the actual set removal/calculation. The
returned payout is the one subsequently sent by the recipient-call bridge. -/
def claimOne (requestId hint : Nat) (recipient : Address) : Contract Nat := fun state =>
  match prepareClaim requestId hint recipient state with
  | .revert reason _ => .revert reason state
  | .success payout removed =>
    let locked := (removed.readSlot lockedEtherAmountPosition).val
    if payout > locked then .revert "Panic(0x11)" state
    else .success payout (removed.writeSlot lockedEtherAmountPosition (.ofNat (locked - payout)))

private theorem prepareClaim_success_guards (requestId hint : Nat) (recipient : Address)
    (state after : ContractState) (payout : Nat)
    (h : prepareClaim requestId hint recipient state = .success payout after) :
    requestId ≠ 0 ∧ requestId ≤ (state.readSlot lastFinalizedRequestIdPosition).val ∧
      requestClaimed (requestMetadataWord state requestId) = false ∧
      requestOwner (requestMetadataWord state requestId) = state.sender := by
  by_cases h0 : requestId = 0
  · simp only [prepareClaim, h0, if_true] at h
    contradiction
  by_cases h1 : requestId > (state.readSlot lastFinalizedRequestIdPosition).val
  · simp only [prepareClaim, h0, h1, if_false, if_true] at h
    contradiction
  by_cases hc : requestClaimed (requestMetadataWord state requestId) = true
  · simp only [prepareClaim, h0, h1, hc, if_false, if_true] at h
    contradiction
  by_cases ho : (requestOwner (requestMetadataWord state requestId) != state.sender) = true
  · simp only [prepareClaim, h0, h1, hc, ho, if_false, if_true] at h
    contradiction
  exact ⟨h0, Nat.le_of_not_gt h1, Bool.eq_false_iff.mpr hc, by simpa using ho⟩

/-- Success derives finalization/claimed/owner guards from physical reads. -/
theorem claimOne_success_guards (requestId hint : Nat) (recipient : Address)
    (state after : ContractState) (payout : Nat)
    (h : claimOne requestId hint recipient state = .success payout after) :
    requestId ≠ 0 ∧ requestId ≤ (state.readSlot lastFinalizedRequestIdPosition).val ∧
      requestClaimed (requestMetadataWord state requestId) = false ∧
      requestOwner (requestMetadataWord state requestId) = state.sender := by
  unfold claimOne at h
  cases hp : prepareClaim requestId hint recipient state with
  | «revert» reason rollback => simp only [hp] at h; contradiction
  | success amount removed =>
    simp only [hp] at h
    split at h
    · contradiction
    · cases h
      exact prepareClaim_success_guards requestId hint recipient state removed payout hp

/-- Success derives the exact final storage write, successful preparation and
word bound from the actual locked-balance subtraction. -/
theorem claimOne_success_storage (requestId hint : Nat) (recipient : Address)
    (state after : ContractState) (payout : Nat)
    (h : claimOne requestId hint recipient state = .success payout after) :
    ∃ removed, prepareClaim requestId hint recipient state = .success payout removed ∧
      payout ≤ (removed.readSlot lockedEtherAmountPosition).val ∧
      payout < 2 ^ 256 ∧
      after = removed.writeSlot lockedEtherAmountPosition
        (.ofNat ((removed.readSlot lockedEtherAmountPosition).val - payout)) := by
  unfold claimOne at h
  cases hp : prepareClaim requestId hint recipient state with
  | «revert» reason rollback => simp only [hp] at h; contradiction
  | success amount removed =>
    simp only [hp] at h
    split at h
    · contradiction
    · cases h
      refine ⟨removed, rfl, Nat.le_of_not_gt (by assumption), ?_, rfl⟩
      exact Nat.lt_of_le_of_lt (Nat.le_of_not_gt (by assumption)) (removed.readSlot lockedEtherAmountPosition).isLt

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
  let state := state.writeSlot (queueAmountsPhysicalSlot 0) (packAmounts 0 0)
  let state := state.writeSlot (queueAmountsPhysicalSlot 1) (packAmounts 30 30)
  let state := state.writeSlot (queueAmountsPhysicalSlot 2) (packAmounts 70 70)
  let state := state.writeSlot (queueMetadataPhysicalSlot 1)
    (packMetadata (1 : Address) 100 false 90)
  let state := state.writeSlot (queueMetadataPhysicalSlot 2)
    (packMetadata (1 : Address) 101 false 90)
  let state := match insertOwnerRequest state (1 : Address) 1 with
    | some after => after | none => state
  let state := match insertOwnerRequest state (1 : Address) 2 with
    | some after => after | none => state
  let state := state.writeSlot (checkpointFromPhysicalSlot 1) 1
  state.writeSlot (checkpointRatePhysicalSlot 1) (.ofNat E27)

/-- The transaction boundary restores the entry snapshot after any failed
guard or payout frame, including failures reached during later iterations. -/
theorem every_revert_restores_snapshot (requestIds hints : List Nat) (recipient : Address)
    (state rollback : ContractState) (reason : String)
    (h : (executeClaimWithdrawalsTo requestIds hints recipient).run state =
      .revert reason rollback) : rollback = state := by
  unfold Contract.run at h
  split at h <;> simp_all

end LidoSRv3.Audit.Verity.AddressClaimBatchTx
