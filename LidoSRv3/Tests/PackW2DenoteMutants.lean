import LidoSRv3.Audit.Spec.ConsolidationDenoteCallsChild
import LidoSRv3.Audit.Verity.ConsolidationTx
import LidoSRv3.Audit.Verity.ConsolidationCallFragment

/-!
# Pack W2-DENOTE fail-closed vectors

Official `denoteFunction` reverts on the raw-call entrypoint, and the
`requestOne` body still contains `externalCallBind`. Widened constructors
are not official success.
-/

namespace LidoSRv3.Tests.PackW2DenoteMutants

open Compiler.CompilationModel
open LidoSRv3.Audit.Verity
open LidoSRv3.Audit.Spec.ConsolidationDenoteCallsChild

/-- Kill-line: official call entrypoint reverts, and `requestOne` still
contains `externalCallBind`. That pair is the honesty that widened
constructors ≠ official success. -/
theorem official_revert_with_widened_bind
    (oracle : Denote.DenoteOracle) (tx : Denote.DenoteTransaction)
    (world : Verity.ContractState) :
    (ConsolidationCallFragment.run oracle
        ConsolidationCallFragment.requestConsolidation tx world).success = false ∧
      ConsolidationTx.requestOne.body[2]? =
        some (.externalCallBind [] "consolidationPredeploy"
          [.param "sourceKey", .param "targetKey"]) :=
  ⟨official_raw_call_still_reverts oracle tx world, by
    simp [requestOne_uses_widened_call_constructor]⟩

/-- The constructors theorem is the source of the bind fact. -/
example := requestOne_uses_widened_call_constructor

/-- Official denotation gap stays the existing fragment theorem. -/
example := official_raw_call_still_reverts

/-- Link-time resolve is not execution. -/
example (target fee : Nat) := functionEnv_resolves_predeploy target fee

/-- The named ETH-balance gap stays the documented nonempty string. -/
example := preservesEthBalance_gap_remains

end LidoSRv3.Tests.PackW2DenoteMutants
