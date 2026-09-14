#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
bash scripts/check_differential_sources.sh
lake build LidoSRv3.Audit.Verity.TopupSourceEntry
FOUNDRY_PROFILE=topup_source forge test --ffi --match-contract TopupDifferentialTest -vv
