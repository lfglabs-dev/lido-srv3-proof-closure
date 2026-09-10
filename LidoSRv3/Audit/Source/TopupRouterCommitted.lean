import LidoSRv3.Audit.Source.TopupBeaconCommitted
import LidoSRv3.Audit.Source.TopupModuleCall

/-! Necessary effects of the existing router/module execution on committed runs.
The statements inspect the actual program result and its same-world calls;
they introduce neither another executor nor a supplied callee-frame law.
The arbitrary module and withdrawal interpreters remain explicit. Their own
physical preservation and the omitted router preamble are still obligations.
-/
namespace LidoSRv3.Audit.Source.TopupRouterCommitted
open TrioReserve1 Live TopupRouterContinuation TopupBeaconCallee
open LidoSRv3.Audit.Verity TopupTx
open LidoSRv3.Audit.SolidityTopup

/-- Actual helper early-return semantics, retained in the committed consumer. -/
def helperAmount (i : TopupRouterContinuation.Input) : Nat :=
  if i.pubkeys = [] then 0 else allocSum (values i.allocations)

def helperCount (i : TopupRouterContinuation.Input) : Nat :=
  if i.pubkeys = [] then 0 else TopupBeaconBatch.nonzeroCount (values i.allocations)

/-- A successful positive suffix exposes the actual withdrawal and helper
transitions. The final core and balances come from the helper's returned world,
and the final log is the actual router event. The count is physical slot32,
relative to the state after the executed withdrawal, not an auxiliary counter. -/
structure PositiveEffects (hash : TopupRouterCredentials.Keccak) (callee : External)
    (ctx : Context) (beacon : Address) (i : TopupRouterContinuation.Input)
    (before : World) (result : Result Unit) (total : Nat) : Prop where
  positive : total ≠ 0
  executed : ∃ withdrawn deposited withdrawalTrace helperTrace,
    Live.run (TopupLiveWithdrawal.suffix callee ctx (word total)) before =
      ⟨.ok (),withdrawn,withdrawalTrace⟩ ∧
    helper hash (TopupBeaconFundedTx.routerContext ctx) beacon i withdrawn =
      ⟨.ok (),deposited,helperTrace⟩ ∧
    deposited.balances ctx.sender = before.balances ctx.sender ∧
    result.world.core = deposited.core ∧
    result.world.balances = deposited.balances ∧
    result.world.logs = deposited.logs ++ [topUpEvent ctx.sender i total] ∧
    result.attempts = withdrawalTrace ++ helperTrace ∧
    CallSpec.Balances withdrawn.balances result.world.balances
      ctx.sender beacon (helperAmount i) ∧
    (result.world.core.readContractSlot beacon.val countSlot).val =
      (withdrawn.core.readContractSlot beacon.val countSlot).val + helperCount i ∧
    (helperCount i > 0 →
      (result.world.core.readContractSlot beacon.val countSlot).val ≤ maxCount)

/-- The guard result and both continuation paths come from the existing
program's success, including zero total, arbitrary key widths and aliases.
No funding, initial capacity, input-length or amount-admission premise is used. -/
theorem continuation_success (hash : TopupRouterCredentials.Keccak) (callee : External)
    (ctx : Context) (beacon : Address) (i : TopupRouterContinuation.Input) (before : World)
    (h : (TopupRouterContinuation.program hash callee ctx beacon i before).outcome = .ok ()) :
    ∃ total, guardSum (values i.allocations) (values i.limits) 0 = .ok total ∧
      total ≤ i.roundedTarget.val ∧
      ((total = 0 ∧ TopupRouterContinuation.program hash callee ctx beacon i before =
        ⟨.ok (),{before with logs := before.logs ++ [topUpEvent ctx.sender i 0]},[]⟩) ∨
       PositiveEffects hash callee ctx beacon i before
        (TopupRouterContinuation.program hash callee ctx beacon i before) total) := by
  cases hg : guardSum (values i.allocations) (values i.limits) 0 with
  | «error» fault => simp [TopupRouterContinuation.program,hg,fail] at h
  | ok total =>
    by_cases ht : total > i.roundedTarget.val
    · simp [TopupRouterContinuation.program,hg,ht,fail] at h
    · refine ⟨total,rfl,Nat.le_of_not_gt ht,?_⟩
      by_cases hz : total = 0
      · subst total
        exact Or.inl ⟨rfl,by simp [TopupRouterContinuation.program,hg]⟩
      · apply Or.inr
        refine ⟨hz,?_⟩
        cases hw : Live.run (TopupLiveWithdrawal.suffix callee ctx (word total)) before with
        | mk withdrawalOutcome withdrawn withdrawalTrace =>
          cases withdrawalOutcome with
          | «error» fault => simp [TopupRouterContinuation.program,hg,ht,hz,bindExec,hw] at h
          | ok u =>
            cases u
            cases hh : helper hash (TopupBeaconFundedTx.routerContext ctx) beacon i withdrawn with
            | mk helperOutcome deposited helperTrace =>
              cases helperOutcome with
              | «error» fault => simp [TopupRouterContinuation.program,hg,ht,hz,bindExec,hw,hh] at h
              | ok v =>
                cases v
                by_cases hf : deposited.balances ctx.sender ≠ before.balances ctx.sender
                · simp [TopupRouterContinuation.program,hg,ht,hz,bindExec,hw,hh,
                    TopupRouterContinuation.finish,hf,fail] at h
                · have hr : TopupRouterContinuation.program hash callee ctx beacon i before =
                      ⟨.ok (),{deposited with logs := deposited.logs ++ [topUpEvent ctx.sender i total]},
                        withdrawalTrace ++ helperTrace⟩ := by
                    simp [TopupRouterContinuation.program,hg,ht,hz,bindExec,hw,hh,
                      TopupRouterContinuation.finish,hf]
                  have hb := TopupBeaconCommitted.helper_success_balances hash
                    (TopupBeaconFundedTx.routerContext ctx) beacon i withdrawn deposited helperTrace hh
                  have hc := TopupBeaconCommitted.helper_success_count hash
                    (TopupBeaconFundedTx.routerContext ctx) beacon i withdrawn deposited helperTrace hh
                  refine ⟨withdrawn,deposited,withdrawalTrace,helperTrace,rfl,hh,
                    Classical.not_not.mp hf,?_,?_,?_,?_,?_,?_,?_⟩
                  · rw [hr]
                  · rw [hr]
                  · rw [hr]
                  · rw [hr]
                  · simpa only [hr,helperAmount,TopupBeaconFundedTx.routerContext] using hb
                  · simpa only [hr,helperCount] using hc.1
                  · simpa only [hr,helperCount] using hc.2

