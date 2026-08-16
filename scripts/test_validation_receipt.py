#!/usr/bin/env python3
"""Regression coverage for validation-receipt committed-tree semantics."""

import os
import subprocess
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
CHECKER = ROOT / "scripts/check_validation_receipt.py"


def git(*args, env=None):
    return subprocess.run(
        ["git", "-c", f"safe.directory={ROOT}", *args],
        cwd=ROOT,
        env=env,
        check=True,
        capture_output=True,
        text=True,
    )


def main():
    expected = git("rev-parse", "HEAD^{tree}").stdout.strip()
    with tempfile.TemporaryDirectory() as tmp:
        env = os.environ.copy()
        env["GIT_INDEX_FILE"] = str(Path(tmp) / "index")
        git("read-tree", "HEAD", env=env)
        # A staged change to a non-receipt file would alter an index-derived
        # tree.  The checker must ignore it and continue to check HEAD.
        staged = Path(tmp) / "staged.txt"
        staged.write_text("uncommitted index content\n", encoding="utf-8")
        git("update-index", "--add", "--cacheinfo", "100644", git("hash-object", "-w", str(staged)).stdout.strip(), "precommit-only.txt", env=env)
        staged_tree = git("write-tree", env=env).stdout.strip()
        if staged_tree == expected:
            raise SystemExit("test setup did not produce a distinct staged tree")
        result = subprocess.run(
            ["python3", str(CHECKER)], cwd=ROOT, env=env, text=True,
            capture_output=True,
        )
    if result.returncode:
        raise SystemExit(result.stderr or result.stdout)
    if "committed HEAD tree excluding receipt" not in result.stdout:
        raise SystemExit("checker did not report committed HEAD semantics")
    print("validation receipt regression ok: staged index does not affect HEAD check")


if __name__ == "__main__":
    main()
