#!/usr/bin/env bash
# Run once per immutable source checkpoint; logs are outside the validation tree.
set -euo pipefail
reserve_root=$(git rev-parse --show-toplevel)
reserve_sha=$(git rev-parse HEAD)
reserve_receipts="$reserve_root/audit/trio/reserve1/receipts"
reserve_validation="$reserve_root/audit/trio/reserve1/.local/gates-$reserve_sha"
export PATH="$reserve_root/audit/trio/reserve1/.local/lean4-v4.31.0/bin:$PATH"
# Prevent accidental duplicate invocations for this immutable checkpoint.
mkdir "$reserve_receipts/gates-$reserve_sha.lock"
{
  date -u +%FT%TZ
  printf 'source_commit=%s\nvalidation=%s\n' "$reserve_sha" "$reserve_validation"
  git submodule status
  df -h "$reserve_root"
  free -h
  lean --version
} > "$reserve_receipts/gates-context.txt"
git worktree add --detach "$reserve_validation" "$reserve_sha"
git clone --no-hardlinks "$reserve_root/lido-core" "$reserve_validation/lido-core"
cp -a --reflink=auto "$reserve_root/.lake" "$reserve_validation/.lake"
cd "$reserve_validation"
run_gate() {
  local reserve_label="$1"
  shift
  local reserve_exit=0
  {
    printf 'source_commit=%s\ncommand=' "$reserve_sha"
    printf '%q ' "$@"
    printf '\n'
    "$@"
  } > "$reserve_receipts/$reserve_label.txt" 2>&1 || reserve_exit=$?
  printf '%s\n' "$reserve_exit" > "$reserve_receipts/$reserve_label.exit"
}
run_gate full-production-test-trust lake build LidoSRv3 LidoSRv3Test LidoSRv3Audit
run_gate make-prove make prove
run_gate make-test make test
printf 'Terminal; consult each exit receipt. Canonical new registration is still missing.\n' > "$reserve_receipts/gates-terminal.txt"
