import LidoSRv3.Audit.Source.TopupReturnBuffer
import LidoSRv3.Tests.TopupPointerOriginMutants

/-! Concrete witnesses for the derived `returnBuffer = credentials.next`
decoder. No always-success stub, no renamed TOPUP premise. -/
set_option autoImplicit false
namespace LidoSRv3.Tests.TopupReturnBufferMutants

open TrioReserve1 Live
open LidoSRv3.Audit.Source.TopupPointerOrigin
open LidoSRv3.Audit.Source.TopupReturnBuffer
open LidoSRv3.Tests.TopupPointerOriginMutants
open audit.trio.deposit.ModuleCall (finalizeAllocation)

/-- Credentials @ 128 then module @ the derived 160. -/
theorem decode_at_credentials_next_128 :
    decodeReturnAtCredentialsNext (word 128) credRaw moduleRaw =
      .ok (credWord, word 160, [word 1, word 9], word 384) := by
  native_decide

theorem decode_at_credentials_next_disjoint_128 :
    ∃ postRaw,
      finalizeAllocation (word 160) (word moduleRaw.length).val = .ok postRaw ∧
        Disjoint (scalar32 (word 128) (word 160))
          (ofAllocation (word 160) (word moduleRaw.length).val postRaw) := by
  have hex := decodeReturnAtCredentialsNext_disjoint (word 128) credRaw moduleRaw
    credWord (word 160) [word 1, word 9] (word 384) decode_at_credentials_next_128
  rcases hex with ⟨postRaw, ha, hd, _⟩
  exact ⟨postRaw, ha, hd⟩

/-- Locator word that fits the 160-bit guard, then credentials, then module
at the derived cursor. Locator raw is a 32-byte address word. -/
def locWord : Word := word 0xabc
def locRaw : Bytes := encode 32 locWord.val

theorem locator_at_128 :
    TopupCredentialCall.decodeCredentials (word 128) locRaw =
      .ok (locWord, word 160) := by
  decide +kernel

theorem decode_after_locator_128 :
    decodeReturnAfterLocator (word 128) locRaw credRaw moduleRaw =
      .ok (locWord, word 160, credWord, word 192, [word 1, word 9], word 416) := by
  native_decide

theorem decode_after_locator_disjoint_128 :
    Disjoint (scalar32 (word 128) (word 160)) (scalar32 (word 160) (word 192)) ∧
      ∃ postRaw,
        finalizeAllocation (word 192) (word moduleRaw.length).val = .ok postRaw ∧
          Disjoint (scalar32 (word 160) (word 192))
            (ofAllocation (word 192) (word moduleRaw.length).val postRaw) :=
  decodeReturnAfterLocator_disjoint (word 128) locRaw credRaw moduleRaw
    locWord (word 160) credWord (word 192) [word 1, word 9] (word 416)
    decode_after_locator_128

/-- The public independently-supplied `returnBuffer = 128` path is *not*
this wrapper: that decode still succeeds and aliases the locator zone. -/
theorem public_returnBuffer_is_not_the_wrapper :
    decodeReturnAtCredentialsNext (word 128) credRaw moduleRaw =
      .ok (credWord, word 160, [word 1, word 9], word 384) ∧
      TopupModuleMemory.decodeReturn (word 128) moduleRaw =
        .ok ([word 1, word 9], word 352) ∧
      ¬ Disjoint (scalar32 (word 128) (word 160))
          (ofAllocation (word 128) (word moduleRaw.length).val (word 256)) :=
  ⟨decode_at_credentials_next_128, module_at_128, existing_topup_cursors_alias.2.2⟩

#print axioms decode_at_credentials_next_128
#print axioms decode_at_credentials_next_disjoint_128
#print axioms decode_after_locator_disjoint_128
#print axioms public_returnBuffer_is_not_the_wrapper

end LidoSRv3.Tests.TopupReturnBufferMutants
