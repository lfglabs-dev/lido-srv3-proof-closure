# Independent canonical state-placement reference

This executable check uses @chainsafe/ssz 1.2.1 and @chainsafe/persistent-merkle-tree 1.2.0, the exact versions in pinned Lido yarn.lock, against an independent Node SHA-256 sparse level reduction. schemas.json preserves the named Electra37/Fulu38 BeaconState field order from ethereum/consensus-specs v1.6.0 at f96d3e7acf35125295d234da4b0c67591fdef49c; each source URL and digest is recorded there. Both have validators at field11 and container depth6.

The registry encodes all eight semantic Validator fields, capacity2^40, recursively hashed zero padding and the actual uint256 little-endian length. All other BeaconState fields are supplied opaque SSZ roots. This checks canonical container/registry structure, not recursive serialization of every BeaconState field. Empty registries have roots but no semantic membership witness. Proof selection requires index below actual list length, stronger than merely index below capacity.

The independent implementation and library agree on64 registry/state cases and104 leaf proofs, including every47 state sibling and the length sibling40. The independently calculated header adds three siblings, giving50 and index1430*2^40+i. Tests cover first/last selected indices for list sizes0,1,2,3,4,7,8,9; uint64 boundaries, both booleans and named fork schemas. Concrete changed-length, unhashed-padding and reversed-proof mutations alter these SHA fixtures; no universal collision resistance or injectivity is inferred.

Six full header/witness fixtures are exported to vectors.json. generate_solidity.py deterministically renders their bytes into SszStatePlacement.t.sol. Its thin harness invokes the unmodified pinned CLValidatorVerifier with both configured base indices150*2^40. All six real Solidity0.8.25 tests pass: canonical proof accepted, modified list-length sibling rejected and incorrect level39 zero padding rejected. Only the EIP-4788 response is mocked, at the exact address and timestamp bytes. These are synthetic roots, not consensus-authenticated observations; no deployed fork/configuration, gas guarantee, SHA failure handling or universal Lean/EVM refinement is established.

Reproduction from this directory:

```sh
npm ci --ignore-scripts --no-audit --no-fund
node check.mjs
python3 generate_solidity.py
forge test --root . --match-contract SszStatePlacementReferenceTest -vv
```

The final recorded Node run used a fresh /tmp/lido-ssz-state-reference-portable directory. A normal npm install generated the portable lock, then npm ci succeeded and check.mjs reproduced byte-identical vectors.json/result.json. An earlier --prefix installation had embedded absolute-relative temporary package paths in the lock; independent review rejected that candidate's reproduction instructions. The repaired lock preserves every package version and integrity hash. npm-ci.log and validation.log record the successful clean installation and replay; no Lean source changed. Forge ran from the repository root with --root audit/ssz-state-placement/reference; its unchanged harness/configuration and input fixtures reuse the earlier actual execution log. receipt.json records commands, versions and hashes. No main/root dependency files were changed.
