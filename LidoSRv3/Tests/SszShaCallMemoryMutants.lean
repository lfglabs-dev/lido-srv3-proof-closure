import LidoSRv3.Audit.Source.SszShaCallMemory

set_option maxRecDepth 4096
set_option maxHeartbeats 400000

namespace LidoSRv3.Tests.SszShaCallMemoryMutants
open EvmYul EvmYul.EVM
open LidoSRv3.Audit.Source
open SszShaCallMemory SszScratchByteArray

/-- Actual precompile 4: short-return tests exercise CALL's own output writer. -/
def identityCall (n : Nat) :=
  EVM.call 2 0 [] (UInt256.ofNat 1000) (UInt256.ofNat 0)
    (UInt256.ofNat 4) (UInt256.ofNat 4) (UInt256.ofNat 0) (UInt256.ofNat 0)
    (UInt256.ofNat 64) (UInt256.ofNat n) (UInt256.ofNat 0) (UInt256.ofNat 32) false
    ({ (default : EVM.State) with
      gasAvailable := UInt256.ofNat 100000
      memory := zeros 64 ++ ⟨Array.replicate n 9⟩ })

def observed (outcome : Except ExecutionException (UInt256 × EVM.State)) :
    Option (Nat × ByteArray × ByteArray) :=
  match outcome with
  | .error _ => none
  | .ok (flag, st) => some (flag.toNat, st.returnData, st.memory.readWithPadding 0 32)

-- Success with no returndata leaves the old output window untouched.
example : observed (identityCall 0) = some (1, .empty, zeros 32) := by
  simp only [identityCall, EVM.call]
  simp only [show (UInt256.ofNat 64).toNat = 64 by decide +kernel,
    show (UInt256.ofNat 0).toNat = 0 by decide +kernel]
  rw [SszShaCallBytes.read_fit _ 64 0 (by decide +kernel) (by omega)]
  change some (1, ByteArray.empty,
    (zeros 64 ++ (⟨Array.replicate 0 9⟩ : ByteArray)).readWithPadding 0 32) = _
  rw [SszShaCallBytes.read_fit _ 0 32 (by decide +kernel) (by omega)]
  decide +kernel

