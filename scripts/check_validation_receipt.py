#!/usr/bin/env python3
"""Check that the canonical validation receipt names its non-self-referential tree."""

import re
import subprocess
import os
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RECEIPT = Path("audit/validation-receipt.txt")
EXPECTED_BASE = "9cfb87a3b4728a5eb70ae90d9997a02b5ec408b7"


def git(*args, env=None):
    return subprocess.run(
        ["git", "-c", f"safe.directory={ROOT}", *args],
        cwd=ROOT,
        env=env,
        check=True,
        capture_output=True,
        text=True,
    ).stdout.strip()


def main():
    text = (ROOT / RECEIPT).read_text(encoding="utf-8")
    fields = dict(
        re.findall(
            r"^(base|head|validation-subject|validated-tree): (.+)$",
            text,
            re.MULTILINE,
        )
    )
    if fields.get("base") != EXPECTED_BASE:
        raise SystemExit("validation receipt base is not the canonical predecessor")
    if fields.get("validation-subject") != "HEAD tracked tree excluding this receipt":
        raise SystemExit("validation receipt subject semantics are missing or incompatible")
    with tempfile.NamedTemporaryFile() as index:
        env = os.environ.copy()
        env["GIT_INDEX_FILE"] = index.name
        git("read-tree", "HEAD", env=env)
        git("rm", "--cached", "--quiet", str(RECEIPT), env=env)
        actual = git("write-tree", env=env)
    if fields.get("validated-tree") != actual:
        raise SystemExit(
            f"validation receipt tree is stale: recorded {fields.get('validated-tree')}, "
            f"actual {actual}"
        )
    print(f"validation receipt ok: final tracked content tree excluding receipt {actual}")


if __name__ == "__main__":
    main()
