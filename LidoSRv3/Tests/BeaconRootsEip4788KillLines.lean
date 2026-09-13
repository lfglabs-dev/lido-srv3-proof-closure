import LidoSRv3.Audit.Source.BeaconRootsEip4788Source

/-! # Kill-lines for `BeaconRootsEip4788Source`

**Chantier 3 (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the EIP-4788 beacon-roots predeploy address and canonical call
targeting.** -/

namespace LidoSRv3.Tests.BeaconRootsEip4788KillLines

open LidoSRv3.Audit.Source.BeaconRootsEip4788Source

/-- **Kill-line: the pinned BEACON_ROOTS_ADDRESS is exactly
`0x000F3df6D732807Ef1319fB7B8bB8522d0Beac02`.**

A mutant that changed a single hex digit would refute this. -/
theorem beaconRootsAddress_pinned :
    beaconRootsAddress = 0x000F3df6D732807Ef1319fB7B8bB8522d0Beac02 :=
  rfl

/-- **Kill-line: the pinned address fits uint160 (address).**

A mutant that increased the address past 2^160 - 1 would refute. -/
theorem beaconRootsAddress_fits_address :
    beaconRootsAddress ≤ 2 ^ 160 - 1 := by
  decide

/-- **Kill-line: canonical call has target = beacon-roots address.**

A mutant that redirected the call to a different target address
(e.g. 0x00 or the deposit contract) would refute this. -/
theorem canonicalCall_hits_beacon_roots (timestamp : Nat) :
    (canonicalCall timestamp).target = beaconRootsAddress :=
  rfl

/-- **Kill-line: canonical call preserves the input timestamp.**

A mutant that discarded or overwrote the timestamp would refute. -/
theorem canonicalCall_preserves_timestamp (timestamp : Nat) :
    (canonicalCall timestamp).timestamp = timestamp :=
  rfl

/-- **Kill-line: canonicalCall at timestamp 0 gives the pinned target.** -/
theorem canonicalCall_zero_target :
    (canonicalCall 0).target =
      0x000F3df6D732807Ef1319fB7B8bB8522d0Beac02 := rfl

#print axioms beaconRootsAddress_pinned
#print axioms beaconRootsAddress_fits_address
#print axioms canonicalCall_hits_beacon_roots
#print axioms canonicalCall_preserves_timestamp
#print axioms canonicalCall_zero_target

end LidoSRv3.Tests.BeaconRootsEip4788KillLines
