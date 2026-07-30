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

        source_map_path = fixture / "audit/source-map.yaml"
        source_map = json.loads(source_map_path.read_text(encoding="utf-8"))
        forked_source = copy.deepcopy(source_map)
        forked_source["pinned_source"] = forked_source["pinned_source"].replace(
            "lidofinance/core@", "example/core@"
        )
        forked_lock = copy.deepcopy(baseline_lock)
        forked_lock["pins"]["lido_core"]["repository"] = (
            "https://github.com/example/core.git"
        )
        write_json(source_map_path, forked_source)
        write_json(lock_path, forked_lock)
        run(
            fixture,
            False,
            "generate",
            "pinned_source must use the canonical lidofinance/core repository",
        )
        write_json(source_map_path, source_map)
        write_json(lock_path, baseline_lock)

        exclusions_path = fixture / "audit/exclusions.yaml"
        exclusions = json.loads(exclusions_path.read_text(encoding="utf-8"))
        write_json(exclusions_path, {})
        run(
            fixture,
            False,
            "generate",
            "exclusions differ from the canonical scope boundary set",
        )
        write_json(exclusions_path, exclusions)

        assumptions_path = fixture / "audit/assumptions.yaml"
        assumptions = json.loads(assumptions_path.read_text(encoding="utf-8"))
        for field, value in (("accepted", False), ("risk", "")):
            malformed_assumption = copy.deepcopy(assumptions)
            malformed_assumption["assumptions"][0][field] = value
            write_json(assumptions_path, malformed_assumption)
            run(
                fixture,
                False,
                "generate",
                "assumptions differ from the canonical accepted risk records",
            )
        write_json(assumptions_path, assumptions)

        guarantees_path = fixture / "audit/guarantees.yaml"
        guarantees = json.loads(guarantees_path.read_text(encoding="utf-8"))
        contradictory_authority = copy.deepcopy(guarantees)
        contradictory_authority["authority"] = (
            "This metadata closes every semantic guarantee."
        )
        write_json(guarantees_path, contradictory_authority)
        run(
            fixture,
            False,
            "generate",
            "guarantee registry authority differs from the canonical declaration",
        )
        write_json(guarantees_path, guarantees)

        audit_manifest_path = fixture / "verity/targets/audit-manifest.json"
        audit_manifest = json.loads(
            audit_manifest_path.read_text(encoding="utf-8")
        )
        missing_common_module = copy.deepcopy(audit_manifest)
        missing_common_module["layers"]["audit"]["modules"].remove(
            "LidoSRv3.Audit.Common.Atomicity"
        )
        write_json(audit_manifest_path, missing_common_module)
        run(
            fixture,
            False,
            "generate",
            "audit manifest omits canonical Common modules",
        )
        for index, theorem in enumerate(audit_manifest["theorems"]):
            missing_theorem = copy.deepcopy(audit_manifest)
            del missing_theorem["theorems"][index]
            write_json(audit_manifest_path, missing_theorem)
            run(
                fixture,
                False,
                "generate",
                "audit manifest theorem ledger differs from the canonical records",
            )
            mutated_theorem = copy.deepcopy(audit_manifest)
            mutated_theorem["theorems"][index]["axioms"] = ["False"]
            write_json(audit_manifest_path, mutated_theorem)
            run(
                fixture,
                False,
                "generate",
                "audit manifest theorem ledger differs from the canonical records",
            )
        write_json(audit_manifest_path, audit_manifest)

        for revision in ("verity", "lean"):
            stale_revision = copy.deepcopy(audit_manifest)
            stale_revision["source_revisions"][revision] = "stale"
            write_json(audit_manifest_path, stale_revision)
            run(
                fixture,
                False,
                "generate",
                f"{('Lake Verity' if revision == 'verity' else 'Lean toolchain')} "
                "pin differs from verity target audit manifest",
            )
        write_json(audit_manifest_path, audit_manifest)

        toolchain_path = fixture / "lean-toolchain"
        canonical_toolchain = toolchain_path.read_text(encoding="utf-8")
        noncanonical_toolchain = canonical_toolchain.replace(
            "leanprover/lean4:", "example/lean4:"
        )
        toolchain_path.write_text(noncanonical_toolchain, encoding="utf-8")
        noncanonical_lock = copy.deepcopy(baseline_lock)
        noncanonical_lock["pins"]["lean"]["toolchain"] = noncanonical_toolchain.strip()
        write_json(lock_path, noncanonical_lock)
        run(
            fixture,
            False,
            "generate",
            "lean-toolchain must use the canonical Lean 4.31 toolchain",
        )
        toolchain_path.write_text(canonical_toolchain, encoding="utf-8")
        write_json(lock_path, baseline_lock)

        newer_toolchain = canonical_toolchain.replace("v4.31.0", "v4.32.0")
        toolchain_path.write_text(newer_toolchain, encoding="utf-8")
        newer_lock = copy.deepcopy(baseline_lock)
        newer_lock["pins"]["lean"]["toolchain"] = newer_toolchain.strip()
        write_json(lock_path, newer_lock)
        newer_manifest = copy.deepcopy(audit_manifest)
        newer_manifest["source_revisions"]["lean"] = "v4.32.0"
        write_json(audit_manifest_path, newer_manifest)
        run(
            fixture,
            False,
            "generate",
            "lean-toolchain must use the canonical Lean 4.31 toolchain",
        )
        toolchain_path.write_text(canonical_toolchain, encoding="utf-8")
        write_json(lock_path, baseline_lock)
        write_json(audit_manifest_path, audit_manifest)

        proof_policy_mutants = {
            "project_axioms": 1,
            "sorry": 1,
            "admit": 1,
            "unsafe_proof_escapes": 1,
            "report_entrypoint": "LidoSRv3.Audit.Missing",
        }
        for field, value in proof_policy_mutants.items():
            malformed_policy = copy.deepcopy(audit_manifest)
            malformed_policy["proof_policy"][field] = value
            write_json(audit_manifest_path, malformed_policy)
            run(
                fixture,
                False,
                "generate",
                "audit manifest proof policy differs from the canonical zero-escape policy",
            )
        write_json(audit_manifest_path, audit_manifest)

        malformed = copy.deepcopy(guarantees)
        malformed["guarantees"][0]["statuses"].pop("crypto")
        write_json(guarantees_path, malformed)
        run(fixture, False, "generate")
        write_json(guarantees_path, guarantees)

        for index, guarantee in enumerate(guarantees["guarantees"]):
            theorem_mutant = copy.deepcopy(guarantees)
            theorem_mutant["guarantees"][index]["theorem"] = (
                "LidoSRv3.Audit.DoesNotExist"
            )
            write_json(guarantees_path, theorem_mutant)
            run(
                fixture,
                False,
                "generate",
                f"{guarantee['id']}: theorem differs from canonical evidence",
            )
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

        for index, guarantee in enumerate(guarantees["guarantees"]):
            command_mutant = copy.deepcopy(guarantees)
            command_mutant["guarantees"][index]["reproduction"]["command"] = "true"
            write_json(guarantees_path, command_mutant)
            run(
                fixture,
                False,
                "generate",
                f"{guarantee['id']}: reproduction record differs from canonical evidence",
            )
        write_json(guarantees_path, guarantees)

        expected_mutant = copy.deepcopy(guarantees)
        expected_mutant["guarantees"][5]["reproduction"]["expected"] = (
            "certified source correspondence"
        )
        write_json(guarantees_path, expected_mutant)
        run(
            fixture,
            False,
            "generate",
            "SRV3-SOLIDITY-CORR: reproduction record differs from canonical evidence",
        )
        write_json(guarantees_path, guarantees)

        for index, guarantee in enumerate(guarantees["guarantees"]):
            gate_mutant = copy.deepcopy(guarantees)
            gate_mutant["guarantees"][index]["next_gate"] = (
                "All production guarantees are certified."
            )
            write_json(guarantees_path, gate_mutant)
            run(
                fixture,
                False,
                "generate",
                f"{guarantee['id']}: next gate differs from canonical roadmap",
            )
        write_json(guarantees_path, guarantees)

        for index, guarantee in enumerate(guarantees["guarantees"]):
            missing_link = copy.deepcopy(guarantees)
            missing_link["guarantees"][index]["assumptions"] = []
            write_json(guarantees_path, missing_link)
            run(
                fixture,
                False,
                "generate",
                f"{guarantee['id']}: assumption links differ from canonical risks",
            )
        write_json(guarantees_path, guarantees)

        for blocker in baseline_lock["unavailable"]:
            missing_blocker = copy.deepcopy(baseline_lock)
            del missing_blocker["unavailable"][blocker]
            write_json(lock_path, missing_blocker)
            run(fixture, False, "generate")
        write_json(lock_path, baseline_lock)

        blocker_mutant = copy.deepcopy(source_map)
        blocker_mutant["targets"][8]["blocker"] = (
            "Canonical production runtime independently verified."
        )
        write_json(source_map_path, blocker_mutant)
        run(
            fixture,
            False,
            "generate",
            "source-map targets differ from canonical blocker records",
        )
        write_json(source_map_path, source_map)

        policy_mutant = copy.deepcopy(source_map)
        policy_mutant["policy"] = "Fabricated and unverified spans are permitted."
        write_json(source_map_path, policy_mutant)
        run(
            fixture,
            False,
            "generate",
            "source-map policy differs from the canonical assurance rule",
        )
        write_json(source_map_path, source_map)

        reproduce_path = fixture / "audit/REPRODUCE.md"
        reproduce_path.write_text("stale\n", encoding="utf-8")
        run(fixture, False)

    print(
        "optimized audit metadata mutants rejected: "
        "all pins/base/blockers, source/exclusions, "
        "assumption records/links, authority, full manifest theorem ledger/revisions, "
        "canonical Lean toolchain, proof policy, source-map policy, reproduction evidence, "
        "status vocabulary/plane/closure, stale view"
    )


if __name__ == "__main__":
    main()
