/-! # Lido._seedDepositsCount bookkeeping + Unbuffered/DepositedPostReport events source model

**General rule (Thomas 2026-09-13, real derivation naming the pinned
Lido.sol:877-882 `_seedDepositsCount` bookkeeping and the paired
`Unbuffered` / `DepositedPostReportUpdated` events as source-level
functions.)**

Chantier: grok differential #419 flags D-SEED-1 / D-EVENT-1 —
Verity omits `_seedDepositsCount` bookkeeping and the `Unbuffered`
/ `DepositedPostReportUpdated` events.

This composition names each bookkeeping step and the paired event
frames as source-level functions:

- `updateDepositedPostReport current amount` = `current + amount`
  (pinned line 878).
- `updateBuffered current amount` = `current - amount` (pinned
  line 881: `_setBufferedEther(_getBufferedEther().sub(_amount))`).
- Two event frames: `unbufferedEvent amount` and
  `depositedPostReportUpdatedEvent newTotal`.

Downstream consumers of a Verity reserve-writer can now compare
their journal against the pinned bookkeeping + events shape.

Pinned Solidity (17005714):

- `Lido.sol:877-882`: `_seedDepositsCount` writes `depositedPostReport
   += _amount`, `buffered -= _amount`, emits `Unbuffered(_amount)`
   and `DepositedPostReportUpdated(newTotal)`.

**Status:** first real derivation naming the D-SEED-1 / D-EVENT-1
divergences (grok #419) as source-level functions. -/

namespace LidoSRv3.Audit.Source.ReserveSeedBookkeepingSource

/-- Source-level definition of the pinned line-878 depositedPostReport
increment. -/
def updateDepositedPostReport (current amount : Nat) : Nat :=
  current + amount

/-- Source-level definition of the pinned line-881 buffered
decrement. -/
def updateBuffered (current amount : Nat) : Nat :=
  current - amount

/-- Source-level event frame for the pinned `Unbuffered(_amount)`
event. -/
structure UnbufferedEvent : Type where
  amount : Nat

/-- Source-level event frame for the pinned
`DepositedPostReportUpdated(newTotal)` event. -/
structure DepositedPostReportUpdatedEvent : Type where
  newTotal : Nat

/-- The pinned `Unbuffered` event carries the amount. -/
def unbufferedEvent (amount : Nat) : UnbufferedEvent :=
  { amount := amount }

/-- The pinned `DepositedPostReportUpdated` event carries the new
total. -/
def depositedPostReportUpdatedEvent (newTotal : Nat) :
    DepositedPostReportUpdatedEvent :=
  { newTotal := newTotal }

/-- Composite bookkeeping: applies both writes and produces the
paired events. -/
structure SeedDepositsCountResult : Type where
  newDepositedPostReport : Nat
  newBuffered : Nat
  events : UnbufferedEvent × DepositedPostReportUpdatedEvent

/-- Source-level definition of the pinned `_seedDepositsCount`
bookkeeping applied to (currentDepositedPostReport, currentBuffered,
amount). -/
def seedDepositsCount
    (currentDepositedPostReport currentBuffered amount : Nat) :
    SeedDepositsCountResult :=
  let newDpr := updateDepositedPostReport currentDepositedPostReport amount
  let newBuf := updateBuffered currentBuffered amount
  { newDepositedPostReport := newDpr,
    newBuffered := newBuf,
    events := (unbufferedEvent amount, depositedPostReportUpdatedEvent newDpr) }

/-- The seed-write's new depositedPostReport equals the pinned
increment. -/
theorem seedDepositsCount_depositedPostReport_eq
    (currentDepositedPostReport currentBuffered amount : Nat) :
    (seedDepositsCount currentDepositedPostReport currentBuffered amount).newDepositedPostReport =
      currentDepositedPostReport + amount :=
  rfl

/-- The seed-write's new buffered equals the pinned decrement. -/
theorem seedDepositsCount_buffered_eq
    (currentDepositedPostReport currentBuffered amount : Nat) :
    (seedDepositsCount currentDepositedPostReport currentBuffered amount).newBuffered =
      currentBuffered - amount :=
  rfl

end LidoSRv3.Audit.Source.ReserveSeedBookkeepingSource
