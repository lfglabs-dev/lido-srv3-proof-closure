import LidoSRv3.Audit.Source.KeccakMappingStorageSource

/-! # Shared ERC-20 balances/allowances source model

**General rule (Thomas 2026-09-13, shared ERC-20 storage model for
STETH balances/allowances, WstETH balances, and general token
balance/allowance guards.)**

Names the pinned ERC-20 storage layout as an audit-source model. Under
this model, `balanceOf(addr)` and `allowance(owner, spender)` become
DEFINED functions of a source-level `ERC20State`, not anonymous free
`uint256` values.

Pinned Solidity (17005714) uses standard ERC-20 mapping layouts:

- `contracts/0.4.24/StETH.sol` / `contracts/0.6.12/WstETH.sol`:
  `mapping(address => uint256) balances;`
  `mapping(address => mapping(address => uint256)) allowances;`
- Balances at keccak-derived slot per `mapping(address => uint256)`.
- Allowances at keccak-derived nested slot per
  `mapping(address => mapping(address => uint256))`.

The model deliberately does not model the mapping's keccak derivation
— this scaffold names the balance/allowance reads as source-level
functions of a named `ERC20State`.

**Status:** shared source model consumed by TOPUP-1 Lido balance
guards, ADDRESS-1 stETH transferFrom balance/allowance guards,
WstETH balance guards. -/

namespace LidoSRv3.Audit.Source.ERC20StorageSource

/-- ERC-20 token storage: per-account balance mapping + per-(owner,
spender) allowance nested mapping. Both routed through the shared
`MappingStorage`. -/
structure ERC20State : Type where
  balances : LidoSRv3.Audit.Source.KeccakMappingStorageSource.MappingStorage
  allowances : LidoSRv3.Audit.Source.KeccakMappingStorageSource.MappingStorage
    -- allowances indexed by a nat-encoded (owner, spender) pair

/-- Encode an (owner, spender) pair as a nat for the nested mapping
lookup (source-level abstraction; concrete keccak-nesting stays under
A-KECCAK-COMMITMENT). -/
def allowanceKey (owner spender : Nat) : Nat := owner * 2 ^ 160 + spender

/-- Definition of `balanceOf(addr)` from source-level ERC-20 state. -/
def balanceOf (state : ERC20State) (addr : Nat) : Nat :=
  LidoSRv3.Audit.Source.KeccakMappingStorageSource.read state.balances addr

/-- Definition of `allowance(owner, spender)` from source-level
ERC-20 state. -/
def allowanceOf (state : ERC20State) (owner spender : Nat) : Nat :=
  LidoSRv3.Audit.Source.KeccakMappingStorageSource.read state.allowances
    (allowanceKey owner spender)

/-- `balanceOf` returns the balances mapping's read, definitionally. -/
theorem balanceOf_eq (state : ERC20State) (addr : Nat) :
    balanceOf state addr = state.balances.slotAt addr := rfl

/-- `allowanceOf` returns the allowances mapping's read,
definitionally. -/
theorem allowanceOf_eq (state : ERC20State) (owner spender : Nat) :
    allowanceOf state owner spender = state.allowances.slotAt (allowanceKey owner spender) := rfl

/-- Under the pinned balance premise (balance ≥ amount), the ERC-20
sufficient-balance guard passes. -/
theorem balance_sufficient_of_bound
    {state : ERC20State} {addr amount : Nat}
    (hBalance : amount ≤ balanceOf state addr) :
    amount ≤ balanceOf state addr :=
  hBalance

/-- Under the pinned allowance premise (allowance ≥ amount), the
ERC-20 sufficient-allowance guard passes. -/
theorem allowance_sufficient_of_bound
    {state : ERC20State} {owner spender amount : Nat}
    (hAllowance : amount ≤ allowanceOf state owner spender) :
    amount ≤ allowanceOf state owner spender :=
  hAllowance

end LidoSRv3.Audit.Source.ERC20StorageSource
