import LidoSRv3.Audit.Source.TrioReserve1.OptionalCallSpec
import LidoSRv3.Audit.Source.TrioReserve1.ReportParent

namespace LidoSRv3.Audit.Source.TrioReserve1.ReportCalls
open Live

def execute (amount : Nat) (checkWord : Bool) (lookup : Exec Address) (invoke : Address → Exec Bytes) : Exec Unit := do
  if amount > 0 then
    let target ← lookup
    let data ← invoke target
    if checkWord then
      let _ ← decodeWord data
      pure ()
    else pure ()

def Describes (amount : Nat) (checkWord : Bool) (lookup : Exec Address) (invoke : Address → Exec Bytes)
    (before : World) : Except Fault Unit → World → List Attempt → Prop :=
  OptionalCallSpec.Executes .empty List.length amount checkWord
    (fun w outcome after trace => lookup w = ⟨outcome, after, trace⟩)
    (fun target w outcome after trace => invoke target w = ⟨outcome, after, trace⟩) before

theorem of_spec (amount : Nat) (checkWord : Bool) (lookup : Exec Address) (invoke : Address → Exec Bytes)
    (before after : World) (outcome : Except Fault Unit) (trace : List Attempt)
    (h : Describes amount checkWord lookup invoke before outcome after trace) :
    execute amount checkWord lookup invoke before = ⟨outcome, after, trace⟩ := by
  cases h with
  | skipped hz => simp [execute, hz, pure, pureExec]
  | lookup_error hn hl => simp [execute, hn, hl, bind, bindExec]
  | call_error hn hl hc => simp [execute, hn, hl, hc, bind, bindExec]
  | malformed hn hl hc hw hs =>
    simp [execute, hn, hl, hc, hw, bind, bindExec, decodeWord, require, fail, Nat.not_le.mpr hs]
  | success hn hl hc hv =>
    rcases hv with hv | hv
    · simp [execute, hn, hl, hc, hv, bind, bindExec, pure, pureExec]
    · cases checkWord <;> simp [execute, hn, hl, hc, hv, bind, bindExec, decodeWord, require, pure, pureExec]

theorem exists_spec (amount : Nat) (checkWord : Bool) (lookup : Exec Address) (invoke : Address → Exec Bytes)
    (before : World) : ∃ outcome after trace, Describes amount checkWord lookup invoke before outcome after trace := by
  by_cases hn : 0 < amount
  · generalize hl : lookup before = located
    rcases located with ⟨lookupOutcome, lookupWorld, lookupTrace⟩
    cases lookupOutcome with
    | error fault => exact ⟨_, _, _, .lookup_error hn hl⟩
    | ok target =>
      generalize hc : invoke target lookupWorld = called
      rcases called with ⟨callOutcome, callWorld, callTrace⟩
      cases callOutcome with
      | error fault => exact ⟨_, _, _, .call_error hn hl hc⟩
      | ok data =>
        cases checkWord with
        | false => exact ⟨_, _, _, .success hn hl hc (.inl rfl)⟩
        | true =>
          by_cases hs : 32 ≤ data.length
          · exact ⟨_, _, _, .success hn hl hc (.inr hs)⟩
          · exact ⟨_, _, _, .malformed hn hl hc rfl (by omega)⟩
  · exact ⟨_, _, _, .skipped (by omega)⟩

theorem corresponds (amount : Nat) (checkWord : Bool) (lookup : Exec Address) (invoke : Address → Exec Bytes)
    (before after : World) (outcome : Except Fault Unit) (trace : List Attempt) :
    Describes amount checkWord lookup invoke before outcome after trace ↔
      execute amount checkWord lookup invoke before = ⟨outcome, after, trace⟩ := by
  constructor
  · exact of_spec amount checkWord lookup invoke before after outcome trace
  · intro h
    obtain ⟨o, w, t, hd⟩ := exists_spec amount checkWord lookup invoke before
    have he := of_spec amount checkWord lookup invoke before w o t hd
    have hi : o = outcome ∧ w = after ∧ t = trace := by
      simpa only [Result.mk.injEq] using he.symm.trans h
    obtain ⟨rfl, rfl, rfl⟩ := hi
    exact hd

def Rewards (external : External) (ctx : Context) (locator : Address) (input : Report.Inputs) :=
  Describes input.rewards.val true (Report.lookup external ctx locator 0xe441d25f)
    (fun target => CallData.invoke external ctx target (encode 4 0x9342c8f4 ++ encode 32 input.rewards.val))

def Withdrawals (external : External) (ctx : Context) (locator : Address) (input : Report.Inputs) :=
  Describes input.withdrawals.val false (Report.lookup external ctx locator 0x69d42148)
    (fun target => CallData.invoke external ctx target (encode 4 0x3194528a ++ encode 32 input.withdrawals.val))

