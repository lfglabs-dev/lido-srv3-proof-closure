import LidoSRv3.Audit.Source.NoReentry
import LidoSRv3.Audit.Guarantees.PConsolidation1ActualGatewayVault

/-! # P-CONSOLIDATION-ETH-1 under A-NO-REENTRY: settlement callbacks leave gateway and vault storage

`gateway_vault_live_success_and_revert` derives the final world of the
physical gateway-to-vault settlement from the exact worlds returned by the
per-request inbox CALLs and the refund CALL. Under
`NoReentry callee [gateway, vault]` (the EIP-7251 predeploy and the configured
refund recipient do not call back into the gateway or the vault) every one of
those returned worlds carries the gateway's and the vault's storage unchanged,
so the final storage of both contracts is exactly the post-quota storage the
gateway wrote before the settlement.

**Status:** corollary of the registered parent
`PConsolidationEth1.actual_physical_entry_quota_settlement_requests`; the
premise is the accepted assumption `A-NO-REENTRY`. -/

namespace LidoSRv3.Audit.Guarantees.PConsolidationEth1NoReentry

open LidoSRv3.Audit.Source.TrioReserve1 LidoSRv3.Audit.Source.TrioReserve1.Live
open LidoSRv3.Audit.Source.NoReentry
open audit.trio.consolidation

/-- An executable leaves a protected slot unchanged from every incoming world. -/
abbrev SlotPreserved {α : Type} (a : Address) (slot : Nat) (program : Exec α) : Prop :=
  ∀ w, (program w).world.core.readContractSlot a.val slot = w.core.readContractSlot a.val slot

theorem bind_slot {α β : Type} (first : Exec α) (next : α → Exec β) (a : Address) (slot : Nat)
    (h1 : SlotPreserved a slot first) (h2 : ∀ x, SlotPreserved a slot (next x)) :
    SlotPreserved a slot (bindExec first next) := by
  intro w
  simp only [bindExec]
  split
  · exact h1 w
  · exact (h2 _ _).trans (h1 w)

theorem validate_slot (pubkey : Bytes) (a : Address) (slot : Nat) :
    SlotPreserved a slot (validatePublicKey pubkey) := by
  intro w
  unfold validatePublicKey Live.require
  by_cases hc : decide (pubkey.length = pubkeyLength) = true
  · rw [if_pos hc]; rfl
  · rw [if_neg hc]; rfl

/-- A protected contract's storage is unchanged by any low-level CALL. -/
theorem lowLevel_slot {callee : External} {self : List Address} (hNo : NoReentry callee self)
    (ctx : Context) (target : Address) (payload : Bytes) (value : Word) (a : Address)
    (ha : a ∈ self) (slot : Nat) :
    SlotPreserved a slot (lowLevelCall callee ctx target payload value) := by
  intro w
  simp only [lowLevelCall]
  split
  · rfl
  · split
    · rfl
    · have hr := (hNo ⟨ctx.self, target, value, payload⟩ (transfer w ctx.self target value.val)).2
      revert hr
      cases callee ⟨ctx.self, target, value, payload⟩ (transfer w ctx.self target value.val) with
      | rejected d => intro _; rfl
      | rejectedWithTrace d n => intro _; rfl
      | success d after => intro hr; exact ((hr a ha).1 slot).trans rfl
      | successWithTrace d after n => intro hr; exact ((hr.1 a ha).1 slot).trans rfl

theorem callAdd_slot {callee : External} {self : List Address} (hNo : NoReentry callee self)
    (ctx : Context) (inbox : Address) (pair : ProducedPair) (fee : Word) (a : Address)
    (ha : a ∈ self) (slot : Nat) :
    SlotPreserved a slot (callAddConsolidationRequest callee ctx inbox pair fee) := by
  intro w
  simp only [callAddConsolidationRequest]
  split
  · exact lowLevel_slot hNo ctx inbox (vaultCallPayload pair) fee a ha slot w
  · exact lowLevel_slot hNo ctx inbox (vaultCallPayload pair) fee a ha slot w

