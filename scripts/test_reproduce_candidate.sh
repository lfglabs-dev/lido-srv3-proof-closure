#!/usr/bin/env bash
# Test submission gating with isolated command doubles; no Lean/Forge/network.
set -euo pipefail
cd "$(dirname "$0")/.."
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
mkdir -p "$scratch/bin" "$scratch/scripts"
cp scripts/reproduce_candidate.sh "$scratch/scripts/"
printf '#!/usr/bin/env bash\nexit 0\n' > "$scratch/scripts/check_differential_sources.sh"
cat > "$scratch/bin/git" <<'STUB'
#!/usr/bin/env bash
if [[ "$1" == rev-parse ]]; then printf '%040d\n' 0; fi
STUB
cat > "$scratch/bin/python3" <<'STUB'
#!/usr/bin/env bash
if [[ "$1" == "${FAIL_GATE:-}" ]]; then exit 42; fi
STUB
cat > "$scratch/bin/remote-lean-build" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' submitted >> "$SUBMISSION_LOG"
exit 75
STUB
chmod +x "$scratch/bin/"*
export SUBMISSION_LOG="$scratch/submissions"
for gate in scripts/generate_ux2.py scripts/check_report_theorem_inventory.py scripts/check_validation_receipt.py; do
  rc=0
  FAIL_GATE="$gate" PATH="$scratch/bin:$PATH" bash "$scratch/scripts/reproduce_candidate.sh" \
    0000000000000000000000000000000000000000 || rc=$?
  [[ "$rc" == 42 && ! -e "$SUBMISSION_LOG" ]] || { echo "failed to block $gate" >&2; exit 1; }
done
rc=0
FAIL_GATE='' PATH="$scratch/bin:$PATH" bash "$scratch/scripts/reproduce_candidate.sh" \
  0000000000000000000000000000000000000000 || rc=$?
[[ "$rc" == 75 && "$(cat "$SUBMISSION_LOG")" == submitted ]]
printf '%s\n' 'candidate reproduction: stale gates block submission; pending remains exit 75'
