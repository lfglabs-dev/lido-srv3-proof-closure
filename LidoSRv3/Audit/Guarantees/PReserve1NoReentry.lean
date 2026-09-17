import LidoSRv3.Audit.Source.NoReentry
import LidoSRv3.Audit.Guarantees.PReserve1LiveWriters

/-! # P-RESERVE-1 under A-NO-REENTRY: the final reserve is the spending stage's reserve

`PReserve1LiveWriters.WithdrawSuccess` exposes the actual stage worlds of a
successful withdrawal and threads the exact world returned by the router's
`receiveDepositableEther` CALL into the final world. Under
`NoReentry callee [ctx.self]` (the router/queue/oracle callbacks do not call
back into Lido) that returned world carries Lido's reserve word unchanged from
the end of the spending stage, so the final protected reserve is the value
written by `spendDepositableEther` itself.

**Status:** corollary of the registered `actual_reserve_physical_history`
(`step_effects`, `withdrawal_success`); the premise is the accepted assumption
`A-NO-REENTRY`. -/

namespace LidoSRv3.Audit.Guarantees.PReserve1NoReentry

open LidoSRv3.Audit.Source.TrioReserve1 LidoSRv3.Audit.Source.TrioReserve1.Live
open LidoSRv3.Audit.Source.NoReentry
open LidoSRv3.Audit.Guarantees.PReserve1LiveWriters

/-- A successful bind exposes the intermediate value, outcome and world. -/
theorem bind_success_world {α β : Type} (first : Exec α) (next : α → Exec β) (w : World) (b : β)
    (h : (bindExec first next w).outcome = .ok b) :
    ∃ a, (first w).outcome = .ok a ∧ (next a (first w).world).outcome = .ok b ∧
      (bindExec first next w).world = (next a (first w).world).world := by
  obtain ⟨a, ha, hb⟩ := Allocation.bind_success first next w b h
  refine ⟨a, ha, hb, ?_⟩
  simp only [bindExec, ha]

/-- `updateSeeds` writes only `seedSlot`. -/
theorem seeds_other_slot (ctx : Context) (seeds : Word) (w : World) (slot : Nat)
    (hs : slot ≠ seedSlot) :
    (WithdrawalTail.updateSeeds ctx seeds w).world.core.readContractSlot ctx.self.val slot =
      w.core.readContractSlot ctx.self.val slot := by
  by_cases hz : seeds.val = 0
  · rw [WithdrawalTail.seeds_zero ctx seeds w hz]
    all_goals rfl
  · have hn : 0 < seeds.val := Nat.pos_of_ne_zero hz
    by_cases hb : (w.core.readContractSlot ctx.self.val seedSlot).val % width + seeds.val <
        Verity.Core.UINT256_MODULUS
    · rw [WithdrawalTail.seeds_success ctx seeds w hn hb]
      unfold WithdrawalTail.seedWorld
      exact Pipeline.read_other_slot _ _ _ _ _ _ hs
    · rw [WithdrawalTail.seeds_overflow ctx seeds w hn (Nat.not_lt.mp hb)]
      all_goals rfl

/-- A successful `finish` is a successful seed update followed by a successful
router CALL whose returned world is the final world. -/
theorem finish_success (external : External) (ctx : Context) (router : Address)
    (amount seeds : Word) (w after : World) (trace : List Attempt)
    (h : WithdrawalTail.finish external ctx router amount seeds w = ⟨.ok (), after, trace⟩) :
    (WithdrawalTail.updateSeeds ctx seeds w).outcome = .ok () ∧
    ∃ data,
      (call external ctx router 0x13ae8460 amount
        (WithdrawalTail.updateSeeds ctx seeds w).world).outcome = .ok data ∧
      (call external ctx router 0x13ae8460 amount
        (WithdrawalTail.updateSeeds ctx seeds w).world).world = after := by
  have ho : (WithdrawalTail.finish external ctx router amount seeds w).outcome = .ok () := by
    rw [h]
  have hw : (WithdrawalTail.finish external ctx router amount seeds w).world = after := by
    rw [h]
  unfold WithdrawalTail.finish at ho hw
  obtain ⟨u, hu, hrest, hworld⟩ := bind_success_world _ _ _ _ ho
  obtain ⟨data, hd, _, hworld2⟩ := bind_success_world _ _ _ _ hrest
  refine ⟨?_, data, hd, ?_⟩
  · cases u; exact hu
  · exact hworld2.symm.trans (hworld.symm.trans hw)

