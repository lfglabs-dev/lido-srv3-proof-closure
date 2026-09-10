import LidoSRv3.Audit.Guarantees.PAccount1TreasuryCall
import Tests.Verity.ReportFeeDistributionTest
namespace AccountTreasuryCallRegression
set_option autoImplicit false
set_option maxRecDepth 8192
open AccountAddress ReportWriteFee StETHMintShares ReportFeeTreasuryCall
open AccountCheckedSplitRegression
open LidoSRv3.Audit.Source.TrioReserve1

def env : TreasuryCall.Environment := {
  locator := Verity.Core.Address.ofNat 900
  codeSize := fun _ => Live.word 1
  external := fun req w =>
    if req = ⟨Verity.Core.Address.ofNat 7,Verity.Core.Address.ofNat 900,Live.word 0,Live.encode 4 0x61d027b3⟩ ∧
       (w.router.read AccountActualMintRegression.layout.routerAccountingSlot).val = 4 ∧
       totalShares w.steth = 20 ∧ w.steth.shares 7 = 11 ∧ w.steth.shares 170 = 2 ∧ w.steth.shares 190 = 2 then
      .success (Live.encode 32 500 ++ [0xab]) else .rejected [0xee] }
def result := execute env input world

theorem actual_call_and_payment : (match result with
  | .committed post fee events payments attempts => decide
    (fee.sharesToMintAsFees = 10 ∧ post.steth.shares 7 = 5 ∧ post.steth.shares 500 = 6 ∧
     payments = [(170,2),(190,2),(500,6)] ∧ events.length = 8 ∧
     attempts = [⟨TreasuryCall.request env 7,true,true,Live.encode 32 500 ++ [0xab],1⟩])
  | _ => false) = true := by decide +kernel

theorem public_consumer : match result with
  | .committed post fee events payments _ => ∃ minted : ReportFeeMint.World,
      ReportFeeDistribution.Success (TreasuryCall.read env 7 minted.router) input world post fee events payments ∧
      ReportFeeDistribution.Ledger input world post fee payments
  | _ => False := by
  cases hr : result with
  | committed post fee events payments attempts =>
    obtain ⟨minted,_,_,hs,hl,_⟩ := LidoSRv3.Audit.Guarantees.PAccount1.actual_report_fee_mint_treasury_call
      env input world post fee events payments attempts hr
    exact ⟨minted,hs,hl⟩
  | reverted e w ps ats => have h := actual_call_and_payment; rw [hr] at h; cases h

theorem malformed_address : TreasuryCall.decodeAddress (Live.encode 32 (2^160+500)) = .error .empty := by rfl
theorem short_return : TreasuryCall.decodeAddress (List.replicate 31 0) = .error .empty := by rfl
theorem zero_address_decodes : TreasuryCall.decodeAddress (Live.encode 32 0) = .ok 0 := by rfl

def returned (raw : Live.Bytes) : TreasuryCall.Environment := {env with external := fun _ _ => .success raw}

theorem malformed_after_modules_rolls_back : (match execute (returned (Live.encode 32 (2^160+500))) input world with
  | .reverted (.locator .empty) rollback ps ats => decide
    (rollback.router = world.router ∧ rollback.steth.storage = world.steth.storage ∧ rollback.steth.shares 7 = 5 ∧
     rollback.steth.shares 170 = 0 ∧ ps = [(170,2),(190,2)] ∧ ats.length = 1 ∧
     ats.head?.map (fun a => a.accepted) = some true)
  | _ => false) = true := by decide +kernel

theorem no_code_before_external : (match execute {env with codeSize := fun _ => Live.word 0} input world with
  | .reverted (.locator .empty) rollback ps ats => decide
    (rollback.router = world.router ∧ rollback.steth.shares 170 = 0 ∧ ps = [(170,2),(190,2)] ∧ ats = [])
  | _ => false) = true := by decide +kernel

theorem revert_bytes_bubble : (match execute {env with external := fun _ _ => .rejected [0xde,0xad]} input world with
  | .reverted (.locator (.bubbled bytes)) _ ps ats => decide
    (bytes = [0xde,0xad] ∧ ps = [(170,2),(190,2)] ∧
     ats = [⟨TreasuryCall.request env 7,true,false,[0xde,0xad],1⟩])
  | _ => false) = true := by decide +kernel

theorem static_write_rejects : (match execute {env with external := fun _ _ => .forbiddenStateChange} input world with
  | .reverted (.locator .empty) rollback _ ats => decide
    (rollback.steth.shares 170 = 0 ∧ ats = [⟨TreasuryCall.request env 7,true,false,[],1⟩])
  | _ => false) = true := by decide +kernel

theorem decoded_zero_then_transfer_guard : (match execute (returned (Live.encode 32 0)) input world with
  | .reverted (.distribution (.transfer .toZero)) rollback ps ats => decide
    (rollback.steth.shares 170 = 0 ∧ ps = [(170,2),(190,2),(0,6)] ∧ ats.length = 1)
  | _ => false) = true := by decide +kernel

theorem zero_mint_no_attempt : (match execute {env with codeSize := fun _ => Live.word 0}
    {input with report := {input.report with clValidatorsBalance := 0}} world with
  | .committed _ _ events ps ats => decide (events = [] ∧ ps = [] ∧ ats = [])
  | _ => false) = true := by decide +kernel

theorem zero_treasury_no_attempt : (match distribute {env with codeSize := fun _ => Live.word 0}
    7 ⟨5,[170,180],[1,2],[2,3],0⟩ world with
  | .committed post _ ps ats => decide
    (post.steth.shares 7 = 0 ∧ ps = [(170,2),(180,3)] ∧ ats = [])
  | _ => false) = true := by decide +kernel

#print axioms actual_call_and_payment
#print axioms public_consumer
#print axioms malformed_address
#print axioms short_return
#print axioms zero_address_decodes
#print axioms malformed_after_modules_rolls_back
#print axioms no_code_before_external
#print axioms revert_bytes_bubble
#print axioms static_write_rejects
#print axioms decoded_zero_then_transfer_guard
#print axioms zero_mint_no_attempt
#print axioms zero_treasury_no_attempt
end AccountTreasuryCallRegression
