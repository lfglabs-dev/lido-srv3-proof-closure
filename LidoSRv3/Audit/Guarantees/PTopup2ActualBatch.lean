import LidoSRv3.Audit.Guarantees.PTopup2
import LidoSRv3.Audit.Source.TopupBatchConsumer

/-! Public P-TOPUP-2 consumer of the actual module-reply value path.
The historical abstract allocator theorem remains available. This theorem
uses neither its greedy allocation algorithm nor independent limit inputs.
The source module documents the covered phase and still-uncomposed entry. -/
namespace LidoSRv3.Audit.Guarantees.PTopup2
open Source Source.TrioReserve1.Live Source.SszValidatorLeaf Source.SszVerifierEntry
open Source.SszWrapperIndex Source.TopupGatewayWitnessBatch

/-- The completed covered batch's actual returned allocations total no more
than the packed router cap, converted to wei. The gateway derives the limits,
and the module CALL/decode consumes the same keys, amounts and World.
Zero/empty returns are included. No gas, consensus or cryptographic proof is
added to the accepted boundary by this safety statement. -/
theorem actual_module_batch_bound (hash : TopupRouterCredentials.Keccak)
    (moduleExternal withdrawalExternal : External) (precompile : Precompile)
    (oracle : RootOracle) (scratch : Fin 32 → Byte) (gi : Configuration)
    (beacon : BeaconData) (divisor : Index) (credentials : Digest)
    (gateway : Address) (ctx : Context) (depositContract : Address) (moduleId : Word)
    (keyIndices operatorIds : List Word) (rows : List Row) (moduleAllocation : Word)
    (before : World) (result : Result Unit)
    (h : TopupBatchConsumer.run hash moduleExternal withdrawalExternal precompile oracle scratch gi beacon divisor
      credentials gateway ctx depositContract moduleId keyIndices operatorIds rows moduleAllocation before = .ok result)
    (hs : result.outcome = .ok ()) :
    ∃ out raw afterModule trace allocations,
      loop precompile oracle scratch gi (TopupGatewayConfigWords.readConfig gateway before)
        beacon divisor credentials none 0 rows = .ok out ∧
      TopupModuleCall.call hash moduleExternal
        (LidoSRv3.Audit.Verity.TopupBeaconFundedTx.routerContext ctx)
        (TopupBatchConsumer.moduleInput out moduleId keyIndices operatorIds ctx.sender moduleAllocation before) before =
          ⟨.ok raw,afterModule,trace⟩ ∧
      TopupModuleCall.decodeReturn raw = .ok allocations ∧
      (TopupRouterContinuation.values allocations).sum ≤
        (TopupBatchConsumer.blockCap ctx.sender before).val * GWEI :=
  TopupBatchConsumer.run_success_bound hash moduleExternal withdrawalExternal precompile oracle scratch gi beacon
    divisor credentials gateway ctx depositContract moduleId keyIndices operatorIds rows moduleAllocation before result h hs

#print axioms actual_module_batch_bound
end LidoSRv3.Audit.Guarantees.PTopup2
