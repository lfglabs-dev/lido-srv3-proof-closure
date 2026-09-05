#!/usr/bin/env bash
set -euo pipefail

repo="${LIDO_CORE_REPO:-../lido-core}"
expected=17005714f151e5502c559932319a3f2f74ac2436
forge_bin="${FORGE_BIN:-/root/.foundry/bin/forge}"
test "$(git -C "$repo" rev-parse HEAD)" = "$expected"
test "$(git -C "$repo" status --porcelain --untracked-files=no)" = ""
rg -q 'evm_version = "cancun"' "$repo/foundry.toml"
rg -q 'via_ir = true' "$repo/foundry.toml"
rg -q 'optimizer_runs = 200' "$repo/foundry.toml"

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT
"$forge_bin" build contracts/0.8.25/TopUpGateway.sol --force --ast \
  --root "$repo" --out "$tmpdir/out" --cache-path "$tmpdir/cache" >/dev/null
artifact="$tmpdir/out/TopUpGateway.sol/TopUpGateway.json"
test -s "$artifact"

# Derive member order, elementary widths, packing offsets, and the ERC-7201
# literal from the freshly compiled pinned source. Committed receipts are only
# comparison targets and cannot make this gate pass by setting `matches=true`.
ARTIFACT="$artifact" SOURCE="$repo/contracts/0.8.25/TopUpGateway.sol" \
  ACTUAL="$tmpdir/actual.json" node <<'NODE'
const fs = require('fs');
const artifact = JSON.parse(fs.readFileSync(process.env.ARTIFACT));
const nodes = [];
function walk(x) {
  if (Array.isArray(x)) return x.forEach(walk);
  if (!x || typeof x !== 'object') return;
  if (x.nodeType === 'StructDefinition' && x.name === 'Storage') nodes.push(x);
  Object.values(x).forEach(walk);
}
walk(artifact.ast);
if (nodes.length !== 1) throw new Error(`expected one Storage struct, found ${nodes.length}`);
let word = 0, bit = 0;
const members = nodes[0].members.map((m) => {
  const type = m.typeDescriptions.typeString;
  const match = /^uint(8|16|32|64|128|256)$/.exec(type);
  if (!match) throw new Error(`unsupported Storage member type ${type}`);
  const width = Number(match[1]);
  if (bit + width > 256) { word += 1; bit = 0; }
  const result = {name: m.name, solidity_type: type, word, bit_offset: bit, width};
  bit += width;
  if (bit === 256) { word += 1; bit = 0; }
  return result;
});
const source = fs.readFileSync(process.env.SOURCE, 'utf8');
const bases = [...source.matchAll(/bytes32\s+(?:private|internal)\s+constant\s+GATEWAY_STORAGE_POSITION\s*=\s*(0x[0-9a-fA-F]{64})\s*;/g)].map(m => m[1].toLowerCase());
if (bases.length !== 1) throw new Error(`expected one gateway storage literal, found ${bases.length}`);
fs.writeFileSync(process.env.ACTUAL, JSON.stringify({erc7201_base: bases[0], members}));
NODE

comparison=audit/p-topup-2-layout-comparison.json
jq -e --slurpfile actual "$tmpdir/actual.json" \
  '.erc7201_base == $actual[0].erc7201_base and .members == $actual[0].members and
   .storage_layout_direct_entries == 0' "$comparison" >/dev/null
printf '%s\n' 'P-TOPUP-2 compiler-derived AST/layout comparison ok'
