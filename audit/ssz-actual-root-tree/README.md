# Actual root to independent validator tree

Base: integrated `14a96a3180ac9fb81f853db36af3b630c1d5891f`.
Public identifier: SSZ-1. New consuming theorem:
`LidoSRv3.Audit.Guarantees.PSsz1.actual_root_staticcall_validator_tree`.

## Improvement and consumer

The existing #311 theorem derives an independent Merkle branch against the
actual EIP4788 reply, but expresses its leaf as an existential digest obtained
from `sourceLeaf`. The independent SSZ validator-tree equality previously
available in `SszValidatorLeaf.source_leaf_eq_tree` used `standardSha`, which
makes every SHA call successful with a 32-byte reply.

This increment keeps the original executable and all its guards. From actual
whole-entry success it derives that the leaf equals the independent eight-field
validator tree, using the digest output of the same interpreted SHA replies.
The public theorem consumes that equality and projects every successful proof
edge to the same byte-hash interpretation. The tree is thereby linked to the
root returned by the actual timestamp STATICCALL. Its only propositional input
is whole-entry success. No global SHA success, global return width, assumed
intermediate result, correct leaf, or correct root premise is introduced.

`outputSha` is only the output field of each existing typed reply. It is not a
new cryptographic correctness axiom. The original partial SHA interpreter
still executes; unused inputs may fail or have nonstandard reply widths.
The kernel regression executes the full typed entry with such an interpreter,
then consumes the public theorem on that exact success.

## Pinned source correspondence

`lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`:

- `contracts/0.8.25/CLValidatorVerifier.sol:43-85`: slot check, timestamp root
  call, index, leaf and proof order; the eight semantic fields, supplied expected
  credentials, four bottom pairs, two middle pairs and final pair.
- `contracts/common/lib/BLS.sol:516-561`: two full bytes32 inputs, pubkey length
  48, upper scratch zeroing and 48-byte copy, producing pubkey plus 16 zeros;
  actual call success and exactly 32 returned bytes checked for these helpers.
- `contracts/common/lib/SSZ.sol:179-249`: current-index left/right selection and
  successful hash output consumed at each branch edge. This proof loop checks
  CALL success, not returndata width; no missing width guard is invented.
- Existing little-endian/uint64 and slashed-as-uint64 proofs transport the same
  actual field encodings into the independent container tree.

All imported executable sources are byte-identical to integrated main. Only
new theorems, a domain regression, facade/Trust registration and this dossier
are added. The reviewed #311 full-verifier Solidity tests and correspondence
remain applicable by exact source identity; no fresh Solidity run is claimed.

## Boundary

This is the existing typed source-entry result. SHA output denotes its modeled
scratch digest; it does not newly prove raw return-data copying or cryptographic
SHA correctness. The declared external/cryptographic/compiler/gas/consensus
boundaries retain their scope. It does not connect this typed entry to #310's
compiled memory harness, authenticate an EIP4788 root, establish full raw ABI
admission/declared-list equality, or produce a complete SHA call transcript.
Those stronger properties are not closed by the new theorem.

## Reproduction

`lake build LidoSRv3.Tests.SszActualRootTreeRegression LidoSRv3.Audit.AllGuarantees LidoSRv3.Audit.Trust`

`python3 audit/ssz-actual-root-tree/validate.py`

`python3 scripts/check_trust_axioms.py`

The scoped identity checker verifies all imported local source bodies against
the integrated base and all package bodies against their eleven pins, then
recomputes the new public/helper/regression transitive axiom sets. Existing
receipts under `audit/ssz-root-call-composition/` retain their historical scope.
