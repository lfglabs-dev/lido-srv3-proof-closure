#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

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
