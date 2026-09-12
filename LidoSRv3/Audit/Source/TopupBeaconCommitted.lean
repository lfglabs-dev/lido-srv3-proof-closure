import LidoSRv3.Audit.Source.TopupRouterContinuation

/-! Necessary ledger property of the actual beacon loop on committed runs.
Unlike a sufficient success-domain theorem, this result derives word fit from
executed helper guards and funding/frame preservation from the actual callee.
No initial funding, capacity, key-width, amount-admission or non-alias premise
is required. It remains a theorem of the accepted Live execution model.
-/
namespace LidoSRv3.Audit.Source.TopupBeaconCommitted
open TrioReserve1 Live TopupBeaconBatch TopupBeaconCallee
open LidoSRv3.Audit.Verity.TopupTx LidoSRv3.Audit.SolidityTopup
open DepositDataRootCorrespondence

/-- The executed uint64-gwei upper guard implies the full wei value fits a
uint256. There is no independent nowrap premise. -/
theorem guarded_amount_fits (a : Nat) (h : a / 10^9 ≤ 2^64-1) : a < uint256Modulus := by
  have hr := Nat.mod_lt a (show 0 < 10^9 by decide)
  have he := Nat.mod_add_div a (10^9)
  unfold uint256Modulus
  omega

set_option maxRecDepth 4096 in
/-- Any successful actual beacon loop conserves its mathematical allocation
sum pointwise over all ledger accounts, including aliased caller/recipient.
This consumes real CALL/callee success; no per-call receipt is an input. -/
theorem loop_success_balances (ctx : Context) (target : Address)
    (inputs : List SourceDepositDataRootInput) :
    ∀ (amounts : List Nat) (before after : World) (trace : List Attempt),
    TopupBeaconBatch.loop ctx target inputs amounts before = ⟨.ok (),after,trace⟩ →
    CallSpec.Balances before.balances after.balances ctx.self target (allocSum amounts) := by
  induction inputs with
  | nil =>
    intro amounts before after trace h
    cases amounts with
    | nil =>
      simp only [TopupBeaconBatch.loop,pureExec,Result.mk.injEq] at h
      rcases h with ⟨_,rfl,_⟩
      simp [CallSpec.Balances,allocSum]
    | cons a rest => simp only [decide_true,decide_false,if_true,if_false,Result.mk.injEq,Bool.false_eq_true,reduceCtorEq,false_and,List.nil_append,TopupBeaconBatch.loop,fail] at h
  | cons input inputs ih =>
    intro amounts before after trace h
    cases amounts with
    | nil => simp only [decide_true,decide_false,if_true,if_false,Result.mk.injEq,Bool.false_eq_true,reduceCtorEq,false_and,List.nil_append,TopupBeaconBatch.loop,fail] at h
    | cons a rest =>
      by_cases hpk : input.publicKey.length = 48
      · by_cases hz : a = 0
        · subst a
          simpa only [decide_true,decide_false,if_true,if_false,List.nil_append,TopupBeaconBatch.loop,hpk,require,bind,bindExec,pure,pureExec,allocSum,Nat.zero_add]
            using ih rest before after trace (by
              simpa only [decide_true,decide_false,if_true,if_false,List.nil_append,TopupBeaconBatch.loop,hpk,require,bind,bindExec,pure,pureExec] using h)
        · by_cases hmin : 10^18 ≤ a
          · by_cases hmax : a / 10^9 ≤ 2^64-1
            · have hv : (word a).val = a := word_val (guarded_amount_fits a hmax)
              cases hp : TopupBeaconEffects.push sha256 ctx target
                  (TopupBeaconEffects.sourcePayload input) (word a) before with
              | mk outcome middle firstTrace =>
                cases outcome with
                | «error» err =>
                  simp only [decide_true,decide_false,if_true,if_false,Result.mk.injEq,Bool.false_eq_true,reduceCtorEq,false_and,List.nil_append,TopupBeaconBatch.loop,hpk,hz,hmin,hmax,require,bind,bindExec,pure,pureExec,hp] at h
                | ok data =>
                  have hb := TopupBeaconEffects.success_balances sha256 ctx target
                    (TopupBeaconEffects.sourcePayload input) (word a) before middle data firstTrace hp
                  rw [hv] at hb
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
                      have htbal := ih rest middle last tailTrace ht
                      intro account
                      have h1 := hb account
                      have h2 := htbal account
                      unfold allocSum
                      split_ifs at h1 h2 ⊢ <;> omega
            · simp only [decide_true,decide_false,if_true,if_false,Result.mk.injEq,Bool.false_eq_true,reduceCtorEq,false_and,List.nil_append,TopupBeaconBatch.loop,hpk,hz,hmin,hmax,require,bind,bindExec,pure,pureExec,fail] at h
          · simp only [decide_true,decide_false,if_true,if_false,Result.mk.injEq,Bool.false_eq_true,reduceCtorEq,false_and,List.nil_append,TopupBeaconBatch.loop,hpk,hz,hmin,require,bind,bindExec,pure,pureExec,fail] at h
      · simp only [decide_true,decide_false,if_true,if_false,Result.mk.injEq,Bool.false_eq_true,reduceCtorEq,false_and,List.nil_append,TopupBeaconBatch.loop,hpk,require,bind,bindExec,fail] at h

