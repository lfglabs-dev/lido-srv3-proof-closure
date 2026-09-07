#!/usr/bin/env bash
set -euo pipefail

checker="scripts/check_proof_escapes.py"
tmpdir="$(mktemp -d)"
fixture="$tmpdir/fixture"
imported="$fixture/LidoSRv3/Audit/Source/SanityEnvelope.lean"
project="$fixture/LidoSRv3/Audit/Trust.lean"
library_root="$fixture/LidoSRv3.lean"
trap 'rm -rf "$tmpdir"' EXIT
mkdir -p "$(dirname "$imported")" "$(dirname "$project")"
cp LidoSRv3/Audit/Source/SanityEnvelope.lean "$imported"
cp LidoSRv3/Audit/Trust.lean "$project"
cp LidoSRv3.lean "$library_root"

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
  elif [ "$file" = "$library_root" ]; then
    cp LidoSRv3.lean "$file"
  else
    cp LidoSRv3/Audit/Trust.lean "$file"
  fi
}

# An imported project module and the Trust entrypoint are distinct surfaces;
# each mutation must be rejected without relying on a Lean warning.
reject "$imported" "sorry" "forbidden sorry"
reject "$imported" "admit" "forbidden admit"
reject "$imported" "constant injected : False" "forbidden constant"
reject "$project" "axiom injected : True" "forbidden axiom"
reject "$library_root" "axiom rootInjected : False" "forbidden axiom"
reject "$project" "unsafe def injected := 0" "forbidden unsafe"
reject "$project" "#check Lean.ofReduceBool" "forbidden Lean.ofReduceBool"
reject "$project" "native_decide" "forbidden native_decide"

# Escaped identifiers are code, but their contents are names rather than proof
# commands or declarations.  Every guarded spelling must therefore be ignored
# inside guillemets while the mutations above remain rejected outside them.
printf '\ntheorem «sorry» : True := trivial\ntheorem «axiom» : True := trivial\ntheorem «native_decide» : True := trivial\n' >> "$project"
if ! python3 "$checker" --root "$fixture" --native-decide-policy forbid >"$tmpdir/out" 2>&1; then
  cat "$tmpdir/out" >&2
  exit 1
fi

# Character literals (including each guillemet) are data, not escaped
# identifier delimiters; every following guarded spelling must stay visible.
for literal in "'«'" "'»'" "'\\\\'"; do
  while IFS='|' read -r token needle; do
    cp LidoSRv3/Audit/Trust.lean "$project"
    printf "\ndef marker : Char := %s\n%s\n" "$literal" "$token" >> "$project"
    if python3 "$checker" --root "$fixture" --native-decide-policy forbid >"$tmpdir/out" 2>&1; then
      printf 'proof-escape regression accepted %s after character literal %s\n' "$token" "$literal" >&2
      exit 1
    fi
    rg -q "$needle" "$tmpdir/out" || { cat "$tmpdir/out" >&2; exit 1; }
  done <<'TOKENS'
sorry|forbidden sorry
admit|forbidden admit
axiom injected : False|forbidden axiom
constant injected : False|forbidden constant
unsafe def injected := 0|forbidden unsafe
#check Lean.ofReduceBool|forbidden Lean.ofReduceBool
native_decide|forbidden native_decide
TOKENS
done

printf '%s\n' 'proof-escape negative regressions rejected imported, library-root, and Trust project Lean mutations'
