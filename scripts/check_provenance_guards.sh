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
printf 'verified_source_tree=%040d\nBuilt LidoSRv3\n' 0 > "$tmpdir/stale.log"
if BUILD_STATUS=0 BUILD_LOG="$tmpdir/stale.log" \
  bash scripts/write_proof_report.sh > "$tmpdir/report.json" 2>/dev/null; then
  fail 'emitted a report from a successful-looking log for a different source tree'
fi

# A current-looking log lets the following cases isolate the dependency guard.
printf 'verified_source_tree=%s\nlean_version=%s\nBuilt LidoSRv3\n' \
  "$tree" "$(lake env lean --version)" > "$tmpdir/current.log"

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
PY

# A successful report must carry the exact resolved Verity manifest pin.  This
# is a narrow positive generator regression, using the current source tree and
# toolchain while avoiding a redundant build in this guard script.
BUILD_STATUS=0 BUILD_LOG="$tmpdir/current.log" \
  bash scripts/write_proof_report.sh > "$tmpdir/report.json"
report_pin="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["toolchain"]["verity_commit"])' "$tmpdir/report.json")"
[ "$report_pin" = "$manifest_pin" ] || \
  fail "proof report Verity pin '$report_pin' differs from manifest '$manifest_pin'"

printf '%s\n' "provenance guards ok: untracked/ignored Lean inputs and stale-tree logs rejected; emitted Verity pin equals manifest $manifest_pin (current tree $tree)"
