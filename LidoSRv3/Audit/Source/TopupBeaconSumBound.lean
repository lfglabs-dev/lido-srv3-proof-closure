import LidoSRv3.Audit.Source.TopupRouterCommitted

namespace LidoSRv3.Audit.Source.TopupBeaconSumBound
open TrioReserve1 Live TopupBeaconBatch TopupBeaconCallee TopupBeaconCommitted
open LidoSRv3.Audit.Verity TopupTx LidoSRv3.Audit.SolidityTopup
open DepositDataRootCorrespondence

set_option maxRecDepth 4096 in
/-- Every amount bound is derived from the guards of the executed loop,
including zeros; no supplied amount-admission predicate is needed. -/
theorem loop_success_amount_bounds (ctx : Context) (target : Address)
    (inputs : List SourceDepositDataRootInput) :
    ∀ (amounts : List Nat) (before after : World) (trace : List Attempt),
    TopupBeaconBatch.loop ctx target inputs amounts before = ⟨.ok (),after,trace⟩ →
    ∀ a ∈ amounts, a < 2^64 * 10^9 := by
  induction inputs with
  | nil =>
    intro amounts before after trace h
    cases amounts with
    | nil =>
      simp only [TopupBeaconBatch.loop,pureExec,Result.mk.injEq] at h
      rcases h with ⟨_,rfl,_⟩
      simp
    | cons a rest => simp only [decide_true,decide_false,if_true,if_false,Result.mk.injEq,Bool.false_eq_true,reduceCtorEq,false_and,List.nil_append,TopupBeaconBatch.loop,fail] at h
  | cons input inputs ih =>
    intro amounts before after trace h
    cases amounts with
    | nil => simp only [decide_true,decide_false,if_true,if_false,Result.mk.injEq,Bool.false_eq_true,reduceCtorEq,false_and,List.nil_append,TopupBeaconBatch.loop,fail] at h
    | cons a rest =>
      by_cases hpk : input.publicKey.length = 48
      · by_cases hz : a = 0
        · subst a
          have ht : TopupBeaconBatch.loop ctx target inputs rest before = ⟨.ok (),after,trace⟩ := by
            simpa only [decide_true,decide_false,if_true,if_false,List.nil_append,
              TopupBeaconBatch.loop,hpk,require,bind,bindExec,pure,pureExec] using h
          have hb := ih rest before after trace ht
          intro x hx
          rcases List.mem_cons.mp hx with rfl | hx
          · decide
          · exact hb x hx
        · by_cases hmin : 10^18 ≤ a
          · by_cases hmax : a / 10^9 ≤ 2^64-1
            · have hv : a < 2^64 * 10^9 := by
                have hr := Nat.mod_lt a (show 0 < 10^9 by decide)
                have he := Nat.mod_add_div a (10^9)
                omega
              cases hp : TopupBeaconEffects.push sha256 ctx target
                  (TopupBeaconEffects.sourcePayload input) (word a) before with
              | mk outcome middle firstTrace =>
                cases outcome with
                | «error» err =>
                  simp only [decide_true,decide_false,if_true,if_false,Result.mk.injEq,Bool.false_eq_true,reduceCtorEq,false_and,List.nil_append,TopupBeaconBatch.loop,hpk,hz,hmin,hmax,require,bind,bindExec,pure,pureExec,hp] at h
                | ok data =>
                  cases ht : TopupBeaconBatch.loop ctx target inputs rest middle with
                  | mk tailOutcome last tailTrace =>
                    cases tailOutcome with
                    | «error» err =>
                      simp only [decide_true,decide_false,if_true,if_false,Result.mk.injEq,Bool.false_eq_true,reduceCtorEq,false_and,List.nil_append,TopupBeaconBatch.loop,hpk,hz,hmin,hmax,require,bind,bindExec,pure,pureExec,hp,ht] at h
                    | ok u =>
                      cases u
                      simp only [TopupBeaconBatch.loop,hpk,decide_true,require,if_true,bind,bindExec,
                        pure,pureExec,if_neg hz,hmin,hmax,hp,ht,Result.mk.injEq] at h
                      have hw : last = after := h.2.1
                      subst after
                      have hbounds := ih rest middle last tailTrace ht
                      intro x hx
                      rcases List.mem_cons.mp hx with rfl | hx
                      · exact hv
                      · exact hbounds x hx
            · simp only [decide_true,decide_false,if_true,if_false,Result.mk.injEq,Bool.false_eq_true,reduceCtorEq,false_and,List.nil_append,TopupBeaconBatch.loop,hpk,hz,hmin,hmax,require,bind,bindExec,pure,pureExec,fail] at h
          · simp only [decide_true,decide_false,if_true,if_false,Result.mk.injEq,Bool.false_eq_true,reduceCtorEq,false_and,List.nil_append,TopupBeaconBatch.loop,hpk,hz,hmin,require,bind,bindExec,pure,pureExec,fail] at h
      · simp only [decide_true,decide_false,if_true,if_false,Result.mk.injEq,Bool.false_eq_true,reduceCtorEq,false_and,List.nil_append,TopupBeaconBatch.loop,hpk,require,bind,bindExec,fail] at h

