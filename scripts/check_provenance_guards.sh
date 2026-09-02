#!/usr/bin/env bash
set -euo pipefail

# Regression checks for the two provenance guards. They are deliberately
# independent of a full Lake build, so `make test` proves the rejection paths.
fail() { printf 'check_provenance_guards: %s\n' "$1" >&2; exit 1; }

tmpdir="$(mktemp -d)"
untracked="LidoSRv3/.provenance-guard-$$.lean"
trap 'rm -f "$untracked"; rm -rf "$tmpdir"' EXIT

printf '%s\n' '-- deliberately untracked provenance regression input' > "$untracked"
if bash scripts/verified_source_tree.sh >/dev/null 2>&1; then
  fail 'accepted an untracked Lean input below LidoSRv3/'
fi

# `--ignored` is essential: an ignored Lean input is still visible to Lake.
printf '%s\n' "$untracked" > "$tmpdir/excludes"
if GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=core.excludesFile \
  GIT_CONFIG_VALUE_0="$tmpdir/excludes" \
  bash scripts/verified_source_tree.sh >/dev/null 2>&1; then
  fail 'accepted an ignored untracked Lean input below LidoSRv3/'
fi
rm -f "$untracked"

tree="$(bash scripts/verified_source_tree.sh)"
receipt_targets="$(bash scripts/write_proof_report.sh --targets)"
[ -n "$receipt_targets" ] || fail 'write_proof_report.sh declares no receipt targets'

printf 'verified_source_tree=%040d\nproof_targets=%s\nBuilt LidoSRv3\n' 0 "$receipt_targets" \
  > "$tmpdir/stale.log"
if BUILD_STATUS=0 BUILD_LOG="$tmpdir/stale.log" \
  bash scripts/write_proof_report.sh > "$tmpdir/report.json" 2>/dev/null; then
  fail 'emitted a report from a successful-looking log for a different source tree'
fi

# A current-looking log lets the following cases isolate the dependency guard.
printf 'verified_source_tree=%s\nlean_version=%s\nproof_targets=%s\nBuilt LidoSRv3\n' \
  "$tree" "$(lake env lean --version)" "$receipt_targets" > "$tmpdir/current.log"

# The receipt marks theorems from every declared target `lean_checked`, so a
# build that omits any of them must not produce one. Dropping a target from an
# otherwise current log is exactly what splitting LidoSRv3Legacy out of the
# default target did to the unchanged `lake build LidoSRv3` recipe.
for omitted in $receipt_targets; do
  kept="$(printf '%s\n' $receipt_targets | grep -Fvx "$omitted" | tr '\n' ' ' || true)"
  printf 'verified_source_tree=%s\nlean_version=%s\nproof_targets=%s\nBuilt LidoSRv3\n' \
    "$tree" "$(lake env lean --version)" "${kept% }" > "$tmpdir/partial.log"
  if BUILD_STATUS=0 BUILD_LOG="$tmpdir/partial.log" \
    bash scripts/write_proof_report.sh > "$tmpdir/report.json" 2>"$tmpdir/partial.err"; then
    fail "emitted a lean_checked report from a build that never compiled '$omitted'"
  fi
  grep -Fq "'$omitted' lean_checked" "$tmpdir/partial.err" || \
    fail "omitting '$omitted' was rejected for an unrelated reason: $(cat "$tmpdir/partial.err")"
done

# A log that records no target set at all is likewise unbindable.
printf 'verified_source_tree=%s\nlean_version=%s\nBuilt LidoSRv3\n' \
  "$tree" "$(lake env lean --version)" > "$tmpdir/untargeted.log"
if BUILD_STATUS=0 BUILD_LOG="$tmpdir/untargeted.log" \
  bash scripts/write_proof_report.sh > "$tmpdir/report.json" 2>"$tmpdir/untargeted.err"; then
  fail 'emitted a report from a log that records no built target set'
