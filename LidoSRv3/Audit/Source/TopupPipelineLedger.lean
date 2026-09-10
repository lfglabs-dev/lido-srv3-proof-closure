import audit.trio.deposit.WithdrawalLedger
import LidoSRv3.Audit.Source.TopupRouterCommitted

/-! Necessary TOPUP withdrawal/beacon conservation. The registered consumer
below starts at the actual post-module router continuation, StakingRouter.sol
721–758 at core pin 17005714f151e5502c559932319a3f2f74ac2436.
It reuses the integrated DEPOSIT303 concrete withdrawal proof. -/
namespace LidoSRv3.Audit.Source.TopupPipelineLedger
open TrioReserve1 Live TopupRouterContinuation TopupRouterCommitted
open LidoSRv3.Audit.Verity LidoSRv3.Audit.SolidityTopup

/-- The final router assertion equates the pulled word to the actual helper
debit, including its empty-key alternative. No helper length, funding,
capacity or amount-admission premise is supplied. -/
theorem positive_effects_conservation (hash : TopupRouterCredentials.Keccak)
    (k : Queue.Keccak) (config : Pipeline.Config)
    (staticOther : StaticCall.External) (other : External)
    (ctx : Context) (beacon : Address) (i : Input) (before : World)
    (result : Result Unit) (total : Nat)
    (bound : Pipeline.Bound config ctx before)
    (lido_ne_router : ctx.self ≠ ctx.sender) (router_ne_beacon : ctx.sender ≠ beacon)
    (hfit : total < uint256Modulus)
    (h : PositiveEffects hash (Pipeline.external k config staticOther other)
      ctx beacon i before result total) :
    CallSpec.Balances before.balances result.world.balances ctx.self beacon total ∧
    result.world.balances ctx.sender = before.balances ctx.sender ∧
    i.pubkeys ≠ [] ∧ total = allocSum (values i.allocations) := by
  obtain ⟨withdrawn,deposited,withdrawalTrace,helperTrace,hw,hh,hr,hcore,hbal,hlog,
    htrace,hbeacon,hcount,hcap⟩ := h.executed
  have hword : (word total).val = total := Nat.mod_eq_of_lt hfit
  have hn : (word total).val ≠ 0 := by rw [hword]; exact h.positive
  simp only [TopupLiveWithdrawal.suffix, if_neg hn] at hw
  obtain ⟨hfunds,hledger⟩ :=
    audit.trio.deposit.WithdrawalLedger.pipeline_withdrawal_success_ledger
      k config staticOther other ctx (word total) (word 0)
      before withdrawn withdrawalTrace bound hw
  rw [hword] at hfunds hledger
  have hwithdraw := CallFlow.transfer_balances before ctx.self ctx.sender total hfunds
  rw [← hledger] at hwithdraw
  have restored : result.world.balances ctx.sender = before.balances ctx.sender := by
    rw [hbal]; exact hr
  have hwr := hwithdraw ctx.sender
  have hbr := hbeacon ctx.sender
  simp only [Ne.symm lido_ne_router, if_false, ite_true, Nat.add_zero] at hwr
  simp only [router_ne_beacon, if_false, ite_true, Nat.add_zero] at hbr
  have amount_eq : total = helperAmount i := by omega
  have hnonempty : i.pubkeys ≠ [] := by
    intro hz
    simp [helperAmount, hz] at amount_eq
    exact h.positive amount_eq
  have sum_eq : total = allocSum (values i.allocations) := by
    simpa only [helperAmount, if_neg hnonempty] using amount_eq
  refine ⟨?_,restored,hnonempty,sum_eq⟩
  intro account
  have hw := hwithdraw account
  have hb := hbeacon account
  rw [← amount_eq] at hb
  by_cases hl : account = ctx.self <;>
    by_cases hr : account = ctx.sender <;>
    by_cases hbc : account = beacon <;>
    simp only [hl,hr,hbc,if_pos] at hw hb ⊢ <;> omega

/-- Necessary result of the existing complete continuation, including zero
total and its emitted event. Positive success derives an exact unwrapped sum
and nonempty keys from the live withdrawal, helper and final assertion. -/
theorem execute_success_conservation (hash : TopupRouterCredentials.Keccak)
    (k : Queue.Keccak) (config : Pipeline.Config)
    (staticOther : StaticCall.External) (other : External)
    (ctx : Context) (beacon : Address) (i : Input) (before : World)
    (bound : Pipeline.Bound config ctx before)
    (lido_ne_router : ctx.self ≠ ctx.sender) (router_ne_beacon : ctx.sender ≠ beacon)
    (h : (execute hash (Pipeline.external k config staticOther other) ctx beacon i before).outcome = .ok ()) :
    ∃ total, guardSum (values i.allocations) (values i.limits) 0 = .ok total ∧
      total ≤ i.roundedTarget.val ∧
      CallSpec.Balances before.balances
        (execute hash (Pipeline.external k config staticOther other) ctx beacon i before).world.balances
        ctx.self beacon total ∧
      (execute hash (Pipeline.external k config staticOther other) ctx beacon i before).world.balances ctx.sender =
        before.balances ctx.sender ∧
      (total = 0 ∨ (i.pubkeys ≠ [] ∧ total = allocSum (values i.allocations))) := by
  obtain ⟨he,hs⟩ := execute_success_program hash (Pipeline.external k config staticOther other)
    ctx beacon i before h
  obtain ⟨total,hg,ht,cases⟩ := continuation_success hash (Pipeline.external k config staticOther other)
    ctx beacon i before hs
  rw [he]
  refine ⟨total,hg,ht,?_⟩
  rcases cases with ⟨hz,hr⟩ | hp
  · rw [hr,hz]
    exact ⟨by simp [CallSpec.Balances],rfl,Or.inl rfl⟩
  · have hf : total < uint256Modulus := lt_of_le_of_lt ht i.roundedTarget.isLt
    obtain ⟨hb,hr,hn,heq⟩ := positive_effects_conservation hash k config staticOther other
      ctx beacon i before _ total bound lido_ne_router router_ne_beacon hf hp
    exact ⟨hb,hr,Or.inr ⟨hn,heq⟩⟩

#print axioms positive_effects_conservation
#print axioms execute_success_conservation
end LidoSRv3.Audit.Source.TopupPipelineLedger
