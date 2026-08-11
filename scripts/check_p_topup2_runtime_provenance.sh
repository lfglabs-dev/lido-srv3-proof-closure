#!/usr/bin/env bash
set -euo pipefail

# Rebuild and deploy the pinned TopUpGateway, then optionally bind that exact
# runtime to Ethereum mainnet. MAINNET_RPC_URL is intentionally the only RPC
# input: credentials are never stored in this repository.

fail() { printf 'P-TOPUP-2 runtime provenance: FAIL: %s\n' "$1" >&2; exit 1; }
need() { command -v "$1" >/dev/null || fail "missing tool: $1"; }

PIN=af095e48bbc1c3841c2c9936219c8461af01056b
RELEASE_COMMIT=17005714f151e5502c559932319a3f2f74ac2436
REFERENCE_BLOCK=25730798
PROXY=0x3FC2C71579D80790Aaa3fc7Be8B66ac39dC57374
IMPLEMENTATION=0xb08dBc68C521cD7A4318dc4C807a42bEB20f1106
IMPLEMENTATION_LOWER=0xb08dbc68c521cd7a4318dc4c807a42beb20f1106
IMPLEMENTATION_SLOT=0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
EXPECTED_LENGTH=9868
EXPECTED_HASH=0x2b9cce4868b60e874f60387f61ebbaceaf20f074dc78bec5564c8477319aa6e4
LOCATOR=0xC1d0b3DE6792Bf6b4b37EccdcC24e45978Cfd2Eb
GINDEX=0x0000000000000000000000000000000000000000000000000096000000000028
RECEIPT=audit/p-topup-2-runtime-provenance.json
LIDO_CORE_DIR=${LIDO_CORE_DIR:-../lido-core}
FOUNDRY_BIN=${FOUNDRY_BIN:-/root/.foundry/bin}
PATH="$FOUNDRY_BIN:$PATH"

need git; need jq; need sha256sum; need node; need anvil; need cast
test -d "$LIDO_CORE_DIR/.git" || fail "LIDO_CORE_DIR is not a Git checkout"
test -x "$LIDO_CORE_DIR/node_modules/.bin/hardhat" || fail "pinned checkout dependencies are not installed"
test "$(git -C "$LIDO_CORE_DIR" rev-parse HEAD)" = "$PIN" || fail "Lido checkout is not at $PIN"
test "$(git -C "$LIDO_CORE_DIR" rev-parse v4.0.0^{})" = "$RELEASE_COMMIT" || fail "v4.0.0 does not resolve to the recorded release commit"

files=(
  contracts/common/lib/SSZ.sol
  contracts/common/lib/GIndex.sol
  contracts/common/lib/BLS.sol
  contracts/0.8.25/CLValidatorVerifier.sol
  contracts/0.8.25/TopUpGateway.sol
)
for file in "${files[@]}"; do
  pin_blob=$(git -C "$LIDO_CORE_DIR" rev-parse "$PIN:$file")
  release_blob=$(git -C "$LIDO_CORE_DIR" rev-parse "$RELEASE_COMMIT:$file")
  test "$pin_blob" = "$release_blob" || fail "$file differs between pin and v4.0.0"
  expected_blob=$(jq -r --arg file "$file" '.source_identity.files[] | select(.path == $file) | .git_blob' "$RECEIPT")
  test "$pin_blob" = "$expected_blob" || fail "$file blob is not receipt-pinned"
done
ssz_sha=$(git -C "$LIDO_CORE_DIR" show "$PIN:contracts/common/lib/SSZ.sol" | sha256sum | cut -d' ' -f1)
test "$ssz_sha" = 91ef497b972bbee0fe89043034e6bd62fa0c1059f22874d4826bc6164a22009b || fail "SSZ.sol SHA-256 mismatch"

