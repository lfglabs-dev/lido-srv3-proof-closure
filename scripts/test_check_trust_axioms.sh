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

# Matching the generated name shape must not be enough.  A project `opaque`
# can be *spelled* exactly like a Lean-generated native-decision axiom, which
# satisfies both the allowlist shape rule and the LidoSRv3.Tests. scope rule
# while Lean generated nothing.  Before provenance was checked, disclosing that
# name and adding it to a registered CHECKED theorem's report made this exit
# successfully; only the source declaration distinguishes it.
launder="$tmp/laundered-shape-fixture"
mkdir -p "$launder/scripts" "$launder/audit" "$launder/LidoSRv3/Audit" "$launder/LidoSRv3/Tests"
cp scripts/check_trust_axioms.py "$launder/scripts/check_trust_axioms.py"
cp audit/guarantees.yaml "$launder/audit/guarantees.yaml"
cp LidoSRv3/Audit/Trust.lean "$launder/LidoSRv3/Audit/Trust.lean"
cp audit/trust-native-decide-allowlist.txt "$launder/audit/trust-native-decide-allowlist.txt"
laundered='LidoSRv3.Tests.Injected.fake._native.native_decide.ax_1_1'
printf '%s\n' "$laundered" >> "$launder/audit/trust-native-decide-allowlist.txt"
cat > "$launder/LidoSRv3/Tests/Injected.lean" <<'LEAN'
namespace LidoSRv3.Tests.Injected

opaque fake._native.native_decide.ax_1_1 : False

end LidoSRv3.Tests.Injected
LEAN
python3 - "$tmp/ok" "$tmp/laundered-shape-report" "$laundered" <<'PY'
import sys
lines = open(sys.argv[1], encoding="utf-8").read().splitlines()
for index, line in enumerate(lines):
    if line.endswith("]"):
        lines[index] = line[:-1] + ", " + sys.argv[3] + "]"
        break
else:
    raise SystemExit("fixture has no dependency report to mutate")
open(sys.argv[2], "w", encoding="utf-8").write("\n".join(lines) + "\n")
PY
reject "$tmp/laundered-shape-report" \
  "LidoSRv3/Tests/Injected.lean:3: opaque fake._native.native_decide.ax_1_1 : False" \
  'a source-declared axiom wearing generated native-decision spelling' \
  "$launder/scripts/check_trust_axioms.py"

# The same fixture without the source declaration is accepted, so the negative
# above is carried by provenance alone and not by some unrelated rejection.
rm "$launder/LidoSRv3/Tests/Injected.lean"
python3 "$launder/scripts/check_trust_axioms.py" --trust-output "$tmp/laundered-shape-report" >/dev/null

# Executable provenance regression.  Scanning sources for the literal `_native`
# token is necessary but not sufficient: a project command elaborator can build
# the very same name out of fragments and `addDecl` a `Declaration.axiomDecl`
# under it, so the generated spelling never appears in the source at all.  This
# fixture is that elaborator.  `mistyped` mints an outright `False`; `fake` also
# wears the `e = true` reflection type, so only binding the name to a real
# `native_decide` site can reject it.  `genuine` is a real `native_decide` proof
# in the same module, which must still be accepted.
minted="$tmp/minted"
mkdir -p "$minted/LidoSRv3/Tests"
cat > "$minted/LidoSRv3/Tests/Injected.lean" <<'LEAN'
import Lean
open Lean Elab Command

namespace LidoSRv3.Tests.Injected

theorem genuine : (10000 : Nat) + 1 = 10001 := by
  native_decide

private def generatedName (parent : Name) : Name :=
  -- Assembled from fragments: no `_ native` token (sans space) is ever spelled.
  (parent.str ("_" ++ "native")).str "native_decide" |>.str "ax_1_1"

