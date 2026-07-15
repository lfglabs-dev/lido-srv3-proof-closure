#!/usr/bin/env bash
set -euo pipefail

# Hash the exact tracked inputs to `lake build LidoSRv3`, without including
# generated proof logs or report artifacts.  This virtual Git tree has five
# entries: the complete proof namespace, its root module, the Lake project and
# dependency manifest, and the pinned Lean toolchain.  `git mktree` gives the
# Git object ID without making the generated report refer to itself.
inputs=(LidoSRv3 LidoSRv3.lean lakefile.lean lake-manifest.json lean-toolchain)
git diff --quiet HEAD -- "${inputs[@]}" || {
  printf '%s\n' 'verified_source_tree: checked source/dependency inputs are dirty; commit them before make prove' >&2
  exit 1
}

{
  printf '040000 tree %s\tLidoSRv3\n' "$(git rev-parse HEAD:LidoSRv3)"
  printf '100644 blob %s\tLidoSRv3.lean\n' "$(git rev-parse HEAD:LidoSRv3.lean)"
  printf '100644 blob %s\tlake-manifest.json\n' "$(git rev-parse HEAD:lake-manifest.json)"
  printf '100644 blob %s\tlakefile.lean\n' "$(git rev-parse HEAD:lakefile.lean)"
  printf '100644 blob %s\tlean-toolchain\n' "$(git rev-parse HEAD:lean-toolchain)"
} | git mktree
