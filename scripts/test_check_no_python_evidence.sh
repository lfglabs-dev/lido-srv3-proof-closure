#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
checker="$repo_root/scripts/check_no_python_evidence.sh"
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

fail() {
  printf 'check_no_python_evidence regression failed: %s\n' "$1" >&2
  exit 1
}

# A missing rg must be an explicit error, even though the scan is used as an
# `if` condition by the checker.
if PATH="$tmpdir/empty-path" /bin/bash "$checker" \
    >"$tmpdir/no-rg.out" 2>"$tmpdir/no-rg.err"; then
  fail "missing rg was accepted"
fi
if ! /bin/grep -q "requires 'rg'" "$tmpdir/no-rg.err"; then
  fail "missing rg did not produce the required diagnostic"
fi

# Exercise the real recursive/file scope with an otherwise minimal tree.
fixture="$tmpdir/stale-fixture"
mkdir -p "$fixture"/{scripts,verity,proofs,fixtures,content}
cp "$checker" "$fixture/scripts/"
touch "$fixture"/{README.md,report.tex,Makefile}
printf '%s\n' 'This is a stale Verity-style evidence reference.' \
  >"$fixture/content/stale-reference.tex"
if (cd "$fixture" && /bin/bash scripts/check_no_python_evidence.sh) \
    >"$tmpdir/stale.out" 2>"$tmpdir/stale.err"; then
  fail "stale reference was accepted"
fi
if ! /bin/grep -q 'content/stale-reference.tex' "$tmpdir/stale.err"; then
  fail "stale reference failure did not identify the fixture"
fi

printf '%s\n' 'check_no_python_evidence regressions ok: missing rg fails closed; stale references are rejected'
