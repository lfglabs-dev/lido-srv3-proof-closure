namespace LidoSRv3.Audit.ReserveRelational

/-!
Independent first slice of `P-RESERVE-RELATIONAL` for Lido core
`af095e48bbc1c3841c2c9936219c8461af01056b`.

The report supplies the already-computed, ascending finalization batch ends
and the queue supplies the nominal/discounted ETH for each batch.  The model
covers the data-flow boundary shared by `Accounting._calculateWithdrawals`,
`WithdrawalQueue.prefinalize`, and `WithdrawalQueue._finalize`.  In particular,
`depositsReserve` is deliberately state, not an input to finalization.
-/

structure Batch where
  endRequestId : Nat
  nominalEth : Nat
  discountedEth : Nat
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
  prefinalizedRange : Option (Nat × Nat)
  finalizedRange : Option (Nat × Nat)
  lockedEth : Nat
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

def lockFor (queue : Queue) (report : Report) : Option Nat := do
  let selected ← report.batchEnds.mapM fun id => lookupBatch queue.batches id
  pure (selected.map (batchEth report.useDiscount)).sum

def requestedRange (queue : Queue) (report : Report) : Option (Nat × Nat) := do
  let last ← report.batchEnds.getLast?
  pure (queue.lastFinalizedRequestId + 1, last)

def abstractPrefinalize (report : Report) (queue : Queue) : Option (Nat × (Nat × Nat)) :=
  match lockFor queue report, requestedRange queue report with
  | some amount, some range => some (amount, range)
  | _, _ => none

/-- Abstract transaction. Reverts preserve the complete state. -/
def spec (inputs : Inputs) (before : State) : Outcome :=
  if inputs.queue.paused || inputs.report.batchEnds.isEmpty then .reverted before
  else match abstractPrefinalize inputs.report inputs.queue with
    | some (amount, range) =>
        if amount ≤ inputs.buffer then
          let after := { before with lockedEth := before.lockedEth + amount }
          .committed after ⟨some range, some range, after.lockedEth⟩
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
  | some pair =>
      rcases pair with ⟨amount, range⟩
      by_cases hb : amount ≤ inputs.buffer <;>
        simp [hb, outcomeObservables]

end LidoSRv3.Audit.ReserveRelational
