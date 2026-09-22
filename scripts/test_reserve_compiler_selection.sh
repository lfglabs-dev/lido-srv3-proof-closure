#!/usr/bin/env bash
# Exercise dispatch without running any compiler or downloading artifacts.
set -euo pipefail
cd "$(dirname "$0")/.."
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
mkdir -p "$scratch/scripts"
cp scripts/compile_reserve_pin.sh "$scratch/scripts/"
cat > "$scratch/scripts/compile_reserve_soljson.sh" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' checked-fallback
STUB
cat > "$scratch/untrusted-solc" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' UNCHECKED-COMPILER >&2
exit 99
STUB
chmod +x "$scratch/untrusted-solc"
result=$(SOLC_0424="$scratch/untrusted-solc" bash "$scratch/scripts/compile_reserve_pin.sh")
[[ "$result" == checked-fallback ]]
printf '%s\n' 'reserve compiler dispatch: unchecked override bypassed'

# A cached download must be rejected if its bytes do not match the pin.
cp scripts/compile_reserve_soljson.sh "$scratch/scripts/"
mkdir -p "$scratch/.lake/trio-tools/reserve-soljson"
for platform in linux-arm64 linux-x64 darwin-arm64 darwin-x64; do
  printf 'tampered artifact' > "$scratch/.lake/trio-tools/reserve-soljson/node-$platform.tar.xz"
done
if bash "$scratch/scripts/compile_reserve_soljson.sh" > "$scratch/checksum.log" 2>&1; then
  echo 'tampered compiler download was accepted' >&2
  exit 1
fi
grep -q 'SHA-256 mismatch:' "$scratch/checksum.log"
printf '%s\n' 'reserve compiler checksum: tampered download rejected'
