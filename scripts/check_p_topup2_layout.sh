#!/usr/bin/env bash
set -euo pipefail

repo="${LIDO_CORE_REPO:-../lido-core}"
expected=af095e48bbc1c3841c2c9936219c8461af01056b
test "$(git -C "$repo" rev-parse HEAD)" = "$expected"
test "$(git -C "$repo" status --porcelain --untracked-files=no)" = ""
rg -q 'evm_version = "cancun"' "$repo/foundry.toml"
rg -q 'via_ir = true' "$repo/foundry.toml"
rg -q 'optimizer_runs = 200' "$repo/foundry.toml"
forge build contracts/0.8.25/TopUpGateway.sol --force --root "$repo" >/dev/null

ast=audit/p-topup-2-pinned-storage-ast.json
comparison=audit/p-topup-2-layout-comparison.json
test "$(jq -r '.name' "$ast")" = Storage
jq -e --argjson expected "$(jq '.members | map({name,type:.solidity_type})' "$comparison")" \
  '[.members[] | {name,type}] == $expected' "$ast" >/dev/null
jq -e '.matches == true and .storage_layout_direct_entries == 0' "$comparison" >/dev/null
printf '%s\n' 'P-TOPUP-2 pinned solc AST/layout comparison ok'

