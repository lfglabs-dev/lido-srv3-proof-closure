# Account/address independent source slice

This isolated Lake package is an audit implementation for P-ACCOUNT-1 and
P-ADDRESS-1 against `lidofinance/core` commit
`17005714f151e5502c559932319a3f2f74ac2436`.  It does not import the existing
registered guarantee models.  The source spans are the P-ACCOUNT-1 and
P-ADDRESS-1 entries in `audit/source-map.yaml` at repository commit
`caad1ef5e297202636e6fe643afa88fe8a62d618`.

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
