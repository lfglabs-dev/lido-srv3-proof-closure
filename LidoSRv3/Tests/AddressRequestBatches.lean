import LidoSRv3.Audit.Guarantees.PAddress1RequestBatches
namespace LidoSRv3.Tests.AddressRequestBatches
open LidoSRv3.Audit.Source.TrioReserve1.Live
open LidoSRv3.Audit.Source.AddressRequestBatches
open LidoSRv3.Audit.Guarantees.PAddress1
open LidoSRv3.Audit.Verity.AddressRecipientCallBridge (StaticExternal)

def before : World := ⟨{Verity.defaultState with blockTimestamp := word 42},fun _ => 100,[]⟩
def paused : World := {before with core := before.core.writeSlot resumeSlot (word 43)}
def reject : External := fun _ _ => .rejected [0xee]
def quote : StaticExternal := fun _ _ => .ok (encode 32 1)

-- Kernel tests that never need a positive Keccak computation.
example : resumeSlot = 0xe8b012900cb200ee5dfc3b895a32791b67d12891b09f117814f167a237783a02 := rfl
example : (runBatch (stETHStep reject quote ⟨99,1⟩ 2) ⟨99,1⟩ 0 [] paused).outcome =
    .error (.reason "ResumedExpected") := by decide +kernel
example : (runBatch (stETHStep reject quote ⟨99,1⟩ 2) ⟨99,1⟩ 0 [word 0] paused).outcome =
    .error (.reason "ResumedExpected") := by decide +kernel
example : (runBatch (stETHStep reject quote ⟨99,1⟩ 2) ⟨99,1⟩ 0 [] before).outcome = .ok [] := by decide +kernel
example : (runBatch (stETHStep reject quote ⟨99,1⟩ 2) ⟨99,1⟩ 0 [word 99] before).outcome =
    .error (.reason "RequestAmountTooSmall") := by decide +kernel
example : (runBatch (stETHStep reject quote ⟨99,1⟩ 2) ⟨99,1⟩ 0 [word 99] before).attempts = [] := by decide +kernel
example : (runBatch (wrappedStep quote reject reject quote ⟨99,1⟩ 3 2) ⟨99,1⟩ 0 [] paused).outcome =
    .error (.reason "ResumedExpected") := by decide +kernel

def atResume : World := {before with core := before.core.writeSlot resumeSlot (word 42)}
example : (runBatch (stETHStep reject quote ⟨99,1⟩ 2) ⟨99,1⟩ 0 [] atResume).outcome = .ok [] := by decide +kernel

-- Generic loop diagnostics are labelled separately from actual item proofs.
-- First item pauses the world. Second still runs, because pause is entry-only.
def mark (owner : Address) (amount : Word) : Exec Nat := fun w =>
  if amount.val = 9 then ⟨.error (.bubbled [0x09]),w,[]⟩ else
  ⟨.ok amount.val, {w with core := w.core.writeSlot resumeSlot (word 100), logs := w.logs ++ [⟨99,"Item",[word owner.val,amount]⟩]}, []⟩
example : (runBatch mark ⟨99,1⟩ 0 [word 1,word 2] before).outcome = .ok [1,2] := by decide +kernel
example : (runBatch mark ⟨99,1⟩ 0 [word 1,word 2] before).world.logs.map (·.values) =
    [[word 1,word 1],[word 1,word 2]] := by decide +kernel
example : (runBatch mark ⟨99,1⟩ 8 [word 1,word 2] before).world.logs.map (·.values) =
    [[word 8,word 1],[word 8,word 2]] := by decide +kernel
example : (entry mark ⟨99,1⟩ 0 [word 1,word 9] before).world.logs.length = 1 := by decide +kernel
example : (runBatch mark ⟨99,1⟩ 0 [word 1,word 9] before).world.logs = [] := by decide +kernel
example : (runBatch mark ⟨99,1⟩ 0 [word 1,word 9] before).world.core.readSlot resumeSlot = word 0 := by decide +kernel

theorem public_empty_steth :
    Resumed before ∧ Transcript (stETHEffect reject quote ⟨99,1⟩ 2 1) [] [] before before [] ∧
      ([] : List Nat).length = ([] : List Word).length := by
  exact actual_steth_request_batch reject quote ⟨99,1⟩ 2 0 [] [] before (by rfl)

theorem public_paused_wrapped_rollback :
    (runBatch (wrappedStep quote reject reject quote ⟨99,1⟩ 3 2) ⟨99,1⟩ 0 [word 7] paused).world = paused := by
  apply actual_wrapped_batch_failure_restores _ _ _ _ _ _ _ _ _ _ (.reason "ResumedExpected")
  rfl

-- Positive physical executions below require the existing native Keccak support;
-- they are diagnostics, never kernel/native_decide proof claims.
def physicalBefore : World :=
  let core := {Verity.defaultState with blockTimestamp := word 42, codeSize := fun _ => word 1}
  let core := core.writeContractSlot 3 7 (word 2)
  let core := core.writeContractSlot 3 2 (word 15)
  let core := core.writeContractSlot 3 (LidoSRv3.Audit.Source.AddressWrappedTokenCalls.balanceSlot 1) (word 15)
  let core := core.writeContractSlot 3 (LidoSRv3.Audit.Source.AddressWrappedTransferCalls.allowanceSlot 1 99) (word 15)
  ⟨core,fun _ => 100,[]⟩
