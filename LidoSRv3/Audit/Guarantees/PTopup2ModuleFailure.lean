import LidoSRv3.Audit.Source.TopupBatchRootCalls

namespace LidoSRv3.Audit.Guarantees.PTopup2
open Source Source.TrioReserve1.Live Source.TopupGatewayWitnessBatch

/-- Ordinary no-code module CALL succeeds empty, then the consumed ABI decoder
fails and root execution restores its initial world, retaining the exact CALL.
Precompile dispatch is outside the inherited ordinary no-code branch. -/
theorem actual_module_no_code_failure (hash : TopupRouterCredentials.Keccak) (m x : External)
    (ctx : Context) (deposit : Address) (i : TopupModuleCall.Input) (before : World)
    (hc : (before.core.codeSize (TopupModuleCall.moduleAddress hash ctx.sender i.moduleId before).val).val = 0) :
    TopupModuleCall.execute hash m x ctx deposit i before =
      ⟨.error .empty,before,
       [⟨⟨ctx.sender,TopupModuleCall.moduleAddress hash ctx.sender i.moduleId before,
          word 0,TopupModuleCall.payload i⟩,true,[],[]⟩]⟩ :=
  TopupModuleCall.execute_no_code hash m x ctx deposit i before hc

/-- The whole root/module batch cannot succeed with an ordinary no-code module.
Earlier gateway rejection makes no module attempt; otherwise its actual empty
CALL is recorded after the root phase, and the entire initial world is restored.
No successful prefix is assumed. -/
theorem actual_root_batch_no_code_failure (hash : TopupRouterCredentials.Keccak) (m x : External)
    (e : TopupGatewayRootCalls.Environment) (ctx : Context) (deposit : Address) (moduleId : Word)
    (keys operators : List Word) (rows : List Row) (allocation : Word)
    (hc : (e.before.core.codeSize (TopupModuleCall.moduleAddress hash ctx.sender moduleId e.before).val).val = 0) :
    let result := TopupBatchRootCalls.run hash m x e ctx deposit moduleId keys operators rows allocation
    result.outcome ≠ .ok () ∧ result.world = e.before ∧
      (result.moduleAttempts = [] ∨ ∃ out,
        (TopupGatewayRootCalls.loop (TopupBatchRootCalls.environment e) none 0 rows).outcome = .ok out ∧
        result.rootAttempts = (TopupGatewayRootCalls.loop (TopupBatchRootCalls.environment e) none 0 rows).attempts ∧
        result.outcome = .error (.module .empty) ∧
        result.moduleAttempts =
          [⟨⟨ctx.sender,TopupModuleCall.moduleAddress hash ctx.sender moduleId e.before,word 0,
            TopupModuleCall.payload (TopupBatchConsumer.moduleInput out moduleId keys operators
              ctx.sender allocation e.before)⟩,true,[],[]⟩]) := by
  dsimp only
  unfold TopupBatchRootCalls.run
  cases hl : checkLengths (TopupBatchRootCalls.environment e).cfg rows.length keys.length operators.length rows.length rows.length with
  | «error» fault => simp [hl]
  | ok u =>
    cases u
    simp only [hl]
    cases hr : (TopupGatewayRootCalls.loop (TopupBatchRootCalls.environment e) none 0 rows).outcome with
    | «error» fault => simp [TopupBatchRootCalls.finish,hr]
    | ok out =>
      have hn := TopupModuleCall.execute_no_code hash m x ctx deposit
        (TopupBatchConsumer.moduleInput out moduleId keys operators ctx.sender allocation e.before) e.before hc
      simp [TopupBatchRootCalls.finish,hr,hn,Except.mapError]
      rfl

#print axioms actual_module_no_code_failure
#print axioms actual_root_batch_no_code_failure
end LidoSRv3.Audit.Guarantees.PTopup2
