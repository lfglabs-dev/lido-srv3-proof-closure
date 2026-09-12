import LidoSRv3.Audit.Source.TopupGatewayWitnessBatch

set_option maxRecDepth 4096
set_option maxHeartbeats 2000000

namespace LidoSRv3.Tests.TopupGatewayWitnessBatchMutants
open Audit.Source Audit.Source.TopupGatewayWitnessBatch
open SszValidatorLeaf SszVerifierEntry SszWrapperIndex

private def cfg : TopupWeiBounds.GatewayConfig := ⟨⟨64,by decide⟩,⟨2,by decide⟩,⟨1,by decide⟩⟩
private def witness : Witness :=
  ⟨List.replicate 48 0,32,false,0,0,BitVec.ofNat 64 (2^64-1),0⟩
private def beacon : BeaconData := ⟨1,0,0⟩
private def row : Row := ⟨⟨0,by decide⟩,witness,List.replicate 50 0,⟨0,by decide⟩⟩
private def sha : Sha := fun _ => 0
private def oracle : RootOracle := fun _ _ => ⟨true,List.replicate 32 0⟩
private def scratch : Fin 32 → Byte := fun _ => 0
private def gi : Configuration := pinnedConfiguration ⟨0,by decide⟩
private def divisor : Index := ⟨32,by decide⟩
private def checkRow := rowLimit (standardSha sha) oracle scratch gi cfg beacon divisor 0
private def runRows := loop (standardSha sha) oracle scratch gi cfg beacon divisor 0 none 0

-- Length/cardinality precedence is tested separately from the witness loop.
example : checkLengths cfg 0 0 0 0 0 = .error .wrongArrayLength := by decide
example : checkLengths cfg 3 2 3 3 3 = .error .wrongArrayLength := by decide
example : checkLengths cfg 3 3 3 3 3 = .error .maxValidatorsExceeded := by decide
example : checkLengths cfg 2 2 1 2 2 = .error .wrongArrayLength := by decide
example : checkLengths cfg 2 2 2 1 2 = .error .wrongArrayLength := by decide
example : checkLengths cfg 2 2 2 2 1 = .error .wrongArrayLength := by decide
example : checkLengths cfg 2 2 2 2 2 = .ok () := by decide

-- Genuine sourceEntry executes here. A constant digest is an explicit abstract
-- hash fixture, not a cryptographic inequality or root-authenticity test.
example : checkRow none row = .ok 32 := by decide
example : checkRow (some row.index) row = .error .invalidSortOrder := by decide
example : checkRow (some ⟨2,by decide⟩) {row with index := ⟨1,by decide⟩} =
    .error .invalidSortOrder := by decide
example : checkRow (some row.index) {row with witness := {witness with pubkey := []}} =
    .error .wrongPubkeyLength := by decide
example : checkRow none {row with witness := {witness with activationEpoch := 1}, proof := []} =
    .error .notActivated := by decide
example : activated 0 ⟨0,by decide⟩ witness = .error .divisionByZero := by decide
example : activated (BitVec.ofNat 64 (2^64-1)) ⟨1,by decide⟩
    {witness with activationEpoch := BitVec.ofNat 64 (2^64-1)} = .ok () := by decide
example : activated 64 ⟨32,by decide⟩ {witness with activationEpoch := 2} = .ok () := by decide
example : activated 63 ⟨32,by decide⟩ {witness with activationEpoch := 2} = .error .notActivated := by decide

private def overflowing : Row := {row with pending := ⟨2^256-1,by decide⟩}
example : checkRow none overflowing = .error .pendingOverflow := by decide
example : checkRow none {overflowing with proof := []} =
    .error (.verifier (.slotOrIndex .arithmeticPanic)) := by decide
example : checkRow none {overflowing with witness := {witness with slashed := true}} = .ok 0 := by decide
example : checkRow none {overflowing with witness := {witness with exitEpoch := 0}} = .ok 0 := by decide
example : checkRow none {overflowing with witness := {witness with slashed := true}, proof := []} =
    .error (.verifier (.slotOrIndex .arithmeticPanic)) := by decide