def pausedCallback : External := fun req w =>
  .success (encode 32 (if req.payload.take 4 = encode 4 0x23b872dd then 1 else 2))
    {w with core := w.core.writeSlot resumeSlot (word (2^256-1)), logs := w.logs ++ [⟨req.target,"Callback",[]⟩]}
def convert : StaticExternal := fun req _ =>
  if req.caller = 3 ∧ req.target = 2 ∧ req.payload.take 4 = encode 4 0x7a28fb88 then
    .ok (encode 32 (decode (req.payload.drop 4) * 100)) else .error (.bubbled [0x44])
def shares : StaticExternal := fun req _ =>
  if req.caller = 99 ∧ req.target = 2 ∧ req.payload.take 4 = encode 4 0x19208451 then
    .ok (encode 32 (decode (req.payload.drop 4) + 1)) else .error (.bubbled [0x45])

def diagnostics : IO Unit := do
  let st := runBatch (stETHStep pausedCallback shares ⟨99,1⟩ 2) ⟨99,1⟩ 0 [word 100,word 200] physicalBefore
  unless st.outcome == .ok [1,2] && st.attempts.length == 4 &&
      st.world.logs.filterMap (fun e => if e.name == "WithdrawalRequested" then some (e.values.map (·.val)) else none) ==
        [[1,1,1,100,101],[2,1,1,200,201]] do
    throw (IO.userError "actual stETH batch effects/ordered IDs/owner failed")
  let ws := wrappedStep convert pausedCallback reject shares ⟨99,1⟩ 3 2
  let wr := runBatch ws ⟨99,1⟩ 9 [word 7,word 8] physicalBefore
  unless wr.outcome == .ok [1,2] && wr.attempts.length == 6 &&
      wr.world.logs.filterMap (fun e => if e.name == "WithdrawalRequested" then some (e.values.map (·.val)) else none) ==
        [[1,1,9,700,701],[2,1,9,800,801]] do
    throw (IO.userError "actual transferFrom unwrap batch consumer failed")
  unless (wr.world.core.readSlot resumeSlot).val == 2^256-1 &&
      (wr.world.core.readContractSlot 3 2).val == 0 &&
      (wr.world.core.readContractSlot 3 (LidoSRv3.Audit.Source.AddressWrappedTransferCalls.allowanceSlot 1 99)).val == 0 do
    throw (IO.userError "pause callback was rechecked or qualified worlds lost")
  let lateSt := runBatch (stETHStep pausedCallback shares ⟨99,1⟩ 2) ⟨99,1⟩ 0 [word 100,word 99] physicalBefore
  unless lateSt.outcome == .error (.reason "RequestAmountTooSmall") && lateSt.attempts.length == 2 &&
      lateSt.world.logs.isEmpty && (lateSt.world.core.readSlot resumeSlot).val == 0 do
    throw (IO.userError "late stETH failure lost entry rollback/first attempts")
  let lateWr := runBatch ws ⟨99,1⟩ 0 [word 7,word 9] physicalBefore
  unless lateWr.outcome == .error (.bubbled (LidoSRv3.Audit.Source.TrioReserve1.ReplyABI.reason "ERC20: transfer amount exceeds balance")) &&
      lateWr.attempts.length == 4 && lateWr.world.logs.isEmpty &&
      (lateWr.world.core.readContractSlot 3 2).val == 15 &&
      (lateWr.world.core.readContractSlot 3 (LidoSRv3.Audit.Source.AddressWrappedTransferCalls.allowanceSlot 1 99)).val == 15 do
    throw (IO.userError "late wrapped failure failed full earlier-item rollback")
  IO.println "PASS 5 native actual-batch checks: stETH transcript, wrapped transcript, pause callback/worlds, late stETH rollback/journal, late wrapped rollback/journal"

#print axioms LidoSRv3.Audit.Source.AddressRequestBatches.loop_success
#print axioms LidoSRv3.Audit.Source.AddressRequestBatches.entry_success
#print axioms LidoSRv3.Audit.Source.AddressRequestBatches.owner_idempotent
#print axioms LidoSRv3.Audit.Guarantees.PAddress1.actual_steth_request_batch
#print axioms LidoSRv3.Audit.Guarantees.PAddress1.actual_wrapped_request_batch
#print axioms LidoSRv3.Audit.Guarantees.PAddress1.actual_steth_batch_failure_restores
#print axioms LidoSRv3.Audit.Guarantees.PAddress1.actual_wrapped_batch_failure_restores
#print axioms LidoSRv3.Tests.AddressRequestBatches.public_empty_steth
#print axioms LidoSRv3.Tests.AddressRequestBatches.public_paused_wrapped_rollback
end LidoSRv3.Tests.AddressRequestBatches
