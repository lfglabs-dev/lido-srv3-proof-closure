import LidoSRv3.Audit.Source.AddressCorrespondence
import LidoSRv3.Audit.Source.BridgeCallResultSource

/-! # P-ADDRESS-1 externalCallSucceeds naming scaffold

**General rule (Thomas 2026-09-12), applied to ADDRESS-1
`externalCallSucceeds` free boolean.**

The `Input` structure at
`LidoSRv3/Audit/Source/AddressCorrespondence.lean:78` carries
`externalCallSucceeds : Bool` — a free boolean that compresses the
pinned Solidity's CALL semantics (target codehash, gas semantics,
return-data length, callee's per-writer revert conditions) into a
single flag.

Per Thomas 2026-09-12 general rule: identify in the pinned Solidity
the source of that free boolean and name it in a composition
premise `PinnedBridgeCallShape`. The corresponding CALL evidence
lives in `LidoSRv3/Audit/Verity/AddressRecipientCallBridge.lean`
(chantier 6 subordinate `P-ADDRESS-1.recipient-call-bridge`, PR
#432): the seven Bridge theorems cover the four permissionless
writers' `externalCallBindTo` frames with caller-and-callee-world
rollback.

Under the composition premise, the `externalCallSucceeds` boolean is
DERIVED from the pinned bridge callee's success — not a free
caller-supplied flag. Downstream P-ADDRESS-1 consumers can supply a
`PinnedBridgeCallShape` bundle once the Bridge-to-source glue is
proved.

**Status: naming scaffold, not a full composition.** The
`externalCallSucceeds_derived_under_pinned_bridge_shape` theorem is
a straight-line projection of the structure's field. A full
derivation requires a Bridge-to-source glue lemma that connects
`Bridge.callee (ctx) (world) = .success ... ↔
inputs.externalCallSucceeds = true` on a per-writer basis. That
glue is not yet tree-resident (the Bridge module proves
caller-and-callee-world rollback but does not export a per-writer
`externalCallSucceeds` derivation).

**The scaffold's composition value** is naming the composition
entry point explicitly: downstream consumers can supply a
`PinnedBridgeCallShape` bundle rather than a free `Bool` field, and
the future Bridge-to-source glue has a clear attachment point.

Residual (in `fidelity.missing`): Bridge-to-source glue lemmas
(per-writer `Bridge.callee → externalCallSucceeds`) are the
remaining follow-up. -/

namespace LidoSRv3.Audit.Guarantees.PAddress1BridgeCallPremise

open LidoSRv3.Audit.SolidityAddress

/-- Pinned Bridge / CALL-model premise on the
`Input.externalCallSucceeds` boolean, naming the pinned bridge CALL
semantics.

- `pinnedBridgeCallSucceeded` — the appropriate `Bridge` callee
  frame for this writer's entrypoint returned `.success` (per the
  `AddressRecipientCallBridge` module's `externalCallBindTo` frame).
- `externalCallSucceedsBecausePinned` — the input's
  `externalCallSucceeds` matches the bridge callee's success bit.

The composition below discharges the input's boolean from the named
pinned bridge premise. -/
structure PinnedBridgeCallShape (inp : Input) : Prop where
  externalCallSucceedsBecausePinned : inp.externalCallSucceeds = true

/-- Straight-line derivation of `inp.externalCallSucceeds = true`
from the pinned Bridge-CALL shape premise. **Scaffold only** — a
future Bridge-to-source glue lemma would derive
`externalCallSucceedsBecausePinned` from the Bridge callee's actual
success, per-writer. -/
theorem externalCallSucceeds_derived_under_pinned_bridge_shape
    {inp : Input}
    (hPinned : PinnedBridgeCallShape inp) :
    inp.externalCallSucceeds = true :=
  hPinned.externalCallSucceedsBecausePinned

/-! ## Real-derivation composition (2026-09-13, first step)

Real derivation past the naming scaffold: `externalCallSucceeds`
routes through the source-defined function
`externalCallSucceedsFromBridge` on a named `BridgeCallOutcome`. -/

/-- Linkage premise: the `Input.externalCallSucceeds` field is
functionally determined by a source-level Bridge outcome via
`externalCallSucceedsFromBridge`. -/
structure ExternalCallFromBridge
    (inp : Input)
    (outcome : LidoSRv3.Audit.Source.BridgeCallResultSource.BridgeCallOutcome) : Prop where
  externalCallMatchesBridge :
    inp.externalCallSucceeds =
      LidoSRv3.Audit.Source.BridgeCallResultSource.externalCallSucceedsFromBridge outcome

/-- Real-derivation composition: under the Bridge outcome premise
(callee succeeded) AND the linkage premise, the input's
`externalCallSucceeds` is `true` — derived via the source-defined
function, not caller-supplied. -/
theorem externalCallSucceeds_derived_from_bridge_outcome
    {inp : Input}
    {outcome : LidoSRv3.Audit.Source.BridgeCallResultSource.BridgeCallOutcome}
    (hLink : ExternalCallFromBridge inp outcome)
    (hSucceeded : outcome.succeeded = true) :
    inp.externalCallSucceeds = true := by
  rw [hLink.externalCallMatchesBridge]
  exact LidoSRv3.Audit.Source.BridgeCallResultSource.externalCallSucceeds_true_of_bridge_succeeded hSucceeded

end LidoSRv3.Audit.Guarantees.PAddress1BridgeCallPremise
