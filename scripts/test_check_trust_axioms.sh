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

# Each negative must be rejected *for its own reason*.  Asserting only a
# nonzero exit let an injected axiom "pass" this suite through an unrelated
# malformed-report rejection, hiding whether the axiom itself was validated.
reject() {
  local output="$1" needle="$2" label="$3" script="${4:-scripts/check_trust_axioms.py}"
  local captured status
  captured="$(python3 "$script" --trust-output "$output" 2>&1)" && status=0 || status=$?
  if (( status == 0 )); then
    echo "trust-axiom negative regression unexpectedly accepted $label" >&2
    exit 1
  fi
  if [[ "$captured" != *"$needle"* ]]; then
    echo "trust-axiom negative regression rejected $label for the wrong reason: $captured" >&2
    exit 1
  fi
}

# A non-native project axiom (for example `opaque injected : False`, which the
# lexical proof-escape scanner does not forbid) is emitted by Lean as an
# ordinary named report.  Every emitted axiom must be validated, so this must
# be rejected as undisclosed rather than silently discarded as "not native".
cp "$tmp/ok" "$tmp/injected-opaque-report"
printf "'%s' depends on axioms: [propext, %s]\n" \
  'LidoSRv3.Audit.Injected.opaque_dependency_theorem' 'LidoSRv3.Audit.Injected.injected' \
  >> "$tmp/injected-opaque-report"
reject "$tmp/injected-opaque-report" \
  'LidoSRv3.Audit.Injected.opaque_dependency_theorem emits undisclosed axiom(s): LidoSRv3.Audit.Injected.injected' \
  'a printed theorem depending on an injected opaque axiom'

# The same injected dependency hidden inside a registered CHECKED theorem's
# own report, where an allowlist-shaped scan would find nothing to complain of.
python3 - "$tmp/ok" "$tmp/injected-opaque-registered" <<'PY'
import sys
lines = open(sys.argv[1], encoding="utf-8").read().splitlines()
for index, line in enumerate(lines):
    if line.endswith("]"):
        lines[index] = line[:-1] + ", LidoSRv3.Audit.Injected.injected]"
        break
else:
    raise SystemExit("fixture has no dependency report to mutate")
open(sys.argv[2], "w", encoding="utf-8").write("\n".join(lines) + "\n")
PY
reject "$tmp/injected-opaque-registered" 'emits undisclosed axiom(s): LidoSRv3.Audit.Injected.injected' \
  'a registered CHECKED theorem depending on an injected opaque axiom'

# Disclosure must not be able to launder that same opaque axiom: the allowlist
# documents native-decision axioms only, never arbitrary project axioms.  The
# mutation runs against an isolated copy of the tree so the checked-in
# disclosure stays authoritative for every other case here.
fixture="$tmp/laundering-fixture"
mkdir -p "$fixture/scripts" "$fixture/audit" "$fixture/LidoSRv3/Audit"
cp scripts/check_trust_axioms.py "$fixture/scripts/check_trust_axioms.py"
cp audit/guarantees.yaml "$fixture/audit/guarantees.yaml"
cp LidoSRv3/Audit/Trust.lean "$fixture/LidoSRv3/Audit/Trust.lean"
cp audit/trust-native-decide-allowlist.txt "$fixture/audit/trust-native-decide-allowlist.txt"
printf '%s\n' 'LidoSRv3.Audit.Injected.injected' >> "$fixture/audit/trust-native-decide-allowlist.txt"
reject "$tmp/injected-opaque-report" \
  'allowlist documents non-native axiom(s): LidoSRv3.Audit.Injected.injected' \
  'an allowlist disclosing a non-native project axiom' "$fixture/scripts/check_trust_axioms.py"

# An unnamed dependency line must fail closed rather than be discarded, so a
# report Lean did emit can never go unparsed.
cp "$tmp/ok" "$tmp/unnamed-report"
printf '%s\n' 'Injected theorem depends on axioms: [LidoSRv3.Audit.Injected.injected]' >> "$tmp/unnamed-report"
reject "$tmp/unnamed-report" 'unnamed or malformed axiom report' 'an unnamed axiom report'

# The old union-only checker accepted this: the omitted registered theorem
# could have had an opaque dependency, while every emitted report remained
# within the allowlist.  Completeness must reject that hidden theorem.
sed '1d' "$tmp/ok" > "$tmp/unprinted-registered-opaque"
reject "$tmp/unprinted-registered-opaque" 'Trust output omits registered CHECKED theorem report(s)' \
  'an unprinted registered theorem with an opaque dependency'

printf '%s\n' 'trust-axiom negative regressions rejected injected opaque dependencies (printed, registered, and laundered through disclosure), an unnamed report, and an unprinted registered theorem'