elab "mint_forged_axioms" : command => do
  liftCoreM <| addDecl (.axiomDecl {
    name := generatedName `LidoSRv3.Tests.Injected.mistyped
    levelParams := [], type := mkConst ``False, isUnsafe := false })
  let forged := generatedName `LidoSRv3.Tests.Injected.fake
  liftCoreM <| addDecl (.axiomDecl {
    name := forged, levelParams := [], isUnsafe := false
    type := mkApp3 (mkConst ``Eq [1]) (mkConst ``Bool)
      (mkConst ``Bool.false) (mkConst ``Bool.true) })
  -- Even the declaration range is forged, from this command's own syntax.
  Lean.Elab.addDeclarationRangesFromSyntax forged (← getRef)

mint_forged_axioms

end LidoSRv3.Tests.Injected
LEAN

# The premise of this regression: both lexical guards have nothing to find.
# The generated namespace is never spelled, and `axiomDecl` is not the `axiom`
# keyword, so the proof-escape scanner does not match the embedded word either.
if grep -q '_native' "$minted/LidoSRv3/Tests/Injected.lean"; then
  echo 'minted-axiom fixture must not spell the generated namespace literally' >&2
  exit 1
fi
python3 - "$minted/LidoSRv3/Tests/Injected.lean" <<'PY'
import pathlib
import sys

sys.path.insert(0, "scripts")
import check_proof_escapes as scanner

clean = scanner.strip_comments_and_strings(
    pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
if "axiomDecl" not in clean:
    raise SystemExit("fixture must mint its axioms through addDecl")
caught = [name for name, pattern in scanner.ESCAPES if pattern.search(clean)]
if caught:
    raise SystemExit("fixture is caught lexically, so it does not reproduce the "
                     "claim: " + ", ".join(caught))
PY
lean -R "$minted" -o "$minted/LidoSRv3/Tests/Injected.olean" "$minted/LidoSRv3/Tests/Injected.lean"

probe_names() { printf '%s\n' "$1" > "$minted/names.txt"; }
probe() {
  python3 scripts/check_trust_axioms.py --provenance-fixture "$minted" \
    --provenance-module LidoSRv3.Tests.Injected --provenance-names "$minted/names.txt"
}
reject_probe() {
  local needle="$1" label="$2" captured status
  captured="$(probe 2>&1)" && status=0 || status=$?
  if (( status == 0 )); then
    echo "trust-axiom provenance regression unexpectedly accepted $label" >&2
    exit 1
  fi
  if [[ "$captured" != *"$needle"* ]]; then
    echo "trust-axiom provenance regression rejected $label for the wrong reason: $captured" >&2
    exit 1
  fi
}

probe_names 'LidoSRv3.Tests.Injected.mistyped._native.native_decide.ax_1_1'
reject_probe 'does not carry the `_ = true` reflection type Lean mints native-decision axioms with' \
  'an elaborator-minted axiom that native_decide never generated'

probe_names 'LidoSRv3.Tests.Injected.fake._native.native_decide.ax_1_1'
reject_probe 'is not recorded at a reviewed native_decide site' \
  'an elaborator-minted axiom wearing the generated type and a forged declaration range'

# The genuine `native_decide` axiom in the very same module is accepted, so the
# two negatives are carried by the checks under test and not by an unusable
# fixture.
probe_names 'LidoSRv3.Tests.Injected.genuine._native.native_decide.ax_1_1'
probe >/dev/null

# Recorded-metadata regression.  Every field the environment holds *about* a
# declaration is written by whoever declared it, so none of it is evidence that
# `native_decide` elaborated anything.  This fixture mints an axiom with the
# generated name, the owning module, the `Eq Bool e true` shape, and — by
# copying the genuine axiom's own `DeclarationRanges` — a declaration position
# that really is a `native_decide` site in the pinned inventory.  It therefore
# satisfies every check that inspects recorded provenance, and is caught only
# because its claim is re-evaluated: it asserts `false = true`.
sited="$tmp/sited"
mkdir -p "$sited/LidoSRv3/Tests"
cat > "$sited/LidoSRv3/Tests/Sited.lean" <<'LEAN'
import Lean
open Lean Elab Command

namespace LidoSRv3.Tests.Sited

theorem decoy : (10000 : Nat) + 1 = 10001 := by
  native_decide

private def generatedName (parent : Name) : Name :=
  (parent.str ("_" ++ "native")).str "native_decide" |>.str "ax_1_1"

elab "mint_axiom_at_genuine_site" : command => do
  let genuine := generatedName `LidoSRv3.Tests.Sited.decoy
  let some ranges ← findDeclarationRanges? genuine
    | throwError "fixture lost its genuine native-decision axiom"
  let forged := generatedName `LidoSRv3.Tests.Sited.sited
  liftCoreM <| addDecl (.axiomDecl {
    name := forged, levelParams := [], isUnsafe := false
    type := mkApp3 (mkConst ``Eq [1]) (mkConst ``Bool)
      (mkConst ``Bool.false) (mkConst ``Bool.true) })
  -- The forged axiom is registered at the genuine `native_decide` site itself.
  addDeclarationRanges forged ranges

mint_axiom_at_genuine_site

end LidoSRv3.Tests.Sited
LEAN
lean -R "$sited" -o "$sited/LidoSRv3/Tests/Sited.olean" "$sited/LidoSRv3/Tests/Sited.lean"

probe_names() { printf '%s\n' "$1" > "$sited/names.txt"; }
probe() {
  python3 scripts/check_trust_axioms.py --provenance-fixture "$sited" \
    --provenance-module LidoSRv3.Tests.Sited --provenance-names "$sited/names.txt"
}

# Rejected for the claim, which is only reachable once the kind, safety, type,
# module-ownership and declaration-site checks have all passed on this axiom.
probe_names 'LidoSRv3.Tests.Sited.sited._native.native_decide.ax_1_1'
reject_probe 'asserts a Bool claim that evaluates to false' \
  'an axiom registered at a genuine native_decide site whose claim is false'

# The genuine axiom from the same site is accepted, so the negative is carried
# by re-evaluating the claim rather than by rejecting the site.
probe_names 'LidoSRv3.Tests.Sited.decoy._native.native_decide.ax_1_1'
probe >/dev/null

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

printf '%s\n' 'trust-axiom negative regressions rejected injected opaque dependencies (printed, registered, laundered through disclosure, and laundered by wearing generated native-decision spelling), elaborator-minted axioms carrying no literal generated spelling (mistyped and type-shaped with a forged declaration range), an axiom registered at a genuine native_decide site whose re-evaluated claim is false, an unnamed report, and an unprinted registered theorem'
