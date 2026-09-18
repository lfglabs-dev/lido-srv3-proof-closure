#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
bash scripts/check_differential_sources.sh
lake build LidoSRv3.Audit.Verity.ReserveSourceEntry
bash scripts/compile_reserve_pin.sh
FOUNDRY_PROFILE=reserve_source forge test --ffi --match-contract ReserveDifferentialTest -vv