-- Actual 31-byte identity reply, capped output copy of 31 bytes.
example : observed (identityCall 31) =
    some (1, ⟨Array.replicate 31 9⟩, ⟨Array.replicate 31 9 ++ #[0]⟩) := by
  simp only [identityCall, EVM.call]
  simp only [show (UInt256.ofNat 64).toNat = 64 by decide +kernel,
    show (UInt256.ofNat 31).toNat = 31 by decide +kernel]
  rw [SszShaCallBytes.read_fit _ 64 31 (by decide +kernel) (by omega)]
  change some (1, (⟨Array.replicate 31 9⟩ : ByteArray),
    ((⟨Array.replicate 31 9⟩ : ByteArray).write 0
      (zeros 64 ++ ⟨Array.replicate 31 9⟩) 0 31).readWithPadding 0 32) = _
  have hw : (⟨Array.replicate 31 9⟩ : ByteArray).write 0
      (zeros 64 ++ ⟨Array.replicate 31 9⟩) 0 31 =
      ⟨Array.replicate 31 9 ++ Array.replicate 33 0 ++ Array.replicate 31 9⟩ := by
    apply ByteArray.ext
    rw [write_fit _ _ 0 0 31 (by omega) (by decide +kernel) (by omega)]
    decide +kernel
  rw [hw, SszShaCallBytes.read_fit _ 0 32 (by decide +kernel) (by omega)]
  decide +kernel

-- Actual 32-byte identity reply, capped output copy of 32 bytes.
example : observed (identityCall 32) =
    some (1, ⟨Array.replicate 32 9⟩, ⟨Array.replicate 32 9⟩) := by
  simp only [identityCall, EVM.call]
  simp only [show (UInt256.ofNat 64).toNat = 64 by decide +kernel,
    show (UInt256.ofNat 32).toNat = 32 by decide +kernel]
  rw [SszShaCallBytes.read_fit _ 64 32 (by decide +kernel) (by omega)]
  change some (1, (⟨Array.replicate 32 9⟩ : ByteArray),
    ((⟨Array.replicate 32 9⟩ : ByteArray).write 0
      (zeros 64 ++ ⟨Array.replicate 32 9⟩) 0 32).readWithPadding 0 32) = _
  have hw : (⟨Array.replicate 32 9⟩ : ByteArray).write 0
      (zeros 64 ++ ⟨Array.replicate 32 9⟩) 0 32 =
      ⟨Array.replicate 32 9 ++ Array.replicate 32 0 ++ Array.replicate 32 9⟩ := by
    apply ByteArray.ext
    rw [write_fit _ _ 0 0 32 (by omega) (by decide +kernel) (by omega)]
    decide +kernel
  rw [hw, SszShaCallBytes.read_fit _ 0 32 (by decide +kernel) (by omega)]
  decide +kernel

-- Actual 33-byte identity reply, capped output copy of 32 bytes.
example : observed (identityCall 33) =
    some (1, ⟨Array.replicate 33 9⟩, ⟨Array.replicate 32 9⟩) := by
  simp only [identityCall, EVM.call]
  simp only [show (UInt256.ofNat 64).toNat = 64 by decide +kernel,
    show (UInt256.ofNat 33).toNat = 33 by decide +kernel]
  rw [SszShaCallBytes.read_fit _ 64 33 (by decide +kernel) (by omega)]
  change some (1, (⟨Array.replicate 33 9⟩ : ByteArray),
    ((⟨Array.replicate 33 9⟩ : ByteArray).write 0
      (zeros 64 ++ ⟨Array.replicate 33 9⟩) 0 32).readWithPadding 0 32) = _
  have hw : (⟨Array.replicate 33 9⟩ : ByteArray).write 0
      (zeros 64 ++ ⟨Array.replicate 33 9⟩) 0 32 =
      ⟨Array.replicate 32 9 ++ Array.replicate 32 0 ++ Array.replicate 33 9⟩ := by
    apply ByteArray.ext
    rw [write_fit _ _ 0 0 32 (by omega) (by decide +kernel) (by omega)]
    decide +kernel
  rw [hw, SszShaCallBytes.read_fit _ 0 32 (by decide +kernel) (by omega)]
  decide +kernel

/-- A dirty64-byte input/window and real gas budget; no SHA mock. -/
def dirtyState : EVM.State :=
  { (default : EVM.State) with
    gasAvailable := UInt256.ofNat 100000
    memory := ⟨Array.replicate 64 7⟩
    activeWords := UInt256.ofNat 2 }

-- Below the exact64-byte SHA fee, the real precompile rejects without copying.
example : observed (callSha 2 0 (UInt256.ofNat 0) (UInt256.ofNat 83) dirtyState) =
    some (0, .empty, ⟨Array.replicate 32 7⟩) := by
  simp only [callSha, EVM.call]
  simp only [show (UInt256.ofNat 0).toNat = 0 by decide +kernel,
    show (UInt256.ofNat 64).toNat = 64 by decide +kernel]
  rw [SszShaCallBytes.read_fit _ 0 64 (by decide +kernel) (by omega)]
  change some (0, ByteArray.empty,
    (⟨Array.replicate 64 7⟩ : ByteArray).readWithPadding 0 32) = _
  rw [SszShaCallBytes.read_fit _ 0 32 (by decide +kernel) (by omega)]
  decide +kernel
-- Sufficient CALL recursion must still leave fuel for Theta.
example : observed (callSha 1 0 (UInt256.ofNat 0) (UInt256.ofNat 1000) dirtyState) = none := by
  decide +kernel
example : observed (callSha 0 0 (UInt256.ofNat 0) (UInt256.ofNat 1000) dirtyState) = none := by
  decide +kernel
-- Depth admission precedes the callee, and leaves the output window untouched.
example : observed (callSha 2 0 (UInt256.ofNat 0) (UInt256.ofNat 1000)
    { dirtyState with executionEnv := { dirtyState.executionEnv with depth := 1024 } }) =
    some (0, .empty, ⟨Array.replicate 32 7⟩) := by
  change some (0, ByteArray.empty,
    (⟨Array.replicate 64 7⟩ : ByteArray).readWithPadding 0 32) = _
  rw [SszShaCallBytes.read_fit _ 0 32 (by decide +kernel) (by omega)]
  decide +kernel

-- Explicit nonzero memory witness for the activeWords multiplication wrap.
example : (({ dirtyState.toMachineState with activeWords := UInt256.ofNat (2^251) }
    : MachineState).mload (UInt256.ofNat 0)).1 = UInt256.ofNat 0 := by
  exact SszShaCallBytes.mload_wrap _ rfl
example : UInt256.ofNat (fromByteArrayBigEndian (⟨Array.replicate 32 7⟩ : ByteArray)) ≠
    UInt256.ofNat 0 := by decide +kernel

#print axioms SszShaCallMemory.bls_call_success
#print axioms SszShaCallMemory.gas_fits
#print axioms SszShaCallMemory.theta_sha
#print axioms SszShaCallMemory.call_sha_bytes
#print axioms SszShaCallMemory.prepared_words
#print axioms SszShaCallMemory.scratch_call_bytes
#print axioms SszShaCallMemory.scratch_call_mload
#print axioms SszShaCallBytes.mload32
#print axioms SszShaCallBytes.mload_wrap

end LidoSRv3.Tests.SszShaCallMemoryMutants
