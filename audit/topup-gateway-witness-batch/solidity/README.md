# Actual gateway witness and limit execution

The harness inherits unmodified pinned TopUpGateway and CLValidatorVerifier. It executes the real public topUp, including the actual verifier, paired witness/pending processing, wei limits and post-return timing write. Internal source setters and role grant prepare a standalone fixture; this is not an initialized production proxy. A locator fixture selects a router recorder. Only that external router boundary and the exact EIP-4788 root response are mocked. No module, funding or beacon effects are claimed here.

Independent test code builds two validator container roots from all fields and one common type-2 WC, sparse zero padding to capacity2^40, the actual list-length mix-in, a37-field state padded to64 with validators at11, and a header with state at3. Other state fields are explicitly opaque roots. The actual verifier receives the resulting50-sibling proofs. This is a synthetic canonical fixture, not authenticated consensus membership or a deployed schema fact. No Lido hashing helper constructs the expected proof/root.

Seven tests pass, including three1024-run fuzz properties: arbitrary uint64 balances/pending and exit/slash fields; focused headroom/minimum thresholds; arbitrary physical configuration words. The latter checks the original getters against independent masks at namespace0x22e512057841e2bc1e6d80030c8bb8b4935377af2e64ba9bf8e6a3e88fb32200: count low64, target bits160–223, minimum next-slot low64. The slot-zero layoutOnly variable is solely a compiler type-layout witness; real reads use the source namespace.

Deterministic checks cover nonzero limit pairing and wei units, index0 admission, wrong pubkey before duplicate index, activation before proof error, proof rejection before pending overflow, common-WC mismatch, exited/slashed rows still requiring valid proofs but skipping overflowing pending addition, paired length rejection and zero epoch-divisor panic. Timing follows total limits despite the recorder performing no allocation. These finite checks complement the new Lean consumer; they do not prove its full Solidity/EVM refinement, role/configuration reachability, reentrancy exclusion or an aggregate block cap.

Reproduction from the proof checkout (Forge1.5.0, solc0.8.25, repository foundry.toml):

```sh
mkdir -p /tmp/lido-topup-wei-deps
cd /tmp/lido-topup-wei-deps
npm pack @openzeppelin/contracts@5.2.0
tar -xzf openzeppelin-contracts-5.2.0.tgz
cd /path/to/lido-srv3-proof-closure
FOUNDRY_SRC=audit/topup-gateway-witness-batch/solidity FOUNDRY_TEST=audit/topup-gateway-witness-batch/solidity forge test --remappings contracts/=lido-core/contracts/ --remappings @openzeppelin/contracts-v5.2/=/tmp/lido-topup-wei-deps/package/ --match-contract TopupGatewayWitnessBatchTest --fuzz-runs 1024 --fuzz-seed 0x20260909 --out /tmp/lido-gateway-witness-solidity-out --cache-path /tmp/lido-gateway-witness-solidity-cache -vv
FOUNDRY_SRC=audit/topup-gateway-witness-batch/solidity FOUNDRY_TEST=audit/topup-gateway-witness-batch/solidity forge inspect GatewayWitnessHarness storageLayout --json --remappings contracts/=lido-core/contracts/ --remappings @openzeppelin/contracts-v5.2/=/tmp/lido-topup-wei-deps/package/ --out /tmp/lido-gateway-witness-solidity-out --cache-path /tmp/lido-gateway-witness-solidity-cache
```

The actual run reused the byte-verified5.2.0 archive/package from the earlier units/layout checks. receipt.json records archive hash, every compiler-consumed source identity, command results and four local artifact hashes. No fresh npm installation is claimed. The validation log is the final successful run after adding focused headroom and physical-word cases; earlier five/six-test runs are superseded.

The recorder count after a revert observes absence of persistent effects; by itself it does not exclude a transient call later rolled back. Source inspection and the matched earlier error selectors establish the tested stage ordering.
