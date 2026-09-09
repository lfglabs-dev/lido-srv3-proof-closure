# SSZ-1: actual validator witness leaf

This increment proves the leaf used by `CLValidatorVerifier` from its semantic
witness fields and separate expected-withdrawal-credentials argument. It also
feeds that calculated leaf into the delivered index/header/proof consumer.
It does not substitute `SSZ.hashTreeRoot(Validator memory)` for the actual
calldata path and does not close SSZ-1.

Source: `lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`.
Accepted proof baseline: `9f1bc6dce3a76e31c31a398d72ea67ebfecfd965`.
Only the new source, tests and this audit directory are authored by this worker;
the integrator separately supplied the Solidity harness.

## Source correspondence

| Immutable source | New result |
|---|---|
| [CLValidatorVerifier.sol:60-85](https://github.com/lidofinance/core/blob/17005714f151e5502c559932319a3f2f74ac2436/contracts/0.8.25/CLValidatorVerifier.sol#L60-L85) | `sourceLeaf` selects pubkey root, expected credentials, effective balance, slashed, eligibility epoch, activation epoch, exit epoch and withdrawable epoch. `sourceMerkle` executes the four first-level, two second-level and one final pair call in source order. |
| [BLS.sol:539-561](https://github.com/lidofinance/core/blob/17005714f151e5502c559932319a3f2f74ac2436/contracts/common/lib/BLS.sol#L539-L561) | `sourcePubkeyRoot` checks actual calldata pubkey length 48 before calling SHA. `source_pubkey_padding` proves the scratch clear/copy interpretation produces all 48 input bytes followed by 16 zero bytes, independently of old lower scratch contents. |
| [BLS.sol:516-536](https://github.com/lidofinance/core/blob/17005714f151e5502c559932319a3f2f74ac2436/contracts/common/lib/BLS.sol#L516-L536) | `sourcePair` supplies the two ordered 32-byte words. `checkedSha` requires both call success and exact returndata size 32. The digest is read from the typed call result. |
| [SSZ.sol:251-266](https://github.com/lidofinance/core/blob/17005714f151e5502c559932319a3f2f74ac2436/contracts/common/lib/SSZ.sol#L251-L266) | Reuses universal uint64 endian correspondence. `sourceSlashed` executes the actual `slashed ? uint64(1) : 0` integer overload, then proves agreement with the independent SSZ boolean chunk. |
| [CLValidatorVerifier.sol:43-57](https://github.com/lidofinance/core/blob/17005714f151e5502c559932319a3f2f74ac2436/contracts/0.8.25/CLValidatorVerifier.sol#L43-L57) | The new calculated leaf is connected to the delivered successful header/index/fold checks. Full wrapper execution and its failure ordering remain open. |

The witness model contains raw pubkey octets, five uint64 fields and a Boolean.
It has no credentials field: the separate argument is authoritative, as in the
source. `proofValidator` is omitted from this leaf-only input because the leaf
function never reads it; the Solidity harness tests that independence.

## Independent specification and domain

`validatorTree` constructs a balanced eight-leaf SSZ container tree from the
semantic inputs. The pubkey digest is obtained by applying the abstract SHA
function to `pubkey ++ 16 zero bytes`. Integer chunks are independently
serialized with the delivered octet specification; slashed uses the Boolean
chunk. Neither the pubkey digest, encoded field chunks nor an expected final
digest is supplied as an independent input.

`source_leaf_eq_tree` proves exact outcomes for every typed witness and every
abstract SHA function under the standard successful adapter: length 48 yields
the independently merkleized tree digest, every other length yields
`invalidPubkeyLength`. `leaf_success_length` derives the real length guard from
success even for an arbitrary partial precompile. `checked_sha_success_iff`
exposes the actual conjunction of success, exact return size and returned word.
There is no truncation of an oversized pubkey into an admitted input.

The seven source pair calls are factored as `sourceMerkle` so their control
flow can be proved with an uninterpreted pair function without expanding
nested byte arrays. The independent container still comes from semantic fields;
this factorization changes no call, field or guard in the source interpretation.

`validator_header_consumer` returns a leaf produced by `sourceLeaf` and a single
50-sibling proof that passes the delivered digest fold and slot/proposer check.
The header root is computed from the same independent tree. The state placement
condition is structural: `subtreeAt state path = some (validatorTree ...)`.
There is no supplied leaf-digest equality or final-root match. The state path's
index relationship to `150 * 2^40 + offset` and its actual container/list
placement remain explicit input-selection obligations. The accepted wrapper
guards derive the offset domain and full header index. No deployed configuration
identity is inferred from the pinned configuration artifact.

## Validation actually performed

There are 12 new source theorems, 26 kernel-checked regression declarations and
six principal axiom queries. The final targeted command and its cache replay
are recorded in `validation.log`; the same source and tests passed compilation
before that replay. The padding and checked-SHA queries use `propext` and
`Quot.sound`; the other four additionally use `Classical.choice`. No new axiom,
`sorry`, `native_decide` or `bv_decide` is introduced.

Lean tests cover dirty scratch, the preserved last 16 pubkey bytes and zero
padding, lengths 0/47/49/256, length-before-SHA rejection, call failure,
short/long/empty returndata, ordered pair bytes, integer-cast Boolean encoding,
epoch byte order, semantic field positions and final container changes for
credentials, slashed and swapped epochs. Their small noncommutative test hash
is a regression witness, not an implementation of SHA or a collision claim.

The integrator's harness inherits the actual `CLValidatorVerifier` and invokes
its actual leaf function and `BLS.pubkeyRoot`. Six Solidity tests pass, including
three fuzz properties with 1024 runs each and seed `0x20260909`: arbitrary witness
fields, pubkey padding, and invalid pubkey lengths. Deterministic cases cover
uint64 extrema, both Boolean values, epoch order, credentials, pubkey byte 47,
missing/dirty padding and proof-array independence. The reference uses independent
octet serialization and a generic balanced level reduction. The exact harness,
command, log and hashes are recorded in `receipt.json`. No SHA failure, short
returndata or full-wrapper execution was forced in this Forge suite.

`check_source.py` checks full pinned file identities and textual anchors only;
it does not prove the transcription or compiler/EVM correspondence. Existing
wrapper/fold/endian proof inputs are reused only after byte comparison with the
accepted baseline. No full repository build is claimed.

## Remaining obligations

- **Typed memory and precompile adapter:** `clearUpper`/`sourcePubkeyBytes`
  interpret the 64-byte scratch block as typed octets; `digestBytes` interprets
  full-word mstores. Raw offsets, calldata bounds, copying, scratch aliasing and
  compiler/EVM execution are not proved. `ShaReply.output` denotes the output
  scratch word, with actual success and returndata-size fields checked before
  use. Its extraction from raw returndata and memory remains outside this model.
- **SHA and resources:** the successful adapter computes the abstract SHA of
  the supplied bytes and returns size 32. It does not prove SHA mathematics,
  collision resistance or sufficient gas. A deterministic partial precompile
  supports local failures and size errors but not a general gas-dependent
  failure schedule. Unlike this BLS helper, the delivered `SSZ.verifyProof`
  source has no returndata-size guard; that distinction remains unchanged.
- **State selection and anchoring:** deriving the validator-list/container path,
  fork configuration and physical state placement remains open. The final
  theorem composes successful leaf/header checks, not the full wrapper order:
  slot SHA/check, EIP-4788 root lookup, index selection, leaf computation and
  proof loop. Root-call return handling, trusted anchor provenance and deployed
  runtime identity are not closed by this result.

The next useful bounded consumer is `_verifyValidator`'s actual ordering and
return handling, especially the root staticcall's timestamp encoding, success
and empty checks, and short bytes32 decoding. It can reuse this leaf and the
accepted index/fold modules while retaining beacon-root trust separately.
Estimated 0.5–2 focused days for a typed call/return composition and targeted
tests, with medium confidence; raw EVM/refinement and deployed anchor provenance
remain separate work and are not included in that estimate.
