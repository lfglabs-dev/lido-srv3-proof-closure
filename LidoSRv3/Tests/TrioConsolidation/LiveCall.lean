import audit.trio.consolidation.LiveCall

/-! Executable vectors for the vault hop as an actual `Live.CallData` CALL
under `Live.run`. The inbox callees below are acceptance-shape test doubles
(96-byte payload, `value ≥ fee`, one count write, no logs, no return data);
they are not the EIP-7251 predeploy. Test doubles have code, since
`CallData.invoke` checks callee code (residual documented in `LiveCall.lean`). -/

namespace LidoSRv3.Tests.TrioConsolidation.LiveCall

open audit.trio.consolidation
open LidoSRv3.Audit.Source.TrioReserve1
open LidoSRv3.Audit.Source.TrioReserve1.Live
open LidoSRv3.Audit.Source.TrioReserve1.ABI

private def blob (id : Nat) : Bytes := encode pubkeyLength id
private def addr (n : Nat) : Live.Address := Verity.Core.Address.ofNat n

private def vault : Live.Address := addr 0xA1
private def gateway : Live.Address := addr 0xB2
private def stranger : Live.Address := addr 0xC3
private def inbox : Live.Address := addr 0x0000BBdDc7CE488642fb579F8B00f3a590007251
private def recipient : Live.Address := addr 0xD4

private def ctx : Context := ⟨vault, gateway⟩
private def fee : Live.Word := Live.word 7
private def countSlot : Nat := 1

/-- Acceptance-shape inbox: exact target, 96 octets, `value ≥ fee`, `count += 1`. -/
private def acceptingInbox : External := fun req w =>
  if req.target ≠ inbox then .rejected []
  else if req.payload.length ≠ 96 then .rejected []
  else if req.value.val < fee.val then .rejected []
  else
    let count := (w.core.readContractSlot inbox.val countSlot).val
    .success [] { w with core := w.core.writeContractSlot inbox.val countSlot (Live.word (count + 1)) }

/-- Rejects everything. -/
private def rejectingInbox : External := fun _ _ => .rejected [0xFF]

/-- Accepts only while `count = 0`: the second hop of a batch fails. -/
private def onceInbox : External := fun req w =>
  if (w.core.readContractSlot inbox.val countSlot).val ≠ 0 then .rejected [0xEE]
  else acceptingInbox req w

/-- Recipient double for the refund CALL: accepts an empty payload. -/
private def recipientCallee : External := fun req w =>
  if req.payload.length ≠ 0 then .rejected [] else .success [] w

private def core : Verity.ContractState :=
  { Verity.defaultState with
    codeSize := fun a =>
      if a = inbox.val ∨ a = recipient.val ∨ a = gateway.val then Live.word 1 else Live.word 0 }

/-- Entry world of the vault frame: the payable credit already happened. -/
private def before (msgValue : Nat) : World :=
  ⟨core, fun a => if a = vault then msgValue else 0, []⟩

private def sources : List Bytes := [blob 11, blob 12]
private def targets : List Bytes := [blob 21, blob 22]

private def committed : Result Unit :=
  executeVault acceptingInbox ctx gateway inbox fee (Live.word 14) sources targets (before 14)

private def isOk (r : Result Unit) : Bool :=
  match r.outcome with
  | .ok _ => true
  | .error _ => false

/-! ### Committed batch -/

example : isOk committed = true := by native_decide

/-- One line-115 request per zipped pair: callee `CONSOLIDATION_REQUEST`,
value `fee`, payload `source ++ target`. -/
example : committed.attempts.map (·.request) =
    [⟨vault, inbox, fee, blob 11 ++ blob 21⟩, ⟨vault, inbox, fee, blob 12 ++ blob 22⟩] := by
  native_decide

example : committed.attempts.map (·.accepted) = [true, true] := by native_decide

/-- Exactly `msg.value = 2 * fee` moved from the vault to the inbox. -/
example : committed.world.balances vault = 0 := by native_decide
example : committed.world.balances inbox = 14 := by native_decide

/-- Two inbox count writes survived. -/
example : (committed.world.core.readContractSlot inbox.val countSlot).val = 2 := by
  native_decide

/-- Two `ConsolidationRequestAdded` events from the vault, in pair order,
retaining every request octet. -/
example : committed.world.logs.map (·.name) =
    ["ConsolidationRequestAdded", "ConsolidationRequestAdded"] := by native_decide
example : committed.world.logs.map (·.emitter) = [vault, vault] := by native_decide
example : committed.world.logs.map (fun l => l.values.map (·.val)) =
    [(blob 11 ++ blob 21).map UInt8.toNat, (blob 12 ++ blob 22).map UInt8.toNat] := by
  native_decide

/-- The committed vault balance is the entry balance minus `msg.value`
(`preservesEthBalance`). -/
example : committed.world.balances vault = (before 14).balances vault - 14 := by native_decide

/-! ### Rolled-back batches -/

