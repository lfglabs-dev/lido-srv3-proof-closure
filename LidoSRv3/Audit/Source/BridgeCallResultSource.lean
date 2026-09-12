/-! # Bridge CALL-result source model (P-ADDRESS-1 externalCallSucceeds real derivation)

**General rule (Thomas 2026-09-13, real-derivation step for
P-ADDRESS-1 externalCallSucceeds).**

Names the Bridge CALL result as an audit-source model. Under this
model, `Input.externalCallSucceeds` becomes a DEFINED function of a
per-writer Bridge callee outcome, not an anonymous free `Bool`.

Pinned Solidity (17005714) callees the Bridge module covers:

- `WithdrawalQueue.requestWithdrawals` → `STETH.transferFrom(msg.sender,
  address(this), _amountOfStETH)`.
- `WithdrawalQueue._claim` → value CALL to `_recipient`.
- `WstETH.unwrap` → `stETH.transfer(msg.sender, stETHAmount)`.
- `WithdrawalQueueERC721.transferFrom` → no external call (Transfer event only).

The `AddressRecipientCallBridge` module (chantier 6 subordinate)
carries the executable `externalCallBindTo` frames with
caller-and-callee-world rollback.

**Status:** first-step real derivation. `externalCallSucceedsFromBridge`
is NO LONGER a free boolean — it's a source-level function of a
named `BridgeCallOutcome` (with a `succeeded` field naming the
Bridge callee's success bit).

Residual: `BridgeCallOutcome.succeeded` is still an input boolean;
per-writer Bridge-to-source glue that derives it from the actual
`externalCallBindTo` frame per callee (per-writer) remains the
next follow-up. -/

namespace LidoSRv3.Audit.Source.BridgeCallResultSource

/-- Bridge CALL outcome for a single address-bearing writer's
external callee. Names the success bit of the per-writer
`externalCallBindTo` frame. -/
structure BridgeCallOutcome : Type where
  succeeded : Bool

/-- Definition of the source-level `externalCallSucceeds` boolean as
a function of the Bridge callee's success bit. -/
def externalCallSucceedsFromBridge (outcome : BridgeCallOutcome) : Bool :=
  outcome.succeeded

/-- Under the pinned Bridge premise (callee succeeded),
`externalCallSucceedsFromBridge = true`. Real derivation from a
named Bridge outcome, definitionally. -/
theorem externalCallSucceeds_true_of_bridge_succeeded
    {outcome : BridgeCallOutcome}
    (hSucceeded : outcome.succeeded = true) :
    externalCallSucceedsFromBridge outcome = true := by
  simp [externalCallSucceedsFromBridge, hSucceeded]

end LidoSRv3.Audit.Source.BridgeCallResultSource
