import LidoSRv3.Audit.Source.TrioReserve1.Vaults
import LidoSRv3.Audit.Source.TrioReserve1.Report

namespace LidoSRv3.Tests.TrioReserve1.VaultCases
open LidoSRv3.Audit.Source.TrioReserve1 Live

def address := Verity.Core.Address.ofNat
def ctx : Context := ⟨address 1, address 2⟩
def input : Report.Inputs := ⟨word 11, word 12, word 13, word 30, word 20, word 0, word 0, word 0⟩
def initial (rewardBalance withdrawalBalance total : Nat) : World :=
  let core := {Verity.defaultState with codeSize := fun _ => word 1}
  let core := core.writeContractSlot 1 activeSlot (word 1)
  let core := core.writeContractSlot 1 locatorSlot (word 3)
  let core := core.writeContractSlot 1 bufferSlot (pack 100 7)
  let core := core.writeContractSlot 1 reserveSlot (word 20)
  let core := core.writeContractSlot 1 targetSlot (word 50)
  let core := core.writeContractSlot 1 VaultCallbacks.totalRewardsSlot (word total)
  ⟨core, fun a => if a = address 1 then 1000 else if a = address 4 then rewardBalance
    else if a = address 5 then withdrawalBalance else 0, []⟩

def rejectOther : External := fun _ _ => .rejected [255]
/-- Explicit locator fixture; vaults and Lido callback bodies below are source models. -/
def getters (other : External) : External := fun req w =>
  if req.target = address 3 then
    if req.payload = encode 4 0x9624e83e then .success (encode 32 2) w
    else if req.payload = encode 4 0xe441d25f then .success (encode 32 4) w
    else if req.payload = encode 4 0x69d42148 then .success (encode 32 5) w
    else other req w
  else other req w

def callbacks : External := VaultCallbacks.dispatch (getters rejectOther) (address 1) rejectOther
def external : External := getters (Vaults.dispatch callbacks (address 4) (address 5) (address 1) rejectOther)

def succeeded (r : Result Unit) : Bool := match r.outcome with | .ok _ => true | .error _ => false
def failed (r : Result Unit) (fault : Fault) : Bool := match r.outcome with
  | .ok _ => false
  | .error e => decide (e = fault)

def success : Bool :=
  let r := run (Report.collect external ctx input) (initial 50 40 10)
  let trace := ReplyABI.nested r.attempts
  succeeded r &&
  [r.world.balances (address 1), r.world.balances (address 4), r.world.balances (address 5)] == [1050,30,10] &&
  (r.world.core.readContractSlot 1 bufferSlot).val == (pack 150 7).val &&
  (r.world.core.readContractSlot 1 VaultCallbacks.totalRewardsSlot).val == 30 &&
  trace.map (fun n => (n.request.target.val,n.request.value.val,n.depth)) ==
    [(3,0,1),(3,0,1),(4,0,1),(1,20,2),(3,0,3),(3,0,1),(5,0,1),(1,30,2),(3,0,3)] &&
  r.world.logs.map (fun l => (l.name,l.values.map (·.val))) ==
    [("ELRewardsReceived",[20]),("WithdrawalsReceived",[30]),("DepositsReserveSet",[50]),
      ("ETHDistributed",[11,13,12,30,20,150])]

def capped : Bool :=
  let args := {input with rewards := word 100}
  let r := run (Report.collect external ctx args) (initial 50 40 10)
  succeeded r && r.world.balances (address 1) == 1080 && r.world.balances (address 4) == 0 &&
  (r.world.core.readContractSlot 1 VaultCallbacks.totalRewardsSlot).val == 60 &&
  -- Source report arithmetic uses the supplied input, not the returned capped amount.
  (r.world.core.readContractSlot 1 bufferSlot).val == (pack 230 7).val &&
  (r.attempts[2]?).any (fun a => a.returned == encode 32 50)

def emptyRewards : Bool :=
  let r := run (Report.collect external ctx input) (initial 0 40 10)
  succeeded r && (r.attempts[2]?).any (fun a => a.nested.isEmpty && a.returned == encode 32 0) &&
  r.world.balances (address 1) == 1030 && (r.world.core.readContractSlot 1 VaultCallbacks.totalRewardsSlot).val == 10

def insufficientWithdrawals : Bool :=
  let r := run (Report.collect external ctx input) (initial 50 20 10)
  failed r (.bubbled (encode 4 0x41ba67b6 ++ encode 32 30 ++ encode 32 20)) &&
  [r.world.balances (address 1),r.world.balances (address 4),r.world.balances (address 5)] == [1000,50,20] &&
  (r.world.core.readContractSlot 1 VaultCallbacks.totalRewardsSlot).val == 10 && r.world.logs.isEmpty &&
  r.attempts.length == 5 && (r.attempts[2]?).any (fun a => a.nested.length == 2) && (r.attempts[4]?).any (fun a => a.nested.isEmpty)

def counterOverflow : Bool :=
  let total := 2^256 - 11
  let r := run (Report.collect external ctx input) (initial 50 40 total)
  failed r (.bubbled (ReplyABI.reason "MATH_ADD_OVERFLOW")) &&
  r.world.balances (address 1) == 1000 && r.world.balances (address 4) == 50 &&
  (r.world.core.readContractSlot 1 VaultCallbacks.totalRewardsSlot).val == total && r.world.logs.isEmpty &&
  r.attempts.length == 3 && (r.attempts[2]?).any (fun a => a.nested.map (fun n => (n.accepted,n.depth)) == [(false,1),(true,2)])

def zeroWithdrawal : Bool :=
  let r := run (Vaults.withdrawals callbacks ⟨address 5,address 1⟩ (address 1) (word 0)) (initial 50 40 10)
  failed r (.bubbled (encode 4 0x1f2a2005)) && r.attempts.isEmpty

def unauthorized : Bool :=
  let r := run (VaultCallbacks.receiveWithdrawals (getters rejectOther) ⟨address 1,address 9⟩ (word 30)) (initial 50 40 10)
  failed r (.reason "APP_AUTH_FAILED") && r.attempts.length == 1 && r.world.logs.isEmpty

def malformedEntry : Bool :=
  match Vaults.dispatch callbacks (address 4) (address 5) (address 1) rejectOther
      ⟨address 1,address 4,word 0,encode 4 0x9342c8f4 ++ [1]⟩ (initial 50 40 10) with
  | .rejected data => data.isEmpty
  | _ => false

def nonpayableEntry : Bool :=
  match Vaults.dispatch callbacks (address 4) (address 5) (address 1) rejectOther
      ⟨address 1,address 4,word 1,encode 4 0x9342c8f4 ++ encode 32 20⟩ (initial 50 40 10) with
  | .rejected data => data.isEmpty
  | _ => false

#eval (show IO Unit from do
  let cases := [("nested-success-transfers-events",success),("reward-cap-and-report-input",capped),
    ("empty-reward-vault-skips-callback",emptyRewards),("withdrawal-funds-error-root-rollback",insufficientWithdrawals),
    ("reward-counter-overflow-nested-rollback",counterOverflow),("zero-withdrawal-guard",zeroWithdrawal),
    ("callback-address-admission",unauthorized),("short-vault-calldata",malformedEntry),("nonpayable-vault",nonpayableEntry)]
  for (name,ok) in cases do
    if !ok then throw (IO.userError ("vault case failed: " ++ name))
    IO.println ("PASS " ++ name))

end LidoSRv3.Tests.TrioReserve1.VaultCases