(
  cd "$LIDO_CORE_DIR"
  ./node_modules/.bin/hardhat compile >/dev/null
)
source_count=$(jq -s '[.[].input.sources | keys[]] | unique | length' "$LIDO_CORE_DIR"/artifacts/build-info/*.json)
test "$source_count" -eq 478 || fail "Hardhat build covered $source_count unique Solidity sources, expected 478"
artifact="$LIDO_CORE_DIR/artifacts/contracts/0.8.25/TopUpGateway.sol/TopUpGateway.json"
test -s "$artifact" || fail "Hardhat TopUpGateway artifact missing"

tmpdir=$(mktemp -d)
anvil_pid=
cleanup() {
  if test -n "$anvil_pid"; then kill "$anvil_pid" 2>/dev/null || true; fi
  rm -rf "$tmpdir"
}
trap cleanup EXIT
port=${ANVIL_PORT:-18546}
anvil --port "$port" --silent >"$tmpdir/anvil.log" 2>&1 &
anvil_pid=$!
for _ in $(seq 1 50); do cast chain-id --rpc-url "http://127.0.0.1:$port" >/dev/null 2>&1 && break; sleep 0.1; done
cast chain-id --rpc-url "http://127.0.0.1:$port" >/dev/null 2>&1 || fail "local anvil did not start"

local_address=$(LIDO_CORE_DIR="$LIDO_CORE_DIR" ARTIFACT="$artifact" RPC_URL="http://127.0.0.1:$port" node - <<'NODE'
const fs = require("fs");
const { ethers } = require(process.env.LIDO_CORE_DIR
  ? process.env.LIDO_CORE_DIR + "/node_modules/ethers"
  : "../lido-core/node_modules/ethers");
(async () => {
  const artifact = JSON.parse(fs.readFileSync(process.env.ARTIFACT));
  const provider = new ethers.JsonRpcProvider(process.env.RPC_URL);
  const wallet = new ethers.Wallet("0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80", provider);
  const factory = new ethers.ContractFactory(artifact.abi, artifact.bytecode, wallet);
  const contract = await factory.deploy(
    "0xC1d0b3DE6792Bf6b4b37EccdcC24e45978Cfd2Eb",
    "0x0000000000000000000000000000000000000000000000000096000000000028",
    "0x0000000000000000000000000000000000000000000000000096000000000028",
    0, 32
  );
  await contract.waitForDeployment();
  process.stdout.write(await contract.getAddress());
})().catch((error) => { console.error(error); process.exit(1); });
NODE
)
local_code=$(cast code "$local_address" --rpc-url "http://127.0.0.1:$port")
local_length=$(( (${#local_code} - 2) / 2 ))
local_hash=$(printf '%s' "$local_code" | cast keccak)
test "$local_length" -eq "$EXPECTED_LENGTH" || fail "local runtime length $local_length != $EXPECTED_LENGTH"
test "$local_hash" = "$EXPECTED_HASH" || fail "local runtime hash $local_hash != $EXPECTED_HASH"

receipt_local_hash=$(jq -r '.artifact_identity.runtime.keccak256' "$RECEIPT")
receipt_local_length=$(jq -r '.artifact_identity.runtime.length_bytes' "$RECEIPT")
test "$local_hash" = "$receipt_local_hash" || fail "local runtime hash differs from receipt"
test "$local_length" -eq "$receipt_local_length" || fail "local runtime length differs from receipt"

if test -z "${MAINNET_RPC_URL:-}"; then
  printf '%s\n' "P-TOPUP-2 runtime provenance: LOCAL PASS; OPTIONAL MAINNET RPC GATE SKIPPED_NO_RPC (set MAINNET_RPC_URL)" >&2
  exit 2
fi

# Pass the credential-bearing endpoint through the standard environment rather
# than argv so process listings and shell error rendering cannot expose it.
rpc_cast() { ETH_RPC_URL="$MAINNET_RPC_URL" cast "$@"; }
chain_id=$(rpc_cast chain-id)
test "$chain_id" = 1 || fail "RPC chainId is $chain_id, expected 1"
slot=$(rpc_cast storage "$PROXY" "$IMPLEMENTATION_SLOT" --block "$REFERENCE_BLOCK")
slot_impl=0x${slot: -40}
test "${slot_impl,,}" = "$IMPLEMENTATION_LOWER" || fail "proxy implementation slot mismatch at block $REFERENCE_BLOCK"
chain_code=$(rpc_cast code "$IMPLEMENTATION" --block "$REFERENCE_BLOCK")
chain_length=$(( (${#chain_code} - 2) / 2 ))
chain_hash=$(printf '%s' "$chain_code" | cast keccak)
test "$chain_length" -eq "$EXPECTED_LENGTH" || fail "mainnet runtime length mismatch"
test "$chain_hash" = "$EXPECTED_HASH" || fail "mainnet runtime hash mismatch"
test "$chain_code" = "$local_code" || fail "local and mainnet runtime bytes differ"

printf '%s\n' "P-TOPUP-2 runtime provenance: PASS chainId=1 block=$REFERENCE_BLOCK implementation=$IMPLEMENTATION length=$chain_length hash=$chain_hash exact_bytes=true"
