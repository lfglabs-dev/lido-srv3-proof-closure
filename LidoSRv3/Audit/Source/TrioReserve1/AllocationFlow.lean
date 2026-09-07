import LidoSRv3.Audit.Source.TrioReserve1.AllocationFlowSpec
import LidoSRv3.Audit.Source.TrioReserve1.FrameRead

namespace LidoSRv3.Audit.Source.TrioReserve1.AllocationFlow
open Live

def buffer (ctx : Context) (before : World) : Nat := (before.core.readContractSlot ctx.self.val bufferSlot).val % width
def reserve (ctx : Context) (before : World) : Nat := (before.core.readContractSlot ctx.self.val reserveSlot).val
def demand (data : Bytes) : Nat := (word (decode (data.take 32))).val

def allocation (ctx : Context) (before : World) (data : Bytes) : Live.Allocation :=
  let total := buffer ctx before
  let deposits := min total (reserve ctx before)
  let withdrawals := min (total - deposits) (demand data)
  ⟨total, deposits, withdrawals, total - deposits - withdrawals⟩

theorem allocation_spec (ctx : Context) (before : World) (data : Bytes) :
    AllocationSpec.Describes (buffer ctx before) (reserve ctx before) (demand data)
      (Allocation.observe (allocation ctx before data)) :=
  AllocationSpec.exists_allocation _ _ _

theorem allocation_unique (ctx : Context) (before : World) (data : Bytes) (a : Live.Allocation)
    (ht : a.total = buffer ctx before)
    (hs : AllocationSpec.Describes (buffer ctx before) (reserve ctx before) (demand data) (Allocation.observe a)) :
    a = allocation ctx before data := by
  have he := AllocationSpec.unique _ _ _ _ _ hs (allocation_spec ctx before data)
  cases a
  simp_all [Allocation.observe, allocation]

def Describes (external : External) (ctx : Context) (before : World) :
    Except Fault Live.Allocation → World → List Attempt → Prop :=
  AllocationFlowSpec.Evaluates .empty (buffer ctx before) (reserve ctx before) List.length demand
    Live.Allocation.total Allocation.observe
    (fun w outcome after trace => Lookup.Describes external ctx 0x37d5fe99 w outcome after trace)
    (fun queue w outcome after trace => call external ctx queue 0xd0fb84e8 (word 0) w = ⟨outcome, after, trace⟩) before

theorem of_spec (external : External) (ctx : Context) (before after : World)
    (outcome : Except Fault Live.Allocation) (trace : List Attempt)
    (h : Describes external ctx before outcome after trace) :
    getBufferedEtherAllocation external ctx before = ⟨outcome, after, trace⟩ := by
  cases h with
  | lookup_error hl =>
    have hlookup := Lookup.of_spec external ctx 0x37d5fe99 before _ _ _ hl
    simp [getBufferedEtherAllocation, Live.read, bind, bindExec, pure, withdrawalQueue, hlookup]
  | call_error hl hc =>
    have hlookup := Lookup.of_spec external ctx 0x37d5fe99 before _ _ _ hl
    simp [getBufferedEtherAllocation, Live.read, bind, bindExec, withdrawalQueue, hlookup, hc]
  | malformed hl hc hn =>
    have hlookup := Lookup.of_spec external ctx 0x37d5fe99 before _ _ _ hl
    simp [getBufferedEtherAllocation, Live.read, bind, bindExec, withdrawalQueue, hlookup, hc,
      decodeWord, require, Nat.not_le.mpr hn, fail]
  | allocated hl hc hn ht hs =>
    have hlookup := Lookup.of_spec external ctx 0x37d5fe99 before _ _ _ hl
    have he := allocation_unique ctx before _ _ ht hs
    rw [he]
    simp [getBufferedEtherAllocation, Live.read, bind, bindExec, withdrawalQueue, hlookup, hc,
      decodeWord, require, hn, pure, pureExec, allocation, buffer, reserve, demand]

theorem exists_spec (external : External) (ctx : Context) (before : World) :
    ∃ outcome after trace, Describes external ctx before outcome after trace := by
  obtain ⟨lookupOutcome, found, left, hl⟩ := Lookup.exists_spec external ctx 0x37d5fe99 before
  cases lookupOutcome with
  | error fault => exact ⟨_, _, _, .lookup_error hl⟩
  | ok queue =>
    generalize hc : call external ctx queue 0xd0fb84e8 (word 0) found = callResult
    rcases callResult with ⟨callOutcome, after, right⟩
    cases callOutcome with
    | error fault => exact ⟨_, _, _, .call_error hl hc⟩
    | ok data =>
      by_cases hn : 32 ≤ data.length
      · exact ⟨_, _, _, .allocated hl hc hn rfl (allocation_spec ctx before data)⟩
      · exact ⟨_, _, _, .malformed hl hc (by omega)⟩

