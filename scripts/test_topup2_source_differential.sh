#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
bash scripts/check_differential_sources.sh
lake build LidoSRv3.Audit.Verity.Topup2SourceEntry
FOUNDRY_PROFILE=topup2_source forge test --ffi --match-contract Topup2DifferentialTest -vv