fi
grep -Fq 'exactly one proof_targets=' "$tmpdir/untargeted.err" || \
  fail "an untargeted log was rejected for an unrelated reason: $(cat "$tmpdir/untargeted.err")"

verity_dir=".lake/packages/verity"
manifest_pin="$(python3 -c 'import json; print(next(p for p in json.load(open("lake-manifest.json"))["packages"] if p["name"] == "verity")["rev"])')"
[ "$(git -C "$verity_dir" rev-parse HEAD)" = "$manifest_pin" ] || \
  fail 'test requires the resolved Verity checkout to match the manifest pin'
[ -z "$(git -C "$verity_dir" status --porcelain --untracked-files=all)" ] || \
  fail 'test requires a clean resolved Verity checkout'

# The receipt must not attribute a build to the manifest pin when Lake would
# consume another resolved revision, even if the build log looks current.
stale_verity="$(git -C "$verity_dir" rev-parse HEAD^)"
git -C "$verity_dir" checkout --detach --quiet "$stale_verity"
if BUILD_STATUS=0 BUILD_LOG="$tmpdir/current.log" \
  bash scripts/write_proof_report.sh > "$tmpdir/report.json" 2>/dev/null; then
  git -C "$verity_dir" checkout --detach --quiet "$manifest_pin"
  fail 'emitted a report with a stale resolved Verity checkout'
fi
git -C "$verity_dir" checkout --detach --quiet "$manifest_pin"

# Local dependency edits are likewise build inputs and must prevent a receipt.
dirty_verity="$verity_dir/.provenance-guard-$$"
printf '%s\n' 'deliberately dirty Verity dependency regression input' > "$dirty_verity"
if BUILD_STATUS=0 BUILD_LOG="$tmpdir/current.log" \
  bash scripts/write_proof_report.sh > "$tmpdir/report.json" 2>/dev/null; then
  rm -f "$dirty_verity"
  fail 'emitted a report with a dirty resolved Verity checkout'
fi
rm -f "$dirty_verity"

# `make prove` must invoke the provenance checker before any Lake command.
# Otherwise `lake env` can repair a stale checkout and the post-build check
# never observes the mutation the guard exists to reject.
python3 - <<'PY'
from pathlib import Path

text = Path("Makefile").read_text(encoding="utf-8")
lines = text.splitlines()
start = next(i for i, line in enumerate(lines) if line.startswith("prove:"))
body = []
for line in lines[start + 1 :]:
    if line and not line[0].isspace():
        break
    body.append(line)
recipe = "\n".join(body)
guard = "scripts/check_verity_provenance.py"
lake_at = min(
    (recipe.find(token) for token in ("lake env", "lake build", "$(LATEXMK)") if token in recipe),
    default=-1,
)
guard_at = recipe.find(guard)
if guard_at < 0:
    raise SystemExit("check_provenance_guards: make prove never calls check_verity_provenance.py")
if lake_at >= 0 and guard_at > lake_at:
    raise SystemExit("check_provenance_guards: make prove invokes Lake before the Verity provenance guard")

# The built target set must come from the receipt generator, not from a literal
# in this recipe. A literal is what silently went stale when LidoSRv3Legacy was
# split out of the default target, leaving the receipt claiming uncompiled
# theorems.
if "write_proof_report.sh --targets" not in recipe:
    raise SystemExit("check_provenance_guards: make prove does not read its Lake targets from write_proof_report.sh --targets")
if "proof_targets=" not in recipe:
    raise SystemExit("check_provenance_guards: make prove does not record proof_targets= in the build log")
PY

# A successful report must carry the exact resolved Verity manifest pin.  This
# is a narrow positive generator regression, using the current source tree and
# toolchain while avoiding a redundant build in this guard script.
BUILD_STATUS=0 BUILD_LOG="$tmpdir/current.log" \
  bash scripts/write_proof_report.sh > "$tmpdir/report.json"
