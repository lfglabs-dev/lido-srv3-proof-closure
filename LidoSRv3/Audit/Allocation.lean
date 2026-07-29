import LidoSRv3.Audit.Trace

namespace LidoSRv3.Audit

/-!
# Source-shaped allocation audit predicates

Rows are in `SRStorage.getModuleIdAt(i)` order. WC01 top-up rows remain strategy
competitors; payment eligibility is intentionally a separate WC02-only fact.
-/

inductive AllocationMode
  | initialDeposit
  | topUp
  deriving DecidableEq, Repr

inductive CredentialType
  | wc01
  | wc02
  deriving DecidableEq, Repr

abbrev Word := Verity.Core.Uint256

structure AllocationRow where
  moduleId : Word
  active : Bool
  credentialType : CredentialType
  current : Validators
  capacity : Validators
  deriving DecidableEq, Repr

structure AllocationSnapshot where
  requested : Validators
  rows : List AllocationRow
  projectedTotal : Validators
  deriving DecidableEq, Repr

structure AllocationResultRow where
  moduleId : Word
  current : Validators
  increment : Validators
  allocationAfter : Validators
  capacity : Validators
  deriving DecidableEq, Repr

structure AllocationResult where
  rows : List AllocationResultRow
  totalAllocated : Validators
  deriving DecidableEq, Repr

def AllocationSnapshot.sourceDenominator (snapshot : AllocationSnapshot) : Prop :=
  Quantity.checkedSum (snapshot.requested :: snapshot.rows.map (·.current)) =
    some snapshot.projectedTotal

def rowsCorrespond : List AllocationRow → List AllocationResultRow → Prop
  | [], [] => True
  | source :: sources, result :: results =>
      result.moduleId = source.moduleId ∧
        result.current = source.current ∧
        result.capacity = source.capacity ∧
        Quantity.checkedAdd result.current result.increment =
          some result.allocationAfter ∧
        rowsCorrespond sources results
  | _, _ => False

/-- Checked conservation of row deltas and the requested-demand upper bound. -/
def conservesAllocation (snapshot : AllocationSnapshot) (result : AllocationResult) : Prop :=
  Quantity.checkedSum (result.rows.map (·.increment)) = some result.totalAllocated ∧
    result.totalAllocated.value ≤ snapshot.requested.value

/-- Positive increments are bounded by capacity; over-cap unchanged rows are allowed. -/
def respectsPositiveHeadroom (result : AllocationResult) : Prop :=
  ∀ row ∈ result.rows,
    row.increment.value > 0 → row.allocationAfter.value ≤ row.capacity.value

def paymentEligible (mode : AllocationMode) (source : AllocationRow) : Prop :=
  source.active = true ∧
    (mode = .initialDeposit ∨ source.credentialType = .wc02)

/-- Payment rows are stricter than strategy rows for top-ups. -/
def committedPaymentsEligible
    (mode : AllocationMode) (snapshot : AllocationSnapshot)
    (payments : List Wei) : Prop :=
  payments.length = snapshot.rows.length ∧
    ∀ i : Nat, ∀ payment source,
      payments[i]? = some payment →
      snapshot.rows[i]? = some source →
      payment.value > 0 →
      paymentEligible mode source

def validAllocationResult
    (snapshot : AllocationSnapshot) (result : AllocationResult) : Prop :=
  snapshot.sourceDenominator ∧
    rowsCorrespond snapshot.rows result.rows ∧
    conservesAllocation snapshot result ∧
    respectsPositiveHeadroom result

private theorem rowsCorrespond_moduleIds
    (h : rowsCorrespond sources results) :
    results.map AllocationResultRow.moduleId =
      sources.map AllocationRow.moduleId := by
  induction sources generalizing results with
  | nil =>
      cases results <;> simp_all [rowsCorrespond]
  | cons source sources ih =>
      cases results with
      | nil => simp [rowsCorrespond] at h
      | cons result results =>
          simp only [rowsCorrespond] at h
          simp [h.1, ih h.2.2.2.2]

theorem valid_result_preserves_router_order
    (h : validAllocationResult snapshot result) :
    result.rows.map AllocationResultRow.moduleId =
      snapshot.rows.map AllocationRow.moduleId :=
  rowsCorrespond_moduleIds h.2.1

/-! ## Regression falsifiers -/

private def word (n : Nat) : Word := Verity.Core.Uint256.ofNat n
private def q (n : Nat) : Validators := ⟨word n⟩

private def ineligibleRow : AllocationRow :=
  ⟨word 1, false, .wc01, q 0, q 1⟩

private def conservedButIneligibleSnapshot : AllocationSnapshot :=
  ⟨q 1, [ineligibleRow], q 1⟩

private def conservedButIneligibleResult : AllocationResult :=
  ⟨[⟨word 1, q 0, q 1, q 1, q 1⟩], q 1⟩

/-- Conservation alone does not establish eligibility. -/
example :
    conservesAllocation conservedButIneligibleSnapshot conservedButIneligibleResult ∧
      ¬ paymentEligible .initialDeposit ineligibleRow := by
  simp [conservesAllocation, conservedButIneligibleSnapshot,
    conservedButIneligibleResult, ineligibleRow, q, word,
    Quantity.checkedSum, Quantity.checkedAdd, Quantity.zero,
    Verity.Stdlib.Math.safeAdd, Verity.Core.MAX_UINT256,
    Verity.Core.Uint256.ofNat,
    Verity.Core.Uint256.modulus, Verity.Core.UINT256_MODULUS,
    paymentEligible]

end LidoSRv3.Audit
