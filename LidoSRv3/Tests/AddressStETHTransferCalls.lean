import LidoSRv3.Audit.Guarantees.PAddress1StETHTransferCalls
namespace LidoSRv3.Tests.AddressStETHTransferCalls
open LidoSRv3.Audit.Source
open TrioReserve1 Live
open AddressStETHTransferCalls
open AddressStETHQuoteCalls (sharesSlot bufferedSlot clSlot quote)
open AddressStETHConversionCalls (conversion)
open AddressRequestBatches AddressPermitRequestCalls
open LidoSRv3.Audit.Guarantees.PAddress1
open LidoSRv3.Audit.Verity.AddressRecipientCallBridge (erc20TransferCalldata)
set_option maxRecDepth 16384
set_option maxHeartbeats 2000000

def ctx : Context := ⟨99,1⟩
def p : PermitInput := ⟨word 15,word 500,27,word 8,word 9⟩
def base : World := ⟨{Verity.defaultState with codeSize := fun _ => word 1,blockTimestamp := word 42},fun _ => 100,[]⟩
def physical (s b c : Nat) : World :=
  {base with core := ((base.core.writeContractSlot 4 sharesSlot (word s)).writeContractSlot 4 bufferedSlot (word b)).writeContractSlot 4 clSlot (word c)}
def reject : External := fun _ _ => .rejected [0xaa]
def permit : External := fun _ w => .success [] {w with core := w.core.writeSlot 123 (word 15),logs := w.logs ++ [⟨3,"Permit",[]⟩]}

example : (erc20TransferCalldata 99 700).length = 68 := by decide +kernel
example : (erc20TransferCalldata 99 700).take 4 = [0xa9,0x05,0x9c,0xbb] := by decide +kernel
example : (erc20TransferCalldata 99 700).drop 4 = encode 32 99 ++ encode 32 700 := by decide +kernel
example : (program ⟨4,0⟩ 0 (word (2^128-1)) base).outcome = .error (.bubbled (ReplyABI.reason "ETH_TOO_LARGE")) := by decide +kernel
example : (program ⟨4,0⟩ 0 (word 1) base).outcome = .error (.bubbled []) := by decide +kernel
example : (program ⟨4,0⟩ 0 (word 7) (physical 20 2000 0)).outcome = .error (.bubbled (ReplyABI.reason "TRANSFER_FROM_ZERO_ADDR")) := by decide +kernel
example : (program ⟨4,3⟩ 0 (word 7) (physical 20 2000 0)).outcome = .error (.bubbled (ReplyABI.reason "TRANSFER_TO_ZERO_ADDR")) := by decide +kernel
example : (program ⟨4,3⟩ 4 (word 7) (physical 20 2000 0)).outcome = .error (.bubbled (ReplyABI.reason "TRANSFER_TO_STETH_CONTRACT")) := by decide +kernel
example : (program ⟨4,3⟩ 99 (word 7) (physical 20 2000 0)).outcome = .error (.bubbled (ReplyABI.reason "CONTRACT_IS_STOPPED")) := by decide +kernel
example : callee ⟨3,4,1,erc20TransferCalldata 99 700⟩ base = .rejected [] := by rfl
example : callee ⟨3,4,0,encode 4 0xa9059cbb ++ List.replicate 63 0⟩ base = .rejected [] := by rfl
example : callee ⟨3,4,0,erc20TransferCalldata 0 700⟩ (physical 20 2000 0) = .rejected (ReplyABI.reason "TRANSFER_TO_ZERO_ADDR") := by rfl

-- Constant physical storage avoids evaluating Keccak in these admission tests;
-- later native diagnostics use the actual mapping backend and exact slot words.
def constantStorage (v : Word) : World := {base with core := {base.core with storageWords := fun _ => v}}
example : (move ⟨4,3⟩ 99 (word 700) (word 3) (constantStorage (word 2))).outcome = .error (.bubbled (ReplyABI.reason "BALANCE_EXCEEDED")) := by decide +kernel
example : (move ⟨4,3⟩ 99 (word 700) (word (2^255+1)) (constantStorage (word (2^255)))).outcome = .error (.bubbled (ReplyABI.reason "BALANCE_EXCEEDED")) := by decide +kernel

def empty := runBatch (wrappedStep conversion callee reject (quote 2) ctx 3 2) ctx 0 []
theorem public_empty_success : PhysicalConversionPermitEffect permit reject ctx 3 2 0 p [] [] base
    (runPermit permit ctx 3 p empty base).world (runPermit permit ctx 3 p empty base).attempts :=
  (actual_wrapped_physical_steth_transfer_permit_batch permit reject ctx 3 2 0 p [] [] base (by rfl)).1

def paused : World := {base with core := base.core.writeSlot resumeSlot (word 43)}
theorem public_paused_rollback : (runPermit permit ctx 3 p empty paused).world = paused :=
  actual_wrapped_physical_steth_transfer_failure_restores permit reject ctx 3 2 0 p [] paused (.reason "ResumedExpected") (by rfl)

/-- Actual WstETH balance/allowance and full-Lido qualified mapping words. Queue
underlying target2 differs from WstETH's slot7-selected target4. -/
def physicalBefore : World :=
  let w := physical 20 2000 0
  let c := w.core.writeContractSlot 2 sharesSlot (word 15)
  let c := c.writeContractSlot 2 bufferedSlot (word 1500)
  let c := c.writeContractSlot 4 AddressStETHTransferCalls.activeSlot (word 256)
  let c := c.writeContractSlot 4 (balanceSlot 3) (word 20)
  let c := c.writeContractSlot 4 (balanceSlot 99) (word 5)
  let c := c.writeContractSlot 3 7 (word (4+2^200))
  let c := c.writeContractSlot 3 2 (word 15)
  let c := c.writeContractSlot 3 (AddressWrappedTokenCalls.balanceSlot 1) (word 15)
  {w with core := c}

