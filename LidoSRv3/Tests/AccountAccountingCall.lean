import LidoSRv3.Audit.Guarantees.PAccount1AccountingCall
import LidoSRv3.Tests.AccountPhysicalPause
namespace LidoSRv3.Tests.AccountAccountingCall
set_option autoImplicit false
set_option maxRecDepth 16384
open AccountAddress ReportWriteFee StETHMintShares ReportFeeAccountingCall
open LidoSRv3.Audit.Source.TrioReserve1
open AccountCheckedSplitRegression

def original (target : Nat := 99) (pause : Nat := 2) : World :=
  let w := AccountPhysicalPause.physical pause false
  {w with steth := {w.steth with locatorAccounting := 888, storage := w.steth.storage.write AccountingCall.locatorPosition (AccountPhysicalPause.word target)}}
def accounting : AccountingCall.Environment :=
  ⟨fun a => if a.val = 99 then some ⟨Verity.Core.Address.ofNat 7⟩
    else if a.val = 100 then some ⟨Verity.Core.Address.ofNat 8⟩ else none⟩
def treasury : TreasuryCall.Environment :=
  {AccountPhysicalPause.env with external := fun req w =>
    if w.steth.locatorAccounting = 7 then AccountPhysicalPause.env.external req w else .rejected [0xee]}
def result := execute accounting treasury input (original 99 2)

theorem positive : (match result.outcome with
  | .committed post fee events payments attempts => decide
    (fee.sharesToMintAsFees = 10 ∧ post.steth.shares 7 = 5 ∧ post.steth.shares 500 = 6 ∧
     post.steth.locatorAccounting = 7 ∧ post.steth.activeFlag = true ∧
     (ReportFeePhysicalPause.pauseWord post.steth).val = 2 ∧
     payments = [(170,2),(190,2),(500,6)] ∧ events.length = 8 ∧ attempts.length = 1 ∧
     result.accountingAttempts.length = 1 ∧
     result.accountingAttempts.map (fun a => a.request.caller.val) = [(original 99 2).steth.selfAddress] ∧
     result.accountingAttempts.map (fun a => (a.request.target.val,a.isStatic,a.accepted,a.request.value.val,a.request.payload)) =
       [(99,false,true,0,[0x96,0x24,0xe8,0x3e])])
  | _ => false) = true := by decide +kernel

theorem public_success : match result.outcome with
  | .committed post fee events payments attempts =>
    Success accounting treasury input (original 99 2) post fee events payments attempts result.accountingAttempts
  | _ => False := by
  cases h : result.outcome with
  | committed post fee events payments attempts =>
    exact LidoSRv3.Audit.Guarantees.PAccount1.actual_report_accounting_call accounting treasury input (original 99 2) post fee events payments attempts h
  | reverted f w ps ats => have hp := positive; rw [h] at hp; cases hp

example : AccountingCall.decodeAddress [1,2,3] = .error .empty := by rfl
example : AccountingCall.decodeAddress (List.replicate 31 0) = .error .empty := by rfl
example : AccountingCall.decodeAddress (List.replicate 31 0 ++ [7]) = .ok 7 := by rfl
example : AccountingCall.decodeAddress ([0xff] ++ List.replicate 30 0 ++ [7,0xab]) = .ok 7 := by rfl
example : AccountingCall.decodeAddress (List.replicate 32 0xff) = .ok (2^160-1) := by rfl
example : AccountingCall.locator (original ((2^96-1)*2^160+99) 2) = Verity.Core.Address.ofNat 99 := by decide +kernel
example : (match (execute accounting treasury input (original ((2^96-1)*2^160+99) 2)).outcome with
  | .committed post _ _ _ _ => decide (post.steth.locatorAccounting=7)
  | _ => false) = true := by decide +kernel

-- Physical target100 resolves8, irrespective of contradictory old metadata.
example : (match (execute accounting treasury input (original 100 2)).outcome with
  | .reverted (.mint (.mint .notAccounting)) _ _ _ => true
  | _ => false) = true := by decide +kernel
