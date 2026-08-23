import LidoSRv3.Audit.Verity.ConsolidationTx
import LidoSRv3.Audit.Verity.ConsolidationCallFragment
import LidoSRv3.Audit.Guarantees.PConsolidation1

/-!
# Leftover W2-DENOTE: widened constructors ≠ official denotation success

Unregistered child. It names two already-proved facts together: `requestOne`
still contains `externalCallBind` (widened constructors), and official
`denoteFunction` still reverts on `Expr.call` (C-GAP). Those facts do not
compose into official denotation success.

Does not discharge `A-CONSOLIDATION-GATEWAY-NONZERO`. Does not start the
bus. Does not invent a guarantee ID.

The former `preservesEthBalance_gap` string child is retired by the
value-bearing CALL lift: `addRequests` now credits `msg.value` at frame
entry and debits each journaled CALL, so the registered parent closes
`preservesEthBalance` on the vault side
(`Guarantees.PConsolidation1.verity_tx_preserves_eth_balance`).
-/

namespace LidoSRv3.Audit.Spec.ConsolidationDenoteCallsChild

open LidoSRv3.Audit.Verity
open LidoSRv3.Audit.Guarantees
open Compiler.CompilationModel
open Compiler.CompilationModel.Denote

/-- The `requestOne` body is the widened call/event/memory constructors.
This is a constructor-shape fact, not official denotation success. -/
theorem requestOne_uses_widened_call_constructor :
    ConsolidationTx.requestOne.body =
      [ .mstore (.literal 0) (.param "sourceKey")
      , .mstore (.literal 1) (.param "targetKey")
      , .externalCallBind [] "consolidationPredeploy"
          [.param "sourceKey", .param "targetKey"]
      , .emit "ConsolidationRequestAdded"
          [.param "sourceKey", .param "targetKey"]
      , .setStorage "requests" (.add (.storage "requests") (.literal 1))
      , .stop ] :=
  ConsolidationTx.function_spec_bridge_constructors

/-- Official `denoteFunction` still reverts on the raw-call entrypoint.
C-GAP remains. This is not official denotation success. -/
theorem official_raw_call_still_reverts
    (oracle : DenoteOracle) (tx : DenoteTransaction)
    (world : Verity.ContractState) :
    (ConsolidationCallFragment.run oracle
        ConsolidationCallFragment.requestConsolidation tx world).success = false :=
  ConsolidationCallFragment.raw_call_entrypoint_always_reverts oracle tx world

/-- Link-time env resolves the named predeploy. Resolution is not
execution; official denotation still reverts. -/
theorem functionEnv_resolves_predeploy (target fee : Nat) :
    (ConsolidationTx.functionEnv target fee).resolve "consolidationPredeploy" =
      some { target := target, value := fee, siteId := 0 } :=
  rfl

end LidoSRv3.Audit.Spec.ConsolidationDenoteCallsChild
