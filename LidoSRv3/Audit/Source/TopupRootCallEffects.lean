import LidoSRv3.Audit.Source.TopupBatchRootCalls

/-! Necessary physical effects of the existing actual root/module batch.
No executor is introduced. Root-authenticated rows produce the very arrays
whose module reply feeds the existing zero/positive committed continuation. -/
namespace LidoSRv3.Audit.Source.TopupRootCallEffects
open TrioReserve1 Live TopupGatewayWitnessBatch

/-- Same ordered witness/limit relation, actual module reply, and its executed
continuation. PositiveEffects includes physical beacon slot32, helper balances,
actual withdrawal/helper worlds, events and attempts relative to afterModule.
No pre-module conservation or arbitrary-module locator frame is asserted. -/
def Effects (hash : TopupRouterCredentials.Keccak) (m x : External)
    (e : TopupGatewayRootCalls.Environment) (ctx : Context) (deposit : Address) (moduleId : Word)
    (keys operators : List Word) (rows : List Row) (allocation : Word)
    (result : TopupBatchRootCalls.Result) : Prop :=
  ∃ out ns raw afterModule trace allocations,
    (TopupGatewayRootCalls.loop (TopupBatchRootCalls.environment e) none 0 rows).outcome = .ok out ∧
    TopupWeiBounds.limits (TopupBatchRootCalls.environment e).cfg (rows.map fields) = some ns ∧
    List.Forall₂ (TopupGatewayRootCalls.Authenticated (TopupBatchRootCalls.environment e)) rows ns ∧
    Increasing none rows ∧
    out.pubkeys = rows.map (fun r => r.witness.pubkey) ∧
    out.limits = TopupWeiBounds.weiLimits ns ∧
    result.rootAttempts = rows.flatMap (fun r => (TopupGatewayRootCalls.verify (TopupBatchRootCalls.environment e) r).attempts) ∧
    TopupModuleCall.call hash m (LidoSRv3.Audit.Verity.TopupBeaconFundedTx.routerContext ctx)
      (TopupBatchConsumer.moduleInput out moduleId keys operators ctx.sender allocation e.before) e.before =
        ⟨.ok raw,afterModule,trace⟩ ∧
    TopupModuleCall.decodeReturn raw = .ok allocations ∧
    (TopupRouterContinuation.values allocations).sum < 2^256 ∧
    (TopupRouterContinuation.values allocations).sum ≤ (TopupBatchConsumer.blockCap ctx.sender e.before).val * 10^9 ∧
    let ci := TopupModuleCall.continuationInput
      (TopupBatchConsumer.moduleInput out moduleId keys operators ctx.sender allocation e.before) allocations
    let suffix := TopupRouterContinuation.program hash x ctx deposit ci afterModule
    TopupRouterContinuation.guardSum (TopupRouterContinuation.values allocations)
      (TopupRouterContinuation.values ci.limits) 0 = .ok (TopupRouterContinuation.values allocations).sum ∧
    result.world = suffix.world ∧ result.moduleAttempts = trace ++ suffix.attempts ∧
    (((TopupRouterContinuation.values allocations).sum = 0 ∧
      suffix = ⟨.ok (),{afterModule with logs := afterModule.logs ++
        [TopupRouterContinuation.topUpEvent ctx.sender ci 0]},[]⟩) ∨
     TopupRouterCommitted.PositiveEffects hash x ctx deposit ci afterModule suffix
       (TopupRouterContinuation.values allocations).sum)

theorem run_success (hash : TopupRouterCredentials.Keccak) (m x : External)
    (e : TopupGatewayRootCalls.Environment) (ctx : Context) (deposit : Address) (moduleId : Word)
    (keys operators : List Word) (rows : List Row) (allocation : Word)
    (h : (TopupBatchRootCalls.run hash m x e ctx deposit moduleId keys operators rows allocation).outcome = .ok ()) :
    Effects hash m x e ctx deposit moduleId keys operators rows allocation
      (TopupBatchRootCalls.run hash m x e ctx deposit moduleId keys operators rows allocation) := by
  obtain ⟨out,ns,_,_,_,_,hl,heval,hkeys,hlimits,htotal,hfit,hauth,horder,hroots,_,_,_,hs,hworld,htrace⟩ :=
    TopupBatchRootCalls.run_success hash m x e ctx deposit moduleId keys operators rows allocation h
  obtain ⟨raw,afterModule,trace,allocations,total,hcall,hdecode,hguard,htarget,hw,ht,heffects⟩ :=
    TopupRouterCommitted.module_execute_success hash m x ctx deposit
      (TopupBatchConsumer.moduleInput out moduleId keys operators ctx.sender allocation e.before) e.before hs
  have hwords : TopupRouterContinuation.values
      (TopupBatchConsumer.moduleInput out moduleId keys operators ctx.sender allocation e.before).limits = out.limits := by
    change TopupRouterContinuation.values (out.limits.map word) = _
    rw [hlimits,wei_word_values]
  obtain ⟨hg,hacc⟩ := TopupRouterContinuation.guardSum_spec _ _ _ _ hguard
  rw [hwords] at hg
  have hsum : (TopupRouterContinuation.values allocations).sum < TopupWeiBounds.wordModulus := by
    have hb := TopupWeiBounds.allocations_sum_le _ _ hg
    rw [htotal] at hfit
    exact Nat.lt_of_le_of_lt hb hfit
  have hexact : total = (TopupRouterContinuation.values allocations).sum := by
    rw [hacc,TopupWeiBounds.uncheckedSum_exact _ 0 (by simpa using hsum),Nat.zero_add]
  refine ⟨out,ns,raw,afterModule,trace,allocations,hl,heval,hauth,horder,hkeys,hlimits,hroots,
    hcall,hdecode,hsum,?_,?_,hworld.trans hw,htrace.trans ht,?_⟩
  · rw [← hexact]
    exact Nat.le_trans htarget (TopupBatchConsumer.target_bound ctx.sender allocation e.before)
  · simpa only [hexact,TopupModuleCall.continuationInput] using hguard
  · simpa only [hexact] using heffects

#print axioms run_success
end LidoSRv3.Audit.Source.TopupRootCallEffects
