import LidoSRv3.Audit.Source.TopupBatchMemory

/-! Additive TOPUP-1/2 phase claim with actual module-return scalar allocator
checks. The explicit returnBuffer is the phase input, not a proven initial
cursor. Earlier memory provenance, byte-copy semantics and opcode gas retain
the stated boundary; no extra bound or successful-stage premise is used. -/
set_option autoImplicit false
namespace LidoSRv3.Audit.Guarantees.PTopupMemoryCalls
open Source Source.TrioReserve1.Live Source.TopupGatewayWitnessBatch

/-- Actual root calls and consumed witnesses, module reply and guarded memory
allocation, exact sum/cap, and zero/physical positive effects on the same World. -/
theorem actual_root_module_memory_effects (returnBuffer : Word)
    (hash : TopupRouterCredentials.Keccak) (m x : External)
    (e : TopupGatewayRootCalls.Environment) (ctx : Context) (deposit : Address) (moduleId : Word)
    (keys operators : List Word) (rows : List Row) (allocation : Word)
    (h : (TopupBatchMemory.run returnBuffer hash m x e ctx deposit moduleId keys operators rows allocation).outcome = .ok ()) :
    let result := TopupBatchMemory.run returnBuffer hash m x e ctx deposit moduleId keys operators rows allocation
    TopupBatchRootCalls.Success hash m x e ctx deposit moduleId keys operators rows allocation result ∧
    TopupRootCallEffects.Effects hash m x e ctx deposit moduleId keys operators rows allocation result ∧
    ∃ out raw after trace allocations next postRaw,
      (TopupGatewayRootCalls.loop (TopupBatchRootCalls.environment e) none 0 rows).outcome = .ok out ∧
      TopupModuleCall.call hash m (LidoSRv3.Audit.Verity.TopupBeaconFundedTx.routerContext ctx)
        (TopupBatchConsumer.moduleInput out moduleId keys operators ctx.sender allocation e.before) e.before =
        ⟨.ok raw,after,trace⟩ ∧
      TopupModuleMemory.decodeReturn returnBuffer raw = .ok (allocations,next) ∧
      audit.trio.deposit.ModuleCall.finalizeAllocation returnBuffer (word raw.length).val = .ok postRaw ∧
      returnBuffer.val + (word raw.length).val ≤ postRaw.val ∧ postRaw.val < 2^64 ∧
      audit.trio.deposit.ModuleCall.finalizeAllocation postRaw
        (32*(decode ((raw.drop (decode (raw.take 32))).take 32))+32) = .ok next ∧
      postRaw.val ≤ next.val ∧ next.val < 2^64 := by
  obtain ⟨he,out,raw,after,trace,allocations,next,hl,hc,hd⟩ :=
    TopupBatchMemory.run_success returnBuffer hash m x e ctx deposit moduleId keys operators rows allocation h
  have ho := h
  rw [he] at ho
  obtain ⟨_,postRaw,ha,hraw,hr,hn,hmono,hnext⟩ := TopupModuleMemory.decode_success returnBuffer next raw allocations hd
  refine ⟨?_,?_,out,raw,after,trace,allocations,next,postRaw,hl,hc,hd,ha,hraw,hr,hn,hmono,hnext⟩
  · rw [he]
    exact TopupBatchRootCalls.run_success hash m x e ctx deposit moduleId keys operators rows allocation ho
  · rw [he]
    exact TopupRootCallEffects.run_success hash m x e ctx deposit moduleId keys operators rows allocation ho

theorem actual_root_module_memory_failure_restores (returnBuffer : Word)
    (hash : TopupRouterCredentials.Keccak) (m x : External)
    (e : TopupGatewayRootCalls.Environment) (ctx : Context) (deposit : Address) (moduleId : Word)
    (keys operators : List Word) (rows : List Row) (allocation : Word) (fault : TopupBatchRootCalls.Error)
    (h : (TopupBatchMemory.run returnBuffer hash m x e ctx deposit moduleId keys operators rows allocation).outcome = .error fault) :
    (TopupBatchMemory.run returnBuffer hash m x e ctx deposit moduleId keys operators rows allocation).world = e.before :=
  TopupBatchMemory.failure_restores returnBuffer hash m x e ctx deposit moduleId keys operators rows allocation fault h

#print axioms actual_root_module_memory_effects
#print axioms actual_root_module_memory_failure_restores
end LidoSRv3.Audit.Guarantees.PTopupMemoryCalls
