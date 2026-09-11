import LidoSRv3.Audit.Source.TopupEntryAdmission
set_option autoImplicit false
namespace LidoSRv3.Audit.Guarantees.PTopupEntryAdmission
open Source Source.TrioReserve1 Live TopupGatewayWitnessBatch
open TopupTimingHistory PTopupTimingHistory PTopupRouterLocatorCall
open TopupCredentialCall (resolved)

/-- Physical role and resume gates are actually executed before the full retained
locator/credentials/root/module/history phase. No role or resumed premise. -/
theorem actual_physical_entry_locator_timing_credential_root_module_memory_history
    (caller : Address) (locatorCall : StaticCall.External) (locator : Address) (cursor returnBuffer : Word)
    (hash : TopupRouterCredentials.Keccak) (m x : External)
    (e : TopupGatewayRootCalls.Environment) (ctx : Context) (deposit : Address) (moduleId : Word)
    (keys operators : List Word) (rows : List Row) (allocation : Word)
    (h : (TopupEntryAdmission.run caller locatorCall locator cursor returnBuffer hash m x e ctx deposit moduleId keys operators rows allocation).outcome = .ok ()) :
    TopupEntryAdmission.Admitted e.gateway caller e.before ∧
    TopupEntryAdmission.run caller locatorCall locator cursor returnBuffer hash m x e ctx deposit moduleId keys operators rows allocation = TopupEntryAdmission.ofPrior (TopupRouterLocatorCall.run locatorCall locator cursor returnBuffer hash m x e ctx deposit moduleId keys operators rows allocation) ∧
    (∃ router next raw,
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
      TimingEffects next returnBuffer hash m x e selected deposit moduleId keys operators rows allocation) := by
  obtain ⟨ha,hp,he⟩ := TopupEntryAdmission.run_success caller locatorCall locator cursor returnBuffer hash m x e ctx deposit moduleId keys operators rows allocation h
  exact ⟨ha,he,actual_locator_timing_credential_root_module_memory_history locatorCall locator cursor returnBuffer hash m x e ctx deposit moduleId keys operators rows allocation hp⟩

theorem actual_physical_entry_failure_restores (caller : Address) (locatorCall : StaticCall.External) (locator : Address) (cursor returnBuffer : Word)
    (hash : TopupRouterCredentials.Keccak) (m x : External) (e : TopupGatewayRootCalls.Environment) (ctx : Context)
    (deposit : Address) (moduleId : Word) (keys operators : List Word) (rows : List Row)
    (allocation : Word) (fault : TopupEntryAdmission.Error)
    (h : (TopupEntryAdmission.run caller locatorCall locator cursor returnBuffer hash m x e ctx deposit moduleId keys operators rows allocation).outcome = .error fault) :
    (TopupEntryAdmission.run caller locatorCall locator cursor returnBuffer hash m x e ctx deposit moduleId keys operators rows allocation).world = e.before :=
  TopupEntryAdmission.failure_restores caller locatorCall locator cursor returnBuffer hash m x e ctx deposit moduleId keys operators rows allocation fault h

#print axioms actual_physical_entry_locator_timing_credential_root_module_memory_history
#print axioms actual_physical_entry_failure_restores
end LidoSRv3.Audit.Guarantees.PTopupEntryAdmission
