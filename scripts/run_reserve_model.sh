#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
exec lake env lean --run LidoSRv3/Audit/Verity/ReserveSourceEntry.lean "$@"