def Finalize (external : External) (ctx : Context) (locator : Address) (input : Report.Inputs) :=
  Describes input.lockAmount.val false (Report.lookup external ctx locator 0x37d5fe99)
    (fun target => CallData.invoke external ctx target
      (encode 4 0xb6013cef ++ encode 32 input.lastRequest.val ++ encode 32 input.shareRate.val) input.lockAmount)

theorem rewards_corresponds (external : External) (ctx : Context) (locator : Address) (input : Report.Inputs)
    (before after : World) (outcome : Except Fault Unit) (trace : List Attempt) :
    Rewards external ctx locator input before outcome after trace ↔
      ReportStages.rewards external ctx locator input before = ⟨outcome, after, trace⟩ := by
  exact corresponds _ _ _ _ _ _ _ _

theorem withdrawals_corresponds (external : External) (ctx : Context) (locator : Address) (input : Report.Inputs)
    (before after : World) (outcome : Except Fault Unit) (trace : List Attempt) :
    Withdrawals external ctx locator input before outcome after trace ↔
      ReportStages.withdrawals external ctx locator input before = ⟨outcome, after, trace⟩ := by
  exact corresponds _ _ _ _ _ _ _ _

theorem finalize_corresponds (external : External) (ctx : Context) (locator : Address) (input : Report.Inputs)
    (before after : World) (outcome : Except Fault Unit) (trace : List Attempt) :
    Finalize external ctx locator input before outcome after trace ↔
      ReportStages.finalize external ctx locator input before = ⟨outcome, after, trace⟩ := by
  exact corresponds _ _ _ _ _ _ _ _

/-- Expanded parent: independent optional-call stages replace all three opaque
stage observations. Accounting already uses independent arithmetic/write rules.
Locator lookup internals and primitive CALL replies remain the next boundaries. -/
def Parent (external : External) (ctx : Context) (input : Report.Inputs) (before : World) :
    Except Fault Unit → World → List Attempt → Prop :=
  ReportSpec.Executes (.reason "CONTRACT_IS_STOPPED") (.reason "APP_AUTH_FAILED")
    ((before.core.readContractSlot ctx.self.val activeSlot).val ≠ 0) ctx.sender
    (fun w outcome after trace => Report.lookup external ctx (ReportParent.captured ctx before) 0x9624e83e w = ⟨outcome, after, trace⟩)
    (Rewards external ctx (ReportParent.captured ctx before) input)
    (Withdrawals external ctx (ReportParent.captured ctx before) input)
    (Finalize external ctx (ReportParent.captured ctx before) input)
    (fun w outcome after trace => ReportAccounting.Describes ctx input w ⟨outcome, after, trace⟩) before

theorem parent_corresponds (external : External) (ctx : Context) (input : Report.Inputs) (before after : World)
    (outcome : Except Fault Unit) (trace : List Attempt) :
    Parent external ctx input before outcome after trace ↔
      run (Report.collect external ctx input) before = ⟨outcome, after, trace⟩ := by
  have hr : Rewards external ctx (ReportParent.captured ctx before) input =
      (fun w o a t => ReportStages.rewards external ctx (ReportParent.captured ctx before) input w = ⟨o, a, t⟩) := by
    funext w o a t
    exact propext (rewards_corresponds _ _ _ _ _ _ _ _)
  have hw : Withdrawals external ctx (ReportParent.captured ctx before) input =
      (fun w o a t => ReportStages.withdrawals external ctx (ReportParent.captured ctx before) input w = ⟨o, a, t⟩) := by
    funext w o a t
    exact propext (withdrawals_corresponds _ _ _ _ _ _ _ _)
  have hf : Finalize external ctx (ReportParent.captured ctx before) input =
      (fun w o a t => ReportStages.finalize external ctx (ReportParent.captured ctx before) input w = ⟨o, a, t⟩) := by
    funext w o a t
    exact propext (finalize_corresponds _ _ _ _ _ _ _ _)
  unfold Parent
  rw [hr, hw, hf]
  exact ReportParent.corresponds external ctx input before after outcome trace

theorem complete (external : External) (ctx : Context) (input : Report.Inputs) (before : World) :
    let r := run (Report.collect external ctx input) before
    Parent external ctx input before r.outcome r.world r.attempts :=
  (parent_corresponds external ctx input before _ _ _).mpr rfl

theorem failure_restores (external : External) (ctx : Context) (input : Report.Inputs)
    (before after : World) (fault : Fault) (trace : List Attempt)
    (h : Parent external ctx input before (.error fault) after trace) : after = before :=
  ReportSpec.failure_restores h

end LidoSRv3.Audit.Source.TrioReserve1.ReportCalls