example : (match (execute accounting treasury input (original 99 0)).outcome with
  | .reverted (.mint (.mint .stopped)) _ _ _ => true
  | _ => false) = true := by decide +kernel
example : (execute accounting treasury input (original 99 0)).accountingAttempts.length = 1 := by decide +kernel
example : (match (execute accounting treasury input (original 100 0)).outcome with
  | .reverted (.mint (.mint .notAccounting)) _ _ _ => true | _ => false) = true := by decide +kernel
-- Code check occurs before pause/auth; no nonexistent CALL attempt is logged.
example : (match (execute accounting treasury input (original 101 0)).outcome with
  | .reverted (.locator .empty) _ _ _ => true
  | _ => false) = true := by decide +kernel
example : (execute accounting treasury input (original 101 0)).accountingAttempts = [] := by decide +kernel

-- Zero fee skips the accounting getter even with no code and a stopped word.
def zeroBefore : World :=
  {original 101 0 with steth := {(original 101 0).steth with activeFlag := true}}
def zeroResult := execute accounting treasury
  {input with report := {input.report with clValidatorsBalance := 0}} zeroBefore
example : (match zeroResult.outcome with
  | .committed post fee events payments attempts => decide
    (fee.sharesToMintAsFees=0 ∧ post.steth.locatorAccounting=888 ∧ post.steth.activeFlag=false ∧
     events=[] ∧ payments=[] ∧ attempts=[] ∧ zeroResult.accountingAttempts=[])
  | _ => false) = true := by decide +kernel
-- Report and arithmetic errors precede any accounting CALL.
example : (execute accounting treasury {input with balancesGwei := []} (original 99 2)).accountingAttempts = [] := by decide +kernel
example : (match (execute accounting treasury {input with balancesGwei := []} (original 99 2)).outcome with
  | .reverted (.mint (.invalidReport _)) _ _ _ => true | _ => false) = true := by decide +kernel
example : (execute accounting treasury {input with report := {input.report with internalSharesBeforeFees := 2^256}} (original 99 2)).accountingAttempts = [] := by decide +kernel

def badTreasury := AccountPhysicalPause.badEnv
def failed := execute accounting badTreasury input (original 99 2)
theorem late_failure : (match failed.outcome with
  | .reverted (.distribution (.transfer .toZero)) rollback ps ats => decide
    (rollback.steth.locatorAccounting=888 ∧ rollback.steth.activeFlag=false ∧
     rollback.steth.storage=(original 99 2).steth.storage ∧ rollback.router=(original 99 2).router ∧
     rollback.steth.shares 170=0 ∧ rollback.steth.shares 7=5 ∧
     ps=[(170,2),(190,2),(0,6)] ∧ ats.length=1 ∧ failed.accountingAttempts.length=1)
  | _ => false) = true := by decide +kernel

theorem public_failure : match failed.outcome with
  | .reverted _ rollback _ _ => rollback = original 99 2
  | _ => False := by
  cases h : failed.outcome with
  | reverted fault rollback ps ats =>
    exact LidoSRv3.Audit.Guarantees.PAccount1.actual_report_accounting_call_failure_restores accounting badTreasury input (original 99 2) rollback fault ps ats h
  | committed post fee events payments attempts => have hf := late_failure; rw [h] at hf; cases hf

#print axioms AccountAddress.AccountingCall.call_success
#print axioms AccountAddress.AccountingCall.decode_getter
#print axioms AccountAddress.AccountingCall.call_getter
#print axioms AccountAddress.ReportFeeAccountingCall.prepare_success
#print axioms AccountAddress.ReportFeeAccountingCall.mint_replay
#print axioms AccountAddress.ReportFeeAccountingCall.finish_success_replay
#print axioms AccountAddress.ReportFeeAccountingCall.execute_success
#print axioms LidoSRv3.Audit.Guarantees.PAccount1.actual_report_accounting_call
#print axioms LidoSRv3.Audit.Guarantees.PAccount1.actual_report_accounting_call_failure_restores
#print axioms public_success
#print axioms public_failure
end LidoSRv3.Tests.AccountAccountingCall
