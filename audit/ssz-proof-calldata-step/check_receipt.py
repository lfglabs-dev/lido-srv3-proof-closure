#!/usr/bin/env python3
"""Read-only replay of recorded inputs; does not compile Lean or execute Forge."""
import hashlib
import json
from pathlib import Path
import subprocess

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent.parent

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

receipt = json.loads((HERE / "receipt.json").read_text())
deps = json.loads((HERE / "dependency-inputs.json").read_text())
errors = []
checks = 0
for name, expected in {**receipt["validated_inputs"], **receipt["evidence_hashes"]}.items():
    checks += 1
    path = ROOT / name
    if not path.is_file() or sha(path) != expected:
        errors.append(name)
for entry in deps["package_source_closure"]:
    checks += 1
    path = ROOT / entry["path"]
    if not path.is_file() or sha(path) != entry["sha256"]:
        errors.append(entry["path"])
lean_prefix = Path(subprocess.check_output(["lake", "env", "lean", "--print-prefix"], cwd=ROOT, text=True).strip())
for name, expected in deps["selected_core_sources"].items():
    checks += 1
    path = lean_prefix / "src/lean" / name
    if not path.is_file() or sha(path) != expected:
        errors.append("toolchain:" + name)
for path, expected in receipt["package_pins"].items():
    actual = subprocess.check_output(["git", "-C", str(ROOT / path), "rev-parse", "HEAD"], text=True).strip()
    checks += 1
    if actual != expected:
        errors.append("pin:" + path)
for name in receipt["pinned_solidity_sources"]:
    path = ROOT / "lido-core" / name
    pinned = subprocess.check_output(["git", "-C", str(ROOT / "lido-core"), "show", receipt["source_pin"] + ":" + name])
    checks += 1
    if path.read_bytes() != pinned:
        errors.append("source-pin:" + name)
print(json.dumps({"scope": "Recorded file/package-pin comparison only; no fresh proof or EVM execution", "checks": checks, "errors": errors}, indent=2))
raise SystemExit(bool(errors))
