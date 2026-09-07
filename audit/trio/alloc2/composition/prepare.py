#!/usr/bin/env python3
"""Materialize complete consumer and exact producer source for isolated validation.

The producer namespace is read from Git into a private verification worktree;
no producer-owned path in the implementation branch is created or edited.
"""
import hashlib
import json
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[4]
DEST = ROOT.parent / "temp" / "alloc2-composition"
BASE = "c7adae04416704a839d56333efad003f0a0f46b7"
PRODUCER = "8269ac576cf119975a7e9954459cd4aa04d5cd82"
ACCEPTED_INTERFACE = "2a4e9d2a91d257353470677c6101fd91293cf4e4"


def blob(commit, path):
    return subprocess.check_output(["git", "-C", str(ROOT), "show", f"{commit}:{path}"])


def main():
    head = subprocess.check_output(["git", "-C", str(DEST), "rev-parse", "HEAD"], text=True).strip()
    if head != BASE:
        raise RuntimeError("unexpected verification base")
    producer_files = [f"LidoSRv3/Audit/Source/TrioAlloc1/{name}.lean"
                      for name in ("Interface", "Storage", "Execution", "Properties", "Bytes", "Memory")]
    interface = producer_files[0]
    if blob(PRODUCER, interface) != blob(ACCEPTED_INTERFACE, interface):
        raise RuntimeError("producer interface differs from accepted v0")
    sources = {path: blob(PRODUCER, path) for path in producer_files}
    for path in sorted(ROOT.glob("LidoSRv3/Audit/Source/TrioAlloc2/*.lean")):
        sources[str(path.relative_to(ROOT))] = path.read_bytes()
    for name in ("Composition.lean", "LibraryABI.lean", "LibraryABIVectors.lean", "Parent.lean", "ParentVectors.lean", "lakefile.lean"):
        path = Path(__file__).parent / name
        sources[str(path.relative_to(ROOT))] = path.read_bytes()
    vectors = Path("LidoSRv3/Tests/TrioIntegration/LibraryABI.lean")
    sources[str(vectors)] = (ROOT / vectors).read_bytes()
    hashes = {}
    for path, data in sorted(sources.items()):
        target = DEST / path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(data)
        hashes[path] = hashlib.sha256(data).hexdigest()
    (Path(__file__).parent / "source-identity.json").write_text(json.dumps({
        "base": BASE, "producer": PRODUCER, "accepted_interface": ACCEPTED_INTERFACE,
        "files": hashes,
    }, indent=2) + "\n")
    print(f"Materialized {len(sources)} exact source/config files at {DEST}")


if __name__ == "__main__":
    main()