/-- Successful withdrawal under A-NO-REENTRY: the exposed stage worlds of
`WithdrawSuccess`, and the final reserve word equals the reserve word at the
end of the spending stage. -/
theorem withdraw_success_final_reserve (callee : External) (ctx : Context)
    (amount seeds : Word) (before after : World) (trace : List Attempt)
    (hNo : NoReentry callee [ctx.self])
    (h : WithdrawSuccess callee ctx amount seeds before after trace) :
    ∃ spent,
      (∃ statusWorld spendWorld s r p t router,
        canDeposit callee ctx before = ⟨.ok true, statusWorld, s⟩ ∧
        stakingRouter callee ctx statusWorld = ⟨.ok router, spendWorld, r⟩ ∧
        ctx.sender = router ∧ amount.val ≠ 0 ∧
        spendDepositableEther callee ctx amount spendWorld = ⟨.ok (), spent, p⟩ ∧
        SpendPartition callee ctx amount spendWorld ∧
        WithdrawalTail.finish callee ctx router amount seeds spent = ⟨.ok (), after, t⟩ ∧
        trace = s ++ r ++ p ++ t) ∧
      after.core.readContractSlot ctx.self.val reserveSlot =
        spent.core.readContractSlot ctx.self.val reserveSlot := by
  obtain ⟨statusWorld, spendWorld, spent, s, r, p, t, router, hs, hr, hsender, hnz, hp, hpart,
    hfin, htrace⟩ := h
  refine ⟨spent, ⟨statusWorld, spendWorld, s, r, p, t, router, hs, hr, hsender, hnz, hp, hpart,
    hfin, htrace⟩, ?_⟩
  obtain ⟨_, data, _, hworld⟩ := finish_success callee ctx router amount seeds spent after t hfin
  rw [← hworld, call_storage hNo ctx router 0x13ae8460 amount _ ctx.self
    (List.mem_singleton.mpr rfl) reserveSlot]
  exact seeds_other_slot ctx seeds spent reserveSlot (by decide)

/-- Registered-parent corollary: a successful `.withdraw` step of the physical
history, under A-NO-REENTRY on the physical callee, leaves the reserve word
exactly as the spending stage wrote it. -/
theorem actual_reserve_history_final_reserve (c : Pipeline.Config)
    (staticOther : StaticCall.External) (other : External) (ctx : Context)
    (amount seeds : Word) (before : World)
    (hNo : NoReentry (physicalExternal c staticOther other) [ctx.self])
    (h : (execute (physicalExternal c staticOther other) ctx (.withdraw amount seeds) before).outcome =
      .ok ()) :
    ∃ spent,
      (∃ statusWorld spendWorld s r p t router,
        canDeposit (physicalExternal c staticOther other) ctx before = ⟨.ok true, statusWorld, s⟩ ∧
        stakingRouter (physicalExternal c staticOther other) ctx statusWorld =
          ⟨.ok router, spendWorld, r⟩ ∧
        ctx.sender = router ∧ amount.val ≠ 0 ∧
        spendDepositableEther (physicalExternal c staticOther other) ctx amount spendWorld =
          ⟨.ok (), spent, p⟩ ∧
        SpendPartition (physicalExternal c staticOther other) ctx amount spendWorld ∧
        WithdrawalTail.finish (physicalExternal c staticOther other) ctx router amount seeds spent =
          ⟨.ok (), (execute (physicalExternal c staticOther other) ctx (.withdraw amount seeds) before).world, t⟩ ∧
        (execute (physicalExternal c staticOther other) ctx (.withdraw amount seeds) before).attempts =
          s ++ r ++ p ++ t) ∧
      (execute (physicalExternal c staticOther other) ctx (.withdraw amount seeds) before).world.core.readContractSlot
          ctx.self.val reserveSlot =
        spent.core.readContractSlot ctx.self.val reserveSlot := by
  have he := step_effects (physicalExternal c staticOther other) ctx (.withdraw amount seeds) before
  simp only [Effects, h] at he
  exact withdraw_success_final_reserve (physicalExternal c staticOther other) ctx amount seeds
    before _ _ hNo he.2

end LidoSRv3.Audit.Guarantees.PReserve1NoReentry
