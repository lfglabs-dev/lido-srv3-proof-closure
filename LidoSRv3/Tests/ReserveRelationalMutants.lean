import LidoSRv3.Audit.Guarantees.PReserveRelational

namespace LidoSRv3.Tests.ReserveRelationalMutants

open LidoSRv3.Audit.ReserveRelational

private def queue : Queue := ⟨9,
  [⟨11, 30, 20⟩, ⟨14, 50, 35⟩], false⟩
private def report : Report := ⟨[11, 14], false⟩
private def inputs : Inputs := ⟨report, queue, 100⟩
private def lowReserve : State := ⟨5, 7⟩
private def highReserve : State := ⟨90, 7⟩

/-- Positive two-batch chaining: range endpoints and both batch amounts compose. -/
example : sourceRun inputs lowReserve = .committed ⟨5, 87⟩
    ⟨some (10, 14), some (10, 14), 87⟩ := by decide

example : outcomeObservables (sourceRun inputs lowReserve) =
    outcomeObservables (sourceRun inputs highReserve) := by decide

/-- Forbidden reserve-to-range dependency. -/
private def reserveToRangeMutant (i : Inputs) (s : State) : Outcome :=
  match sourceRun i s with
  | .reverted before => .reverted before
  | .committed after obs => .committed after
      { obs with finalizedRange := some (s.depositsReserve, obs.finalizedRange.getD (0, 0)).2 }

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
example : ignoredReportMutant { inputs with report := ⟨[11], false⟩ } lowReserve ≠
    sourceRun { inputs with report := ⟨[11], false⟩ } lowReserve := by decide
example : ignoredQueueMutant { inputs with queue := ⟨9, [⟨11, 1, 1⟩], false⟩ } lowReserve ≠
    sourceRun { inputs with queue := ⟨9, [⟨11, 1, 1⟩], false⟩ } lowReserve := by decide
example : ignoredBufferMutant { inputs with buffer := 40 } lowReserve ≠
    sourceRun { inputs with buffer := 40 } lowReserve := by decide

/-- Commit/revert outcomes are preserved across reserve-only variants. -/
example : sourceRun { inputs with buffer := 40 } lowReserve = .reverted lowReserve := by decide
example : sourceRun { inputs with buffer := 40 } highReserve = .reverted highReserve := by decide

end LidoSRv3.Tests.ReserveRelationalMutants
