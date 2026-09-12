import LidoSRv3.Audit.Guarantees.PAddress1StETHQuoteCalls
namespace LidoSRv3.Tests.AddressStETHQuoteCalls
open LidoSRv3.Audit.Source.TrioReserve1
open Live
open LidoSRv3.Audit.Source
open LidoSRv3.Audit.Source.AddressStETHQuoteCalls
open LidoSRv3.Audit.Source.AddressRequestBatches
open LidoSRv3.Audit.Source.AddressPermitRequestCalls
open LidoSRv3.Audit.Guarantees.PAddress1
open LidoSRv3.Audit.Verity.AddressRecipientCallBridge (StaticExternal stETHSharesCalldata)
def ctx : Context := ⟨99,1⟩
def p : PermitInput := ⟨word 15,word 500,27,word 8,word 9⟩
def base : World := ⟨{Verity.defaultState with codeSize := fun _ => word 1,blockTimestamp := word 42},fun _ => 100,[]⟩
def physical (s b c : Nat) : World :=
  {base with core := ((base.core.writeContractSlot 2 sharesSlot (word s)).writeContractSlot 2 bufferedSlot (word b)).writeContractSlot 2 clSlot (word c)}
def reject : External := fun _ _ => .rejected [0xaa]
def permit : External := fun _ w => .success [0xfe] {w with core := w.core.writeSlot 123 (word 15),logs := w.logs ++ [⟨2,"Permit",[]⟩]}
example : (stETHSharesCalldata 100).length = 36 := by decide +kernel
example : (stETHSharesCalldata 100).take 4 = [0x19,0x20,0x84,0x51] := by decide +kernel
example : internalEther 2 (physical 0 (100+200*2^128) (300+400*2^128)) = 1000 := by decide +kernel
example : body 2 (word 100) (physical (100+20*2^128) (100+200*2^128) (300+400*2^128)) = .ok (word 8) := by decide +kernel
example : body 2 (word (2^128-1)) (physical 0 0 0) = .error (.bubbled (ReplyABI.reason "ETH_TOO_LARGE")) := by decide +kernel
example : body 2 (word (2^128-2)) (physical 1 1 0) = .ok (word (2^128-2)) := by decide +kernel
example : body 2 (word 0) (physical 0 0 0) = .error (.bubbled []) := by decide +kernel
example : body 2 (word 100) (physical 0 1 0) = .ok (word 0) := by decide +kernel
example : body 2 (word 2) (physical (2^128) 1 0) = .ok (word (2^256-2)) := by decide +kernel
example : body 2 (word 100) (physical 100 (2^256-1) (2^256-1)) = .ok (word 0) := by decide +kernel
example : body 3 (word 100) (physical 100 1000 0) = .error (.bubbled []) := by decide +kernel
example : quote 2 ⟨99,2,0,stETHSharesCalldata 100⟩ (physical 10 1000 0) = .ok (encode 32 1) := by decide +kernel
example : quote 2 ⟨99,3,0,stETHSharesCalldata 100⟩ (physical 10 1000 0) = .error (.bubbled []) := by decide +kernel
example : quote 2 ⟨99,2,1,stETHSharesCalldata 100⟩ (physical 10 1000 0) = .error (.bubbled []) := by decide +kernel

def empty := runBatch (stETHStep reject (quote 2) ctx 2) ctx 0 []
theorem public_empty_success :
    JoinedEffect permit ctx 2 p (StETHEffect reject (quote 2) ctx 2 0 []) [] base
      (runPermit permit ctx 2 p empty base).world (runPermit permit ctx 2 p empty base).attempts :=
  ( actual_steth_physical_quote_permit_batch permit reject ctx 2 0 p [] [] base (by rfl)).1
def paused : World := {base with core := base.core.writeSlot resumeSlot (word 43)}
theorem public_paused_rollback : (runPermit permit ctx 2 p empty paused).world = paused :=
  actual_steth_physical_quote_failure_restores permit reject ctx 2 0 p [] paused (.reason "ResumedExpected") (by rfl)

def transferOnly : External := fun _ w => .success (encode 32 1) w
def zeroBatch := runBatch (stETHStep transferOnly (quote 2) ctx 2) ctx 0 [word 100]
example : (runPermit permit ctx 2 p zeroBatch base).outcome = .error (.bubbled []) := by decide +kernel
example : (runPermit permit ctx 2 p zeroBatch base).attempts.length = 3 := by decide +kernel
theorem public_nonempty_quote_rollback : (runPermit permit ctx 2 p zeroBatch base).world = base :=
  actual_steth_physical_quote_failure_restores permit transferOnly ctx 2 0 p [word 100] base (.bubbled []) (by rfl)