/-- Root rollback wrapper preserves the successful raw program result. -/
theorem execute_success_program (hash : TopupRouterCredentials.Keccak) (callee : External)
    (ctx : Context) (beacon : Address) (i : TopupRouterContinuation.Input) (before : World)
    (h : (TopupRouterContinuation.execute hash callee ctx beacon i before).outcome = .ok ()) :
    TopupRouterContinuation.execute hash callee ctx beacon i before =
      TopupRouterContinuation.program hash callee ctx beacon i before ∧
    (TopupRouterContinuation.program hash callee ctx beacon i before).outcome = .ok () := by
  unfold TopupRouterContinuation.execute Live.run at h ⊢
  dsimp only at h ⊢
  split at *
  · exact ⟨rfl,h⟩
  · cases h

/-- The existing raw module CALL and decoder feed the very continuation whose
physical helper effects were proved above. This theorem consumes success of
the complete existing module executor; no module reply or later world is an
input premise. Module effects before the suffix remain in its returned world. -/
theorem module_execute_success (hash : TopupRouterCredentials.Keccak)
    (moduleExternal withdrawalExternal : External) (ctx : Context) (beacon : Address)
    (i : TopupModuleCall.Input) (before : World)
    (h : (TopupModuleCall.execute hash moduleExternal withdrawalExternal ctx beacon i before).outcome = .ok ()) :
    ∃ raw afterModule moduleTrace allocations total,
      TopupModuleCall.call hash moduleExternal (TopupBeaconFundedTx.routerContext ctx) i before =
        ⟨.ok raw,afterModule,moduleTrace⟩ ∧
      TopupModuleCall.decodeReturn raw = .ok allocations ∧
      guardSum (values allocations) (values i.limits) 0 = .ok total ∧
      total ≤ i.roundedTarget.val ∧
      let ci := TopupModuleCall.continuationInput i allocations
      let suffixResult := TopupRouterContinuation.program hash withdrawalExternal ctx beacon ci afterModule
      (TopupModuleCall.execute hash moduleExternal withdrawalExternal ctx beacon i before).world = suffixResult.world ∧
      (TopupModuleCall.execute hash moduleExternal withdrawalExternal ctx beacon i before).attempts =
        moduleTrace ++ suffixResult.attempts ∧
      ((total = 0 ∧ suffixResult =
        ⟨.ok (),{afterModule with logs := afterModule.logs ++ [topUpEvent ctx.sender ci 0]},[]⟩) ∨
       PositiveEffects hash withdrawalExternal ctx beacon ci afterModule suffixResult total) := by
  have he : TopupModuleCall.execute hash moduleExternal withdrawalExternal ctx beacon i before =
      TopupModuleCall.program hash moduleExternal withdrawalExternal ctx beacon i before := by
    unfold TopupModuleCall.execute Live.run at h ⊢
    dsimp only at h ⊢
    split at *
    · rfl
    · cases h
  rw [he] at h ⊢
  obtain ⟨raw,afterModule,moduleTrace,allocations,hcall,hdecode,hs,hworld,htrace⟩ :=
    TopupModuleCall.program_success_origin hash moduleExternal withdrawalExternal ctx beacon i before h
  obtain ⟨total,hguard,htarget,heffects⟩ := continuation_success hash withdrawalExternal ctx beacon
    (TopupModuleCall.continuationInput i allocations) afterModule hs
  exact ⟨raw,afterModule,moduleTrace,allocations,total,hcall,hdecode,hguard,htarget,hworld,htrace,heffects⟩

#print axioms continuation_success
#print axioms execute_success_program
#print axioms module_execute_success
end LidoSRv3.Audit.Source.TopupRouterCommitted
