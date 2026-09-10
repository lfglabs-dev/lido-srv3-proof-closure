import LidoSRv3.Audit.Guarantees.PTopup2ActualBatch
import LidoSRv3.Audit.Source.TopupBatchRootCalls

namespace LidoSRv3.Audit.Guarantees.PTopup2
open Source Source.TrioReserve1.Live Source.TopupGatewayWitnessBatch

/-- Actual gateway-caller root STATICCALLs authenticate the ordered witnesses
whose evaluated wei limits and pubkeys feed the actual module CALL. Its actual
decoded allocations satisfy the packed router cap. Success alone derives the
joint relation; no root/SHA success, frame, independent limit or target premise.
This additive typed covered-phase result preserves the prior claim boundaries. -/
theorem actual_root_module_batch_bound (hash : TopupRouterCredentials.Keccak) (m x : External)
    (e : TopupGatewayRootCalls.Environment) (ctx : Context) (deposit : Address) (moduleId : Word)
    (keys operators : List Word) (rows : List Row) (allocation : Word)
    (h : (TopupBatchRootCalls.run hash m x e ctx deposit moduleId keys operators rows allocation).outcome = .ok ()) :
    TopupBatchRootCalls.Success hash m x e ctx deposit moduleId keys operators rows allocation
      (TopupBatchRootCalls.run hash m x e ctx deposit moduleId keys operators rows allocation) :=
  TopupBatchRootCalls.run_success hash m x e ctx deposit moduleId keys operators rows allocation h

#print axioms actual_root_module_batch_bound
end LidoSRv3.Audit.Guarantees.PTopup2
