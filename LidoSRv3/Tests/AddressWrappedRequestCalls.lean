import LidoSRv3.Audit.Guarantees.PAddress1WrappedRequestCalls

namespace LidoSRv3.Tests.AddressWrappedRequestCalls
set_option autoImplicit false
set_option maxRecDepth 16384
open LidoSRv3.Audit.Source.TrioReserve1.Live
open LidoSRv3.Audit.Source.AddressWrappedRequestCalls
open LidoSRv3.Audit.Source.AddressRequestCalls (enqueue resolvedOwner)
open LidoSRv3.Audit.Verity.AddressRecipientCallBridge (StaticExternal stETHTransferFromCalldata stETHSharesCalldata)
open LidoSRv3.Audit.Guarantees.PAddress1

def ctx : Context := ⟨99,1⟩
def before : World := ⟨{Verity.defaultState with codeSize := (fun _ => word 1), blockTimestamp := word 42},fun _ => 100,[]⟩
def marked (w : World) (n : Nat) : World :=
  {w with core := w.core.writeSlot 73 (word n),logs := w.logs ++ [⟨3,"WrappedEffect",[word n]⟩]}
def callee (boolData unwrapData : Bytes) : External := fun req w =>
  if req.payload = stETHTransferFromCalldata ctx.sender ctx.self 7 then .success boolData (marked w 11)
  else if req.payload = unwrapCalldata (word 7) then
    if (w.core.readSlot 73).val = 11 then .success unwrapData (marked w 22)
    else .rejected [0xbb]
  else .rejected [0xcc]
def reject : External := fun _ _ => .rejected [0xee]
def quoteReject : StaticExternal := fun req w =>
  if req.payload = stETHSharesCalldata 123 ∧ (w.core.readSlot 73).val = 22
  then .error (.bubbled [0xaa]) else .error (.bubbled [0xbb])
def quote : StaticExternal := fun req w =>
  if req.payload = stETHSharesCalldata 123 ∧ (w.core.readSlot 73).val = 22
  then .ok (encode 32 (2^128+5)) else .error (.bubbled [0xbb])
def exec (b r : Bytes) (q : StaticExternal := quoteReject) := runRequest (callee b r) q ctx 3 2 (word 7) 0 before

example : unwrapCalldata (word 7) = [0xde,0x0e,0x9a,0x3e] ++ encode 32 7 := by decide +kernel
example : (unwrapStage (fun _ w => .success (encode 32 123 ++ [0xff]) w) ctx 3 (word 7) before).outcome = .ok (word 123) := by decide +kernel
example : (unwrapStage (fun _ w => .success (encode 32 (2^256-1)) w) ctx 3 (word 7) before).outcome = .ok (word (2^256-1)) := by decide +kernel
example : (unwrapStage (fun _ w => .success (List.replicate 31 0) w) ctx 3 (word 7) before).outcome = .error .empty := by decide +kernel
example : (exec (encode 32 2) []).outcome = .error .empty := by decide +kernel
example : (exec (List.replicate 31 0) []).outcome = .error .empty := by decide +kernel
example : (exec (encode 32 0) (List.replicate 31 0)).outcome = .error .empty := by decide +kernel
example : (exec (encode 32 0) (encode 32 99)).outcome = .error (.reason "RequestAmountTooSmall") := by decide +kernel
example : (exec (encode 32 0) (encode 32 (1000*10^18+1))).outcome = .error (.reason "RequestAmountTooLarge") := by decide +kernel
example : (exec (encode 32 0) (encode 32 (2^128+123))).outcome = .error (.reason "RequestAmountTooLarge") := by decide +kernel
example : (exec (encode 32 0 ++ [0xff]) (encode 32 123 ++ [0xff])).outcome = .error (.bubbled [0xaa]) := by decide +kernel
example : (exec (encode 32 0) (encode 32 123)).attempts.map (·.request.target.val) = [3,3,2] := by decide +kernel
example : (exec (encode 32 0) (encode 32 123)).attempts.map (·.request.payload) =
    [stETHTransferFromCalldata 1 99 7,unwrapCalldata (word 7),stETHSharesCalldata 123] := by decide +kernel
