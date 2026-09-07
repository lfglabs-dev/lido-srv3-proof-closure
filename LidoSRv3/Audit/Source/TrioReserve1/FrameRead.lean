import LidoSRv3.Audit.Source.TrioReserve1.FrameReadSpec
import LidoSRv3.Audit.Source.TrioReserve1.Spend

namespace LidoSRv3.Audit.Source.TrioReserve1.FrameRead
open Live

def decoded (data : Bytes) : Nat × Nat :=
  ((word (decode (data.take 32))).val, (word (decode ((data.drop 32).take 32))).val)

/-- Oracle lookup uses the physical locator and independent getter rules; frame
bytes come from the actual oracle CALL, not a supplied nonce/time pair. -/
def Describes (external : External) (ctx : Context) (before : World) :
    Except Fault (Nat × Nat) → World → List Attempt → Prop :=
  FrameReadSpec.Reads .empty List.length decoded
    (fun w outcome after trace => Lookup.Describes external ctx 0x5a2031f9 w outcome after trace)
    (fun target w outcome after trace => call external ctx target 0x72f79b13 (word 0) w = ⟨outcome, after, trace⟩) before

theorem of_spec (external : External) (ctx : Context) (before after : World)
    (outcome : Except Fault (Nat × Nat)) (trace : List Attempt)
    (h : Describes external ctx before outcome after trace) :
    getCurrentFrame external ctx before = ⟨outcome, after, trace⟩ := by
  cases h with
  | lookup_error hl =>
    have hlookup := Lookup.of_spec external ctx 0x5a2031f9 before _ _ _ hl
    simp [getCurrentFrame, bind, bindExec, hlookup]
  | call_error hl hc =>
    have hlookup := Lookup.of_spec external ctx 0x5a2031f9 before _ _ _ hl
    simp [getCurrentFrame, bind, bindExec, hlookup, hc]
  | malformed hl hc hn =>
    have hlookup := Lookup.of_spec external ctx 0x5a2031f9 before _ _ _ hl
    simp [getCurrentFrame, bind, bindExec, hlookup, hc, require, Nat.not_le.mpr hn, fail]
  | decoded hl hc hn =>
    rename_i target located left right data
    have hlookup := Lookup.of_spec external ctx 0x5a2031f9 before _ _ _ hl
    have h32 : 32 ≤ data.length := by omega
    simp [getCurrentFrame, bind, bindExec, hlookup, hc, require, hn, h32, decodeWord, pure, pureExec, decoded]

theorem exists_spec (external : External) (ctx : Context) (before : World) :
    ∃ outcome after trace, Describes external ctx before outcome after trace := by
  obtain ⟨lookupOutcome, located, left, hl⟩ := Lookup.exists_spec external ctx 0x5a2031f9 before
  cases lookupOutcome with
  | error fault => exact ⟨_, _, _, .lookup_error hl⟩
  | ok target =>
    generalize hc : call external ctx target 0x72f79b13 (word 0) located = callResult
    rcases callResult with ⟨callOutcome, after, right⟩
    cases callOutcome with
    | error fault => exact ⟨_, _, _, .call_error hl hc⟩
    | ok data =>
      by_cases hn : 64 ≤ data.length
      · exact ⟨_, _, _, .decoded hl hc hn⟩
      · exact ⟨_, _, _, .malformed hl hc (by omega)⟩

theorem to_spec (external : External) (ctx : Context) (before after : World)
    (outcome : Except Fault (Nat × Nat)) (trace : List Attempt)
    (h : getCurrentFrame external ctx before = ⟨outcome, after, trace⟩) :
    Describes external ctx before outcome after trace := by
  obtain ⟨otherOutcome, otherWorld, otherTrace, hd⟩ := exists_spec external ctx before
  have he := of_spec external ctx before otherWorld otherOutcome otherTrace hd
  have hi : otherOutcome = outcome ∧ otherWorld = after ∧ otherTrace = trace := by
    simpa only [Result.mk.injEq] using he.symm.trans h
  obtain ⟨rfl, rfl, rfl⟩ := hi
  exact hd

theorem corresponds (external : External) (ctx : Context) (before after : World)
    (outcome : Except Fault (Nat × Nat)) (trace : List Attempt) :
    Describes external ctx before outcome after trace ↔ getCurrentFrame external ctx before = ⟨outcome, after, trace⟩ :=
  ⟨of_spec external ctx before after outcome trace, to_spec external ctx before after outcome trace⟩

def Spending (external : External) (ctx : Context) (amount : Word) (before : World) :
    Except Fault Unit → World → List Attempt → Prop :=
  SpendSpec.Executes (.reason "NOT_ENOUGH_ETHER") amount.val (fun a : Live.Allocation => a.deposits + a.unreserved)
    (fun a w => LidoSRv3.Audit.Source.TrioReserve1.Spending.beforeFrame ctx a amount w) (Spend.committed ctx amount)
    (fun w outcome after trace => getBufferedEtherAllocation external ctx w = ⟨outcome, after, trace⟩)
    (fun w outcome after trace => Describes external ctx w outcome after trace) before

theorem spending_corresponds (external : External) (ctx : Context) (amount : Word)
    (before after : World) (outcome : Except Fault Unit) (trace : List Attempt) :
    Spending external ctx amount before outcome after trace ↔
      spendDepositableEther external ctx amount before = ⟨outcome, after, trace⟩ := by
  have he : (fun w outcome after trace => Describes external ctx w outcome after trace) =
      (fun w outcome after trace => getCurrentFrame external ctx w = ⟨outcome, after, trace⟩) := by
    funext w outcome after trace
    exact propext (corresponds external ctx w after outcome trace)
  unfold Spending
  rw [he]
  exact Spend.corresponds external ctx amount before after outcome trace

def Withdrawal (external : External) (ctx : Context) (amount seeds : Word) (before : World) :
    Except Fault Unit → World → List Attempt → Prop :=
  WithdrawalSpec.Executes (.reason "CAN_NOT_DEPOSIT") (.reason "APP_AUTH_FAILED") (.reason "ZERO_AMOUNT")
    ctx.sender (amount.val ≠ 0)
    (fun w outcome after trace => Lookup.Status external ctx w outcome after trace)
    (fun w outcome after trace => Lookup.Describes external ctx 0xef6c064c w outcome after trace)
    (fun w outcome after trace => Spending external ctx amount w outcome after trace)
    (fun router w outcome after trace => Tail.Describes external ctx router amount seeds w outcome after trace) before

/-- Oracle lookup and complete tuple-decoding semantics are substituted all the
way through spending into withdrawal. Allocation and CALL/deployed interpretation
remain explicit boundaries, including actual oracle/consensus implementation binding. -/
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

end LidoSRv3.Audit.Source.TrioReserve1.FrameRead