private def rejectedAll : Result Unit :=
  executeVault rejectingInbox ctx gateway inbox fee (Live.word 14) sources targets (before 14)

example : rejectedAll.outcome = .error (.reason "RequestAdditionFailed") := by native_decide
example : rejectedAll.world.balances vault = 14 := by native_decide
example : rejectedAll.world.balances inbox = 0 := by native_decide
example : rejectedAll.world.logs.length = 0 := by native_decide
/-- The failed hop is still observable with its request octets. -/
example : rejectedAll.attempts.map (fun a => (a.accepted, a.request.payload)) =
    [(false, blob 11 ++ blob 21)] := by native_decide

/-- First hop accepted, second rejected: root rollback restores the first
hop's inbox write, event and value transfer together. -/
private def secondFails : Result Unit :=
  executeVault onceInbox ctx gateway inbox fee (Live.word 14) sources targets (before 14)

example : secondFails.outcome = .error (.reason "RequestAdditionFailed") := by native_decide
example : secondFails.attempts.map (·.accepted) = [true, false] := by native_decide
example : secondFails.world.balances vault = 14 := by native_decide
example : secondFails.world.balances inbox = 0 := by native_decide
example : (secondFails.world.core.readContractSlot inbox.val countSlot).val = 0 := by
  native_decide
example : secondFails.world.logs.length = 0 := by native_decide

/-- Guards of lines 60-66 and `WithdrawalVault.sol:203-205`. -/
example : (executeVault acceptingInbox ⟨vault, stranger⟩ gateway inbox fee (Live.word 14)
    sources targets (before 14)).outcome = .error (.reason "NotConsolidationGateway") := by
  native_decide

example : (executeVault acceptingInbox ctx gateway inbox fee (Live.word 14)
    [] [] (before 14)).outcome = .error (.reason "ZeroArgument") := by native_decide

example : (executeVault acceptingInbox ctx gateway inbox fee (Live.word 14)
    sources [blob 21] (before 14)).outcome = .error (.reason "ArraysLengthMismatch") := by
  native_decide

/-- `msg.value ≠ requestsCount * fee`: no hop is attempted. -/
example : (executeVault acceptingInbox ctx gateway inbox fee (Live.word 13)
    sources targets (before 13)).outcome = .error (.reason "IncorrectFee") := by native_decide
example : (executeVault acceptingInbox ctx gateway inbox fee (Live.word 13)
    sources targets (before 13)).attempts = [] := by native_decide

/-- A 47-octet target fails `_validatePublicKey` after the first hop; the
first hop is rolled back. -/
private def shortTarget : Result Unit :=
  executeVault acceptingInbox ctx gateway inbox fee (Live.word 14)
    sources [blob 21, List.replicate 47 1] (before 14)

example : shortTarget.outcome = .error (.reason "InvalidPublicKeyLength") := by native_decide
example : shortTarget.attempts.length = 1 := by native_decide
example : shortTarget.world.balances vault = 14 := by native_decide

/-! ### Refund hop (`ConsolidationGateway.sol:295-307`) -/

private def gatewayCtx : Context := ⟨gateway, stranger⟩
private def gatewayWorld : World := ⟨core, fun a => if a = gateway then 5 else 0, []⟩

example : refundFee recipientCallee gatewayCtx (Live.word 0) recipient gatewayWorld =
    ⟨.ok (), gatewayWorld, []⟩ :=
  refund_zero recipientCallee gatewayCtx recipient (Live.word 0) gatewayWorld rfl

private def refunded : Result Unit :=
  refundFee recipientCallee gatewayCtx (Live.word 5) recipient gatewayWorld

example : isOk refunded = true := by native_decide
example : refunded.attempts.map (·.request) = [⟨gateway, recipient, Live.word 5, []⟩] := by
  native_decide
example : refunded.world.balances gateway = 0 := by native_decide
example : refunded.world.balances recipient = 5 := by native_decide

/-- `address(0)` resolves to `msg.sender` (line 298-300). -/
example : (refundRequest gatewayCtx (Live.word 5) 0).target = stranger := by native_decide
example : resolveRecipient 0 stranger.val = stranger.val := resolveRecipient_zero _

/-- Rejected refund: `FeeRefundFailed`, gateway balance restored. -/
private def refundRejected : Result Unit :=
  refundFee rejectingInbox gatewayCtx (Live.word 5) recipient gatewayWorld

example : refundRejected.outcome = .error (.reason "FeeRefundFailed") := by native_decide
example : refundRejected.world.balances gateway = 5 := by native_decide

/-- Vault hop value plus refund value is `msg.value` (`checkFee_additive`). -/
example : (Live.word 14).val +
    (refundRequest gatewayCtx (audit.trio.consolidation.word (19 - 14)) recipient).value.val = 19 :=
  refund_value_split gatewayCtx recipient (Live.word 19) (Live.word 14) (by decide)

end LidoSRv3.Tests.TrioConsolidation.LiveCall
