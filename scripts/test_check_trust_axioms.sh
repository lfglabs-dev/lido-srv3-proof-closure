#!/usr/bin/env bash
set -euo pipefail

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

names="$tmp/names"
grep -v '^#\|^$' audit/trust-native-decide-allowlist.txt > "$names"
mapfile -t checked < <(python3 - <<'PY'
import json
for row in json.load(open("audit/guarantees.yaml", encoding="utf-8"))["guarantees"]:
    for plane in (row["abstract"], row["verity"]):
        if plane["status"] == "CHECKED":
            print(plane["theorem"])
PY
)
{
  first=1
  for theorem in "${checked[@]}"; do
    if [[ "$theorem" == 'LidoSRv3.Audit.MinFirst.incrementSelected_moduleId' ]]; then
      # Lean's empty-set spelling must remain a named report, not an omission.
      printf "'%s' does not depend on any axioms\n" "$theorem"
      continue
    fi
    printf "'%s' depends on axioms: [propext, Classical.choice, Quot.sound" "$theorem"
    if (( first )); then
      while IFS= read -r name; do
        printf ', %s' "$name"
      done < "$names"
      first=0
    fi
    printf ']\n'
  done
} > "$tmp/ok"
python3 scripts/check_trust_axioms.py --trust-output "$tmp/ok" >/dev/null

# The newly registered digest theorem must be emitted and checked by the
# normal Trust command; its actual dependency set is not fabricated here.
grep -Fqx '#print axioms LidoSRv3.Audit.Verity.SszTxSimulation.digest_preimages_length' \
  LidoSRv3/Audit/Trust.lean

cp "$tmp/ok" "$tmp/bad"
printf '%s\n' 'Injected theorem depends on axioms: [LidoSRv3.Injected.opaque_false]' >> "$tmp/bad"
if python3 scripts/check_trust_axioms.py --trust-output "$tmp/bad" >/dev/null 2>&1; then
  echo 'trust-axiom negative regression unexpectedly accepted an undisclosed axiom' >&2
  exit 1
fi

# The old union-only checker accepted this: the omitted registered theorem
# could have had an opaque dependency, while every emitted report remained
# within the allowlist.  Completeness must reject that hidden theorem.
sed '1d' "$tmp/ok" > "$tmp/unprinted-registered-opaque"
if python3 scripts/check_trust_axioms.py --trust-output "$tmp/unprinted-registered-opaque" >/dev/null 2>&1; then
  echo 'trust-axiom negative regression unexpectedly accepted an unprinted registered theorem with an opaque dependency' >&2
  exit 1
fi

printf '%s\n' 'trust-axiom negative regressions rejected an undisclosed opaque axiom and an unprinted registered theorem with an opaque dependency'
