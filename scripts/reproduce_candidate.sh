#!/usr/bin/env bash
# Use the full SHA named by the PR/audit handoff; never substitute a moving ref.
set -euo pipefail
cd "$(dirname "$0")/.."
expected="${1:?usage: bash scripts/reproduce_candidate.sh FULL_CANDIDATE_SHA}"
[[ "$expected" =~ ^[0-9a-f]{40}$ ]] || { echo 'expected a full 40-hex SHA' >&2; exit 2; }
[[ "$(git rev-parse HEAD)" == "$expected" ]] || { echo 'candidate SHA mismatch' >&2; exit 1; }
[[ -z "$(git status --porcelain --untracked-files=all)" ]] || { echo 'candidate checkout is dirty' >&2; exit 1; }
bash scripts/check_differential_sources.sh
python3 scripts/check_reproduction_targets.py
# Submission is durable. Exit 75 means accepted/pending, never validation PASS.
REMOTE_BUILD_NODE_ID=dgx-spark REMOTE_BUILD_PASSIVE=1 remote-lean-build lake test -- repository
