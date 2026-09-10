import LidoSRv3.Audit.Source.SszShaCommitted

namespace LidoSRv3.Tests.SszShaCommittedMutants
open EvmYul EvmYul.EVM LidoSRv3.Audit.Source
open SszBlsComposition SszShaCommitted

private def sevenBytes : ByteArray := ⟨(Array.replicate 31 (0 : UInt8)).push 7⟩

private def memoryCase (words : Nat) : EVM.State :=
  { (default : EVM.State) with
    activeWords := UInt256.ofNat words
    memory := sevenBytes
    returnData := sevenBytes }

/-- A synthetic returned state isolates the remaining engine representation
obligation. This is not a real SHA execution or a reachable Solidity state. -/
theorem successful_guard_keeps_wrap : ∃ r : Result,
    finish (.ok (UInt256.ofNat 1,memoryCase (2^251))) = .ok r ∧
    r.digest = UInt256.ofNat 0 ∧ r.state.activeWords.toNat = 2^251 ∧
    r.state.returnData.size = 32 := by
  have hg : ¬ (UInt256.ofNat 1 = UInt256.ofNat 0 ∨ (memoryCase (2^251)).returnData.size ≠ 32) := by decide +kernel
  simp only [finish,hg,if_false]
  refine ⟨_,rfl,?_,?_,?_⟩
  · change ((memoryCase (2^251)).toMachineState.mload (UInt256.ofNat 0)).1 = UInt256.ofNat 0
    exact SszShaCallBytes.mload_wrap (memoryCase (2^251)).toMachineState rfl
  · decide +kernel
  · decide +kernel

-- Immediately below the extent-product wrap, the same copied word is read.
example : ((memoryCase (2^251-1)).toMachineState.mload (UInt256.ofNat 0)).1 =
    UInt256.ofNat 7 := by
  have hm : (memoryCase (2^251-1)).memory = sevenBytes ++ ByteArray.empty := by rfl
  have hv := SszShaCallBytes.mload32 (memoryCase (2^251-1)).toMachineState sevenBytes ByteArray.empty
    hm (by decide +kernel) (by decide +kernel) (by decide +kernel)
  rw [hv]
  decide +kernel
example : ((memoryCase (2^251)).toMachineState.mload (UInt256.ofNat 0)).1 =
    UInt256.ofNat 0 := SszShaCallBytes.mload_wrap _ rfl
example : (default : EVM.State).activeWords.toNat = 0 := rfl
example : (preparePair (default : EVM.State) (UInt256.ofNat 7) (UInt256.ofNat 9)).activeWords.toNat = 2 := by
  rw [prepared_words]
  decide +kernel

private def state : EVM.State :=
  {(default : EVM.State) with gasAvailable := UInt256.ofNat 1_000_000}
private def tooDeep : EVM.State := {state with executionEnv := {state.executionEnv with depth := 1024}}
private def lowGas : EVM.State := {state with gasAvailable := UInt256.ofNat 83}
private def tag (r : Except Error Result) : Option Error :=
  match r with | .ok _ => none | .error e => some e

-- Actual engine failures, not supplied fake SHA replies. No FFI call succeeds.
example : tag (pairRun 0 tooDeep (UInt256.ofNat 7) (UInt256.ofNat 9)) = some .sha256PrecompileFailed := rfl
example : tag (pairRun 0 lowGas (UInt256.ofNat 7) (UInt256.ofNat 9)) = some .sha256PrecompileFailed := by
  unfold pairRun pairCall SszShaCallMemory.callSha
  rw [EVM.call]
  simp only [show (UInt256.ofNat 0).toNat = 0 by decide +kernel,
    show (UInt256.ofNat 64).toNat = 64 by decide +kernel,prepared_read]
  rfl
example : tag (pubkeyRun 0 tooDeep (UInt256.ofNat 0) 47) = some .invalidPubkeyLength := rfl

#print axioms successful_guard_keeps_wrap
#print axioms merkle_success_digest
#print axioms run_success_computed_merkle
end LidoSRv3.Tests.SszShaCommittedMutants
