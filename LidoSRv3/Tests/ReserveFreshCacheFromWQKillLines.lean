import LidoSRv3.Audit.Source.ReserveFreshCacheFromWQ

/-! # Kill-lines for `ReserveFreshCacheFromWQ`

**Chantier 2 (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the pinned `WithdrawalQueue.unfinalizedStETH` read (freshQueueCache
source).**

`ReserveFreshCacheFromWQ.liveFromWQStorage wqs` = the WQ storage's
`unfinalizedStETH` accumulator.  `liveFromWQStorage_eq` is a `rfl`-shaped
equality between the source-model read and the WQ storage field.

These kill-lines pin the identity and demonstrate that a mutant that
projected a different field or returned a constant would fail. -/

namespace LidoSRv3.Tests.ReserveFreshCacheFromWQKillLines

open LidoSRv3.Audit.Source.ReserveFreshCacheFromWQ
open LidoSRv3.Audit.Source.WithdrawalQueueMappingSource

private def emptyMapping :
    LidoSRv3.Audit.Source.KeccakMappingStorageSource.MappingStorage :=
  { slotAt := fun _ => 0 }

/-- Witness WQ storage with `unfinalizedStETH = 42`. -/
private def witnessWQ : WithdrawalQueueStorage :=
  { unfinalizedStETH := 42
    requestMapping := emptyMapping
    checkpointMapping := emptyMapping }

/-- **Kill-line: `liveFromWQStorage` recovers the exact `unfinalizedStETH`.**

A mutant that returned a constant or a different field would produce
a different value at the witness. -/
theorem liveFromWQStorage_at_witness :
    liveFromWQStorage witnessWQ = 42 := rfl

/-- **Kill-line: `liveFromWQStorage` is injective on distinct
`unfinalizedStETH` values.**

At two witnesses with `unfinalizedStETH = 42` vs `= 100`, the read
distinguishes.  A mutant that mapped all WQ storages to the same
constant would fail. -/
theorem liveFromWQStorage_distinguishes :
    liveFromWQStorage witnessWQ ≠
      liveFromWQStorage { witnessWQ with unfinalizedStETH := 100 } := by
  unfold liveFromWQStorage unfinalizedStETHFromStorage
  decide

/-- **Kill-line: `liveFromWQStorage` equals the `unfinalizedStETH` field
by refl.**

The universal equality is `rfl`; a mutant that reorganized the
underlying `unfinalizedStETHFromStorage` (e.g., returned a sibling
field) would fail this. -/
theorem liveFromWQStorage_eq_field :
    ∀ wqs : WithdrawalQueueStorage,
      liveFromWQStorage wqs = wqs.unfinalizedStETH :=
  liveFromWQStorage_eq

/-- **Kill-line: `liveFromWQStorage` on zero storage is zero.** -/
theorem liveFromWQStorage_of_zero :
    liveFromWQStorage { witnessWQ with unfinalizedStETH := 0 } = 0 := rfl

#print axioms liveFromWQStorage_at_witness
#print axioms liveFromWQStorage_distinguishes
#print axioms liveFromWQStorage_eq_field
#print axioms liveFromWQStorage_of_zero

end LidoSRv3.Tests.ReserveFreshCacheFromWQKillLines
