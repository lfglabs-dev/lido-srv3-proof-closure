import LidoSRv3.Audit.Source.TrioReserve1.CallFlow

namespace LidoSRv3.Audit.Source.TrioReserve1.WithdrawalCalls
open Live

abbrev CallObservation := Context → Address → Nat → Word → World → Except Fault Bytes → World → List Attempt → Prop

/-- Parameterized independent stage composition. CALL observations are threaded
through every lookup, status read, allocation query, frame query and receiver. -/
def lookup (calls : CallObservation) (ctx : Context) (selector : Nat) (before : World) :=
  LookupSpec.Returns .empty List.length Lookup.decodedAddress
    (fun w outcome after trace => calls ctx
      (Verity.Core.Address.ofNat (before.core.readContractSlot ctx.self.val locatorSlot).val)
      selector (word 0) w outcome after trace) before

def status (calls : CallObservation) (ctx : Context) (before : World) :=
  StatusSpec.Evaluates .empty List.length (fun data => (word (decode (data.take 32))).val)
    (fun w => (w.core.readContractSlot ctx.self.val activeSlot).val)
    (fun w outcome after trace => lookup calls ctx 0x37d5fe99 w outcome after trace)
    (fun queue w outcome after trace => calls ctx queue 0x2b95b781 (word 0) w outcome after trace) before

def allocation (calls : CallObservation) (ctx : Context) (before : World) :=
  AllocationFlowSpec.Evaluates .empty (AllocationFlow.buffer ctx before) (AllocationFlow.reserve ctx before)
    List.length AllocationFlow.demand Live.Allocation.total Allocation.observe
    (fun w outcome after trace => lookup calls ctx 0x37d5fe99 w outcome after trace)
    (fun queue w outcome after trace => calls ctx queue 0xd0fb84e8 (word 0) w outcome after trace) before

def frame (calls : CallObservation) (ctx : Context) (before : World) :=
  FrameReadSpec.Reads .empty List.length FrameRead.decoded
    (fun w outcome after trace => lookup calls ctx 0x5a2031f9 w outcome after trace)
    (fun target w outcome after trace => calls ctx target 0x72f79b13 (word 0) w outcome after trace) before

def spending (calls : CallObservation) (ctx : Context) (amount : Word) (before : World) :=
  SpendSpec.Executes (.reason "NOT_ENOUGH_ETHER") amount.val (fun a : Live.Allocation => a.deposits + a.unreserved)
    (fun a w => Spending.beforeFrame ctx a amount w) (Spend.committed ctx amount)
    (fun w outcome after trace => allocation calls ctx w outcome after trace)
    (fun w outcome after trace => frame calls ctx w outcome after trace) before

def tail (calls : CallObservation) (ctx : Context) (router : Address) (amount seeds : Word) (before : World) :=
  TailSpec.Finishes (Tail.Seeds ctx seeds)
    (fun w outcome after trace => calls ctx router 0x13ae8460 amount w outcome after trace) before

def withdrawal (calls : CallObservation) (ctx : Context) (amount seeds : Word) (before : World) :=
  WithdrawalSpec.Executes (.reason "CAN_NOT_DEPOSIT") (.reason "APP_AUTH_FAILED") (.reason "ZERO_AMOUNT")
    ctx.sender (amount.val ≠ 0)
    (fun w outcome after trace => status calls ctx w outcome after trace)
    (fun w outcome after trace => lookup calls ctx 0xef6c064c w outcome after trace)
    (fun w outcome after trace => spending calls ctx amount w outcome after trace)
    (fun router w outcome after trace => tail calls ctx router amount seeds w outcome after trace) before

/-- All high-level CALLs use independent code/funds/transfer/reply rules. No source
stage executor or `Live.call` occurs in the expanded relation. The explicit raw
External interpreter remains the deployed-callee/primitive binding obligation. -/
def Describes (external : External) (ctx : Context) (amount seeds : Word) (before : World) :=
  withdrawal (CallFlow.Describes external) ctx amount seeds before

theorem call_observations (external : External) :
    CallFlow.Describes external =
      (fun ctx target selector value before outcome after trace =>
        call external ctx target selector value before = ⟨outcome, after, trace⟩) := by
  funext ctx target selector value before outcome after trace
  exact propext (CallFlow.corresponds external ctx target selector value before after outcome trace)

/-- Full internal withdrawal and high-level CALL correspondence, preserving exact
return/fault, physical world and ordered direct/nested attempts. The raw callee
interpreter is not asserted to be deployed bytecode or an EVM resource model. -/
theorem corresponds (external : External) (ctx : Context) (amount seeds : Word)
    (before after : World) (outcome : Except Fault Unit) (trace : List Attempt) :
    Describes external ctx amount seeds before outcome after trace ↔
      run (withdrawDepositableEther external ctx amount seeds) before = ⟨outcome, after, trace⟩ := by
  unfold Describes
  rw [call_observations]
  exact AllocationFlow.withdrawal_corresponds external ctx amount seeds before after outcome trace

theorem complete (external : External) (ctx : Context) (amount seeds : Word) (before : World) :
    let result := run (withdrawDepositableEther external ctx amount seeds) before
    Describes external ctx amount seeds before result.outcome result.world result.attempts := by
  apply (corresponds external ctx amount seeds before _ _ _).mpr
  rfl

theorem failure_restores (external : External) (ctx : Context) (amount seeds : Word)
    (before after : World) (fault : Fault) (trace : List Attempt)
    (h : Describes external ctx amount seeds before (.error fault) after trace) : after = before :=
  WithdrawalSpec.failure_restores h

theorem success_nonzero (external : External) (ctx : Context) (amount seeds : Word)
    (before after : World) (trace : List Attempt)
    (h : Describes external ctx amount seeds before (.ok ()) after trace) : amount.val ≠ 0 :=
  WithdrawalSpec.success_nonzero h

end LidoSRv3.Audit.Source.TrioReserve1.WithdrawalCalls
