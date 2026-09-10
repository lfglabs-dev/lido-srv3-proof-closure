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

/-- The recipient is the CALL target, not a post-hoc observation.  `Live.call`
passes the value-debited world to the external callee and returns its resulting
world on success. -/
def payoutCall (external : External) (ctx : Context) (recipient : Address)
    (payout : Nat) : Exec Unit := do
  let _ ← call external ctx recipient 0 (.ofNat payout)
  pure ()

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
