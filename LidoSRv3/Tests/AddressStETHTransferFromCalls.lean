import LidoSRv3.Audit.Guarantees.PAddress1StETHTransferFromCalls
namespace LidoSRv3.Tests.AddressStETHTransferFromCalls
open LidoSRv3.Audit.Source
open TrioReserve1 Live AddressStETHTransferFromCalls
open AddressStETHQuoteCalls (sharesSlot bufferedSlot clSlot quote)
open AddressRequestBatches AddressPermitRequestCalls
open LidoSRv3.Audit.Guarantees.PAddress1
open LidoSRv3.Audit.Verity.AddressRecipientCallBridge (stETHTransferFromCalldata)
set_option maxRecDepth 16384
set_option maxHeartbeats 2000000

def ctx : Context := ⟨99,1⟩
def p : PermitInput := ⟨word 1500,word 500,27,word 8,word 9⟩
def base : World := ⟨{Verity.defaultState with codeSize := fun _ => word 1,blockTimestamp := word 42},fun _ => 100,[]⟩
def constantStorage (v : Word) : World := {base with core := {base.core with storageWords := fun _ => v}}
example : (stETHTransferFromCalldata 1 99 700).length = 100 := by decide +kernel
example : (stETHTransferFromCalldata 1 99 700).take 4 = [0x23,0xb8,0x72,0xdd] := by decide +kernel
example : (stETHTransferFromCalldata 1 99 700).drop 4 = encode 32 1 ++ encode 32 99 ++ encode 32 700 := by decide +kernel
example : (program ⟨4,0⟩ 0 0 (word (2^128-1)) base).outcome = .error (.bubbled (ReplyABI.reason "ALLOWANCE_EXCEEDED")) := by decide +kernel
example : (spend ⟨4,0⟩ 0 (word 1) (constantStorage (word 1))).outcome = .error (.bubbled (ReplyABI.reason "APPROVE_FROM_ZERO_ADDR")) := by decide +kernel
example : (spend ⟨4,0⟩ 1 (word 1) (constantStorage (word 1))).outcome = .error (.bubbled (ReplyABI.reason "APPROVE_TO_ZERO_ADDR")) := by decide +kernel
example : (spend ⟨4,0⟩ 0 (word 0) base).outcome = .error (.bubbled (ReplyABI.reason "APPROVE_FROM_ZERO_ADDR")) := by decide +kernel
example : (spend ⟨4,0⟩ 0 (word (2^256-1)) (constantStorage (word (2^256-1)))).outcome = .ok () := by decide +kernel
example : (spend ⟨4,0⟩ 0 (word 0) (constantStorage (word (2^256-1)))).world.logs = [] := by decide +kernel
example : (spend ⟨4,99⟩ 1 (word 0) base).world.logs = [approval ⟨4,99⟩ 1 (word 0)] := by rfl
example : (spend ⟨4,99⟩ 1 (word (2^256-1)) (constantStorage (word (2^256-2)))).outcome = .error (.bubbled (ReplyABI.reason "ALLOWANCE_EXCEEDED")) := by decide +kernel
example : (program ⟨4,0⟩ 0 0 (word (2^128-1)) (constantStorage (word (2^256-1)))).outcome = .error (.bubbled (ReplyABI.reason "ETH_TOO_LARGE")) := by decide +kernel
example : callee ⟨99,4,1,stETHTransferFromCalldata 1 99 700⟩ base = .rejected [] := by rfl
example : callee ⟨99,4,0,encode 4 0x23b872dd ++ List.replicate 95 0⟩ base = .rejected [] := by rfl
example : callee ⟨99,4,0,stETHTransferFromCalldata 0 99 0 ++ [9,8]⟩ base = .rejected (ReplyABI.reason "APPROVE_FROM_ZERO_ADDR") := by rfl

def permit : External := fun _ w => .success [] {w with logs := w.logs ++ [⟨4,"Permit",[]⟩]}
def batch (amounts : List Word) := runBatch (stETHStep callee (quote 4) ctx 4) ctx 0 amounts

theorem public_empty_success : DirectQuotePermitEffect permit ctx 4 0 p [] [] base
    (runPermit permit ctx 4 p (batch []) base).world (runPermit permit ctx 4 p (batch []) base).attempts :=
  (actual_steth_transfer_from_quote_permit_batch permit ctx 4 0 p [] [] base (by rfl)).1

theorem public_nonempty_allowance_rollback : (runPermit permit ctx 4 p (batch [word 700]) base).world = base :=
  actual_steth_transfer_from_quote_permit_failure_restores permit ctx 4 0 p [word 700] base
    (.bubbled (ReplyABI.reason "ALLOWANCE_EXCEEDED")) (by rfl)

def physicalBefore : World :=
  let c := base.core.writeContractSlot 4 sharesSlot (word 20)
  let c := c.writeContractSlot 4 bufferedSlot (word 2000)
  let c := c.writeContractSlot 4 AddressStETHTransferCalls.activeSlot (word 256)
  let c := c.writeContractSlot 4 (AddressStETHTransferCalls.balanceSlot 1) (word 20)
  let c := c.writeContractSlot 4 (AddressStETHTransferCalls.balanceSlot 99) (word 5)
  {base with core := c}
def permitAmount (amount : Word) : External := fun req w =>
  if req = ⟨99,4,0,calldata ctx p⟩ then
    .success [] {w with core := w.core.writeContractSlot 4 (allowanceSlot 1 99) amount,logs := w.logs ++ [⟨4,"Permit",[amount]⟩]}
  else .rejected [0xbb]
