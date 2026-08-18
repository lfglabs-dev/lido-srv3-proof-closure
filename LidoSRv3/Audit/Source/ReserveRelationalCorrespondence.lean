import LidoSRv3.Audit.Model.ReserveRelational

namespace LidoSRv3.Audit.ReserveRelational

/-!
Separate source-shaped interpreter for the pinned paths:

* `Accounting.sol:250-261` (`_calculateWithdrawals`);
* `WithdrawalQueueBase.sol:288-328` (`prefinalize`); and
* `WithdrawalQueueBase.sol:330-359` (`_finalize`).

It intentionally does not call `spec`, `lockFor`, `sharesFor`, `requestedRange`,
`batchRanges`, or `lookupBatch`; the correspondence theorems below, not shared
names, tie the two planes together.  The executable Verity transaction that
computes the same five observables from contract storage lives in
`LidoSRv3.Audit.Verity.ReserveRelationalTx`.
-/

def sourceFindBatch (id : Nat) : List Batch → Option Batch
  | [] => none
  | batch :: rest =>
      if id = batch.endRequestId then some batch else sourceFindBatch id rest

def sourceSum (discount : Bool) : List Batch → Nat
  | [] => 0
  | batch :: rest =>
      (if discount then batch.discountedEth else batch.nominalEth) + sourceSum discount rest

def sourceShareSum : List Batch → Nat
  | [] => 0
  | batch :: rest => batch.shares + sourceShareSum rest

def sourceRanges (cursor : Nat) : List Batch → List (Nat × Nat)
  | [] => []
  | batch :: rest => (cursor + 1, batch.endRequestId) :: sourceRanges batch.endRequestId rest

def sourceSelect (report : Report) (queue : Queue) : Option (List Batch) :=
  report.batchEnds.mapM fun endId => sourceFindBatch endId queue.batches

def sourcePrefinalize (report : Report) (queue : Queue) :
    Option (List (Nat × Nat) × Nat × Nat × (Nat × Nat)) := do
  let _ ← report.batchEnds.head?
  let last ← report.batchEnds.getLast?
  let selected ← sourceSelect report queue
  pure (sourceRanges queue.lastFinalizedRequestId selected,
    sourceSum report.useDiscount selected,
    sourceShareSum selected,
    (queue.lastFinalizedRequestId + 1, last))

def sourceRun (inputs : Inputs) (before : State) : Outcome :=
  if inputs.queue.paused then .reverted before
  else match sourcePrefinalize inputs.report inputs.queue with
    | none => .reverted before
    | some (ranges, eth, shares, range) =>
        if eth ≤ inputs.buffer then
          let nextLocked := before.lockedEth + eth
          let after := { before with lockedEth := nextLocked }
          .committed after ⟨ranges, eth, shares, some range, nextLocked⟩
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

theorem sourceSelect_eq_selectBatches (report : Report) (queue : Queue) :
    sourceSelect report queue = selectBatches queue report := by
  simp [sourceSelect, selectBatches, sourceFindBatch_eq_lookupBatch]

private theorem sourceSum_eq_sum (discount : Bool) (batches : List Batch) :
    sourceSum discount batches =
      (batches.map (batchEth discount)).sum := by
  induction batches with
  | nil => rfl
  | cons batch rest ih => simp [sourceSum, batchEth, ih]

private theorem sourceShareSum_eq_sum (batches : List Batch) :
    sourceShareSum batches = (batches.map Batch.shares).sum := by
  induction batches with
  | nil => rfl
  | cons batch rest ih => simp [sourceShareSum, ih]

private theorem sourceRanges_eq_batchRanges (cursor : Nat) (batches : List Batch) :
    sourceRanges cursor batches = batchRanges cursor batches := by
  induction batches generalizing cursor with
  | nil => rfl
  | cons batch rest ih => simp [sourceRanges, batchRanges, ih]

theorem sourcePrefinalize_correspondence (report : Report) (queue : Queue) :
    sourcePrefinalize report queue = abstractPrefinalize report queue := by
  rcases report with ⟨batchEnds, discount⟩
  cases batchEnds with
  | nil =>
      simp [sourcePrefinalize, abstractPrefinalize, sourceSelect, selectBatches, requestedRange]
  | cons first rest =>
      cases hs : selectBatches queue ⟨first :: rest, discount⟩ <;>
        cases hg : (first :: rest).getLast? <;>
          simp [sourcePrefinalize, abstractPrefinalize, sourceSelect_eq_selectBatches,
            requestedRange, sourceSum_eq_sum, sourceShareSum_eq_sum,
            sourceRanges_eq_batchRanges, hs, hg]

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
            abstractPrefinalize, selectBatches, requestedRange]
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
