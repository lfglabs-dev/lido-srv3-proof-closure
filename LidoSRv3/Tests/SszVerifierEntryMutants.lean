import LidoSRv3.Audit.Source.SszVerifierEntry

namespace LidoSRv3.Tests.SszVerifierEntryMutants
open LidoSRv3.Audit.Source SszVerifierEntry SszValidatorLeaf SszWrapperIndex

set_option maxRecDepth 8192
set_option maxHeartbeats 2000000

/-- Deterministic toy SHA isolates ordered control flow. It is not SHA-256 or
an injectivity assumption. The Solidity harness separately executes real SHA. -/
def zeroSha : Sha := fun _ => 0
def goodSha := standardSha zeroSha
def failedSha : Precompile := fun _ => ⟨false, 32, 0⟩
def shortSha : Precompile := fun _ => ⟨true, 31, 0⟩
def beacon : BeaconData := ⟨0x0102030405060708, 1, 2⟩
def witness : Witness := ⟨List.replicate 48 7, 3, true, 4, 5, 6, 7⟩
def badWitness : Witness := {witness with pubkey := []}
def scratch : Fin 32 → Byte := fun _ => 255
def cfg := pinnedConfiguration ⟨100, by decide⟩
def offset : Fin wordModulus := ⟨0, by decide⟩
def badOffset : Fin wordModulus := ⟨2 ^ 40, by decide⟩
def proof : List Digest := List.replicate 50 0

def missingRoot : RootOracle := fun _ _ => ⟨false, digestBytes 0⟩
def rootOracle (bytes : List Byte) : RootOracle := fun address payload =>
  if address = beaconRootsAddress ∧ payload = timestampPayload beacon.childBlockTimestamp
  then ⟨true, bytes⟩ else ⟨false, []⟩
def run (precompile : Precompile) (oracle : RootOracle) (w : Witness := witness)
    (p : List Digest := proof) (i : Fin wordModulus := offset) :=
  sourceEntry precompile oracle scratch cfg beacon w p i 9

/-- ABI timestamp bytes are high-endian, exactly32bytes, without a selector. -/
example : timestampPayload beacon.childBlockTimestamp =
    List.replicate 24 0 ++ [1, 2, 3, 4, 5, 6, 7, 8] := by decide
example : timestampPayload 1 ≠ digestBytes (SszLittleEndianCorrespondence.uint64Chunk 1) := by decide
example : timestampPayload 0 = List.replicate 32 0 := by decide
example : timestampPayload (BitVec.ofNat 64 (2 ^ 64 - 1)) =
    List.replicate 24 0 ++ List.replicate 8 255 := by decide
example : beaconRootsAddress.toNat = 0x000F3df6D732807Ef1319fB7B8bB8522d0Beac02 := by decide

/-- The decoder uses the first word, including its most/least significant byte. -/
example : firstWord (List.replicate 31 0 ++ [7]) = 7 := by decide
example : firstWord (1 :: List.replicate 31 0) = (1 : Digest) <<< (248 : Nat) := by decide
example : decodeRootReply ⟨true, digestBytes 7 ++ [255]⟩ = .ok 7 := by decide
example : decodeRootReply ⟨true, digestBytes 7 ++ List.replicate 223 255⟩ = .ok 7 := by decide
example : decodeRootReply ⟨false, digestBytes 7⟩ = .error .rootNotFound := by decide
example : decodeRootReply ⟨true, []⟩ = .error .rootNotFound := by decide
example : decodeRootReply ⟨true, [7]⟩ = .error .abiDecodeFailure := by decide
example : decodeRootReply ⟨true, List.replicate 31 7⟩ = .error .abiDecodeFailure := by decide
example : decodeRootReply ⟨false, [7]⟩ = .error .rootNotFound := by decide

/-- SHA errors precede proof subtraction, missing root, index and leaf errors. -/
example : run failedSha missingRoot badWitness [] badOffset =
    .error (.bls .sha256PrecompileFailed) := by decide
example : run shortSha missingRoot badWitness [0] badOffset =
    .error (.bls .sha256PrecompileFailed) := by decide
example : run goodSha missingRoot badWitness [] badOffset =
    .error (.slotOrIndex .arithmeticPanic) := by decide
example : run goodSha missingRoot badWitness [0] badOffset =
    .error (.slotOrIndex .arithmeticPanic) := by decide
example : run goodSha missingRoot badWitness [1, 0] badOffset =
    .error (.slotOrIndex .invalidSlot) := by decide

/-- Root guard/decode precede both configured-index rejection and invalid key. -/
example : run goodSha missingRoot badWitness proof badOffset = .error .rootNotFound := by decide
example : run goodSha (rootOracle []) badWitness proof badOffset = .error .rootNotFound := by decide
example : run goodSha (rootOracle [0]) badWitness proof badOffset = .error .abiDecodeFailure := by decide
example : run goodSha (rootOracle (List.replicate 31 0)) badWitness proof badOffset =
    .error .abiDecodeFailure := by decide
example : run goodSha (rootOracle (digestBytes 0)) badWitness proof badOffset =
    .error (.slotOrIndex .indexOutOfRange) := by decide
example : run goodSha (rootOracle (digestBytes 0)) badWitness =
    .error (.bls .invalidPubkeyLength) := by decide

/-- Full entry consumes the returned root, permits suffixes, and uses all50siblings. -/
example : run goodSha (rootOracle (digestBytes 0)) = .ok () := by decide
example : run goodSha (rootOracle (digestBytes 0 ++ [255])) = .ok () := by decide
example : run goodSha (rootOracle (digestBytes 1)) = .error (.proof .invalidProof) := by decide
example : run goodSha (rootOracle (digestBytes 1)) witness (List.replicate 49 0) =
    .error (.proof .missingItem) := by decide
example : run goodSha (rootOracle (digestBytes 1)) witness (List.replicate 51 0) =
    .error (.proof .extraItem) := by decide
example : sourceEntry goodSha (rootOracle (digestBytes 0)) scratch cfg
    {beacon with childBlockTimestamp := beacon.childBlockTimestamp + 1}
    witness proof offset 9 = .error .rootNotFound := by decide
example : rootOracle (digestBytes 0) (beaconRootsAddress + 1)
    (timestampPayload beacon.childBlockTimestamp) = ⟨false, []⟩ := by decide

/-- Same response adapter, different actual guards: BLS demands exact32;
SSZ.verifyProof only checks success and uses the modeled scratch word. -/
example : sourcePair shortSha 0 0 = .error .sha256PrecompileFailed := by decide
example : foldHash shortSha 0 0 = some 0 := by decide
example : foldHash failedSha 0 0 = none := by decide

#print axioms first_word_encoded
#print axioms root_reply_success_iff
#print axioms source_slot_standard
#print axioms entry_success_iff
#print axioms entry_success_returned_bytes
#print axioms entry_success_domains
#print axioms validator_entry_consumer

end LidoSRv3.Tests.SszVerifierEntryMutants
