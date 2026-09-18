#!/usr/bin/env bash
# Isolated Git fixtures; no Lean, Forge or network.
set -euo pipefail
cd "$(dirname "$0")/.."
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
mkdir -p "$scratch/scripts" "$scratch/bin"
cp scripts/check_differential_sources.sh "$scratch/scripts/"
real_git=$(command -v git)
export REAL_GIT="$real_git"
cat > "$scratch/bin/git" <<'STUB'
#!/usr/bin/env bash
if [[ "${1:-}" == -C && "${2:-}" == lido-core ]]; then
  if [[ "${3:-}" == rev-parse ]]; then echo 17005714f151e5502c559932319a3f2f74ac2436; fi
  exit 0
fi
exec "$REAL_GIT" "$@"
STUB
chmod +x "$scratch/bin/git"
git -C "$scratch" init -q
for profile in deposit topup topup2 reserve; do
  mkdir -p "$scratch/solidity/$profile"
  echo original > "$scratch/solidity/$profile/input.sol"
done
git -C "$scratch" add .
git -C "$scratch" -c user.name=fixture -c user.email=fixture@example.invalid commit -qm fixture
run_guard() { PATH="$scratch/bin:$PATH" bash "$scratch/scripts/check_differential_sources.sh"; }
run_guard >/dev/null
for profile in deposit topup topup2 reserve; do
  input="solidity/$profile/input.sol"
  echo changed >> "$scratch/$input"
  if run_guard >/dev/null 2>&1; then echo "accepted unstaged $profile" >&2; exit 1; fi
  git -C "$scratch" add "$input"
  if run_guard >/dev/null 2>&1; then echo "accepted staged $profile" >&2; exit 1; fi
  git -C "$scratch" restore --source=HEAD --staged --worktree -- "$input"
  echo extra > "$scratch/solidity/$profile/extra.sol"
  if run_guard >/dev/null 2>&1; then echo "accepted untracked $profile" >&2; exit 1; fi
  echo 'extra.sol' >> "$scratch/.git/info/exclude"
  if run_guard >/dev/null 2>&1; then echo "accepted ignored $profile" >&2; exit 1; fi
  rm "$scratch/solidity/$profile/extra.sol"
done
run_guard >/dev/null
echo 'differential input guard: all four profiles reject staged, unstaged, untracked and ignored mutations'
