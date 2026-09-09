import LidoSRv3.Audit.Source.SszProofCalldataStep

set_option maxRecDepth 8192
set_option maxHeartbeats 800000

namespace LidoSRv3.Tests.SszProofCalldataStepMutants
open EvmYul EvmYul.EVM
open LidoSRv3.Audit.Source
open SszWordBytes SszProofCalldataStep SszShaCallMemory

private def a : UInt256 := UInt256.ofNat 0x01020304
private def b : UInt256 := UInt256.ofNat (2^255 + 0x11223344)
private def prebytes : ByteArray := ⟨#[0xaa, 0xbb, 0xcc]⟩
private def suffix : ByteArray := ⟨#[0xdd, 0xee]⟩
private def raw : ByteArray := layout prebytes suffix [] a [b]
private def fixture (old : ByteArray) : EVM.State :=
  { (default : EVM.State) with
    executionEnv := { (default : EVM.State).executionEnv with calldata := raw }
    memory := old
    gasAvailable := UInt256.ofNat 100000 }

-- A fixed-position, one-hot byte specification independent of the recursive codec.
private def oneHotBytes (bit : Nat) : ByteArray :=
  ⟨Array.ofFn (fun i : Fin 32 => if i.val = 31 - bit / 8 then UInt8.ofNat (2^(bit % 8)) else 0)⟩

example : (List.range 256).all (fun bit =>
    (UInt256.ofNat (2^bit)).toByteArray == oneHotBytes bit) = true := by
  simp only [actual_word_bytes]
  decide +kernel
example : (UInt256.ofNat 0).toByteArray = ⟨Array.replicate 32 0⟩ := by
  simp only [actual_word_bytes]
  decide +kernel
example : (UInt256.ofNat (2^256-1)).toByteArray = ⟨Array.replicate 32 255⟩ := by
  simp only [actual_word_bytes]
  decide +kernel
-- Omitting the leading padding or reversing the complete word changes its bytes.
example : a.toByteArray ≠ BE a.toNat := by
  simp only [actual_word_bytes]
  decide +kernel
example : a.toByteArray ≠ a.toByteArray.data.toList.reverse.toByteArray := by
  simp only [actual_word_bytes]
  decide +kernel

example : ((fixture .empty).toState.calldataload (proofOffset prebytes [])).toNat = 0x01020304 := by
  rw [actual_sibling _ prebytes suffix [] [b] a rfl (by decide +kernel)]
  decide +kernel
example : ((fixture .empty).toState.calldataload (proofOffset prebytes [a])).toNat = 2^255 + 0x11223344 := by
  rw [actual_sibling _ prebytes suffix [a] [] b rfl (by decide +kernel)]
  decide +kernel
-- Both zero-base and one-byte cursor mutations select different actual calldata.
example : (fixture .empty).toState.calldataload (UInt256.ofNat 0) ≠ a := by
  change uInt256OfByteArray (raw.readBytes 0 32) ≠ a
  rw [calldata_read_fit _ _ (by decide +kernel)]
  decide +kernel
example : (fixture .empty).toState.calldataload (UInt256.ofNat 4) ≠ a := by
  change uInt256OfByteArray (raw.readBytes 4 32) ≠ a
  rw [calldata_read_fit _ _ (by decide +kernel)]
  decide +kernel

example : (List.range 256).all (fun metadata =>
    (decodeIndex (UInt256.ofNat (2*256+metadata))).toNat == 2) = true := by decide +kernel
example : (decodeIndex (UInt256.ofNat (2^256-1))).toNat = 2^248-1 := by decide +kernel
example : scratchAddress (UInt256.ofNat 2) = UInt256.ofNat 0 := by decide +kernel
example : scratchAddress (UInt256.ofNat 3) = UInt256.ofNat 32 := by decide +kernel
-- Choosing scratch after shifting changes the side for both concrete indices.
example : scratchAddress (parentIndex (UInt256.ofNat 2)) ≠ scratchAddress (UInt256.ofNat 2) := by decide +kernel
example : scratchAddress (parentIndex (UInt256.ofNat 5)) ≠ scratchAddress (UInt256.ofNat 5) := by decide +kernel

private def scratchRead (index : Nat) (old : ByteArray) : ByteArray :=
  (preparedStep (fixture old) (UInt256.ofNat index) b (proofOffset prebytes [])).memory.readWithPadding 0 64
private theorem scratch_model (index : Nat) (old : ByteArray) :
    scratchRead index old = pairInput (UInt256.ofNat index) b a := by
  exact prepared_read (fixture old) (UInt256.ofNat index) b prebytes suffix [] [b] a rfl (by change raw.size < UInt256.size; decide +kernel)

example : scratchRead 2 .empty = b.toByteArray ++ a.toByteArray := by
  rw [scratch_model]
  simp only [actual_word_bytes]
  decide +kernel
