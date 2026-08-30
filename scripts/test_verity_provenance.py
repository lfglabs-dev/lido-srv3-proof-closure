#!/usr/bin/env python3
"""Family-level mutants for Verity provenance agreement and uniqueness."""

from __future__ import annotations

import json
import os
import shutil
import subprocess
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
CHECKER = ROOT / "scripts/check_verity_provenance.py"
FILES = (
    "lakefile.lean",
    "lake-manifest.json",
    "audit/artifacts.lock.json",
    "verity/targets/audit-manifest.json",
    "verity/targets/source-map.json",
    "proofs/LOCKFILE.md",
)
PIN = "e977aaad6e1a9e92e0132d41b3d33a14135a4d46"
OTHER = "0" * 40


def run(root: Path, succeeds: bool, diagnostic: str = "") -> None:
    result = subprocess.run(
        ["python3", str(CHECKER), "--root", str(root)],
        text=True, capture_output=True, check=False,
    )
    if (result.returncode == 0) != succeeds:
        raise SystemExit(f"unexpected provenance result: {result.stdout}{result.stderr}")
    if diagnostic and diagnostic not in result.stderr:
        raise SystemExit(f"missing diagnostic {diagnostic!r}: {result.stderr}")


def load(path: Path) -> dict[str, object]:
    return json.loads(path.read_text(encoding="utf-8"))


def write(path: Path, value: object) -> None:
    path.write_text(json.dumps(value, indent=2) + "\n", encoding="utf-8")


with tempfile.TemporaryDirectory(prefix="verity-provenance-mutants-") as tmp:
    fixture = Path(tmp)
    for relative in FILES:
        destination = fixture / relative
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(ROOT / relative, destination)
    (fixture / ".lake/packages").mkdir(parents=True)
    os.symlink(ROOT / ".lake/packages/verity", fixture / ".lake/packages/verity")

    run(fixture, True)

    lakefile = fixture / "lakefile.lean"
    original_lakefile = lakefile.read_text(encoding="utf-8")
    lakefile.write_text(original_lakefile.replace(PIN, PIN[:12]), encoding="utf-8")
    run(fixture, False, "not an exact 40-hex revision")
    lakefile.write_text(original_lakefile + original_lakefile.split("require verity", 1)[1].join(("\nrequire verity", "")), encoding="utf-8")
    run(fixture, False, "exactly one canonical Verity git request")
    lakefile.write_text(original_lakefile, encoding="utf-8")

    manifest_path = fixture / "lake-manifest.json"
    manifest = load(manifest_path)
    package = next(p for p in manifest["packages"] if p["name"] == "verity")
    package["rev"] = OTHER
    write(manifest_path, manifest)
    run(fixture, False, "Verity rev")
    package["rev"] = PIN
    package["inputRev"] = OTHER
    write(manifest_path, manifest)
    run(fixture, False, "Verity inputRev")
    package["inputRev"] = PIN
    manifest["packages"].append(dict(package))
    write(manifest_path, manifest)
    run(fixture, False, "exactly one Verity package")
    shutil.copy2(ROOT / "lake-manifest.json", manifest_path)

    lock_path = fixture / "audit/artifacts.lock.json"
    lock = load(lock_path)
    lock["pins"]["verity"]["commit"] = OTHER
    write(lock_path, lock)
    run(fixture, False, "artifact-lock Verity pin")
    shutil.copy2(ROOT / "audit/artifacts.lock.json", lock_path)

    audit_path = fixture / "verity/targets/audit-manifest.json"
    audit = load(audit_path)
    audit["source_revisions"]["verity"] = OTHER
    write(audit_path, audit)
    run(fixture, False, "audit-manifest Verity revision")
    shutil.copy2(ROOT / "verity/targets/audit-manifest.json", audit_path)

    source_map_path = fixture / "verity/targets/source-map.json"
    source_map = load(source_map_path)
    source_revisions = source_map.get("source_revisions")
    if not isinstance(source_revisions, dict):
        raise SystemExit("fixture source_revisions must be an object")
    source_revisions["verity_commit"] = OTHER
    write(source_map_path, source_map)
    run(fixture, False, "source-map Verity revision")
    shutil.copy2(ROOT / "verity/targets/source-map.json", source_map_path)

    lockfile_path = fixture / "proofs/LOCKFILE.md"
    original_lockfile = lockfile_path.read_text(encoding="utf-8")
    lockfile_path.write_text(original_lockfile.replace(PIN, OTHER), encoding="utf-8")
    run(fixture, False, "proofs/LOCKFILE.md Verity pin")
    lockfile_path.write_text(original_lockfile, encoding="utf-8")

    # Regression: row only inside an HTML comment must not qualify
    verity_row = next(l for l in original_lockfile.splitlines(keepends=True) if "| Verity |" in l)
    without_active = original_lockfile.replace(verity_row, "")
    lockfile_path.write_text(without_active + f"<!-- {verity_row.rstrip()} -->\n", encoding="utf-8")
    run(fixture, False, "proofs/LOCKFILE.md must contain exactly one Verity pin row")
    # Regression: unclosed HTML comment running to EOF swallows remaining content (discussion_r3889427978)
    lockfile_path.write_text(without_active + f"<!--\n{verity_row}", encoding="utf-8")
    run(fixture, False, "proofs/LOCKFILE.md must contain exactly one Verity pin row")
    # Regression: row only inside a fenced code block must not qualify
    lockfile_path.write_text(without_active + f"```\n{verity_row}```\n", encoding="utf-8")
    run(fixture, False, "proofs/LOCKFILE.md must contain exactly one Verity pin row")
    # Regression: opener indented up to 3 spaces is still a valid fence opener
    lockfile_path.write_text(without_active + f"   ```\n{verity_row}```\n", encoding="utf-8")
    run(fixture, False, "proofs/LOCKFILE.md must contain exactly one Verity pin row")
    # Regression: closer longer than opener still closes the fence
    lockfile_path.write_text(without_active + f"```\n{verity_row}````\n", encoding="utf-8")
    run(fixture, False, "proofs/LOCKFILE.md must contain exactly one Verity pin row")
    # Regression: unclosed fence at EOF swallows remaining content
    lockfile_path.write_text(without_active + f"```\n{verity_row}", encoding="utf-8")
    run(fixture, False, "proofs/LOCKFILE.md must contain exactly one Verity pin row")
    # Positive regression: unclosed <!-- inside a fenced block is literal content, not an HTML
    # comment opener; the real Verity row appearing after the fence must still be found
    # (discussion_r3889471382)
    lockfile_path.write_text(without_active + f"```\nsome fenced content <!--\n```\n{verity_row}", encoding="utf-8")
    run(fixture, True)
    # Regression: multiline code span (backtick run with backtick in info string that is not a
    # CommonMark fence opener) makes the enclosed row non-table content; must be rejected
    # (discussion_r3889471379)
    lockfile_path.write_text(without_active + f"```foo`\n{verity_row}```\n", encoding="utf-8")
    run(fixture, False, "proofs/LOCKFILE.md must contain exactly one Verity pin row")
    lockfile_path.write_text(original_lockfile, encoding="utf-8")

print(
    "Verity provenance mutants rejected: exact lakefile request, request uniqueness, "
    "manifest rev/inputRev/uniqueness, canonical artifact/audit/source-map pins, "
    "lockfile Verity pin (HTML comment, unclosed-HTML-comment-to-EOF, equal fence, "
    "indented opener, longer closer, unclosed-at-EOF, backtick-code-span-suppressor); "
    "positive gates: baseline, fenced-literal-unclosed-HTML-comment; "
    "checkout identity agree"
)
