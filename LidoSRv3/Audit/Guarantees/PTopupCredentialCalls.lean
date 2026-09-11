import LidoSRv3.Audit.Source.TopupCredentialCall

/-! Actual credentials lookup joined to the complete existing TOPUP memory
consumer. A typed covered phase, not full topUp admission or deployed locator,
router entry-call, compiled memory alias/copy or gas correspondence. -/
set_option autoImplicit false
namespace LidoSRv3.Audit.Guarantees.PTopupCredentialCalls
open Source Source.TrioReserve1 Live TopupGatewayWitnessBatch TopupCredentialCall

theorem actual_credential_root_module_memory_effects (getter : StaticCall.External)
    (credentialCursor returnBuffer : Word) (hash : TopupRouterCredentials.Keccak) (m x : External)
    (e : TopupGatewayRootCalls.Environment) (ctx : Context) (deposit : Address) (moduleId : Word)
    (keys operators : List Word) (rows : List Row) (allocation : Word)
    (h : (TopupCredentialCall.run getter credentialCursor returnBuffer hash m x e ctx deposit moduleId keys operators rows allocation).outcome = .ok ()) :
    checkLengths (TopupBatchRootCalls.environment e).cfg rows.length keys.length operators.length rows.length rows.length = .ok () ∧
    ∃ wc nextCredential rawCredential,
      (e.before.core.codeSize ctx.sender.val).val ≠ 0 ∧
      getter (request e.gateway ctx.sender moduleId) e.before = .success rawCredential ∧
      decodeCredentials credentialCursor rawCredential = .ok (wc,nextCredential) ∧
      32 ≤ (word rawCredential.length).val ∧ wc = word (decode (rawCredential.take 32)) ∧
      wc.val / 2^248 = 2 ∧
      audit.trio.deposit.ModuleCall.finalizeAllocation credentialCursor 32 = .ok nextCredential ∧
      credentialCursor.val + 32 = nextCredential.val ∧ nextCredential.val < 2^64 ∧
      let e' := resolved e wc
      let result := TopupBatchMemory.run returnBuffer hash m x e' ctx deposit moduleId keys operators rows allocation
      TopupCredentialCall.run getter credentialCursor returnBuffer hash m x e ctx deposit moduleId keys operators rows allocation =
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
  obtain ⟨hl,wc,next,trace,hq,hp,hs,he⟩ := TopupCredentialCall.run_success getter credentialCursor returnBuffer hash m x e ctx deposit moduleId keys operators rows allocation h
  obtain ⟨hc,raw,hcall,hd,hsize,hword,ha,hext,hbound,ht⟩ := lookup_origin getter e.gateway ctx.sender moduleId credentialCursor e.before wc next trace hq
  refine ⟨hl,wc,next,raw,hc,hcall,hd,hsize,hword,hp,ha,hext,hbound,?_,?_⟩
  · exact he.trans (congrArg (fun t => ofBatch t _) ht)
  · exact PTopupMemoryCalls.actual_root_module_memory_effects returnBuffer hash m x (resolved e wc) ctx deposit moduleId keys operators rows allocation hs

theorem actual_credential_root_module_failure_restores (getter : StaticCall.External)
    (credentialCursor returnBuffer : Word) (hash : TopupRouterCredentials.Keccak) (m x : External)
    (e : TopupGatewayRootCalls.Environment) (ctx : Context) (deposit : Address) (moduleId : Word)
    (keys operators : List Word) (rows : List Row) (allocation : Word) (fault : TopupCredentialCall.Error)
    (h : (TopupCredentialCall.run getter credentialCursor returnBuffer hash m x e ctx deposit moduleId keys operators rows allocation).outcome = .error fault) :
    (TopupCredentialCall.run getter credentialCursor returnBuffer hash m x e ctx deposit moduleId keys operators rows allocation).world = e.before :=
  TopupCredentialCall.failure_restores getter credentialCursor returnBuffer hash m x e ctx deposit moduleId keys operators rows allocation fault h

#print axioms actual_credential_root_module_memory_effects
#print axioms actual_credential_root_module_failure_restores
end LidoSRv3.Audit.Guarantees.PTopupCredentialCalls
