import LidoSRv3.Audit.Verity.BeaconRootsTx

/-! # Kill-lines for `Verity.BeaconRootsTx.executeRead`

**Chantier 3 (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the EIP-4788 BEACON_ROOTS Verity-plane read semantics (zero-
timestamp rejection, fail-closed on missing cell, matched-cell
acceptance). -/

namespace LidoSRv3.Tests.VerityBeaconRootsTxKillLines

open LidoSRv3.Audit.Verity.BeaconRootsTx
open LidoSRv3.Audit.Source.BeaconRootsCorrespondence

/-- **Kill-line: `executeRead` rejects the zero timestamp.**

EIP-4788 defines timestamp 0 as an invalid/uninitialized slot; a
mutant that accepted zero would refute the pinned system-contract
guard. -/
theorem executeRead_zero_none (storage : BeaconRootsStorage) :
    executeRead ⟨storage, 0⟩ = none := by
  unfold executeRead
  simp

/-- **Kill-line: `executeRead` on empty storage returns none.** -/
theorem executeRead_empty_storage (timestamp : Nat) :
    executeRead ⟨⟨[]⟩, timestamp⟩ = none := by
  unfold executeRead
  by_cases h : timestamp = 0
  · simp [h]
  · simp [h]

/-- **Kill-line: matched-timestamp cell yields the paired root.** -/
theorem executeRead_match :
    executeRead ⟨⟨[⟨8191, 42⟩]⟩, 8191⟩ = some 42 := by decide

/-- **Kill-line: mismatched-timestamp cell yields none.**

The stored slot at index 0 has timestampWord 2, but a query for
8191 (which also maps to index 0 mod 8191) triggers the timestamp
validation and rejects. -/
theorem executeRead_mismatch :
    executeRead ⟨⟨[⟨2, 42⟩]⟩, 8191⟩ = none := by decide

#print axioms executeRead_zero_none
#print axioms executeRead_empty_storage
#print axioms executeRead_match
#print axioms executeRead_mismatch

end LidoSRv3.Tests.VerityBeaconRootsTxKillLines
