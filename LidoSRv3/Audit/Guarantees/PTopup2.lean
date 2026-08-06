import LidoSRv3.Audit.Guarantees.Registry

namespace List

/-- Compatibility spelling for total list indexing in the abstract model. -/
def get! [Inhabited α] (xs : List α) (i : Nat) : α := xs[i]!

end List

namespace LidoSRv3.Audit.Guarantees.PTopup2

/-- The validator information needed by the abstract top-up model. -/
structure Validator where
  pubkey : ByteArray
  currentBalance : Nat
  deriving Inhabited

/-- The consensus maximum effective balance, expressed in wei. -/
def MAX_EFFECTIVE_BALANCE : Nat := 32 * 10^18

/-- Remaining balance that may be assigned without exceeding the maximum. -/
def validator_headroom (v : Validator) : Nat :=
  MAX_EFFECTIVE_BALANCE - v.currentBalance

/-- A batch of validator top-ups and its aggregate budget. -/
structure TopupBatch where
  validators : List Validator
  topupAmounts : List Nat
  totalBudget : Nat

/-- Every amount has a corresponding validator and fits its headroom. -/
def per_validator_headroom (b : TopupBatch) : Prop :=
  b.validators.length = b.topupAmounts.length ∧
  ∀ i, i < b.topupAmounts.length →
    b.topupAmounts.get! i ≤ validator_headroom (b.validators.get! i)

/-- The batch does not spend more than its declared budget. -/
def aggregate_budget_conserved (b : TopupBatch) : Prop :=
  b.topupAmounts.sum ≤ b.totalBudget

private theorem sum_topups_le_headroom
    (validators : List Validator) (amounts : List Nat)
    (length_eq : validators.length = amounts.length)
    (per_validator : ∀ i, i < amounts.length →
      amounts.get! i ≤ validator_headroom (validators.get! i)) :
    amounts.sum ≤ (validators.map validator_headroom).sum := by
  induction validators generalizing amounts with
  | nil =>
      cases amounts with
      | nil => simp
      | cons amount amounts => simp at length_eq
  | cons validator validators ih =>
      cases amounts with
      | nil => simp at length_eq
      | cons amount amounts =>
          have length_eq' : validators.length = amounts.length :=
            Nat.succ.inj length_eq
          apply Nat.add_le_add
          · simpa [List.get!] using per_validator 0 (by simp)
          · apply ih amounts length_eq'
            intro i hi
            simpa [List.get!] using per_validator (i + 1) (by simp [hi])

/-- Per-validator bounds compose into the aggregate headroom bound. -/
theorem topup_batch_sound (b : TopupBatch) :
    per_validator_headroom b →
      b.topupAmounts.sum ≤ (b.validators.map validator_headroom).sum := by
  rintro ⟨length_eq, per_validator⟩
  exact sum_topups_le_headroom b.validators b.topupAmounts length_eq per_validator

/-- Both independently checked constraints required of a valid batch. -/
def topup_well_formed (b : TopupBatch) : Prop :=
  per_validator_headroom b ∧ aggregate_budget_conserved b

/-- A well-formed batch is bounded by both its budget and aggregate headroom. -/
theorem topup_well_formed_sound (b : TopupBatch) (h : topup_well_formed b) :
    b.topupAmounts.sum ≤ b.totalBudget ∧
      b.topupAmounts.sum ≤ (b.validators.map validator_headroom).sum :=
  ⟨h.2, topup_batch_sound b h.1⟩

/-- Budget/headroom is checked at MODEL; runtime verifier binding remains blocked. -/
def guarantee : Guarantee := ⟨.pTopup2, [.model]⟩

/- TODO(P-TOPUP-2 verifier binding): establish from runtime provenance that the
deployed verifier address and codehash bind an accepted SSZ proof to the intended
validator. Source, transaction, and EVM closure remain BLOCKED until then. -/

end LidoSRv3.Audit.Guarantees.PTopup2
