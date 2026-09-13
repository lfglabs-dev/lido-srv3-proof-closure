import LidoSRv3.Audit.Source.ReserveSeedBookkeepingSource

/-! # Kill-lines for `ReserveSeedBookkeepingSource`

**Chantier 2 (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the pinned `Lido.sol:877-882 _seedDepositsCount` bookkeeping
(D-SEED-1 / D-EVENT-1).**

`ReserveSeedBookkeepingSource.seedDepositsCount` names the pinned
bookkeeping as `newDpr = updateDepositedPostReport currentDpr amount`
and `newBuf = updateBuffered currentBuf amount`, plus paired
`UnbufferedEvent` / `DepositedPostReportUpdatedEvent`.

Two proved projection identities pin the arithmetic:
- `seedDepositsCount_depositedPostReport_eq`: `newDpr = currentDpr +
  amount`.
- `seedDepositsCount_buffered_eq`: `newBuf = currentBuf - amount`.

These kill-lines exhibit concrete counterexamples for weakened
formulations. -/

namespace LidoSRv3.Tests.ReserveSeedBookkeepingKillLines

open LidoSRv3.Audit.Source.ReserveSeedBookkeepingSource

/-- **Kill-line: seed writes both accumulators at witness values.**

Applied to `currentDpr = 100, currentBuf = 200, amount = 50`, the
pinned bookkeeping produces `newDpr = 150, newBuf = 150`.  A mutant
that skipped the write to either accumulator would fail. -/
theorem seedDepositsCount_at_witness :
    (seedDepositsCount 100 200 50).newDepositedPostReport = 150 ∧
    (seedDepositsCount 100 200 50).newBuffered = 150 :=
  ⟨seedDepositsCount_depositedPostReport_eq 100 200 50,
   seedDepositsCount_buffered_eq 100 200 50⟩

/-- **Kill-line: seed grows depositedPostReport monotonically.**

Applied to any nonzero amount, `newDpr = currentDpr + amount >
currentDpr`.  A mutant that shrunk `newDpr` would fail. -/
theorem seedDepositsCount_grows_depositedPostReport :
    (seedDepositsCount 100 200 50).newDepositedPostReport >
      100 := by
  rw [seedDepositsCount_depositedPostReport_eq]
  decide

/-- **Kill-line: seed shrinks buffered by the amount.**

Applied to `currentBuf ≥ amount`, `newBuf = currentBuf - amount <
currentBuf`.  A mutant that grew `newBuf` would fail. -/
theorem seedDepositsCount_shrinks_buffered :
    (seedDepositsCount 100 200 50).newBuffered < 200 := by
  rw [seedDepositsCount_buffered_eq]
  decide

/-- **Kill-line: seed of zero is a no-op on both accumulators.**

Applied to `amount = 0`, both accumulators are preserved.  A mutant
that touched them anyway would fail. -/
theorem seedDepositsCount_of_zero :
    (seedDepositsCount 100 200 0).newDepositedPostReport = 100 ∧
    (seedDepositsCount 100 200 0).newBuffered = 200 := by
  constructor
  · rw [seedDepositsCount_depositedPostReport_eq]
  · rw [seedDepositsCount_buffered_eq]

/-- **Kill-line: the paired events carry the amount and new total.**

The paired `UnbufferedEvent` carries `amount` and the paired
`DepositedPostReportUpdatedEvent` carries the new total.  A mutant
that dropped the event pair or corrupted their payloads would fail. -/
theorem seedDepositsCount_events_shape :
    (seedDepositsCount 100 200 50).events.1 = unbufferedEvent 50 ∧
    (seedDepositsCount 100 200 50).events.2 = depositedPostReportUpdatedEvent 150 :=
  ⟨rfl, rfl⟩

#print axioms seedDepositsCount_at_witness
#print axioms seedDepositsCount_grows_depositedPostReport
#print axioms seedDepositsCount_shrinks_buffered
#print axioms seedDepositsCount_of_zero
#print axioms seedDepositsCount_events_shape

end LidoSRv3.Tests.ReserveSeedBookkeepingKillLines
