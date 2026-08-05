#!/usr/bin/env python3
"""Check that the canonical validation receipt names its non-self-referential tree."""

import re
import subprocess
import os
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RECEIPT = Path("audit/validation-receipt.txt")
EXPECTED_BASE = "1b76e4b0c1fb5fcc6eb8f1031709b7d4c083e329"


def git(*args, env=None):
    return subprocess.run(
        ["git", "-c", f"safe.directory={ROOT}", *args],
        cwd=ROOT,
        env=env,
        check=True,
        capture_output=True,
        text=True,
    ).stdout.strip()


def receipt_excluded_tree():
    with tempfile.NamedTemporaryFile(prefix="validation-receipt-index-", delete=False) as index:
        index_path = index.name
    os.unlink(index_path)
    try:
        env = dict(os.environ, GIT_INDEX_FILE=index_path)
        git("read-tree", "HEAD", env=env)
        git("rm", "--cached", "--quiet", "--", str(RECEIPT), env=env)
        return git("write-tree", env=env)
    finally:
        Path(index_path).unlink(missing_ok=True)


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
    actual = receipt_excluded_tree()
    if fields.get("validated-tree") != actual:
        raise SystemExit(
            f"validation receipt tree is stale: recorded {fields.get('validated-tree')}, "
            f"actual {actual}"
        )
    print(f"validation receipt ok: final tracked content tree excluding receipt {actual}")


if __name__ == "__main__":
    main()
