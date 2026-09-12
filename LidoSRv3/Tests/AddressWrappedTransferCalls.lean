import LidoSRv3.Audit.Guarantees.PAddress1WrappedTransferCalls
namespace LidoSRv3.Tests.AddressWrappedTransferCalls
set_option autoImplicit false
set_option maxRecDepth 16384
open LidoSRv3.Audit.Source.TrioReserve1
open Live
open LidoSRv3.Audit.Source.AddressWrappedTransferCalls
open LidoSRv3.Audit.Source.AddressWrappedTokenCalls (balanceSlot supplySlot stETHSlot)
open LidoSRv3.Audit.Verity.AddressRecipientCallBridge (StaticExternal stETHTransferFromCalldata pooledEthBySharesCalldata erc20TransferCalldata stETHSharesCalldata)
open LidoSRv3.Audit.Guarantees.PAddress1

def kernelWorld : World := ⟨{Verity.defaultState with codeSize := (fun _ => word 1), storageWords := (fun _ => word 2)},fun _ => 100,[]⟩
def reject : External := fun _ _ => .rejected [0xee]
def staticReply (data : Bytes) : StaticExternal := fun _ _ => .ok data

example : allowanceSlot 1 99 = Compiler.Proofs.nestedMappingSlotLocation 1 1 99 0 := rfl
example : (move 3 0 0 (word 7) kernelWorld).outcome = .error (.reason "ERC20: transfer from the zero address") := by decide +kernel
example : (move 3 1 0 (word 7) kernelWorld).outcome = .error (.reason "ERC20: transfer to the zero address") := by decide +kernel
example : (move 3 1 99 (word 7) kernelWorld).outcome = .error (.reason "ERC20: transfer amount exceeds balance") := by decide +kernel
example : (spend ⟨3,0⟩ 0 (word 7) kernelWorld).outcome = .error (.reason "ERC20: transfer amount exceeds allowance") := by decide +kernel
example : (spend ⟨3,0⟩ 0 (word 1) kernelWorld).outcome = .error (.reason "ERC20: approve from the zero address") := by decide +kernel
example : (spend ⟨3,0⟩ 1 (word 1) kernelWorld).outcome = .error (.reason "ERC20: approve to the zero address") := by decide +kernel
example : (transferFrom ⟨3,0⟩ 0 0 (word 7) kernelWorld).outcome = .error (.reason "ERC20: transfer from the zero address") := by decide +kernel
example : (calleeFor 3 reject ⟨99,3,1,[0x23,0xb8,0x72,0xdd]⟩ kernelWorld) = .rejected [] := by rfl
example : (calleeFor 3 reject ⟨99,3,0,[0x23,0xb8,0x72,0xdd]⟩ kernelWorld) = .rejected [] := by rfl
example : (calleeFor 3 reject ⟨99,2,0,[0x23,0xb8,0x72,0xdd]⟩ kernelWorld) = .rejected [0xee] := by rfl
example : calleeFor 3 reject ⟨99,3,0,stETHTransferFromCalldata 0 99 7⟩ kernelWorld =
    .rejected (ReplyABI.reason "ERC20: transfer from the zero address") := by
  change calleeFor 3 reject ⟨99,3,0,stETHTransferFromCalldata 0 99 (word 7).val⟩ kernelWorld = _
  rw [canonical_call]
  rfl
example : calleeFor 3 reject ⟨99,3,0,stETHTransferFromCalldata 1 0 7⟩ kernelWorld =
    .rejected (ReplyABI.reason "ERC20: transfer to the zero address") := by
  change calleeFor 3 reject ⟨99,3,0,stETHTransferFromCalldata 1 0 (word 7).val⟩ kernelWorld = _
  rw [canonical_call]
  rfl

