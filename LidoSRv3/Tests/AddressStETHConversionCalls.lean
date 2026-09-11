import LidoSRv3.Audit.Guarantees.PAddress1StETHConversionCalls
namespace LidoSRv3.Tests.AddressStETHConversionCalls
open LidoSRv3.Audit.Source
open TrioReserve1 Live
open AddressStETHQuoteCalls (internalEther internalShares sharesSlot bufferedSlot clSlot quote)
open AddressStETHConversionCalls
open AddressRequestBatches AddressPermitRequestCalls
open LidoSRv3.Audit.Guarantees.PAddress1
open LidoSRv3.Audit.Verity.AddressRecipientCallBridge (pooledEthBySharesCalldata)
def ctx : Context := ⟨99,1⟩
def p : PermitInput := ⟨word 15,word 500,27,word 8,word 9⟩
def base : World := ⟨{Verity.defaultState with codeSize := fun _ => word 1,blockTimestamp := word 42},fun _ => 100,[]⟩
def physical (s b c : Nat) : World :=
  {base with core := ((base.core.writeContractSlot 4 sharesSlot (word s)).writeContractSlot 4 bufferedSlot (word b)).writeContractSlot 4 clSlot (word c)}
def reject : External := fun _ _ => .rejected [0xaa]
def permit : External := fun _ w => .success [] {w with core := w.core.writeSlot 123 (word 15),logs := w.logs ++ [⟨3,"Permit",[]⟩]}
example : (pooledEthBySharesCalldata 7).length = 36 := by decide +kernel
example : (pooledEthBySharesCalldata 7).take 4 = [0x7a,0x28,0xfb,0x88] := by decide +kernel
example : body 4 (word 8) (physical (100+20*2^128) (100+200*2^128) (300+400*2^128)) = .ok (word 100) := by decide +kernel
example : body 4 (word (2^128-1)) base = .error (.bubbled (ReplyABI.reason "SHARES_TOO_LARGE")) := by decide +kernel
example : body 4 (word (2^128-2)) (physical 1 1 0) = .ok (word (2^128-2)) := by decide +kernel
example : body 4 (word 0) (physical 0 1 0) = .error (.bubbled []) := by decide +kernel
example : body 4 (word 7) (physical 1 0 0) = .ok (word 0) := by decide +kernel
example : body 4 (word 2) (physical (2^128) 1 0) = .ok (word 0) := by decide +kernel
example : body 4 (word (2^128-2)) (physical 1 (2^256-1) (2^256-1)) = .ok (word (((2^128-2)*(4*(2^128-1))) % 2^256)) := by decide +kernel
example : body 5 (word 7) (physical 20 2000 0) = .error (.bubbled []) := by decide +kernel
example : conversion ⟨3,4,0,pooledEthBySharesCalldata 7⟩ (physical 20 2000 0) = .ok (encode 32 700) := by decide +kernel
example : conversion ⟨3,4,1,pooledEthBySharesCalldata 7⟩ (physical 20 2000 0) = .error (.bubbled []) := by decide +kernel
example : AddressWrappedTokenCalls.stETHAddress 3 {base with core := base.core.writeContractSlot 3 7 (word (4+2^200))} = 4 := by decide +kernel

def empty := runBatch (wrappedStep conversion reject reject (quote 2) ctx 3 2) ctx 0 []
theorem public_empty_success : PhysicalQuotePermitEffect permit reject reject ctx 3 2 0 p [] [] base
    (runPermit permit ctx 3 p empty base).world (runPermit permit ctx 3 p empty base).attempts :=
  (actual_wrapped_physical_conversion_permit_batch permit reject reject ctx 3 2 0 p [] [] base (by rfl)).1
def paused : World := {base with core := base.core.writeSlot resumeSlot (word 43)}
theorem public_paused_rollback : (runPermit permit ctx 3 p empty paused).world = paused :=
  actual_wrapped_physical_conversion_failure_restores permit reject reject ctx 3 2 0 p [] paused (.reason "ResumedExpected") (by rfl)

-- Conversion happens before burn (whose balance map uses Keccak).
def preburn : World := {base with core := base.core.writeContractSlot 3 7 (word 4)}
example : (AddressWrappedTokenCalls.tokenProgram conversion reject ⟨3,99⟩ (word 7) preburn).outcome = .error (.bubbled []) := by decide +kernel
example : (AddressWrappedTokenCalls.tokenProgram conversion reject ⟨3,99⟩ (word 0) preburn).outcome = .error (.reason "wstETH: zero amount unwrap not allowed") := by decide +kernel
example : (AddressWrappedTokenCalls.tokenProgram conversion reject ⟨3,99⟩ (word (2^128-1)) preburn).outcome = .error (.bubbled (ReplyABI.reason "SHARES_TOO_LARGE")) := by decide +kernel

