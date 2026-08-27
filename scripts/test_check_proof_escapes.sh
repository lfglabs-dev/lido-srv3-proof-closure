#!/usr/bin/env bash
set -euo pipefail

checker="scripts/check_proof_escapes.py"
tmpdir="$(mktemp -d)"
fixture="$tmpdir/fixture"
imported="$fixture/LidoSRv3/Audit/Source/SanityEnvelope.lean"
project="$fixture/LidoSRv3/Audit/Trust.lean"
trap 'rm -rf "$tmpdir"' EXIT
mkdir -p "$(dirname "$imported")" "$(dirname "$project")"
cp LidoSRv3/Audit/Source/SanityEnvelope.lean "$imported"
cp LidoSRv3/Audit/Trust.lean "$project"

reject() {
  local file="$1" token="$2" needle="$3"
  printf '\n%s\n' "$token" >> "$file"
  if python3 "$checker" --root "$fixture" --native-decide-policy forbid >"$tmpdir/out" 2>&1; then
    printf 'proof-escape regression accepted %s in %s\n' "$token" "$file" >&2
    exit 1
  fi
  rg -q "$needle" "$tmpdir/out" || { cat "$tmpdir/out" >&2; exit 1; }
  if [ "$file" = "$imported" ]; then
    cp LidoSRv3/Audit/Source/SanityEnvelope.lean "$file"
  else
    cp LidoSRv3/Audit/Trust.lean "$file"
  fi
}

# An imported project module and the Trust entrypoint are distinct surfaces;
# each mutation must be rejected without relying on a Lean warning.
reject "$imported" "sorry" "forbidden sorry"
reject "$imported" "admit" "forbidden admit"
reject "$project" "axiom injected : True" "forbidden axiom"
reject "$project" "unsafe def injected := 0" "forbidden unsafe"
reject "$project" "#check Lean.ofReduceBool" "forbidden Lean.ofReduceBool"
reject "$project" "native_decide" "forbidden native_decide"

printf '%s\n' 'proof-escape negative regressions rejected imported and Trust project Lean mutations'
