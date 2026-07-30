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


def run(root, expected_success, command="check", expected_error=None):
    env = dict(os.environ, PYTHONOPTIMIZE="1")
    result = subprocess.run(
        ["python3", "scripts/audit_metadata.py", command],
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
    if expected_error is not None and expected_error not in result.stderr:
        raise RuntimeError(
            f"missing expected error {expected_error!r}:\n"
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

        lock_path = fixture / "audit/artifacts.lock.json"
        lock = json.loads(lock_path.read_text(encoding="utf-8"))
        baseline_lock = copy.deepcopy(lock)
        # A source archive has no .git directory, remote, or branch refs.
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
        run(fixture, False, "generate")
        write_json(guarantees_path, guarantees)

        for status in ("AUDIT-CERT", "TYPO"):
            invalid_status = copy.deepcopy(guarantees)
            invalid_status["guarantees"][5]["statuses"]["source"] = status
            write_json(guarantees_path, invalid_status)
            run(fixture, False, "generate")
        write_json(guarantees_path, guarantees)

        unmapped_closure = copy.deepcopy(guarantees)
        unmapped_closure["guarantees"][0]["statuses"]["source"] = "LEAN_CHECKED"
        write_json(guarantees_path, unmapped_closure)
        run(fixture, False, "generate")
        write_json(guarantees_path, guarantees)

        unbacked = copy.deepcopy(guarantees)
        unbacked["guarantees"][5]["statuses"]["model"] = "LEAN_CHECKED"
        write_json(guarantees_path, unbacked)
        run(fixture, False, "generate")
        write_json(guarantees_path, guarantees)

        wrong_plane = copy.deepcopy(guarantees)
        wrong_plane["guarantees"][0]["statuses"]["evm"] = "LEAN_CHECKED"
        write_json(guarantees_path, wrong_plane)
        run(
            fixture,
            False,
            "generate",
            "evm status LEAN_CHECKED requires theorem evidence for that plane",
        )
        write_json(guarantees_path, guarantees)

        tx_mutant = copy.deepcopy(guarantees)
        tx_mutant["guarantees"][2]["reproduction"]["command"] = (
            "lake build LidoSRv3.Audit.Common.Atomicity"
        )
        write_json(guarantees_path, tx_mutant)
        run(fixture, False, "generate")
        write_json(guarantees_path, guarantees)

        for blocker in baseline_lock["unavailable"]:
            missing_blocker = copy.deepcopy(baseline_lock)
            del missing_blocker["unavailable"][blocker]
            write_json(lock_path, missing_blocker)
            run(fixture, False, "generate")
        write_json(lock_path, baseline_lock)

        reproduce_path = fixture / "audit/REPRODUCE.md"
        reproduce_path.write_text("stale\n", encoding="utf-8")
        run(fixture, False)

    print(
        "optimized audit metadata mutants rejected: "
        "all pins/base/blockers, status vocabulary/plane/closure, theorem, stale view"
    )


if __name__ == "__main__":
    main()
