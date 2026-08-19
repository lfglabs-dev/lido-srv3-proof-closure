namespace LidoSRv3.Audit.ReserveRelational

/-!
Abstract plane of `P-RESERVE-RELATIONAL` for Lido core
`af095e48bbc1c3841c2c9936219c8461af01056b`.

The report supplies the already-computed, ascending finalization batch ends
and the queue supplies the nominal/discounted ETH and burnable shares for each
batch.  The model covers the data-flow boundary shared by
`Accounting._calculateWithdrawals`, `WithdrawalQueue.prefinalize`, and
`WithdrawalQueue._finalize`.  In particular, `depositsReserve` is deliberately
state, not an input to finalization.

The observables are the five values a caller can distinguish: the per-batch
prefinalized request-id ranges, the prefinalized ETH, the shares to burn, the
finalized range, and the post-state locked ETH.
-/

structure Batch where
  endRequestId : Nat
  nominalEth : Nat
  discountedEth : Nat
  shares : Nat
  deriving DecidableEq, Repr

structure Queue where
  lastFinalizedRequestId : Nat
  batches : List Batch
  paused : Bool
  deriving DecidableEq, Repr

structure Report where
  batchEnds : List Nat
  useDiscount : Bool
  deriving DecidableEq, Repr

structure State where
  depositsReserve : Nat
  lockedEth : Nat
  deriving DecidableEq, Repr

structure Inputs where
  report : Report
  queue : Queue
  buffer : Nat
  deriving DecidableEq, Repr

structure Observables where
  prefinalizedRanges : List (Nat × Nat)
  prefinalizedEth : Nat
  sharesToBurn : Nat
  finalizedRange : Option (Nat × Nat)
  lockedEtherAfter : Nat
  deriving DecidableEq, Repr

inductive Outcome where
  | reverted (before : State)
  | committed (after : State) (observables : Observables)
  deriving DecidableEq, Repr

def batchEth (discount : Bool) (batch : Batch) : Nat :=
  if discount then batch.discountedEth else batch.nominalEth

def lookupBatch : List Batch → Nat → Option Batch
  | [], _ => none
  | batch :: rest, id =>
      if batch.endRequestId = id then some batch else lookupBatch rest id

def selectBatches (queue : Queue) (report : Report) : Option (List Batch) :=
  report.batchEnds.mapM fun id => lookupBatch queue.batches id

/-- Each requested batch covers the ids strictly after the previous batch end,
starting from the last finalized request. -/
def batchRanges : Nat → List Batch → List (Nat × Nat)
  | _, [] => []
  | cursor, batch :: rest => (cursor + 1, batch.endRequestId) :: batchRanges batch.endRequestId rest

def lockFor (queue : Queue) (report : Report) : Option Nat := do
  let selected ← selectBatches queue report
  pure (selected.map (batchEth report.useDiscount)).sum

def sharesFor (queue : Queue) (report : Report) : Option Nat := do
  let selected ← selectBatches queue report
  pure (selected.map Batch.shares).sum

def requestedRange (queue : Queue) (report : Report) : Option (Nat × Nat) := do
  let last ← report.batchEnds.getLast?
  pure (queue.lastFinalizedRequestId + 1, last)

def abstractPrefinalize (report : Report) (queue : Queue) :
    Option (List (Nat × Nat) × Nat × Nat × (Nat × Nat)) :=
  match selectBatches queue report, requestedRange queue report with
  | some selected, some range =>
      some (batchRanges queue.lastFinalizedRequestId selected,
        (selected.map (batchEth report.useDiscount)).sum,
        (selected.map Batch.shares).sum,
        range)
  | _, _ => none

/-- Abstract transaction. Reverts preserve the complete state. -/
def spec (inputs : Inputs) (before : State) : Outcome :=
  if inputs.queue.paused || inputs.report.batchEnds.isEmpty then .reverted before
  else match abstractPrefinalize inputs.report inputs.queue with
    | some (ranges, eth, shares, range) =>
        if eth ≤ inputs.buffer then
          let after := { before with lockedEth := before.lockedEth + eth }
          .committed after ⟨ranges, eth, shares, some range, after.lockedEth⟩
        else .reverted before
    | none => .reverted before

def differOnlyInReserve (left right : State) : Prop :=
  left.lockedEth = right.lockedEth

def outcomeObservables : Outcome → Option Observables
  | .reverted _ => none
  | .committed _ observables => some observables

theorem reserve_relational (inputs : Inputs) (left right : State)
    (h : differOnlyInReserve left right) :
    outcomeObservables (spec inputs left) = outcomeObservables (spec inputs right) := by
  rcases left with ⟨leftReserve, leftLocked⟩
  rcases right with ⟨rightReserve, rightLocked⟩
  simp [differOnlyInReserve] at h
  subst rightLocked
  simp only [spec]
  split <;> try rfl
  cases hl : abstractPrefinalize inputs.report inputs.queue with
  | none => simp [outcomeObservables]
  | some quad =>
      rcases quad with ⟨ranges, eth, shares, range⟩
      by_cases hb : eth ≤ inputs.buffer <;>
        simp [hb, outcomeObservables]

end LidoSRv3.Audit.ReserveRelational
