import LidoSRv3.Audit.Guarantees.PConsolidationEth1PhysicalQuota
import LidoSRv3.Tests.ConsolidationSettlementRequestsRegression

namespace LidoSRv3.Tests.TrioConsolidation.PhysicalQuotaSettlement
open Audit.Source.TrioReserve1 Audit.Source.TrioReserve1.Live
open audit.trio.consolidation
open ConsolidationSettlementRegression
set_option maxRecDepth 16384
set_option maxHeartbeats 8000000

def raw (maximum previous timestamp duration items : Nat) : Live.Word :=
  Live.word (maximum + previous*2^32 + timestamp*2^64 + duration*2^96 + items*2^128 + 2^255)

theorem disabled_skips_bad_duration_time :
    audit.trio.consolidation.PhysicalQuotaSettlement.transition (raw 0 99 100 0 10) 0 (2^256-1) = .ok none := by decide +kernel
theorem backwards_time :
    audit.trio.consolidation.PhysicalQuotaSettlement.transition (raw 10 6 100 10 0) 99 2 = .error audit.trio.consolidation.PhysicalQuotaSettlement.arithmetic := by decide +kernel
theorem zero_duration_current :
    audit.trio.consolidation.PhysicalQuotaSettlement.transition (raw 10 6 0 0 1) 100 2 = .error audit.trio.consolidation.PhysicalQuotaSettlement.division := by decide +kernel
theorem zero_duration_update_after_early_return :
    audit.trio.consolidation.PhysicalQuotaSettlement.transition (raw 10 6 0 0 0) 100 2 = .error audit.trio.consolidation.PhysicalQuotaSettlement.division := by decide +kernel
theorem count_before_update_division :
    audit.trio.consolidation.PhysicalQuotaSettlement.transition (raw 10 6 0 0 0) 100 7 =
      .error (.bubbled (GatewayCall.error2 0xd0e5bff5 7 6)) := by decide +kernel
theorem inconsistent_previous_limit :
    audit.trio.consolidation.PhysicalQuotaSettlement.transition (raw 3 10 0 1 0) 1 2 = .error (.bubbled (encode 4 0x3261c792)) := by decide +kernel
theorem restored_multiplication_overflow :
    audit.trio.consolidation.PhysicalQuotaSettlement.transition (raw 10 1 0 1 2) (2^256-1) 1 = .error audit.trio.consolidation.PhysicalQuotaSettlement.arithmetic := by decide +kernel
theorem restored_addition_overflow :
    audit.trio.consolidation.PhysicalQuotaSettlement.transition (raw 10 1 0 1 1) (2^256-1) 1 = .error audit.trio.consolidation.PhysicalQuotaSettlement.arithmetic := by decide +kernel
theorem checked_uint32_time_product :
    audit.trio.consolidation.PhysicalQuotaSettlement.transition (raw 10 6 0 3 0) (2^32+2) 2 = .error audit.trio.consolidation.PhysicalQuotaSettlement.arithmetic := by decide +kernel
theorem checked_uint32_timestamp_add :
    audit.trio.consolidation.PhysicalQuotaSettlement.transition (raw 10 6 2 3 0) (2^32+1) 2 = .error audit.trio.consolidation.PhysicalQuotaSettlement.arithmetic := by decide +kernel
theorem frames_cast_before_product :
    audit.trio.consolidation.PhysicalQuotaSettlement.transition (raw 10 6 0 1 0) (2^32+5) 2 =
      .ok (some ⟨6,4,5,raw 10 4 5 1 0⟩) := by decide +kernel
theorem replenish_cap_and_keep_upper96 :
    audit.trio.consolidation.PhysicalQuotaSettlement.transition (raw 10 6 90 10 100) 109 2 =
      .ok (some ⟨10,8,100,raw 10 8 100 10 100⟩) := by decide +kernel

def entry : World := {before with core :=
  {before.core.writeContractSlot 100 audit.trio.consolidation.PhysicalQuotaSettlement.position (raw 10 6 90 10 1) with blockTimestamp := Live.word 100}}
def expectedQuota : Live.Word := raw 10 5 100 10 1
def quotaFees : StaticCall.External := fun req w =>
  if w.core.readContractSlot 100 audit.trio.consolidation.PhysicalQuotaSettlement.position = expectedQuota then fees req w else .rejected [0xfa]
