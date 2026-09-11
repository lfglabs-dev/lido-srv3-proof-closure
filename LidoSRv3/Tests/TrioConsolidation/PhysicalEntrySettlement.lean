import LidoSRv3.Audit.Guarantees.PConsolidationEth1PhysicalEntry
import LidoSRv3.Tests.TrioConsolidation.PhysicalQuotaSettlement
namespace LidoSRv3.Tests.TrioConsolidation.PhysicalEntrySettlement
open Audit.Source.TrioReserve1 Audit.Source.TrioReserve1.Live
open audit.trio.consolidation.PhysicalEntrySettlement
open audit.trio.consolidation
open ConsolidationSettlementRegression
set_option maxRecDepth 16384
set_option maxHeartbeats 8000000

/-- Admission-only cases use constant storage, avoiding kernel Keccak work. -/
def uniform (raw time balance : Nat) : World :=
  ⟨{Verity.defaultState with storageWords := fun _ => Live.word raw,blockTimestamp := Live.word time},fun _ => balance,[]⟩
theorem role_before_balance_and_pause : gates ctx (Live.word 1) (uniform 0 0 0) =
    .error (.bubbled (unauthorized ctx.sender)) := by decide +kernel
theorem high_bits_only_not_role : gates ctx (Live.word 1) (uniform 256 0 0) =
    .error (.bubbled (unauthorized ctx.sender)) := by decide +kernel
theorem noncanonical_lowbyte_accepted : gates ctx (Live.word 6) (uniform 2 2 6) = .ok () := by decide +kernel
theorem balance_underflow_before_pause : gates ctx (Live.word 1) (uniform 2 0 0) =
    .error PhysicalQuotaSettlement.arithmetic := by decide +kernel
theorem full_word_pause_after_balance : gates ctx (Live.word 1) (uniform (2^255+2) 2 1) =
    .error (.bubbled (encode 4 0x14378398)) := by decide +kernel
theorem pause_before_zero_value : gates ctx (Live.word 0) (uniform 2 0 0) =
    .error (.bubbled (encode 4 0x14378398)) := by decide +kernel
theorem resume_equality : gates ctx (Live.word 1) (uniform 2 2 1) = .ok () := by decide +kernel
theorem max_pause_before_max : gates ctx (Live.word 1) (uniform (2^256-1) (2^256-2) 1) =
    .error (.bubbled (encode 4 0x14378398)) := by decide +kernel
theorem max_pause_at_max : gates ctx (Live.word 1) (uniform (2^256-1) (2^256-1) 1) = .ok () := by decide +kernel
theorem unauthorized_exact_bytes : (unauthorized ctx.sender).length = 68 ∧
    (unauthorized ctx.sender).take 4 = [0xe2,0x51,0x7d,0x3f] ∧
    (unauthorized ctx.sender).drop 4 = encode 32 999 ++ encode 32 role := by decide +kernel

def blocked := audit.trio.consolidation.PhysicalEntrySettlement.execute (dispatch refundAccept) fees ctx
  (addr 200) (addr 100) (addr 300) (addr 400) (Live.word 0) [] (uniform 0 0 0)
theorem role_before_empty_and_zero : blocked.outcome = .error (.bubbled (unauthorized ctx.sender)) ∧
    blocked.suffix.isNone = true ∧ blocked.trace = [] := by decide +kernel
theorem admitted_zero_value_reaches_old_guard :
    (audit.trio.consolidation.PhysicalEntrySettlement.execute (dispatch refundAccept) fees ctx
      (addr 200) (addr 100) (addr 300) (addr 400) (Live.word 0) [] (uniform 2 2 0)).outcome =
      .error (.bubbled (GatewayCall.errorBytes 0x56e42893 "msg.value".toUTF8.toList)) := by decide +kernel

/-- Constant gateway storage admits every symbolic role slot. Other contracts
start with zero storage. A separate runtime suite evaluates actual Keccak slots.
Large raw timestamp makes the shared resume word admissible; quota's uint32
frames cast is deliberately exercised, not replaced by a fit hypothesis. -/
def initialRaw : Live.Word := PhysicalQuotaSettlement.raw 10 6 0 1 0
def finalRaw : Live.Word := PhysicalQuotaSettlement.raw 10 4 10 1 0
def entry : World := {before with core := {before.core with
  blockTimestamp := initialRaw
  storageWords := fun k => match k with
    | .contractSlot owner _ => if owner = 100 then initialRaw else Live.word 0
    | _ => Live.word 0}}
def entryFees : StaticCall.External := fun req w =>
  if w.core.readContractSlot 100 audit.trio.consolidation.PhysicalQuotaSettlement.position = finalRaw then fees req w
  else .rejected [0xfa]
def entryRefund : External := fun req w =>
  if w.core.readContractSlot 100 audit.trio.consolidation.PhysicalQuotaSettlement.position = finalRaw then refundAccept req w
  else .rejected [0xfb]
def run (refund : External) := audit.trio.consolidation.PhysicalEntrySettlement.execute (dispatch refund) entryFees ctx
  (addr 200) (addr 100) (addr 300) (addr 400) (Live.word 6) groups entry
theorem actual_nonempty_success :
    ((run entryRefund).outcome,(run entryRefund).world.core.readContractSlot 100 audit.trio.consolidation.PhysicalQuotaSettlement.position,
      ((run entryRefund).world.core.readContractSlot 300 777).val,
      ((run entryRefund).world.core.readContractSlot 400 888).val,(run entryRefund).trace.length) =
      (.ok (),finalRaw,2,42,7) := by decide +kernel
theorem public_nonempty :
    Admitted ctx (Live.word 6) entry ∧ ∃ u,
      audit.trio.consolidation.PhysicalQuotaSettlement.QuotaEffects ctx.self entry (GatewaySettlement.requestCount groups) u ∧
      GatewaySettlement.Success (dispatch entryRefund) (dispatch entryRefund) entryFees ctx
        (addr 200) (addr 100) (addr 300) (addr 400) (Live.word 6) groups
        (audit.trio.consolidation.PhysicalQuotaSettlement.postQuota ctx.self entry u) ∧
      SettlementRequests.Effects (dispatch entryRefund) entryFees ctx
        (addr 200) (addr 100) (addr 300) (addr 400) (Live.word 6) groups
        (audit.trio.consolidation.PhysicalQuotaSettlement.postQuota ctx.self entry u) := by
  obtain ⟨ha,_,u,_,_,_,hq,_,hs⟩ := Audit.Guarantees.PConsolidationEth1.actual_physical_entry_quota_settlement_requests
    _ _ _ _ _ _ _ _ _ _ (congrArg Prod.fst actual_nonempty_success)
  exact ⟨ha,u,hq,hs⟩
theorem late_refund_failure :
    ((run refundReject).outcome,(run refundReject).world.core.readContractSlot 100 audit.trio.consolidation.PhysicalQuotaSettlement.position,
      ((run refundReject).world.core.readContractSlot 300 777).val,(run refundReject).trace.length) =
      (.error (.reason "FeeRefundFailed"),initialRaw,0,7) := by decide +kernel
theorem public_original_rollback : (run refundReject).world = entry :=
  Audit.Guarantees.PConsolidationEth1.actual_physical_entry_failure_restores
    _ _ _ _ _ _ _ _ _ _ _ (congrArg Prod.fst late_refund_failure)

#print axioms public_nonempty
#print axioms public_original_rollback
#print axioms actual_nonempty_success
end LidoSRv3.Tests.TrioConsolidation.PhysicalEntrySettlement
