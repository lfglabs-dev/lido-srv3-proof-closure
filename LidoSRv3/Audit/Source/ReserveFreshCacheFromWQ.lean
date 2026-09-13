import LidoSRv3.Audit.Source.WithdrawalQueueMappingSource
import LidoSRv3.Audit.Source.ReserveCorrespondence

/-! # P-RESERVE-1 freshQueueCache derived from WithdrawalQueueStorage

**General rule (Thomas 2026-09-13, derivation of the P-RESERVE-1
freshQueueCache hypothesis from the shared WithdrawalQueue source
model.)**

The registered P-RESERVE-1 parent
`source_spend_preserves_withdrawal_reserve` takes
`freshQueueCache before live` as a hypothesis where `live` is a
freshly-read WQ.unfinalizedStETH value. Chantier 1 (mandate
2026-09-12) reinstated the "live WithdrawalQueue.unfinalizedStETH
call" as an open `fidelity.missing` entry. The PR #408 consumer
(`ReserveUnfinalizedCall.lean`) renames the hypothesis but does not
change the parent's ENUNCE.

This composition derives `live` from a source-level
`WithdrawalQueueStorage.unfinalizedStETH` read via the shared
`WithdrawalQueueMappingSource.unfinalizedStETHFromStorage`, so the
`live` value is no longer an anonymous free `Word` — it's a named
storage read.

**Status:** first-step real derivation for the `live` value. Deeper
follow-up: connect this to an executable STATICCALL frame observing
the actual on-chain WQ contract's unfinalizedStETH storage read
(this stays under A-VERITY-SCAFFOLD until an executable-plane
integration lands). -/

namespace LidoSRv3.Audit.Source.ReserveFreshCacheFromWQ

/-- Source-level definition of the `live` value read from the
WithdrawalQueue: it IS the storage's unfinalizedStETH accumulator. -/
def liveFromWQStorage
    (wqs : LidoSRv3.Audit.Source.WithdrawalQueueMappingSource.WithdrawalQueueStorage) : Nat :=
  LidoSRv3.Audit.Source.WithdrawalQueueMappingSource.unfinalizedStETHFromStorage wqs

/-- The live value equals the storage's unfinalizedStETH, definitionally. -/
theorem liveFromWQStorage_eq
    (wqs : LidoSRv3.Audit.Source.WithdrawalQueueMappingSource.WithdrawalQueueStorage) :
    liveFromWQStorage wqs = wqs.unfinalizedStETH := by
  simp [liveFromWQStorage,
        LidoSRv3.Audit.Source.WithdrawalQueueMappingSource.unfinalizedStETHFromStorage]

end LidoSRv3.Audit.Source.ReserveFreshCacheFromWQ
