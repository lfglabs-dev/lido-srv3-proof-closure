import LidoSRv3.Audit.Guarantees.PConsolidation1
import Compiler.Proofs.Storage.SolidityStorage
import Verity.Core.Model.CallProgramRollback
import Verity.Core.Model.DenoteMemory

/-!
# P-CONSOLIDATION-1 faithful transaction-plane FunctionSpec

This is the line-by-line executable model used for P-CONSOLIDATION-1.  The
source-facing boundary is the seven operations in the audit target: the
top-level value guard, two calldata reads, the per-request prepaid-balance
guard and debit, the source-to-target mapping write, the EIP-7251 request call,
and the event.

The pinned Lido `ConsolidationBus`/`ConsolidationGateway` route requests to the
withdrawal vault and do not themselves declare `prepaidBalance`,
`validatorPubkeyMapping`, or `feePerConsolidation`.  Consequently the three
slot numbers below are the declared layout of this bounded target, not a claim
about either Lido gateway contract's inherited storage layout.
-/

namespace LidoSRv3.Audit.Verity.ConsolidationFee

open Compiler.CompilationModel.DenoteExternalCalls
open Compiler.CompilationModel.DenoteMemory
open Compiler.Proofs.IRGeneration
open Compiler.Proofs.Storage
open LidoSRv3.Audit.Guarantees.PConsolidation1

def consolidationRequestAddress : Nat :=
  0x0000BBdDc7CE488642fb579F8B00f3a590007251

/-! ## 1D: canonical Solidity storage addresses -/

def consolidationContract : ContractId := 0
def prepaidBalanceBaseSlot : Nat := 0
def validatorPubkeyMappingBaseSlot : Nat := 1
def feePerConsolidationSlot : Nat := 2

def scalarSlotPointer (slot : Nat) : ByteArray :=
  (EvmYul.UInt256.ofNat slot).toByteArray

def prepaidBalanceSlot (sender : Nat) : ByteArray :=
  mappingSlotPointer prepaidBalanceBaseSlot sender

def validatorPubkeyMappingSlot (sourcePubkey : ValidatorPubkey) : ByteArray :=
  mappingSlotPointer validatorPubkeyMappingBaseSlot sourcePubkey

def feeSlot : ByteArray := scalarSlotPointer feePerConsolidationSlot

theorem prepaidBalanceSlot_is_canonical (sender : Nat) :
    ∃ preimage,
      preimage = Compiler.Proofs.abiEncodeMappingSlot prepaidBalanceBaseSlot sender ∧
      prepaidBalanceSlot sender = KeccakEngine.keccak256 preimage := by
  exact mappingSlot_preimage prepaidBalanceBaseSlot sender

theorem validatorPubkeyMappingSlot_is_canonical (sourcePubkey : ValidatorPubkey) :
    ∃ preimage,
      preimage = Compiler.Proofs.abiEncodeMappingSlot validatorPubkeyMappingBaseSlot sourcePubkey ∧
      validatorPubkeyMappingSlot sourcePubkey = KeccakEngine.keccak256 preimage := by
  exact mappingSlot_preimage validatorPubkeyMappingBaseSlot sourcePubkey

/-! ## 1H: byte-precise ABI calldata -/

def selectorOffset : Nat := 0x00
def sourceArrayOffsetWord : Nat := 0x04
def targetArrayOffsetWord : Nat := 0x24
def sourceArrayOffset : Nat := 0x40

def targetArrayOffset (requests : List ConsolidationRequest) : Nat :=
  sourceArrayOffset + 32 + 32 * requests.length

def natWord (value : Nat) : Compiler.CompilationModel.DenoteMemory.Word :=
  fun index => ⟨(value / 256 ^ (31 - index.val)) % 256, Nat.mod_lt _ (by decide)⟩

/-- `bytes4(keccak256("consolidate(bytes[],bytes[])"))`, left-aligned in the
ABI word.  The following write at `0x04` overlaps only the 28 padding bytes. -/
def consolidateSelector : Nat := 0x313afb62

def selectorWord : Compiler.CompilationModel.DenoteMemory.Word :=
  natWord (consolidateSelector * 2 ^ 224)

/-- Positional word writer (unlike a value search, repeated pubkeys retain
their distinct ABI positions). -/
def writeIndexedWords (memory : Memory) (offset : Nat) : List Nat → Nat → Memory
  | [], _ => memory
  | value :: rest, index =>
      writeIndexedWords (memory.writeWord (offset + 32 * index) (natWord value))
        offset rest (index + 1)

