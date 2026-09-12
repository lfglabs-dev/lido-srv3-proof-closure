# Module callsite differential checks

Eight tests; one 1024-case property and 64 exact Lean byte vectors. The harness
uses the unchanged pinned SRStorage and IStakingModuleV2 definitions. Its raw
callee records the actual request and returns configured arbitrary bytes.
The tests validate address selection, all five argument positions, zero value,
return order, committed callee effects, decoder rollback, exact revert bytes,
zero target, no-code failure and accepted noncanonical offsets/trailing bytes.

The explicit 2^59-count fixture records the compiler memory-allocation boundary;
it is not counted as full agreement with the logical Lean decoder. The retained
IR shows the allocation order and the absence of an early extcodesize check.
This is not a full StakingRouter topUp run or an end-to-end deployment test.

```sh
lake env lean --run audit/topup-module-call/Export.lean
FOUNDRY_SRC=audit/topup-module-call/solidity FOUNDRY_TEST=audit/topup-module-call/solidity forge test --remappings contracts/=lido-core/contracts/ --remappings @openzeppelin/contracts-v5.2/=/tmp/lido-topup-wei-deps/package/ --match-contract TopupModuleCallTest --fuzz-runs 1024 --fuzz-seed 0x202609093 --out /tmp/lido-module-call-solidity-out --cache-path /tmp/lido-module-call-solidity-cache --threads 2 -vv
```

The compiler source identities include OpenZeppelin EnumerableSet 5.2.0 at its
actual temporary input path. A full byte-identical copy and package descriptor
are retained in ../vendor for replay; the receipt records the mapping. No
network download or fresh compiler execution occurs in check_receipt.py.
