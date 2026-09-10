import LidoSRv3.Audit.Source.TopupRootCallEffects

namespace LidoSRv3.Audit.Guarantees.PTopup1
open Source Source.TrioReserve1.Live Source.TopupGatewayWitnessBatch

/-- Whole actual root/module batch success composes authenticated witness
inputs with the actual module reply and its exact zero/positive physical
continuation effects. No stage-success, sum, count, limit or callee-frame
premise is supplied. Pre-module conservation and full entry admission remain
outside this typed covered-phase claim. -/
theorem actual_root_module_batch_effects (hash : TopupRouterCredentials.Keccak) (m x : External)
    (e : TopupGatewayRootCalls.Environment) (ctx : Context) (deposit : Address) (moduleId : Word)
    (keys operators : List Word) (rows : List Row) (allocation : Word)
    (h : (TopupBatchRootCalls.run hash m x e ctx deposit moduleId keys operators rows allocation).outcome = .ok ()) :
    TopupRootCallEffects.Effects hash m x e ctx deposit moduleId keys operators rows allocation
      (TopupBatchRootCalls.run hash m x e ctx deposit moduleId keys operators rows allocation) :=
  TopupRootCallEffects.run_success hash m x e ctx deposit moduleId keys operators rows allocation h

#print axioms actual_root_module_batch_effects
end LidoSRv3.Audit.Guarantees.PTopup1
