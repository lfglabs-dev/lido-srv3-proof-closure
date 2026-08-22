import LidoSRv3.Audit.Verity.ConsolidationCallFragment
import LidoSRv3.Audit.Guarantees.PConsolidation1

/-!
# Leftover C-GAP: official denotation gap

Names the already-proved official-denotation gap: `Expr.call` /
`Stmt.externalCallBind` have no `denoteFunction` arm and revert. Does not
discharge `A-CONSOLIDATION-GATEWAY-NONZERO`, start the bus, or compose
P-CONSOLIDATION-ETH-1 with P-CONSOLIDATION-1.
-/

namespace LidoSRv3.Audit.Spec.ConsolidationBridgeGap

open LidoSRv3.Audit.Verity.ConsolidationCallFragment
open LidoSRv3.Audit.Guarantees.PConsolidation1
open LidoSRv3.Audit.SolidityConsolidation
open Compiler.CompilationModel.Denote

/-- Official denotation implements no arm for the registered bind
entrypoint, so it reverts for every oracle, transaction, and world.
Strongest public fragment theorem: the function is the compilation-model
member, not a caller-supplied `FunctionSpec`. -/
theorem official_external_call_reverts
    (oracle : DenoteOracle) (tx : DenoteTransaction) (world : Verity.ContractState) :
    (denoteFunction oracle spec spec.functions[1] tx world).success = false :=
  registered_external_call_bind_entrypoint_always_reverts oracle tx world

/-- `A-CONSOLIDATION-GATEWAY-NONZERO` stays a named hyp. Dropping it still
admits a free batch, so this node does not discharge it and does not start
the bus. Premise necessity, not a parent-shaped refutation. -/
theorem gateway_nonzero_remains_named_hyp :
    ¬ (∀ (inputs : Inputs) (obs : Observables),
        sourceRun inputs = .committed obs → inputs.fee.val ≠ 0) :=
  LidoSRv3.Audit.Guarantees.PConsolidation1.gateway_admitted_nonzero_kill_line

end LidoSRv3.Audit.Spec.ConsolidationBridgeGap