example : scratchRead 3 .empty = a.toByteArray ++ b.toByteArray := by
  rw [scratch_model]
  simp only [actual_word_bytes]
  decide +kernel
example : scratchRead 2 ⟨#[9,8,7,6,5]⟩ = b.toByteArray ++ a.toByteArray := by
  rw [scratch_model]
  simp only [actual_word_bytes]
  decide +kernel
example : scratchRead 3 ⟨Array.replicate 128 77⟩ = a.toByteArray ++ b.toByteArray := by
  rw [scratch_model]
  simp only [actual_word_bytes]
  decide +kernel
example : (preparedStep (fixture ⟨Array.replicate 128 77⟩) (UInt256.ofNat 3) b (proofOffset prebytes [])).memory.data.getD 64 0 = 77 := by
  rw [prepared_memory _ _ _ prebytes suffix [] [b] a rfl (by decide +kernel)]
  decide +kernel
-- Wrong parity and a missing second store cannot produce the expected pair.
example : scratchRead 2 .empty ≠ a.toByteArray ++ b.toByteArray := by
  rw [scratch_model]
  simp only [actual_word_bytes]
  decide +kernel
example : ((fixture .empty).toMachineState.mstore (UInt256.ofNat 0) b).memory.size ≠ (scratchRead 2 .empty).size := by
  rw [scratch_model]
  change (b.toByteArray.write 0 ByteArray.empty 0 32).size ≠ (pairInput (UInt256.ofNat 2) b a).size
  rw [SszShaCallBytes.write32 _ _ (actual_word_size b), pair_size]
  simp [actual_word_size]

example : (sourceEnd prebytes 2).toNat = 67 := by decide +kernel
example : (proofOffset prebytes [] + UInt256.ofNat 32).toNat = 35 := by decide +kernel
example : (proofOffset prebytes [a] + UInt256.ofNat 32).toNat = 67 := by decide +kernel
example : proofOffset prebytes [] + UInt256.ofNat 32 < sourceEnd prebytes 2 := by decide +kernel
example : ¬ proofOffset prebytes [a] + UInt256.ofNat 32 < sourceEnd prebytes 2 := by decide +kernel
example : (sourceEnd prebytes 2).toNat ≠ prebytes.size + 2 := by decide +kernel
example : (proofOffset prebytes [] + UInt256.ofNat 31).toNat ≠ 35 := by decide +kernel
example : (UInt256.ofNat (UInt256.size-16) + UInt256.ofNat 32).toNat = 16 := by decide +kernel

private def errorTag (out : Except StepError StepResult) : Option StepError :=
  match out with | .error e => some e | .ok _ => none
-- Extra-item priority needs no calldata, gas, memory or hash-success premise.
example : errorTag (sourceStep 0 (default : EVM.State) (UInt256.ofNat 0) b (UInt256.ofNat 0) (UInt256.ofNat 0)) = some .extraItem := by
  rw [sourceStep_extra _ _ _ _ _ _ (by decide +kernel)]; rfl
example : errorTag (sourceStep 0 (default : EVM.State) (UInt256.ofNat 1) b (UInt256.ofNat 999) (UInt256.ofNat 0)) = some .extraItem := by
  rw [sourceStep_extra _ _ _ _ _ _ (by decide +kernel)]; rfl

-- Cold-account gas cap and depth rejection through the actual source driver.
-- PR278 retains the unchanged actual-SHA83 and zero/one-fuel regressions.
private def cold : EVM.State := { (default : EVM.State) with gasAvailable := UInt256.ofNat 2684 }
example : Ccallgas shaAddress shaAddress (UInt256.ofNat 0)
    (preparedStep cold (UInt256.ofNat 2) (UInt256.ofNat 0) (UInt256.ofNat 0)).gasAvailable
    (preparedStep cold (UInt256.ofNat 2) (UInt256.ofNat 0) (UInt256.ofNat 0)).accountMap
    (preparedStep cold (UInt256.ofNat 2) (UInt256.ofNat 0) (UInt256.ofNat 0)).toMachineState
    (preparedStep cold (UInt256.ofNat 2) (UInt256.ofNat 0) (UInt256.ofNat 0)).substate = 83 := by decide +kernel
example : errorTag (sourceStep 0 { cold with executionEnv := {cold.executionEnv with depth := 1024} }
    (UInt256.ofNat 2) (UInt256.ofNat 0) (UInt256.ofNat 0) (UInt256.ofNat 32)) = some .hashFailure := by
  change some StepError.hashFailure = some StepError.hashFailure
  rfl

#print axioms actual_word_bytes
#print axioms actual_word_decode
#print axioms actual_memory_decode
#print axioms actual_sibling
#print axioms prepared_memory
#print axioms prepared_call
#print axioms layout_continue
#print axioms sourceStep_success
#print axioms sourceStep_extra
#print axioms decode_width
end LidoSRv3.Tests.SszProofCalldataStepMutants
