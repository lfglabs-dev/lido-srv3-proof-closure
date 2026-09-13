import LidoSRv3.Audit.Source.MappingSlotViaOracleSource

/-! # Solidity nested-mapping slot derivation via KeccakOracle

**General rule (Thomas 2026-09-13, real derivation of the Solidity
nested-mapping slot layout past `ERC20StorageSource.allowanceKey`'s
placeholder.)**

`ERC20StorageSource.allowanceKey owner spender` returns
`owner * 2^160 + spender` — a placeholder for the pinned
`keccak256(abi.encode(spender, keccak256(abi.encode(owner, slot))))`
that Solidity uses for `mapping(K1 => mapping(K2 => V))`.

This composition consumes the shared `KeccakOracle` (PR #478) and
derives the real nested-mapping slot from it via two chained
`concreteMappingSlot` applications.

**Status:** first real derivation of the Solidity nested-mapping
slot rule past its placeholder in ERC-20 allowance keys and any
other double-mapping consumers (Aragon ACL permissions). -/

namespace LidoSRv3.Audit.Source.NestedMappingSlotViaOracleSource

open LidoSRv3.Audit.Source.KeccakConcreteCommitmentSource
open LidoSRv3.Audit.Source.MappingSlotViaOracleSource

/-- Real slot derivation for `mapping(K1 => mapping(K2 => V))` at
outer key `k1` and inner key `k2`, per pinned Solidity:
`keccak256(abi.encode(k2, keccak256(abi.encode(k1, baseSlot))))`. -/
def realNestedSlotDerivation
    (oracle : KeccakOracle) (baseSlot k1 k2 : Nat) : Nat :=
  concreteMappingSlot oracle
    (encodeMappingKey k2 (realSlotDerivation oracle baseSlot k1))

/-- Determinism of the real nested-mapping-slot derivation on
identical inputs. Real derivation from the shared oracle's
determinism law. -/
theorem realNestedSlotDerivation_deterministic
    {oracle : KeccakOracle} {b1 b2 x1 y1 x2 y2 : Nat}
    (hBase : b1 = b2) (hOuter : x1 = x2) (hInner : y1 = y2) :
    realNestedSlotDerivation oracle b1 x1 y1
      = realNestedSlotDerivation oracle b2 x2 y2 := by
  subst hBase
  subst hOuter
  subst hInner
  rfl

end LidoSRv3.Audit.Source.NestedMappingSlotViaOracleSource
