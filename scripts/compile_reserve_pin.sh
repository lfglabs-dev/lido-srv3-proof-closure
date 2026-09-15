#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
# Every architecture uses the checksummed soljson + Node artifacts. Do not
# select an unchecked SOLC_0424 or SVM native executable from the environment.
exec bash scripts/compile_reserve_soljson.sh
