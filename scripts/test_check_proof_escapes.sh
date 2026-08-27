#!/usr/bin/env bash
set -euo pipefail

checker="scripts/check_proof_escapes.py"
imported="LidoSRv3/Audit/Source/SanityEnvelope.lean"
project="LidoSRv3/Audit/Trust.lean"
tmpdir="$(mktemp -d)"
trap 'cp "$tmpdir/imported" "$imported"; cp "$tmpdir/project" "$project"; rm -rf "$tmpdir"' EXIT
cp "$imported" "$tmpdir/imported"
cp "$project" "$tmpdir/project"

reject() {
  local file="$1" token="$2" needle="$3"
  printf '\n%s\n' "$token" >> "$file"
  if python3 "$checker" >"$tmpdir/out" 2>&1; then
    printf 'proof-escape regression accepted %s in %s\n' "$token" "$file" >&2
    exit 1
  fi
  rg -q "$needle" "$tmpdir/out" || { cat "$tmpdir/out" >&2; exit 1; }
  if [ "$file" = "$imported" ]; then cp "$tmpdir/imported" "$file"; else cp "$tmpdir/project" "$file"; fi
}

# An imported project module and the Trust entrypoint are distinct surfaces;
# each mutation must be rejected without relying on a Lean warning.
reject "$imported" "sorry" "forbidden sorry"
reject "$imported" "admit" "forbidden admit"
reject "$project" "axiom injected : True" "forbidden axiom"
reject "$project" "unsafe def injected := 0" "forbidden unsafe"
reject "$project" "#check Lean.ofReduceBool" "forbidden Lean.ofReduceBool"
reject "$project" "native_decide" "native_decide inventory differs"

printf '%s\n' 'proof-escape negative regressions rejected imported and Trust project Lean mutations'
