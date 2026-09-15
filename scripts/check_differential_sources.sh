#!/usr/bin/env bash
# Reject changed compiler inputs, including transitive imports and vendor files.
set -euo pipefail
cd "$(dirname "$0")/.."
pin=17005714f151e5502c559932319a3f2f74ac2436
[[ "$(git -C lido-core rev-parse HEAD)" == "$pin" ]] || { echo 'wrong Solidity pin' >&2; exit 1; }
check_tree() {
  local repo="$1" revision="$2" path="$3"
  git -C "$repo" diff --exit-code "$revision" -- "$path" >/dev/null || {
    echo "dirty compiled inputs: $repo/$path" >&2; exit 1;
  }
  if [[ -n "$(git -C "$repo" ls-files --others -- "$path")" ]]; then
    echo "untracked compiled inputs: $repo/$path" >&2; exit 1
  fi
}
# Supersets of the Solidity import closure deliberately fail closed. Comparing
# against HEAD includes staged changes; ls-files includes ignored extra inputs.
check_tree lido-core "$pin" contracts
for profile in deposit topup topup2 reserve signing-keys; do
  check_tree . HEAD "solidity/$profile"
done
check_tree . HEAD audit/account-fee-distribution/solidity/vendor
check_tree . HEAD audit/deposit-dsm-call/solidity/src/@openzeppelin
printf '%s\n' "differential source inputs match lido-core $pin and candidate $(git rev-parse HEAD)"