def physicalBefore : World :=
  let w := physical 20 2000 0
  let c := w.core.writeContractSlot 2 sharesSlot (word 15)
  let c := c.writeContractSlot 2 bufferedSlot (word 1500)
  let c := c.writeContractSlot 5 sharesSlot (word 20)
  let c := c.writeContractSlot 5 bufferedSlot (word 4000)
  let c := c.writeContractSlot 3 7 (word (4+2^200))
  let c := c.writeContractSlot 3 2 (word 15)
  let c := c.writeContractSlot 3 (AddressWrappedTokenCalls.balanceSlot 1) (word 15)
  {w with core := c}
def permitAllowance : External := fun req w =>
  if req = ⟨99,3,0,calldata ctx p⟩ then
    .success [] {w with core := w.core.writeContractSlot 3 (AddressWrappedTransferCalls.allowanceSlot 1 99) p.value,logs := w.logs ++ [⟨3,"Permit",[p.value]⟩]}
  else .rejected [0xbb]
def callback (zeroSecond : Bool) : External := fun req w =>
  let first := internalEther 2 w = 1500
  if req.target = (if first then 4 else 5) ∧ decode (req.payload.drop 36) = (if first then 700 else 1600) then
    let c := w.core.writeContractSlot 3 7 (word (5+2^200))
    let c := c.writeContractSlot 2 bufferedSlot (word (if first then 3000 else 6000))
    let c := if zeroSecond then c.writeContractSlot 5 sharesSlot (word 0) else c
    .success (encode 32 1) {w with core := c}
  else .rejected [0xcc]
def diagnostics : IO Unit := do
  let batch := fun bad amounts => runBatch (wrappedStep conversion (callback bad) reject (quote 2) ctx 3 2) ctx 0 amounts
  let good := runPermit permitAllowance ctx 3 p (batch false [word 7,word 8]) physicalBefore
  unless good.outcome == .ok [1,2] && good.attempts.length == 7 &&
      good.world.logs.filterMap (fun e => if e.name == "WithdrawalRequested" then some (e.values.map (·.val)) else none) == [[1,1,1,700,3],[2,1,1,1600,4]] &&
      AddressWrappedTokenCalls.stETHAddress 3 good.world == 5 && internalEther 2 good.world == 6000 &&
      (good.world.core.readContractSlot 3 (AddressWrappedTransferCalls.allowanceSlot 1 99)).val == 0 do
    throw (IO.userError "dynamic target/rate/captured output not consumed")
  let late := runPermit permitAllowance ctx 3 p (batch true [word 7,word 8]) physicalBefore
  unless late.outcome == .error (.bubbled []) && late.attempts.length == 6 && late.world.logs.isEmpty &&
      AddressWrappedTokenCalls.stETHAddress 3 late.world == 4 && internalEther 2 late.world == 1500 &&
      (late.world.core.readContractSlot 3 2).val == 15 && (late.world.core.readContractSlot 3 (AddressWrappedTransferCalls.allowanceSlot 1 99)).val == 0 do
    throw (IO.userError "late reverse INVALID root rollback")
  let zeroI := {physicalBefore with core := physicalBefore.core.writeContractSlot 4 bufferedSlot (word 0)}
  let noEffectTransfer : External := fun _ w => .success (encode 32 1) w
  let zero := runPermit permitAllowance ctx 3 p (runBatch (wrappedStep conversion noEffectTransfer reject (quote 2) ctx 3 2) ctx 0 [word 7]) zeroI
  unless zero.outcome == .error (.reason "RequestAmountTooSmall") && zero.world.logs.isEmpty &&
      (zero.world.core.readContractSlot 3 2).val == 15 do
    throw (IO.userError "captured zero conversion not consumed by queue guard")
  let noCode := {physicalBefore with core := {physicalBefore.core with codeSize := fun a => if a=4 then word 0 else word 1}}
  let missing := runPermit permitAllowance ctx 3 p (batch false [word 7]) noCode
  unless missing.outcome == .error (.bubbled []) && missing.world.logs.isEmpty && missing.attempts.length == 3 do
    throw (IO.userError "actual dynamic target code guard")
  IO.println "PASS 4 native diagnostics: different dynamic targets/rates and captured outputs; late reverse INVALID rollback; zero result queue guard; dynamic target no-code"

#print axioms LidoSRv3.Audit.Source.AddressStETHConversionCalls.body_success
#print axioms LidoSRv3.Audit.Source.AddressStETHConversionCalls.canonical_call
#print axioms LidoSRv3.Audit.Source.AddressStETHConversionCalls.conversion_effect
#print axioms LidoSRv3.Audit.Source.AddressStETHConversionCalls.token_effect
#print axioms LidoSRv3.Audit.Source.AddressStETHConversionCalls.item_effect
#print axioms LidoSRv3.Audit.Guarantees.PAddress1.actual_wrapped_physical_conversion_permit_batch
#print axioms LidoSRv3.Audit.Guarantees.PAddress1.actual_wrapped_physical_conversion_failure_restores
#print axioms LidoSRv3.Tests.AddressStETHConversionCalls.public_empty_success
#print axioms LidoSRv3.Tests.AddressStETHConversionCalls.public_paused_rollback
end LidoSRv3.Tests.AddressStETHConversionCalls
