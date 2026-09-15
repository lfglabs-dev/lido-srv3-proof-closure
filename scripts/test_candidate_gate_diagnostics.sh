#!/usr/bin/env bash
# Receipt-export regression; no Lean/Forge execution or remote submission.
set -euo pipefail
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
python3 - "$scratch/test.log" <<'PY'
from pathlib import Path
import sys
p=Path(sys.argv[1])
p.write_text('compiled dependency\n' * 2100 +
    'foundational-only trust BLOCKED; disclosure is not authorization: Parent: native_dependency\n' +
    'make: *** [Makefile:65: test] Error 1\n')
PY
bash scripts/emit_candidate_gate_diagnostics.sh "$scratch/test.log" > "$scratch/excerpt"
rg -Fq 'foundational-only trust BLOCKED; disclosure is not authorization: Parent: native_dependency' "$scratch/excerpt"
rg -Fq '[Makefile:65: test] Error 1' "$scratch/excerpt"
# An unrecognized SystemExit message must survive through Make's leading context.
printf '%s\n' 'arbitrary checker rejection with no recognized prefix' \
  'make: *** [Makefile:65: test] Error 1' > "$scratch/test.log"
bash scripts/emit_candidate_gate_diagnostics.sh "$scratch/test.log" > "$scratch/excerpt"
rg -Fq 'arbitrary checker rejection with no recognized prefix' "$scratch/excerpt"
[[ $(wc -l < "$scratch/excerpt") -le 160 ]]
echo 'candidate diagnostics retain actual checker rejection and Make target'