/-- A successful callee body derives the capacity guard and the actual slot32
increment. No initial count invariant or successful insertion is assumed. -/
theorem deposit_success_count (hash : Hash) (f : Fields) (req : Request)
    (before after : World) (data : Live.Bytes)
    (h : deposit hash f req before = .success data after) :
    (after.core.readContractSlot req.target.val countSlot).val =
      (before.core.readContractSlot req.target.val countSlot).val + 1 ∧
    (after.core.readContractSlot req.target.val countSlot).val ≤ maxCount := by
  unfold deposit at h
  split at h <;> try { simp [rejected] at h }
  split at h <;> try { simp [rejected] at h }
  split at h <;> try { simp [rejected] at h }
  split at h <;> try { simp [rejected] at h }
  split at h <;> try { simp [rejected] at h }
  split at h <;> try { simp [rejected] at h }
  dsimp only at h
  split at h <;> try { simp [rejected] at h }
  split at h <;> try { simp [rejected] at h }
  rename_i hcap
  split at h <;> try { simp [rejected] at h }
  rename_i after' hi
  cases h
  have he := insert_count _ _ _ _ _ _ _ _ (by decide) hi
  rw [he, Verity.ContractState.readContractSlot_writeContractSlot_same]
  have hb : (before.core.readContractSlot req.target.val countSlot).val + 1 < uint256Modulus := by
    unfold maxCount at hcap
    unfold uint256Modulus
    omega
  have hv : (Live.word ((before.core.readContractSlot req.target.val countSlot).val + 1)).val =
      (before.core.readContractSlot req.target.val countSlot).val + 1 := by
    exact Nat.mod_eq_of_lt hb
  rw [hv]
  exact ⟨rfl,by omega⟩

/-- The real CALL consumes the callee's physical count result, including its
pre-call transfer. It does not obtain a count from an auxiliary journal. -/
theorem push_success_count (hash : Hash) (ctx : Context) (target : Address)
    (payload : Live.Bytes) (amount : Word) (before after : World) (data : Live.Bytes)
    (trace : List Attempt)
    (h : TopupBeaconEffects.push hash ctx target payload amount before = ⟨.ok data,after,trace⟩) :
    (after.core.readContractSlot target.val countSlot).val =
      (before.core.readContractSlot target.val countSlot).val + 1 ∧
    (after.core.readContractSlot target.val countSlot).val ≤ maxCount := by
  unfold TopupBeaconEffects.push CallData.invoke at h
  dsimp only at h
  split at h
  · simp at h
  · split at h
    · simp at h
    · split at h
      · simp at h
      · rename_i data' w' hr
        cases h
        unfold dispatch at hr
        split at hr <;> try { simp [rejected] at hr }
        split at hr <;> try { simp [rejected] at hr }
        exact deposit_success_count _ _ _ _ _ _ hr
      · rename_i data' w' nested hr
        unfold dispatch at hr
        split at hr <;> try { simp [rejected] at hr }
        split at hr <;> try { simp [rejected] at hr }
        unfold deposit at hr
        split at hr <;> try { simp [rejected] at hr }
        split at hr <;> try { simp [rejected] at hr }
        split at hr <;> try { simp [rejected] at hr }
        split at hr <;> try { simp [rejected] at hr }
        split at hr <;> try { simp [rejected] at hr }
        split at hr <;> try { simp [rejected] at hr }
        dsimp only at hr
        split at hr <;> try { simp [rejected] at hr }
        split at hr <;> try { simp [rejected] at hr }
        split at hr <;> try { simp [rejected] at hr }
      · simp at h

