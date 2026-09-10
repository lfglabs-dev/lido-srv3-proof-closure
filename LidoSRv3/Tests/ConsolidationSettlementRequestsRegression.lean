import LidoSRv3.Audit.Guarantees.PConsolidationEth1Requests
import LidoSRv3.Tests.ConsolidationSettlementRegression

namespace LidoSRv3.Tests.ConsolidationSettlementRequestsRegression
open Audit.Source.TrioReserve1 Audit.Source.TrioReserve1.Live
open audit.trio.consolidation
open ConsolidationSettlementRegression
set_option maxRecDepth 16384
set_option maxHeartbeats 4000000

/-- The earlier same-world fixture is a real successful execution, not a
supplied successful vault/loop/refund premise. -/
theorem actual_two_requests_joint_consumer :
    GatewaySettlement.Success (dispatch refundAccept) (dispatch refundAccept) fees ctx
      (addr 200) (addr 100) (addr 300) (addr 400) (Live.word 6) groups before ∧
    SettlementRequests.Effects (dispatch refundAccept) fees ctx
      (addr 200) (addr 100) (addr 300) (addr 400) (Live.word 6) groups before :=
  Audit.Guarantees.PConsolidationEth1.actual_settlement_requests _ _ _ _ _ _ _ _ _ _
    (congrArg Prod.fst same_world_success)

def sources : List Bytes := [List.replicate 48 1,List.replicate 48 3]
def targets : List Bytes := [List.replicate 48 2,List.replicate 48 2]

theorem actual_bytes_decode :
    decodeVaultArgs (gatewayVaultArgs (GatewayCall.sourceArray groups) (GatewayCall.targetArray groups)) =
      some (sources,targets) := by decide +kernel

def decodedLoop := addConsolidationRequestsLoop (dispatch refundAccept) ⟨addr 200,addr 100⟩
  (addr 300) (Live.word 2) (pairsOf sources targets) (transfer before (addr 100) (addr 200) 4)
def refundFromLoop := refundFee (dispatch refundAccept) ctx (Live.word 2) (addr 400) decodedLoop.world

/-- Exact source+target request bytes, fees and full loop state, subsequently
consumed by the real callback which observes slot777 and writes slot888. -/
theorem decoded_loop_and_refund_effects :
    (decodedLoop.outcome,
      decodedLoop.attempts.map (fun a => (a.request.caller.val,a.request.target.val,a.request.value.val,a.request.payload)),
      (decodedLoop.world.core.readContractSlot 300 777).val,
      decodedLoop.world.balances (addr 300),refundFromLoop.outcome,
      (refundFromLoop.world.core.readContractSlot 400 888).val) =
    (.ok (),[(200,300,2,List.replicate 48 1 ++ List.replicate 48 2),
             (200,300,2,List.replicate 48 3 ++ List.replicate 48 2)],2,4,.ok (),42) := by rfl

theorem zero_refund_joint_consumer :
    GatewaySettlement.Success (dispatch refundReject) (dispatch refundReject) fees ctx
      (addr 200) (addr 100) (addr 300) (addr 400) (Live.word 4) groups before ∧
    SettlementRequests.Effects (dispatch refundReject) fees ctx
      (addr 200) (addr 100) (addr 300) (addr 400) (Live.word 4) groups before :=
  Audit.Guarantees.PConsolidationEth1.actual_settlement_requests _ _ _ _ _ _ _ _ _ _
    (congrArg Prod.fst zero_refund_skips_rejecting_recipient)

/-- Fee observations are genuinely taken on distinct worlds: the inner read
sees the vault's credited CALL world and may differ from the outer quote. -/
theorem distinct_fee_read_worlds :
    (GatewaySettlement.quote changedFees ctx (addr 200) (addr 300) before).outcome = .ok (Live.word 2) ∧
    (lowLevelStaticCall changedFees (addr 200) (addr 300) []
      (transfer before (addr 100) (addr 200) 4)).outcome = .ok (encode 32 3) := by decide +kernel

theorem changed_inner_fee_rejects_and_restores :
    let result := GatewaySettlement.execute (dispatch refundAccept) (dispatch refundAccept) changedFees ctx
      (addr 200) (addr 100) (addr 300) (addr 400) (Live.word 6) groups before
    result.outcome = .error (.bubbled (GatewayCall.error2 0xdcf6afcb 6 4)) ∧ result.world = before := by
  have h := congrArg Prod.fst fee_requoted_in_vault_world
  exact ⟨h,Audit.Guarantees.PConsolidationEth1.actual_settlement_failure_restores _ _ _ _ _ _ _ _ _ _ _ h⟩

theorem rejected_refund_restores_inbox_effects :
    (execute refundReject 400 6).world = before :=
  Audit.Guarantees.PConsolidationEth1.actual_settlement_failure_restores _ _ _ _ _ _ _ _ _ _ _
    (congrArg Prod.fst refund_reject_rolls_back_prior_vault_storage_and_value)

#print axioms actual_two_requests_joint_consumer
#print axioms actual_bytes_decode
#print axioms decoded_loop_and_refund_effects
#print axioms zero_refund_joint_consumer
#print axioms distinct_fee_read_worlds
#print axioms changed_inner_fee_rejects_and_restores
#print axioms rejected_refund_restores_inbox_effects
end LidoSRv3.Tests.ConsolidationSettlementRequestsRegression
