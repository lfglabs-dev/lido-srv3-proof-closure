#!/usr/bin/env python3
"""Verify the retained candidate source identities without repeating tests."""
import hashlib
import json
import subprocess
from pathlib import Path

root = Path(__file__).resolve().parents[2]
dossier = Path(__file__).resolve().parent
manifest = json.loads((dossier / 'source-inputs.json').read_text())
errors = []
for name, expected in manifest['sources'].items():
    path = root / name
    if not path.is_file() or hashlib.sha256(path.read_bytes()).hexdigest() != expected:
        errors.append(name)
for package, expected in manifest['lean_package_pins'].items():
    result = subprocess.run(['git', 'rev-parse', 'HEAD'], cwd=root / '.lake/packages' / package, capture_output=True, text=True)
    if result.returncode != 0 or result.stdout.strip() != expected:
        errors.append('package:' + package)
for status in ['lean-status.json', 'solidity-status.json']:
    if json.loads((dossier / status).read_text())['exit_code'] != 0:
        errors.append(status)
for name, expected in json.loads((dossier / 'receipt.json').read_text())['artifacts'].items():
    path = dossier / name
    if not path.is_file() or hashlib.sha256(path.read_bytes()).hexdigest() != expected:
        errors.append(name)
if errors:
    raise SystemExit('Mismatch: ' + ', '.join(errors))
print(f"PASS: {len(manifest['sources'])} source identities; retained Lean/Forge exits and receipt artifacts.")