theorem public_zero_sender_rollback :
    (runRequest (staticReply []) reject reject (staticReply []) ⟨99,0⟩ 3 2 (word 7) 0 kernelWorld).world = kernelWorld := by
  apply actual_wrapped_transfer_request_failure_restores _ _ _ _ _ _ _ _ _ _
    (.bubbled (ReplyABI.reason "ERC20: transfer from the zero address"))
  rfl

/-- Keccak-positive executions are native diagnostics only; no axiom or
native_decide is used to promote them into kernel theorems. -/
def before : World :=
  let core := {Verity.defaultState with codeSize := (fun _ => word 1), blockTimestamp := word 42}
  let core := (((core.writeContractSlot 3 stETHSlot (word 2)).writeContractSlot 3 supplySlot (word 7)).writeContractSlot 3 (balanceSlot 1) (word 7)).writeContractSlot 3 (allowanceSlot 1 99) (word 7)
  ⟨core,fun _ => 100,[]⟩
def conversion (value : Nat := 123) : StaticExternal := fun req w =>
  if req.caller = 3 ∧ req.target = 2 ∧ req.payload = pooledEthBySharesCalldata 7 ∧
      (w.core.readContractSlot 3 (balanceSlot 99)).val = 7 ∧
      (w.core.readContractSlot 3 (allowanceSlot 1 99)).val = 0 then .ok (encode 32 value) else .error (.bubbled [0x11])
def tokenTransfer (size : Nat := 32) (callback : Bool := false) : External := fun req w =>
  if req.caller = 3 ∧ req.target = 2 ∧ req.payload = erc20TransferCalldata 99 123 ∧
      (w.core.readContractSlot 3 (balanceSlot 99)).val = 0 ∧ (w.core.readContractSlot 3 supplySlot).val = 0 then
    let core := if callback then w.core.writeContractSlot 3 supplySlot (word 5) else w.core
    .success ((encode 32 2).take size) {w with core := core, logs := w.logs ++ [⟨2,"TokenTransferEffect",[]⟩]}
  else .rejected [0x22]
def queueQuote : StaticExternal := fun req _ =>
  if req.caller = 99 ∧ req.target = 2 ∧ req.payload = stETHSharesCalldata 123
  then .ok (encode 32 (2^128+5)) else .error (.bubbled [0x33])
def result := runRequest (conversion 123) (tokenTransfer 32 false) reject queueQuote ⟨99,1⟩ 3 2 (word 7) 0 before

