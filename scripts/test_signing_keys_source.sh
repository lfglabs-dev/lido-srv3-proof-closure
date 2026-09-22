#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
bash scripts/check_differential_sources.sh
bash scripts/compile_reserve_soljson.sh \
  solidity/signing-keys/pin/SigningKeysHarness.sol SigningKeysHarness solidity/out/signing-keys-0424
FOUNDRY_PROFILE=signing_keys_source forge test --match-contract SigningKeysMemoryTest -vv
