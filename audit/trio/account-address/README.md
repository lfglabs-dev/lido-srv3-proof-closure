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
accumulation, and the packed accounting writes. `ReportWriteFee.lean` carries
those writes into the fee getter over physical storage (see below).
`PAddress1.lean` models the
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
`PAccount1` itself still models balance writes on natural-number words with a
parallel module list; rollback is defined in this isolated model, not derived
from executing EVM calls.

`ReportWriteFee.lean` (pin `17005714`, SRLib 873-892, StakingRouter 808-873 and
885-893, Accounting 265-301 / 306-333 / 335-358) replaces that parallel list
by physical storage. `Core` is a slot map of `Fin (2^256)` words with unwritten
slots reading zero. `Layout` gives the pinned router keys: the router
accounting word at router slot 3 and each `ModuleState` as four consecutive
words (config, deposits, accounting, name) from the `moduleStates` mapping key,
where `moduleBase` stands for the keccak-derived key and its collision-freedom
`Layout.Separated` is a caller premise. `reportValidatorBalances` writes the
uint64-cast gwei into the low 64 bits of each registered module's accounting
word through `Core.write` and the checked uint64 total into the router word;
`getStakingRewardsDistribution` reads the same slots through `Core.read`,
decodes the physical config word (address, uint16 fees, status byte), skips
zero allocations in registration order, applies `_computeModuleFee` with its
uint96 casts, sends a Stopped module's fee to the treasury while keeping it in
the total, adds with the checked uint96 total, enforces the post-loop
`assert`, and returns the empty success when the router total is zero.
`calculateProtocolFees` consumes that result with the LIP-12 guard, the checked
`postInternalEther - feeEther` subtraction, and the per-module floor shares.

`ReportFeeMint.lean` continues that physical report write through one
post-write `getStakingRewardsDistribution` result, checked uint256
Accounting 317/323/325/331 products, and the source-ordered
`Accounting.sol:403-406` Lido mint. Its mint invokes
`StETHMintShares.mintShares` on a single StETH state: the abstract account
`shares` map and the `lido.StETH.totalAndExternalShares` packed word are
therefore read and written by the same execution. The Lido caller/recipient
identity is the Accounting address, the stopped guard precedes `_mintShares`,
and the two transfer events use the post-mint internal-ether share-rate
numerator. Fee arithmetic and mint failures roll the entire composed world
back; a zero fee reaches neither mint nor mint events. This is supplementary
evidence for the registered `P-ACCOUNT-1`, not a new guarantee ID.
The public `actual_report_fee_mint` theorem consumes this execution. Locator
resolution and call context remain supplied; intervening report operations,
`_distributeFee` and `reportRewardsMinted` are outside this continuation.
See [the exact mint dossier](../../account-actual-mint/README.md) for its
physical-word, abstract-map, arithmetic and transactional rollback scope.

Proved: a committed report sets exactly the low uint64 of each registered
accounting word and of the router word, preserves every other bit (including
`exitedValidatorsCount`) and every other slot (including the config words),
and every revert restores the snapshot; after a committed report the getter's
total and per-module allocations are the reported gwei in wei; every
successful distribution has equal-length arrays (the Accounting 279-280
asserts), module fees inside the total fee, the total inside the precision
cap, and only registered nonzero-allocation ids; the Accounting 340 assert
holds on every reachable path; module shares plus treasury shares equal the
minted shares, so 351 cannot overflow and 356 cannot underflow. Regression
vectors use kernel-checked `decide` on concrete words, including the Stopped,
skip, empty-success, status-panic, cap-panic, rollback, non-profitable, and
checked-subtraction cases.

Still OPEN (P-ACCOUNT is not closed): the keccak slot-key derivation is not
computed; the registered-id order is an input standing for the `EnumerableSet`
values array, whose own slots are not modeled; deposits and name words and the
router's other words are outside the slice; the config word is only read here;
uint256 overflow of the Accounting 325 and 331 products is unmodeled in the
older `ReportWriteFee.calculateProtocolFees` helper (the new public
`ReportFeeMint` consumer executes checked products); the
uint96 casts are shown load-bearing on report-inconsistent storage only, and
their exactness on report-consistent storage is not proved (HOLD); a status
byte above 2 is modeled as the storage-load panic; the getter is modeled over
arbitrary storage, so words written by other paths are read as-is; and there
is no compiler, EVM, bytecode, or deployment correspondence.

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