def diagnostics : IO Unit := do
  let r := result
  unless r.outcome == .ok 1 && r.world.logs.map (·.name) == ["Transfer","Approval","Transfer","TokenTransferEffect","WithdrawalRequested","Transfer"] &&
      r.attempts.map (·.request.target.val) == [3,3,2] do
    throw (IO.userError "complete transferFrom unwrap quote enqueue chain failed")
  unless (r.world.logs.head?.map (fun e => e.values.map (·.val))) == some [1,99,7] &&
      ((r.world.logs.drop 1).head?.map (fun e => e.values.map (·.val))) == some [1,99,0] &&
      ((r.world.logs.drop 4).head?.map (fun e => e.values.map (·.val))) == some [1,1,1,123,5] &&
      (r.world.core.readContractSlot 3 (allowanceSlot 1 99)).val == 0 do
    throw (IO.userError "canonical arguments, allowance, or request amount not consumed")
  let aliasRun := transferFrom ⟨3,99⟩ 1 1 (word 7) before
  unless aliasRun.outcome == .ok () && (aliasRun.world.core.readContractSlot 3 (balanceSlot 1)).val == 7 &&
      (aliasRun.world.core.readContractSlot 3 (allowanceSlot 1 99)).val == 0 do
    throw (IO.userError "self-transfer used stale recipient balance")
  let badAllowance := {before with core := before.core.writeContractSlot 3 (allowanceSlot 1 99) (word 6)}
  let lateAllowance := transferFrom ⟨3,99⟩ 1 99 (word 7) badAllowance
  unless lateAllowance.outcome == .error (.reason "ERC20: transfer amount exceeds allowance") &&
      (lateAllowance.world.core.readContractSlot 3 (balanceSlot 1)).val == 0 &&
      (lateAllowance.world.core.readContractSlot 3 (balanceSlot 99)).val == 7 && lateAllowance.world.logs.map (·.name) == ["Transfer"] do
    throw (IO.userError "allowance tested before physical transfer and event")
  let fullBad := runRequest (conversion 123) (tokenTransfer 32 false) reject queueQuote ⟨99,1⟩ 3 2 (word 7) 0 badAllowance
  unless fullBad.world.logs.isEmpty && (fullBad.world.core.readContractSlot 3 (balanceSlot 1)).val == 7 && fullBad.attempts.length == 1 do
    throw (IO.userError "allowance failure failed root rollback or ran unwrap")
  let overflow := {before with core := before.core.writeContractSlot 3 (balanceSlot 99) (word (2^256-1))}
  let overflowRun := transferFrom ⟨3,99⟩ 1 99 (word 7) overflow
  unless overflowRun.outcome == .error (.reason "SafeMath: addition overflow") &&
      (overflowRun.world.core.readContractSlot 3 (balanceSlot 1)).val == 0 && overflowRun.world.logs.isEmpty do
    throw (IO.userError "recipient overflow ordering failed")
  let zero := transferFrom ⟨3,99⟩ 1 99 (word 0) before
  unless zero.outcome == .ok () && zero.world.logs.map (·.name) == ["Transfer","Approval"] do
    throw (IO.userError "zero transferFrom spuriously rejected")
  let cb := runRequest (conversion 123) (tokenTransfer 32 true) reject queueQuote ⟨99,1⟩ 3 2 (word 7) 0 before
  unless cb.outcome == .ok 1 && (cb.world.core.readContractSlot 3 supplySlot).val == 5 do
    throw (IO.userError "arbitrary stETH returned-world callback erased")
  let short := runRequest (conversion 123) (tokenTransfer 31 false) reject queueQuote ⟨99,1⟩ 3 2 (word 7) 0 before
  unless short.outcome == .error (.bubbled []) && short.world.logs.isEmpty &&
      (short.world.core.readContractSlot 3 (balanceSlot 1)).val == 7 &&
      (short.world.core.readContractSlot 3 (allowanceSlot 1 99)).val == 7 do
    throw (IO.userError "short transfer failed full allowance/balance rollback")
  let late := runRequest (conversion 99) (fun _ w => .success (encode 32 2) w) reject queueQuote ⟨99,1⟩ 3 2 (word 7) 0 before
  unless late.outcome == .error (.reason "RequestAmountTooSmall") && late.world.logs.isEmpty &&
      (late.world.core.readContractSlot 3 (balanceSlot 1)).val == 7 &&
      (late.world.core.readContractSlot 3 (allowanceSlot 1 99)).val == 7 do
    throw (IO.userError "late enqueue amount rejection failed whole entry rollback")
  IO.println "PASS 10 native checks: full chain, canonical payload/events, self-transfer, late allowance, allowance root rollback, checked recipient overflow, zero transfer, callback, short return rollback, late amount rollback"

#print axioms LidoSRv3.Audit.Source.AddressWrappedTransferCalls.move_success
#print axioms LidoSRv3.Audit.Source.AddressWrappedTransferCalls.spend_success
#print axioms LidoSRv3.Audit.Source.AddressWrappedTransferCalls.transferFrom_success
#print axioms LidoSRv3.Audit.Source.AddressWrappedTransferCalls.canonical_call
#print axioms LidoSRv3.Audit.Source.AddressWrappedTransferCalls.canonical_outer_call
#print axioms LidoSRv3.Audit.Source.AddressWrappedTransferCalls.joined_success
#print axioms actual_wrapped_transfer_request_enqueue
#print axioms actual_wrapped_transfer_request_failure_restores
#print axioms public_zero_sender_rollback
end LidoSRv3.Tests.AddressWrappedTransferCalls
