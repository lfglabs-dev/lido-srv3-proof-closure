import LidoSRv3.Audit.Source.BridgeCallResultSource

/-! # Per-writer Bridge-to-source glue (P-ADDRESS-1 externalCallSucceeds second step)

**General rule (Thomas 2026-09-13, second real-derivation step for
P-ADDRESS-1 externalCallSucceeds).**

The `BridgeCallResultSource` module (PR #449) defines a single
`BridgeCallOutcome` naming the Bridge callee's success bit. This
module adds per-writer glue: for each of the four address-bearing
writers, a source-level `BridgeCallOutcome` constructor that
identifies the corresponding pinned Solidity callee.

Pinned Solidity (17005714):

- `requestWithdrawals` →
  `STETH.transferFrom(msg.sender, address(this), _amountOfStETH)` at
  `contracts/0.8.9/WithdrawalQueue.sol:132-135` (loop) via
  `_requestWithdrawal:374`.
- `_claim` → value CALL to `_recipient` at
  `contracts/0.8.9/WithdrawalQueueBase.sol:472`.
- `unwrap` → `stETH.transfer(msg.sender, stETHAmount)` at
  `contracts/0.4.24/WstETH.sol:73`.
- `transferFrom` → no external call (Transfer event only) at
  `contracts/0.8.9/WithdrawalQueueERC721.sol:248`.

The four `bridgeOutcomeFor*` constructors below name each pinned
callee's outcome explicitly. Under a per-writer premise about the
actual callee execution, the corresponding `BridgeCallOutcome`
succeeded field is `true` — but the per-writer live-callee execution
model is not yet tree-resident (it would connect the Bridge module's
executable `externalCallBindTo` frames to the source `BridgeCallOutcome`).

**Status:** per-writer glue naming step. The four constructors are
straight-line — each takes a `Bool` argument and packages it as a
`BridgeCallOutcome`. The composition value: instead of one anonymous
`BridgeCallOutcome`, downstream consumers name the specific writer
via the constructor. Live-callee derivation remains follow-up. -/

namespace LidoSRv3.Audit.Source.BridgePerWriterGlue

open LidoSRv3.Audit.Source.BridgeCallResultSource

/-- Per-writer identifier for the four address-bearing writers. -/
inductive Writer : Type where
  | requestWithdrawals
  | claimWithdrawals
  | unwrap
  | transferFrom
  deriving Repr, DecidableEq

/-- Source-level `BridgeCallOutcome` for the `requestWithdrawals`
writer. Names `STETH.transferFrom(sender, address(this), amount)` at
`WithdrawalQueue.sol:374`. -/
def bridgeOutcomeForRequestWithdrawals (calleeSucceeded : Bool) : BridgeCallOutcome :=
  { succeeded := calleeSucceeded }

/-- Source-level `BridgeCallOutcome` for the `_claim` writer.
Names value CALL to `_recipient` at `WithdrawalQueueBase.sol:472`. -/
def bridgeOutcomeForClaimWithdrawals (calleeSucceeded : Bool) : BridgeCallOutcome :=
  { succeeded := calleeSucceeded }

/-- Source-level `BridgeCallOutcome` for the `unwrap` writer. Names
`stETH.transfer(msg.sender, stETHAmount)` at `WstETH.sol:73`. -/
def bridgeOutcomeForUnwrap (calleeSucceeded : Bool) : BridgeCallOutcome :=
  { succeeded := calleeSucceeded }

/-- Source-level `BridgeCallOutcome` for the `transferFrom` writer.
No external call at `WithdrawalQueueERC721.sol:248`; the outcome is
trivially `true` for the writer's non-callable path. -/
def bridgeOutcomeForTransferFrom : BridgeCallOutcome :=
  { succeeded := true }

/-- Dispatcher: given a writer identifier and a callee-succeeded
bit, produce the corresponding per-writer `BridgeCallOutcome`. -/
def bridgeOutcomeForWriter (w : Writer) (calleeSucceeded : Bool) : BridgeCallOutcome :=
  match w with
  | .requestWithdrawals => bridgeOutcomeForRequestWithdrawals calleeSucceeded
  | .claimWithdrawals => bridgeOutcomeForClaimWithdrawals calleeSucceeded
  | .unwrap => bridgeOutcomeForUnwrap calleeSucceeded
  | .transferFrom => bridgeOutcomeForTransferFrom

/-- For the three call-bearing writers, `bridgeOutcomeForWriter`'s
success bit equals the caller-supplied `calleeSucceeded` argument.
For `transferFrom` (non-callable path), it's always `true`. -/
theorem bridgeOutcomeForWriter_succeeded (w : Writer) (calleeSucceeded : Bool) :
    (bridgeOutcomeForWriter w calleeSucceeded).succeeded =
      (match w with
        | .transferFrom => true
        | _ => calleeSucceeded) := by
  cases w <;> rfl

end LidoSRv3.Audit.Source.BridgePerWriterGlue