/-- The inbox request loop leaves every protected slot unchanged. -/
theorem loop_slot {callee : External} {self : List Address} (hNo : NoReentry callee self)
    (ctx : Context) (inbox : Address) (fee : Word) (a : Address) (ha : a ∈ self) (slot : Nat) :
    ∀ pairs, SlotPreserved a slot (addConsolidationRequestsLoop callee ctx inbox fee pairs)
  | [] => by
      intro w
      simp only [addConsolidationRequestsLoop]
      rfl
  | pair :: rest => by
      simp only [addConsolidationRequestsLoop]
      refine bind_slot _ _ a slot (validate_slot pair.source a slot) (fun _ => ?_)
      refine bind_slot _ _ a slot (validate_slot pair.target a slot) (fun _ => ?_)
      exact bind_slot _ _ a slot (callAdd_slot hNo ctx inbox pair fee a ha slot)
        (fun _ => loop_slot hNo ctx inbox fee a ha slot rest)

/-- The refund CALL leaves every protected slot unchanged. -/
theorem refund_slot {callee : External} {self : List Address} (hNo : NoReentry callee self)
    (ctx : Context) (refund : Word) (recipient : Address) (a : Address) (ha : a ∈ self)
    (slot : Nat) :
    SlotPreserved a slot (refundFee callee ctx refund recipient) := by
  intro w
  simp only [refundFee]
  split
  · rfl
  · split
    · exact lowLevel_slot hNo ctx (resolveAddress recipient ctx.sender) [] refund a ha slot w
    · exact lowLevel_slot hNo ctx (resolveAddress recipient ctx.sender) [] refund a ha slot w

/-- Registered-parent corollary: after a successful physical settlement under
A-NO-REENTRY, the gateway's and the vault's storage equal the post-quota
storage; the inbox requests and the refund CALL changed neither. -/
theorem settlement_preserves_gateway_and_vault_storage
    (callee : External) (sexternal : StaticCall.External) (ctx : Context)
    (vault gateway inbox recipient : Address) (msgValue : Live.Word)
    (groups : List WitnessGroupBytes) (before : World)
    (hNo : NoReentry callee [gateway, vault])
    (h : (PhysicalEntrySettlement.execute callee sexternal ctx vault gateway inbox recipient
      msgValue groups before).outcome = .ok ()) :
    ctx.self = gateway ∧
    ∃ u, PhysicalQuotaSettlement.transition (PhysicalQuotaSettlement.stored ctx.self before)
        before.core.blockTimestamp.val (GatewaySettlement.requestCount groups) = .ok u ∧
      ∀ a ∈ [gateway, vault], ∀ slot,
        (PhysicalEntrySettlement.execute callee sexternal ctx vault gateway inbox recipient
          msgValue groups before).world.core.readContractSlot a.val slot =
        (PhysicalQuotaSettlement.postQuota ctx.self before u).core.readContractSlot a.val slot := by
  obtain ⟨_, hEq, u, _, _, hTrans, _, hQuota, _, hReq⟩ :=
    PConsolidationEth1.actual_physical_entry_quota_settlement_requests callee sexternal ctx vault
      gateway inbox recipient msgValue groups before h
  obtain ⟨hself, fee, outerData, quoteAttempts, sources, targets, innerData, innerAttempts,
    _, _, _, _, _, hrest⟩ := hReq
  obtain ⟨_, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, hGS, _, _⟩ := hrest
  refine ⟨hself, u, hTrans, ?_⟩
  intro a ha slot
  rw [hEq]
  show (PhysicalQuotaSettlement.execute callee sexternal ctx vault gateway inbox recipient
    msgValue groups before).world.core.readContractSlot a.val slot = _
  rw [hQuota]
  show (GatewaySettlement.execute callee callee sexternal ctx vault gateway inbox recipient
    msgValue groups (PhysicalQuotaSettlement.postQuota ctx.self before u)).world.core.readContractSlot
      a.val slot = _
  rw [hGS, refund_slot hNo ctx _ recipient a ha slot _,
    loop_slot hNo ⟨vault, ctx.self⟩ inbox _ a ha slot _ _]
  all_goals rfl

end LidoSRv3.Audit.Guarantees.PConsolidationEth1NoReentry
