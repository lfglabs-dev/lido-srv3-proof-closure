# Scratch-memory execution checks

Four tests run with solc0.8.25, including two1024-case fuzz properties and seed0x20260909. The actual harness calls the unmodified pinned BLS12_381.pubkeyRoot. Extra dynamic prefix/suffix arguments vary the raw key offset; raw ABI calls deliberately dirty all16 padding bytes after the48-byte key. Initial scratch words are arbitrary and memory words64/96 are observed before/after. The actual helper root equals independent SHA256(key++zero16), and the two outside words are preserved. All48 one-hot key positions and invalid lengths are checked.

A separate blockInput function duplicates only the exact mstore32zero/calldatacopy48 block so its pre-SHA64 bytes can be observed directly. This is explicitly a duplicated assembly fixture, not a second claim of executing the unmodified helper. Six intentionally wrong blocks (missing zero store, reversed store order, copy32, copy64, shifted offset, destination32) disagree with the independent64-byte specification. Dirty ABI padding makes the copy64 error observable. The destination32 mutant restores the free-memory pointer after capturing its wrong bytes solely so the test can return them instead of exhausting gas during ABI return; that correction does not alter the observed mutant slice.

These are finite Solidity execution checks, separate from the new universal EvmYul primitive-memory proof. They do not prove full BLS/SHA execution correspondence, runtime/deployment provenance, gas adequacy, forced SHA failures or short-return handling. The frame tests observe words64/96; universal outside-memory framing belongs to the Lean theorem. Short/empty initial EvmYul bytearrays are not represented by this Solidity function prologue.

Actual reproduction command from repository root:

```sh
FOUNDRY_SRC=audit/ssz-scratch-evm-memory/solidity FOUNDRY_TEST=audit/ssz-scratch-evm-memory/solidity forge test --remappings contracts/=lido-core/contracts/ --match-contract SszScratchEvmMemoryTest --fuzz-runs 1024 --fuzz-seed 0x20260909 --out /tmp/lido-ssz-scratch-solidity-out --cache-path /tmp/lido-ssz-scratch-solidity-cache -vv
```

The command exited0 on the final harness, four tests passed. Earlier experimental destination32 mutation destroyed the free-memory pointer and could not return; only the final successful run is recorded in validation.log. No pinned source, root compiler configuration or prior test was changed. receipt.json records source and harness hashes.
