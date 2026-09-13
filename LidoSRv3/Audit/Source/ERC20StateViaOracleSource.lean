import LidoSRv3.Audit.Source.ERC20StorageSource
import LidoSRv3.Audit.Source.MappingSlotViaOracleSource

/-! # ERC-20 balances/allowances state via shared KeccakOracle

**General rule (Thomas 2026-09-13, chain
`ERC20StorageSource.ERC20State`'s two MappingStorage fields through
the shared oracle-backed realMappingStorage.)**

`ERC20StorageSource.ERC20State` holds two `MappingStorage` fields
for balances and allowances. This composition specialises each to a
`realMappingStorage oracle baseSlot` so their storage slots are
derived through the pinned Solidity mapping-slot rule via the
shared A-KECCAK-COMMITMENT oracle.

**Status:** first real derivation of the ERC-20 state past its two
free MappingStorage fields — both are now functions of
`(oracle, balancesBaseSlot, allowancesBaseSlot)`. -/

namespace LidoSRv3.Audit.Source.ERC20StateViaOracleSource

open LidoSRv3.Audit.Source.KeccakConcreteCommitmentSource
open LidoSRv3.Audit.Source.MappingSlotViaOracleSource
open LidoSRv3.Audit.Source.ERC20StorageSource

/-- Real ERC-20 state derived from the shared oracle at two pinned
base slots. -/
def realERC20State
    (oracle : KeccakOracle)
    (balancesBaseSlot allowancesBaseSlot : Nat) : ERC20State :=
  { balances := realMappingStorage oracle balancesBaseSlot,
    allowances := realMappingStorage oracle allowancesBaseSlot }

/-- The real ERC-20 state's `balanceOf` traces through the pinned
Solidity mapping-slot rule. -/
theorem realERC20State_balanceOf_eq
    (oracle : KeccakOracle)
    (balancesBaseSlot allowancesBaseSlot addr : Nat) :
    balanceOf (realERC20State oracle balancesBaseSlot allowancesBaseSlot) addr =
      (realMappingStorage oracle balancesBaseSlot).slotAt addr :=
  rfl

/-- The real ERC-20 state's `allowanceOf` traces through the pinned
Solidity mapping-slot rule (single-level; the nested key is
`allowanceKey owner spender`). -/
theorem realERC20State_allowanceOf_eq
    (oracle : KeccakOracle)
    (balancesBaseSlot allowancesBaseSlot owner spender : Nat) :
    allowanceOf (realERC20State oracle balancesBaseSlot allowancesBaseSlot)
        owner spender =
      (realMappingStorage oracle allowancesBaseSlot).slotAt
        (allowanceKey owner spender) :=
  rfl

end LidoSRv3.Audit.Source.ERC20StateViaOracleSource
