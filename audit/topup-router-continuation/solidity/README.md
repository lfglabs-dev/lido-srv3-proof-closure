# Actual router credential layout checks

Four Solidity0.8.25 tests call the unmodified pinned SRStorage getters and WithdrawalCredentials.setType. Two fuzz properties ran1024 cases each (seed0x20260909), and deterministic cases cover all256 type-byte values and repeated reads after changed storage. A harness containing the actual imported RouterState additionally exposes compiler storageLayout: moduleStates at root+0, withdrawalCredentials root+4, ModuleState.config offset0, type at config byte29 (bit232). The namespace getter returns0x5648d366b9f342bdcc64be95cdcf5f05da808509be70eaa548a8795901d5d000, matching the actual ERC7201 expression.

Raw storage fixtures compare the getter against keccak256(abi.encode(moduleId,root)), arbitrary surrounding packed fields and the independent mask/shift byte rule. The compiler's actual uint8 writer changes only that byte. The credential helper preserves the low31 bytes and sets the high byte. These checks support this adapter's layout/read behavior, not full StakingRouter execution, a changed state during withdrawal, deployment provenance or universal Lean/EVM refinement.

Reproduce from repository root after extracting the pinned @openzeppelin/contracts5.2.0 tarball into /tmp/lido-topup-wei-deps/package (the exact version from Lido yarn.lock):

```sh
mkdir -p /tmp/lido-topup-wei-deps
npm pack @openzeppelin/contracts@5.2.0 --pack-destination /tmp/lido-topup-wei-deps
tar -xzf /tmp/lido-topup-wei-deps/openzeppelin-contracts-5.2.0.tgz -C /tmp/lido-topup-wei-deps
FOUNDRY_SRC=audit/topup-router-continuation/solidity FOUNDRY_TEST=audit/topup-router-continuation/solidity forge test --remappings contracts/=lido-core/contracts/ --remappings @openzeppelin/contracts-v5.2/=/tmp/lido-topup-wei-deps/package/ --match-contract TopupRouterCredentialsTest --fuzz-runs 1024 --fuzz-seed 0x20260909 --out /tmp/lido-topup-router-solidity-out --cache-path /tmp/lido-topup-router-solidity-cache -vv
FOUNDRY_SRC=audit/topup-router-continuation/solidity FOUNDRY_TEST=audit/topup-router-continuation/solidity forge inspect TopupRouterCredentialsHarness storageLayout --json --remappings contracts/=lido-core/contracts/ --remappings @openzeppelin/contracts-v5.2/=/tmp/lido-topup-wei-deps/package/ --out /tmp/lido-topup-router-solidity-out --cache-path /tmp/lido-topup-router-solidity-cache
```

The recorded run reused the previously downloaded exact tarball (SHA2567a7f3060fc71bf080f88cd2f574d9e4813a2409de4dff1badfadc7dec13e9441). Every extracted dependency file was independently byte-compared against the tar archive before execution. No package installation, root compiler configuration or pinned source was changed. Both actual commands exited0. receipt.json binds harness, compiler layout, logs and consumed source identities. The storageLayout contract's slot-zero field is only a type-layout witness; actual test getters use the original namespaced SRStorage pointer.
