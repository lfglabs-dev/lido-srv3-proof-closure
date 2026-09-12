import LidoSRv3.Audit.Guarantees.PConsolidationEth1ActualSettlement
namespace LidoSRv3.Tests.ConsolidationSettlementRegression
open Audit.Source.TrioReserve1 Audit.Source.TrioReserve1.Live
open audit.trio.consolidation
set_option maxRecDepth 16384
set_option maxHeartbeats 4000000

def addr (n : Nat) : Address := Verity.Core.Address.ofNat n
def ctx : Context := ⟨addr 100,addr 999⟩
def groups : List WitnessGroupBytes :=
  [⟨[List.replicate 48 1,List.replicate 48 3],List.replicate 48 2⟩]
def before : World :=
  ⟨{Verity.defaultState with codeSize := fun a => if a = 999 then Live.word 0 else Live.word 1},
    fun a => if a = addr 100 then 10 else if a = addr 200 then 7 else 0,[]⟩
def fees : StaticCall.External := fun r _ =>
  if r.caller = addr 200 ∧ r.target = addr 300 ∧ r.payload = [] ∧ r.value.val = 0 then
    .success (encode 32 2)
  else .rejected [0xff]
def inbox : External := fun r w =>
  if r.caller = addr 200 ∧ r.target = addr 300 ∧ r.value.val = 2 ∧ r.payload.length = 96 then
    .success [] {w with core := (w.core.writeContractSlot 300 777
      (Live.word ((w.core.readContractSlot 300 777).val+1)))}
  else .rejected [0xee]
/-- Refund callback observes the two committed inbox calls, their storage and
value, and the gateway AFTER provisional refund transfer. -/
def refundAccept : External := fun r w =>
  if r.caller = addr 100 ∧ r.target = addr 400 ∧ r.value.val = 2 ∧ r.payload = [] ∧
      (w.core.readContractSlot 300 777).val = 2 ∧ w.balances (addr 300) = 4 ∧
      w.balances (addr 100) = 4 then
    .success [] {w with core := w.core.writeContractSlot 400 888 (Live.word 42)}
  else .rejected [0xdd]
def refundReject : External := fun _ w =>
  if (w.core.readContractSlot 300 777).val = 2 ∧ w.balances (addr 300) = 4 then
    .rejected [0x42]
  else .rejected [0xff]
def dispatch (refund : External) : External := fun r w =>
  if r.caller = addr 200 then inbox r w else refund r w
def execute (r : External) (recipient : Nat) (value : Nat) :=
  GatewaySettlement.execute (dispatch r) (dispatch r) fees ctx (addr 200) (addr 100) (addr 300)
    (addr recipient) (Live.word value) groups before

theorem same_world_success :
    ((execute refundAccept 400 6).outcome,
      (execute refundAccept 400 6).world.balances (addr 100),
      (execute refundAccept 400 6).world.balances (addr 200),
      (execute refundAccept 400 6).world.balances (addr 300),
      (execute refundAccept 400 6).world.balances (addr 400),
      ((execute refundAccept 400 6).world.core.readContractSlot 300 777).val,
      ((execute refundAccept 400 6).world.core.readContractSlot 400 888).val) =
    (.ok (),4,7,4,2,2,42) := by decide +kernel

theorem nested_quote_vault_refund_order :
    ((execute refundAccept 400 6).trace.map (fun a =>
      (a.isStatic,a.depth,a.request.caller.val,a.request.target.val,a.request.value.val))) =
    [(true,1,100,200,0),(true,2,200,300,0),
     (false,1,100,200,4),(true,2,200,300,0),
     (false,2,200,300,2),(false,2,200,300,2),(false,1,100,400,2)] := by decide +kernel

theorem refund_reject_rolls_back_prior_vault_storage_and_value :
    ((execute refundReject 400 6).outcome,
      (execute refundReject 400 6).world.balances (addr 100),
      (execute refundReject 400 6).world.balances (addr 300),
      ((execute refundReject 400 6).world.core.readContractSlot 300 777).val,
      (execute refundReject 400 6).world.logs.length,
      (execute refundReject 400 6).trace.getLast?.map (fun a => a.returned.map UInt8.toNat)) =
    (.error (.reason "FeeRefundFailed"),10,0,0,0,some [0x42]) := by decide +kernel

