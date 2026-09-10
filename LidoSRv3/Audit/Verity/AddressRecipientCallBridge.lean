import LidoSRv3.Audit.Verity.AddressClaimBatchTx
import LidoSRv3.Audit.Source.TrioReserve1.Live

/-!
# P-ADDRESS-1 recipient CALL bridge

`AddressClaimBatchTx.claimOne` is the storage-accurate, pinned
`claimWithdrawalsTo` iteration.  Its `externalCallBindTo` frame fixes the
actual target and value in the executable Verity receipt, but that primitive
has only a caller state.  This bridge supplies the missing callee-world step:
the same recipient and value are passed to the project-wide live CALL
interpreter, whose result contains both caller and callee effects.  A rejected
callee is not an input flag; `Live.run` restores the complete entry world.

The bridge intentionally starts with the smallest address-bearing call edge.
The other entrypoint work must use this boundary rather than add another
boolean success parameter or an observation-only recipient slot.
-/

namespace LidoSRv3.Audit.Verity.AddressRecipientCallBridge

open _root_.Verity
open _root_.Verity.EVM.Uint256
open Contracts
open LidoSRv3.Audit.Verity.AddressClaimBatchTx
open LidoSRv3.Audit.Source.TrioReserve1.Live

abbrev World := LidoSRv3.Audit.Source.TrioReserve1.Live.World
abbrev Context := LidoSRv3.Audit.Source.TrioReserve1.Live.Context
abbrev External := LidoSRv3.Audit.Source.TrioReserve1.Live.External
abbrev Exec := LidoSRv3.Audit.Source.TrioReserve1.Live.Exec

/-- Lift the pinned storage transition into the whole-world interpreter.  The
state supplied to `claimOne` receives the live transaction sender; every
queue/checkpoint read and the claimed/locked write therefore remains on the
physical channels used by `AddressClaimBatchTx`. -/
def claimStorage (ctx : Context) (requestId hint : Nat) (recipient : Address) :
    Exec Nat := fun world =>
  let before := { world.core with sender := ctx.sender }
  let request := readRequest before requestId hint
  match claimableEther request with
  | none => ⟨.error (.reason "ZeroShares"), world, []⟩
  | some payout =>
      match claimOne requestId hint recipient before with
      | .success _ after => ⟨.ok payout, { world with core := after }, []⟩
      | .revert reason _ => ⟨.error (.reason reason), world, []⟩

/-- Exact `WithdrawalQueueBase._sendValue` call frame (lines 475--480): it is
an EVM `CALL` to the recipient with value and **empty** calldata.  The generic
`Live.call` helper encodes a four-byte selector, so using it here would silently
change the real call target's input.  Rejection restores the value transfer;
success returns the callee's entire resulting world. -/
def emptyValueCall (external : External) (ctx : Context) (recipient : Address)
    (payout : Nat) : Exec Unit := fun world =>
  let value : Uint256 := .ofNat payout
  let request : Request := ⟨ctx.self, recipient, value, []⟩
  if (world.core.codeSize recipient.val).val = 0 then
    ⟨.error .empty, world, []⟩
  else if world.balances ctx.self < value.val then
    ⟨.error (.bubbled []), world, [⟨request, false, [], []⟩]⟩
  else
    match external request (transfer world ctx.self recipient value.val) with
    | .rejected data => ⟨.error (.bubbled data), world, [⟨request, false, data, []⟩]⟩
    | .success data after => ⟨.ok (), after, [⟨request, true, data, []⟩]⟩
    | .successWithTrace data after nested => ⟨.ok (), after, [⟨request, true, data, nested⟩]⟩
    | .rejectedWithTrace data nested =>
        ⟨.error (.bubbled data), world, [⟨request, false, data, nested⟩]⟩

/-- The recipient is the CALL target, not a post-hoc observation. -/
def payoutCall (external : External) (ctx : Context) (recipient : Address)
    (payout : Nat) : Exec Unit :=
  emptyValueCall external ctx recipient payout