def quotaRefund : External := fun req w =>
  if w.core.readContractSlot 100 audit.trio.consolidation.PhysicalQuotaSettlement.position = expectedQuota then refundAccept req w else .rejected [0xfb]
def run (refund : External) := audit.trio.consolidation.PhysicalQuotaSettlement.execute (dispatch refund) quotaFees ctx
  (addr 200) (addr 100) (addr 300) (addr 400) (Live.word 6) groups entry

/-- Both quote reads and refund observe the actual physical quota write. -/
theorem nonempty_actual_success :
    ((run quotaRefund).outcome,(run quotaRefund).world.core.readContractSlot 100 audit.trio.consolidation.PhysicalQuotaSettlement.position,
      ((run quotaRefund).world.core.readContractSlot 300 777).val,
      ((run quotaRefund).world.core.readContractSlot 400 888).val,
      (run quotaRefund).trace.length) = (.ok (),expectedQuota,2,42,7) := by decide +kernel

theorem public_nonempty :
    ∃ u,
      audit.trio.consolidation.PhysicalQuotaSettlement.QuotaEffects (addr 100) entry (GatewaySettlement.requestCount groups) u ∧
      GatewaySettlement.Success (dispatch quotaRefund) (dispatch quotaRefund) quotaFees ctx
        (addr 200) (addr 100) (addr 300) (addr 400) (Live.word 6) groups (audit.trio.consolidation.PhysicalQuotaSettlement.postQuota (addr 100) entry u) ∧
      SettlementRequests.Effects (dispatch quotaRefund) quotaFees ctx
        (addr 200) (addr 100) (addr 300) (addr 400) (Live.word 6) groups (audit.trio.consolidation.PhysicalQuotaSettlement.postQuota (addr 100) entry u) := by
  have hs : (run quotaRefund).outcome = .ok () := congrArg Prod.fst nonempty_actual_success
  obtain ⟨u,_,_,_,hq,_,he⟩ := Audit.Guarantees.PConsolidationEth1.actual_physical_quota_settlement_requests
    _ _ _ _ _ _ _ _ _ _ hs
  exact ⟨u,hq,he⟩

theorem late_refund_failure :
    ((run refundReject).outcome,(run refundReject).world.core.readContractSlot 100 audit.trio.consolidation.PhysicalQuotaSettlement.position,
      ((run refundReject).world.core.readContractSlot 300 777).val,(run refundReject).trace.length) =
      (.error (.reason "FeeRefundFailed"),raw 10 6 90 10 1,0,7) := by decide +kernel

theorem public_original_rollback : (run refundReject).world = entry :=
  Audit.Guarantees.PConsolidationEth1.actual_physical_quota_failure_restores
    _ _ _ _ _ _ _ _ _ _ _ (congrArg Prod.fst late_refund_failure)

/-- No false final-quota frame: an accepted refund callback can change it. -/
def mutateQuota : External := fun req w =>
  match quotaRefund req w with
  | .success b after => .success b {after with core := after.core.writeContractSlot 100 audit.trio.consolidation.PhysicalQuotaSettlement.position (Live.word 123)}
  | reply => reply
theorem accepted_callback_changes_quota :
    ((run mutateQuota).outcome,(run mutateQuota).world.core.readContractSlot 100 audit.trio.consolidation.PhysicalQuotaSettlement.position) =
      (.ok (),Live.word 123) := by decide +kernel

/-- Executing gateway self owns the quota, not the vault's configured gate. -/
theorem physical_owner_before_vault_authorization :
    let w := {entry with core := (entry.core.writeContractSlot 100
      audit.trio.consolidation.PhysicalQuotaSettlement.position (raw 10 0 100 10 1))}
    (audit.trio.consolidation.PhysicalQuotaSettlement.execute (dispatch quotaRefund) quotaFees ctx
      (addr 200) (addr 999) (addr 300) (addr 400) (Live.word 6) groups w).outcome =
      .error (.bubbled (GatewayCall.error2 0xd0e5bff5 2 0)) := by decide +kernel

#print axioms public_nonempty
#print axioms public_original_rollback
#print axioms nonempty_actual_success
#print axioms accepted_callback_changes_quota
end LidoSRv3.Tests.TrioConsolidation.PhysicalQuotaSettlement
