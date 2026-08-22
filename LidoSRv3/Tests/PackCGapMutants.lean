import LidoSRv3.Audit.Spec.ConsolidationBridgeGap
import LidoSRv3.Audit.Guarantees.PConsolidation1

/-!
# Pack C-GAP fail-closed vectors

Dropping `A-CONSOLIDATION-GATEWAY-NONZERO` admits a free batch. This
restates the existing premise-necessity kill-line; it is not a
parent-shaped refutation of the hyp-conditioned parent.
-/

namespace LidoSRv3.Tests.PackCGapMutants

open LidoSRv3.Audit.Guarantees.PConsolidation1
open LidoSRv3.Audit.SolidityConsolidation
open LidoSRv3.Audit.Spec.ConsolidationBridgeGap

/-- Kill-line: restating that dropping the gateway-nonzero premise admits
a free batch. Citation of the existing kill-line, not a new parent-shaped
refutation of the hyp-conditioned parent. -/
theorem dropping_gateway_nonzero_admits_free_batch :
    ¬ (∀ (inputs : Inputs) (obs : Observables),
        sourceRun inputs = .committed obs → inputs.fee.val ≠ 0) :=
  gateway_nonzero_remains_named_hyp

/-- Official denotation gap stays the existing fragment theorem. -/
example := official_external_call_reverts

end LidoSRv3.Tests.PackCGapMutants