/-- One physical `_claim` followed by its value-bearing recipient CALL.  The
two layers have distinct jobs: `claimOne` fixes Solidity storage and its
`externalCallBindTo` receipt; `payoutCall` executes that same frame against a
callee that may accept, reject, or change its own world. -/
def claimTo (external : External) (ctx : Context) (requestId hint : Nat)
    (recipient : Address) : Exec Unit := do
  let payout ← claimStorage ctx requestId hint recipient
  payoutCall external ctx recipient payout

def runClaimTo (external : External) (ctx : Context) (requestId hint : Nat)
    (recipient : Address) (before : World) :=
  run (claimTo external ctx requestId hint recipient) before

/-! ## `transferFrom` owner-operated physical branch

The live Solidity function also admits the two approval branches.  This bridge
contains the owner-operated branch, which is the branch shared with the
existing `AddressTransferTx` source slice: authorization is read from
`ctx.sender`, never injected as an approval Boolean.  It updates precisely the
low 160-bit `owner` field of the same `QUEUE_POSITION` metadata word used by
`claimOne`; timestamp, claimed byte, and report timestamp are retained. -/

/-- Replace only `WithdrawalRequest.owner`, packed into bits 0--159 of the
second request word. -/
def withRequestOwner (word : Uint256) (owner : Address) : Uint256 :=
  .ofNat ((word.val / 2 ^ 160) * 2 ^ 160 + owner.toNat)

/-- `WithdrawalQueueERC721.transferFrom` through `_transfer`, restricted to
the literal `msg.sender == _from` branch.  Every guard is evaluated from the
caller and physical request word; the successful write is
`keccak256(abi.encode(requestId, QUEUE_POSITION)) + 1`. -/
def transferFrom (ctx : Context) (from recipient : Address) (requestId : Nat) :
    Exec Unit := fun world =>
  let before := { world.core with sender := ctx.sender }
  let metadata := requestMetadataWord before requestId
  if recipient = zeroAddress then ⟨.error (.reason "TransferToZeroAddress"), world, []⟩
  else if recipient = from then ⟨.error (.reason "TransferToThemselves"), world, []⟩
  else if requestId = 0 then ⟨.error (.reason "InvalidRequestId"), world, []⟩
  else if requestClaimed metadata then ⟨.error (.reason "RequestAlreadyClaimed"), world, []⟩
  else if requestOwner metadata != from then
    ⟨.error (.reason "TransferFromIncorrectOwner"), world, []⟩
  else if ctx.sender != from then ⟨.error (.reason "NotOwnerOrApproved"), world, []⟩
  else
    ⟨.ok (), { world with core :=
      before.writeMapUint (queuePosition + 1) (.ofNat requestId)
        (withRequestOwner metadata recipient) }, []⟩

def runTransferFrom (ctx : Context) (from recipient : Address) (requestId : Nat)
    (before : World) :=
  run (transferFrom ctx from recipient requestId) before

/-- The direct ownership handoff is a top-level transaction too: every failed
guard returns the entry world, including every unrelated account's state. -/
theorem transfer_revert_restores_world
    (ctx : Context) (from recipient : Address) (requestId : Nat) (before : World)
    (fault : Fault)
    (h : (runTransferFrom ctx from recipient requestId before).outcome = .error fault) :
    (runTransferFrom ctx from recipient requestId before).world = before := by
  unfold runTransferFrom LidoSRv3.Audit.Source.TrioReserve1.Live.run
  cases hrun : transferFrom ctx from recipient requestId before <;> simp [hrun] at h ⊢

/-- Top-level failure restores the exact caller/callee world.  Failed calls
remain in `attempts`, but no queue slot, balance, or callee effect commits. -/
theorem revert_restores_caller_and_callee_world
    (external : External) (ctx : Context) (requestId hint : Nat)
    (recipient : Address) (before : World) (fault : Fault)
  (h : (runClaimTo external ctx requestId hint recipient before).outcome = .error fault) :
    (runClaimTo external ctx requestId hint recipient before).world = before := by
  unfold runClaimTo LidoSRv3.Audit.Source.TrioReserve1.Live.run
  cases hrun : claimTo external ctx requestId hint recipient before <;>
    simp [hrun] at h ⊢

end LidoSRv3.Audit.Verity.AddressRecipientCallBridge
