import LidoSRv3.Audit.Source.TopupPointerOrigin

/-!
Derived module cursor for the TOPUP sequential decode.

`TopupRouterLocatorCall.run` already threads locator `next` into the
credentials cursor. `returnBuffer` is still a later phase input. This file
supplies the missing sequential decoder: the module copy cursor is
`credentials.next`, not a caller-supplied `Word`.

The public `run` functions are not edited. This is not a derivation of
`PTopupMemoryCalls` / `PTopupRouterLocatorCall` cursors, and not a
`guarantees.yaml` close.
-/
set_option autoImplicit false
namespace LidoSRv3.Audit.Source.TopupReturnBuffer

open TrioReserve1 Live
open LidoSRv3.Audit.Source.TopupPointerOrigin
open audit.trio.deposit.ModuleCall (finalizeAllocation)

/-- Module `decodeReturn` at the credentials allocator's next pointer.
`returnBuffer` is not an input. -/
def decodeReturnAtCredentialsNext (credCursor : Word) (rawCred rawMod : Bytes) :
    Except Fault (Word × Word × List Word × Word) :=
  match TopupCredentialCall.decodeCredentials credCursor rawCred with
  | .error f => .error f
  | .ok (wc, credNext) =>
    match TopupModuleMemory.decodeReturn credNext rawMod with
    | .error f => .error f
    | .ok (xs, next) => .ok (wc, credNext, xs, next)

/-- Locator 32-byte copy, then credentials at `locNext`, then module at
`credNext`. Matches the public locator→credentials thread plus the derived
module cursor. -/
def decodeReturnAfterLocator (locCursor : Word) (rawLoc rawCred rawMod : Bytes) :
    Except Fault (Word × Word × Word × Word × List Word × Word) :=
  match TopupCredentialCall.decodeCredentials locCursor rawLoc with
  | .error f => .error f
  | .ok (locWord, locNext) =>
    match decodeReturnAtCredentialsNext locNext rawCred rawMod with
    | .error f => .error f
    | .ok (wc, credNext, xs, next) => .ok (locWord, locNext, wc, credNext, xs, next)

/-- Wrapper success is exactly credentials success plus module success at
`credentials.next`. The module cursor is recovered, not supplied. -/
theorem decodeReturnAtCredentialsNext_ok
    (credCursor : Word) (rawCred rawMod : Bytes)
    (wc credNext : Word) (xs : List Word) (next : Word)
    (h : decodeReturnAtCredentialsNext credCursor rawCred rawMod =
      .ok (wc, credNext, xs, next)) :
    TopupCredentialCall.decodeCredentials credCursor rawCred = .ok (wc, credNext) ∧
      TopupModuleMemory.decodeReturn credNext rawMod = .ok (xs, next) := by
  unfold decodeReturnAtCredentialsNext at h
  cases hc : TopupCredentialCall.decodeCredentials credCursor rawCred with
  | «error» f => simp [hc] at h
  | ok pair =>
    rcases pair with ⟨wc', credNext'⟩
    simp only [hc] at h
    cases hm : TopupModuleMemory.decodeReturn credNext' rawMod with
    | «error» f => simp [hm] at h
    | ok pair =>
      rcases pair with ⟨xs', next'⟩
      simp only [hm] at h
      injection h with heq
      cases heq
      exact ⟨rfl, hm⟩

/-- Sequential credentials then module on the *derived* cursor. No
`returnBuffer = credNext` hypothesis: the wrapper does not take
`returnBuffer`. -/
theorem decodeReturnAtCredentialsNext_disjoint
    (credCursor : Word) (rawCred rawMod : Bytes)
    (wc credNext : Word) (xs : List Word) (next : Word)
    (h : decodeReturnAtCredentialsNext credCursor rawCred rawMod =
      .ok (wc, credNext, xs, next)) :
    ∃ postRaw : Word,
      finalizeAllocation credNext (word rawMod.length).val = .ok postRaw ∧
        Disjoint (scalar32 credCursor credNext)
          (ofAllocation credNext (word rawMod.length).val postRaw) ∧
        (scalar32 credCursor credNext).valid ∧
        (scalar32 credCursor credNext).next = credCursor.val + 32 ∧
        (scalar32 credCursor credNext).next = credNext.val := by
  obtain ⟨hc, hm⟩ := decodeReturnAtCredentialsNext_ok credCursor rawCred rawMod
    wc credNext xs next h
  exact chained_credential_then_module_disjoint credCursor credNext credNext next
    rawCred rawMod wc xs hc hm rfl

theorem decodeReturnAfterLocator_ok
    (locCursor : Word) (rawLoc rawCred rawMod : Bytes)
    (locWord locNext wc credNext : Word) (xs : List Word) (next : Word)
    (h : decodeReturnAfterLocator locCursor rawLoc rawCred rawMod =
      .ok (locWord, locNext, wc, credNext, xs, next)) :
    TopupCredentialCall.decodeCredentials locCursor rawLoc = .ok (locWord, locNext) ∧
      decodeReturnAtCredentialsNext locNext rawCred rawMod =
        .ok (wc, credNext, xs, next) := by
  unfold decodeReturnAfterLocator at h
  cases hl : TopupCredentialCall.decodeCredentials locCursor rawLoc with
  | «error» f => simp [hl] at h
  | ok pair =>
    rcases pair with ⟨locWord', locNext'⟩
    simp only [hl] at h
    cases hm : decodeReturnAtCredentialsNext locNext' rawCred rawMod with
    | «error» f => simp [hm] at h
    | ok pair =>
      rcases pair with ⟨wc', credNext', xs', next'⟩
      simp only [hm] at h
      injection h with heq
      cases heq
      exact ⟨rfl, hm⟩

/-- Locator→credentials (already in the public run) plus the derived module
cursor. Pairwise sequential, no `hchain`. -/
theorem decodeReturnAfterLocator_disjoint
    (locCursor : Word) (rawLoc rawCred rawMod : Bytes)
    (locWord locNext wc credNext : Word) (xs : List Word) (next : Word)
    (h : decodeReturnAfterLocator locCursor rawLoc rawCred rawMod =
      .ok (locWord, locNext, wc, credNext, xs, next)) :
    Disjoint (scalar32 locCursor locNext) (scalar32 locNext credNext) ∧
      ∃ postRaw : Word,
        finalizeAllocation credNext (word rawMod.length).val = .ok postRaw ∧
          Disjoint (scalar32 locNext credNext)
            (ofAllocation credNext (word rawMod.length).val postRaw) := by
  obtain ⟨hl, hm⟩ := decodeReturnAfterLocator_ok locCursor rawLoc rawCred rawMod
    locWord locNext wc credNext xs next h
  obtain ⟨hc, hmod⟩ := decodeReturnAtCredentialsNext_ok locNext rawCred rawMod
    wc credNext xs next hm
  have hloc := (credentials_zone locCursor locWord locNext rawLoc hl).1
  exact chained_locator_credential_module_disjoint locCursor locNext credNext
    credNext next rawCred rawMod wc xs hloc hc hmod rfl

#print axioms decodeReturnAtCredentialsNext_ok
#print axioms decodeReturnAtCredentialsNext_disjoint
#print axioms decodeReturnAfterLocator_ok
#print axioms decodeReturnAfterLocator_disjoint

end LidoSRv3.Audit.Source.TopupReturnBuffer
