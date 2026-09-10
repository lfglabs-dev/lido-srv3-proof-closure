import LidoSRv3.Audit.Guarantees.PTopup1
import LidoSRv3.Audit.Source.TopupBatchConsumer

/-! TOPUP-1 consumes the actual gateway count/wei-limit bounds and actual
module reply, so the executed zero branch refers to the mathematical sum of
those same decoded allocations. Full gateway admission remains separate. -/
namespace LidoSRv3.Audit.Guarantees.PTopup1
open Source Source.TrioReserve1.Live Source.SszValidatorLeaf Source.SszVerifierEntry
open Source.SszWrapperIndex Source.TopupGatewayWitnessBatch Source.TopupBatchConsumer

/-- Actual batch success exposes its module-returned world and continuation
effects at the exact mathematical allocation sum. The zero branch makes no
withdrawal or beacon call and preserves the module's returned storage/balances;
the positive branch contains the actual successful subexecutions. No separate
sum, no-wrap, count, helper-length or sub-stage-success premise is supplied. -/
theorem actual_module_batch_effects (hash : TopupRouterCredentials.Keccak)
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
        (moduleInput out moduleId keyIndices operatorIds ctx.sender moduleAllocation before) before =
          ⟨.ok raw,afterModule,trace⟩ ∧
      TopupModuleCall.decodeReturn raw = .ok allocations ∧
      (TopupRouterContinuation.values allocations).sum ≤ (blockCap ctx.sender before).val * 10^9 ∧
      let ci := TopupModuleCall.continuationInput
        (moduleInput out moduleId keyIndices operatorIds ctx.sender moduleAllocation before) allocations
      let suffix := TopupRouterContinuation.program hash withdrawalExternal ctx depositContract ci afterModule
      result.world = suffix.world ∧ result.attempts = trace ++ suffix.attempts ∧
      (((TopupRouterContinuation.values allocations).sum = 0 ∧
        suffix = ⟨.ok (), {afterModule with logs := afterModule.logs ++
          [TopupRouterContinuation.topUpEvent ctx.sender ci 0]}, []⟩) ∨
       TopupRouterCommitted.PositiveEffects hash withdrawalExternal ctx depositContract ci afterModule suffix
         (TopupRouterContinuation.values allocations).sum) :=
  TopupBatchConsumer.run_success_exact_effects hash moduleExternal withdrawalExternal precompile oracle
    scratch gi beacon divisor credentials gateway ctx depositContract moduleId keyIndices operatorIds rows
    moduleAllocation before result h hs

#print axioms actual_module_batch_effects
end LidoSRv3.Audit.Guarantees.PTopup1
