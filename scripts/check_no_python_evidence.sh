#!/usr/bin/env bash
set -euo pipefail

if ! command -v rg >/dev/null 2>&1; then
  echo "error: check_no_python_evidence.sh requires 'rg' (ripgrep); refusing to skip the stale-reference scan." >&2
  exit 2
fi

if [ -n "$(find verity fixtures proofs -type f \( -name '*.py' -o -name '*.pyc' \) -print -quit)" ]; then
  echo "Python proof artifacts are not allowed in this branch." >&2
  find verity fixtures proofs -type f \( -name '*.py' -o -name '*.pyc' \) >&2
  exit 1
fi

# Only these exact prerequisite lines are allowed to mention Python in README.
# Keep the evidence scan strict everywhere else, including appended claims.
prerequisite_line='Needs [elan](https://github.com/leanprover/elan), Lean 4.31.0, Python 3.10+'
path_line='local Lean runner. Put these tools on `PATH`; macOS'"'"'s system Bash and Python'

scan_file="$(mktemp)"
trap 'rm -f "$scan_file"' EXIT
if rg -n "Python|standard-library Python|Verity-style|verity_srv3" \
    verity proofs fixtures content report.tex Makefile >"$scan_file"; then
  :
else
  scan_status=$?
  if [ "$scan_status" -ne 1 ]; then
    echo "Stale-reference scan failed; refusing to skip it." >&2
    exit 2
  fi
fi
awk -v prerequisite="$prerequisite_line" -v path_note="$path_line" \
  '$0 != prerequisite && $0 != path_note && /Python|standard-library Python|Verity-style|verity_srv3/ { print "README.md:" NR ":" $0 }' README.md >>"$scan_file"
if [ -s "$scan_file" ]; then
  echo "Stale Python/Verity-style references remain:" >&2
  cat "$scan_file" >&2
  exit 1
fi
