import LidoSRv3.Audit.Source.TopupTimingHistory

/-! The complete physical getter / actual-root / module / memory conclusion
is retained on the exact intermediate result. Temporal guards precede all
attempts; history uses the executed witness total and actual returned World.
Role/pause/locator and the outer gateway-to-router CALL, full memory/gas and
LOG bytes remain the explicitly typed phase boundaries. -/
set_option autoImplicit false
namespace LidoSRv3.Audit.Guarantees.PTopupTimingHistory
open Source Source.TrioReserve1 Live TopupGatewayWitnessBatch TopupCredentialCall
open TopupTimingHistory

/-- Verbatim full 3674 public conjunction, named only to make the added final
world and trace relation readable. It refers to the same actual old run. -/
def IntermediateEffects
    (credentialCursor returnBuffer : Word) (hash : TopupRouterCredentials.Keccak) (m x : External)
    (e : TopupGatewayRootCalls.Environment) (ctx : Context) (deposit : Address) (moduleId : Word)
    (keys operators : List Word) (rows : List Row) (allocation : Word) : Prop :=
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
        postRaw.val ≤ next.val ∧ next.val < 2^64

def HistoryEffects (gateway : Address) (total : Nat) (before after : World) : Prop :=
  after = finishHistory gateway total before ∧
  (total = 0 → after = before) ∧
  (total ≠ 0 →
    after = update gateway before ∧
    after.logs = before.logs ++ [historyEvent gateway before] ∧
    (stored gateway after).val % 2^64 = (stored gateway before).val % 2^64 ∧
    (stored gateway after).val / 2^64 % 2^32 = before.core.blockTimestamp.val % 2^32 ∧
    (stored gateway after).val / 2^96 % 2^32 = before.core.blockNumber.val % 2^32 ∧
    (stored gateway after).val / 2^128 = (stored gateway before).val / 2^128)

theorem history_effects (gateway : Address) (total : Nat) (w : World) :
    HistoryEffects gateway total w (finishHistory gateway total w) := by
  refine ⟨rfl,?_,?_⟩
  · intro hz; simp [finishHistory,hz]
  · intro hp
    simp only [finishHistory,if_neg hp]
    refine ⟨trivial,rfl,?_⟩
    rw [update_word]
    exact packed_fields _ _ _

theorem actual_timing_credential_root_module_memory_history
    (credentialCursor returnBuffer : Word) (hash : TopupRouterCredentials.Keccak) (m x : External)
    (e : TopupGatewayRootCalls.Environment) (ctx : Context) (deposit : Address) (moduleId : Word)
    (keys operators : List Word) (rows : List Row) (allocation : Word)
    (h : (TopupTimingHistory.run credentialCursor returnBuffer hash m x e ctx deposit moduleId keys operators rows allocation).outcome = .ok ()) :
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
      HistoryEffects e.gateway out.total s.intermediate.world final.world := by
  obtain ⟨hg,hs,hr⟩ := TopupTimingHistory.run_success credentialCursor returnBuffer hash m x e ctx deposit moduleId keys operators rows allocation h
  have hp := execute_projection credentialCursor returnBuffer hash m x e ctx deposit moduleId keys operators rows allocation
  have ho := hs
  rw [hp] at ho
  have prior := PTopupPhysicalCredentialGetter.actual_physical_credential_root_module_memory_effects
    credentialCursor returnBuffer hash m x e ctx deposit moduleId keys operators rows allocation ho
  obtain ⟨wc,out,hproduced,hloop⟩ := execute_produced credentialCursor returnBuffer hash m x e ctx deposit moduleId keys operators rows allocation hs
  refine ⟨prior,gates_admitted e hg,_,wc,out,rfl,hp,hs,hproduced,hloop,hr,?_,?_,?_,?_,?_⟩
  · rw [hr]; rfl
  · rw [hr]; rfl
  · rw [hr]; rfl
  · rw [hr]; rfl
  · rw [hr]
    simp only [finish,hs,hproduced,Option.map,Option.getD]
    exact history_effects _ _ _

theorem actual_timing_credential_root_module_failure_restores
    (credentialCursor returnBuffer : Word) (hash : TopupRouterCredentials.Keccak) (m x : External)
    (e : TopupGatewayRootCalls.Environment) (ctx : Context) (deposit : Address) (moduleId : Word)
    (keys operators : List Word) (rows : List Row) (allocation : Word) (fault : TopupTimingHistory.Error)
    (h : (TopupTimingHistory.run credentialCursor returnBuffer hash m x e ctx deposit moduleId keys operators rows allocation).outcome = .error fault) :
    (TopupTimingHistory.run credentialCursor returnBuffer hash m x e ctx deposit moduleId keys operators rows allocation).world = e.before :=
  TopupTimingHistory.failure_restores credentialCursor returnBuffer hash m x e ctx deposit moduleId keys operators rows allocation fault h

#print axioms history_effects
#print axioms actual_timing_credential_root_module_memory_history
#print axioms actual_timing_credential_root_module_failure_restores
end LidoSRv3.Audit.Guarantees.PTopupTimingHistory
