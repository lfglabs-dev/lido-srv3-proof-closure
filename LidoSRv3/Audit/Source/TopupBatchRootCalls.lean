import LidoSRv3.Audit.Source.TopupGatewayRootCalls
import LidoSRv3.Audit.Source.TopupBatchConsumer

/-! Actual root-call phase followed by the unchanged module CALL and committed
continuation, on one World. The config is read from gateway storage; Environment.cfg
is replaced at this entry. Root attempts precede module attempts; their distinct
existing observation types are retained. This is the covered batch value path,
not the preceding role/timing/locator checks or final gateway history write. -/
set_option maxRecDepth 4096
set_option maxHeartbeats 800000

namespace LidoSRv3.Audit.Source.TopupBatchRootCalls
open TrioReserve1 Live TopupGatewayWitnessBatch
open TopupGatewayRootCalls (Environment Authenticated)

inductive Error where
  | gateway (fault : GatewayFault)
  | module (fault : Fault)
  deriving DecidableEq, Repr

structure Result where
  outcome : Except Error Unit
  world : World
  rootAttempts : List NestedAttempt
  moduleAttempts : List Attempt

/-- Ordered observation view: the complete root phase precedes the module
phase, while each existing attempt retains its original type and metadata. -/
def Result.attempts (r : Result) : List (Sum NestedAttempt Attempt) :=
  r.rootAttempts.map Sum.inl ++ r.moduleAttempts.map Sum.inr

/-- Read the actual packed gateway configuration on the same initial World. -/
def environment (e : Environment) : Environment :=
  {e with cfg := TopupGatewayConfigWords.readConfig e.gateway e.before}

def finish (hash : TopupRouterCredentials.Keccak) (m x : External)
    (e : Environment) (ctx : Context) (deposit : Address) (moduleId : Word)
    (keys operators : List Word) (allocation : Word)
    (checked : TopupGatewayRootCalls.Result Output) : Result :=
  match checked.outcome with
  | .error fault => ⟨.error (.gateway fault),e.before,checked.attempts,[]⟩
  | .ok out =>
    let executed := TopupModuleCall.execute hash m x ctx deposit
      (TopupBatchConsumer.moduleInput out moduleId keys operators ctx.sender allocation e.before) e.before
    ⟨executed.outcome.mapError Error.module,executed.world,checked.attempts,executed.attempts⟩

def run (hash : TopupRouterCredentials.Keccak) (m x : External)
    (e : Environment) (ctx : Context) (deposit : Address) (moduleId : Word)
    (keys operators : List Word) (rows : List Row) (allocation : Word) : Result :=
  match checkLengths (environment e).cfg rows.length keys.length operators.length rows.length rows.length with
  | .error fault => ⟨.error (.gateway fault),e.before,[],[]⟩
  | .ok () => finish hash m x e ctx deposit moduleId keys operators allocation
      (TopupGatewayRootCalls.loop (environment e) none 0 rows)

/-- Concrete simultaneous postcondition: authentication is indexed by the same
ordered row/limit list that supplies moduleInput, whose actual raw reply is bounded. -/
def Success (hash : TopupRouterCredentials.Keccak) (m x : External)
    (e : Environment) (ctx : Context) (deposit : Address) (moduleId : Word)
    (keys operators : List Word) (rows : List Row) (allocation : Word) (result : Result) : Prop :=
  ∃ out ns raw afterModule trace allocations,
    (TopupGatewayRootCalls.loop (environment e) none 0 rows).outcome = .ok out ∧
    TopupWeiBounds.limits (environment e).cfg (rows.map fields) = some ns ∧
    out.pubkeys = rows.map (fun r => r.witness.pubkey) ∧
    out.limits = TopupWeiBounds.weiLimits ns ∧
    out.total = out.limits.sum ∧ out.total < 2^256 ∧
    List.Forall₂ (Authenticated (environment e)) rows ns ∧ Increasing none rows ∧
    result.rootAttempts = rows.flatMap (fun r => (TopupGatewayRootCalls.verify (environment e) r).attempts) ∧
    TopupModuleCall.call hash m (LidoSRv3.Audit.Verity.TopupBeaconFundedTx.routerContext ctx)
      (TopupBatchConsumer.moduleInput out moduleId keys operators ctx.sender allocation e.before) e.before =
        ⟨.ok raw,afterModule,trace⟩ ∧
    TopupModuleCall.decodeReturn raw = .ok allocations ∧
    (TopupRouterContinuation.values allocations).sum ≤
      (TopupBatchConsumer.blockCap ctx.sender e.before).val * 10^9 ∧
    let executed := TopupModuleCall.execute hash m x ctx deposit
      (TopupBatchConsumer.moduleInput out moduleId keys operators ctx.sender allocation e.before) e.before
    executed.outcome = .ok () ∧ result.world = executed.world ∧
      result.moduleAttempts = executed.attempts

