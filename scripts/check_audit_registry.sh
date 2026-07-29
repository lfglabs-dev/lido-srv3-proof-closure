#!/usr/bin/env bash
set -euo pipefail

python3 scripts/audit_registry.py check
python3 scripts/audit_registry.py test-negative
