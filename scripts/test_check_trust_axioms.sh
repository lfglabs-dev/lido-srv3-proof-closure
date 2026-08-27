#!/usr/bin/env bash
set -euo pipefail

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

cp audit/trust-native-decide-allowlist.txt "$tmp/ok"
python3 scripts/check_trust_axioms.py --trust-output "$tmp/ok" >/dev/null

cp "$tmp/ok" "$tmp/bad"
printf '%s\n' 'LidoSRv3.Tests.Injected.unreviewed._native.native_decide.ax_1_1' >> "$tmp/bad"
if python3 scripts/check_trust_axioms.py --trust-output "$tmp/bad" >/dev/null 2>&1; then
  echo 'trust-axiom negative regression unexpectedly accepted an undisclosed native-decision axiom' >&2
  exit 1
fi

printf '%s\n' 'trust-axiom negative regression rejected an undisclosed native-decision axiom'