set_option maxRecDepth 4096 in
/-- Successful execution increments physical slot32 once per nonzero entry.
A nonempty committed batch derives its final capacity bound from the callee
guards; an empty batch deliberately makes no claim about its initial count. -/
theorem loop_success_count (ctx : Context) (target : Address)
    (inputs : List SourceDepositDataRootInput) :
    ∀ (amounts : List Nat) (before after : World) (trace : List Attempt),
    TopupBeaconBatch.loop ctx target inputs amounts before = ⟨.ok (),after,trace⟩ →
    (after.core.readContractSlot target.val countSlot).val =
      (before.core.readContractSlot target.val countSlot).val + nonzeroCount amounts ∧
    (nonzeroCount amounts > 0 → (after.core.readContractSlot target.val countSlot).val ≤ maxCount) := by
  induction inputs with
  | nil =>
    intro amounts before after trace h
    cases amounts with
    | nil =>
      simp only [TopupBeaconBatch.loop,pureExec,Result.mk.injEq] at h
      rcases h with ⟨_,rfl,_⟩
      simp [nonzeroCount]
    | cons a rest => simp only [decide_true,decide_false,if_true,if_false,Result.mk.injEq,Bool.false_eq_true,reduceCtorEq,false_and,List.nil_append,TopupBeaconBatch.loop,fail] at h
  | cons input inputs ih =>
    intro amounts before after trace h
    cases amounts with
    | nil => simp only [decide_true,decide_false,if_true,if_false,Result.mk.injEq,Bool.false_eq_true,reduceCtorEq,false_and,List.nil_append,TopupBeaconBatch.loop,fail] at h
    | cons a rest =>
      by_cases hpk : input.publicKey.length = 48
      · by_cases hz : a = 0
        · subst a
          simpa only [decide_true,decide_false,if_true,if_false,List.nil_append,TopupBeaconBatch.loop,hpk,require,bind,bindExec,pure,pureExec,nonzeroCount,List.filter_cons,ne_eq,not_true_eq_false,Bool.false_eq_true,Nat.zero_add]
            using ih rest before after trace (by
              simpa only [decide_true,decide_false,if_true,if_false,List.nil_append,TopupBeaconBatch.loop,hpk,require,bind,bindExec,pure,pureExec] using h)
        · by_cases hmin : 10^18 ≤ a
          · by_cases hmax : a / 10^9 ≤ 2^64-1
            · cases hp : TopupBeaconEffects.push sha256 ctx target
                  (TopupBeaconEffects.sourcePayload input) (word a) before with
              | mk outcome middle firstTrace =>
                cases outcome with
                | «error» err =>
                  simp only [decide_true,decide_false,if_true,if_false,Result.mk.injEq,Bool.false_eq_true,reduceCtorEq,false_and,List.nil_append,TopupBeaconBatch.loop,hpk,hz,hmin,hmax,require,bind,bindExec,pure,pureExec,hp] at h
                | ok data =>
                  have hb := push_success_count sha256 ctx target
                    (TopupBeaconEffects.sourcePayload input) (word a) before middle data firstTrace hp
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
                      have htcount := ih rest middle last tailTrace ht
                      have hc : nonzeroCount (a :: rest) = 1 + nonzeroCount rest := by
                        simp [nonzeroCount,hz,Nat.add_comm]
                      rw [hc]
                      refine ⟨by omega, ?_⟩
                      intro _
                      by_cases hn : nonzeroCount rest > 0
                      · exact htcount.2 hn
                      · have he : nonzeroCount rest = 0 := by omega
                        omega
            · simp only [decide_true,decide_false,if_true,if_false,Result.mk.injEq,Bool.false_eq_true,reduceCtorEq,false_and,List.nil_append,TopupBeaconBatch.loop,hpk,hz,hmin,hmax,require,bind,bindExec,pure,pureExec,fail] at h
          · simp only [decide_true,decide_false,if_true,if_false,Result.mk.injEq,Bool.false_eq_true,reduceCtorEq,false_and,List.nil_append,TopupBeaconBatch.loop,hpk,hz,hmin,require,bind,bindExec,pure,pureExec,fail] at h
      · simp only [decide_true,decide_false,if_true,if_false,Result.mk.injEq,Bool.false_eq_true,reduceCtorEq,false_and,List.nil_append,TopupBeaconBatch.loop,hpk,require,bind,bindExec,fail] at h

