# SSZ-1: computed-digest proof loop

This increment connects the decoded generalized index, the ordered sibling
hashes and the root actually calculated by `SSZ.verifyProof`. It also consumes
the delivered wrapper/index and little-endian results on one independently
constructed header proof. It does not close SSZ-1 or certify arbitrary EVM
calldata, deployed addresses or cryptographic collision resistance.

Source pin: `lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`.
Proof baseline: `42210924cd58ff751d2472f5ea998383fed4be7f`.
Only the new source, tests and this audit directory are authored by this worker;
the integrator separately supplied the actual-Solidity harness.

## Source correspondence

| Immutable source | Delivered interpretation |
|---|---|
| [SSZ.sol:179-197](https://github.com/lidofinance/core/blob/17005714f151e5502c559932319a3f2f74ac2436/contracts/common/lib/SSZ.sol#L179-L197) | `sourceVerify` rejects empty proof first. Input index is the decoded `Fin (2^248)`, including 0 and 1; proof is a typed list. |
| [SSZ.sol:198-231](https://github.com/lidofinance/core/blob/17005714f151e5502c559932319a3f2f74ac2436/contracts/common/lib/SSZ.sol#L198-L231) | `sourceFold` selects operand order using current parity before division by two, rejects zero parent before hashing, obtains the new accumulator from `Hash`, and rejects a failed hash. |
| [SSZ.sol:232-249](https://github.com/lidofinance/core/blob/17005714f151e5502c559932319a3f2f74ac2436/contracts/common/lib/SSZ.sol#L232-L249) | After typed iteration, the remaining index must be 1 before the computed digest is compared with root. |
| [CLValidatorVerifier.sol:43-58](https://github.com/lidofinance/core/blob/17005714f151e5502c559932319a3f2f74ac2436/contracts/0.8.25/CLValidatorVerifier.sol#L43-L58) | `pinned_encoded_header_verifies` composes the admitted wrapper index with both the slot arithmetic check and the computed-digest loop over the same proof. Leaf construction and beacon-root retrieval are still outside this consumer. |
| [CLValidatorVerifier.sol:89-99](https://github.com/lidofinance/core/blob/17005714f151e5502c559932319a3f2f74ac2436/contracts/0.8.25/CLValidatorVerifier.sol#L89-L99) | Reuses the delivered strict-pivot selection, checked neighbor, header prefix and uint64 slot/proposer encoding. |

Errors correspond to `InvalidProof()` (empty or wrong root),
`BranchHasExtraItem()`, empty revert on failed SHA call, and
`BranchHasMissingItem()`. The Lean error constructors classify these outcomes;
they are not a new proof of their ABI selector bytes.

## Independent specification and useful results

`Branch` constructs a finite Merkle path from root index 1. Its left and right
constructors use child indices `2*n` and `2*n+1`, respectively, and calculate
the appropriate ordered parent hash. It contains no source loop, shift,
scratch offset, terminal-index check or executable equality.

`verify_success_iff` proves exactly that source success is equivalent to a
nonempty independently constructed branch. The accumulator is calculated at
every level. No `finalRootMatches` flag, successful final digest assumption or
manually supplied computed root is an input. `verify_depth` derives both
`proof.length = log2(index)` and `1 <= proof.length <= 247`. The upper bound is
from the real uint248 index; there is no 32-level, 256-level or shorter proof
restriction imposed on the entry list.

`tree_branch_authenticates` and `tree_verifies` connect this relation to the
independent binary tree from `SszWrapperIndex`. Root-to-leaf traversal chooses
the leaf, canonical extraction supplies the leaf-to-root siblings, and the
resulting source fold reaches the mathematical tree digest. `branch_graft`
proves the required composition of subtree paths. This is a construction
correctness result and does not assume hash injectivity.

The final consumer `pinned_encoded_header_verifies` uses a successful wrapper
result and a state-tree path whose independent index is
`150 * 2^40 + offset`. That **input path/validator selection correspondence is
still explicit**, not proved from all BeaconState fields or validator-list
layout in this increment. The wrapper guard derives `offset < 2^40`; this and
the independent positional encoding derive state depth 47. The header prefix
left/right/right produces `1430 * 2^40 + offset` at depth 50. The same extracted
50-sibling proof passes the computed-digest loop and the concrete uint64
little-endian slot/proposer arithmetic check. Its root is calculated from the
same independent header tree. The source configuration artifact has equal
previous/current bases; no deployed immutable identity is inferred from it.

## Validation actually performed

The targeted Lean build, six principal axiom queries and 26 kernel-checked
regression declarations are recorded in `validation.log` and `receipt.json`.
The six queried results depend on `propext`, `Classical.choice` and `Quot.sound`;
no new axiom, `sorry`, `native_decide` or `bv_decide` is introduced.

Lean tests distinguish empty-first, extra-before-hash, hash-failure-before-later
structural rejection, missing-before-root, operand reversal, parity selected
after shifting, skipped accumulator update, sibling reordering and the wrong
header index. Both uint248 depth-247 edges succeed, a 248th sibling is extra
and a 246-item branch at depth 247 is missing. Noncommutative arithmetic hashes
are test witnesses, not SHA models; commutative addition is used only for the
large-depth boundary checks.

The integrator's harness imports the actual library and executes
`SSZ.verifyProof`, with high-level SHA256 and original-index division as its
reference. Its six tests include three fuzz properties, each with 1024 runs
and seed `0x20260909`, full depth 247, header-relative depth 50, root mismatch,
structural error precedence, operand/path mutations and empty/root indices.
The exact harness, command, log and configuration hashes are recorded here.
These finite tests support the source transcription; they are not universal
Lean-to-EVM refinement. `check_source.py` compares exact pinned git objects and
textual anchors only, not program semantics.

## Remaining obligations

- **Raw memory/calldata and gas:** the model iterates a typed list; it does not
  prove `proof.offset`, `shl(5, proof.length)`, wrapped `end`, calldata loads,
  scratch-memory writes or EVM loop termination on forged pointers. A later
  byte-level consumer must establish those representation and memory facts.
- **SHA execution:** `Hash` is an abstract deterministic partial function for
  ordered pairs. `none` represents call failure; `some digest` represents a
  standard successful SHA precompile writing its complete digest. The Solidity
  loop does **not** check `returndatasize`; no such guard is invented here.
  Nonstandard short successful return data, scratch-memory residue and a
  gas-dependent failure schedule are not modeled. The tree consumer specializes
  to a total pair function and therefore does not prove gas sufficiency. Forge
  tests do not force SHA failure or malformed precompile return behavior.
- **Full witness/wrapper:** deriving the selected validator path and leaf from
  the actual fields, pubkey padding, validator container/list shape, fork
  configuration and EIP-4788 root retrieval remains necessary. The theorem
  composes the two successful checks, not their complete failure ordering or
  `_verifyValidator` execution. Existing `fls` assembly and constructor/deployed
  configuration boundaries remain as documented in the wrapper increment.
- **Cryptographic authenticity:** agreement with the calculated root does not
  prove unique tree contents or resistance to hash collisions. That trust
  assumption is distinct from the now-proved ordering and digest calculation.

A useful next bounded result is the validator container: derive the eight
actual leaf chunks and its three pair-hash levels from an independent SSZ
container specification, then plug that digest into this tree consumer.
Estimated 0.5–2 days for the container proof and targeted differential tests,
with medium confidence; full list-layout/fork selection and raw calldata/EVM
refinement are separate obligations and are not included in that estimate.
