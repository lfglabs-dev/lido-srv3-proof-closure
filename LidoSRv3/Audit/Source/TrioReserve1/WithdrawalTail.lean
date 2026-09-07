import LidoSRv3.Audit.Source.TrioReserve1.Admission
import LidoSRv3.Audit.Source.TrioReserve1.Router

namespace LidoSRv3.Audit.Source.TrioReserve1.WithdrawalTail
open Live

theorem bind_assoc (first : Exec α) (next : α → Exec β) (last : β → Exec γ) :
    bindExec (bindExec first next) last = bindExec first (fun a => bindExec (next a) last) := by
  funext w
  cases hf : (first w).outcome with
  | error fault => simp [bindExec, hf]
  | ok value =>
    cases hn : (next value (first w).world).outcome <;>
      simp [bindExec, hf, hn, List.append_assoc]

/-- Exact final source block, with the router retained from the earlier lookup. -/
def updateSeeds (ctx : Context) (seeds : Word) : Exec Unit := do
  if seeds.val > 0 then
    let packed ← read ctx seedSlot
    let count ← checkedAdd (packed.val % width) seeds.val
    write ctx seedSlot (pack count (packed.val / width))
    emit ctx "DepositedValidatorsChanged" [word count]

def finish (external : External) (ctx : Context) (router : Address)
    (amount seeds : Word) : Exec Unit := do
  updateSeeds ctx seeds
  let _ ← call external ctx router 0x13ae8460 amount
  pure ()

theorem source_decomposition (external : External) (ctx : Context) (amount seeds : Word) :
    withdrawDepositableEther external ctx amount seeds = (do
      let allowed ← canDeposit external ctx
      require allowed (.reason "CAN_NOT_DEPOSIT")
      let router ← stakingRouter external ctx
      require (ctx.sender = router) (.reason "APP_AUTH_FAILED")
      require (amount.val ≠ 0) (.reason "ZERO_AMOUNT")
      spendDepositableEther external ctx amount
      finish external ctx router amount seeds) := by
  by_cases h : seeds.val > 0 <;>
    simp only [withdrawDepositableEther, finish, updateSeeds, h, ite_true, ite_false,
      bind, bind_assoc]

def seedWorld (ctx : Context) (seeds : Word) (w : World) : World :=
  let packed := w.core.readContractSlot ctx.self.val seedSlot
  let count := packed.val % width + seeds.val
  { w with
    core := w.core.writeContractSlot ctx.self.val seedSlot (pack count (packed.val / width))
    logs := w.logs ++ [⟨ctx.self, "DepositedValidatorsChanged", [word count]⟩] }

theorem seeds_zero (ctx : Context) (seeds : Word) (w : World) (hz : seeds.val = 0) :
    updateSeeds ctx seeds w = ⟨.ok (), w, []⟩ := by
  simp [updateSeeds, hz, pure, pureExec]

/-- The event exposes the checked full count; physical packing narrows it to
uint128. No unproved no-truncation condition is silently added. -/
theorem seeds_success (ctx : Context) (seeds : Word) (w : World)
    (hn : 0 < seeds.val)
    (hb : (w.core.readContractSlot ctx.self.val seedSlot).val % width + seeds.val <
      Verity.Core.UINT256_MODULUS) :
    updateSeeds ctx seeds w = ⟨.ok (), seedWorld ctx seeds w, []⟩ := by
  simp [updateSeeds, hn, Live.read, checkedAdd, require, hb, bind, bindExec,
    pure, pureExec, write, emit, seedWorld]

theorem seeds_overflow (ctx : Context) (seeds : Word) (w : World)
    (hn : 0 < seeds.val)
    (hb : Verity.Core.UINT256_MODULUS ≤
      (w.core.readContractSlot ctx.self.val seedSlot).val % width + seeds.val) :
    updateSeeds ctx seeds w = ⟨.error (.reason "MATH_ADD_OVERFLOW"), w, []⟩ := by
  simp [updateSeeds, hn, Live.read, checkedAdd, require, Nat.not_lt.mpr hb,
    bind, bindExec, fail]

theorem finish_call (external : External) (ctx : Context) (router : Address)
    (amount seeds : Word) (w seeded after : World) (data : Bytes) (trace : List Attempt)
    (hs : updateSeeds ctx seeds w = ⟨.ok (), seeded, []⟩)
    (hc : call external ctx router 0x13ae8460 amount seeded = ⟨.ok data, after, trace⟩) :
    finish external ctx router amount seeds w = ⟨.ok (), after, trace⟩ := by
  simp [finish, bind, bindExec, pure, pureExec, hs, hc]

