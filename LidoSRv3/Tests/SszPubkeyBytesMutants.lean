import LidoSRv3.Audit.Source.SszPubkeyBytes

namespace LidoSRv3.Tests.SszPubkeyBytesMutants
open EvmYul EvmYul.EVM LidoSRv3.Audit.Source
open SszPubkeyBytes SszScratchEvmMemory SszScratchByteArray

private def state (raw : ByteArray) : EVM.State :=
  {(default : EVM.State) with
    memory := ⟨Array.replicate 96 255⟩
    executionEnv := {(default : EVM.State).executionEnv with calldata := raw}}
private def raw47 : ByteArray := ⟨Array.replicate 47 7⟩
private def raw48 : ByteArray := ⟨Array.replicate 48 7⟩

/-- Actual scratch overwrites a dirty missing 48th key byte and zero suffix. -/
theorem truncated_copy_zero_extends :
    (scratch (state raw47).toSharedState (UInt256.ofNat 0)).memory.readWithPadding 0 64 =
      (⟨Array.replicate 47 7 ++ Array.replicate 17 0⟩ : ByteArray) := by
  rw [SszPubkeyBytes.read_exact]
  decide +kernel

/-- An arbitrary out-of-range source offset clears the entire scratch block,
while the real memory beyond it remains dirty and unchanged. -/
theorem absent_copy_frames_tail :
    (scratch (state raw47).toSharedState (UInt256.ofNat (2^256-1))).memory =
      (⟨Array.replicate 64 0 ++ Array.replicate 32 255⟩ : ByteArray) := by
  rw [SszPubkeyBytes.memory_exact]
  decide +kernel

/-- A mutation retaining dirty memory for the short key disagrees with the
actual copy, even though both buffers have the same length. -/
theorem dirty_padding_mutant_killed :
    (scratch (state raw47).toSharedState (UInt256.ofNat 0)).memory.readWithPadding 0 64 ≠
      (⟨Array.replicate 47 7 ++ #[255] ++ Array.replicate 16 0⟩ : ByteArray) := by
  rw [truncated_copy_zero_extends]
  decide +kernel

example : keyBytes raw47 47 = zeros 48 := by decide +kernel
example : keyBytes raw47 46 = (⟨#[7] ++ Array.replicate 47 0⟩ : ByteArray) := by decide +kernel
example : keyBytes raw48 0 = raw48 := by decide +kernel
example : blockBytes raw48 0 = rawBlock raw48 0 := block_eq_raw _ _ (by decide +kernel)
example : keyBytes ByteArray.empty (2^256-1) = zeros 48 := by decide +kernel
example : (scratch (state raw47).toSharedState (UInt256.ofNat 0)).memory.data.getD 64 0 = 255 := by
  rw [SszPubkeyBytes.memory_exact]
  decide +kernel

#print axioms truncated_copy_zero_extends
#print axioms absent_copy_frames_tail
#print axioms dirty_padding_mutant_killed
#print axioms run_success_computed_leaf
end LidoSRv3.Tests.SszPubkeyBytesMutants
