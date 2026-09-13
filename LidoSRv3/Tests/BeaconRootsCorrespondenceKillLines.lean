import LidoSRv3.Audit.Source.BeaconRootsCorrespondence

/-! # Kill-lines for `BeaconRootsCorrespondence.sourceBeaconRootsRead`

**Chantier 3 (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the pinned EIP-4788 ring-buffer read semantics: zero-timestamp
rejection, sparse snapshot fail-closed, and timestamp validation. -/

namespace LidoSRv3.Tests.BeaconRootsCorrespondenceKillLines

open LidoSRv3.Audit.Source.BeaconRootsCorrespondence
open LidoSRv3.Audit.Spec.Eip4788AnchorChild

/-- **Kill-line: `sourceBeaconRootsRead storage 0 = none`.**

A mutant that dropped the zero-timestamp rejection would refute the
pinned EIP-4788 semantics. -/
theorem sourceBeaconRootsRead_zero_none (storage : BeaconRootsStorage) :
    sourceBeaconRootsRead storage 0 = none := by
  unfold sourceBeaconRootsRead
  simp

/-- **Kill-line: empty storage rejects every timestamp.**

Sparse snapshot fail-closed on missing ring-buffer cells. -/
theorem sourceBeaconRootsRead_empty (timestamp : Nat) :
    sourceBeaconRootsRead ⟨[]⟩ timestamp = none := by
  unfold sourceBeaconRootsRead
  by_cases h : timestamp = 0
  · simp [h]
  · simp [h]

/-- **Kill-line: mismatched-timestamp cell rejects the read.**

Storage `[⟨2, 42⟩]` at index 0; queried timestamp 8191 maps to
index 0 (8191 % 8191 = 0) and stored timestamp 2 ≠ 8191, so the
read is rejected. A mutant would refute. -/
theorem sourceBeaconRootsRead_wrong_timestamp_conc :
    sourceBeaconRootsRead ⟨[⟨2, 42⟩]⟩ 8191 = none := by
  decide

/-- **Kill-line: matched-timestamp cell accepts the read.**

Storage `[⟨8191, 42⟩]` at index 0; queried timestamp 8191 also
maps to index 0 and matches the stored timestamp, so the read
succeeds with root 42. -/
theorem sourceBeaconRootsRead_match_conc :
    sourceBeaconRootsRead ⟨[⟨8191, 42⟩]⟩ 8191 = some 42 := by
  decide

#print axioms sourceBeaconRootsRead_zero_none
#print axioms sourceBeaconRootsRead_empty
#print axioms sourceBeaconRootsRead_wrong_timestamp_conc
#print axioms sourceBeaconRootsRead_match_conc

end LidoSRv3.Tests.BeaconRootsCorrespondenceKillLines
