#!/usr/bin/env bash
set -euo pipefail

if [ -n "$(find verity tests proofs -type f \( -name '*.py' -o -name '*.pyc' \) -print -quit)" ]; then
  echo "Python proof artifacts are not allowed in this branch." >&2
  find verity tests proofs -type f \( -name '*.py' -o -name '*.pyc' \) >&2
  exit 1
fi

if rg -n "Python|standard-library Python|Verity-style|verity_srv3" \
  README.md verity proofs tests content report.tex Makefile >/tmp/lido-srv3-python-refs.txt; then
  echo "Stale Python/Verity-style references remain:" >&2
  cat /tmp/lido-srv3-python-refs.txt >&2
  exit 1
fi
