#!/usr/bin/env python3
"""Copy owned Lean files to the private base-shaped verification worktree.

The remote fetch transport cannot fetch unpublished commits containing gitlinks.
Keep the persistent implementation branch intact and send exact changed sources
as the durable build protocol's hashed overlay over the public pinned base.
"""
import hashlib
import json
from pathlib import Path
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[3]
DEST = ROOT.parent / "temp" / "alloc2-verification"
BASE = "c7adae04416704a839d56333efad003f0a0f46b7"


def main():
    actual = subprocess.check_output(["git", "-C", str(DEST), "rev-parse", "HEAD"], text=True).strip()
    if actual != BASE:
        raise RuntimeError("verification worktree must stay at the exact base")
    paths = sorted(
        list(ROOT.glob("LidoSRv3/Audit/Source/TrioAlloc2/*.lean"))
        + list(ROOT.glob("LidoSRv3/Tests/TrioAlloc2/*.lean"))
        + [ROOT / "audit/trio/alloc2/lakefile.lean"]
    )
    manifest_path = DEST.parent / "alloc2-verification-source-sha256.json"
    previous = json.loads(manifest_path.read_text()) if manifest_path.exists() else {}
    current = {str(p.relative_to(ROOT)) for p in paths}
    for removed in previous.keys() - current:
        relative = Path(removed)
        allowed = (
            relative.parent == Path("LidoSRv3/Audit/Source/TrioAlloc2")
            or relative.parent == Path("LidoSRv3/Tests/TrioAlloc2")
            or relative == Path("audit/trio/alloc2/lakefile.lean")
        )
        if not allowed or relative.suffix != ".lean":
            raise RuntimeError("previous overlay contains an unexpected path")
        (DEST / relative).unlink(missing_ok=True)
    hashes = {}
    for source in paths:
        relative = source.relative_to(ROOT)
        target = DEST / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(source, target)
        hashes[str(relative)] = hashlib.sha256(source.read_bytes()).hexdigest()
    manifest_path.write_text(json.dumps(hashes, indent=2) + "\n")
    print(f"Copied {len(paths)} source files to {DEST}; implementation branch unchanged.")


if __name__ == "__main__":
    main()
