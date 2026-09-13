import LidoSRv3.Audit.Model.ReserveRelational

/-!
Kill-lines pinning `Model.ReserveRelational` spec transaction, outcome
distinctness, `outcomeObservables`, `differOnlyInReserve`,
`abstractPrefinalize` and `spec` reverting branches.
-/

namespace LidoSRv3.Tests.ModelReserveRelationalSpecOutcomeKillLines

open LidoSRv3.Audit.ReserveRelational

private def emptyQueue : Queue :=
  { lastFinalizedRequestId := 0, batches := [], paused := false }

private def emptyReport : Report :=
  { batchEnds := [], useDiscount := false }

private def pausedQueue : Queue :=
  { lastFinalizedRequestId := 0, batches := [], paused := true }

private def zeroState : State :=
  { depositsReserve := 0, lockedEth := 0 }

/-! ## `Outcome` — two-arm inductive distinctness. -/

theorem outcome_reverted_ne_committed :
    (Outcome.reverted zeroState) ≠
      Outcome.committed zeroState
        { prefinalizedRanges := [], prefinalizedEth := 0, sharesToBurn := 0
          finalizedRange := none, lockedEtherAfter := 0 } := by
  decide

/-! ## `outcomeObservables` — reverted has no observables. -/

theorem outcomeObservables_reverted :
    outcomeObservables (.reverted zeroState) = none := rfl

theorem outcomeObservables_committed :
    outcomeObservables
      (.committed zeroState
        { prefinalizedRanges := [], prefinalizedEth := 0, sharesToBurn := 0
          finalizedRange := none, lockedEtherAfter := 0 }) =
      some
        { prefinalizedRanges := [], prefinalizedEth := 0, sharesToBurn := 0
          finalizedRange := none, lockedEtherAfter := 0 } := rfl

/-! ## `spec` reverts when queue paused. -/

theorem spec_reverts_when_paused :
    spec { report := emptyReport, queue := pausedQueue, buffer := 100 }
        zeroState = .reverted zeroState := by
  decide

/-! ## `spec` reverts when batchEnds empty. -/

theorem spec_reverts_when_report_empty :
    spec { report := emptyReport, queue := emptyQueue, buffer := 100 }
        zeroState = .reverted zeroState := by
  decide

/-! ## `differOnlyInReserve` is symmetric on lockedEth. -/

theorem differOnlyInReserve_refl (s : State) :
    differOnlyInReserve s s := rfl

theorem differOnlyInReserve_symm (l r : State)
    (h : differOnlyInReserve l r) : differOnlyInReserve r l :=
  h.symm

/-! ## `abstractPrefinalize` reverts on empty report. -/

theorem abstractPrefinalize_none_on_empty :
    abstractPrefinalize emptyReport emptyQueue = none := by
  decide

/-! ## `Batch`/`Queue`/`Report`/`State`/`Inputs`/`Observables` decEq. -/

theorem batch_decEq_self :
    (decide
      (({ endRequestId := 0, nominalEth := 0, discountedEth := 0, shares := 0 } : Batch) =
       { endRequestId := 0, nominalEth := 0, discountedEth := 0, shares := 0 })) = true := by
  decide

theorem state_decEq_self :
    (decide (zeroState = zeroState)) = true := by decide

theorem queue_decEq_self :
    (decide (emptyQueue = emptyQueue)) = true := by decide

end LidoSRv3.Tests.ModelReserveRelationalSpecOutcomeKillLines
