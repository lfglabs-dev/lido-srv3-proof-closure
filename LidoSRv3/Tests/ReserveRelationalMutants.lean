import LidoSRv3.Audit.Guarantees.PReserveRelational

namespace LidoSRv3.Tests.ReserveRelationalMutants

open LidoSRv3.Audit.ReserveRelational

private def queue : Queue := ⟨9,
  [⟨11, 30, 20, 12⟩, ⟨14, 50, 35, 25⟩], false⟩
private def report : Report := ⟨[11, 14], false⟩
private def inputs : Inputs := ⟨report, queue, 100⟩
private def lowReserve : State := ⟨5, 7⟩
private def highReserve : State := ⟨90, 7⟩

/-- Positive two-batch chaining: the second prefinalized range starts one past
the first batch end, and both batch amounts and share counts compose. -/
example : sourceRun inputs lowReserve = .committed ⟨5, 87⟩
    ⟨[(10, 11), (12, 14)], 80, 37, some (10, 14), 87⟩ := by decide

/-- The discount channel selects the other per-batch ETH column. -/
example : sourceRun { inputs with report := ⟨[11, 14], true⟩ } lowReserve =
    .committed ⟨5, 62⟩ ⟨[(10, 11), (12, 14)], 55, 37, some (10, 14), 62⟩ := by decide

example : outcomeObservables (sourceRun inputs lowReserve) =
    outcomeObservables (sourceRun inputs highReserve) := by decide

/-- Forbidden reserve-to-range dependency. -/
private def reserveToRangeMutant (i : Inputs) (s : State) : Outcome :=
  match sourceRun i s with
  | .reverted before => .reverted before
  | .committed after obs => .committed after
      { obs with finalizedRange := obs.finalizedRange.map fun range =>
          (s.depositsReserve, range.2) }

/-- Forbidden reserve-to-prefinalized-range dependency. -/
private def reserveToPrefinalizedMutant (i : Inputs) (s : State) : Outcome :=
  match sourceRun i s with
  | .reverted before => .reverted before
  | .committed after obs => .committed after
      { obs with prefinalizedRanges :=
          obs.prefinalizedRanges.map fun range => (s.depositsReserve, range.2) }

/-- Forbidden reserve-to-shares dependency. -/
private def reserveToSharesMutant (i : Inputs) (s : State) : Outcome :=
  match sourceRun i s with
  | .reverted before => .reverted before
  | .committed after obs => .committed after { obs with sharesToBurn := s.depositsReserve }

/-- Forbidden report omission: silently prefinalize the entire queue. -/
private def ignoredReportMutant (i : Inputs) (s : State) : Outcome :=
  sourceRun { i with report := { i.report with batchEnds := i.queue.batches.map (·.endRequestId) } } s

/-- Forbidden queue omission: accept invented batch economics. -/
private def ignoredQueueMutant (i : Inputs) (s : State) : Outcome :=
  sourceRun { i with queue := queue } s

/-- Forbidden buffer omission: permit a lock larger than available ETH. -/
private def ignoredBufferMutant (i : Inputs) (s : State) : Outcome :=
  sourceRun { i with buffer := 1000 } s

example : reserveToRangeMutant inputs lowReserve ≠ reserveToRangeMutant inputs highReserve := by decide
example : reserveToPrefinalizedMutant inputs lowReserve ≠
    reserveToPrefinalizedMutant inputs highReserve := by decide
example : reserveToSharesMutant inputs lowReserve ≠
    reserveToSharesMutant inputs highReserve := by decide
example : ignoredReportMutant { inputs with report := ⟨[11], false⟩ } lowReserve ≠
    sourceRun { inputs with report := ⟨[11], false⟩ } lowReserve := by decide
example : ignoredQueueMutant { inputs with queue := ⟨9, [⟨11, 1, 1, 1⟩], false⟩ } lowReserve ≠
    sourceRun { inputs with queue := ⟨9, [⟨11, 1, 1, 1⟩], false⟩ } lowReserve := by decide
example : ignoredBufferMutant { inputs with buffer := 40 } lowReserve ≠
    sourceRun { inputs with buffer := 40 } lowReserve := by decide

/-- Commit/revert outcomes are preserved across reserve-only variants. -/
example : sourceRun { inputs with buffer := 40 } lowReserve = .reverted lowReserve := by decide
example : sourceRun { inputs with buffer := 40 } highReserve = .reverted highReserve := by decide

/-- A paused queue and an empty report both fail closed. -/
example : sourceRun { inputs with queue := { queue with paused := true } } lowReserve =
    .reverted lowReserve := by decide
example : sourceRun { inputs with report := ⟨[], false⟩ } lowReserve =
    .reverted lowReserve := by decide

/-- An unknown batch end is not silently skipped. -/
example : sourceRun { inputs with report := ⟨[11, 13], false⟩ } lowReserve =
    .reverted lowReserve := by decide

end LidoSRv3.Tests.ReserveRelationalMutants
