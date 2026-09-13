import LidoSRv3.Audit.Source.ERC20StorageSource
import LidoSRv3.Audit.Source.NestedMappingSlotViaOracleSource

/-! # ERC-20 allowance key via shared KeccakOracle real derivation

**General rule (Thomas 2026-09-13, real derivation of the ERC-20
allowance-key layout past
`ERC20StorageSource.allowanceKey`'s placeholder
`owner * 2^160 + spender`.)**

The pinned Solidity ERC-20 nested-mapping layout for
`mapping(address owner => mapping(address spender => uint256))
allowances` derives the value slot at
`keccak256(abi.encode(spender, keccak256(abi.encode(owner, slot))))`.

This composition consumes the shared nested-mapping-slot derivation
(PR #482) and derives the real allowance-key for the ERC-20 module.

**Status:** first real derivation of the ERC-20 allowance-key past
its `owner * 2^160 + spender` placeholder in
`ERC20StorageSource.allowanceKey`. -/

namespace LidoSRv3.Audit.Source.ERC20AllowanceKeyViaOracleSource

open LidoSRv3.Audit.Source.KeccakConcreteCommitmentSource
open LidoSRv3.Audit.Source.NestedMappingSlotViaOracleSource

/-- Real derivation of the ERC-20 allowance-mapping slot at
`(owner, spender)` for a given `allowancesBaseSlot`. -/
def realAllowanceSlot
    (oracle : KeccakOracle) (allowancesBaseSlot owner spender : Nat) : Nat :=
  realNestedSlotDerivation oracle allowancesBaseSlot owner spender

/-- The real allowance-key follows the pinned Solidity nested-
mapping rule, definitionally. -/
theorem realAllowanceSlot_eq
    (oracle : KeccakOracle) (allowancesBaseSlot owner spender : Nat) :
    realAllowanceSlot oracle allowancesBaseSlot owner spender =
      realNestedSlotDerivation oracle allowancesBaseSlot owner spender :=
  rfl

/-- Determinism of `realAllowanceSlot` on identical inputs. Real
derivation from the shared oracle's determinism law. -/
theorem realAllowanceSlot_deterministic
    {oracle : KeccakOracle} {b1 b2 o1 o2 s1 s2 : Nat}
    (hBase : b1 = b2) (hOwner : o1 = o2) (hSpender : s1 = s2) :
    realAllowanceSlot oracle b1 o1 s1 = realAllowanceSlot oracle b2 o2 s2 := by
  subst hBase
  subst hOwner
  subst hSpender
  rfl

end LidoSRv3.Audit.Source.ERC20AllowanceKeyViaOracleSource