theorem to_spec (external : External) (ctx : Context) (before after : World)
    (outcome : Except Fault Live.Allocation) (trace : List Attempt)
    (h : getBufferedEtherAllocation external ctx before = ⟨outcome, after, trace⟩) :
    Describes external ctx before outcome after trace := by
  obtain ⟨otherOutcome, otherWorld, otherTrace, hd⟩ := exists_spec external ctx before
  have he := of_spec external ctx before otherWorld otherOutcome otherTrace hd
  have hi : otherOutcome = outcome ∧ otherWorld = after ∧ otherTrace = trace := by
    simpa only [Result.mk.injEq] using he.symm.trans h
  obtain ⟨rfl, rfl, rfl⟩ := hi
  exact hd

theorem corresponds (external : External) (ctx : Context) (before after : World)
    (outcome : Except Fault Live.Allocation) (trace : List Attempt) :
    Describes external ctx before outcome after trace ↔ getBufferedEtherAllocation external ctx before = ⟨outcome, after, trace⟩ :=
  ⟨of_spec external ctx before after outcome trace, to_spec external ctx before after outcome trace⟩

def Spending (external : External) (ctx : Context) (amount : Word) (before : World) :
    Except Fault Unit → World → List Attempt → Prop :=
  SpendSpec.Executes (.reason "NOT_ENOUGH_ETHER") amount.val (fun a : Live.Allocation => a.deposits + a.unreserved)
    (fun a w => LidoSRv3.Audit.Source.TrioReserve1.Spending.beforeFrame ctx a amount w) (Spend.committed ctx amount)
    (fun w outcome after trace => Describes external ctx w outcome after trace)
    (fun w outcome after trace => FrameRead.Describes external ctx w outcome after trace) before

theorem spending_corresponds (external : External) (ctx : Context) (amount : Word)
    (before after : World) (outcome : Except Fault Unit) (trace : List Attempt) :
    Spending external ctx amount before outcome after trace ↔
      spendDepositableEther external ctx amount before = ⟨outcome, after, trace⟩ := by
  have he : (fun w outcome after trace => Describes external ctx w outcome after trace) =
      (fun w outcome after trace => getBufferedEtherAllocation external ctx w = ⟨outcome, after, trace⟩) := by
    funext w outcome after trace
    exact propext (corresponds external ctx w after outcome trace)
  unfold Spending
  rw [he]
  exact FrameRead.spending_corresponds external ctx amount before after outcome trace

def Withdrawal (external : External) (ctx : Context) (amount seeds : Word) (before : World) :
    Except Fault Unit → World → List Attempt → Prop :=
  WithdrawalSpec.Executes (.reason "CAN_NOT_DEPOSIT") (.reason "APP_AUTH_FAILED") (.reason "ZERO_AMOUNT")
    ctx.sender (amount.val ≠ 0)
    (fun w outcome after trace => Lookup.Status external ctx w outcome after trace)
    (fun w outcome after trace => Lookup.Describes external ctx 0xef6c064c w outcome after trace)
    (fun w outcome after trace => Spending external ctx amount w outcome after trace)
    (fun router w outcome after trace => Tail.Describes external ctx router amount seeds w outcome after trace) before

/-- Every major internal withdrawal stage is now expanded into independent
ordered/arithmetic rules and physical projections. The remaining source execution
boundaries are CALLs; primitive and deployed-callee interpretation are still open. -/
theorem withdrawal_corresponds (external : External) (ctx : Context) (amount seeds : Word)
    (before after : World) (outcome : Except Fault Unit) (trace : List Attempt) :
    Withdrawal external ctx amount seeds before outcome after trace ↔
      run (withdrawDepositableEther external ctx amount seeds) before = ⟨outcome, after, trace⟩ := by
  have he : (fun w outcome after trace => Spending external ctx amount w outcome after trace) =
      (fun w outcome after trace => spendDepositableEther external ctx amount w = ⟨outcome, after, trace⟩) := by
    funext w outcome after trace
    exact propext (spending_corresponds external ctx amount w after outcome trace)
  unfold Withdrawal
  rw [he]
  exact Tail.withdrawal_corresponds external ctx amount seeds before after outcome trace

end LidoSRv3.Audit.Source.TrioReserve1.AllocationFlow
