#!/usr/bin/env python3
"""Require the reordered source guard to invalidate the zero-demand theorem."""
import re
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
source = (ROOT / "LidoSRv3/Audit/Verity/MinFirstSourceEntry.lean").read_text()
honest = """  if demand = 0 then .ok ⟨0, buckets⟩ else
  if capacities.length < buckets.length then .error .indexOutOfBounds else"""
mutant = """  if capacities.length < buckets.length then .error .indexOutOfBounds else
  if demand = 0 then .ok ⟨0, buckets⟩ else"""
if source.count(honest) != 1:
    raise SystemExit("guard mutation site changed; update and review this test")
changed = source.replace(honest, mutant)
lines = changed.splitlines()
start = next(i + 1 for i, line in enumerate(lines) if line.startswith("theorem zero_demand"))
end = next(i + 1 for i, line in enumerate(lines) if line.startswith("theorem short_capacity"))
with tempfile.TemporaryDirectory(prefix="lido-minfirst-mutant-") as directory:
    path = Path(directory) / "GuardMutant.lean"
    path.write_text(changed)
    result = subprocess.run(["lake", "env", "lean", str(path)], cwd=ROOT,
                            capture_output=True, text=True, timeout=120)
    diagnostics = result.stdout + result.stderr
    failures = re.findall(re.escape(str(path)) + r":(\d+):\d+: error: unsolved goals", diagnostics)
    if result.returncode == 0 or not any(start <= int(line) < end for line in failures):
        raise SystemExit("mutation did not fail the zero_demand proof specifically:\n" + diagnostics)
print("MinFirst guard mutation rejected by the zero_demand theorem")