def calldataMemory (requests : List ConsolidationRequest) : Memory :=
  let sourceValues := requests.map (·.sourcePubkey)
  let targetValues := requests.map (·.targetPubkey)
  let sourceData := 4 + sourceArrayOffset + 32
  let targetOffset := targetArrayOffset requests
  let targetData := 4 + targetOffset + 32
  let header := Memory.empty
    |>.writeWord selectorOffset selectorWord
    |>.writeWord sourceArrayOffsetWord (natWord sourceArrayOffset)
    |>.writeWord targetArrayOffsetWord (natWord targetOffset)
    |>.writeWord (4 + sourceArrayOffset) (natWord requests.length)
    |>.writeWord (4 + targetOffset) (natWord requests.length)
  writeIndexedWords
    (writeIndexedWords header sourceData sourceValues 0)
    targetData targetValues 0

def sourcePubkeyWord (requests : List ConsolidationRequest) (index : Nat) :=
  (calldataMemory requests).readWord (4 + sourceArrayOffset + 32 + 32 * index)

def targetPubkeyWord (requests : List ConsolidationRequest) (index : Nat) :=
  (calldataMemory requests).readWord
    (4 + targetArrayOffset requests + 32 + 32 * index)

theorem source_offset_write_read :
    (Memory.empty.writeWord sourceArrayOffsetWord (natWord sourceArrayOffset)).readWord
      sourceArrayOffsetWord = natWord sourceArrayOffset := by
  funext index
  rw [Memory.readWord, Memory.readByte, if_pos]
  · exact Memory.writeWord_at Memory.empty sourceArrayOffsetWord
      (natWord sourceArrayOffset) index
  · simp [sourceArrayOffsetWord, Memory.writeWord, Memory.expand,
      expandedLength, Memory.empty]
    omega

/-! ## Storage reads, guards, writes, calls, and events -/

structure ConsolidationState where
  storage : SolidityStorage
  events : List ConsolidationRequest

def readWordAt (state : ConsolidationState) (slot : ByteArray) : Nat :=
  (state.storage consolidationContract slot).toNat

def writeWordAt (state : ConsolidationState) (slot : ByteArray) (value : Nat) :
    ConsolidationState :=
  let write : StorageWrite :=
    { contract := consolidationContract
      slot := slot
      value := IRStorageWord.ofNat value }
  { state with storage := applyStorageWrite write state.storage }

def feePerConsolidation (state : ConsolidationState) : Nat :=
  readWordAt state feeSlot

def prepaidBalance (state : ConsolidationState) (sender : Nat) : Nat :=
  readWordAt state (prepaidBalanceSlot sender)

def mappedPubkey (state : ConsolidationState) (source : ValidatorPubkey) : Nat :=
  readWordAt state (validatorPubkeyMappingSlot source)

def wordBytes (value : Nat) : List Nat :=
  List.ofFn (fun index : Fin 32 => (natWord value index).val)

/-- A bounded pubkey is represented by sixteen leading zero bytes followed by
its 256-bit model value. Two such 48-byte keys are the exact 96-byte EIP-7251
payload. -/
def consolidationPayload (request : ConsolidationRequest) : List Nat :=
  List.replicate 16 0 ++ wordBytes request.sourcePubkey ++
    List.replicate 16 0 ++ wordBytes request.targetPubkey

theorem consolidationPayload_length (request : ConsolidationRequest) :
    (consolidationPayload request).length = 96 := by
  simp [consolidationPayload, wordBytes]

def requestSite (index : Nat) (request : ConsolidationRequest)
    (fee : FeePerConsolidation) : CallSite :=
  { siteId := index
    kind := .call
    target := consolidationRequestAddress
    value := fee
    calldata := consolidationPayload request
    gas := Verity.Core.MAX_UINT256 }

inductive StepResult where
  | insufficientPrepaidBalance
  | called (post : ConsolidationState) (observation : CallObservation)

