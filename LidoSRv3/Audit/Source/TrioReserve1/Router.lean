import LidoSRv3.Audit.Source.TrioReserve1.Live
import LidoSRv3.Audit.Source.TrioReserve1.RouterSpec

namespace LidoSRv3.Audit.Source.TrioReserve1.Router
open Live

/-- ABI NotAuthorized() selector, independently checked by the Solidity probe. -/
def notAuthorized : Bytes := encode 4 0xea8e4eb5

/-- Source receiver body. CALL value has already been credited by Live.call.
The receiver reads immutable LIDO, rejects a different sender, and emits exactly
one event. It has no storage/balance writes or external calls of its own. -/
def receiveDepositableEther (router lido : Address) (req : Request) (w : World) : Reply :=
  if req.caller = lido then
    .success [] {w with logs := w.logs ++ [⟨router, "DepositableEthReceived", [req.value]⟩]}
  else .rejected notAuthorized

/-- Only the exact no-argument selector used by Lido is claimed here. Other
router selectors are delegated rather than treated as successful fixtures. -/
def dispatch (router lido : Address) (other : External) : External := fun req w =>
  if req.target = router ∧ req.payload = encode 4 0x13ae8460 then
    receiveDepositableEther router lido req w
  else other req w

theorem authorized_observations (router lido : Address) (req : Request) (w : World)
    (h : req.caller = lido) :
    receiveDepositableEther router lido req w =
      .success [] {w with logs := w.logs ++ [⟨router, "DepositableEthReceived", [req.value]⟩]} := by
  simp [receiveDepositableEther, h]

theorem unauthorized_rejects (router lido : Address) (req : Request) (w : World)
    (h : req.caller ≠ lido) :
    receiveDepositableEther router lido req w = .rejected notAuthorized := by
  simp [receiveDepositableEther, h]

/-- Relate the branch decision to the independent auth/event rule. Exact world
effects are stated separately in authorized_observations / unauthorized_rejects. -/
theorem source_rule (router lido : Address) (req : Request) (w : World) :
    match receiveDepositableEther router lido req w with
    | .success _ _ => RouterSpec.Describes lido.val req.caller.val req.value.val
        (.accepted req.value.val)
    | .successWithTrace _ _ _ => RouterSpec.Describes lido.val req.caller.val req.value.val
        (.accepted req.value.val)
    | .rejected _ => RouterSpec.Describes lido.val req.caller.val req.value.val
        .notAuthorized
    | .rejectedWithTrace _ _ => RouterSpec.Describes lido.val req.caller.val req.value.val
        .notAuthorized := by
  by_cases h : req.caller = lido
  · simp [receiveDepositableEther, h, RouterSpec.Describes]
  · simp only [receiveDepositableEther, h, ↓reduceIte, RouterSpec.Describes]
    intro he
    apply h
    exact Verity.Core.Address.ext he

/-- The CALL succeeds by executing the actual receiver body, rather than by
assuming an external success reply. The returned world includes ETH credit and
the receiver's event; its physical storage is unchanged. -/
theorem authorized_call (router lido : Address) (other : External) (ctx : Context)
    (w : World) (amount : Word)
    (hcaller : ctx.self = lido)
    (hcode : (w.core.codeSize router.val).val ≠ 0)
    (hfunds : amount.val ≤ w.balances ctx.self) :
    call (dispatch router lido other) ctx router 0x13ae8460 amount w =
      ⟨.ok [], {transfer w ctx.self router amount.val with
        logs := w.logs ++ [⟨router, "DepositableEthReceived", [amount]⟩]},
        [⟨⟨ctx.self, router, amount, encode 4 0x13ae8460⟩, true, [], []⟩]⟩ := by
  rw [hcaller] at hfunds
  simp [call, dispatch, receiveDepositableEther, hcode, Nat.not_lt.mpr hfunds,
    hcaller, transfer]

/-- A wrong immutable LIDO binding rejects after entering the real receiver.
The CALL restores the incoming world, including the attempted ETH credit. -/
theorem unauthorized_call (router lido : Address) (other : External) (ctx : Context)
    (w : World) (amount : Word)
    (hcaller : ctx.self ≠ lido)
    (hcode : (w.core.codeSize router.val).val ≠ 0)
    (hfunds : amount.val ≤ w.balances ctx.self) :
    call (dispatch router lido other) ctx router 0x13ae8460 amount w =
      ⟨.error (.bubbled notAuthorized), w,
        [⟨⟨ctx.self, router, amount, encode 4 0x13ae8460⟩, false, notAuthorized, []⟩]⟩ := by
  simp [call, dispatch, receiveDepositableEther, hcode, Nat.not_lt.mpr hfunds, hcaller]

end LidoSRv3.Audit.Source.TrioReserve1.Router
