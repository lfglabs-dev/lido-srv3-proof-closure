import LidoSRv3.Audit.Guarantees.PAccount1PhysicalPause
import Tests.Verity.ReportFeeTreasuryCallTest
namespace LidoSRv3.Tests.AccountPhysicalPause
set_option autoImplicit false
set_option maxRecDepth 8192
open AccountAddress ReportWriteFee StETHMintShares ReportFeePhysicalPause
open AccountCheckedSplitRegression
open LidoSRv3.Audit.Source.TrioReserve1
def word (n : Nat) : StorageWord := ⟨n % two256,Nat.mod_lt _ (by decide)⟩
def physical (n : Nat) (metadata : Bool) : ReportFeeMint.World :=
  {world with steth := {world.steth with storage := world.steth.storage.write activePosition (word n),activeFlag := metadata}}
def checkedExternal (req : Live.Request) (w : ReportFeeMint.World) : StaticCall.Reply :=
  if w.steth.activeFlag && (pauseWord w.steth).val == 2 then
    AccountTreasuryCallRegression.env.external req w
  else
    StaticCall.Reply.rejected [0xdd]
def env : TreasuryCall.Environment := {AccountTreasuryCallRegression.env with external := checkedExternal}

def result := execute env input (physical 2 false)
example : active (physical 0 true).steth = false := by decide +kernel
example : active (physical 2 false).steth = true := by decide +kernel
example : active (physical (2^255) false).steth = true := by decide +kernel
example : active (physical (2^256) true).steth = false := by decide +kernel
example : active (physical (2^256+2) false).steth = true := by decide +kernel

theorem positive : (match result with
  | .committed post fee events payments attempts => decide
    (fee.sharesToMintAsFees=10 ∧ post.steth.shares 7=5 ∧ post.steth.shares 500=6 ∧
     post.steth.activeFlag=true ∧ (pauseWord post.steth).val=2 ∧ payments=[(170,2),(190,2),(500,6)] ∧ events.length=8 ∧ attempts.length=1)
  | _ => false) = true := by decide +kernel

theorem public_success : match result with
  | .committed post fee events payments attempts =>
      OldEffect env input (physical 2 false) post fee events payments attempts ∧
      PhysicalEffect input (physical 2 false) post fee events payments
  | _ => False := by
  cases hr : result with
  | committed post fee events payments attempts =>
    exact LidoSRv3.Audit.Guarantees.PAccount1.actual_report_physical_pause env input (physical 2 false) post fee events payments attempts hr
  | reverted f w ps ats => have h := positive; rw [hr] at h; cases h

example : (match execute env input (physical 0 true) with
  | .reverted (.mint (.mint .stopped)) rollback payments attempts => decide
      (rollback.steth.activeFlag=true ∧ (pauseWord rollback.steth).val=0 ∧ rollback.steth.shares 170=0 ∧ payments=[] ∧ attempts=[])
  | _ => false) = true := by decide +kernel
example : (match execute env input { (physical 0 true) with steth := {(physical 0 true).steth with locatorAccounting := 8}} with
  | .reverted (.mint (.mint .notAccounting)) _ _ _ => true
  | _ => false) = true := by decide +kernel
example : (match mintShares 7 0 1 (project (physical 0 true)).steth with
  | .reverted .stopped _ => true | _ => false) = true := by decide +kernel
example : (match FeeDistribution.transferShares 7 0 1 (project (physical 0 true)).steth with
  | .reverted .toZero _ => true | _ => false) = true := by decide +kernel
example : (match FeeDistribution.transferShares 7 170 1 (project (physical 0 true)).steth with
  | .reverted .stopped _ => true | _ => false) = true := by decide +kernel
example : (match execute AccountTreasuryCallRegression.env input (physical (2^255) false) with
  | .committed post _ _ _ _ => decide (post.steth.activeFlag=true ∧ (pauseWord post.steth).val=2^255)
  | _ => false) = true := by decide +kernel
example : (match execute env {input with report := {input.report with clValidatorsBalance := 0}} (physical 0 true) with
  | .committed post _ events payments attempts => decide
    (post.steth.activeFlag=false ∧ (pauseWord post.steth).val=0 ∧ post.steth.storage=(physical 0 true).steth.storage ∧ events=[] ∧ payments=[] ∧ attempts=[])
  | _ => false) = true := by decide +kernel

def badEnv : TreasuryCall.Environment := AccountTreasuryCallRegression.returned (Live.encode 32 0)
def failed := execute badEnv input (physical 2 false)
theorem late_failure : (match failed with
  | .reverted (.distribution (.transfer .toZero)) rollback ps ats => decide
    (rollback.steth.activeFlag=false ∧ rollback.steth.storage=(physical 2 false).steth.storage ∧
     rollback.router=(physical 2 false).router ∧ rollback.steth.shares 170=0 ∧ rollback.steth.shares 7=5 ∧ ps=[(170,2),(190,2),(0,6)] ∧ ats.length=1)
  | _ => false) = true := by decide +kernel

theorem public_failure : match failed with
  | .reverted fault rollback ps ats => rollback = physical 2 false
  | _ => False := by
  cases hr : failed with
  | reverted fault rollback ps ats =>
    exact LidoSRv3.Audit.Guarantees.PAccount1.actual_report_physical_pause_failure_restores badEnv input (physical 2 false) rollback fault ps ats hr
  | committed post fee events payments attempts => have h := late_failure; rw [hr] at h; cases h

example : (match execute {env with external := fun _ _ => .forbiddenStateChange} input (physical 2 false) with
  | .reverted (.locator .empty) rollback _ ats => decide ((pauseWord rollback.steth).val=2 ∧ rollback.steth.activeFlag=false ∧ ats.length=1)
  | _ => false) = true := by decide +kernel

#print axioms AccountAddress.ReportFeePhysicalPause.projection
#print axioms AccountAddress.ReportFeePhysicalPause.total_slot_distinct
#print axioms AccountAddress.ReportFeePhysicalPause.mint_frame
#print axioms AccountAddress.ReportFeePhysicalPause.chain_physical
#print axioms AccountAddress.ReportFeePhysicalPause.execute_success
#print axioms LidoSRv3.Audit.Guarantees.PAccount1.actual_report_physical_pause
#print axioms LidoSRv3.Audit.Guarantees.PAccount1.actual_report_physical_pause_failure_restores
#print axioms LidoSRv3.Tests.AccountPhysicalPause.public_success
#print axioms LidoSRv3.Tests.AccountPhysicalPause.public_failure
end LidoSRv3.Tests.AccountPhysicalPause
