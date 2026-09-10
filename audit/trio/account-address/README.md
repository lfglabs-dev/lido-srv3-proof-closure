# Account/address independent source slice

This isolated Lake package is an audit implementation for P-ACCOUNT-1 and
P-ADDRESS-1 against `lidofinance/core` commit
`17005714f151e5502c559932319a3f2f74ac2436`.  It does not import the existing
registered guarantee models.  `PAccount1.lean` and `PAddress1.lean` follow the
registered source spans, the P-ACCOUNT-1 and P-ADDRESS-1 entries in
`audit/source-map.yaml` at repository commit
`caad1ef5e297202636e6fe643afa88fe8a62d618`. `PAddress1Physical.lean` models two
address-bearing storage words in `SRTypes.sol`, `SRLib.sol`, and
`NodeOperatorsRegistry.sol` that are outside the registered P-ADDRESS-1 span;
see its paragraph below.

`PAccount1.lean` models the ordered router validation errors, checked uint64
accumulation, and the packed accounting writes. `PAddress1.lean` models the
ordered guards and errors of `transferFrom`, `requestWithdrawals`,
`claimWithdrawalsTo`, and `unwrap`, including the packed withdrawal-request
owner/claimed fields. `Tests/Verity` contains concrete success, rejection,
rollback, packing, and mutant witnesses.

This is source-level Lean evidence. It is not a compiler, EVM, bytecode, or
deployment correspondence claim.

Integrated from `p-account-1-address-1` at `e04136dd` and the bounded
address changes at `39991771`. The bounded version uses `Fin (2^160)`
for packed owners and checks out-of-range conversions. Regression proofs
use kernel-checked `decide`; they do not add native-decision trust axioms.
Run `lake build AccountAddressChecks` from the repository root.

These are supplementary slices, not replacements for the registered parents.
ACCOUNT models balance writes, not the complete oracle report or subsequent
fee calculation. Registered IDs and module-word correspondence are supplied;
the list model needs distinct IDs to describe distinct physical records.
ACCOUNT packed words remain natural numbers; matching its physical storage
still needs uint256 bounds and a slot relation. Rollback is defined in this
isolated model, not derived from executing EVM calls.

ADDRESS supplies approval, set-operation, transfer and quote results. It does
not compute them from deployed contracts or prove general account-renaming
symmetry. Requests and claims cover one item only. The unsupported empty or
multi-item claim result is model-specific, not Solidity behavior. Assertion
failures and some callee errors are grouped. The request model now checks the
uint256 request-ID increment in source order and derives a representable,
strictly increasing ID from every successful execution, without an input-width
premise. This is auxiliary-model evidence, not physical-storage or EVM
correspondence. Exact ABI error bytes, arbitrary callbacks, events, enumerable
sets and the full batch storage relation remain outside these slices. The
ADDRESS now also has a physical `Fin (2^256)` storage-word layer for its packed
withdrawal-request word. Owner and claimed assignments are proved not to wrap;
the owner write preserves the complete upper 96-bit tail, while the claimed
write preserves every bit below 200 and at/above 208. The claimed field is a
full storage byte (bits 200..207) matching `AddressClaimBatchTx.requestClaimed`.
Concrete words exercise the timestamp, report-timestamp, and unused-high-bit
regions. Slot-key
derivation and execution-to-storage refinement remain outside the slice. These
packing lemmas are useful independently of those execution boundaries.

`PAddress1Physical.lean` adds physical-storage equivariance for two pinned
address-bearing packed words that are not in the registered P-ADDRESS-1 span.
The registered span (`audit/source-map.yaml`) is `WithdrawalQueueERC721.sol`
`transferFrom`, `WithdrawalQueue.sol` `requestWithdrawals` and
`claimWithdrawalsTo`, and `WstETH.sol` `unwrap`. The words modeled here are
pinned to the same `core` commit but live in other contracts: the SRStorage
`ModuleStateConfig` slot
(`SRTypes.sol:118-135`, module address in bits 0..159, reached through
`RouterState.moduleStates` at `SRTypes.sol:187`) and the first
`NodeOperatorsRegistry.NodeOperator` slot (`NodeOperatorsRegistry.sol:171-175`,
`active` byte then reward address in bits 8..167). An address renaming acts on
a word by rewriting exactly the address field; decoding the renamed word is
the renamed decoding, every non-address bit is preserved, encode and decode
are mutually inverse, no write wraps past `2^256`, renaming is functorial
(identity, composition, swap involution, injectivity), and the pinned source
comparisons (`SRLib.sol:203` duplicate scan, `NodeOperatorsRegistry.sol:373`
unchanged-address guard) are transported by an injective renaming. A
storage-level renaming over `Word -> Word` rewrites only the enumerated module
config slots and is stated with `keccak` and `ROUTER_STORAGE_POSITION` as
explicit parameters; no hash injectivity is assumed. Five mutant renamings
(wrong bit offset, 19-byte mask, fixed unrenamed module address, reserved-bit
clearing, `active`-byte clobber) are refuted by `decide`. This is
layout-level evidence only: it does not execute `_addModule`,
`setNodeOperatorRewardAddress`, or any EVM code, does not model the
EnumerableSet enumeration physically, and does not identify the parameterized
hash with keccak256. It is supplementary evidence only. The P-ADDRESS-1
entries in `audit/guarantees.yaml`, `audit/source-map.yaml`, and the Trust
registry were not changed for it, no registered span was widened to cover
these words, and P-ADDRESS-1 is not closed by this file.
