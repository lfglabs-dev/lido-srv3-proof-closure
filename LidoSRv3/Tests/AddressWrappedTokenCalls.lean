import LidoSRv3.Audit.Guarantees.PAddress1WrappedTokenCalls
namespace LidoSRv3.Tests.AddressWrappedTokenCalls
set_option autoImplicit false
set_option maxRecDepth 16384
open LidoSRv3.Audit.Source.TrioReserve1
open Live
open LidoSRv3.Audit.Source.AddressWrappedTokenCalls
open LidoSRv3.Audit.Verity.AddressRecipientCallBridge (StaticExternal pooledEthBySharesCalldata erc20TransferCalldata)
open LidoSRv3.Audit.Guarantees.PAddress1

def kernelWorld : World := ⟨{Verity.defaultState with codeSize := (fun _ => word 1), storageWords := (fun _ => word 2)},fun _ => 100,[]⟩
def reject : External := fun _ _ => .rejected [0xee]
def staticReply (data : Bytes) : StaticExternal := fun _ _ => .ok data
def reply (data : Bytes) : External := fun _ w => .success data w

example : stETHSlot = 7 ∧ supplySlot = 2 := by decide +kernel
example : stETHAddress 3 kernelWorld = 2 := by decide +kernel
example : stETHAddress 3 {kernelWorld with core := {kernelWorld.core with storageWords := fun _ => word (2^200+2)}} = 2 := by decide +kernel
example : (staticWord (staticReply (encode 32 123 ++ [0xff])) ⟨3,99⟩ 2 (pooledEthBySharesCalldata 7) kernelWorld).outcome = .ok (word 123) := by decide +kernel
example : (wordCall (reply (encode 32 2)) ⟨3,99⟩ 2 (erc20TransferCalldata 99 123) kernelWorld).outcome = .ok (word 2) := by decide +kernel
example : (wordCall (reply (encode 32 0 ++ [0xab])) ⟨3,99⟩ 2 [] kernelWorld).outcome = .ok (word 0) := by decide +kernel
example : (wordCall (reply (List.replicate 31 0)) ⟨3,99⟩ 2 [] kernelWorld).outcome = .error .empty := by decide +kernel
example : (wordCall reject ⟨3,99⟩ 2 [] kernelWorld).outcome = .error (.bubbled [0xee]) := by decide +kernel
example : (burn ⟨3,0⟩ (word 7) kernelWorld).outcome = .error (.reason "ERC20: burn from the zero address") := by decide +kernel
example : (burn ⟨3,99⟩ (word 7) kernelWorld).outcome = .error (.reason "ERC20: burn amount exceeds balance") := by decide +kernel
example : (tokenProgram (staticReply []) reject ⟨3,99⟩ (word 0) kernelWorld).outcome = .error (.reason "wstETH: zero amount unwrap not allowed") := by decide +kernel
example : (tokenProgram (staticReply []) reject ⟨3,99⟩ (word 7) kernelWorld).outcome = .error .empty := by decide +kernel
example : (tokenProgram (staticReply (encode 32 123)) reject ⟨3,0⟩ (word 7) kernelWorld).outcome = .error (.reason "ERC20: burn from the zero address") := by decide +kernel
example : (calleeFor 3 (staticReply []) reject reject ⟨99,3,1,[0xde,0x0e,0x9a,0x3e]⟩ kernelWorld) = .rejected [] := by rfl
example : (calleeFor 3 (staticReply []) reject reject ⟨99,3,0,[0xde,0x0e,0x9a,0x3e]⟩ kernelWorld) = .rejected [] := by rfl
example : (calleeFor 3 (staticReply []) reject reject ⟨99,2,0,[0xde,0x0e,0x9a,0x3e]⟩ kernelWorld) = .rejected [0xee] := by rfl
example : (runRequest (staticReply []) reject (reply (encode 32 2)) (staticReply []) ⟨99,1⟩ 3 2 (word 7) 0 kernelWorld).outcome = .error .empty := by decide +kernel

theorem public_zero_rollback :
    (runRequest (staticReply []) reject (reply (encode 32 1)) (staticReply []) ⟨99,1⟩ 3 2 (word 0) 0 kernelWorld).world = kernelWorld := by
  apply actual_wrapped_token_request_failure_restores _ _ _ _ _ _ _ _ _ _
    (.bubbled (ReplyABI.reason "wstETH: zero amount unwrap not allowed"))
  rfl

/-- Full native fixtures with real Keccak slot calculations; no kernel-positive
or EVM theorem is inferred from these executable diagnostic checks. -/
def before : World :=
  let core := {Verity.defaultState with codeSize := (fun _ => word 1), blockTimestamp := word 42}
  let core := ((core.writeContractSlot 3 stETHSlot (word 2)).writeContractSlot 3 supplySlot (word 7)).writeContractSlot 3 (balanceSlot 99) (word 7)
  let core := (core.writeSlot supplySlot (word 999)).writeSlot (balanceSlot 99) (word 888)
  ⟨core,fun _ => 100,[]⟩
