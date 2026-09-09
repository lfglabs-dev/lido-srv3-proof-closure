#!/usr/bin/env python3
"""Regenerate the fixtures from actual Lean output, or check retained bytes.

Default is read-only. --write writes vectors.json and ModuleVectors.sol.
The Lean command executes the encoder; it is not an independent proof review.
"""
import argparse
import json
from pathlib import Path
import subprocess

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent.parent
parser = argparse.ArgumentParser()
parser.add_argument("--write", action="store_true")
args = parser.parse_args()
raw = subprocess.check_output(
    ["lake", "env", "lean", "--run", "audit/topup-module-call/Export.lean"],
    cwd=ROOT, text=True)
rows = json.loads(raw)
assert len(rows) == 64 and [r["seed"] for r in rows] == list(range(64))
source = "// Generated from Export.lean output; regenerate, do not edit.\npragma solidity 0.8.25;\nlibrary ModuleVectors {\nfunction get(uint256 seed) internal pure returns(bytes memory payload,bytes memory reply) {\n"
for row in rows:
    bytes.fromhex(row["payload"])
    bytes.fromhex(row["reply"])
    source += f'if(seed=={row["seed"]}) return(hex"{row["payload"]}",hex"{row["reply"]}");\n'
source += 'revert("unknown vector");\n}\n}\n'
outputs = {HERE / "vectors.json": json.dumps(rows, indent=2) + "\n",
           HERE / "solidity/ModuleVectors.sol": source}
for path, expected in outputs.items():
    if args.write:
        path.write_text(expected)
    else:
        assert path.read_text() == expected, path
print(json.dumps({"vectors": len(rows), "generated_files": len(outputs),
                  "mode": "write" if args.write else "check", "passed": True}))
