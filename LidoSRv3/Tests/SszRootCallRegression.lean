import LidoSRv3.Audit.Guarantees.PSsz1RootCall

namespace LidoSRv3.Tests.SszRootCallRegression
open Audit.Source Audit.Source.SszRootCall Audit.Source.SszVerifierEntry
open Audit.Source.SszValidatorLeaf Audit.Source.SszWrapperIndex Audit.Source.TrioReserve1
set_option maxRecDepth 4096
set_option maxHeartbeats 4000000

private def caller : Live.Address := ⟨17,by decide⟩
private def world : Live.World :=
  ⟨{Verity.defaultState with codeSize := fun _ => Live.word 1},fun _ => 0,[]⟩
private def zeroSha : Precompile := standardSha (fun _ => 0)
private def input : Input := {
  scratch := fun _ => 255
  cfg := pinnedConfiguration ⟨0,by decide⟩
  beacon := ⟨0x0102030405060708,0,0⟩
  witness := ⟨List.replicate 48 0,0,false,0,0,0,0⟩
  proof := List.replicate 50 0
  offset := ⟨0,by decide⟩
  credentials := 0 }
private def rootData : Live.Bytes := List.replicate 32 0
private def reply (data : Live.Bytes) : StaticCall.External := fun _ _ => .success data
private def reject : StaticCall.External := fun _ _ => .rejected rootData
private def observe (external : StaticCall.External) (i : Input := input) :
    Except SszVerifierEntry.Error Unit × List Live.NestedAttempt :=
  let r := SszRootCall.run zeroSha external caller i world
  (r.outcome,r.attempts)

/-- Concrete uint64 byte order and absence of a selector. -/
theorem timestamp_octets : payload 0x0102030405060708 =
    List.replicate 24 0 ++ [1,2,3,4,5,6,7,8] := by decide +kernel

/-- Full successful pinned-index typed entry, not merely a decoded-root unit test. -/
theorem success_consumes_one_reply : observe (reply rootData) =
    (.ok (),[⟨request caller input.beacon.childBlockTimestamp,true,true,rootData,1⟩]) := by
  decide +kernel

/-- Changing only the actual returned root invalidates the final proof. -/
theorem changed_returned_root_fails :
    (observe (reply (List.replicate 31 0 ++ [1]))).1 = .error (.proof .invalidProof) := by
  decide +kernel

theorem trailing_data_accepted : (observe (reply (rootData ++ [99,100]))).1 = .ok () := by
  decide +kernel

/-- Slot failure wins over root-call rejection and leaves no attempted root call. -/
theorem slot_failure_before_root : observe reject {input with proof := List.replicate 50 1} =
    (.error (.slotOrIndex .invalidSlot),[]) := by decide +kernel

/-- A failed BLS slot hash is observed before the short-proof subtraction guard. -/
theorem slot_hash_before_short_proof :
    (SszRootCall.run (fun _ => ⟨false,32,0⟩) reject caller {input with proof := []} world).outcome =
      .error (.bls .sha256PrecompileFailed) ∧
    (SszRootCall.run (fun _ => ⟨false,32,0⟩) reject caller {input with proof := []} world).attempts = [] := by
  decide +kernel

/-- Callee rejection is RootNotFound even when rejected bytes would decode. -/
theorem rejected_call_retained : observe reject =
    (.error .rootNotFound,[⟨request caller input.beacon.childBlockTimestamp,true,false,rootData,1⟩]) := by
  decide +kernel

theorem forbidden_write_retained : observe (fun _ _ => .forbiddenStateChange) =
    (.error .rootNotFound,[⟨request caller input.beacon.childBlockTimestamp,true,false,[],1⟩]) := by
  decide +kernel

theorem empty_reply_before_decode : (observe (reply [])).1 = .error .rootNotFound := by
  decide +kernel

theorem short_reply_before_invalid_leaf :
    (observe (reply (List.replicate 31 0))
      {input with witness := {input.witness with pubkey := []}}).1 = .error .abiDecodeFailure := by
  decide +kernel

/-- EOA behavior cannot be replaced by the supplied external's 32-byte success. -/
theorem no_code_success_empty_then_root_failure :
    let emptyWorld := {world with core := {world.core with codeSize := fun _ => Live.word 0}}
    let r := SszRootCall.run zeroSha (reply rootData) caller input emptyWorld
    r.outcome = .error .rootNotFound ∧
    r.attempts = [⟨request caller input.beacon.childBlockTimestamp,true,true,[],1⟩] := by
  decide +kernel

/-- GIndex range rejection runs after the root call, before invalid pubkey length. -/
theorem index_before_leaf :
    (observe (reply rootData) {input with
      offset := ⟨2^40,by decide⟩
      witness := {input.witness with pubkey := []}}).1 = .error (.slotOrIndex .indexOutOfRange) := by
  decide +kernel

/-- Root rejection and ABI decoding both precede a failing GIndex constructor. -/
theorem root_guards_before_index :
    (observe reject {input with offset := ⟨2^40,by decide⟩}).1 = .error .rootNotFound ∧
    (observe (reply (List.replicate 31 0)) {input with offset := ⟨2^40,by decide⟩}).1 =
      .error .abiDecodeFailure := by decide +kernel

#print axioms root_guards_before_index
#print axioms timestamp_octets
#print axioms success_consumes_one_reply
#print axioms changed_returned_root_fails
#print axioms trailing_data_accepted
#print axioms slot_failure_before_root
#print axioms slot_hash_before_short_proof
#print axioms rejected_call_retained
#print axioms forbidden_write_retained
#print axioms empty_reply_before_decode
#print axioms short_reply_before_invalid_leaf
#print axioms no_code_success_empty_then_root_failure
#print axioms index_before_leaf
end LidoSRv3.Tests.SszRootCallRegression
