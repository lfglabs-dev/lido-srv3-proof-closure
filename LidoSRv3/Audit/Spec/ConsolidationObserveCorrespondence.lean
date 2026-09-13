import LidoSRv3.Audit.Verity.ConsolidationTx
import LidoSRv3.Audit.Guarantees.PConsolidation1

/-!
# Pack F: consolidation observe/payloads

Unregistered children. They do not replace the registered P-CONSOLIDATION-1
parent, do not start a gateway/bus, and do not invent a guarantee ID.

Chantier 2 (Thomas 2026-09-13, item c completion): the two Pack F
observe/payloads witnesses (`observe_success_payloads_reread_maps` and
`persist_payloads_reread`) were physically retired in this PR — both
theorems consumed the pre-retirement `observe` / `persist` / `readPayloads`
machinery reading the fabricated `sourceMapSlot` / `targetMapSlot`. Since
PR #648 the registered P-CONSOLIDATION-1 parent consumes only the
slot-free companions (`observeFromJournal` / `addRequestsSlotFree`), so
these two Pack F witnesses no longer name any live model surface.
Only the `A-CONSOLIDATION-GATEWAY-NONZERO` premise-necessity witness
survives here.
-/

namespace LidoSRv3.Audit.Spec.ConsolidationObserveCorrespondence

open LidoSRv3.Audit.Verity.ConsolidationTx
open LidoSRv3.Audit.Guarantees.PConsolidation1
open LidoSRv3.Audit.SolidityConsolidation

/-- `A-CONSOLIDATION-GATEWAY-NONZERO` stays a named hyp. Dropping it still
admits a free batch, so Pack F does not discharge it and does not start
the bus. -/
theorem gateway_nonzero_remains_named_hyp :
    ¬ (∀ (inputs : Inputs) (obs : Observables),
        sourceRun inputs = .committed obs → inputs.fee.val ≠ 0) :=
  LidoSRv3.Audit.Guarantees.PConsolidation1.gateway_admitted_nonzero_kill_line

end LidoSRv3.Audit.Spec.ConsolidationObserveCorrespondence