/-- An independent list bound counts only nonzero amounts. Empty and all-zero
lists impose no bound on the initial physical deposit count. -/
theorem sum_le_nonzero (amounts : List Nat)
    (hb : ∀ a ∈ amounts, a < 2^64 * 10^9) :
    allocSum amounts ≤ nonzeroCount amounts * (2^64 * 10^9 - 1) := by
  induction amounts with
  | nil => simp [allocSum,nonzeroCount]
  | cons a rest ih =>
    have ha := hb a (by simp)
    have ht := ih (fun x hx => hb x (by simp [hx]))
    by_cases hz : a = 0
    · subst a
      simpa [allocSum,nonzeroCount] using ht
    · have hn : nonzeroCount (a::rest) = 1 + nonzeroCount rest := by
        simp [nonzeroCount,hz,Nat.add_comm]
      rw [hn]
      simp only [allocSum,Nat.add_mul,Nat.one_mul]
      omega

/-- Actual slot32 capacity, not an initial count hypothesis, bounds the number
of nonzero deposits that a committed loop could have executed. -/
theorem loop_success_nonzero_bound (ctx : Context) (target : Address)
    (inputs : List SourceDepositDataRootInput) (amounts : List Nat)
    (before after : World) (trace : List Attempt)
    (h : TopupBeaconBatch.loop ctx target inputs amounts before = ⟨.ok (),after,trace⟩) :
    nonzeroCount amounts ≤ maxCount := by
  obtain ⟨he,hcap⟩ := loop_success_count ctx target inputs amounts before after trace h
  by_cases hn : nonzeroCount amounts > 0
  · have hc := hcap hn
    omega
  · unfold maxCount
    omega

/-- Successful physical callee execution derives enough range for the entire
mathematical wei sum, even if the input Nat ledger or count was arbitrary. -/
theorem loop_success_sum_fits (ctx : Context) (target : Address)
    (inputs : List SourceDepositDataRootInput) (amounts : List Nat)
    (before after : World) (trace : List Attempt)
    (h : TopupBeaconBatch.loop ctx target inputs amounts before = ⟨.ok (),after,trace⟩) :
    allocSum amounts < uint256Modulus := by
  have hb := sum_le_nonzero amounts (loop_success_amount_bounds ctx target inputs amounts before after trace h)
  have hn := loop_success_nonzero_bound ctx target inputs amounts before after trace h
  have hm := Nat.mul_le_mul_right (2^64 * 10^9 - 1) hn
  have hc : maxCount * (2^64 * 10^9 - 1) < uint256Modulus := by decide
  omega

/-- The existing helper's genuine empty-key early return is included, so this
result does not restrict the caller domain to aligned, nonempty key lists. -/
theorem helper_success_sum_fits (hash : TopupRouterCredentials.Keccak)
    (ctx : Context) (beacon : Address) (i : TopupRouterContinuation.Input)
    (before after : World) (trace : List Attempt)
    (h : TopupRouterContinuation.helper hash ctx beacon i before = ⟨.ok (),after,trace⟩) :
    (if i.pubkeys = [] then 0 else allocSum (TopupRouterContinuation.values i.allocations)) <
      uint256Modulus := by
  unfold TopupRouterContinuation.helper at h
  split at h
  · rename_i hempty
    rw [if_pos hempty]
    decide
  · rename_i hnonempty
    split at h
    · cases h
    · rw [if_neg hnonempty]
      exact loop_success_sum_fits ctx beacon (TopupRouterContinuation.inputsAt hash ctx.self i before)
        (TopupRouterContinuation.values i.allocations) before after trace h

/-- If both the router guard and its actual helper execute successfully, the
nonempty-key path has an exact unwrapped guard total. The empty-key alternative
is retained as source behavior; reaching a helper is not assumed for zero paths. -/
theorem helper_success_guard_exact (hash : TopupRouterCredentials.Keccak)
    (ctx : Context) (beacon : Address) (i : TopupRouterContinuation.Input)
    (before after : World) (trace : List Attempt) (total : Nat)
    (hg : TopupRouterContinuation.guardSum (TopupRouterContinuation.values i.allocations)
      (TopupRouterContinuation.values i.limits) 0 = .ok total)
    (hh : TopupRouterContinuation.helper hash ctx beacon i before = ⟨.ok (),after,trace⟩) :
    i.pubkeys = [] ∨ total = allocSum (TopupRouterContinuation.values i.allocations) := by
  by_cases hn : i.pubkeys = []
  · exact Or.inl hn
  · have hf := helper_success_sum_fits hash ctx beacon i before after trace hh
    rw [if_neg hn] at hf
    obtain ⟨_,he⟩ := TopupRouterContinuation.guardSum_spec _ _ _ _ hg
    have hs : 0 + (TopupRouterContinuation.values i.allocations).sum < TopupWeiBounds.wordModulus := by
      simpa only [Nat.zero_add,← TopupFundedSource.allocSum_eq_sum,TopupWeiBounds.wordModulus,uint256Modulus] using hf
    rw [TopupWeiBounds.uncheckedSum_exact _ _ hs,Nat.zero_add,
      ← TopupFundedSource.allocSum_eq_sum] at he
    exact Or.inr he

