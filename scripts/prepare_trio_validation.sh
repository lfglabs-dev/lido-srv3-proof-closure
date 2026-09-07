#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

# Remote source snapshots can omit historical objects used by audit checks.
# Fetch only the immutable review basis; preserve HEAD and the working tree.
review_base=$(python3 -c 'from scripts.audit_metadata import R1_REVIEW_BASE; print(R1_REVIEW_BASE)')
if ! git cat-file -e "$review_base^{commit}" 2>/dev/null; then
  git fetch --no-tags https://github.com/lfglabs-dev/lido-srv3-proof-closure.git "$review_base"
fi
git cat-file -e "$review_base:audit/guarantees.yaml"

# Private checkout-local tooling; no host package or service changes.
version=v1.3.1
case "$(uname -m)" in
  x86_64)
    arch=amd64
    digest=baad3e1b06d6f310d210c93e95258a03d923fe610f8d0742138f2245f94abd7c
    ;;
  aarch64|arm64)
    arch=arm64
    digest=ac5f88c0f6c1e5ed09c035a9f4405f74b996ea8a701d7150dc0184c18dd09f11
    ;;
  *) printf 'Unsupported validation architecture\n' >&2; exit 1 ;;
esac
test "$(uname -s)" = Linux
tools=.lake/trio-tools/foundry-v1.3.1
mkdir -p "$tools"
archive="$tools/foundry.tar.gz"
if ! test -f "$archive"; then
  curl --fail --location --retry 3 --connect-timeout 20 --max-time 300 \
    "https://github.com/foundry-rs/foundry/releases/download/$version/foundry_${version}_linux_${arch}.tar.gz" \
    --output "$archive.part"
  mv "$archive.part" "$archive"
fi
# Digests are from the official release asset metadata, checked 2026-09-07.
printf '%s  %s\n' "$digest" "$archive" | sha256sum --check --strict
tar -xzf "$archive" -C "$tools" forge
"$tools/forge" --version

# The full regression suite uses ripgrep and deliberately rejects its absence.
# Release checksum assets were read from BurntSushi/ripgrep 14.1.1 on 2026-09-07.
case "$(uname -m)" in
  x86_64)
    rg_target=x86_64-unknown-linux-musl
    rg_digest=4cf9f2741e6c465ffdb7c26f38056a59e2a2544b51f7cc128ef28337eeae4d8e
    ;;
  aarch64|arm64)
    rg_target=aarch64-unknown-linux-gnu
    rg_digest=c827481c4ff4ea10c9dc7a4022c8de5db34a5737cb74484d62eb94a95841ab2f
    ;;
esac
rg_tools=.lake/trio-tools/ripgrep-14.1.1
mkdir -p "$rg_tools"
rg_archive="$rg_tools/ripgrep.tar.gz"
if ! test -f "$rg_archive"; then
  curl --fail --location --retry 3 --connect-timeout 20 --max-time 300 \
    "https://github.com/BurntSushi/ripgrep/releases/download/14.1.1/ripgrep-14.1.1-${rg_target}.tar.gz" \
    --output "$rg_archive.part"
  mv "$rg_archive.part" "$rg_archive"
fi
printf '%s  %s\n' "$rg_digest" "$rg_archive" | sha256sum --check --strict
tar -xzf "$rg_archive" -C "$rg_tools" --strip-components=1 "ripgrep-14.1.1-${rg_target}/rg"
"$rg_tools/rg" --version
