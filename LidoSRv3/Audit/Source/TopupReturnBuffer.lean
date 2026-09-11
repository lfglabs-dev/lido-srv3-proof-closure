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
    Except Fault (Word × Word × Word × List Word × Word) :=
  match TopupCredentialCall.decodeCredentials locCursor rawLoc with
  | .error f => .error f
  | .ok (locWord, locNext) =>
    match decodeReturnAtCredentialsNext locNext rawCred rawMod with
    | .error f => .error f
    | .ok (wc, credNext, xs, next) => .ok (locWord, locNext, wc, credNext, xs, next)

end LidoSRv3.Audit.Source.TopupReturnBuffer
