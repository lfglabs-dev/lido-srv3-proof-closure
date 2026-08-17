import LidoSRv3.Audit.Model.ReserveRelational

namespace LidoSRv3.Audit.ReserveRelational

/-!
Separate source-shaped interpreter for the pinned paths:

* `Accounting.sol:250-261` (`_calculateWithdrawals`);
* `WithdrawalQueueBase.sol:288-328` (`prefinalize`); and
* `WithdrawalQueueBase.sol:330-359` (`_finalize`).

It intentionally does not call `spec`, `lockFor`, `requestedRange`, or
`lookupBatch`.  This first slice does not claim executable Verity computation,
cross-contract composition, or rollback after an intermediate storage write.
-/

def sourceFindBatch (id : Nat) : List Batch → Option Batch
  | [] => none
  | batch :: rest =>
      if id = batch.endRequestId then some batch else sourceFindBatch id rest

def sourceSum (discount : Bool) : List Batch → Nat
  | [] => 0
  | batch :: rest =>
      (if discount then batch.discountedEth else batch.nominalEth) + sourceSum discount rest

def sourcePrefinalize (report : Report) (queue : Queue) : Option (Nat × (Nat × Nat)) := do
  let _ ← report.batchEnds.head?
  let last ← report.batchEnds.getLast?
  let selected ← report.batchEnds.mapM fun endId => sourceFindBatch endId queue.batches
  let locked := sourceSum report.useDiscount selected
  pure (locked, (queue.lastFinalizedRequestId + 1, last))

def sourceRun (inputs : Inputs) (before : State) : Outcome :=
  if inputs.queue.paused then .reverted before
  else match sourcePrefinalize inputs.report inputs.queue with
    | none => .reverted before
    | some (amount, range) =>
        if amount ≤ inputs.buffer then
          let nextLocked := before.lockedEth + amount
          let after := { before with lockedEth := nextLocked }
          .committed after ⟨some range, some range, nextLocked⟩
        else .reverted before

theorem sourceFindBatch_eq_lookupBatch (id : Nat) (batches : List Batch) :
    sourceFindBatch id batches = lookupBatch batches id := by
  induction batches with
  | nil => rfl
  | cons batch rest ih =>
      simp only [sourceFindBatch, lookupBatch]
      by_cases h : id = batch.endRequestId
      · simp [h]
      · simp [h, Ne.symm h, ih]

private theorem sourceSum_eq_sum (discount : Bool) (batches : List Batch) :
    sourceSum discount batches =
      (batches.map (batchEth discount)).sum := by
  induction batches with
  | nil => rfl
  | cons batch rest ih => simp [sourceSum, batchEth, ih]

theorem sourcePrefinalize_correspondence (report : Report) (queue : Queue) :
    sourcePrefinalize report queue = abstractPrefinalize report queue := by
  rcases report with ⟨batchEnds, discount⟩
  cases batchEnds with
  | nil => simp [sourcePrefinalize, abstractPrefinalize, lockFor, requestedRange]
  | cons first rest =>
      cases hs : List.mapM (fun id => lookupBatch queue.batches id) (first :: rest) <;>
        cases hg : (first :: rest).getLast? <;>
          simp [sourcePrefinalize, abstractPrefinalize, lockFor, requestedRange,
            sourceFindBatch_eq_lookupBatch, sourceSum_eq_sum, hs, hg]

theorem source_run_correspondence (inputs : Inputs) (before : State) :
    sourceRun inputs before = spec inputs before := by
  rcases inputs with ⟨report, queue, buffer⟩
  rcases report with ⟨batchEnds, discount⟩
  rcases queue with ⟨lastFinalized, batches, paused⟩
  cases paused with
  | true => simp [sourceRun, spec]
  | false =>
      cases batchEnds with
      | nil =>
          simp [sourceRun, spec, sourcePrefinalize_correspondence,
            abstractPrefinalize, lockFor, requestedRange]
      | cons head tail =>
          simp [sourceRun, spec, sourcePrefinalize_correspondence]
          cases abstractPrefinalize
              { batchEnds := head :: tail, useDiscount := discount }
              { lastFinalizedRequestId := lastFinalized, batches := batches, paused := false } <;>
            simp

theorem source_reserve_relational (inputs : Inputs) (left right : State)
    (h : differOnlyInReserve left right) :
    outcomeObservables (sourceRun inputs left) =
      outcomeObservables (sourceRun inputs right) := by
  rw [source_run_correspondence, source_run_correspondence]
  exact reserve_relational inputs left right h

end LidoSRv3.Audit.ReserveRelational
