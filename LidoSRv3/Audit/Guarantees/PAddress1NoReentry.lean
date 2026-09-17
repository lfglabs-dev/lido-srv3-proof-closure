import LidoSRv3.Audit.Source.NoReentry
import LidoSRv3.Audit.Verity.AddressRecipientCallBridge

/-! # P-ADDRESS-1 under A-NO-REENTRY: the claim's committed storage survives the recipient CALL

`AddressRecipientCallBridge.ClaimEffect` threads the exact world returned by
the recipient CALL into the next request. Under `NoReentry callee [ctx.self]`
(the configured recipient does not call back into the queue) that returned
world carries the queue storage committed by the claim itself: the claimed bit
and the `lockedEtherAmount` write are final, and the queue's balance is the
provisional payout transfer. The batch-level corollary records that no nested
attempt into the queue was accepted anywhere in the claim transcript.

**Status:** corollary of the registered `runClaimWithdrawalsTo_success`; the
premise is the accepted assumption `A-NO-REENTRY`. -/

namespace LidoSRv3.Audit.Guarantees.PAddress1NoReentry

open _root_.Verity
open LidoSRv3.Audit.Verity.AddressClaimBatchTx
open LidoSRv3.Audit.Source.TrioReserve1
open LidoSRv3.Audit.Source.TrioReserve1.Live
open LidoSRv3.Audit.Source.NoReentry
open LidoSRv3.Audit.Verity.AddressRecipientCallBridge

/-- The recipient CALL hands back the committed queue storage and the
provisional-transfer balance. -/
theorem payout_returns_committed (callee : External) (ctx : Context) (recipient : Address)
    (payout : Nat) (before after : World) (attempts : List Attempt)
    (hNo : NoReentry callee [ctx.self])
    (h : PayoutEffect callee ctx recipient payout before after attempts) :
    (∀ slot, after.core.readContractSlot ctx.self.val slot =
      before.core.readContractSlot ctx.self.val slot) ∧
    after.balances ctx.self =
      (transfer before ctx.self recipient (Verity.Core.Uint256.ofNat payout).val).balances ctx.self := by
  obtain ⟨_, returned, nested, _, hcase⟩ := h
  have hself : ctx.self ∈ [ctx.self] := List.mem_singleton.mpr rfl
  rcases hcase with ⟨_, hafter, _, _⟩ | ⟨_, ⟨hcall, _⟩ | hcall⟩
  · subst hafter
    exact ⟨fun _ => rfl, rfl⟩
  · have hr := returns_success hNo hcall ctx.self hself
    exact ⟨fun slot => (hr.1 slot).trans rfl, hr.2⟩
  · have hr := (returns_successWithTrace hNo hcall).1 ctx.self hself
    exact ⟨fun slot => (hr.1 slot).trans rfl, hr.2⟩

/-- One actual claim under A-NO-REENTRY: the world after the recipient CALL
holds exactly the claim's committed (dirty) queue storage, so the claimed bit
and the locked-ether write are final. -/
theorem claim_returns_committed_storage (callee : External) (ctx : Context)
    (requestId hint : Nat) (recipient : Address) (before after : World)
    (attempts : List Attempt)
    (hNo : NoReentry callee [ctx.self])
    (h : ClaimEffect callee ctx requestId hint recipient before after attempts) :
    ∃ payout dirty,
      claimOne requestId hint recipient (AccountFrame.enter ctx before.core) =
        .success payout dirty ∧
      (∀ wordIndex, after.core.readContractSlot ctx.self.val wordIndex =
        dirty.readSlot wordIndex) ∧
      after.balances ctx.self =
        (transfer {before with core := AccountFrame.commit ctx.self before.core dirty}
          ctx.self recipient (Verity.Core.Uint256.ofNat payout).val).balances ctx.self := by
  obtain ⟨payout, dirty, called, hClaim, _, _, _, _, _, _, hCommit, _, hPay, hAfter⟩ := h
  have hp := payout_returns_committed callee ctx recipient payout
    {before with core := AccountFrame.commit ctx.self before.core dirty} called attempts hNo hPay
  subst hAfter
  exact ⟨payout, dirty, hClaim,
    fun wordIndex => (hp.1 wordIndex).trans (hCommit wordIndex), hp.2⟩

/-- No accepted nested attempt into the queue anywhere in a claim chain. -/
theorem chain_nested_rejects (callee : External) (ctx : Context) (recipient : Address)
    (hNo : NoReentry callee [ctx.self])
    {requestIds hints : List Nat} {before after : World} {attempts : List Attempt}
    (h : ClaimChain callee ctx recipient requestIds hints before after attempts) :
    ∀ attempt ∈ attempts, NestedRejects [ctx.self] attempt.nested := by
  induction h with
  | nil world => intro attempt hmem; cases hmem
  | cons hEff _ ih =>
    intro attempt hmem
    rw [List.mem_append] at hmem
    rcases hmem with hfirst | hrest
    · obtain ⟨_, _, _, _, _, _, _, _, _, _, _, _, hPay, _⟩ := hEff
      obtain ⟨_, returned, nested, hfirstEq, hcase⟩ := hPay
      subst hfirstEq
      rw [List.mem_singleton] at hfirst
      subst hfirst
      show NestedRejects [ctx.self] nested
      rcases hcase with ⟨_, _, _, hn⟩ | ⟨_, ⟨_, hn⟩ | hc⟩
      · subst hn; intro n hn; cases hn
      · subst hn; intro n hn; cases hn
      · exact (returns_successWithTrace hNo hc).2
    · exact ih attempt hrest

/-- Registered-parent corollary: actual batch success yields the same-world
claim chain and, under A-NO-REENTRY, a transcript with no accepted nested call
into the queue. -/
theorem actual_claim_batch_no_reentry (callee : External) (ctx : Context)
    (requestIds hints : List Nat) (recipient : Address) (before : World)
    (hNo : NoReentry callee [ctx.self])
    (h : (runClaimWithdrawalsTo callee ctx requestIds hints recipient before).outcome = .ok ()) :
    ClaimChain callee ctx recipient requestIds hints before
      (runClaimWithdrawalsTo callee ctx requestIds hints recipient before).world
      (runClaimWithdrawalsTo callee ctx requestIds hints recipient before).attempts ∧
    ∀ attempt ∈ (runClaimWithdrawalsTo callee ctx requestIds hints recipient before).attempts,
      NestedRejects [ctx.self] attempt.nested := by
  obtain ⟨_, _, hchain⟩ := runClaimWithdrawalsTo_success callee ctx requestIds hints recipient before h
  exact ⟨hchain, chain_nested_rejects callee ctx recipient hNo hchain⟩

end LidoSRv3.Audit.Guarantees.PAddress1NoReentry