theorem zero_refund_skips_rejecting_recipient :
    ((execute refundReject 400 4).outcome,
      (execute refundReject 400 4).world.balances (addr 100),
      (execute refundReject 400 4).trace.length) = (.ok (),6,6) := by decide +kernel

theorem zero_recipient_uses_code_less_sender :
    ((execute refundReject 0 6).outcome,
      (execute refundReject 0 6).world.balances (addr 999),
      (execute refundReject 0 6).trace.getLast?.map (fun a => (a.request.target.val,a.request.value.val))) =
    (.ok (),2,some (999,2)) := by decide +kernel

/-- The vault repeats the fee read on its credited world. Changing the quote
there must reject the outer CALL; the first fee is not silently reused. -/
def changedFees : StaticCall.External := fun _ w =>
  .success (encode 32 (if w.balances (addr 100) = 10 then 2 else 3))
theorem fee_requoted_in_vault_world :
    let r := GatewaySettlement.execute (dispatch refundAccept) (dispatch refundAccept) changedFees ctx
      (addr 200) (addr 100) (addr 300) (addr 400) (Live.word 6) groups before
    (r.outcome,r.world.balances (addr 100),r.world.balances (addr 300)) =
      (.error (.bubbled (GatewayCall.error2 0xdcf6afcb 6 4)),10,0) := by decide +kernel

theorem fee_product_overflow_before_vault :
    let r := GatewaySettlement.execute (dispatch refundAccept) (dispatch refundAccept) (fun _ _ => .success (encode 32 (2^255))) ctx
      (addr 200) (addr 100) (addr 300) (addr 400) (Live.word 6) groups before
    (r.outcome,r.trace.length,r.world.balances (addr 100)) =
      (.error (.bubbled (GatewayCall.panic 0x11)),2,10) := by decide +kernel

theorem short_inner_fee_reply_rejected :
    let r := GatewaySettlement.execute (dispatch refundAccept) (dispatch refundAccept) (fun _ _ => .success [1]) ctx
      (addr 200) (addr 100) (addr 300) (addr 400) (Live.word 6) groups before
    (r.outcome,r.trace.map (fun a => (a.isStatic,a.depth,a.accepted))) =
      (.error (.bubbled (GatewayCall.error0 0x8235fc55)),[(true,1,false),(true,2,true)]) := by decide +kernel

theorem checked_count_overflow :
    GatewaySettlement.countGroups [⟨[[]],[]⟩] 0 (2^256-1) =
      .error (.bubbled (GatewayCall.panic 0x11)) := by decide +kernel

/-- An accepted arbitrary refund callback need not preserve the gateway
balance. The source modifier detects that and the root restores the snapshot. -/
theorem accepted_refund_balance_change_rejected :
    let r := execute (fun req w => .success [] (transfer w req.target req.caller req.value.val)) 400 6
    (r.outcome,r.world.balances (addr 100),r.world.balances (addr 300),
      (r.world.core.readContractSlot 300 777).val) =
      (.error (.bubbled (GatewayCall.panic 1)),10,0,0) := by decide +kernel

theorem code_less_vault_typed_decode_failure :
    let w := {before with core := {before.core with codeSize := fun _ => Live.word 0}}
    let r := GatewaySettlement.execute (dispatch refundAccept) (dispatch refundAccept) fees ctx
      (addr 200) (addr 100) (addr 300) (addr 400) (Live.word 6) groups w
    (r.outcome,r.trace.map (fun a => (a.isStatic,a.depth,a.accepted,a.returned))) =
      (.error .empty,[(true,1,true,[])]) := by decide +kernel

#print axioms accepted_refund_balance_change_rejected
#print axioms code_less_vault_typed_decode_failure
#print axioms same_world_success
#print axioms nested_quote_vault_refund_order
#print axioms refund_reject_rolls_back_prior_vault_storage_and_value
#print axioms zero_refund_skips_rejecting_recipient
#print axioms zero_recipient_uses_code_less_sender
#print axioms fee_requoted_in_vault_world
#print axioms fee_product_overflow_before_vault
#print axioms short_inner_fee_reply_rejected
#print axioms checked_count_overflow
end LidoSRv3.Tests.ConsolidationSettlementRegression
