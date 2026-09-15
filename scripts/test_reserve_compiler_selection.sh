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
