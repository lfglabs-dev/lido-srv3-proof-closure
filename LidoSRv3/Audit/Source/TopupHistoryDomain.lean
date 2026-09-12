import LidoSRv3.Audit.Source.TopupCallHistory

/-! Diagnostic for the explicit uint32 horizon in the accepted timing slice.
These results concern its real truncating update and guard, not authenticated
consensus history, full router ETH effects or a deployed exploit. -/
namespace LidoSRv3.Audit.Source.TopupHistoryDomain
open TopupCallHistory

/-- Every full-width block beyond the uint32 range reopens the source timing
guard after a positive-limit return, for every representable uint16 delay.
This is not restricted to the zero-sentinel case. -/
theorem truncated_blocks_reopen (s : TimingState) (blockNumber timestamp total : Nat)
    (hb : uint32Modulus ≤ blockNumber) (ht : 0 < total) :
    distancePassed (finish s blockNumber timestamp total) blockNumber = some true := by
  have hd := s.distance.isLt
  have hmod := Nat.mod_le blockNumber uint32Modulus
  have hgap : s.distance.val ≤ blockNumber - blockNumber % uint32Modulus := by
    unfold uint32Modulus uint16Modulus at *
    omega
  simp only [finish, ht, ↓reduceIte, distancePassed]
  split
  · rfl
  · simp [Nat.not_lt_of_ge hmod, hgap]

/-- The same timestamp remains strictly newer than the stored truncated
timestamp once the timestamp exceeds uint32. This explains the root-age
control in the separate Solidity fixture, not root authenticity. -/
theorem truncated_timestamp_is_older (s : TimingState) (blockNumber timestamp total : Nat)
    (htime : uint32Modulus ≤ timestamp) (ht : 0 < total) :
    (finish s blockNumber timestamp total).lastTimestamp.val < timestamp := by
  have hmod := Nat.mod_lt timestamp (show 0 < uint32Modulus by decide)
  simpa only [finish, ht, ↓reduceIte] using Nat.lt_of_lt_of_le hmod htime

private def configuredOne : TimingState :=
  ⟨⟨0, by decide⟩, ⟨0, by decide⟩, ⟨1, by decide⟩⟩

private theorem configured_one : Configured configuredOne :=
  Configured.initialized 1 configuredOne (by decide +kernel)

/-- Setter/update reachability alone cannot discharge the existing block
horizon. The counterexample starts with the actual successful delay setter.
Full EVM/protocol initialization is not claimed by `Configured`. -/
theorem configured_does_not_give_unrestricted_exclusion :
    ¬ (∀ s : TimingState, Configured s → ∀ b t total : Nat,
      0 < b → 0 < total → distancePassed (finish s b t total) b = some false) := by
  intro h
  have hfalse := h configuredOne configured_one uint32Modulus 1000 1 (by decide) (by decide)
  have htrue := truncated_blocks_reopen configuredOne uint32Modulus 1000 1 (by omega) (by decide)
  rw [htrue] at hfalse
  contradiction

#print axioms truncated_blocks_reopen
#print axioms truncated_timestamp_is_older
#print axioms configured_does_not_give_unrestricted_exclusion
end LidoSRv3.Audit.Source.TopupHistoryDomain
