import LidoSRv3.Audit.Guarantees.PAddress1PermitRequestCalls
namespace LidoSRv3.Tests.AddressPermitRequestCalls
open LidoSRv3.Audit.Source.TrioReserve1.Live
open LidoSRv3.Audit.Source.AddressRequestBatches
open LidoSRv3.Audit.Source.AddressPermitRequestCalls
open LidoSRv3.Audit.Guarantees.PAddress1
open LidoSRv3.Audit.Verity.AddressRecipientCallBridge (StaticExternal)
def p : PermitInput := ⟨word 15,word 500,255,word 8,word 9⟩
def ctx : Context := ⟨99,1⟩
def before : World := ⟨{Verity.defaultState with codeSize := fun _ => word 1, blockTimestamp := word 42},fun _ => 100,[]⟩
def paused : World := {before with core := before.core.writeSlot resumeSlot (word 43)}
def reject : External := fun _ _ => .rejected [0xaa]
def quote : StaticExternal := fun _ _ => .ok (encode 32 1)
def emptyBatch := runBatch (stETHStep reject quote ctx 2) ctx 0 []
def writePermit (data : Bytes) : External := fun _ w =>
  .success data {w with core := w.core.writeSlot 123 (word 15), logs := w.logs ++ [⟨2,"PermitWrite",[]⟩]}
example : (calldata ctx p).length = 228 := by decide +kernel
example : (calldata ctx p).take 4 = [0xd5,0x05,0xac,0xcf] := by decide +kernel
example : decode (((calldata ctx p).drop 4).take 32) = 1 := by decide +kernel
example : decode (((calldata ctx p).drop 36).take 32) = 99 := by decide +kernel
example : decode (((calldata ctx p).drop 68).take 32) = 15 := by decide +kernel
example : decode (((calldata ctx p).drop 100).take 32) = 500 := by decide +kernel
example : decode (((calldata ctx p).drop 132).take 32) = 255 := by decide +kernel
example : decode (((calldata ctx p).drop 164).take 32) = 8 := by decide +kernel
example : decode (((calldata ctx p).drop 196).take 32) = 9 := by decide +kernel
example : (runPermit reject ctx 2 p emptyBatch paused).outcome = .error (.bubbled [0xaa]) := by decide +kernel
example : (runPermit (writePermit [2]) ctx 2 p emptyBatch paused).outcome = .error (.reason "ResumedExpected") := by decide +kernel
example : (runPermit (writePermit [2]) ctx 2 p emptyBatch paused).world.core.readSlot 123 = word 0 := by decide +kernel
example : (runPermit (writePermit []) ctx 2 p emptyBatch before).outcome = .ok [] := by decide +kernel
example : (runPermit (writePermit [2]) ctx 2 p emptyBatch before).outcome = .ok [] := by decide +kernel
example : (runPermit (writePermit [0xff,0x80]) ctx 2 p emptyBatch before).world.logs.length = 1 := by decide +kernel
example : (runPermit reject ctx 2 p emptyBatch {paused with core := {paused.core with codeSize := fun _ => word 0}}).outcome = .error .empty := by decide +kernel
example : (runPermit reject ctx 2 p emptyBatch {paused with core := {paused.core with codeSize := fun _ => word 0}}).attempts = [] := by decide +kernel

-- Batch pause admission observes the actual permit-returned storage world.
def setPausePermit (resumeAt : Word) : External := fun _ w =>
  .success [] {w with core := w.core.writeSlot resumeSlot resumeAt}
example : (runPermit (setPausePermit (word 0)) ctx 2 p emptyBatch paused).outcome = .ok [] := by decide +kernel
example : (runPermit (setPausePermit (word 43)) ctx 2 p emptyBatch before).outcome = .error (.reason "ResumedExpected") := by decide +kernel

theorem public_empty_success :
    JoinedEffect (writePermit [2]) ctx 2 p (StETHEffect reject quote ctx 2 0 []) [] before
      (runPermit (writePermit [2]) ctx 2 p emptyBatch before).world
      (runPermit (writePermit [2]) ctx 2 p emptyBatch before).attempts :=
  actual_steth_permit_batch (writePermit [2]) reject quote ctx 2 0 p [] [] before (by rfl)

theorem public_paused_rollback : (runPermit (writePermit [2]) ctx 2 p emptyBatch paused).world = paused := by
  exact actual_steth_permit_failure_restores (writePermit [2]) reject quote ctx 2 0 p [] paused (.reason "ResumedExpected") (by rfl)

