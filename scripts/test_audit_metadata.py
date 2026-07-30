#!/usr/bin/env python3
"""Optimized-Python negative regressions for audit metadata validation."""

import copy
import json
import os
import shutil
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def run(root, expected_success):
    env = dict(os.environ, PYTHONOPTIMIZE="1")
    result = subprocess.run(
        ["python3", "scripts/audit_metadata.py", "check"],
        cwd=root,
        env=env,
        capture_output=True,
        text=True,
    )
    if (result.returncode == 0) != expected_success:
        raise RuntimeError(
            f"unexpected audit result ({result.returncode}):\n"
            f"stdout:\n{result.stdout}\nstderr:\n{result.stderr}"
        )


def write_json(path, value):
    path.write_text(json.dumps(value, indent=2) + "\n", encoding="utf-8")


def main():
    with tempfile.TemporaryDirectory(prefix="audit-metadata-") as directory:
        fixture = Path(directory)
        for name in ("audit", "scripts"):
            shutil.copytree(ROOT / name, fixture / name)
        for name in ("lakefile.lean", "lake-manifest.json", "lean-toolchain"):
            shutil.copy2(ROOT / name, fixture / name)
        (fixture / "verity/targets").mkdir(parents=True)
        shutil.copy2(
            ROOT / "verity/targets/audit-manifest.json",
            fixture / "verity/targets/audit-manifest.json",
        )

        subprocess.run(["git", "init", "-q"], cwd=fixture, check=True)
        subprocess.run(
            ["git", "remote", "add", "origin",
             "https://github.com/lfglabs-dev/lido-srv3-proof-closure.git"],
            cwd=fixture,
            check=True,
        )
        subprocess.run(["git", "add", "."], cwd=fixture, check=True)
        subprocess.run(
            ["git", "-c", "user.name=Audit Test", "-c", "user.email=audit@example.invalid",
             "commit", "-qm", "fixture"],
            cwd=fixture,
            check=True,
        )
        head = subprocess.run(
            ["git", "rev-parse", "HEAD"],
            cwd=fixture,
            check=True,
            capture_output=True,
            text=True,
        ).stdout.strip()
        subprocess.run(
            ["git", "branch", "campaign/lido-minimal-11", head],
            cwd=fixture,
            check=True,
        )

        lock_path = fixture / "audit/artifacts.lock.json"
        lock = json.loads(lock_path.read_text(encoding="utf-8"))
        lock["campaign_base"]["commit"] = head
        write_json(lock_path, lock)
        baseline_lock = copy.deepcopy(lock)
        run(fixture, True)

        lock_leaves = [
            ("campaign_base", field) for field in ("repository", "ref", "commit")
        ]
        for pin, values in baseline_lock["pins"].items():
            lock_leaves.extend(("pins", pin, field) for field in values)
        for path in lock_leaves:
            for remove in (False, True):
                mutant = copy.deepcopy(baseline_lock)
                target = mutant
                for key in path[:-1]:
                    target = target[key]
                if remove:
                    del target[path[-1]]
                else:
                    target[path[-1]] = "stale"
                write_json(lock_path, mutant)
                run(fixture, False)
        write_json(lock_path, baseline_lock)

        guarantees_path = fixture / "audit/guarantees.yaml"
        guarantees = json.loads(guarantees_path.read_text(encoding="utf-8"))
        malformed = copy.deepcopy(guarantees)
        malformed["guarantees"][0]["statuses"].pop("crypto")
        write_json(guarantees_path, malformed)
        run(fixture, False)
        write_json(guarantees_path, guarantees)

        tx_mutant = copy.deepcopy(guarantees)
        tx_mutant["guarantees"][2]["reproduction"]["command"] = (
            "lake build LidoSRv3.Audit.Common.Atomicity"
        )
        write_json(guarantees_path, tx_mutant)
        run(fixture, False)
        write_json(guarantees_path, guarantees)

        reproduce_path = fixture / "audit/REPRODUCE.md"
        reproduce_path.write_text("stale\n", encoding="utf-8")
        run(fixture, False)

    print("optimized audit metadata mutants rejected: all pins/base, status, theorem, stale view")


if __name__ == "__main__":
    main()
