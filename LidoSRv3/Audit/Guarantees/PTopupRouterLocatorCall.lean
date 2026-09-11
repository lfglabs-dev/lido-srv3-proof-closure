import LidoSRv3.Audit.Source.TopupRouterLocatorCall

/-! Actual locator return selects the router consumed by the entire accepted
TOPUP335 conclusion, including its intermediate world, journals and history.
The immutable locator address is a phase input; deployed locator behavior and
the outer gateway-to-router topUp CALL are not proved by changing Context.sender. -/
set_option autoImplicit false
namespace LidoSRv3.Audit.Guarantees.PTopupRouterLocatorCall
open Source Source.TrioReserve1 Live TopupGatewayWitnessBatch
open TopupTimingHistory PTopupTimingHistory
open TopupCredentialCall (resolved)

/-- Verbatim full TOPUP335 public conjunction on the same selected-router run. -/
def TimingEffects
    (credentialCursor returnBuffer : Word) (hash : TopupRouterCredentials.Keccak) (m x : External)
    (e : TopupGatewayRootCalls.Environment) (ctx : Context) (deposit : Address) (moduleId : Word)
    (keys operators : List Word) (rows : List Row) (allocation : Word) : Prop :=
    IntermediateEffects credentialCursor returnBuffer hash m x e ctx deposit moduleId keys operators rows allocation ∧
    Admitted e ∧
    ∃ s wc out,
      s = execute credentialCursor returnBuffer hash m x e ctx deposit moduleId keys operators rows allocation ∧
      s.intermediate = TopupPhysicalCredentialGetter.run credentialCursor returnBuffer hash m x e ctx deposit moduleId keys operators rows allocation ∧
      s.intermediate.outcome = .ok () ∧
      s.produced = some (wc,out) ∧
      (TopupGatewayRootCalls.loop (TopupBatchRootCalls.environment (resolved e wc)) none 0 rows).outcome = .ok out ∧
      let final := TopupTimingHistory.run credentialCursor returnBuffer hash m x e ctx deposit moduleId keys operators rows allocation
      final = finish e.gateway s ∧
      final.stage = some s ∧
      final.credentialAttempts = s.intermediate.credentialAttempts ∧
      final.rootAttempts = s.intermediate.rootAttempts ∧
      final.moduleAttempts = s.intermediate.moduleAttempts ∧
      HistoryEffects e.gateway out.total s.intermediate.world final.world

theorem actual_locator_timing_credential_root_module_memory_history
    (locatorCall : StaticCall.External) (locator : Address) (cursor returnBuffer : Word)
    (hash : TopupRouterCredentials.Keccak) (m x : External)
    (e : TopupGatewayRootCalls.Environment) (ctx : Context) (deposit : Address) (moduleId : Word)
    (keys operators : List Word) (rows : List Row) (allocation : Word)
    (h : (TopupRouterLocatorCall.run locatorCall locator cursor returnBuffer hash m x e ctx deposit moduleId keys operators rows allocation).outcome = .ok ()) :
    ∃ router next raw,
      (e.before.core.codeSize locator.val).val ≠ 0 ∧
      locatorCall (TopupRouterLocatorCall.request e.gateway locator) e.before = .success raw ∧
      TopupRouterLocatorCall.decodeRouter cursor raw = .ok (router,next) ∧
      32 ≤ (word raw.length).val ∧ router.val = (word (decode (raw.take 32))).val ∧
      router.val < 2^160 ∧ audit.trio.deposit.ModuleCall.finalizeAllocation cursor 32 = .ok next ∧
      cursor.val + 32 = next.val ∧ next.val < 2^64 ∧
      let selected := TopupRouterLocatorCall.resolved ctx router
      selected.self = ctx.self ∧ selected.sender = router ∧
      let prior := TopupTimingHistory.run next returnBuffer hash m x e selected deposit moduleId keys operators rows allocation
      let result := TopupRouterLocatorCall.run locatorCall locator cursor returnBuffer hash m x e ctx deposit moduleId keys operators rows allocation
      result = TopupRouterLocatorCall.ofTiming [⟨TopupRouterLocatorCall.request e.gateway locator,true,true,raw,1⟩] prior ∧
      result.world = prior.world ∧ result.suffix = some prior ∧
      result.observations = [Sum.inl ⟨TopupRouterLocatorCall.request e.gateway locator,true,true,raw,1⟩] ++
        (prior.credentialAttempts ++ prior.rootAttempts).map Sum.inl ++ prior.moduleAttempts.map Sum.inr ∧
      TimingEffects next returnBuffer hash m x e selected deposit moduleId keys operators rows allocation := by
  obtain ⟨router,next,trace,hq,hs,hr⟩ := TopupRouterLocatorCall.run_success locatorCall locator cursor returnBuffer hash m x e ctx deposit moduleId keys operators rows allocation h
  obtain ⟨hc,raw,ho,hd,hl,hv,h160,ha,he,hb,ht⟩ := TopupRouterLocatorCall.lookup_origin locatorCall e.gateway locator cursor e.before router next trace hq
  subst trace
  refine ⟨router,next,raw,hc,ho,hd,hl,hv,h160,ha,he,hb,rfl,rfl,hr,?_,?_,?_,?_⟩
  · rw [hr]; rfl
  · rw [hr]; rfl
  · rw [hr]; rfl
  · exact PTopupTimingHistory.actual_timing_credential_root_module_memory_history next returnBuffer hash m x e (TopupRouterLocatorCall.resolved ctx router) deposit moduleId keys operators rows allocation hs

theorem actual_locator_timing_credential_root_module_failure_restores
    (locatorCall : StaticCall.External) (locator : Address) (cursor returnBuffer : Word)
    (hash : TopupRouterCredentials.Keccak) (m x : External)
    (e : TopupGatewayRootCalls.Environment) (ctx : Context) (deposit : Address) (moduleId : Word)
    (keys operators : List Word) (rows : List Row) (allocation : Word) (fault : TopupRouterLocatorCall.Error)
    (h : (TopupRouterLocatorCall.run locatorCall locator cursor returnBuffer hash m x e ctx deposit moduleId keys operators rows allocation).outcome = .error fault) :
    (TopupRouterLocatorCall.run locatorCall locator cursor returnBuffer hash m x e ctx deposit moduleId keys operators rows allocation).world = e.before :=
  TopupRouterLocatorCall.failure_restores locatorCall locator cursor returnBuffer hash m x e ctx deposit moduleId keys operators rows allocation fault h

#print axioms actual_locator_timing_credential_root_module_memory_history
#print axioms actual_locator_timing_credential_root_module_failure_restores
end LidoSRv3.Audit.Guarantees.PTopupRouterLocatorCall
