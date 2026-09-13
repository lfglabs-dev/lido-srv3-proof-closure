#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
pin=17005714f151e5502c559932319a3f2f74ac2436
[[ "$(git -C lido-core rev-parse HEAD)" == "$pin" ]] || { echo 'wrong Solidity pin' >&2; exit 1; }
for path in \
  contracts/0.4.24/Lido.sol \
  contracts/0.8.9/WithdrawalQueueBase.sol
do
  git -C lido-core diff --quiet "$pin" -- "$path" || { echo "dirty pinned source: $path" >&2; exit 1; }
done
lake build LidoSRv3.Audit.Verity.ReserveSourceEntry
bash scripts/compile_reserve_pin.sh
FOUNDRY_PROFILE=reserve_source forge test --ffi --match-contract ReserveDifferentialTest -vv