/-- One loop iteration in Solidity order: calldata reads, balance guard, two
canonical storage writes, then the 96-byte precompile call.  The event is
appended only on call success. -/
def consolidateStep (adversary : AdversaryModel) (sender index : Nat)
    (request : ConsolidationRequest) (fee : Nat)
    (state : ConsolidationState) (callState : CallState) : StepResult :=
  let _source := sourcePubkeyWord [request] 0
  let _target := targetPubkeyWord [request] 0
  let balance := prepaidBalance state sender
  if balance < fee then .insufficientPrepaidBalance
  else
    let debited := writeWordAt state (prepaidBalanceSlot sender) (balance - fee)
    let mapped := writeWordAt debited
      (validatorPubkeyMappingSlot request.sourcePubkey) request.targetPubkey
    let observation := denoteCall adversary (requestSite index request fee)
      { callState with world := callState.world }
    let post := if observation.result.succeeded then
      { mapped with events := mapped.events ++ [request] }
    else mapped
    .called post observation

inductive BatchResult where
  | reverted (snapshot : ConsolidationState)
  | success (post : ConsolidationState) (observations : List CallObservation)

/-- Transactional loop. Any failed guard, external-call failure, or external
revert returns the pre-transaction snapshot, which models EVM rollback of both
storage writes and earlier event logs. -/
def runRequests (adversary : AdversaryModel) (sender fee : Nat)
    (snapshot : ConsolidationState) :
    List ConsolidationRequest → Nat → ConsolidationState → CallState →
      List CallObservation → BatchResult
  | [], _, state, _, observations => .success state observations.reverse
  | request :: rest, index, state, callState, observations =>
      match consolidateStep adversary sender index request fee state callState with
      | .insufficientPrepaidBalance => .reverted snapshot
      | .called post observation =>
          if observation.result.succeeded then
            runRequests adversary sender fee snapshot rest (index + 1) post
              observation.state (observation :: observations)
          else .reverted snapshot

/-- The top-level `msg.value >= requests.length * fee` guard precedes the
loop, exactly as in the target. -/
def consolidate (adversary : AdversaryModel) (sender msgValue : Nat)
    (requests : List ConsolidationRequest) (pre : ConsolidationState)
    (callState : CallState) : BatchResult :=
  let fee := feePerConsolidation pre
  if msgValue < requests.length * fee then .reverted pre
  else runRequests adversary sender fee pre requests 0 pre callState []

theorem consolidate_value_guard_rolls_back (adversary : AdversaryModel)
    (sender msgValue : Nat) (requests : List ConsolidationRequest)
    (pre : ConsolidationState) (callState : CallState)
    (h : msgValue < requests.length * feePerConsolidation pre) :
    consolidate adversary sender msgValue requests pre callState = .reverted pre := by
  simp [consolidate, h]

theorem runRequests_revert_is_snapshot (adversary : AdversaryModel)
    (sender fee : Nat) (snapshot state revertedState : ConsolidationState)
    (requests : List ConsolidationRequest) (index : Nat) (callState : CallState)
    (observations : List CallObservation)
    (h : runRequests adversary sender fee snapshot requests index state callState observations =
      .reverted revertedState) :
    revertedState = snapshot := by
  induction requests generalizing index state callState observations with
  | nil => simp [runRequests] at h
  | cons request rest ih =>
      simp only [runRequests] at h
      split at h
      · exact (BatchResult.reverted.inj h).symm
      · split at h
        · exact ih _ _ _ _ h
        · exact (BatchResult.reverted.inj h).symm

/-- A.1 transaction rollback: if the batch reports any guard failure, call
failure, or call revert, the returned state is the original snapshot. -/
theorem consolidation_rollback_ok (adversary : AdversaryModel)
    (sender msgValue : Nat) (requests : List ConsolidationRequest)
    (pre revertedState : ConsolidationState) (callState : CallState)
    (h : consolidate adversary sender msgValue requests pre callState =
      .reverted revertedState) :
    revertedState = pre := by
  simp only [consolidate] at h
  split at h
  · exact (BatchResult.reverted.inj h).symm
  · exact runRequests_revert_is_snapshot
      (adversary := adversary) (sender := sender)
      (fee := feePerConsolidation pre) (snapshot := pre) (state := pre)
      (revertedState := revertedState) (requests := requests) (index := 0)
      (callState := callState) (observations := []) h

/-- The generic A.1 theorem remains the external-world component of the
transaction proof: a dynamically observed all-rollback call trace preserves
the initial call world. -/
theorem call_world_rollback_ok (program : CallProgram α)
    (adversary : AdversaryModel) (state : CallState)
    (h : ∀ entry ∈ ObservedCalls program adversary state,
      RollsBack adversary entry) :
    (denote program adversary state).2.world = state.world := by
  exact denoteCallProgram_all_revert_preserves_world program adversary state h

end LidoSRv3.Audit.Verity.ConsolidationFee