example : checkRow none {row with pending := ⟨40,by decide⟩} = .ok 0 := by decide
example : checkRow none {row with pending := ⟨31,by decide⟩} = .ok 1 := by decide

example : runRows [row] = .ok ⟨[witness.pubkey],[32000000000],32000000000⟩ := by decide
example : runRows [row,{row with index := ⟨1,by decide⟩, pending := ⟨16,by decide⟩}] =
    .ok ⟨[witness.pubkey,witness.pubkey],[32000000000,16000000000],48000000000⟩ := by decide
example : runRows [row,row] = .error .invalidSortOrder := by decide
example : runRows [row,{row with index := ⟨1,by decide⟩, pending := ⟨2^256-1,by decide⟩}] =
    .error .pendingOverflow := by decide
example : TopupRouterContinuation.guardSum [] [32000000000] 0 = .ok 0 := by decide
example : TopupRouterContinuation.guardSum [1000000000] [32000000000] 0 = .ok 1000000000 := by decide
example : TopupRouterContinuation.guardSum [1000000001] [32000000000] 0 =
    .error (.reason "AmountNotAlignedToGwei") := by decide
example : TopupRouterContinuation.guardSum [33000000000] [32000000000] 0 =
    .error (.reason "AllocationExceedsLimit") := by decide

private def secondRow : Row :=
  { row with
    index := ⟨1,by decide⟩
    witness := {witness with pubkey := List.replicate 48 1}
    pending := ⟨16,by decide⟩ }
example : runRows [row,secondRow] =
    .ok ⟨[List.replicate 48 0,List.replicate 48 1],[32000000000,16000000000],48000000000⟩ := by decide

private def shaSum : Sha := fun bytes => BitVec.ofNat 256 ((bytes.map BitVec.toNat).sum)
private def sumOracle : RootOracle := fun _ _ => ⟨true,digestBytes 32⟩
example : rowLimit (standardSha shaSum) sumOracle scratch gi cfg beacon divisor 0 none row = .ok 32 := by decide
example : rowLimit (standardSha shaSum) sumOracle scratch gi cfg beacon divisor 1 none row =
    .error (.verifier (.proof .invalidProof)) := by decide

open TrioReserve1.Live in
example : (TopupGatewayConfigWords.decode
    (word (7 + 2^64 * 123456 + 2^160 * 64 + 2^224 * 9)) (word (3 + 2^64 * 17))).target.val = 64 := by decide
open TrioReserve1.Live in
example : (TopupGatewayConfigWords.decode
    (word (7 + 2^64 * 123456 + 2^160 * 64 + 2^224 * 9)) (word (3 + 2^64 * 17))).maxValidators.val = 7 := by decide
open TrioReserve1.Live in
example : (TopupGatewayConfigWords.decode
    (word (7 + 2^64 * 123456 + 2^160 * 64 + 2^224 * 9)) (word (3 + 2^64 * 17))).minTopUp.val = 3 := by decide

example : rowLimit (fun _ => ⟨false,32,0⟩) oracle scratch gi cfg beacon divisor 0 none
    {overflowing with proof := []} = .error (.verifier (.bls .sha256PrecompileFailed)) := by decide
example : rowLimit (fun _ => ⟨true,31,0⟩) oracle scratch gi cfg beacon divisor 0 none row =
    .error (.verifier (.bls .sha256PrecompileFailed)) := by decide
example : rowLimit (fun _ => ⟨true,33,0⟩) oracle scratch gi cfg beacon divisor 0 none row =
    .error (.verifier (.bls .sha256PrecompileFailed)) := by decide

#print axioms checkLengths_iff
#print axioms epoch_cast_exact
#print axioms evaluate_headroom
#print axioms loop_run
#print axioms canonical_row_entry
#print axioms canonical_batch
#print axioms loop_spec
#print axioms router_checked_from_loop
#print axioms router_keys_exact
#print axioms wei_word_values
#print axioms TopupGatewayConfigWords.decode_packed

end LidoSRv3.Tests.TopupGatewayWitnessBatchMutants
