import LidoSRv3.Audit.Source.TrioReserve1.ReportLookup

namespace LidoSRv3.Audit.Source.TrioReserve1.ReportRules
open Live

def stage (external : External) (ctx : Context) (locator : Address) (amount : Nat)
    (checkWord : Bool) (lookupSelector : Nat) (payload : Bytes) (value : Word) (before : World) :
    Except Fault Unit → World → List Attempt → Prop :=
  OptionalCallSpec.Executes .empty List.length amount checkWord
    (ReportLookup.Describes external ctx locator lookupSelector)
    (fun target => CallDataFlow.Describes external ctx target payload value) before

theorem lookup_observations (external : External) (ctx : Context) (locator : Address) (selector : Nat) :
    ReportLookup.Describes external ctx locator selector =
      (fun w outcome after trace => Report.lookup external ctx locator selector w = ⟨outcome, after, trace⟩) := by
  funext w outcome after trace
  exact propext (ReportLookup.corresponds external ctx locator selector w after outcome trace)

theorem call_observations (external : External) (ctx : Context) (payload : Bytes) (value : Word) :
    (fun target => CallDataFlow.Describes external ctx target payload value) =
      (fun target w outcome after trace => CallData.invoke external ctx target payload value w = ⟨outcome, after, trace⟩) := by
  funext target w outcome after trace
  exact propext (CallDataFlow.corresponds external ctx target payload value w after outcome trace)

theorem stage_observations (external : External) (ctx : Context) (locator : Address) (amount : Nat)
    (checkWord : Bool) (lookupSelector : Nat) (payload : Bytes) (value : Word) :
    stage external ctx locator amount checkWord lookupSelector payload value =
      ReportCalls.Describes amount checkWord (Report.lookup external ctx locator lookupSelector)
        (fun target => CallData.invoke external ctx target payload value) := by
  unfold stage ReportCalls.Describes
  rw [lookup_observations, call_observations]

/-- Fully expanded report relation: independent parent order, optional-stage and
getter decoding rules, full-payload CALL rules and accounting rules. The remaining
semantic boundary is the raw external primitive reply interpreter; no report
stage executor or source CALL is used by the expanded predicate. -/
def Describes (external : External) (ctx : Context) (input : Report.Inputs) (before : World) :
    Except Fault Unit → World → List Attempt → Prop :=
  let locator := ReportParent.captured ctx before
  ReportSpec.Executes (.reason "CONTRACT_IS_STOPPED") (.reason "APP_AUTH_FAILED")
    ((before.core.readContractSlot ctx.self.val activeSlot).val ≠ 0) ctx.sender
    (ReportLookup.Describes external ctx locator 0x9624e83e)
    (stage external ctx locator input.rewards.val true 0xe441d25f
      (encode 4 0x9342c8f4 ++ encode 32 input.rewards.val) (word 0))
    (stage external ctx locator input.withdrawals.val false 0x69d42148
      (encode 4 0x3194528a ++ encode 32 input.withdrawals.val) (word 0))
    (stage external ctx locator input.lockAmount.val false 0x37d5fe99
      (encode 4 0xb6013cef ++ encode 32 input.lastRequest.val ++ encode 32 input.shareRate.val) input.lockAmount)
    (fun w outcome after trace => ReportAccounting.Describes ctx input w ⟨outcome, after, trace⟩) before

theorem corresponds (external : External) (ctx : Context) (input : Report.Inputs) (before after : World)
    (outcome : Except Fault Unit) (trace : List Attempt) :
    Describes external ctx input before outcome after trace ↔
      run (Report.collect external ctx input) before = ⟨outcome, after, trace⟩ := by
  unfold Describes
  rw [lookup_observations]
  simp only [stage_observations]
  exact ReportCalls.parent_corresponds external ctx input before after outcome trace

theorem complete (external : External) (ctx : Context) (input : Report.Inputs) (before : World) :
    let r := run (Report.collect external ctx input) before
    Describes external ctx input before r.outcome r.world r.attempts :=
  (corresponds external ctx input before _ _ _).mpr rfl

theorem failure_restores (external : External) (ctx : Context) (input : Report.Inputs)
    (before after : World) (fault : Fault) (trace : List Attempt)
    (h : Describes external ctx input before (.error fault) after trace) : after = before :=
  ReportSpec.failure_restores h

theorem success_active (external : External) (ctx : Context) (input : Report.Inputs)
    (before after : World) (trace : List Attempt)
    (h : Describes external ctx input before (.ok ()) after trace) :
    (before.core.readContractSlot ctx.self.val activeSlot).val ≠ 0 :=
  ReportSpec.success_active h

end LidoSRv3.Audit.Source.TrioReserve1.ReportRules
