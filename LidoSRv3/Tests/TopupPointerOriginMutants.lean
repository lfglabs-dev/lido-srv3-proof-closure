import LidoSRv3.Audit.Source.TopupPointerOrigin

/-! Concrete witnesses and kill-lines for TOPUP pointer-origin / aliasing.
Decoder-only: no always-success stub, no renamed TOPUP premise. -/
set_option autoImplicit false
namespace LidoSRv3.Tests.TopupPointerOriginMutants
open Audit.Source TrioReserve1 Live
open TopupPointerOrigin
open audit.trio.deposit.ModuleCall (finalizeAllocation)

def credWord : Word := word (2 * 2 ^ 248 + 12345)
def credRaw : Bytes := encode 32 credWord.val
def moduleRaw : Bytes := TopupModuleCall.encodeReturn [word 1, word 9]

theorem credentials_at_128 :
    TopupCredentialCall.decodeCredentials (word 128) credRaw = .ok (credWord, word 160) := by
  decide +kernel

theorem module_at_128 :
    TopupModuleMemory.decodeReturn (word 128) moduleRaw = .ok ([word 1, word 9], word 352) := by
  decide +kernel

/-- Locator `stakingRouter()` return is a canonical-160 address, not a 0x02 WC. -/
theorem locator_word_fits_160 :
    (word 0xabc).val < 2 ^ 160 := by decide

/-- Sequential locator-then-credentials allocations at the chained cursor
used by `TopupRouterLocatorCall` (`next` of the locator is the getter cursor). -/
theorem chained_128_then_160_disjoint :
    finalizeAllocation (word 128) 32 = .ok (word 160) ∧
      finalizeAllocation (word 160) 32 = .ok (word 192) ∧
      Disjoint (scalar32 (word 128) (word 160)) (scalar32 (word 160) (word 192)) := by
  have h1 : finalizeAllocation (word 128) 32 = .ok (word 160) := by decide +kernel
  have h2 : finalizeAllocation (word 160) 32 = .ok (word 192) := by decide +kernel
  exact ⟨h1, h2, (chained_scalar32_disjoint (word 128) (word 160) (word 192) h1 h2).1⟩

/-- Module raw zone `[128,256)` and array zone `[256,352)` on the canonical
two-word `allocateDeposits` return (`StakingRouter.sol:717–719`). -/
theorem module_sequential_zones_at_128 :
    ∃ postRaw,
      finalizeAllocation (word 128) (word moduleRaw.length).val = .ok postRaw ∧
        postRaw = word 256 ∧
        Disjoint (ofAllocation (word 128) (word moduleRaw.length).val postRaw)
          (ofAllocation postRaw 96 (word 352)) := by
  refine ⟨word 256, by decide +kernel, rfl, ?_⟩
  exact sequential_disjoint _ _ rfl

/-- Existing TOPUP tests use `credentialCursor = returnBuffer = 128`.
Both decoders succeed and the zones overlap: `[128,160)` vs `[128,256)`. -/
theorem existing_topup_cursors_alias :
    TopupCredentialCall.decodeCredentials (word 128) credRaw = .ok (credWord, word 160) ∧
      TopupModuleMemory.decodeReturn (word 128) moduleRaw = .ok ([word 1, word 9], word 352) ∧
      ¬ Disjoint (scalar32 (word 128) (word 160))
          (ofAllocation (word 128) (word moduleRaw.length).val (word 256)) := by
  refine ⟨credentials_at_128, module_at_128, ?_⟩
  intro h
  cases h with
  | inl hle =>
    have : ¬ (160 : Nat) ≤ 128 := by decide
    exact this hle
  | inr hle =>
    have : ¬ (256 : Nat) ≤ 128 := by decide
    exact this hle

/-- Instantiation of the exported alias theorem on that witness. -/
theorem same_cursor_alias_instance :
    ∃ postRaw, ¬ Disjoint (scalar32 (word 128) (word 160))
        (ofAllocation (word 128) (word moduleRaw.length).val postRaw) :=
  same_cursor_successful_decodes_alias (word 128) (word 160) (word 352) credRaw moduleRaw
    credWord [word 1, word 9] credentials_at_128 module_at_128

/-- Kill-line: the universal claim “any pair of successful same-execution
credential and module decodes has disjoint zones” is false. This is the
unexcluded alias that existing TOPUP `run_success` premises do not rule out. -/
theorem independent_cursor_alias_refutes_global_nonalias :
    ¬ (∀ (cursor nextCred nextMod : Word) (rawCred rawMod : Bytes) (wc : Word)
        (xs : List Word) (postRaw : Word),
        TopupCredentialCall.decodeCredentials cursor rawCred = .ok (wc, nextCred) →
        TopupModuleMemory.decodeReturn cursor rawMod = .ok (xs, nextMod) →
        finalizeAllocation cursor (word rawMod.length).val = .ok postRaw →
        Disjoint (scalar32 cursor nextCred)
          (ofAllocation cursor (word rawMod.length).val postRaw)) := by
  intro h
  have ha : finalizeAllocation (word 128) (word moduleRaw.length).val = .ok (word 256) := by
    decide +kernel
  exact existing_topup_cursors_alias.2.2
    (h (word 128) (word 160) (word 352) credRaw moduleRaw credWord
      [word 1, word 9] (word 256) credentials_at_128 module_at_128 ha)

/-- `mstore(64)` slot is a legal credentials cursor. -/
theorem free_memory_pointer_slot_admitted :
    TopupCredentialCall.decodeCredentials (word 64) credRaw = .ok (credWord, word 96) ∧
      finalizeAllocation (word 64) 32 = .ok (word 96) := by
  decide +kernel

#print axioms locator_word_fits_160
#print axioms credentials_at_128
#print axioms module_at_128
#print axioms chained_128_then_160_disjoint
#print axioms module_sequential_zones_at_128
#print axioms existing_topup_cursors_alias
#print axioms same_cursor_alias_instance
#print axioms independent_cursor_alias_refutes_global_nonalias
#print axioms free_memory_pointer_slot_admitted
end LidoSRv3.Tests.TopupPointerOriginMutants
