# SSZ-1: canonical validator registry and state-container placement

This increment derives the validator's state position from a named consensus
schema and an actual semantic list member. It discharges the entry consumer's
previous index/path, branch and subtree-placement premises, then obtains the
same 50-element proof and successful typed `sourceEntry`. It proves the canonical
container/registry spine; other named BeaconState fields remain opaque SSZ roots.
It does not close SSZ-1 or establish an authenticated, reachable or deployed state.

Lido source pin: `17005714f151e5502c559932319a3f2f74ac2436`.
Accepted dependency baseline: `8ef973fa37997e55061a95fce1a41bf3cfe968e7`.
Additional official schema snapshot: `ethereum/consensus-specs` release `v1.6.0`,
commit `f96d3e7acf35125295d234da4b0c67591fdef49c`. This snapshot is explicitly
selected for this result; it is not a Lido dependency pin or deployed-fork fact.

## Schema provenance and independent construction

The bundled immutable schema files, their URLs and hashes are in
`schema-sources.json` and `consensus-specs/`; the upstream CC0 license is included.
The offline checker compares every ordered field name in Lean to the actual
schema declaration and checks the real capacity and length-serialization rules.

| Immutable specification | Construction and derived fact |
|---|---|
| [Electra BeaconState](https://github.com/ethereum/consensus-specs/blob/f96d3e7acf35125295d234da4b0c67591fdef49c/specs/electra/beacon-chain.md#beaconstate) | 37 ordered fields; validators is field 11. `electraFields` records every name, through pending_consolidations. |
| [Fulu BeaconState](https://github.com/ethereum/consensus-specs/blob/f96d3e7acf35125295d234da4b0c67591fdef49c/specs/fulu/beacon-chain.md#beaconstate) | 38 fields, preserving validators at 11 and appending proposer_lookahead. The latter is a Vector in this snapshot; its internal encoding remains opaque here. |
| [Inherited phase0 definitions](https://github.com/ethereum/consensus-specs/blob/f96d3e7acf35125295d234da4b0c67591fdef49c/specs/phase0/beacon-chain.md) | Validator's eight semantic fields, Bytes48 pubkey, registry limit 2^40 and five header fields. |
| [SSZ merkleization](https://github.com/ethereum/consensus-specs/blob/f96d3e7acf35125295d234da4b0c67591fdef49c/ssz/simple-serialize.md#merkleization) | Ordered container roots padded to the next power of two; composite-list element roots padded to capacity, then mixed with the actual uint256 little-endian length. |
| [Generalized indices](https://github.com/ethereum/consensus-specs/blob/f96d3e7acf35125295d234da4b0c67591fdef49c/ssz/merkle-proofs.md#get_generalized_index) | Container width and field position, followed by the List data edge and element position, independently determine the path and generalized index. |

The pinned Lido helpers `lib/pdg.ts`, `lib/top-ups.ts` and their Solidity test
trees receive a GI and build sparse layout fixtures from it. They do not encode
a named BeaconState or the real list-length mix-in; absent mapping nodes default
to zero at arbitrary heights. They are not used as canonical-schema authority.
The pinned dependency lock supplies a generic SSZ library, not a BeaconState
schema. Equal previous/current indices and pivot 0 in the Lido configuration
artifact do not prove deployed configuration identity or test fork direction.

## Generic tree and list agreement

`SszPerfectTree.perfectTree` constructs a complete binary spine over ordered
subtree values. It mentions no BeaconState, validators position or source GI.
`orderedMerkle` independently reduces a list of chunks by halves. The theorem
`perfect_digest_ordered` relates tree evaluation to that ordered-list algorithm.
`chunks_padding` proves a bounded list yields exactly its actual values followed
by the required number of bottom-level zero chunks; no input element is dropped.
Zero subtrees are recursively hashed, not replaced with zero at every height.

`addressPath` recursively bisects the index interval. Generic theorems prove its
length, generalized index and selected subtree for every depth and index below
2^depth. Canonical sibling existence follows from structural traversal, with
sibling hashes calculated from the same tree. Depth 40 is instantiated through
these generic lemmas; neither proofs nor tests materialize a full 2^40 tree.

## Registry, container and actual entry consumer

`ValidatorValue` contains semantic witness fields, its own withdrawal credentials
and the Bytes48 length domain. The delivered `validatorTree` computes the pubkey
padding, field chunks and eight-leaf tree; no element digest is an input.
`registryData` places those subtrees in list order and bottom-level zero chunks
after the actual list end. `registry_chunks` proves the exact ordered/padded root
list under `values.length ≤ 2^40`. `registryTree` adds the computed right child
`lengthChunk values.length`, independently serialized as 32 little-endian octets.
`length_encoding_no_wrap` derives faithful uint256 embedding from that capacity.
`registry_length_sibling` places the actual length immediately above the 40 data
edges, at sibling position 40 in the bottom-up state branch.

`stateElement` uses the full named schema: it computes validators, reads the
opaque root of each other declared field, and pads beyond the declared field
count with zero chunks. An input at the name validators is ignored.
`state_root_ordered_fields` connects the container to its ordered field-root list
and exact padding; `state_digest` relates its tree digest to this specification.
Opaque fields include the state's slot, fork and other nested values. Their
internal encodings, cross-field consistency and consensus reachability are not
established by their names or by the new tree.

Both schema counts are greater than 32 and at most 64, deriving container depth 6.
Validators' position 11 therefore gives GI 75; its List data child has GI 150.
A member's state path is the seven bits 0010110 followed by its 40-bit address.
The derived index is `150 * 2^40 + i`, state proof length 47. Header placement adds
three edges, yielding index `1430 * 2^40 + i` and proof length 50.

`canonical_validator_entry` takes a semantic list with its actual SSZ capacity
bound, a member `i : Fin values.length`, the schema, opaque other field roots,
header/timestamp inputs and the existing trusted response condition. It derives
an admissible uint256 source offset, the configured wrapper's successful index,
canonical branch existence and semantic validator subtree placement, then calls
the accepted entry consumer. The final statement has no `hi`, `hp`, `hplace`,
leaf-digest equality or root-match Boolean premise. The source witness and
expected credentials come from the selected semantic list value.

The oracle condition still explicitly says that the exact address/timestamp
request returns the independently constructed header root's bytes (with an
optional suffix). It is a trust condition, not proof of EIP-4788 authenticity.
The standard total SHA adapter also remains explicit; no gas or collision
resistance theorem is added.

### Membership and model domain

The canonical-list theorems and final consumer require length at most 2^40 and
an actual member. Raw tree/root constructors are total mathematical functions;
for an oversized list they denote a depth 40 truncation, not valid SSZ encoding.
The capacity premise in `registry_chunks` prevents that case and proves no
valid element is lost. No source input is restricted to an artificial smaller
capacity or proof length.

`i < values.length` implies the source's capacity guard `i < 2^40`. The converse
is not claimed. The first padded index can satisfy the actual Solidity neighbor
guard while failing list membership. `registry_padding_subtree` identifies that
position structurally as a zero chunk. With an arbitrary hash function it does
not follow that every validator digest differs from padding, or that a verifier
can authenticate membership from the capacity guard alone. The tests expressly
separate these propositions.

## Kernel validation

There are 26 source theorems (9 generic, 17 state/registry), 39 regression
declarations and nine principal axiom queries. The exact targeted command and
successful 792-job log are recorded in `receipt.json` and `validation.log`.
Seven queries use `propext` and `Quot.sound`; length embedding/encoding and the
final entry consumer also inherit `Classical.choice`. There is no new axiom,
`sorry`, `native_decide` or `bv_decide`. No full repository build is claimed.

Tests reduce all positions for depths 0..5, compare list and tree merkleization,
and detect reordered/dirty padding with a noncommutative toy hash. Depth 40
selection is checked symbolically at zero and 2^40-1. Further cases cover both
schema counts and neighboring fields; the old 32-field GI 86 versus GI 150;
wrong data/length edge; little-endian length octets including 2^40; omitted,
swapped and wrongly encoded length mix-ins; empty/singleton membership; the
first padding subtree; the actual length sibling; derived source admission of
a member; and capacity admission of the first nonmember. Concrete toy-hash
inequalities are regression witnesses, not universal cryptographic assertions.

## Independent executable reference supplied by the integrator

The separately authored `reference/` uses the exact versions from Lido's pinned
lock: `@chainsafe/ssz` 1.2.1 and `@chainsafe/persistent-merkle-tree` 1.2.0.
An independent Node SHA-256 sparse level reduction agrees with the library on
64 state/registry cases and 104 selected-member proofs. Every 47-element state
branch and its actual length sibling are compared, then extended to the header.
The cases use both named schemas, list sizes 0/1/2/3/4/7/8/9, first/last members,
uint64 boundaries and both Boolean values. Other state fields remain opaque roots
in both implementations. This is a finite differential check, not a universal
Lean-to-library equivalence theorem.

Six generated full header/witness fixtures also pass the actual inherited
`CLValidatorVerifier` compiled with Solidity 0.8.25. Each test accepts the canonical
proof, then rejects a changed length sibling and incorrect level 39 zero padding.
The EIP-4788 response is mocked at the exact address and timestamp; roots and
validators are synthetic. This reference proves no deployed state, authenticated
anchor, gas guarantee or forced SHA-failure behavior.

`reference/receipt.json` records the actual commands, versions, logs, input hashes
and reproduction instructions; its 12 artifact hashes and six source hashes were
checked before integration. The outer receipt additionally hashes that receipt
and all reference artifacts. These checks reuse the integrator's exact successful
logs; no redundant Forge run or new reference execution is claimed by this worker.
`check_source.py` separately verifies bundled schema identities, field extraction,
length/capacity rules, six complete Lido pinned source/config files and the packed
configuration arithmetic. It is a source comparison aid, not semantic/EVM proof.

## Remaining boundaries

- Other field roots are opaque. This is the canonical container/registry spine,
  not a recursive implementation of all BeaconState SSZ types or state validity.
- The external schema release is explicit. Neither it nor Lido's config artifact
  establishes the runtime fork, contract configuration, canonical state or anchor.
- The trusted oracle response, standard SHA adapter, gas sufficiency, cryptography,
  calldata/memory/ABI semantics, EVM/compiler refinement and GIndex fls assembly
  boundary from the delivered entry/index proofs remain unchanged.
- No deposit-amount domain, common source node, metadata or unrelated lane is edited.
