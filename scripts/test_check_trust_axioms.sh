#!/usr/bin/env bash
set -euo pipefail

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

names="$tmp/names"
grep -v '^#\|^$' audit/trust-native-decide-allowlist.txt > "$names"
{
  printf 'Trust theorem depends on axioms: [propext, Classical.choice, Quot.sound'
  while IFS= read -r name; do
    printf ', %s' "$name"
  done < "$names"
  printf ']\n'
} > "$tmp/ok"
python3 scripts/check_trust_axioms.py --trust-output "$tmp/ok" >/dev/null

cp "$tmp/ok" "$tmp/bad"
printf '%s\n' 'Injected theorem depends on axioms: [LidoSRv3.Injected.opaque_false]' >> "$tmp/bad"
if python3 scripts/check_trust_axioms.py --trust-output "$tmp/bad" >/dev/null 2>&1; then
  echo 'trust-axiom negative regression unexpectedly accepted an undisclosed axiom' >&2
  exit 1
fi

printf '%s\n' 'trust-axiom negative regression rejected an undisclosed opaque axiom'
