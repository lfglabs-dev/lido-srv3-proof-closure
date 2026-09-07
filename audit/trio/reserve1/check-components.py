#!/usr/bin/env python3
"""Bounded component elaboration; never a replacement for remote full gates."""
import argparse
import datetime
import hashlib
import json
import os
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[3]
RECEIPTS_ROOT = ROOT / "audit/trio/reserve1/receipts/component-checks"
LEAN = ROOT / "audit/trio/reserve1/.local/lean4-v4.31.0/bin/lean"
MODULES = [
    "Audit/Source/TrioReserve1/Live",
    "Audit/Source/TrioReserve1/ABI",
    "Audit/Source/TrioReserve1/PartitionSpec",
    "Audit/Source/TrioReserve1/QueueSpec",
    "Audit/Source/TrioReserve1/Queue",
    "Audit/Source/TrioReserve1/Packing",
    "Audit/Source/TrioReserve1/PhysicalPacking",
    "Audit/Source/TrioReserve1/Erasure",
    "Audit/Source/TrioReserve1/WriterSpec",
    "Audit/Source/TrioReserve1/Writers",
    "Audit/Source/TrioReserve1/AllocationSpec",
    "Audit/Source/TrioReserve1/Allocation",
    "Audit/Source/TrioReserve1/AdmissionSpec",
    "Audit/Source/TrioReserve1/Admission",
    "Audit/Source/TrioReserve1/RouterSpec",
    "Audit/Source/TrioReserve1/Router",
    "Audit/Source/TrioReserve1/Locator",
    "Audit/Source/TrioReserve1/CallResults",
    "Audit/Source/TrioReserve1/QueueCalls",
    "Audit/Source/TrioReserve1/WithdrawalTail",
    "Audit/Source/TrioReserve1/SpendingSpec",
    "Audit/Source/TrioReserve1/Spending",
    "Audit/Source/TrioReserve1/WithdrawalComposition",
    "Audit/Source/TrioReserve1/Transfers",
    "Audit/Source/TrioReserve1/StaticCall",
    "Audit/Source/TrioReserve1/OracleSpec",
    "Audit/Source/TrioReserve1/Oracle",
    "Audit/Source/TrioReserve1/OracleCalls",
    "Audit/Source/TrioReserve1/FrameSpec",
    "Audit/Source/TrioReserve1/Consensus",
    "Audit/Source/TrioReserve1/ConsensusCalls",
    "Audit/Source/TrioReserve1/Pipeline",
    "Audit/Source/TrioReserve1/PhysicalReserve",
    "Audit/Source/TrioReserve1/SequenceSpec",
    "Audit/Source/TrioReserve1/PhysicalSequence",
    "Audit/Source/TrioReserve1/AragonSpec",
    "Audit/Source/TrioReserve1/Aragon",
    "Tests/TrioReserve1/Foundations",
    "Tests/TrioReserve1/OracleMutants",
    "Tests/TrioReserve1/Differential",
    "Tests/TrioReserve1/AragonDifferential",
    "Tests/TrioReserve1/LiveTrust",
]

def git(*args):
    return subprocess.check_output(["git", *args], cwd=ROOT, text=True).strip()

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--module", action="append", choices=MODULES,
        help="Check only selected modules, in dependency order; dependencies must already be built")
    args = parser.parse_args()
    selected = [m for m in MODULES if args.module is None or m in args.module]
    # Source must be reviewable at the recorded immutable commit. Receipts may
    # be dirty because they are necessarily produced after that source commit.
    for owned in ["LidoSRv3/Audit/Source/TrioReserve1", "LidoSRv3/Tests/TrioReserve1", "solidity/trio-reserve1"]:
        if git("status", "--porcelain", "--", owned):
            raise SystemExit(f"uncommitted source under {owned}")
    receipts = RECEIPTS_ROOT / git("rev-parse", "HEAD")
    receipts.mkdir(parents=True, exist_ok=False)
    env = os.environ.copy()
    env["LEAN_PATH"] = ":".join([str(ROOT / ".lake/build/lib/lean")] +
        [str(p / ".lake/build/lib/lean") for p in sorted((ROOT / ".lake/packages").iterdir())])
    receipt = {
        "source_commit": git("rev-parse", "HEAD"),
        "started_utc": datetime.datetime.now(datetime.timezone.utc).isoformat(),
        "toolchain": (ROOT / "lean-toolchain").read_text().strip(),
        "lean_version": subprocess.check_output([str(LEAN), "--version"], text=True).strip(),
        "lean_sha256": sha(LEAN), "lean_path": env["LEAN_PATH"],
        "scope": "Owned component modules using existing dependency oleans; not a clean/full build or certification",
        "selected_modules": selected,
        "checks": [],
    }
    for module in selected:
        source = Path("LidoSRv3") / (module + ".lean")
        target = ROOT / ".lake/build/lib/lean" / source.with_suffix(".olean")
        command = [str(LEAN), "-o", str(target), str(source)]
        result = subprocess.run(command, cwd=ROOT, env=env, capture_output=True, text=True)
        label = module.rsplit("/", 1)[-1]
        log = receipts / (label + ".txt")
        log.write_text(result.stdout + result.stderr)
        receipt["checks"].append({"command": command, "exit": result.returncode,
            "source_sha256": sha(ROOT / source), "log_sha256": sha(log),
            "olean_sha256": sha(target) if result.returncode == 0 else None})
        (receipts / "receipt.json").write_text(json.dumps(receipt, indent=2) + "\n")
        print(label, result.returncode, flush=True)
        if result.returncode:
            raise SystemExit(result.returncode)

if __name__ == "__main__":
    main()
