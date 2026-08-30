#!/usr/bin/env python3
"""Check that the canonical validation receipt names its non-self-referential tree."""

import argparse
import os
import re
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RECEIPT = Path("audit/validation-receipt.txt")
EXPECTED_BASE = "a57accb1e497894b22741bc243f79150eade8aef"


def git(*args, env=None):
    return subprocess.run(
        ["git", "-c", f"safe.directory={ROOT}", *args],
        cwd=ROOT,
        env=env,
        check=True,
        capture_output=True,
        text=True,
    ).stdout.strip()


def tracked_tree_excluding_receipt(env=None):
    with tempfile.TemporaryDirectory() as tmp:
        tree_env = os.environ.copy() if env is None else env.copy()
        tree_env["GIT_INDEX_FILE"] = str(Path(tmp) / "index")
        git("read-tree", "HEAD", env=tree_env)
        git("rm", "--cached", "--quiet", "--force", "--", str(RECEIPT), env=tree_env)
        return git("write-tree", env=tree_env)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--refresh", action="store_true",
                        help="rewrite only the receipt's non-self-referential tree from the staged tree")
    args = parser.parse_args()
    if args.refresh:
        # The caller stages every tracked change except this receipt first.
        # Removing only the receipt from that index gives the exact tree the
        # eventual commit will contain outside the self-referential file.
        # Use the real staged index rather than HEAD so a commit can be
        # prepared atomically without hand-editing a tree hash.
        result = subprocess.run(
            ["git", "-c", f"safe.directory={ROOT}", "write-tree"], cwd=ROOT,
            check=True, capture_output=True, text=True,
        ).stdout.strip()
        with tempfile.TemporaryDirectory() as tmp:
            env = os.environ.copy()
            env["GIT_INDEX_FILE"] = str(Path(tmp) / "index")
            git("read-tree", result, env=env)
            git("rm", "--cached", "--quiet", "--force", "--", str(RECEIPT), env=env)
            actual = git("write-tree", env=env)
        receipt_path = ROOT / RECEIPT
        text = receipt_path.read_text(encoding="utf-8")
        updated, count = re.subn(r"^validated-tree: .+$", f"validated-tree: {actual}", text,
                                 count=1, flags=re.MULTILINE)
        if count != 1:
            raise SystemExit("validation receipt has no unique validated-tree field to refresh")
        receipt_path.write_text(updated, encoding="utf-8")
        print(f"validation receipt refreshed: final staged content tree excluding receipt {actual}")
        return
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
    if fields.get("validation-subject") != "current tracked tree excluding this receipt":
        raise SystemExit("validation receipt subject semantics are missing or incompatible")
    actual = tracked_tree_excluding_receipt()
    if fields.get("validated-tree") != actual:
        raise SystemExit(
            f"validation receipt tree is stale: recorded {fields.get('validated-tree')}, "
            f"actual {actual}"
        )
    print(f"validation receipt ok: final tracked content tree excluding receipt {actual}")


if __name__ == "__main__":
    main()
