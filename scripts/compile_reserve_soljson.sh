#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
tools="$PWD/.lake/trio-tools/reserve-soljson"
mkdir -p "$tools"
case "$(uname -m)" in
  aarch64|arm64)
    arch=arm64
    node_digest=08bfbf538bad0e8cbb0269f0173cca28d705874a67a22f60b57d99dc99e30050
    ;;
  x86_64)
    arch=x64
    node_digest=69b09dba5c8dcb05c4e4273a4340db1005abeafe3927efda2bc5b249e80437ec
    ;;
  *) echo 'unsupported Node architecture' >&2; exit 1 ;;
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
  printf '%s  %s\n' "$digest" "$dest" | sha256sum --check --strict
}
fetch_checked "https://nodejs.org/dist/v22.14.0/node-v22.14.0-linux-$arch.tar.xz" \
  "$tools/node.tar.xz" "$node_digest"
tar -xJf "$tools/node.tar.xz" -C "$tools" --strip-components=1 \
  "node-v22.14.0-linux-$arch/bin/node"
fetch_checked 'https://raw.githubusercontent.com/ethereum/solc-bin/gh-pages/bin/soljson-v0.4.24+commit.e67f0147.js' \
  "$tools/soljson.js" 9d9ec631865882a435fc577126fe068ccdf9c3962aa439acb2cdd0794907fccc
"$tools/bin/node" scripts/compile_reserve_soljson.cjs "$tools/soljson.js" "$@"