report_pin="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["toolchain"]["verity_commit"])' "$tmpdir/report.json")"
[ "$report_pin" = "$manifest_pin" ] || \
  fail "proof report Verity pin '$report_pin' differs from manifest '$manifest_pin'"

# The declared target list is only trustworthy if it is derivable from what the
# receipt actually claims. Locate each `lean_checked` theorem's module and
# require the Lake library that compiles it to be one of the declared targets,
# so dropping a target from the list cannot silently re-open the gap that
# splitting LidoSRv3Legacy out of the default target opened.
python3 - "$tmpdir/report.json" "$receipt_targets" <<'PY'
import json
import re
import sys
from pathlib import Path

sys.path.insert(0, "scripts")
import check_proof_escapes

report = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
declared = set(sys.argv[2].split())

lakefile = Path("lakefile.lean").read_text(encoding="utf-8")
libraries = {}
for match in re.finditer(r"lean_lib\s+«([^»]+)»(.*?)(?=lean_lib\s+«|\Z)", lakefile, re.S):
    name, body = match.group(1), match.group(2)
    libraries[name] = {
        "one": set(re.findall(r"\.one\s+`([A-Za-z0-9.]+)", body))
        | set(re.findall(r"roots\s*:=\s*#\[\s*`([A-Za-z0-9.]+)", body)),
        "sub": set(re.findall(r"\.submodules\s+`([A-Za-z0-9.]+)", body)),
        "and": set(re.findall(r"\.andSubmodules\s+`([A-Za-z0-9.]+)", body)),
    }
if not libraries:
    raise SystemExit("check_provenance_guards: parsed no lean_lib targets from lakefile.lean")
libraries.setdefault("LidoSRv3", {"one": set(), "sub": set(), "and": set()})["one"].add("LidoSRv3")

def covering_libraries(module):
    found = set()
    for name, globs in libraries.items():
        if module in globs["one"]:
            found.add(name)
        elif any(module == p or module.startswith(p + ".") for p in globs["and"]):
            found.add(name)
        elif any(module.startswith(p + ".") for p in globs["sub"]):
            found.add(name)
    return found

declarations = {}
sources = sorted(Path("LidoSRv3").rglob("*.lean")) + [Path("LidoSRv3.lean")]
for path in sources:
    if not path.is_file():
        continue
    module = path.as_posix()[:-5].replace("/", ".")
    text = check_proof_escapes.strip_comments_and_strings(
        path.read_text(encoding="utf-8"))
    for leaf in re.findall(r"(?:^|\n)\s*(?:@\[[^\]]*\]\s*)?(?:private\s+|protected\s+|nonrec\s+)*"
                           r"(?:theorem|lemma)\s+([^\s:{（(\[]+)", text):
        declarations.setdefault(leaf, set()).add(module)

problems = []
for target in report["targets"]:
    if target["status"] != "lean_checked":
        continue
    leaf = target["theorem"].rsplit(".", 1)[-1]
    modules = declarations.get(leaf)
    if not modules:
        problems.append(f"{target['theorem']} is marked lean_checked but no project Lean file declares it")
        continue
    owners = set().union(*(covering_libraries(m) for m in modules))
    if not owners:
        problems.append(f"{target['theorem']} lives in {sorted(modules)}, which no Lake library compiles")
    elif not owners & declared:
        problems.append(
            f"{target['theorem']} is compiled by {sorted(owners)}, none of which "
            f"`make prove` builds ({sorted(declared)})")

if problems:
    raise SystemExit("check_provenance_guards: " + "; ".join(sorted(set(problems))[:5]))
count = sum(1 for t in report["targets"] if t["status"] == "lean_checked")
print(f"receipt target derivation ok: all {count} lean_checked theorems are compiled "
      f"by declared targets {sorted(declared)}")
PY

printf '%s\n' "provenance guards ok: untracked/ignored Lean inputs, stale-tree logs, untargeted logs, and logs omitting any of '$receipt_targets' rejected; emitted Verity pin equals manifest $manifest_pin (current tree $tree)"
