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
lean_version="$(lake env lean --version)"
printf 'verified_source_tree=%040d\nlean_version=%s\nBuilt LidoSRv3\n' 0 "$lean_version" > "$tmpdir/stale.log"
if BUILD_STATUS=0 BUILD_LOG="$tmpdir/stale.log" \
  bash scripts/write_proof_report.sh > "$tmpdir/report.json" 2>/dev/null; then
  fail 'emitted a report from a successful-looking log for a different source tree'
fi

printf '%s\n' "provenance guards ok: untracked/ignored Lean inputs and stale-tree logs rejected (current tree $tree)"
