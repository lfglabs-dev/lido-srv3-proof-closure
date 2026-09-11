import LidoSRv3.Audit.Source.TopupPhysicalCredentialGetter

/-! Physical credentials getter joined to the complete existing TOPUP memory
consumer. A typed covered phase, not full topUp admission or deployed locator,
router entry-call, compiled memory alias/copy or gas correspondence. -/
set_option autoImplicit false
namespace LidoSRv3.Audit.Guarantees.PTopupPhysicalCredentialGetter
open Source Source.TrioReserve1 Live TopupGatewayWitnessBatch TopupCredentialCall

theorem actual_physical_credential_root_module_memory_effects
    (credentialCursor returnBuffer : Word) (hash : TopupRouterCredentials.Keccak) (m x : External)
    (e : TopupGatewayRootCalls.Environment) (ctx : Context) (deposit : Address) (moduleId : Word)
    (keys operators : List Word) (rows : List Row) (allocation : Word)
    (h : (TopupPhysicalCredentialGetter.run credentialCursor returnBuffer hash m x e ctx deposit moduleId keys operators rows allocation).outcome = .ok ()) :
    checkLengths (TopupBatchRootCalls.environment e).cfg rows.length keys.length operators.length rows.length rows.length = .ok () ∧
    ∃ wc nextCredential rawCredential,
      TopupPhysicalCredentialGetter.membership hash ctx.sender moduleId e.before ≠ 0 ∧
      rawCredential = encode 32 (TopupPhysicalCredentialGetter.selected hash ctx.sender moduleId e.before).val ∧
      wc = TopupPhysicalCredentialGetter.selected hash ctx.sender moduleId e.before ∧
      TopupRouterCredentials.typeOf (e.before.core.readContractSlot ctx.sender.val
        (TopupRouterCredentials.moduleSlot hash moduleId)) = 2 ∧
      wc.val % 2^248 = (TopupRouterCredentials.raw ctx.sender e.before).val % 2^248 ∧
      (e.before.core.codeSize ctx.sender.val).val ≠ 0 ∧
      TopupPhysicalCredentialGetter.dispatch hash (request e.gateway ctx.sender moduleId) e.before = .success rawCredential ∧
      decodeCredentials credentialCursor rawCredential = .ok (wc,nextCredential) ∧
      32 ≤ (word rawCredential.length).val ∧ wc = word (decode (rawCredential.take 32)) ∧
      wc.val / 2^248 = 2 ∧
      audit.trio.deposit.ModuleCall.finalizeAllocation credentialCursor 32 = .ok nextCredential ∧
      credentialCursor.val + 32 = nextCredential.val ∧ nextCredential.val < 2^64 ∧
      let e' := resolved e wc
      let result := TopupBatchMemory.run returnBuffer hash m x e' ctx deposit moduleId keys operators rows allocation
      TopupPhysicalCredentialGetter.run credentialCursor returnBuffer hash m x e ctx deposit moduleId keys operators rows allocation =
        ofBatch [⟨request e.gateway ctx.sender moduleId,true,true,rawCredential,1⟩] result ∧
      TopupBatchRootCalls.Success hash m x e' ctx deposit moduleId keys operators rows allocation result ∧
      TopupRootCallEffects.Effects hash m x e' ctx deposit moduleId keys operators rows allocation result ∧
      ∃ out raw after trace allocations next postRaw,
        (TopupGatewayRootCalls.loop (TopupBatchRootCalls.environment e') none 0 rows).outcome = .ok out ∧
        TopupModuleCall.call hash m (LidoSRv3.Audit.Verity.TopupBeaconFundedTx.routerContext ctx)
          (TopupBatchConsumer.moduleInput out moduleId keys operators ctx.sender allocation e'.before) e'.before =
          ⟨.ok raw,after,trace⟩ ∧
        TopupModuleMemory.decodeReturn returnBuffer raw = .ok (allocations,next) ∧
        audit.trio.deposit.ModuleCall.finalizeAllocation returnBuffer (word raw.length).val = .ok postRaw ∧
        returnBuffer.val + (word raw.length).val ≤ postRaw.val ∧ postRaw.val < 2^64 ∧
        audit.trio.deposit.ModuleCall.finalizeAllocation postRaw
          (32*(decode ((raw.drop (decode (raw.take 32))).take 32))+32) = .ok next ∧
        postRaw.val ≤ next.val ∧ next.val < 2^64 := by
  obtain ⟨hl,wc,next,raw,hc,hcall,hd,hsize,hword,hp,ha,hext,hbound,hrest⟩ :=
    PTopupCredentialCalls.actual_credential_root_module_memory_effects
      (TopupPhysicalCredentialGetter.dispatch hash) credentialCursor returnBuffer hash m x e ctx deposit moduleId keys operators rows allocation h
  obtain ⟨hm,hr,hw⟩ := TopupPhysicalCredentialGetter.response_fields hash e.gateway ctx.sender moduleId credentialCursor e.before wc next raw hcall hd
  have fields := TopupPhysicalCredentialGetter.selected_fields hash ctx.sender moduleId e.before
  have ht : TopupRouterCredentials.typeOf (e.before.core.readContractSlot ctx.sender.val
      (TopupRouterCredentials.moduleSlot hash moduleId)) = 2 := by
    rw [← fields.1,← hw]
    exact hp
  refine ⟨hl,wc,next,raw,hm,hr,hw,ht,?_,hc,hcall,hd,hsize,hword,hp,ha,hext,hbound,hrest⟩
  rw [hw]
  exact fields.2

theorem actual_physical_credential_root_module_failure_restores
    (credentialCursor returnBuffer : Word) (hash : TopupRouterCredentials.Keccak) (m x : External)
    (e : TopupGatewayRootCalls.Environment) (ctx : Context) (deposit : Address) (moduleId : Word)
    (keys operators : List Word) (rows : List Row) (allocation : Word) (fault : TopupCredentialCall.Error)
    (h : (TopupPhysicalCredentialGetter.run credentialCursor returnBuffer hash m x e ctx deposit moduleId keys operators rows allocation).outcome = .error fault) :
    (TopupPhysicalCredentialGetter.run credentialCursor returnBuffer hash m x e ctx deposit moduleId keys operators rows allocation).world = e.before :=
  TopupCredentialCall.failure_restores (TopupPhysicalCredentialGetter.dispatch hash) credentialCursor returnBuffer hash m x e ctx deposit moduleId keys operators rows allocation fault h

#print axioms actual_physical_credential_root_module_memory_effects
#print axioms actual_physical_credential_root_module_failure_restores
end LidoSRv3.Audit.Guarantees.PTopupPhysicalCredentialGetter
