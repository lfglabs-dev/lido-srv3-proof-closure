#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
bash scripts/check_differential_sources.sh
lake build LidoSRv3.Audit.Verity.DepositSourceEntry
FOUNDRY_PROFILE=deposit_source forge test --ffi --match-contract DepositDifferentialTest -vv