/-- The actual positive execution supplies the helper call used to discharge
sum range. No helper success, capacity or amount bound is a new caller premise. -/
theorem positive_effects_sum (hash : TopupRouterCredentials.Keccak)
    (callee : External) (ctx : Context) (beacon : Address)
    (i : TopupRouterContinuation.Input) (before : World) (result : Result Unit)
    (total : Nat)
    (hg : TopupRouterContinuation.guardSum (TopupRouterContinuation.values i.allocations)
      (TopupRouterContinuation.values i.limits) 0 = .ok total)
    (he : TopupRouterCommitted.PositiveEffects hash callee ctx beacon i before result total) :
    i.pubkeys = [] ∨
      (total = allocSum (TopupRouterContinuation.values i.allocations) ∧
       allocSum (TopupRouterContinuation.values i.allocations) < uint256Modulus) := by
  obtain ⟨withdrawn,deposited,withdrawalTrace,helperTrace,_,hh,_⟩ := he.executed
  by_cases hn : i.pubkeys = []
  · exact Or.inl hn
  · have hx := helper_success_guard_exact hash (TopupBeaconFundedTx.routerContext ctx)
      beacon i withdrawn deposited helperTrace total hg hh
    have hf := helper_success_sum_fits hash (TopupBeaconFundedTx.routerContext ctx)
      beacon i withdrawn deposited helperTrace hh
    rw [if_neg hn] at hf
    exact Or.inr ⟨hx.resolve_left hn,hf⟩

/-- This refinement consumes success of the real existing raw-module executor.
The decoded allocations feed the same-world continuation, withdrawal and helper.
Zero-total and empty-key source paths are retained explicitly; the positive,
nonempty path derives its exact mathematical total from executed callee guards
and physical slot32 transitions, retaining the actual ledger and event effects. -/
theorem module_execute_success_sum (hash : TopupRouterCredentials.Keccak)
    (moduleExternal withdrawalExternal : External) (ctx : Context) (beacon : Address)
    (i : TopupModuleCall.Input) (before : World)
    (h : (TopupModuleCall.execute hash moduleExternal withdrawalExternal ctx beacon i before).outcome = .ok ()) :
    ∃ raw afterModule moduleTrace allocations total,
      TopupModuleCall.call hash moduleExternal (TopupBeaconFundedTx.routerContext ctx) i before =
        ⟨.ok raw,afterModule,moduleTrace⟩ ∧
      TopupModuleCall.decodeReturn raw = .ok allocations ∧
      TopupRouterContinuation.guardSum (TopupRouterContinuation.values allocations)
        (TopupRouterContinuation.values i.limits) 0 = .ok total ∧
      total ≤ i.roundedTarget.val ∧
      let ci := TopupModuleCall.continuationInput i allocations
      let suffixResult := TopupRouterContinuation.program hash withdrawalExternal ctx beacon ci afterModule
      (TopupModuleCall.execute hash moduleExternal withdrawalExternal ctx beacon i before).world = suffixResult.world ∧
      (TopupModuleCall.execute hash moduleExternal withdrawalExternal ctx beacon i before).attempts =
        moduleTrace ++ suffixResult.attempts ∧
      ((total = 0 ∧ suffixResult =
        ⟨.ok (),{afterModule with logs := afterModule.logs ++ [TopupRouterContinuation.topUpEvent ctx.sender ci 0]},[]⟩) ∨
       (TopupRouterCommitted.PositiveEffects hash withdrawalExternal ctx beacon ci afterModule suffixResult total ∧
        (i.pubkeys = [] ∨
          (total = allocSum (TopupRouterContinuation.values allocations) ∧
           allocSum (TopupRouterContinuation.values allocations) < uint256Modulus)))) := by
  obtain ⟨raw,afterModule,moduleTrace,allocations,total,hcall,hdecode,hguard,htarget,hworld,htrace,heffects⟩ :=
    TopupRouterCommitted.module_execute_success hash moduleExternal withdrawalExternal ctx beacon i before h
  refine ⟨raw,afterModule,moduleTrace,allocations,total,hcall,hdecode,hguard,htarget,hworld,htrace,?_⟩
  rcases heffects with hz | hp
  · exact Or.inl hz
  · exact Or.inr ⟨hp,positive_effects_sum hash withdrawalExternal ctx beacon
      (TopupModuleCall.continuationInput i allocations) afterModule _ total hguard hp⟩

#print axioms positive_effects_sum
#print axioms module_execute_success_sum
#print axioms sum_le_nonzero
#print axioms loop_success_nonzero_bound
#print axioms loop_success_sum_fits
#print axioms helper_success_sum_fits
#print axioms helper_success_guard_exact
#print axioms loop_success_amount_bounds
end LidoSRv3.Audit.Source.TopupBeaconSumBound
