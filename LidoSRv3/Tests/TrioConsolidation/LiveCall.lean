import audit.trio.consolidation.LiveCall

/-! Executable vectors for the vault hop as an actual low-level CALL
(`lowLevelCall`, no target-code guard) under `Live.run`, with the fee read by
an actual low-level `staticcall("")` (`lowLevelStaticCall`). The inbox callees
below are acceptance-shape test doubles (96-byte payload, `value ≥ fee`, one
count write, no logs, no return data); they are not the EIP-7251 predeploy
(`Predeploy.lean` is the concrete body). The fee doubles answer the line-84
`staticcall("")`. -/

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

/-- Fee STATICCALL double: answers the 32-byte encoding of `fee` to
`staticcall("")` (the `_getFeeFromContract` returndata of lines 83-95). -/
private def feeStatic : StaticCall.External := fun req _ =>
  if req.payload = [] then .success (encode 32 fee.val) else .rejected []

/-- Failed STATICCALL (`FeeReadFailed`, lines 86-88). -/
private def feeRejectedStatic : StaticCall.External := fun _ _ => .rejected []

/-- 16-byte returndata (`FeeInvalidData`, lines 90-92). -/
private def feeShortStatic : StaticCall.External := fun _ _ => .success (encode 16 fee.val)

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
  executeVault acceptingInbox feeStatic ctx gateway inbox (Live.word 14) sources targets (before 14)

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
  executeVault rejectingInbox feeStatic ctx gateway inbox (Live.word 14) sources targets (before 14)

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
  executeVault onceInbox feeStatic ctx gateway inbox (Live.word 14) sources targets (before 14)

example : secondFails.outcome = .error (.reason "RequestAdditionFailed") := by native_decide
example : secondFails.attempts.map (·.accepted) = [true, false] := by native_decide
example : secondFails.world.balances vault = 14 := by native_decide
example : secondFails.world.balances inbox = 0 := by native_decide
example : (secondFails.world.core.readContractSlot inbox.val countSlot).val = 0 := by
  native_decide
example : secondFails.world.logs.length = 0 := by native_decide

/-- Guards of lines 60-66 and `WithdrawalVault.sol:203-205`. -/
example : (executeVault acceptingInbox feeStatic ⟨vault, stranger⟩ gateway inbox (Live.word 14)
    sources targets (before 14)).outcome = .error (.reason "NotConsolidationGateway") := by
  native_decide

example : (executeVault acceptingInbox feeStatic ctx gateway inbox (Live.word 14)
    [] [] (before 14)).outcome = .error (.reason "ZeroArgument") := by native_decide

example : (executeVault acceptingInbox feeStatic ctx gateway inbox (Live.word 14)
    sources [blob 21] (before 14)).outcome = .error (.reason "ArraysLengthMismatch") := by
  native_decide

/-- `msg.value ≠ requestsCount * fee`: no hop is attempted. -/
example : (executeVault acceptingInbox feeStatic ctx gateway inbox (Live.word 13)
    sources targets (before 13)).outcome = .error (.reason "IncorrectFee") := by native_decide
example : (executeVault acceptingInbox feeStatic ctx gateway inbox (Live.word 13)
    sources targets (before 13)).attempts = [] := by native_decide

/-! ### Fee STATICCALL ladder (lines 83-95) -/

/-- A failed `staticcall("")` is `FeeReadFailed`; no hop is attempted. -/
example : (executeVault acceptingInbox feeRejectedStatic ctx gateway inbox (Live.word 14)
    sources targets (before 14)).outcome = .error (.reason "FeeReadFailed") := by native_decide

/-- 16-byte returndata is `FeeInvalidData`; no hop is attempted. -/
example : (executeVault acceptingInbox feeShortStatic ctx gateway inbox (Live.word 14)
    sources targets (before 14)).outcome = .error (.reason "FeeInvalidData") := by native_decide

/-- A code-less target of the fee STATICCALL answers empty success, which the
caller-side 32-byte check rejects as `FeeInvalidData` (matching the source). -/
private def codelessCore : Verity.ContractState :=
  { Verity.defaultState with codeSize := fun _ => Live.word 0 }

example : (executeVault acceptingInbox feeStatic ctx gateway inbox (Live.word 14)
    sources targets ⟨codelessCore, fun a => if a = vault then 14 else 0, []⟩).outcome =
      .error (.reason "FeeInvalidData") := by native_decide

/-- A 47-octet target fails `_validatePublicKey` after the first hop; the
first hop is rolled back. -/
private def shortTarget : Result Unit :=
  executeVault acceptingInbox feeStatic ctx gateway inbox (Live.word 14)
    sources [blob 21, List.replicate 47 1] (before 14)

example : shortTarget.outcome = .error (.reason "InvalidPublicKeyLength") := by native_decide
example : shortTarget.attempts.length = 1 := by native_decide
example : shortTarget.world.balances vault = 14 := by native_decide

/-! ### Code-less (EOA) arms of the low-level CALL -/

/-- Code-less hop target (`stranger` has no code in `core`): the low-level
CALL accepts with empty return data after the value transfer; the rejecting
callee double is never run. -/
example : callAddConsolidationRequest rejectingInbox ctx stranger
    { source := blob 11, target := blob 21 } fee (before 7) =
    ⟨.ok (),
      { transfer (before 7) vault stranger fee.val with
          logs := (before 7).logs ++ [requestAddedEvent vault (blob 11 ++ blob 21)] },
      [⟨⟨vault, stranger, fee, blob 11 ++ blob 21⟩, true, [], []⟩]⟩ :=
  callAdd_no_code_accepted rejectingInbox ctx stranger { source := blob 11, target := blob 21 }
    fee (before 7) (by native_decide) (by native_decide)

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

/-- EOA refund recipient (`stranger` has no code): the low-level `.call`
accepts with empty return data after the value transfer; the rejecting callee
double is never run. -/
example : refundFee rejectingInbox gatewayCtx (Live.word 5) stranger gatewayWorld =
    ⟨.ok (), transfer gatewayWorld gateway stranger 5,
      [⟨⟨gateway, stranger, Live.word 5, []⟩, true, [], []⟩]⟩ :=
  refund_no_code_accepted rejectingInbox gatewayCtx stranger (Live.word 5) gatewayWorld
    (by native_decide) (by native_decide) (by native_decide)

end LidoSRv3.Tests.TrioConsolidation.LiveCall
