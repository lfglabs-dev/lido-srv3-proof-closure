import LidoSRv3.Audit.Verity.ConsolidationTx
import LidoSRv3.Audit.Guarantees.PConsolidation1

/-!
# Pack F: consolidation observe/payloads

Unregistered children. They do not replace the registered P-CONSOLIDATION-1
parent, do not start a gateway/bus, and do not invent a guarantee ID.
-/

namespace LidoSRv3.Audit.Spec.ConsolidationObserveCorrespondence

open LidoSRv3.Audit.Verity.ConsolidationTx
open LidoSRv3.Audit.Guarantees.PConsolidation1
open LidoSRv3.Audit.SolidityConsolidation

/-- Unregistered child: success `observe` rereads the source/target maps.
It does not trust `Result.payloads`. -/
theorem observe_success_payloads_reread_maps
    (before : Verity.ContractState) (result : Result) (after : Verity.ContractState) :
    (observe before (.success result after)).payloads =
      readPayloads after (before.readSlot countSlot).val
        (after.calls.drop before.calls.length).length := by
  simp [observe]

/-- Persist then reread: written maps are the normalized source-then-target
pairs. Re-export of the existing Verity lemma so Pack F names the
observe/payloads layer without a live gateway. -/
theorem persist_payloads_reread
    (start : Nat) (obs : Observables) (state : Verity.ContractState)
    (hCount : obs.requestCount = obs.payloads.length)
    (hNormalized : obs.payloads.map normalizedPayload = obs.payloads)
    (hBound : start + obs.payloads.length ≤ Verity.Core.Uint256.modulus) :
    readPayloads (persist start obs state) start obs.requestCount = obs.payloads :=
  persist_read_payloads start obs state hCount hNormalized hBound

/-- `A-CONSOLIDATION-GATEWAY-NONZERO` stays a named hyp. Dropping it still
admits a free batch, so Pack F does not discharge it and does not start
the bus. -/
theorem gateway_nonzero_remains_named_hyp :
    ¬ (∀ (inputs : Inputs) (obs : Observables),
        sourceRun inputs = .committed obs → inputs.fee.val ≠ 0) :=
  LidoSRv3.Audit.Guarantees.PConsolidation1.gateway_admitted_nonzero_kill_line

end LidoSRv3.Audit.Spec.ConsolidationObserveCorrespondence
