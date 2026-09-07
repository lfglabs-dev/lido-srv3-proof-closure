import LidoSRv3.Audit.Source.TrioReserve1.Allocation
import LidoSRv3.Audit.Source.TrioReserve1.AdmissionSpec

namespace LidoSRv3.Audit.Source.TrioReserve1.Admission
open Live

theorem guard_success (condition : Bool) (fault : Fault) (next : Unit → Exec α)
    (w : World) (value : α)
    (h : (bindExec (require condition fault) next w).outcome = .ok value) :
    condition = true ∧ (next () w).outcome = .ok value := by
  cases condition <;> simp [require, bindExec, fail, pure, pureExec] at h ⊢
  exact h

theorem decode_world (data : Bytes) (offset : Nat) (w : World) :
    (decodeWord data offset w).world = w := by
  by_cases h : offset + 32 ≤ data.length <;>
    simp [decodeWord, require, h, bind, bindExec, fail, pure, pureExec]

/-- Success derives permission from decoded live bunker bytes and the pause
word in the world AFTER the bunker CALL, not a supplied status or stale slot. -/
theorem live_status (external : External) (ctx : Context) (w : World)
    (h : (canDeposit external ctx w).outcome = .ok true) :
    ∃ queue data,
      (withdrawalQueue external ctx w).outcome = .ok queue ∧
      (call external ctx queue 0x2b95b781 (word 0)
        (withdrawalQueue external ctx w).world).outcome = .ok data ∧
      32 ≤ data.length ∧ (word (decode (data.take 32))).val = 0 ∧
      ((call external ctx queue 0x2b95b781 (word 0)
        (withdrawalQueue external ctx w).world).world.core.readContractSlot
          ctx.self.val activeSlot).val ≠ 0 := by
  simp only [canDeposit, bind, bindExec] at h
  split at h
  · contradiction
  · rename_i queue hqueue
    split at h
    · contradiction
    · rename_i data hdata
      split at h
      · contradiction
      · rename_i bunker hbunker
        split at h
        · simp [pure, pureExec] at h
        · rename_i hzero
          simp only [Live.read, bindExec, pure, pureExec, decode_world, Except.ok.injEq] at h
          have ha := of_decide_eq_true h
          obtain ⟨hsize, hw⟩ := Allocation.decoded_demand data _ bunker hbunker
          exact ⟨queue, data, hqueue, hdata, hsize, by simpa [hw] using hzero, ha⟩

theorem live_status_false (external : External) (ctx : Context) (w : World)
    (h : (canDeposit external ctx w).outcome = .ok false) :
    ∃ queue data,
      (withdrawalQueue external ctx w).outcome = .ok queue ∧
      (call external ctx queue 0x2b95b781 (word 0)
        (withdrawalQueue external ctx w).world).outcome = .ok data ∧
      32 ≤ data.length ∧
      ((word (decode (data.take 32))).val ≠ 0 ∨
        ((call external ctx queue 0x2b95b781 (word 0)
          (withdrawalQueue external ctx w).world).world.core.readContractSlot
            ctx.self.val activeSlot).val = 0) := by
  simp only [canDeposit, bind, bindExec] at h
  split at h
  · contradiction
  · rename_i queue hqueue
    split at h
    · contradiction
    · rename_i data hdata
      split at h
      · contradiction
      · rename_i bunker hbunker
        obtain ⟨hsize, hw⟩ := Allocation.decoded_demand data _ bunker hbunker
        split at h
        · rename_i hnonzero
          exact ⟨queue, data, hqueue, hdata, hsize, Or.inl (by simpa [hw] using hnonzero)⟩
        · simp only [Live.read, bindExec, pure, pureExec, decode_world, Except.ok.injEq] at h
          exact ⟨queue, data, hqueue, hdata, hsize, Or.inr (by simpa using of_decide_eq_false h)⟩

/-- Necessary admission follows by inverting the executed prefix. Callees may
reject, change storage, or return malformed bytes; none is assumed successful. -/
theorem withdrawal_admitted (external : External) (ctx : Context) (w : World)
    (amount seeds : Word)
    (h : (withdrawDepositableEther external ctx amount seeds w).outcome = .ok ()) :
    (canDeposit external ctx w).outcome = .ok true ∧
    ∃ router,
      (stakingRouter external ctx (canDeposit external ctx w).world).outcome = .ok router ∧
      ctx.sender = router ∧ amount.val ≠ 0 := by
  unfold withdrawDepositableEther at h
  obtain ⟨allowed, hallowed, h⟩ := Allocation.bind_success (canDeposit external ctx) _ w () h
  obtain ⟨htrue, h⟩ := guard_success allowed (.reason "CAN_NOT_DEPOSIT") _
    (canDeposit external ctx w).world () h
  subst allowed
  obtain ⟨router, hrouter, h⟩ := Allocation.bind_success (stakingRouter external ctx) _
    (canDeposit external ctx w).world () h
  obtain ⟨hcaller, h⟩ := guard_success (decide (ctx.sender = router)) (.reason "APP_AUTH_FAILED") _
    (stakingRouter external ctx (canDeposit external ctx w).world).world () h
  obtain ⟨hamount, _⟩ := guard_success (decide (amount.val ≠ 0)) (.reason "ZERO_AMOUNT") _
    (stakingRouter external ctx (canDeposit external ctx w).world).world () h
  exact ⟨hallowed, router, hrouter, of_decide_eq_true hcaller, of_decide_eq_true hamount⟩

