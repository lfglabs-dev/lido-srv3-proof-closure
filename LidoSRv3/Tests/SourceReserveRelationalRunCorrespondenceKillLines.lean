import LidoSRv3.Audit.Source.ReserveRelationalCorrespondence

/-!
Kill-lines pinning `Source.ReserveRelationalCorrespondence` `sourceRun`
correspondence to `spec`, `sourceSelect` correspondence to
`selectBatches`, and the reserve-invariance closure on the pinned-
source interpreter.
-/

namespace LidoSRv3.Tests.SourceReserveRelationalRunCorrespondenceKillLines

open LidoSRv3.Audit.ReserveRelational

private def emptyQueue : Queue :=
  { lastFinalizedRequestId := 0, batches := [], paused := false }

private def pausedQueue : Queue :=
  { lastFinalizedRequestId := 0, batches := [], paused := true }

private def emptyReport : Report :=
  { batchEnds := [], useDiscount := false }

private def zeroState : State :=
  { depositsReserve := 0, lockedEth := 0 }

/-! ## `sourceFindBatch = lookupBatch` — restated. -/

theorem sourceFindBatch_eq_lookupBatch_restated
    (id : Nat) (batches : List Batch) :
    sourceFindBatch id batches = lookupBatch batches id :=
  sourceFindBatch_eq_lookupBatch id batches

/-! ## `sourceSelect = selectBatches` — restated. -/

theorem sourceSelect_eq_selectBatches_restated
    (report : Report) (queue : Queue) :
    sourceSelect report queue = selectBatches queue report :=
  sourceSelect_eq_selectBatches report queue

/-! ## `sourcePrefinalize = abstractPrefinalize` — restated. -/

theorem sourcePrefinalize_correspondence_restated
    (report : Report) (queue : Queue) :
    sourcePrefinalize report queue = abstractPrefinalize report queue :=
  sourcePrefinalize_correspondence report queue

/-! ## `source_run_correspondence` — restated. -/

theorem source_run_correspondence_restated (inputs : Inputs) (before : State) :
    sourceRun inputs before = spec inputs before :=
  source_run_correspondence inputs before

/-! ## `source_reserve_relational` — restated. -/

theorem source_reserve_relational_restated
    (inputs : Inputs) (left right : State)
    (h : differOnlyInReserve left right) :
    outcomeObservables (sourceRun inputs left) =
      outcomeObservables (sourceRun inputs right) :=
  source_reserve_relational inputs left right h

/-! ## `sourceRun` reverts on paused queue. -/

theorem sourceRun_reverts_paused :
    sourceRun { report := emptyReport, queue := pausedQueue, buffer := 100 }
        zeroState = .reverted zeroState := by
  decide

/-! ## `sourceRun` reverts on empty batchEnds. -/

theorem sourceRun_reverts_empty_report :
    sourceRun { report := emptyReport, queue := emptyQueue, buffer := 100 }
        zeroState = .reverted zeroState := by
  decide

end LidoSRv3.Tests.SourceReserveRelationalRunCorrespondenceKillLines
