import LidoSRv3.Audit.Source.ReserveCorrespondence

/-! # Pinned `Lido._updateBufferedEtherAllocation` source model

**Chantier 2 (Piste A, Thomas 2026-09-13) source model for the third
of the four ETH-reserve partition writers.**

The pinned `Lido._updateBufferedEtherAllocation(uint256
_newBufferedEther, uint256 _newDepositedPostReport)` is invoked from
the oracle report handler at report time.  It rebalances the
`buffered` and `depositedPostReport` slots in the packed uint256
storage word (`BUFFERED_ETHER_AND_DEPOSITED_POST_REPORT_POSITION` at
Lido.sol:131-132) based on the oracle-supplied deltas.

Simplified transition captured here: `updateBufferedEtherAllocation
state newBuffered newDepositedPostReport` writes both new values to
the reserve state, resetting `depositedNextReportAdjusted` to zero
(mirroring the pinned "clear next-report accumulator on report
processing" semantics).

**Real derivation**: the three field updates are exhaustively named
in the transition; a proved theorem shows the other two partition
fields (`storedDepositsReserve`, `unfinalizedStETH`) are preserved by
construction.  Composing this writer with the top-up spend writer
would require analyzing the state after the report has closed —
current model does not carry a temporal ordering of the two writers,
so the composition is left for a follow-up.

This is ONE of the four ETH-reserve partition writers named in
`audit/SITE-CORRECTIONS.md`; writers #1 (spend), #2
(setDepositsReserveTarget), #3 (`_updateBufferedEtherAllocation` —
this module), and #4 (WQ finalize) are all now modeled. -/

namespace LidoSRv3.Audit.Source.ReserveUpdateBufferedAllocationSource

open LidoSRv3.Audit.SolidityReserve

/-- The pinned `_updateBufferedEtherAllocation` transition on the reserve
state.  Writes the new `buffered` and `depositedPostReport`, resets
`depositedNextReportAdjusted` to zero.  Other fields
(`storedDepositsReserve`, `unfinalizedStETH`) preserved by
construction. -/
def updateBufferedEtherAllocation (state : ReserveState)
    (newBuffered newDepositedPostReport : Word) : ReserveState :=
  { state with
    buffered := newBuffered
    depositedPostReport := newDepositedPostReport
    depositedNextReportAdjusted := (0 : Word) }

/-- The rebalance writes exactly the requested new buffered value. -/
theorem updateBufferedEtherAllocation_buffered
    (state : ReserveState) (newBuffered newDepositedPostReport : Word) :
    (updateBufferedEtherAllocation state newBuffered newDepositedPostReport).buffered =
      newBuffered := by
  simp [updateBufferedEtherAllocation]

/-- The rebalance writes exactly the requested new depositedPostReport
value. -/
theorem updateBufferedEtherAllocation_depositedPostReport
    (state : ReserveState) (newBuffered newDepositedPostReport : Word) :
    (updateBufferedEtherAllocation state newBuffered newDepositedPostReport).depositedPostReport =
      newDepositedPostReport := by
  simp [updateBufferedEtherAllocation]

/-- The rebalance resets the next-report accumulator to zero. -/
theorem updateBufferedEtherAllocation_next_report
    (state : ReserveState) (newBuffered newDepositedPostReport : Word) :
    (updateBufferedEtherAllocation state newBuffered newDepositedPostReport
        ).depositedNextReportAdjusted = (0 : Word) := by
  simp [updateBufferedEtherAllocation]

/-- The rebalance preserves `storedDepositsReserve` and
`unfinalizedStETH`; only `buffered`, `depositedPostReport`, and
`depositedNextReportAdjusted` are touched. -/
theorem updateBufferedEtherAllocation_preserves_other_fields
    (state : ReserveState) (newBuffered newDepositedPostReport : Word) :
    (updateBufferedEtherAllocation state newBuffered newDepositedPostReport
        ).storedDepositsReserve = state.storedDepositsReserve ∧
    (updateBufferedEtherAllocation state newBuffered newDepositedPostReport
        ).unfinalizedStETH = state.unfinalizedStETH := by
  simp [updateBufferedEtherAllocation]

end LidoSRv3.Audit.Source.ReserveUpdateBufferedAllocationSource
