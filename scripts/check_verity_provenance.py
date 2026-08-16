#!/usr/bin/env python3
"""Fail-closed agreement check for every canonical Verity revision surface."""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path
from typing import NoReturn


VERITY_REPOSITORY = "https://github.com/lfglabs-dev/verity.git"
FULL_REVISION = re.compile(r"[0-9a-f]{40}")


def fail(message: str) -> NoReturn:
    raise ValueError(message)


def strict_object(pairs: list[tuple[str, object]]) -> dict[str, object]:
    result: dict[str, object] = {}
    for key, value in pairs:
        if key in result:
            fail(f"duplicate JSON key {key!r}")
        result[key] = value
    return result


def load_json(path: Path) -> dict[str, object]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"), object_pairs_hook=strict_object)
    except (OSError, json.JSONDecodeError) as exc:
        fail(f"cannot read {path}: {exc}")
    if not isinstance(value, dict):
        fail(f"{path} must contain one JSON object")
    return value


def check(root: Path) -> str:
    lakefile = (root / "lakefile.lean").read_text(encoding="utf-8")
    requests = re.findall(
        r'^\s*require\s+verity\s+from\s+git\s*\n\s*"([^"\n]+)"@"([^"\n]+)"\s*$',
        lakefile,
        re.MULTILINE,
    )
    if len(requests) != 1:
        fail("lakefile.lean must contain exactly one canonical Verity git request")
    requested_repository, requested_revision = requests[0]
    if requested_repository != VERITY_REPOSITORY:
        fail(f"lakefile Verity repository differs: {requested_repository!r}")
    if FULL_REVISION.fullmatch(requested_revision) is None:
        fail(f"lakefile Verity request is not an exact 40-hex revision: {requested_revision!r}")

    manifest = load_json(root / "lake-manifest.json")
    packages = manifest.get("packages")
    if not isinstance(packages, list):
        fail("lake-manifest.json packages must be a list")
    resolved = [package for package in packages if isinstance(package, dict) and package.get("name") == "verity"]
    if len(resolved) != 1:
        fail("lake-manifest.json must contain exactly one Verity package")
    package = resolved[0]
    expected_package = {
        "url": requested_repository,
        "type": "git",
        "rev": requested_revision,
        "inputRev": requested_revision,
        "inherited": False,
        "configFile": "lakefile.lean",
    }
    for key, expected in expected_package.items():
        if package.get(key) != expected:
            fail(f"lake-manifest Verity {key} {package.get(key)!r} differs from requested {expected!r}")

    lock = load_json(root / "audit/artifacts.lock.json")
    lock_pin = ((lock.get("pins") or {}).get("verity") if isinstance(lock.get("pins"), dict) else None)
    if lock_pin != {"repository": requested_repository, "commit": requested_revision}:
        fail("artifact-lock Verity pin differs from the lakefile request")

    audit_manifest = load_json(root / "verity/targets/audit-manifest.json")
    revisions = audit_manifest.get("source_revisions")
    audit_revision = revisions.get("verity") if isinstance(revisions, dict) else None
    if audit_revision != requested_revision:
        fail("audit-manifest Verity revision differs from the lakefile request")

    checkout = root / ".lake/packages/verity"
    if not checkout.is_dir():
        fail(f"resolved Verity checkout {checkout} not found")
    result = subprocess.run(
        ["git", "-C", str(checkout), "rev-parse", "HEAD"],
        text=True, capture_output=True, check=False,
    )
    if result.returncode != 0 or FULL_REVISION.fullmatch(result.stdout.strip()) is None:
        fail("could not read an exact resolved Verity checkout revision")
    checkout_revision = result.stdout.strip()
    if checkout_revision != requested_revision:
        fail(f"resolved Verity checkout revision {checkout_revision!r} differs from requested {requested_revision!r}")
    dirty = subprocess.run(
        ["git", "-C", str(checkout), "status", "--porcelain", "--untracked-files=all"],
        text=True, capture_output=True, check=False,
    )
    if dirty.returncode != 0 or dirty.stdout:
        fail("resolved Verity checkout is dirty or unreadable")
    return requested_revision


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parent.parent)
    args = parser.parse_args()
    try:
        revision = check(args.root.resolve())
    except (OSError, ValueError) as exc:
        print(f"Verity provenance check failed: {exc}", file=sys.stderr)
        return 1
    print(revision)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