example : (exec (encode 32 0) (encode 32 123)).attempts.map (·.accepted) = [true,true,false] := by decide +kernel
example : (request (callee (encode 32 0) (encode 32 123)) quoteReject ctx 3 2 (word 7) 0 before).world.logs.length = 2 := by decide +kernel
example : (exec (encode 32 0) (encode 32 123)).world.logs = [] := by decide +kernel
example : (runRequest reject quoteReject ctx 3 2 (word 0) 0 before).outcome = .error (.bubbled [0xee]) := by decide +kernel
example : (unwrapStage reject ctx 3 (word 7) {before with core := {before.core with codeSize := fun _ => word 0}}).outcome = .error .empty := by decide +kernel

theorem public_rollback : (exec (encode 32 0) (encode 32 123)).world = before := by
  apply actual_wrapped_request_withdrawal_failure_restores (callee (encode 32 0) (encode 32 123)) quoteReject ctx 3 2 (word 7) 0 before (.bubbled [0xaa])
  decide +kernel

/-- Native executable diagnostics of the complete physical enqueue. These IO
checks are not theorem declarations and add no axioms to the public consumer. -/
def diagnostics : IO Unit := do
  let result := exec (encode 32 0) (encode 32 123 ++ [0xab]) quote
  unless result.outcome == .ok 1 && result.attempts.map (·.request.target.val) == [3,3,2] &&
      result.world.logs.map (·.name) == ["WrappedEffect","WrappedEffect","WithdrawalRequested","Transfer"] do
    throw (IO.userError "complete wrapped request chain failed")
  unless ((result.world.logs.drop 2).head?.map (fun e => e.values.map (·.val))) == some [1,1,1,123,5] do
    throw (IO.userError "unwrap/quote amounts were not consumed by event")
  let changedTimestamp : External := fun req w =>
    match callee (encode 32 0) (encode 32 123) req w with
    | .success bytes after => .success bytes {after with core := {after.core with blockTimestamp := word 999}}
    | other => other
  let timed := runRequest changedTimestamp quote ctx 3 2 (word 7) 0 before
  unless timed.outcome == .ok 1 &&
      (LidoSRv3.Audit.Verity.AddressClaimBatchTx.requestMetadataWord timed.world.core 1).val / 2^160 % 2^40 == 42 do
    throw (IO.userError "entry TIMESTAMP was not captured")
  let zeroCallee : External := fun req w =>
    if req.payload = stETHTransferFromCalldata 1 99 0 then .success (encode 32 0) (marked w 11)
    else if req.payload = unwrapCalldata (word 0) then .success (encode 32 123) (marked w 22)
    else .rejected []
  unless (runRequest zeroCallee quote ctx 3 2 (word 0) 0 before).outcome == .ok 1 do
    throw (IO.userError "caller invented zero wrapped amount guard")
  let duplicate := {before with core := (before.core.writeSlot
    (LidoSRv3.Audit.Verity.AddressClaimBatchTx.ownerRequestIndexSlot 1 1) (word 9))}
  let late := runRequest (callee (encode 32 0) (encode 32 123)) quote ctx 3 2 (word 7) 0 duplicate
  unless late.outcome == .error (.reason "Panic(0x01)") && late.world.logs.isEmpty &&
      late.attempts.map (·.accepted) == [true,true,true] &&
      late.world.core.readSlot 73 == duplicate.core.readSlot 73 do
    throw (IO.userError "late enqueue failure did not restore entry world")
  IO.println "PASS 4 complete native diagnostics: successful chain, captured TIMESTAMP, zero wrapped caller boundary, late physical enqueue rollback"

#print axioms LidoSRv3.Audit.Source.AddressWrappedRequestCalls.unwrap_success
#print axioms LidoSRv3.Audit.Source.AddressWrappedRequestCalls.request_success
#print axioms actual_wrapped_request_withdrawal_enqueue
#print axioms actual_wrapped_request_withdrawal_failure_restores
#print axioms public_rollback
end LidoSRv3.Tests.AddressWrappedRequestCalls
