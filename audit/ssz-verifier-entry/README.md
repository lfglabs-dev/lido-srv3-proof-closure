# SSZ-1: ordered validator verifier entry

This increment connects the actual validator verifier entry to the delivered
index, leaf, endian and digest-fold proofs. It consumes the root call's returned
bytes at the exact timestamp request and preserves the source's error order.
It reduces the typed wrapper-composition obligation; it does not close SSZ-1,
authenticate a beacon root, or prove deployed EVM execution.

Source pin: `lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`.
Accepted dependency baseline: `c22ce0acbe53d9fae3adb2eef2d4695cba8f13fd`.
The worker authors only the new source, tests and this audit directory. The
integrator separately supplies the actual Solidity harness.

## Source correspondence

| Pinned source | Typed interpretation |
|---|---|
| [CLValidatorVerifier.sol:44-56](https://github.com/lidofinance/core/blob/17005714f151e5502c559932319a3f2f74ac2436/contracts/0.8.25/CLValidatorVerifier.sol#L44-L56) | `sourceEntry` executes slot check, root lookup, configured index, calculated leaf and digest fold in order. A single proof, semantic witness, slot, proposer and expected credentials flow through all stages. |
| [CLValidatorVerifier.sol:89-95](https://github.com/lidofinance/core/blob/17005714f151e5502c559932319a3f2f74ac2436/contracts/0.8.25/CLValidatorVerifier.sol#L89-L95) | `sourceSlot` performs checked BLS SHA before proof-length subtraction/index access and comparison. It connects to the previously delivered slot/proposer sibling theorem under the standard SHA adapter. |
| [CLValidatorVerifier.sol:97-108](https://github.com/lidofinance/core/blob/17005714f151e5502c559932319a3f2f74ac2436/contracts/0.8.25/CLValidatorVerifier.sol#L97-L108) | `sourceWrapper` reuses actual configured fork selection and neighbor/concat guards. `sourceRoot` calls the oracle with the literal EIP-4788 address and ABI timestamp octets, then decodes the returned bytes. |
| [BLS.sol:516-561](https://github.com/lidofinance/core/blob/17005714f151e5502c559932319a3f2f74ac2436/contracts/common/lib/BLS.sol#L516-L561) | Slot SHA and the eight leaf SHA calls require both call success and returndata size exactly32. The existing leaf proof selects semantic fields and computes the padded pubkey digest and seven pair hashes. |
| [SSZ.sol:179-249](https://github.com/lidofinance/core/blob/17005714f151e5502c559932319a3f2f74ac2436/contracts/common/lib/SSZ.sol#L179-L249) | `foldHash` checks success only, without inventing a returndata-size guard. The accepted digest-carrying loop preserves parity-before-shift, extra-before-hash, missing-before-root and empty-first behavior. |

`RootOracle` receives the actual 160-bit destination and complete calldata;
it returns a success flag and octets. The timestamp is uint64 zero-extended to
a 32-byte big-endian ABI word without a selector. It is not an SSZ little-endian
chunk. `firstWord` reconstructs bits from the first 32 big-endian octets.
`first_word_encoded` proves the universal bytes32 roundtrip with an arbitrary
suffix. This is a typed ABI interpretation, not a proof of solc's decoder.

A failed root call or successful empty response gives `rootNotFound`. Successful
1..31-byte responses give `abiDecodeFailure`. At least 32 bytes decode the first
word and permit arbitrary suffix bytes. `root_reply_success_iff` proves these
successful response requirements and equality to the actually decoded word.
The error constructors denote source error classes; their ABI revert encoding
and any compiler-generated memory failures are not derived in Lean.

## Independent success result and domain

`entry_success_iff` characterizes success through computed source components
and an independent inductive Merkle `Branch`. That specification constructs
indices and ordered digest parents from a root, independently of the executable
shift loop. `entry_success_returned_bytes` makes the binding explicit: a successful
entry implies a successful response with at least 32 bytes and a branch whose root
is `firstWord` of those very bytes. No final-root-match Boolean, independently
supplied pubkey digest, or assumed calculated leaf is an entry input.

`validator_entry_consumer` independently builds the validator's eight-leaf tree
from semantic witness fields and expected credentials, places that subtree in
the supplied state tree, extracts the canonical header branch and proves the
whole typed entry succeeds. It returns the same 50-element proof used for the
slot and validator checks. The response condition is explicit and trusted:
the oracle at the exact address/timestamp returns the computed header root's
bytes, optionally followed by a suffix. This condition is not evidence of an
authentic, current, or deployed beacon root.

The general source accepts any typed configuration, uint64 timestamp/slot/proposer,
uint256 offset and finite proof/pubkey lists. `entry_success_domains` derives
pubkey length 48 and proof length between 2 and 247 from success. The upper bound
comes from the actual uint248 index; the lower bound comes from checked
proof.length-2. No artificial 32- or 256-element list bound is assumed.

The final structural consumer instantiates the delivered configuration artifact
with first-validator index `150 * 2^40` and power 40. The source guards derive
its offset bound `offset < 2^40`. Equal previous/current values in that artifact
are not a test of fork direction and do not prove deployed configuration identity.
State path index selection and `subtreeAt state path = some (validatorTree ...)`
remain structural premises; canonical consensus list/container placement and
state reachability are not inferred from them.

## Validation actually performed

There are 13 source theorems, 35 kernel-checked regression declarations and seven
principal axiom queries. The targeted Lean build of source and tests passes
790 jobs, with no warnings; the exact log is `validation.log`. The roundtrip,
root-response and standard-slot queries use `propext` and `Quot.sound`. The four
entry/consumer queries additionally use `Classical.choice`. There is no new
axiom, `sorry`, `native_decide` or `bv_decide`. This is not a full repository build.

Lean regressions cover timestamp octets and uint64 extrema; address identity;
most/least significant decoded bytes; root widths 0/1/31/32/33/255; suffix
acceptance; failed calls with nonempty data; SHA-size and SHA-failure priority
over short proof/root/index/key failures; slot subtraction and mismatch priority;
root guard/decode before index and key; configured offset guard before key;
key failure before fold; complete 50-sibling admission; altered returned root;
49/51-sibling missing/extra precedence; and changed timestamp/address. The same
short-SHA reply is rejected by BLS and admitted as a scratch word by the fold
adapter, demonstrating the actual guard distinction. These control-flow fixtures
use a deterministic constant toy hash; they do not claim SHA collision resistance
or prove mutations of arbitrary witness fields change a cryptographic root.

The integrator's harness invokes inherited actual `_verifyValidator` and
`_getParentBlockRoot` with solc 0.8.25. Four tests pass, including two fuzz
properties with 1024 runs each and seed `0x20260909`. Its full-entry reference
independently computes semantic field chunks, leaf merkleization and a 50-sibling
fold, with the required slot/proposer sibling. It mocks the exact destination and
ABI timestamp request with this synthetic root. Tests cover changed timestamp,
changed root, arbitrary return widths 0..255, explicit 0/1/31/32/33/255 boundaries,
slot/root/decode/index/key error priority and length 1 arithmetic panic 0x11.
The mock is not authenticated consensus state. This Forge suite does not force
SHA failure or short SHA returndata; Lean covers the typed guard distinctions.

`check_source.py` checks six complete pinned file identities, 35 ordered textual
anchors and the absence of a returndata-size guard in the proof-fold source.
This is a transcription aid, not semantic or compiler equivalence. The accepted
proof dependencies and build configuration are byte-compared to the baseline.
`receipt.json` records exact inputs, hashes, commands and logs, including the
integrator's harness and Solidity log. Receipt self-hashing is intentionally
excluded; later immutable Git history/review supplies its identity.

## Remaining obligations

- **Root provenance:** the oracle response condition is a trust boundary. EIP-4788
  storage/timestamp policy, canonical consensus anchoring, deployed address/code,
  and runtime configuration are not established by a mocked or supplied response.
- **Raw execution:** typed byte lists and error classes do not prove raw calldata
  offsets/end arithmetic, pointer wrapping, memory allocation/copying/aliasing,
  staticcall side effects, compiler ABI decoding/revert bytes or EVM refinement.
  The SHA output field denotes the typed scratch word; nonstandard short-returndata
  memory behavior is outside the interpretation, especially for the size-unchecked
  SSZ fold. BLS retains both actual checks.
- **SHA and resources:** the same deterministic precompile function is used for
  all stages. It can model input-dependent failures, but not arbitrary gas/history
  dependent schedules. The success consumer uses the explicitly total standard
  SHA adapter. SHA mathematics, collision resistance and sufficient gas are open.
- **Index and placement:** the delivered `Nat.log2` interpretation of GIndex fls
  still lacks universal assembly refinement. Consensus path selection, list/container
  layout, structural witness placement and deployed fork provenance remain open.

A useful next obligation is to derive canonical validator state placement/index
from the pinned consensus schema and selected fork, or to discharge the external
root/runtime correspondence in the existing transaction model. Neither is claimed
by this ordered entry result.
