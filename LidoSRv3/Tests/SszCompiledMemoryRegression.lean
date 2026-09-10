import LidoSRv3.Audit.Source.SszCompiledMerkle

namespace LidoSRv3.Tests.SszCompiledMemoryRegression
open EvmYul EvmYul.EVM LidoSRv3.Audit.Source
open SszCompiledMemory SszCompiledConsumer SszCompiledMerkle
private abbrev w (n : Nat) := UInt256.ofNat n

private def poisoned : EVM.State :=
  {(default : EVM.State) with activeWords := w (2^251), memory := ⟨#[255,254,253]⟩}

/-- The caller's wrapping memory extent and dirty scratch do not survive the
same fresh initializer used by EVM.Ξ and the source consumer. -/
theorem fresh_discards_poison :
    (fresh poisoned).memory = ByteArray.empty ∧
    (prologue poisoned).activeWords.toNat = 3 ∧
    (load (prologue poisoned) 64).1 = w 128 :=
  ⟨rfl,prologue_words _,prologue_free_pointer _⟩

private def allocateAndStore : Except AllocationError (List Nat) := do
  let (ptr,st) ← allocate (prologue poisoned) 256
  let st := store st ptr.toNat (w 123)
  let (next,st) ← allocate st 128
  pure [ptr.toNat,next.toNat,(load st 64).1.toNat,(load st 128).1.toNat]

/-- Two actual allocations preserve the key stored between them while the
free pointer advances. The observed values are independent fixture constants. -/
theorem allocation_keeps_prior_key : allocateAndStore = .ok [128,384,512,123] := by
  obtain ⟨first,a0,f0,w0,e0,k0⟩ := allocate_frame (prologue poisoned) 128 256
    (prologue_free_pointer _) (by omega) (by omega) (by omega)
    (by rw [prologue_words]) (by rw [prologue_words];omega)
  let keyed := store first 128 (w 123)
  have free : Stored keyed 64 (w 384) := stored_preserved _ _ _ _ _ f0 (by omega) (by omega)
  have key : Stored keyed 128 (w 123) := stored_written _ _ _ (by omega)
  have bound : keyed.activeWords.toNat ≤ 20 := store_bounded _ _ _ (by omega) w0
  have low : 3 ≤ keyed.activeWords.toNat := by have := free.2.2;omega
  obtain ⟨second,a1,f1,w1,e1,k1⟩ := allocate_frame keyed 384 128
    (stored_load _ _ _ free (by omega) bound) (by omega) (by omega) (by omega) low bound
  have value := k1 128 (w 123) key (by omega) (by omega)
  have observedFree := stored_load _ _ _ f1 (by omega) w1
  have observedKey := stored_load _ _ _ value (by omega) w1
  unfold allocateAndStore
  rw [a0]
  dsimp only [bind,Except.bind]
  change (allocate keyed 128 >>= fun pair => pure
    [128,pair.1.toNat,(load pair.2 64).1.toNat,(load pair.2 128).1.toNat]) = _
  rw [a1]
  dsimp only [bind,Except.bind]
  rw [observedFree,observedKey]
  rfl

#print axioms fresh_discards_poison
#print axioms allocation_keeps_prior_key
end LidoSRv3.Tests.SszCompiledMemoryRegression
