#!/usr/bin/env python3
"""Check that the canonical validation receipt names its non-self-referential tree."""

import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RECEIPT = Path("audit/validation-receipt.txt")
EXPECTED_BASE = "f9358e6df5e8c6ed4eed15d31054e490601efc1e"
EXPECTED_HEAD = "f9358e6df5e8c6ed4eed15d31054e490601efc1e"


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
    if fields.get("head") != EXPECTED_HEAD:
        raise SystemExit("validation receipt head is not the canonical campaign head")
    if fields.get("validation-subject") != "HEAD tracked tree excluding this receipt":
        raise SystemExit("validation receipt subject semantics are missing or incompatible")
    actual = git("rev-parse", f"{EXPECTED_HEAD}^{{tree}}")
    if fields.get("validated-tree") != actual:
        raise SystemExit(
            f"validation receipt tree is stale: recorded {fields.get('validated-tree')}, "
            f"actual {actual}"
        )
    print(f"validation receipt ok: final tracked content tree excluding receipt {actual}")


if __name__ == "__main__":
    main()
