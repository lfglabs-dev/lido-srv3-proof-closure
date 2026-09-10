#!/usr/bin/env python3
"""Check exact scoped artifacts, pinned source bytes, and validation summaries."""
import argparse, hashlib, json, re, subprocess
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]
ap = argparse.ArgumentParser()
ap.add_argument("--core", type=Path, required=True)
args = ap.parse_args()
r = json.loads((Path(__file__).parent / "receipt.json").read_text())
def digest(p): return hashlib.sha256(p.read_bytes()).hexdigest()
for path, h in r["artifacts"].items():
    assert digest(ROOT / path) == h, path
head = subprocess.check_output(["git", "-C", str(args.core), "rev-parse", "HEAD"], text=True).strip()
assert head == r["solidity_pin"], (head, r["solidity_pin"])
for path, h in r["solidity_sources"].items():
    assert digest(args.core / path) == h, path
    blob = subprocess.check_output(["git", "-C", str(args.core), "show", head + ":" + path])
    assert hashlib.sha256(blob).hexdigest() == h, path
logs = Path(__file__).parent
assert "Build completed successfully (7 jobs)" in (logs / "package-build.log").read_text()
allowed = {"propext", "Classical.choice", "Quot.sound"}
ax = (logs / "axioms.log").read_text()
sets = re.findall(r"depends on axioms:\s*\[([^]]*)\]", ax, re.S)
assert len(sets) == 10, len(sets)
for found in sets:
    assert set(re.findall(r"[A-Za-z][A-Za-z.]*", found)) <= allowed, found
reg = (logs / "regression.log").read_text()
assert reg.count("depends on axioms:") == 7 and reg.count("does not depend on any axioms") == 1
assert "863 citations checked, 0 false, 0 quote mismatches" in (logs / "source-annotations.log").read_text()
assert (logs / "slot-identity.log").read_text().count(" MATCH") == 3
for name in ["package-build.log", "wrapper-build.log", "public-build.log", "fee-helper-build.log", "regression.log", "axioms.log"]:
    assert "error:" not in (logs / name).read_text(), name
assert "539 project Lean files" in (logs / "proof-escapes.log").read_text()
print(f"PASS: {len(r['artifacts'])} exact artifacts; {len(r['solidity_sources'])} pinned source files; 10 theorem axiom sets; 8 kernel regressions; 3 physical slot identities")