/-- The root rollback wrapper preserves the ledger theorem on its successful
branch. Failed executions remain governed by the existing full-world rollback. -/
theorem run_success_balances (ctx : Context) (target : Address)
    (inputs : List SourceDepositDataRootInput) (amounts : List Nat)
    (before after : World) (trace : List Attempt)
    (h : Live.run (TopupBeaconBatch.loop ctx target inputs amounts) before =
      ⟨.ok (),after,trace⟩) :
    CallSpec.Balances before.balances after.balances ctx.self target (allocSum amounts) := by
  unfold Live.run at h
  dsimp only at h
  split at h
  · exact loop_success_balances ctx target inputs amounts before after trace h
  · cases h

/-- The actual router helper consumes the same loop. Its source early return
for empty pubkeys moves zero, even when an arbitrary supplied allocation list
is nonempty; the outer router input validation is a separate required link. -/
theorem helper_success_balances (hash : TopupRouterCredentials.Keccak)
    (ctx : Context) (beacon : Address) (i : TopupRouterContinuation.Input)
    (before after : World) (trace : List Attempt)
    (h : TopupRouterContinuation.helper hash ctx beacon i before = ⟨.ok (),after,trace⟩) :
    CallSpec.Balances before.balances after.balances ctx.self beacon
      (if i.pubkeys = [] then 0 else allocSum (TopupRouterContinuation.values i.allocations)) := by
  unfold TopupRouterContinuation.helper at h
  split at h
  · rename_i hempty
    simp only [pureExec,Result.mk.injEq] at h
    rcases h with ⟨_,rfl,_⟩
    simp [hempty,CallSpec.Balances]
  · rename_i hnonempty
    split at h
    · cases h
    · rw [if_neg hnonempty]
      exact loop_success_balances ctx beacon (TopupRouterContinuation.inputsAt hash ctx.self i before)
        (TopupRouterContinuation.values i.allocations) before after trace h

/-- The actual router helper consumes the physical count theorem as well as
its own empty-key early return. The outer router guard remains to be composed. -/
theorem helper_success_count (hash : TopupRouterCredentials.Keccak)
    (ctx : Context) (beacon : Address) (i : TopupRouterContinuation.Input)
    (before after : World) (trace : List Attempt)
    (h : TopupRouterContinuation.helper hash ctx beacon i before = ⟨.ok (),after,trace⟩) :
    let n := if i.pubkeys = [] then 0 else nonzeroCount (TopupRouterContinuation.values i.allocations)
    (after.core.readContractSlot beacon.val countSlot).val =
      (before.core.readContractSlot beacon.val countSlot).val + n ∧
    (n > 0 → (after.core.readContractSlot beacon.val countSlot).val ≤ maxCount) := by
  dsimp only
  unfold TopupRouterContinuation.helper at h
  split at h
  · rename_i hempty
    simp only [pureExec,Result.mk.injEq] at h
    rcases h with ⟨_,rfl,_⟩
    simp [hempty]
  · rename_i hnonempty
    split at h
    · cases h
    · rw [if_neg hnonempty]
      exact loop_success_count ctx beacon (TopupRouterContinuation.inputsAt hash ctx.self i before)
        (TopupRouterContinuation.values i.allocations) before after trace h

/-- For distinct accounts, initial aggregate funding is a CONSEQUENCE of
successful execution, rather than an admission premise. The main theorem also
covers aliased caller/recipient, where this aggregate bound need not hold. -/
theorem committed_funding (ctx : Context) (target : Address)
    (inputs : List SourceDepositDataRootInput) (amounts : List Nat)
    (before after : World) (trace : List Attempt) (hd : ctx.self ≠ target)
    (h : TopupBeaconBatch.loop ctx target inputs amounts before = ⟨.ok (),after,trace⟩) :
    allocSum amounts ≤ before.balances ctx.self ∧
    after.balances ctx.self + allocSum amounts = before.balances ctx.self := by
  have hbal := loop_success_balances ctx target inputs amounts before after trace h ctx.self
  simp only [if_true,if_neg hd,Nat.add_zero] at hbal
  exact ⟨by omega,hbal⟩

#print axioms helper_success_count
#print axioms loop_success_count
#print axioms deposit_success_count
#print axioms push_success_count
#print axioms guarded_amount_fits
#print axioms loop_success_balances
#print axioms run_success_balances
#print axioms helper_success_balances
#print axioms committed_funding
end LidoSRv3.Audit.Source.TopupBeaconCommitted