-- Actual qualified allowance consumption is a native diagnostic, not a kernel instance.
def physicalBefore : World :=
  let core := before.core.writeContractSlot 3 7 (word 2)
  let core := core.writeContractSlot 3 2 (word 15)
  let core := core.writeContractSlot 3 (LidoSRv3.Audit.Source.AddressWrappedTokenCalls.balanceSlot 1) (word 15)
  ⟨core,fun _ => 100,[]⟩
def permitAllowance : External := fun req w =>
  if req = ⟨99,3,0,calldata ctx p⟩ then
    let core := w.core.writeContractSlot 3 (LidoSRv3.Audit.Source.AddressWrappedTransferCalls.allowanceSlot 1 99) p.value
    .successWithTrace [0xfe] {w with core := core, logs := w.logs ++ [⟨3,"Permit",[p.value]⟩]} []
  else .rejected [0xbb]
def conversion : StaticExternal := fun req _ => .ok (encode 32 (decode (req.payload.drop 4)*100))
def shares : StaticExternal := fun req _ => .ok (encode 32 (decode (req.payload.drop 4)+1))
def transfer : External := fun _ w => .success (encode 32 2) w

def diagnostics : IO Unit := do
  let batch := fun amounts => runBatch (wrappedStep conversion transfer reject shares ctx 3 2) ctx 0 amounts
  let result := runPermit permitAllowance ctx 3 p (batch [word 7,word 8]) physicalBefore
  unless result.outcome == .ok [1,2] && result.attempts.length == 7 && result.world.logs.head?.map (·.name) == some "Permit" &&
      (result.world.core.readContractSlot 3 (LidoSRv3.Audit.Source.AddressWrappedTransferCalls.allowanceSlot 1 99)).val == 0 do
    throw (IO.userError "permit request/world allowance not consumed by actual wrapped batch")
  let noPermit := batch [word 7] physicalBefore
  unless noPermit.outcome == .error (.bubbled (LidoSRv3.Audit.Source.TrioReserve1.ReplyABI.reason "ERC20: transfer amount exceeds allowance")) do
    throw (IO.userError "baseline unexpectedly had allowance")
  let late := runPermit permitAllowance ctx 3 p (batch [word 7,word 9]) physicalBefore
  unless late.outcome == .error (.bubbled (LidoSRv3.Audit.Source.TrioReserve1.ReplyABI.reason "ERC20: transfer amount exceeds balance")) && late.attempts.length == 5 &&
      late.world.logs.isEmpty && (late.world.core.readContractSlot 3 2).val == 15 &&
      (late.world.core.readContractSlot 3 (LidoSRv3.Audit.Source.AddressWrappedTransferCalls.allowanceSlot 1 99)).val == 0 do
    throw (IO.userError "late item failed to restore pre-permit world/journal")
  let pw := {physicalBefore with core := physicalBefore.core.writeSlot resumeSlot (word 43)}
  let pausedResult := runPermit permitAllowance ctx 3 p (batch []) pw
  unless pausedResult.outcome == .error (.reason "ResumedExpected") && pausedResult.attempts.length == 1 && pausedResult.world.logs.isEmpty &&
      (pausedResult.world.core.readContractSlot 3 (LidoSRv3.Audit.Source.AddressWrappedTransferCalls.allowanceSlot 1 99)).val == 0 do
    throw (IO.userError "paused empty batch failed pre-permit rollback")
  IO.println "PASS 4 native checks: consumed permit allowance, no-permit failure, late-item pre-permit rollback, paused-empty permit rollback"

#print axioms LidoSRv3.Audit.Source.AddressPermitRequestCalls.calldata_length
#print axioms LidoSRv3.Audit.Source.AddressPermitRequestCalls.call_success
#print axioms LidoSRv3.Audit.Source.AddressPermitRequestCalls.joined_success
#print axioms LidoSRv3.Audit.Guarantees.PAddress1.actual_steth_permit_batch
#print axioms LidoSRv3.Audit.Guarantees.PAddress1.actual_wrapped_permit_batch
#print axioms LidoSRv3.Audit.Guarantees.PAddress1.actual_steth_permit_failure_restores
#print axioms LidoSRv3.Audit.Guarantees.PAddress1.actual_wrapped_permit_failure_restores
#print axioms LidoSRv3.Tests.AddressPermitRequestCalls.public_empty_success
#print axioms LidoSRv3.Tests.AddressPermitRequestCalls.public_paused_rollback
end LidoSRv3.Tests.AddressPermitRequestCalls
