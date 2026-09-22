#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
tools="$PWD/.lake/trio-tools/reserve-soljson"
mkdir -p "$tools"
case "$(uname -s):$(uname -m)" in
  Linux:aarch64|Linux:arm64)
    node_platform=linux-arm64
    node_digest=08bfbf538bad0e8cbb0269f0173cca28d705874a67a22f60b57d99dc99e30050
    ;;
  Linux:x86_64)
    node_platform=linux-x64
    node_digest=69b09dba5c8dcb05c4e4273a4340db1005abeafe3927efda2bc5b249e80437ec
    ;;
  Darwin:arm64|Darwin:aarch64)
    node_platform=darwin-arm64
    node_digest=4e845cb71b4e897289312743b2e31c405a8a48720655404d82a4dce23fc43527
    ;;
  Darwin:x86_64)
    node_platform=darwin-x64
    node_digest=deb5b211c25f3f803cd49c1c3fc3964e6c3725546d7d9608d994270388dcbf02
    ;;
  *) echo 'unsupported Node operating system or architecture' >&2; exit 1 ;;
esac
# SHA256 values from nodejs.org/dist/v22.14.0/SHASUMS256.txt and
# ethereum/solc-bin bin/list.json; only private checkout-local artifacts.
fetch_checked() {
  local url="$1" dest="$2" digest="$3"
  if [[ ! -f "$dest" ]]; then
    curl --fail --location --retry 3 --connect-timeout 20 --max-time 300 \
      "$url" --output "$dest.part"
    mv "$dest.part" "$dest"
  fi
  python3 - "$dest" "$digest" <<'CHECKSUM'
import hashlib
import pathlib
import sys

artifact = pathlib.Path(sys.argv[1])
actual = hashlib.sha256(artifact.read_bytes()).hexdigest()
if actual != sys.argv[2]:
    raise SystemExit(f"SHA-256 mismatch: {artifact}")
print(f"{artifact.name}: OK")
CHECKSUM
}
fetch_checked "https://nodejs.org/dist/v22.14.0/node-v22.14.0-$node_platform.tar.xz" \
  "$tools/node-$node_platform.tar.xz" "$node_digest"
tar -xJf "$tools/node-$node_platform.tar.xz" -C "$tools" --strip-components=1 \
  "node-v22.14.0-$node_platform/bin/node"
fetch_checked 'https://raw.githubusercontent.com/ethereum/solc-bin/gh-pages/bin/soljson-v0.4.24+commit.e67f0147.js' \
  "$tools/soljson.js" 9d9ec631865882a435fc577126fe068ccdf9c3962aa439acb2cdd0794907fccc
"$tools/bin/node" scripts/compile_reserve_soljson.cjs "$tools/soljson.js" "$@"