theorem finish_rejection (external : External) (ctx : Context) (router : Address)
    (amount seeds : Word) (w seeded after : World) (fault : Fault) (trace : List Attempt)
    (hs : updateSeeds ctx seeds w = ⟨.ok (), seeded, []⟩)
    (hc : call external ctx router 0x13ae8460 amount seeded = ⟨.error fault, after, trace⟩) :
    run (finish external ctx router amount seeds) w = ⟨.error fault, w, trace⟩ := by
  simp [run, finish, bind, bindExec, hs, hc]

theorem seed_failure_stops (external : External) (ctx : Context) (router : Address)
    (amount seeds : Word) (w : World) (fault : Fault)
    (hs : updateSeeds ctx seeds w = ⟨.error fault, w, []⟩) :
    finish external ctx router amount seeds w = ⟨.error fault, w, []⟩ := by
  simp [finish, bind, bindExec, hs]

/-- The final receiver is executed, not assumed successful. Its immutable LIDO
check, incoming ETH credit, event and exact attempted CALL all appear here. -/
theorem actual_receiver (ctx : Context) (router lido : Address) (other : External)
    (amount seeds : Word) (w seeded : World)
    (hs : updateSeeds ctx seeds w = ⟨.ok (), seeded, []⟩)
    (ha : ctx.self = lido) (hc : (seeded.core.codeSize router.val).val ≠ 0)
    (hb : amount.val ≤ seeded.balances ctx.self) :
    finish (Router.dispatch router lido other) ctx router amount seeds w =
      ⟨.ok (), {transfer seeded ctx.self router amount.val with
        logs := seeded.logs ++ [⟨router, "DepositableEthReceived", [amount]⟩]},
        [⟨⟨ctx.self, router, amount, encode 4 0x13ae8460⟩, true, [], []⟩]⟩ := by
  exact finish_call _ ctx router amount seeds w seeded _ [] _ hs
    (Router.authorized_call router lido other ctx seeded amount ha hc hb)

theorem after_spend (external : External) (ctx : Context) (router : Address)
    (amount seeds : Word) (w statusWorld routerWorld spent : World)
    (statusTrace routerTrace spendTrace : List Attempt)
    (hs : canDeposit external ctx w = ⟨.ok true, statusWorld, statusTrace⟩)
    (hr : stakingRouter external ctx statusWorld = ⟨.ok router, routerWorld, routerTrace⟩)
    (ha : ctx.sender = router) (hn : amount.val ≠ 0)
    (hp : spendDepositableEther external ctx amount routerWorld = ⟨.ok (), spent, spendTrace⟩) :
    withdrawDepositableEther external ctx amount seeds w =
      let tail := finish external ctx router amount seeds spent
      ⟨tail.outcome, tail.world, statusTrace ++ routerTrace ++ spendTrace ++ tail.attempts⟩ := by
  rw [source_decomposition]
  simp [bind, bindExec, hs, hr, ha, hn, hp, require, pure, pureExec, List.append_assoc]

/-- A later receiver or seed failure restores the ORIGINAL withdrawal world,
including all earlier successful callee effects and spending writes/events. -/
theorem tail_failure_rolls_back (external : External) (ctx : Context) (router : Address)
    (amount seeds : Word) (w statusWorld routerWorld spent : World)
    (statusTrace routerTrace spendTrace : List Attempt) (fault : Fault)
    (hs : canDeposit external ctx w = ⟨.ok true, statusWorld, statusTrace⟩)
    (hr : stakingRouter external ctx statusWorld = ⟨.ok router, routerWorld, routerTrace⟩)
    (ha : ctx.sender = router) (hn : amount.val ≠ 0)
    (hp : spendDepositableEther external ctx amount routerWorld = ⟨.ok (), spent, spendTrace⟩)
    (hf : (finish external ctx router amount seeds spent).outcome = .error fault) :
    run (withdrawDepositableEther external ctx amount seeds) w =
      ⟨.error fault, w, statusTrace ++ routerTrace ++ spendTrace ++
        (finish external ctx router amount seeds spent).attempts⟩ := by
  unfold run
  rw [after_spend external ctx router amount seeds w statusWorld routerWorld spent
    statusTrace routerTrace spendTrace hs hr ha hn hp]
  simp [hf]

end LidoSRv3.Audit.Source.TrioReserve1.WithdrawalTail
