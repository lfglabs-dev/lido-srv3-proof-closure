#!/usr/bin/env bash
# Focused registered-runner entry. Full repository validation also runs these checks.
set -euo pipefail
python3 scripts/check_trust_axioms.py
bash scripts/test_check_trust_axioms.sh