def permitAllowance : External := fun req w =>
  if req = ⟨99,3,0,calldata ctx p⟩ then
    .success [] {w with core := w.core.writeContractSlot 3 (AddressWrappedTransferCalls.allowanceSlot 1 99) p.value,logs := w.logs ++ [⟨3,"Permit",[p.value]⟩]}
  else .rejected [0xbb]

def diagnostics : IO Unit := do
  let batch := fun amounts => runBatch (wrappedStep conversion callee reject (quote 2) ctx 3 2) ctx 0 amounts
  let good := runPermit permitAllowance ctx 3 p (batch [word 7,word 8]) physicalBefore
  unless good.outcome == .ok [1,2] && good.attempts.length == 7 &&
      good.world.logs.filterMap (fun e => if e.name == "WithdrawalRequested" then some (e.values.map (·.val)) else none) == [[1,1,1,700,7],[2,1,1,800,8]] &&
      (good.world.core.readContractSlot 4 (balanceSlot 3)).val == 5 &&
      (good.world.core.readContractSlot 4 (balanceSlot 99)).val == 20 &&
      good.world.logs.filterMap (fun e => if e.emitter == 4 then some (e.name,e.values.map (·.val)) else none) ==
        [("Transfer",[3,99,700]),("TransferShares",[3,99,7]),("Transfer",[3,99,800]),("TransferShares",[3,99,8])] do
    throw (IO.userError s!"actual physical transfer/full batch: {repr good.outcome}")
  let lateBefore := {physicalBefore with core := physicalBefore.core.writeContractSlot 4 (balanceSlot 3) (word 10)}
  let late := runPermit permitAllowance ctx 3 p (batch [word 7,word 8]) lateBefore
  unless late.outcome == .error (.bubbled (ReplyABI.reason "BALANCE_EXCEEDED")) && late.world.logs.isEmpty && late.attempts.length == 6 &&
      (late.world.core.readContractSlot 4 (balanceSlot 3)).val == 10 && (late.world.core.readContractSlot 4 (balanceSlot 99)).val == 5 &&
      (late.world.core.readContractSlot 3 2).val == 15 && (late.world.core.readContractSlot 3 (AddressWrappedTransferCalls.allowanceSlot 1 99)).val == 0 do
    throw (IO.userError "late transfer failure must restore permit and all earlier effects")
  let self := run (program ⟨4,3⟩ 3 (word 700)) physicalBefore
  unless self.outcome == .ok () && (self.world.core.readContractSlot 4 (balanceSlot 3)).val == 20 && self.world.logs.length == 2 do
    throw (IO.userError "same mapping slot must read fresh debit")
  let overflowBefore := {physicalBefore with core := physicalBefore.core.writeContractSlot 4 (balanceSlot 99) (word (2^256-1))}
  let overflow := run (program ⟨4,3⟩ 99 (word 700)) overflowBefore
  unless overflow.outcome == .error (.bubbled (ReplyABI.reason "MATH_ADD_OVERFLOW")) && overflow.world.logs.isEmpty &&
      (overflow.world.core.readContractSlot 4 (balanceSlot 3)).val == 20 do
    throw (IO.userError "recipient checked overflow/full callee rollback")
  let wrong := run (program ⟨5,3⟩ 99 (word 700)) physicalBefore
  unless wrong.outcome == .error (.bubbled []) do throw (IO.userError "qualified quote/transfer target")
  let noCodeBefore := {physicalBefore with core := {physicalBefore.core with codeSize := fun a => if a=4 then word 0 else word 1}}
  let missing := runPermit permitAllowance ctx 3 p (batch [word 7]) noCodeBefore
  unless missing.outcome == .error (.bubbled []) && missing.world.logs.isEmpty && missing.attempts.length == 3 do
    throw (IO.userError "selected dynamic target no-code")
  IO.println "PASS 6 native diagnostics: actual full batch and physical share/event amounts; late transfer rollback; alias fresh read; checked recipient overflow; qualified target; dynamic no-code"

#print axioms LidoSRv3.Audit.Source.AddressStETHTransferCalls.balanceSlot_keccak
#print axioms LidoSRv3.Audit.Source.AddressStETHTransferCalls.move_success
#print axioms LidoSRv3.Audit.Source.AddressStETHTransferCalls.program_success
#print axioms LidoSRv3.Audit.Source.AddressStETHTransferCalls.canonical_call
#print axioms LidoSRv3.Audit.Source.AddressStETHTransferCalls.reply_success
#print axioms LidoSRv3.Audit.Source.AddressStETHTransferCalls.reply_not_trace
#print axioms LidoSRv3.Audit.Source.AddressStETHTransferCalls.call_effect
#print axioms LidoSRv3.Audit.Source.AddressStETHTransferCalls.token_effect
#print axioms LidoSRv3.Audit.Source.AddressStETHTransferCalls.item_effect
#print axioms LidoSRv3.Audit.Guarantees.PAddress1.actual_wrapped_physical_steth_transfer_permit_batch
#print axioms LidoSRv3.Audit.Guarantees.PAddress1.actual_wrapped_physical_steth_transfer_failure_restores
#print axioms public_empty_success
#print axioms public_paused_rollback
end LidoSRv3.Tests.AddressStETHTransferCalls
