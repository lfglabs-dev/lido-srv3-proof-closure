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
premise is the accepted assumption `A-NO-REENTRY`.

Binder names avoid the Verity DSL keywords (`slot`, `external`) reserved by
the imports of the registered parent. -/

namespace LidoSRv3.Audit.Guarantees.PConsolidationEth1NoReentry

open LidoSRv3.Audit.Source.TrioReserve1 LidoSRv3.Audit.Source.TrioReserve1.Live
open LidoSRv3.Audit.Source.NoReentry
open audit.trio.consolidation

/-- A successful first stage: the bind runs the continuation on the returned
world and keeps the returned attempts as a prefix. -/
theorem bindExec_ok {α β : Type} (first : Exec α) (next : α → Exec β) (w : World)
    (x : α) (w' : World) (tr : List Attempt) (h : first w = ⟨.ok x, w', tr⟩) :
    bindExec first next w =
      ⟨(next x w').outcome, (next x w').world, tr ++ (next x w').attempts⟩ := by
  simp [bindExec, h]

/-- A failed first stage: the bind stops with its outcome, world and attempts. -/
theorem bindExec_error {α β : Type} (first : Exec α) (next : α → Exec β) (w : World)
    (fault : Fault) (w' : World) (tr : List Attempt) (h : first w = ⟨.error fault, w', tr⟩) :
    bindExec first next w = ⟨.error fault, w', tr⟩ := by
  simp [bindExec, h]

/-- Slot preservation composes through the monadic bind. -/
theorem bind_slot {α β : Type} (first : Exec α) (next : α → Exec β) (a : Address) (k : Nat)
    (h1 : ∀ w, (first w).world.core.readContractSlot a.val k = w.core.readContractSlot a.val k)
    (h2 : ∀ x w, (next x w).world.core.readContractSlot a.val k =
      w.core.readContractSlot a.val k) :
    ∀ w, ((first >>= next) w).world.core.readContractSlot a.val k =
      w.core.readContractSlot a.val k := by
  intro w
  show (bindExec first next w).world.core.readContractSlot a.val k = _
  have hw' := h1 w
  cases hfw : first w with
  | mk o w' tr =>
    rw [hfw] at hw'
    cases o with
    | «error» e =>
      rw [bindExec_error first next w e w' tr hfw]
      exact hw'
    | ok x =>
      rw [bindExec_ok first next w x w' tr hfw]
      exact (h2 x w').trans hw'

/-- `_validatePublicKey` never touches storage. -/
theorem validate_slot (pubkey : Bytes) (a : Address) (k : Nat) :
    ∀ w, (validatePublicKey pubkey w).world.core.readContractSlot a.val k =
      w.core.readContractSlot a.val k := by
  intro w
  unfold validatePublicKey Live.require
  by_cases hc : decide (pubkey.length = pubkeyLength) = true
  · rw [if_pos hc]
    try rfl
  · rw [if_neg hc]
    try rfl

/-- A protected contract's storage is unchanged by any low-level CALL. -/
theorem lowLevel_slot {callee : External} {self : List Address} (hNo : NoReentry callee self)
    (ctx : Context) (target : Address) (payload : Bytes) (value : Live.Word) (a : Address)
    (ha : a ∈ self) (k : Nat) :
    ∀ w, (lowLevelCall callee ctx target payload value w).world.core.readContractSlot a.val k =
      w.core.readContractSlot a.val k := by
  intro w
  rcases lowLevelCall_shape callee ctx target payload value w with
    ⟨-, hc⟩ | ⟨-, -, hc⟩ | ⟨-, -, ⟨d, -, hc⟩ | ⟨d, n, -, hc⟩ | ⟨d, after, hr, hc⟩ |
      ⟨d, after, n, hr, hc⟩⟩
  · rw [hc]
  · rw [hc]
    exact transfer_slot w ctx.self target value.val a.val k
  · rw [hc]
  · rw [hc]
  · rw [hc]
    exact ((returns_success hNo hr a ha).1 k).trans
      (transfer_slot w ctx.self target value.val a.val k)
  · rw [hc]
    exact (((returns_successWithTrace hNo hr).1 a ha).1 k).trans
      (transfer_slot w ctx.self target value.val a.val k)

/-- One inbox request leaves every protected slot unchanged. -/
theorem callAdd_slot {callee : External} {self : List Address} (hNo : NoReentry callee self)
    (ctx : Context) (inbox : Address) (pair : ProducedPair) (fee : Live.Word) (a : Address)
    (ha : a ∈ self) (k : Nat) :
    ∀ w, (callAddConsolidationRequest callee ctx inbox pair fee w).world.core.readContractSlot
      a.val k = w.core.readContractSlot a.val k := by
  intro w
  have hl := lowLevel_slot hNo ctx inbox (vaultCallPayload pair) fee a ha k w
  cases hlc : lowLevelCall callee ctx inbox (vaultCallPayload pair) fee w with
  | mk o w' tr =>
    rw [hlc] at hl
    cases o with
    | ok d =>
      simp only [callAddConsolidationRequest, hlc]
      exact hl
    | «error» e =>
      simp only [callAddConsolidationRequest, hlc]
      exact hl

/-- The inbox request loop leaves every protected slot unchanged. -/
theorem loop_slot {callee : External} {self : List Address} (hNo : NoReentry callee self)
    (ctx : Context) (inbox : Address) (fee : Live.Word) (a : Address) (ha : a ∈ self) (k : Nat) :
    ∀ (pairs : List ProducedPair) (w : World),
      (addConsolidationRequestsLoop callee ctx inbox fee pairs w).world.core.readContractSlot
        a.val k = w.core.readContractSlot a.val k
  | [], w => by
      simp [addConsolidationRequestsLoop, pure, pureExec]
  | pair :: rest, w => by
      rw [addConsolidationRequestsLoop]
      exact bind_slot _ _ a k (validate_slot pair.source a k)
        (fun _ => bind_slot _ _ a k (validate_slot pair.target a k)
          (fun _ => bind_slot _ _ a k (callAdd_slot hNo ctx inbox pair fee a ha k)
            (fun _ => loop_slot hNo ctx inbox fee a ha k rest))) w

/-- The refund CALL leaves every protected slot unchanged. -/
theorem refund_slot {callee : External} {self : List Address} (hNo : NoReentry callee self)
    (ctx : Context) (refund : Live.Word) (recipient : Address) (a : Address) (ha : a ∈ self)
    (k : Nat) :
    ∀ w, (refundFee callee ctx refund recipient w).world.core.readContractSlot a.val k =
      w.core.readContractSlot a.val k := by
  intro w
  by_cases hz : refund.val = 0
  · rw [refund_zero callee ctx recipient refund w hz]
    try rfl
  · have hl := lowLevel_slot hNo ctx (resolveAddress recipient ctx.sender) [] refund a ha k w
    cases hlc : lowLevelCall callee ctx (resolveAddress recipient ctx.sender) [] refund w with
    | mk o w' tr =>
      rw [hlc] at hl
      cases o with
      | ok d =>
        simp only [refundFee, if_neg hz, hlc]
        exact hl
      | «error» e =>
        simp only [refundFee, if_neg hz, hlc]
        exact hl

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
      ∀ a ∈ [gateway, vault], ∀ k : Nat,
        (PhysicalEntrySettlement.execute callee sexternal ctx vault gateway inbox recipient
          msgValue groups before).world.core.readContractSlot a.val k =
        (PhysicalQuotaSettlement.postQuota ctx.self before u).core.readContractSlot a.val k := by
  obtain ⟨_, hEq, u, _, _, hTrans, _, hQuota, _, hReq⟩ :=
    PConsolidationEth1.actual_physical_entry_quota_settlement_requests callee sexternal ctx vault
      gateway inbox recipient msgValue groups before h
  obtain ⟨hself, fee, outerData, quoteAttempts, sources, targets, innerData, innerAttempts,
    _, _, _, _, _, hrest⟩ := hReq
  obtain ⟨_, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, hGS, _, _⟩ := hrest
  refine ⟨hself, u, hTrans, ?_⟩
  intro a ha k
  have h1 : (PhysicalEntrySettlement.execute callee sexternal ctx vault gateway inbox recipient
      msgValue groups before).world.core.readContractSlot a.val k =
      (GatewaySettlement.execute callee callee sexternal ctx vault gateway inbox recipient
        msgValue groups (PhysicalQuotaSettlement.postQuota ctx.self before u)).world.core.readContractSlot
        a.val k := by
    rw [hEq, hQuota]
    try rfl
  rw [h1, hGS, refund_slot hNo ctx _ recipient a ha k _,
    loop_slot hNo ⟨vault, ctx.self⟩ inbox _ a ha k _ _]
  try rfl

#print axioms settlement_preserves_gateway_and_vault_storage

end LidoSRv3.Audit.Guarantees.PConsolidationEth1NoReentry
