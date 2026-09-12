import LidoSRv3.Audit.Source.TopupLiveWithdrawal

namespace LidoSRv3.Tests.TopupLiveWithdrawalMutants
open LidoSRv3.Audit.Source LidoSRv3.Audit.Source.TrioReserve1
open Live TopupLiveWithdrawal

set_option maxRecDepth 4096
set_option maxHeartbeats 1000000

def address (n : Nat) : Address := Verity.Core.Address.ofNat n
def context : Context := ⟨address 1, address 2⟩
def config : Pipeline.Config :=
  ⟨address 3, ⟨address 4, address 2, address 5⟩,
    ⟨word 0, word 1⟩, address 6, ⟨0, 1, 1, 7⟩, address 1⟩

/-- Physical fixture: nonzero old router balance, positive buffer, disabled
bunker, concrete locator/consensus pointers, one-epoch consensus frame. -/
def before : World :=
  let core := { Verity.defaultState with
    codeSize := fun _ => word 1
    blockTimestamp := word 1 }
  let core := (core.writeContractSlot 1 locatorSlot (word 3)).writeContractSlot
    5 Oracle.consensusSlot (word 6)
  let core := ((core.writeContractSlot 1 activeSlot (word 1)).writeContractSlot
    1 bufferSlot (word 100)).writeContractSlot 4 Queue.bunkerSlot (word (2^256 - 1))
  let core := (core.writeContractSlot 6 7 (word (2^64))).writeContractSlot
    1 seedSlot (word 9)
  ⟨core, fun a => if a = address 1 then 100 else if a = address 2 then 7 else 11, []⟩

def reject : External := fun _ _ => .rejected []
def rejectStatic : StaticCall.External := fun _ _ => .rejected []
def external : External := Pipeline.external (fun _ => word 0) config rejectStatic reject
def positive := run (suffix external context (word 30)) before

/-- Full concrete getter/accounting/receiver path succeeds even though every
unhandled call rejects. Old router wei are retained; a third account is framed. -/
example : positive.outcome = .ok () ∧ positive.world.balances (address 1) = 70 ∧
    positive.world.balances (address 2) = 37 ∧
    positive.world.balances (address 8) = 11 := by
  constructor
  · rfl
  · decide

/-- The final real callback carries exactly the pulled amount to the router. -/
example : positive.attempts.getLast?.map (fun a =>
    (a.request.caller.val, a.request.target.val, a.request.value.val, a.accepted)) =
      some (1, 2, 30, true) := by decide
example : positive.world.logs.getLast?.map (fun e =>
    (e.emitter.val, e.name, e.values.map (·.val))) =
      some (2, "DepositableEthReceived", [30]) := by decide

/-- Zero seed remains 9; a mutation replacing zero by the amount changes it. -/
example : (positive.world.core.readContractSlot 1 seedSlot).val = 9 := by decide
example : ((run (withdrawDepositableEther external context (word 30) (word 30)) before).world.core.readContractSlot 1 seedSlot).val = 39 := by decide

/-- Zero amount does not enter even an always-rejecting withdrawal. -/
example : (run (suffix reject context (word 0)) before).attempts = [] ∧
    (run (suffix reject context (word 0)) before).outcome = .ok () := by
  constructor <;> rfl

/-- Positive amount cannot bypass the source admission path. -/
example : (run (suffix reject context (word 30)) before).outcome ≠ .ok () := by
  intro h
  cases h

/-- Actual Lido funds are load-bearing even with sufficient accounting buffer. -/
example : (run (suffix external context (word 30))
    {before with balances := fun _ => 7}).outcome = .error (.bubbled []) := by rfl

/-- A mismatched immutable Lido makes the real receiver reject. -/
example : (run (suffix
    (Pipeline.external (fun _ => word 0) {config with lido := address 9} rejectStatic reject)
    context (word 30)) before).outcome = .error (.bubbled Router.notAuthorized) := by rfl

/-- Omitted and doubled credits violate the independent equation, including
when the router already held wei. These are specification mutants, not EVM runs. -/
example : ¬ Balances before.balances before.balances (address 1) (address 2) 30 := by
  intro h
  have hc := h.router_credit
  change 7 = 7 + 30 at hc
  omega
example : ¬ Balances before.balances
    (transfer before (address 1) (address 2) 60).balances (address 1) (address 2) 30 := by
  intro h
  have hc := h.router_credit
  change 67 = 7 + 30 at hc
  omega

end LidoSRv3.Tests.TopupLiveWithdrawalMutants

#print axioms LidoSRv3.Audit.Source.TopupLiveWithdrawal.transfer_balances
#print axioms LidoSRv3.Audit.Source.TopupLiveWithdrawal.zero_noop
#print axioms LidoSRv3.Audit.Source.TopupLiveWithdrawal.zero_seed_tail
#print axioms LidoSRv3.Audit.Source.TopupLiveWithdrawal.positive_success
