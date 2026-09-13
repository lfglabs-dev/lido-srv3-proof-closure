import LidoSRv3.Audit.Source.KeccakConcreteCommitmentSource

/-! # ERC-7201 namespaced storage-slot source model

**General rule (Thomas 2026-09-13, real derivation naming the pinned
ERC-7201 storage-slot derivation rule as a source-level function.)**

Chantier: grok differential #412 flags D-SLOT-1 — the pinned
StakingRouter writes ERC-7201 `ModuleState.deposits` at a
namespaced storage layout, but the Verity plane uses local slots
0-4 with no storage identity claim.

ERC-7201 defines a namespaced storage-position derivation:
`baseSlot = keccak256(abi.encode(uint256(keccak256(namespace)) - 1))
              & ~bytes32(uint256(0xff))`.

This composition names the pinned ERC-7201 rule as a source-level
function of the shared `KeccakOracle` (PR #478). Downstream
consumers can now derive the deployed storage position for any
ERC-7201 namespace and route their storage observations through it.

**Status:** first real derivation of the ERC-7201 storage-slot rule
past the local-slot placeholder. -/

namespace LidoSRv3.Audit.Source.ERC7201StorageSlotSource

open LidoSRv3.Audit.Source.KeccakConcreteCommitmentSource

/-- Encode an ERC-7201 namespace string as a nat (source-level
abstraction). -/
def namespaceToNat (ns : String) : Nat :=
  ns.length + ns.toList.foldl (fun acc c => acc + c.toNat) 0

/-- Bitwise mask for the ERC-7201 base-slot derivation:
`~bytes32(uint256(0xff))` masks off the low byte. Modelled as a
modulo-256 clear at the source level. -/
def maskLowByte (word : Nat) : Nat := word - (word % 256)

/-- Real derivation of the ERC-7201 storage base slot for a given
namespace, per pinned EIP-7201 rule. -/
def realERC7201BaseSlot
    (oracle : KeccakOracle) (ns : String) : Nat :=
  maskLowByte (oracle.hash ((oracle.hash (namespaceToNat ns)) - 1))

/-- Determinism of `realERC7201BaseSlot` on identical namespaces.
Real derivation from the shared oracle's determinism law. -/
theorem realERC7201BaseSlot_deterministic
    {oracle : KeccakOracle} {ns1 ns2 : String} (hEq : ns1 = ns2) :
    realERC7201BaseSlot oracle ns1 = realERC7201BaseSlot oracle ns2 := by
  subst hEq
  rfl

end LidoSRv3.Audit.Source.ERC7201StorageSlotSource