def otherCalls : External := fun _ w => .success (encode 32 1) {w with logs := w.logs ++ [⟨3,"TransferFromEffect",[]⟩]}
def conversion (value : Nat := 123) : StaticExternal := fun req w =>
  if req.caller = 3 ∧ req.target = 2 ∧ req.payload = pooledEthBySharesCalldata 7 ∧
      (w.core.readContractSlot 3 (balanceSlot 99)).val = 7 then .ok (encode 32 value ++ [0xff]) else .error (.bubbled [0x11])
def tokenTransfer (size : Nat := 32) (callback : Bool := false) : External := fun req w =>
  if req.caller = 3 ∧ req.target = 2 ∧ req.payload = erc20TransferCalldata 99 123 ∧
      (w.core.readContractSlot 3 (balanceSlot 99)).val = 0 ∧ (w.core.readContractSlot 3 supplySlot).val = 0 then
    let core := if callback then w.core.writeContractSlot 3 supplySlot (word 5) else w.core
    .success ((encode 32 2).take size) {w with core := core, logs := w.logs ++ [⟨2,"TokenTransferEffect",[]⟩]}
  else .rejected [0x22]
def queueQuote : StaticExternal := fun req _ =>
  if req.caller = 99 ∧ req.target = 2 ∧ req.payload = LidoSRv3.Audit.Verity.AddressRecipientCallBridge.stETHSharesCalldata 123
  then .ok (encode 32 (2^128+5)) else .error (.bubbled [0x33])
def result := runRequest (conversion 123) (tokenTransfer 32 false) otherCalls queueQuote ⟨99,1⟩ 3 2 (word 7) 0 before

def diagnostics : IO Unit := do
  unless balanceSlot 99 == 0x01c4951e729acbc05299798279cd10e5be143681a3d883a027edec470c12b1a9 do
    throw (IO.userError "independent balance mapping preimage mismatch")
  let r := result
  unless r.outcome == .ok 1 && r.world.logs.map (·.name) == ["TransferFromEffect","Transfer","TokenTransferEffect","WithdrawalRequested","Transfer"] &&
      r.attempts.map (·.request.target.val) == [3,3,2] do
    throw (IO.userError "actual token and caller enqueue chain failed")
  unless ((r.attempts.drop 1).head?.map (fun a => a.nested.map (·.isStatic))) == some [true,false] &&
      ((r.world.logs.drop 3).head?.map (fun e => e.values.map (·.val))) == some [1,1,1,123,5] do
    throw (IO.userError "nested call flags or returned amounts not consumed")
  unless (r.world.core.readSlot supplySlot).val == 999 && (r.world.core.readSlot (balanceSlot 99)).val == 888 do
    throw (IO.userError "token burn touched queue root-lens decoys")
  let cb := runRequest (conversion 123) (tokenTransfer 32 true) otherCalls queueQuote ⟨99,1⟩ 3 2 (word 7) 0 before
  unless cb.outcome == .ok 1 && (cb.world.core.readContractSlot 3 supplySlot).val == 5 do
    throw (IO.userError "arbitrary returned-world callback was erased")
  let short := runRequest (conversion 123) (tokenTransfer 31 false) otherCalls queueQuote ⟨99,1⟩ 3 2 (word 7) 0 before
  unless short.outcome == .error (.bubbled []) && short.world.logs.isEmpty &&
      (short.world.core.readContractSlot 3 (balanceSlot 99)).val == 7 &&
      ((short.attempts.drop 1).head?.map (fun a => (a.accepted,a.nested.map (·.accepted)))) == some (false,[true,true]) do
    throw (IO.userError "short transfer reply failed burn/caller rollback")
  let badSupply := {before with core := before.core.writeContractSlot 3 supplySlot (word 6)}
  let raw := tokenProgram (conversion 123) (tokenTransfer 32 false) ⟨3,99⟩ (word 7) badSupply
  unless raw.outcome == .error (.reason "SafeMath: subtraction overflow") &&
      (raw.world.core.readContractSlot 3 (balanceSlot 99)).val == 0 && raw.world.logs.isEmpty do
    throw (IO.userError "supply checked before balance write or burn emitted too soon")
  let late := runRequest (conversion 99) (reply (encode 32 2)) otherCalls queueQuote ⟨99,1⟩ 3 2 (word 7) 0 before
  unless late.outcome == .error (.reason "RequestAmountTooSmall") && late.world.logs.isEmpty &&
      (late.world.core.readContractSlot 3 (balanceSlot 99)).val == 7 do
    throw (IO.userError "late caller amount rejection did not roll back token")
  IO.println "PASS 7 native checks: independent mapping preimage, complete chain/nested return, qualified decoys, callback world, short transfer rollback, source-order supply failure, late caller rollback"

#print axioms LidoSRv3.Audit.Source.AddressWrappedTokenCalls.burn_success
#print axioms LidoSRv3.Audit.Source.AddressWrappedTokenCalls.token_success
#print axioms LidoSRv3.Audit.Source.AddressWrappedTokenCalls.canonical_call
#print axioms LidoSRv3.Audit.Source.AddressWrappedTokenCalls.joined_success
#print axioms actual_wrapped_token_request_enqueue
#print axioms actual_wrapped_token_request_failure_restores
#print axioms public_zero_rollback
end LidoSRv3.Tests.AddressWrappedTokenCalls
