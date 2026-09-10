import LidoSRv3.Audit.Source.SszBlsComposition

namespace LidoSRv3.Tests.SszBlsCompositionMutants
open EvmYul EvmYul.EVM LidoSRv3.Audit.Source
open SszBlsComposition SszWordBytes SszTypedFfiBridge

private def a : UInt256 := UInt256.ofNat 0x01020304
private def b : UInt256 := UInt256.ofNat (2^255 + 0x11223344)
private def fields : Fields := ⟨32_000_000_000, true, 11, 22, 33, 44⟩
private def key : ByteArray := ⟨Array.ofFn fun i : Fin 48 => UInt8.ofNat (i.val+1)⟩
private def st : EVM.State :=
  { (default : EVM.State) with
    memory := ⟨Array.replicate 96 77⟩
    gasAvailable := UInt256.ofNat 1_000_000
    executionEnv := {(default : EVM.State).executionEnv with calldata := ⟨#[0xaa,0xbb,0xcc]⟩ ++ key ++ ⟨#[0xdd]⟩} }
private def tag (r : Except Error Result) : Option Error :=
  match r with | .ok _ => none | .error e => some e
private def vtag (r : Except SszBlsComposition.VerifyError EVM.State) : Option SszBlsComposition.VerifyError :=
  match r with | .ok _ => none | .error e => some e

-- Actual ordered mstores, including padding and an existing memory tail.
example : (preparePair st a b).memory.readWithPadding 0 64 = a.toByteArray ++ b.toByteArray := by
  rw [prepared_read]; simp only [actual_word_bytes]
example : (preparePair st a b).memory.readWithPadding 0 64 ≠ b.toByteArray ++ a.toByteArray := by
  rw [prepared_read]; simp only [actual_word_bytes]; decide +kernel
example : ((preparePair st a b).memory.extract 64 96) = ⟨Array.replicate 32 77⟩ := by
  rw [prepared_memory]; decide +kernel
example : (preparePair (default : EVM.State) a b).activeWords.toNat = 2 := by
  rw [prepared_words]; decide +kernel
example : (preparePair {st with activeWords := UInt256.ofNat 17} a b).activeWords.toNat = 17 := by
  rw [prepared_words]; decide +kernel

-- Every byte of the selected raw key is represented, with its actual offset.
example : bytes (witnessAt st (UInt256.ofNat 3) fields).pubkey = key := by
  rw [show (witnessAt st (UInt256.ofNat 3) fields).pubkey =
    SszScratchEvmMemory.typedBytes (st.executionEnv.calldata.extract 3 51) from rfl, bytes_typed]
  decide +kernel
example : bytes (witnessAt st (UInt256.ofNat 4) fields).pubkey ≠ key := by
  change bytes (SszScratchEvmMemory.typedBytes (st.executionEnv.calldata.extract 4 52)) ≠ key
  rw [bytes_typed]; decide +kernel
example : (witnessAt st (UInt256.ofNat 3) fields).pubkey.length = 48 := by decide +kernel
example : (witnessAt st (UInt256.ofNat 3) fields).pubkey[47]!.toNat = 48 := by decide +kernel
example : (SszScratchEvmMemory.rawBlock st.executionEnv.calldata 3).extract 48 64 = ⟨Array.replicate 16 0⟩ := by decide +kernel

-- The actual primitive CALL at invalid depth rejects before a digest is read.
private def tooDeep : EVM.State := {st with executionEnv := {st.executionEnv with depth := 1024}}
example : tag (pairRun 0 tooDeep a b) = some .sha256PrecompileFailed := by rfl
example : tag (pubkeyRun 0 tooDeep (UInt256.ofNat 3) 48) = some .sha256PrecompileFailed := by rfl
example : tag (merkleRun 0 tooDeep a b a b a b a b) = some .sha256PrecompileFailed := by rfl

-- Key guard precedes hashing and the final verifier's empty-proof guard.
example : tag (pubkeyRun 0 tooDeep (UInt256.ofNat 3) 47) = some .invalidPubkeyLength := by rfl
example : tag (pubkeyRun 0 tooDeep (UInt256.ofNat 3) 49) = some .invalidPubkeyLength := by rfl
example : tag (leafRun 0 tooDeep (UInt256.ofNat 3) 0 fields 0) = some .invalidPubkeyLength := by rfl
example : vtag (verifyLeaf 0 tooDeep (UInt256.ofNat 3) 47 fields 0 a b a 0) = some (.bls .invalidPubkeyLength) := by rfl
example : vtag (verifyLeaf 0 tooDeep (UInt256.ofNat 3) 48 fields 0 a b a 0) = some (.bls .sha256PrecompileFailed) := by rfl

-- Isolated guard truth table; these synthetic replies are not actual SHA runs.
example : tag (finish (.ok (UInt256.ofNat 0,{st with returnData := ⟨Array.replicate 32 0⟩}))) = some .sha256PrecompileFailed := by rfl
example : tag (finish (.ok (UInt256.ofNat 1,{st with returnData := ⟨Array.replicate 31 0⟩}))) = some .sha256PrecompileFailed := by rfl
example : tag (finish (.ok (UInt256.ofNat 1,{st with returnData := ⟨Array.replicate 33 0⟩}))) = some .sha256PrecompileFailed := by rfl
example : tag (finish (.ok (UInt256.ofNat 1,{st with returnData := ⟨Array.replicate 32 0⟩}))) = none := by rfl
example : tag (finish (.error .OutOfFuel)) = some .engineFailure := by rfl

example : budget 7 = 18789 := by decide +kernel
example : budget 8 = 21473 := by decide +kernel
example : budget (8+50) = 155673 := by decide +kernel
example : 8*2684 < budget 8 := by decide +kernel
example : chunk 0x0102030405060708 = UInt256.ofNat (0x0807060504030201 * 2^192) := by decide +kernel
example : chunk 1 ≠ UInt256.ofNat 1 := by decide +kernel
example : chunk 0 = UInt256.ofNat 0 := by decide +kernel
example : chunk (2^64-1) = UInt256.ofNat ((2^64-1)*2^192) := by decide +kernel

#print axioms pair_success
#print axioms pair_budget
#print axioms merkle_success
#print axioms merkle_digest_typed
#print axioms pubkey_success
#print axioms bytes_typed
#print axioms pubkey_digest_typed
#print axioms leaf_success
#print axioms verify_leaf_success
end LidoSRv3.Tests.SszBlsCompositionMutants