/-- The independent rule is instantiated only with observations from the
actual status and router executions. Neither authority nor status is supplied
as a separate Boolean precondition. -/
theorem success_corresponds (external : External) (ctx : Context) (w : World)
    (amount seeds : Word)
    (h : (withdrawDepositableEther external ctx amount seeds w).outcome = .ok ()) :
    ∃ queue data router,
      (withdrawalQueue external ctx w).outcome = .ok queue ∧
      (call external ctx queue 0x2b95b781 (word 0)
        (withdrawalQueue external ctx w).world).outcome = .ok data ∧
      (stakingRouter external ctx (canDeposit external ctx w).world).outcome = .ok router ∧
      32 ≤ data.length ∧
      AdmissionSpec.Describes
        ⟨(word (decode (data.take 32))).val,
          ((call external ctx queue 0x2b95b781 (word 0)
            (withdrawalQueue external ctx w).world).world.core.readContractSlot
              ctx.self.val activeSlot).val,
          ctx.sender.val, router.val, amount.val⟩ .allowed := by
  obtain ⟨hstatus, router, hrouter, hauth, hamount⟩ := withdrawal_admitted external ctx w amount seeds h
  obtain ⟨queue, data, hqueue, hdata, hsize, hbunker, hactive⟩ := live_status external ctx w hstatus
  exact ⟨queue, data, router, hqueue, hdata, hrouter, hsize,
    hbunker, hactive, congrArg (·.val) hauth, hamount⟩

theorem status_failure_stops (external : External) (ctx : Context) (w : World)
    (amount seeds : Word) (fault : Fault)
    (h : (canDeposit external ctx w).outcome = .error fault) :
    run (withdrawDepositableEther external ctx amount seeds) w =
      ⟨.error fault, w, (canDeposit external ctx w).attempts⟩ := by
  simp [run, withdrawDepositableEther, bind, bindExec, h]

theorem cannot_deposit_stops (external : External) (ctx : Context) (w : World)
    (amount seeds : Word)
    (h : (canDeposit external ctx w).outcome = .ok false) :
    run (withdrawDepositableEther external ctx amount seeds) w =
      ⟨.error (.reason "CAN_NOT_DEPOSIT"), w, (canDeposit external ctx w).attempts⟩ := by
  simp [run, withdrawDepositableEther, bind, bindExec, h, require, fail]

theorem router_failure_stops (external : External) (ctx : Context) (w : World)
    (amount seeds : Word) (fault : Fault)
    (hstatus : (canDeposit external ctx w).outcome = .ok true)
    (hrouter : (stakingRouter external ctx (canDeposit external ctx w).world).outcome = .error fault) :
    run (withdrawDepositableEther external ctx amount seeds) w =
      ⟨.error fault, w, (canDeposit external ctx w).attempts ++
        (stakingRouter external ctx (canDeposit external ctx w).world).attempts⟩ := by
  simp [run, withdrawDepositableEther, bind, bindExec, hstatus, hrouter, require, pure, pureExec]

theorem unauthorized_stops (external : External) (ctx : Context) (w : World)
    (amount seeds : Word) (router : Address)
    (hstatus : (canDeposit external ctx w).outcome = .ok true)
    (hrouter : (stakingRouter external ctx (canDeposit external ctx w).world).outcome = .ok router)
    (hauth : ctx.sender ≠ router) :
    run (withdrawDepositableEther external ctx amount seeds) w =
      ⟨.error (.reason "APP_AUTH_FAILED"), w, (canDeposit external ctx w).attempts ++
        (stakingRouter external ctx (canDeposit external ctx w).world).attempts⟩ := by
  simp [run, withdrawDepositableEther, bind, bindExec, hstatus, hrouter, hauth,
    require, pure, pureExec, fail]

theorem zero_amount_stops (external : External) (ctx : Context) (w : World)
    (amount seeds : Word) (router : Address)
    (hstatus : (canDeposit external ctx w).outcome = .ok true)
    (hrouter : (stakingRouter external ctx (canDeposit external ctx w).world).outcome = .ok router)
    (hauth : ctx.sender = router) (hzero : amount.val = 0) :
    run (withdrawDepositableEther external ctx amount seeds) w =
      ⟨.error (.reason "ZERO_AMOUNT"), w, (canDeposit external ctx w).attempts ++
        (stakingRouter external ctx (canDeposit external ctx w).world).attempts⟩ := by
  simp [run, withdrawDepositableEther, bind, bindExec, hstatus, hrouter, hauth, hzero,
    require, pure, pureExec, fail]

end LidoSRv3.Audit.Source.TrioReserve1.Admission
