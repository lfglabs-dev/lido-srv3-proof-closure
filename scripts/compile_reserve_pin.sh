#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
solc="${SOLC_0424:-$HOME/.local/share/svm/0.4.24/solc-0.4.24}"
if [[ ! -x "$solc" ]]; then
  solc="$HOME/.svm/0.4.24/solc-0.4.24"
fi
if [[ ! -x "$solc" ]]; then
  echo "solc 0.4.24 not installed (expected $HOME/.local/share/svm/0.4.24/solc-0.4.24)" >&2
  exit 1
fi
out=solidity/out/reserve-0424
mkdir -p "$out"
"$solc" \
  --bin --abi --overwrite --optimize --optimize-runs 200 \
  --evm-version constantinople \
  @aragon/=audit/account-fee-distribution/solidity/vendor/@aragon/ \
  openzeppelin-solidity/=audit/account-fee-distribution/solidity/vendor/openzeppelin-solidity/ \
  contracts/=lido-core/contracts/ \
  --allow-paths "$(pwd)" \
  -o "$out" \
  solidity/reserve/pin/ReserveHarness.sol
[[ -s "$out/ReserveHarness.bin" ]] || { echo "ReserveHarness.bin missing" >&2; exit 1; }
