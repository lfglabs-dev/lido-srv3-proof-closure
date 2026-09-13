/-! # EIP-4788 BEACON_ROOTS_ADDRESS predeploy identity source model

**General rule (Thomas 2026-09-13, chantier 3 SSZ derivation
prerequisite): the pinned EIP-4788 beacon roots predeploy at
0x000F3df6D732807Ef1319fB7B8bB8522d0Beac02 exposes the beacon
block-root at each timestamp. The CLValidatorVerifier consumes it
as an opaque address; this composition names the identity as a
source-level constant.**

**Status:** first real source-level naming of the pinned EIP-4788
predeploy address. -/

namespace LidoSRv3.Audit.Source.BeaconRootsEip4788Source

/-- Pinned EIP-4788 BEACON_ROOTS_ADDRESS as a source-level constant.
`0x000F3df6D732807Ef1319fB7B8bB8522d0Beac02`. -/
def beaconRootsAddress : Nat :=
  0x000F3df6D732807Ef1319fB7B8bB8522d0Beac02

/-- The address fits uint160 (address). -/
theorem beaconRootsAddress_le_uint160Max :
    beaconRootsAddress ≤ 2 ^ 160 - 1 := by
  unfold beaconRootsAddress
  decide

/-- Source-level EIP-4788 predeploy call shape. -/
structure BeaconRootsCall : Type where
  target : Nat
  timestamp : Nat

/-- The pinned call targets the beacon-roots address. -/
def canonicalCall (timestamp : Nat) : BeaconRootsCall :=
  { target := beaconRootsAddress, timestamp := timestamp }

/-- Canonical call targets are always the pinned address. -/
theorem canonicalCall_target_eq (timestamp : Nat) :
    (canonicalCall timestamp).target = beaconRootsAddress :=
  rfl

end LidoSRv3.Audit.Source.BeaconRootsEip4788Source
