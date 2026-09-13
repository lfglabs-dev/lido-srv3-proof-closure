#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
pin=17005714f151e5502c559932319a3f2f74ac2436
[[ "$(git -C lido-core rev-parse HEAD)" == "$pin" ]] || { echo 'wrong Solidity pin' >&2; exit 1; }
for path in \
  contracts/0.8.25/sr/StakingRouter.sol \
  contracts/0.8.25/sr/SRLib.sol \
  contracts/0.8.25/sr/SRStorage.sol \
  contracts/0.8.25/sr/SRTypes.sol \
  contracts/0.8.25/lib/BeaconChainDepositor.sol
do
  git -C lido-core diff --quiet "$pin" -- "$path" || { echo "dirty pinned source: $path" >&2; exit 1; }
done
lake build LidoSRv3.Audit.Verity.DepositSourceEntry
FOUNDRY_PROFILE=deposit_source forge test --ffi --match-contract DepositDifferentialTest -vv