def funded (amount : Word) : World := {physicalBefore with core := physicalBefore.core.writeContractSlot 4 (allowanceSlot 1 99) amount}
def bal (w : World) (a : Address) := (w.core.readContractSlot 4 (AddressStETHTransferCalls.balanceSlot a)).val
def allow (w : World) (owner spender : Address) := (w.core.readContractSlot 4 (allowanceSlot owner spender)).val

def diagnostics : IO Unit := do
  let good := runPermit (permitAmount (word 1500)) ctx 4 p (batch [word 700,word 800]) physicalBefore
  unless good.outcome == .ok [1,2] && good.attempts.length == 5 && bal good.world 1 == 5 && bal good.world 99 == 20 && allow good.world 1 99 == 0 &&
      good.world.logs.filterMap (fun e => if e.name == "WithdrawalRequested" then some (e.values.map (·.val)) else none) == [[1,1,1,700,7],[2,1,1,800,8]] &&
      good.world.logs.filterMap (fun e => if e.emitter == 4 then some (e.name,e.values.map (·.val)) else none) ==
        [("Permit",[1500]),("Approval",[1,99,800]),("Transfer",[1,99,700]),("TransferShares",[1,99,7]),("Approval",[1,99,0]),("Transfer",[1,99,800]),("TransferShares",[1,99,8])] do
    throw (IO.userError s!"same-world permit/two-items: {repr good.outcome}")
  let direct := batch [word 700,word 800] (funded (word 1500))
  unless direct.outcome == .ok [1,2] && direct.attempts.length == 4 && bal direct.world 1 == 5 do throw (IO.userError "direct public batch")
  let late := runPermit (permitAmount (word 1400)) ctx 4 p (batch [word 700,word 800]) physicalBefore
  unless late.outcome == .error (.bubbled (ReplyABI.reason "ALLOWANCE_EXCEEDED")) && late.world.logs.isEmpty && late.attempts.length == 4 && bal late.world 1 == 20 && bal late.world 99 == 5 && allow late.world 1 99 == 0 do throw (IO.userError "prepermit rollback second-item allowance")
  let self := run (program ⟨4,99⟩ 1 1 (word 700)) (funded (word 1500))
  unless self.outcome == .ok () && bal self.world 1 == 20 && allow self.world 1 99 == 800 && self.world.logs.length == 3 do throw (IO.userError "same owner/recipient fresh read")
  let infinite := run (program ⟨4,99⟩ 1 99 (word 700)) (funded (word (2^256-1)))
  unless infinite.outcome == .ok () && allow infinite.world 1 99 == 2^256-1 && infinite.world.logs.length == 2 do throw (IO.userError "real infinity skips approve")
  let overBefore := {funded (word 1500) with core := (funded (word 1500)).core.writeContractSlot 4 (AddressStETHTransferCalls.balanceSlot 99) (word (2^256-1))}
  let overflow := run (program ⟨4,99⟩ 1 99 (word 700)) overBefore
  unless overflow.outcome == .error (.bubbled (ReplyABI.reason "MATH_ADD_OVERFLOW")) && allow overflow.world 1 99 == 1500 && bal overflow.world 1 == 20 && overflow.world.logs.isEmpty do throw (IO.userError "late credit overflow restores allowance+debit")
  let zeroSpender := {physicalBefore with core := physicalBefore.core.writeContractSlot 4 (allowanceSlot 1 0) (word (2^256-1))}
  let z := run (program ⟨4,0⟩ 1 99 (word 700)) zeroSpender
  unless z.outcome == .ok () && z.world.logs.length == 2 do throw (IO.userError "infinity bypasses spender zero approve guard")
  let different := run (program ⟨5,99⟩ 1 99 (word 700)) (funded (word 1500))
  unless different.outcome == .error (.bubbled (ReplyABI.reason "ALLOWANCE_EXCEEDED")) do throw (IO.userError "qualified storage target")
  IO.println "PASS 8 native groups: complete permit batch; direct batch; late allowance rollback; alias; infinity; overflow rollback; zero spender infinity; qualified target"

#print axioms LidoSRv3.Audit.Source.AddressStETHTransferFromCalls.allowanceSlot_keccak
#print axioms LidoSRv3.Audit.Source.AddressStETHTransferFromCalls.spend_success
#print axioms LidoSRv3.Audit.Source.AddressStETHTransferFromCalls.program_success
#print axioms LidoSRv3.Audit.Source.AddressStETHTransferFromCalls.canonical_call
#print axioms LidoSRv3.Audit.Source.AddressStETHTransferFromCalls.reply_success
#print axioms LidoSRv3.Audit.Source.AddressStETHTransferFromCalls.reply_not_trace
#print axioms LidoSRv3.Audit.Source.AddressStETHTransferFromCalls.transfer_effect
#print axioms LidoSRv3.Audit.Source.AddressStETHTransferFromCalls.item_effect
#print axioms LidoSRv3.Audit.Guarantees.PAddress1.actual_steth_transfer_from_quote_permit_batch
#print axioms LidoSRv3.Audit.Guarantees.PAddress1.actual_steth_transfer_from_quote_batch
#print axioms LidoSRv3.Audit.Guarantees.PAddress1.actual_steth_transfer_from_quote_permit_failure_restores
#print axioms LidoSRv3.Audit.Guarantees.PAddress1.actual_steth_transfer_from_quote_failure_restores
#print axioms public_empty_success
#print axioms public_nonempty_allowance_rollback
end LidoSRv3.Tests.AddressStETHTransferFromCalls
