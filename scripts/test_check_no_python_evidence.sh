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
if ! grep -q "requires 'rg'" "$tmpdir/no-rg.err"; then
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
if ! grep -q 'content/stale-reference.tex' "$tmpdir/stale.err"; then
  fail "stale reference failure did not identify the fixture"
fi

# Real reproduction prerequisites are not Python proof evidence.
rm "$fixture/content/stale-reference.tex"
cat >"$fixture/README.md" <<'EOF'
Needs [elan](https://github.com/leanprover/elan), Lean 4.31.0, Python 3.10+
local Lean runner. Put these tools on `PATH`; macOS's system Bash and Python
EOF
(cd "$fixture" && /bin/bash scripts/check_no_python_evidence.sh) || fail "prerequisites rejected"
printf '%s\n' 'Python proves this guarantee.' >>"$fixture/README.md"
if (cd "$fixture" && /bin/bash scripts/check_no_python_evidence.sh) >/dev/null 2>&1; then
  fail "Python proof claim in README was accepted"
fi
sed -i.bak '$d' "$fixture/README.md"
printf '%s' 'Python proof evidence' >>"$fixture/README.md"
if (cd "$fixture" && /bin/bash scripts/check_no_python_evidence.sh) >/dev/null 2>&1; then
  fail "non-prerequisite Python text was accepted"
fi

printf '%s\n' 'check_no_python_evidence regressions ok: missing rg fails closed; exact prerequisites allowed; stale evidence rejected'
