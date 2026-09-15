#!/usr/bin/env bash
# Keep the actual rejection before a Make failure, not only Make's wrapper.
set -euo pipefail
rg -n -B 3 -A 5 \
  '^error:|Traceback|failed:|AssertionError|Suite result:|^foundational-only trust BLOCKED|^make:.*Error' \
  "$@" | tail -160 || true