-- Native diagnostics use the actual inherited token and queue Keccak operations.
def physicalBefore : World :=
  let w := physical 15 1500 0
  let core := w.core.writeContractSlot 3 7 (word 2)
  let core := core.writeContractSlot 3 2 (word 15)
  let core := core.writeContractSlot 3 (AddressWrappedTokenCalls.balanceSlot 1) (word 15)
  {w with core := core}
def permitAllowance : External := fun req w =>
  if req = ⟨99,3,0,calldata ctx p⟩ then
    .success [] {w with core := w.core.writeContractSlot 3 (AddressWrappedTransferCalls.allowanceSlot 1 99) p.value,logs := w.logs ++ [⟨3,"Permit",[p.value]⟩]}
  else .rejected [0xbb]
def conversion : StaticExternal := fun req _ => .ok (encode 32 (decode (req.payload.drop 4)*100))
def callback (zeroSecond : Bool) : External := fun _ w =>
  let i := internalEther 2 w
  let next := if i = 1500 then 3000 else if zeroSecond then 0 else 6000
  .success (encode 32 1) {w with core := w.core.writeContractSlot 2 bufferedSlot (word next)}
def diagnostics : IO Unit := do
  let batch := fun bad amounts => runBatch (wrappedStep conversion (callback bad) reject (quote 2) ctx 3 2) ctx 0 amounts
  let result := runPermit permitAllowance ctx 3 p (batch false [word 7,word 8]) physicalBefore
  unless result.outcome == .ok [1,2] && result.attempts.length == 7 &&
      result.world.logs.filterMap (fun e => if e.name == "WithdrawalRequested" then some (e.values.map (·.val)) else none) == [[1,1,1,700,3],[2,1,1,800,2]] && internalEther 2 result.world == 6000 &&
      (result.world.core.readContractSlot 3 (AddressWrappedTransferCalls.allowanceSlot 1 99)).val == 0 do
    throw (IO.userError "physical quote/token/permit chain success")
  let late := runPermit permitAllowance ctx 3 p (batch true [word 7,word 8]) physicalBefore
  unless late.outcome == .error (.bubbled []) && late.attempts.length == 7 && late.world.logs.isEmpty &&
      internalEther 2 late.world == 1500 && (late.world.core.readContractSlot 3 2).val == 15 &&
      (late.world.core.readContractSlot 3 (AddressWrappedTransferCalls.allowanceSlot 1 99)).val == 0 do
    throw (IO.userError "late physical quote must roll back permit and earlier item")
  let st := runPermit permit ctx 2 p (runBatch (stETHStep (callback false) (quote 2) ctx 2) ctx 0 [word 600,word 1200]) physicalBefore
  unless st.outcome == .ok [1,2] && st.attempts.length == 5 &&
      st.world.logs.filterMap (fun e => if e.name == "WithdrawalRequested" then some (e.values.map (·.val)) else none) == [[1,1,1,600,3],[2,1,1,1200,3]] && internalEther 2 st.world == 6000 do
    throw (IO.userError "stETH postcallback physical quote batch")
  let stLate := runPermit permit ctx 2 p (runBatch (stETHStep (callback true) (quote 2) ctx 2) ctx 0 [word 600,word 1200]) physicalBefore
  unless stLate.outcome == .error (.bubbled []) && stLate.world.logs.isEmpty && internalEther 2 stLate.world == 1500 &&
      (stLate.world.core.readSlot 123).val == 0 do
    throw (IO.userError "stETH late physical quote rollback")
  IO.println "PASS 4 native checks: wrapped/stETH physical postcallback quote success and late quote root rollback including permit"

#print axioms LidoSRv3.Audit.Source.AddressStETHQuoteCalls.internalEther_bound
#print axioms LidoSRv3.Audit.Source.AddressStETHQuoteCalls.body_success
#print axioms LidoSRv3.Audit.Source.AddressStETHQuoteCalls.canonical_call
#print axioms LidoSRv3.Audit.Source.AddressStETHQuoteCalls.quote_effect
#print axioms LidoSRv3.Audit.Guarantees.PAddress1.actual_steth_physical_quote_permit_batch
#print axioms LidoSRv3.Audit.Guarantees.PAddress1.actual_wrapped_physical_quote_permit_batch
#print axioms LidoSRv3.Audit.Guarantees.PAddress1.actual_steth_physical_quote_failure_restores
#print axioms LidoSRv3.Audit.Guarantees.PAddress1.actual_wrapped_physical_quote_failure_restores
#print axioms LidoSRv3.Tests.AddressStETHQuoteCalls.public_empty_success
#print axioms LidoSRv3.Tests.AddressStETHQuoteCalls.public_nonempty_quote_rollback
#print axioms LidoSRv3.Tests.AddressStETHQuoteCalls.public_paused_rollback
end LidoSRv3.Tests.AddressStETHQuoteCalls