theorem run_success (hash : TopupRouterCredentials.Keccak) (m x : External)
    (e : Environment) (ctx : Context) (deposit : Address) (moduleId : Word)
    (keys operators : List Word) (rows : List Row) (allocation : Word)
    (h : (run hash m x e ctx deposit moduleId keys operators rows allocation).outcome = .ok ()) :
    Success hash m x e ctx deposit moduleId keys operators rows allocation
      (run hash m x e ctx deposit moduleId keys operators rows allocation) := by
  unfold run at h ⊢
  cases hc : checkLengths (environment e).cfg rows.length keys.length operators.length rows.length rows.length with
  | «error» fault => simp [hc] at h
  | ok u =>
    cases u
    simp only [hc] at h ⊢
    cases hl : (TopupGatewayRootCalls.loop (environment e) none 0 rows).outcome with
    | «error» fault => simp [finish,hl] at h
    | ok out =>
      simp only [finish,hl] at h ⊢
      have hs : (TopupModuleCall.execute hash m x ctx deposit
          (TopupBatchConsumer.moduleInput out moduleId keys operators ctx.sender allocation e.before) e.before).outcome = .ok () := by
        cases he : (TopupModuleCall.execute hash m x ctx deposit
            (TopupBatchConsumer.moduleInput out moduleId keys operators ctx.sender allocation e.before) e.before).outcome with
        | «error» fault => simp [he,Except.mapError] at h
        | ok u => cases u; rfl
      obtain ⟨ns,heval,hkeys,hlimits,htotal,hauth,horder,htrace⟩ :=
        TopupGatewayRootCalls.loop_success (environment e) rows none 0 out hl
      have hcount : (rows.map fields).length ≤ (environment e).cfg.maxValidators.val := by
        simpa using ((checkLengths_iff _ _ _ _ _ _).mp hc).2.2.2.2.2
      obtain ⟨_,hfit,hexact⟩ := TopupWeiBounds.gateway_wei_bounds (environment e).cfg (rows.map fields) ns hcount heval
      obtain ⟨raw,afterModule,trace,allocations,total,hcall,hdecode,hguard,htarget,_⟩ :=
        TopupRouterCommitted.module_execute_success hash m x ctx deposit
          (TopupBatchConsumer.moduleInput out moduleId keys operators ctx.sender allocation e.before) e.before hs
      have hwords : TopupRouterContinuation.values
          (TopupBatchConsumer.moduleInput out moduleId keys operators ctx.sender allocation e.before).limits =
          TopupWeiBounds.weiLimits ns := by
        change TopupRouterContinuation.values (out.limits.map word) = _
        rw [hlimits,wei_word_values]
      obtain ⟨hguards,hsum⟩ := TopupRouterContinuation.guardSum_spec _ _ _ _ hguard
      rw [hwords] at hguards
      have he := TopupWeiBounds.router_unchecked_sum_exact (environment e).cfg (rows.map fields) ns
        (TopupRouterContinuation.values allocations) hcount heval hguards
      have ht : total = (TopupRouterContinuation.values allocations).sum := hsum.trans he
      have ho : out.total = (TopupWeiBounds.weiLimits ns).sum := by
        rw [htotal,hlimits,hexact]
      refine ⟨out,ns,raw,afterModule,trace,allocations,hl,heval,hkeys,hlimits,?_,?_,hauth,horder,htrace,hcall,hdecode,?_,hs,rfl,rfl⟩
      · rw [ho,hlimits]
      · rw [ho]; exact hfit
      · rw [← ht]
        exact Nat.le_trans htarget (TopupBatchConsumer.target_bound ctx.sender allocation e.before)

/-- Root failures have no writable effects; later module/continuation failure
uses the existing rollback wrapper, retaining both diagnostic attempt phases. -/
theorem failure_restores (hash : TopupRouterCredentials.Keccak) (m x : External)
    (e : Environment) (ctx : Context) (deposit : Address) (moduleId : Word)
    (keys operators : List Word) (rows : List Row) (allocation : Word) (fault : Error)
    (h : (run hash m x e ctx deposit moduleId keys operators rows allocation).outcome = .error fault) :
    (run hash m x e ctx deposit moduleId keys operators rows allocation).world = e.before := by
  unfold run at h ⊢
  cases hc : checkLengths (environment e).cfg rows.length keys.length operators.length rows.length rows.length with
  | «error» f => rfl
  | ok u =>
    cases u
    simp only [hc] at h ⊢
    cases ho : (TopupGatewayRootCalls.loop (environment e) none 0 rows).outcome with
    | «error» f => simp only [finish,ho]
    | ok out =>
      simp only [finish,ho] at h ⊢
      cases hm : (TopupModuleCall.execute hash m x ctx deposit
          (TopupBatchConsumer.moduleInput out moduleId keys operators ctx.sender allocation e.before) e.before).outcome with
      | ok u => simp [hm,Except.mapError] at h
      | «error» f => exact TopupModuleCall.failure_restores hash m x ctx deposit _ e.before f hm

#print axioms run_success
#print axioms failure_restores
end LidoSRv3.Audit.Source.TopupBatchRootCalls
