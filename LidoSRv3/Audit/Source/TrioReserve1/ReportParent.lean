import LidoSRv3.Audit.Source.TrioReserve1.ReportSpec
import LidoSRv3.Audit.Source.TrioReserve1.ReportStages
import LidoSRv3.Audit.Source.TrioReserve1.ReportAccounting

namespace LidoSRv3.Audit.Source.TrioReserve1.ReportParent
open Live

def captured (ctx : Context) (before : World) : Address :=
  Verity.Core.Address.ofNat (before.core.readContractSlot ctx.self.val locatorSlot).val

/-- Stage relations retain the originally captured locator. The final accounting
stage is already replaced by independent arithmetic and physical write rules;
conditional callee-stage internals remain explicit source observations here. -/
def Describes (external : External) (ctx : Context) (input : Report.Inputs) (before : World) :
    Except Fault Unit → World → List Attempt → Prop :=
  ReportSpec.Executes (.reason "CONTRACT_IS_STOPPED") (.reason "APP_AUTH_FAILED")
    ((before.core.readContractSlot ctx.self.val activeSlot).val ≠ 0) ctx.sender
    (fun w outcome after trace => Report.lookup external ctx (captured ctx before) 0x9624e83e w = ⟨outcome, after, trace⟩)
    (fun w outcome after trace => ReportStages.rewards external ctx (captured ctx before) input w = ⟨outcome, after, trace⟩)
    (fun w outcome after trace => ReportStages.withdrawals external ctx (captured ctx before) input w = ⟨outcome, after, trace⟩)
    (fun w outcome after trace => ReportStages.finalize external ctx (captured ctx before) input w = ⟨outcome, after, trace⟩)
    (fun w outcome after trace => ReportAccounting.Describes ctx input w ⟨outcome, after, trace⟩)
    before

theorem accounting_observations (ctx : Context) (input : Report.Inputs) :
    (fun w outcome after trace => ReportAccounting.Describes ctx input w ⟨outcome, after, trace⟩) =
      (fun w outcome after trace => Report.afterCalls ctx input w = ⟨outcome, after, trace⟩) := by
  funext w outcome after trace
  exact propext (ReportAccounting.corresponds ctx input w ⟨outcome, after, trace⟩)

theorem of_spec (external : External) (ctx : Context) (input : Report.Inputs) (before after : World)
    (outcome : Except Fault Unit) (trace : List Attempt)
    (h : Describes external ctx input before outcome after trace) :
    run (Report.collect external ctx input) before = ⟨outcome, after, trace⟩ := by
  unfold Describes at h
  rw [accounting_observations] at h
  cases h <;>
    simp_all [run, ReportStages.source_decomposition, getLidoLocator, Live.read, captured,
      bind, bindExec, require, pure, pureExec, fail, List.append_assoc]

theorem exists_spec (external : External) (ctx : Context) (input : Report.Inputs) (before : World) :
    ∃ outcome after trace, Describes external ctx input before outcome after trace := by
  unfold Describes
  rw [accounting_observations]
  by_cases ha : (before.core.readContractSlot ctx.self.val activeSlot).val ≠ 0
  · generalize hl : Report.lookup external ctx (captured ctx before) 0x9624e83e before = lookupResult
    rcases lookupResult with ⟨lookupOutcome, lookupWorld, lookupTrace⟩
    cases lookupOutcome with
    | error fault => exact ⟨_, _, _, .lookup_error ha hl⟩
    | ok address =>
      by_cases he : ctx.sender = address
      · generalize hr : ReportStages.rewards external ctx (captured ctx before) input lookupWorld = rewardResult
        rcases rewardResult with ⟨rewardOutcome, rewardWorld, rewardTrace⟩
        cases rewardOutcome with
        | error fault => exact ⟨_, _, _, .rewards_error ha hl he hr⟩
        | ok value =>
          cases value
          generalize hw : ReportStages.withdrawals external ctx (captured ctx before) input rewardWorld = withdrawalResult
          rcases withdrawalResult with ⟨withdrawalOutcome, withdrawalWorld, withdrawalTrace⟩
          cases withdrawalOutcome with
          | error fault => exact ⟨_, _, _, .withdrawals_error ha hl he hr hw⟩
          | ok value =>
            cases value
            generalize hf : ReportStages.finalize external ctx (captured ctx before) input withdrawalWorld = finalizationResult
            rcases finalizationResult with ⟨finalizationOutcome, finalizationWorld, finalizationTrace⟩
            cases finalizationOutcome with
            | error fault => exact ⟨_, _, _, .finalize_error ha hl he hr hw hf⟩
            | ok value =>
              cases value
              generalize ht : Report.afterCalls ctx input finalizationWorld = tailResult
              rcases tailResult with ⟨tailOutcome, tailWorld, tailTrace⟩
              cases tailOutcome with
              | error fault => exact ⟨_, _, _, .accounting_error ha hl he hr hw hf ht⟩
              | ok value => cases value; exact ⟨_, _, _, .finished ha hl he hr hw hf ht⟩
      · exact ⟨_, _, _, .unauthorized ha hl he⟩
  · exact ⟨_, _, _, .stopped ha⟩

theorem to_spec (external : External) (ctx : Context) (input : Report.Inputs) (before after : World)
    (outcome : Except Fault Unit) (trace : List Attempt)
    (h : run (Report.collect external ctx input) before = ⟨outcome, after, trace⟩) :
    Describes external ctx input before outcome after trace := by
  obtain ⟨otherOutcome, otherWorld, otherTrace, hd⟩ := exists_spec external ctx input before
  have he := of_spec external ctx input before otherWorld otherOutcome otherTrace hd
  have hi : otherOutcome = outcome ∧ otherWorld = after ∧ otherTrace = trace := by
    simpa only [Result.mk.injEq] using he.symm.trans h
  obtain ⟨rfl, rfl, rfl⟩ := hi
  exact hd

theorem corresponds (external : External) (ctx : Context) (input : Report.Inputs) (before after : World)
    (outcome : Except Fault Unit) (trace : List Attempt) :
    Describes external ctx input before outcome after trace ↔
      run (Report.collect external ctx input) before = ⟨outcome, after, trace⟩ :=
  ⟨of_spec external ctx input before after outcome trace, to_spec external ctx input before after outcome trace⟩

theorem complete (external : External) (ctx : Context) (input : Report.Inputs) (before : World) :
    let r := run (Report.collect external ctx input) before
    Describes external ctx input before r.outcome r.world r.attempts :=
  (corresponds external ctx input before _ _ _).mpr rfl

theorem failure_restores (external : External) (ctx : Context) (input : Report.Inputs)
    (before after : World) (fault : Fault) (trace : List Attempt)
    (h : Describes external ctx input before (.error fault) after trace) : after = before :=
  ReportSpec.failure_restores h

end LidoSRv3.Audit.Source.TrioReserve1.ReportParent
