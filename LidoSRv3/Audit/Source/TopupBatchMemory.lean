import LidoSRv3.Audit.Source.TopupModuleMemory
set_option autoImplicit false
namespace LidoSRv3.Audit.Source.TopupBatchMemory
open TrioReserve1 Live TopupGatewayWitnessBatch TopupBatchRootCalls
open TopupGatewayRootCalls (Environment)

def finish (cursor : Word) (hash : TopupRouterCredentials.Keccak) (m x : External)
    (e : Environment) (ctx : Context) (deposit : Address) (moduleId : Word)
    (keys operators : List Word) (allocation : Word)
    (checked : TopupGatewayRootCalls.Result Output) : Result :=
  match checked.outcome with
  | .error fault => ⟨.error (.gateway fault),e.before,checked.attempts,[]⟩
  | .ok out =>
    let executed := TopupModuleMemory.execute cursor hash m x ctx deposit
      (TopupBatchConsumer.moduleInput out moduleId keys operators ctx.sender allocation e.before) e.before
    ⟨executed.outcome.mapError Error.module,executed.world,checked.attempts,executed.attempts⟩

def run (cursor : Word) (hash : TopupRouterCredentials.Keccak) (m x : External)
    (e : Environment) (ctx : Context) (deposit : Address) (moduleId : Word)
    (keys operators : List Word) (rows : List Row) (allocation : Word) : Result :=
  match checkLengths (environment e).cfg rows.length keys.length operators.length rows.length rows.length with
  | .error fault => ⟨.error (.gateway fault),e.before,[],[]⟩
  | .ok () => finish cursor hash m x e ctx deposit moduleId keys operators allocation
      (TopupGatewayRootCalls.loop (environment e) none 0 rows)


/-- Same root phase, one module CALL, then the guarded scalar memory decoder
and existing physical continuation. No interpreter is invoked twice by run. -/
theorem run_success (cursor : Word) (hash : TopupRouterCredentials.Keccak) (m x : External)
    (e : Environment) (ctx : Context) (deposit : Address) (moduleId : Word)
    (keys operators : List Word) (rows : List Row) (allocation : Word)
    (h : (run cursor hash m x e ctx deposit moduleId keys operators rows allocation).outcome = .ok ()) :
    run cursor hash m x e ctx deposit moduleId keys operators rows allocation =
      TopupBatchRootCalls.run hash m x e ctx deposit moduleId keys operators rows allocation ∧
    ∃ out raw after trace allocations next,
      (TopupGatewayRootCalls.loop (environment e) none 0 rows).outcome = .ok out ∧
      TopupModuleCall.call hash m (LidoSRv3.Audit.Verity.TopupBeaconFundedTx.routerContext ctx)
        (TopupBatchConsumer.moduleInput out moduleId keys operators ctx.sender allocation e.before) e.before =
        ⟨.ok raw,after,trace⟩ ∧
      TopupModuleMemory.decodeReturn cursor raw = .ok (allocations,next) := by
  unfold run at h ⊢
  unfold TopupBatchRootCalls.run
  cases hc : checkLengths (environment e).cfg rows.length keys.length operators.length rows.length rows.length with
  | «error» fault => simp [hc] at h
  | ok u =>
    cases u
    simp only [hc] at h ⊢
    cases hl : (TopupGatewayRootCalls.loop (environment e) none 0 rows).outcome with
    | «error» fault => simp [finish,hl] at h
    | ok out =>
      have hs : (TopupModuleMemory.execute cursor hash m x ctx deposit
          (TopupBatchConsumer.moduleInput out moduleId keys operators ctx.sender allocation e.before) e.before).outcome = .ok () := by
        cases he : (TopupModuleMemory.execute cursor hash m x ctx deposit
            (TopupBatchConsumer.moduleInput out moduleId keys operators ctx.sender allocation e.before) e.before).outcome with
        | «error» fault => simp [finish,hl,he,Except.mapError] at h
        | ok u => cases u; rfl
      obtain ⟨he,raw,after,trace,allocations,next,hcall,hdecode⟩ :=
        TopupModuleMemory.execute_success cursor hash m x ctx deposit _ e.before hs
      refine ⟨?_,out,raw,after,trace,allocations,next,rfl,hcall,hdecode⟩
      simp only [finish,TopupBatchRootCalls.finish,hl,he]

/-- Rollback includes already successful module changes when a scalar memory
guard or a later continuation guard rejects. Both attempt phases are retained. -/
theorem failure_restores (cursor : Word) (hash : TopupRouterCredentials.Keccak) (m x : External)
    (e : Environment) (ctx : Context) (deposit : Address) (moduleId : Word)
    (keys operators : List Word) (rows : List Row) (allocation : Word) (fault : Error)
    (h : (run cursor hash m x e ctx deposit moduleId keys operators rows allocation).outcome = .error fault) :
    (run cursor hash m x e ctx deposit moduleId keys operators rows allocation).world = e.before := by
  unfold run at h ⊢
  cases hc : checkLengths (environment e).cfg rows.length keys.length operators.length rows.length rows.length with
  | «error» f => rfl
  | ok u =>
    cases u
    simp only [hc] at h ⊢
    cases ho : (TopupGatewayRootCalls.loop (environment e) none 0 rows).outcome with
    | «error» f => simp only [finish,ho]
    | ok out =>
      simp only [finish,ho,TopupModuleMemory.execute,Live.run] at h ⊢
      split at h <;> simp_all [Except.mapError]

#print axioms run_success
#print axioms failure_restores
end LidoSRv3.Audit.Source.TopupBatchMemory
