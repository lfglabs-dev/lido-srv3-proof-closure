#!/usr/bin/env bash
# Isolated TrioDeposit build + RouterDeposit.olean hashes.
# Nested .lake/packages must not be compiled as slice sources (see lakefile.lean).
# With pipefail, a failed `lake | tee` must not be reported as success: inspect
# PIPESTATUS after temporarily disabling -e around the pipeline.
set -euo pipefail

root="$(cd "$(dirname "$0")" && pwd)"
repo="$(cd "$root/../../.." && pwd)"
cd "$root"

log="$root/lake-build.log"
hashes="$root/RouterDeposit.hashes"

set +e
lake build TrioDeposit 2>&1 | tee "$log"
pipe=("${PIPESTATUS[@]}")
set -euo pipefail

lake_status="${pipe[0]}"
tee_status="${pipe[1]}"
if [[ "${lake_status}" -ne 0 ]]; then
  echo "lake build failed with status ${lake_status}" >&2
  exit "${lake_status}"
fi
if [[ "${tee_status}" -ne 0 ]]; then
  echo "tee failed with status ${tee_status}" >&2
  exit "${tee_status}"
fi

mapfile -t oleans < <(find "$root/.lake" "$repo/.lake" -name 'RouterDeposit.olean' 2>/dev/null | sort)
if [[ "${#oleans[@]}" -eq 0 ]]; then
  echo "RouterDeposit.olean not found after a successful lake build" >&2
  exit 1
fi

{
  echo "commit=$(git -C "$repo" rev-parse HEAD)"
  echo "lake_status=${lake_status}"
  echo "tee_status=${tee_status}"
  echo "source_sha256=$(sha256sum "$root/RouterDeposit.lean" | awk '{print $1}')"
  echo "lakefile_sha256=$(sha256sum "$root/lakefile.lean" | awk '{print $1}')"
  echo "deposit_sha256=$(sha256sum "$root/Deposit.lean" | awk '{print $1}')"
  echo "withdraw_sha256=$(sha256sum "$root/WithdrawDepositableEther.lean" | awk '{print $1}')"
  for olean in "${oleans[@]}"; do
    echo "olean_path=${olean}"
    echo "olean_sha256=$(sha256sum "$olean" | awk '{print $1}')"
  done
} | tee "$hashes"
