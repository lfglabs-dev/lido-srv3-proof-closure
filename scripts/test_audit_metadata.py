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
        for name in ("audit", "scripts", "content", "proofs"):
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

        reproducibility_path = fixture / "content/05-reproducibility.tex"
        reproducibility = reproducibility_path.read_text(encoding="utf-8")
        reproducibility_path.write_text(
            reproducibility.replace(
                "04729a9de9099e065dd09283e4f733a5fd4c2a16",
                "d2d4a18a4d7021adcd90d4b03e619affe506dd54",
                1,
            ),
            encoding="utf-8",
        )
        run(
            fixture,
            False,
            "check",
            "reproducibility report must name the canonical Verity pin exactly twice",
        )
        reproducibility_path.write_text(reproducibility, encoding="utf-8")

        proof_lockfile_path = fixture / "proofs/LOCKFILE.md"
        proof_lockfile = proof_lockfile_path.read_text(encoding="utf-8")
        proof_lockfile_path.write_text(
            proof_lockfile.replace(
                "04729a9de9099e065dd09283e4f733a5fd4c2a16",
                "d2d4a18a4d7021adcd90d4b03e619affe506dd54",
                1,
            ),
            encoding="utf-8",
        )
        run(
            fixture,
            False,
            "check",
            "proofs/LOCKFILE.md Verity pin differs from the canonical dependency pin",
        )
        proof_lockfile_path.write_text(proof_lockfile, encoding="utf-8")

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

        coordinated_source = copy.deepcopy(source_map)
        coordinated_source["pinned_source"] = (
            "lidofinance/core@" + "0" * 40
        )
        original_source_sha = source_map["pinned_source"].rsplit("@", 1)[-1]
        for target in coordinated_source["targets"]:
            for span in target["spans"]:
                span["source_sha"] = "0" * 40
                span["permalink"] = span["permalink"].replace(
                    original_source_sha, "0" * 40
                )
        coordinated_lock = copy.deepcopy(baseline_lock)
        coordinated_lock["pins"]["lido_core"]["commit"] = "0" * 40
        write_json(source_map_path, coordinated_source)
        write_json(lock_path, coordinated_lock)
        coordinated_manifest_path = fixture / "verity/targets/audit-manifest.json"
        coordinated_manifest = json.loads(
            coordinated_manifest_path.read_text(encoding="utf-8")
        )
        coordinated_manifest["source_revisions"]["lido"] = "0" * 40
        write_json(coordinated_manifest_path, coordinated_manifest)
        run(
            fixture,
            False,
            "generate",
            "source-map Lido pin differs from the canonical source commit",
        )
        write_json(source_map_path, source_map)
        write_json(lock_path, baseline_lock)
        shutil.copy2(
            ROOT / "verity/targets/audit-manifest.json",
            coordinated_manifest_path,
        )

        lake_manifest_path = fixture / "lake-manifest.json"
        lake_manifest = json.loads(lake_manifest_path.read_text(encoding="utf-8"))
        coordinated_evmyul_manifest = copy.deepcopy(lake_manifest)
        evmyul = next(
            package
            for package in coordinated_evmyul_manifest["packages"]
            if package["name"] == "evmyul"
        )
        evmyul["url"] = "https://github.com/example/EVMYulLean.git"
        evmyul["rev"] = "0" * 40
        evmyul["inputRev"] = "0" * 40
        coordinated_evmyul_lock = copy.deepcopy(baseline_lock)
        coordinated_evmyul_lock["pins"]["evmyullean"] = {
            "repository": evmyul["url"],
            "commit": evmyul["rev"],
        }
        write_json(lake_manifest_path, coordinated_evmyul_manifest)
        write_json(lock_path, coordinated_evmyul_lock)
        run(
            fixture,
            False,
            "check",
            "artifacts.lock.json pins differ from source-map/toolchain/Lake authorities",
        )
        write_json(lake_manifest_path, lake_manifest)
        write_json(lock_path, baseline_lock)

        for field, value in (
            ("url", "https://github.com/example/mathlib4.git"),
            ("rev", "0" * 40),
        ):
            drifted_mathlib_manifest = copy.deepcopy(lake_manifest)
            mathlib = next(
                package
                for package in drifted_mathlib_manifest["packages"]
                if package["name"] == "mathlib"
            )
            mathlib[field] = value
            drifted_mathlib_lock = copy.deepcopy(baseline_lock)
            lock_field = "repository" if field == "url" else "commit"
            drifted_mathlib_lock["pins"]["mathlib"][lock_field] = value
            write_json(lake_manifest_path, drifted_mathlib_manifest)
            write_json(lock_path, drifted_mathlib_lock)
            run(
                fixture,
                False,
                "check",
                "Lake mathlib pin differs from the canonical migration receipt",
            )
        write_json(lake_manifest_path, lake_manifest)
        write_json(lock_path, baseline_lock)

        stale_mathlib_input = copy.deepcopy(lake_manifest)
        mathlib = next(
            package
            for package in stale_mathlib_input["packages"]
            if package["name"] == "mathlib"
        )
        mathlib["inputRev"] = "v0.0.0"
        write_json(lake_manifest_path, stale_mathlib_input)
        run(
            fixture,
            False,
            "check",
            "Lake mathlib pin differs from the canonical migration receipt",
        )
        write_json(lake_manifest_path, lake_manifest)

        stale_verity_input = copy.deepcopy(lake_manifest)
        verity = next(
            package
            for package in stale_verity_input["packages"]
            if package["name"] == "verity"
        )
        verity["inputRev"] = "0" * 40
        write_json(lake_manifest_path, stale_verity_input)
        run(
            fixture,
            False,
            "check",
            "Lake Verity pin differs from the canonical dependency pin",
        )
        write_json(lake_manifest_path, lake_manifest)

        coordinated_verity_manifest = copy.deepcopy(lake_manifest)
        verity = next(
            package
            for package in coordinated_verity_manifest["packages"]
            if package["name"] == "verity"
        )
        verity["url"] = "https://github.com/example/verity.git"
        verity["rev"] = "0" * 40
        verity["inputRev"] = "0" * 40
        coordinated_verity_lock = copy.deepcopy(baseline_lock)
        coordinated_verity_lock["pins"]["verity"] = {
            "repository": verity["url"],
            "commit": verity["rev"],
        }
        lakefile_path = fixture / "lakefile.lean"
        baseline_lakefile = lakefile_path.read_text(encoding="utf-8")
        lakefile_path.write_text(
            baseline_lakefile.replace(
                '"https://github.com/lfglabs-dev/verity.git"@'
                '"04729a9de9099e065dd09283e4f733a5fd4c2a16"',
                f'"{verity["url"]}"@"{verity["rev"]}"',
            ),
            encoding="utf-8",
        )
        coordinated_audit_manifest = json.loads(
            coordinated_manifest_path.read_text(encoding="utf-8")
        )
        coordinated_audit_manifest["source_revisions"]["verity"] = verity["rev"]
        write_json(lake_manifest_path, coordinated_verity_manifest)
        write_json(lock_path, coordinated_verity_lock)
        write_json(coordinated_manifest_path, coordinated_audit_manifest)
        run(
            fixture,
            False,
            "check",
            "Lake Verity pin differs from the canonical dependency pin",
        )
        write_json(lake_manifest_path, lake_manifest)
        write_json(lock_path, baseline_lock)
        lakefile_path.write_text(baseline_lakefile, encoding="utf-8")
        shutil.copy2(
            ROOT / "verity/targets/audit-manifest.json",
            coordinated_manifest_path,
        )

        stale_evmyul_input = copy.deepcopy(lake_manifest)
        evmyul = next(
            package
            for package in stale_evmyul_input["packages"]
            if package["name"] == "evmyul"
        )
        evmyul["inputRev"] = "0" * 40
        write_json(lake_manifest_path, stale_evmyul_input)
        run(
            fixture,
            False,
            "check",
            "Lake EVMYulLean pin differs from the canonical dependency pin",
        )
        write_json(lake_manifest_path, lake_manifest)

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
        schema_artifacts = (
            (
                guarantees_path,
                guarantees,
                "guarantee registry schema differs from the canonical version",
            ),
            (
                source_map_path,
                source_map,
                "source-map schema differs from the canonical version",
            ),
            (
                lock_path,
                baseline_lock,
                "artifacts lock schema differs from the canonical version",
            ),
        )
        for path, artifact, expected_error in schema_artifacts:
            schemas = (None, "incompatible-v999")
            if path == guarantees_path:
                schemas += ("lido-srv3-minimal-11-guarantees-v1",)
            for schema in schemas:
                malformed_schema = copy.deepcopy(artifact)
                if schema is None:
                    del malformed_schema["schema"]
                else:
                    malformed_schema["schema"] = schema
                write_json(path, malformed_schema)
                run(fixture, False, "generate", expected_error)
                run(fixture, False, "check", expected_error)
            write_json(path, artifact)

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
        for schema in (None, "srv3-audit-manifest-v999"):
            malformed_schema = copy.deepcopy(audit_manifest)
            if schema is None:
                del malformed_schema["schema"]
            else:
                malformed_schema["schema"] = schema
            write_json(audit_manifest_path, malformed_schema)
            run(
                fixture,
                False,
                "generate",
                "audit manifest schema differs from the canonical version",
            )
        for layer, record in audit_manifest["layers"].items():
            for field in record:
                missing_field = copy.deepcopy(audit_manifest)
                del missing_field["layers"][layer][field]
                write_json(audit_manifest_path, missing_field)
                run(
                    fixture,
                    False,
                    "generate",
                    "audit manifest layers differ from the canonical trust records",
                )
                mutated_field = copy.deepcopy(audit_manifest)
                if field == "modules":
                    mutated_field["layers"][layer][field].append(
                        "LidoSRv3.Audit.DoesNotExist"
                    )
                else:
                    mutated_field["layers"][layer][field] = (
                        "AUDIT-CERT production correspondence"
                    )
                write_json(audit_manifest_path, mutated_field)
                run(
                    fixture,
                    False,
                    "generate",
                    "audit manifest layers differ from the canonical trust records",
                )
        for layer in audit_manifest["layers"]:
            missing_layer = copy.deepcopy(audit_manifest)
            del missing_layer["layers"][layer]
            write_json(audit_manifest_path, missing_layer)
            run(
                fixture,
                False,
                "generate",
                "audit manifest layers differ from the canonical trust records",
            )
        for proof_baseline in (None, "0" * 40):
            malformed_baseline = copy.deepcopy(audit_manifest)
            if proof_baseline is None:
                del malformed_baseline["proof_baseline"]
            else:
                malformed_baseline["proof_baseline"] = proof_baseline
            write_json(audit_manifest_path, malformed_baseline)
            run(
                fixture,
                False,
                "generate",
                "audit manifest proof baseline differs from the canonical commit",
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

        missing_eugene = copy.deepcopy(guarantees)
        missing_eugene["guarantees"] = [
            row for row in missing_eugene["guarantees"]
            if row["id"] != "P-ALLOC-1.eugene-bound"
        ]
        write_json(guarantees_path, missing_eugene)
        run(
            fixture,
            False,
            "generate",
            "guarantees must contain the exact ordered canonical IDs plus subordinate evidence",
        )
        write_json(guarantees_path, guarantees)

        promoted_eugene = copy.deepcopy(guarantees)
        eugene = next(
            row for row in promoted_eugene["guarantees"]
            if row["id"] == "P-ALLOC-1.eugene-bound"
        )
        del eugene["parent_id"]
        write_json(guarantees_path, promoted_eugene)
        run(
            fixture,
            False,
            "generate",
            "P-ALLOC-1.eugene-bound must remain subordinate to P-ALLOC-1",
        )
        write_json(guarantees_path, guarantees)

        wrong_eugene_parent = copy.deepcopy(guarantees)
        eugene = next(
            row for row in wrong_eugene_parent["guarantees"]
            if row["id"] == "P-ALLOC-1.eugene-bound"
        )
        eugene["parent_id"] = "P-ALLOC-2"
        write_json(guarantees_path, wrong_eugene_parent)
        run(
            fixture,
            False,
            "generate",
            "P-ALLOC-1.eugene-bound must remain subordinate to P-ALLOC-1",
        )
        write_json(guarantees_path, guarantees)

        stale_alloc2_gate = copy.deepcopy(guarantees)
        stale_alloc2_gate["guarantees"][1]["next_gate"] = (
            "Connect checked quantities to independently verified pinned source spans."
        )
        write_json(guarantees_path, stale_alloc2_gate)
        run(
            fixture,
            False,
            "generate",
            "P-ALLOC-2: next gate differs from canonical roadmap",
        )
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

        # P-ACCOUNT-1 closes MODEL -> SOURCE -> VERITY_TX; a downgrade is stale.
        account_source_downgrade = copy.deepcopy(guarantees)
        account_source_downgrade["guarantees"][4]["statuses"]["source"] = "OPEN"
        write_json(guarantees_path, account_source_downgrade)
        run(fixture, False, "generate", "P-ACCOUNT-1: assurance statuses differ")
        write_json(guarantees_path, guarantees)

        unbacked = copy.deepcopy(guarantees)
        unbacked["guarantees"][5]["theorem_planes"] = ["source", "tx"]
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

        # P-DEPOSIT-1 closed its source plane in this campaign; the source-plane
        # claim, its evidence plane, and the evm plane it deliberately did not
        # close all have to stay pinned to the theorem that actually exists.
        deposit_source_downgrade = copy.deepcopy(guarantees)
        deposit_source_downgrade["guarantees"][2]["statuses"]["source"] = "OPEN"
        write_json(guarantees_path, deposit_source_downgrade)
        run(
            fixture,
            False,
            "generate",
            "P-DEPOSIT-1: assurance statuses differ from canonical claims",
        )
        write_json(guarantees_path, guarantees)

        deposit_evm_overclaim = copy.deepcopy(guarantees)
        deposit_evm_overclaim["guarantees"][2]["statuses"]["evm"] = "LEAN_CHECKED"
        write_json(guarantees_path, deposit_evm_overclaim)
        run(
            fixture,
            False,
            "generate",
            "P-DEPOSIT-1: evm status LEAN_CHECKED requires theorem evidence "
            "for that plane",
        )
        write_json(guarantees_path, guarantees)

        deposit_evm_plane_overclaim = copy.deepcopy(guarantees)
        deposit_evm_plane_overclaim["guarantees"][2]["statuses"]["evm"] = "LEAN_CHECKED"
        deposit_evm_plane_overclaim["guarantees"][2]["theorem_planes"] = [
            "model", "tx", "source", "evm",
        ]
        write_json(guarantees_path, deposit_evm_plane_overclaim)
        run(
            fixture,
            False,
            "generate",
            "P-DEPOSIT-1: theorem planes differ from canonical evidence",
        )
        write_json(guarantees_path, guarantees)

        deposit_unbacked_source_plane = copy.deepcopy(guarantees)
        deposit_unbacked_source_plane["guarantees"][2]["theorem_planes"] = ["model", "tx"]
        write_json(guarantees_path, deposit_unbacked_source_plane)
        run(
            fixture,
            False,
            "generate",
            "P-DEPOSIT-1: theorem planes differ from canonical evidence",
        )
        write_json(guarantees_path, guarantees)

        # P-TOPUP-1 closed its source plane in this campaign.  The
        # source claim must not be silently downgraded back to the pre-campaign
        # model-only row, the theorem must stay the top-up correspondence rather
        # than the allocation-ordering model fact it replaced, and the evm plane
        # tx and evm planes it deliberately did not close must stay open.
        topup_source_downgrade = copy.deepcopy(guarantees)
        topup_source_downgrade["guarantees"][3]["statuses"]["source"] = "OPEN"
        write_json(guarantees_path, topup_source_downgrade)
        run(
            fixture,
            False,
            "generate",
            "P-TOPUP-1: assurance statuses differ from canonical claims",
        )
        write_json(guarantees_path, guarantees)

        topup_tx_blocked = copy.deepcopy(guarantees)
        topup_tx_blocked["guarantees"][3]["statuses"]["tx"] = "BLOCKED"
        write_json(guarantees_path, topup_tx_blocked)
        run(
            fixture,
            False,
            "generate",
            "P-TOPUP-1: assurance statuses differ from canonical claims",
        )
        write_json(guarantees_path, guarantees)

        topup_tx_overclaim = copy.deepcopy(guarantees)
        topup_tx_overclaim["guarantees"][3]["statuses"]["tx"] = "LEAN_CHECKED"
        write_json(guarantees_path, topup_tx_overclaim)
        run(
            fixture,
            False,
            "generate",
            "P-TOPUP-1: tx status LEAN_CHECKED requires theorem evidence for that plane",
        )
        write_json(guarantees_path, guarantees)

        topup_evm_plane_overclaim = copy.deepcopy(guarantees)
        topup_evm_plane_overclaim["guarantees"][3]["statuses"]["evm"] = "LEAN_CHECKED"
        topup_evm_plane_overclaim["guarantees"][3]["theorem_planes"] = [
            "model", "tx", "source", "evm",
        ]
        write_json(guarantees_path, topup_evm_plane_overclaim)
        run(
            fixture,
            False,
            "generate",
            "P-TOPUP-1: theorem planes differ from canonical evidence",
        )
        write_json(guarantees_path, guarantees)

        topup_stale_theorem = copy.deepcopy(guarantees)
        topup_stale_theorem["guarantees"][3]["theorem"] = (
            "LidoSRv3.Audit.valid_result_preserves_router_order"
        )
        write_json(guarantees_path, topup_stale_theorem)
        run(
            fixture,
            False,
            "generate",
            "P-TOPUP-1: theorem differs from canonical evidence",
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
            "P-RESERVE-1: reproduction record differs from canonical evidence",
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
            assumptions = missing_link["guarantees"][index]["assumptions"]
            missing_link["guarantees"][index]["assumptions"] = (
                [] if assumptions else ["A-SOURCE-SHAPED"]
            )
            write_json(guarantees_path, missing_link)
            run(
                fixture,
                False,
                "generate",
                f"{guarantee['id']}: assumption links differ from canonical risks",
            )
        write_json(guarantees_path, guarantees)

        topup_dropped_nowrap = copy.deepcopy(guarantees)
        topup_dropped_nowrap["guarantees"][3]["assumptions"] = [
            row for row in topup_dropped_nowrap["guarantees"][3]["assumptions"]
            if row != "A-TOPUP-NOWRAP"
        ]
        write_json(guarantees_path, topup_dropped_nowrap)
        run(
            fixture,
            False,
            "generate",
            "P-TOPUP-1: assumption links differ from canonical risks",
        )
        write_json(guarantees_path, guarantees)

        for blocker in baseline_lock["unavailable"]:
            missing_blocker = copy.deepcopy(baseline_lock)
            del missing_blocker["unavailable"][blocker]
            write_json(lock_path, missing_blocker)
            run(fixture, False, "generate")
        write_json(lock_path, baseline_lock)

        pinned_sha = source_map["pinned_source"].rsplit("@", 1)[-1]
        valid_span = copy.deepcopy(source_map["targets"][0]["spans"][0])
        for missing_field in valid_span:
            malformed_span = copy.deepcopy(source_map)
            malformed_span["targets"][0] = {
                "id": source_map["targets"][0]["id"],
                "status": "MAPPED",
                "spans": [{key: value for key, value in valid_span.items()
                           if key != missing_field}],
            }
            write_json(source_map_path, malformed_span)
            run(
                fixture,
                False,
                "generate",
                "source span requires exact repository/SHA/path/function/lines/permalink",
            )

        short_sha = copy.deepcopy(source_map)
        short_sha["targets"][0]["spans"][0]["source_sha"] = pinned_sha[:12]
        write_json(source_map_path, short_sha)
        run(
            fixture,
            False,
            "generate",
            "source span SHA must equal the pinned source SHA",
        )

        mutable_permalink = copy.deepcopy(source_map)
        mutable_permalink["targets"][0]["spans"][0]["permalink"] = (
            "https://github.com/lidofinance/core/blob/master/"
            "contracts/0.8.25/sr/StakingRouter.sol#L929-L936"
        )
        write_json(source_map_path, mutable_permalink)
        run(
            fixture,
            False,
            "generate",
            "source span requires an immutable exact permalink",
        )

        wrong_function = copy.deepcopy(source_map)
        wrong_function["targets"][0]["spans"][0]["function"] = "deposit"
        write_json(source_map_path, wrong_function)
        run(
            fixture,
            False,
            "generate",
            "source span is not a verified semantic anchor",
        )

        wrong_span = copy.deepcopy(source_map)
        wrong_span["targets"][0]["spans"][0]["start_line"] = 930
        wrong_span["targets"][0]["spans"][0]["permalink"] = (
            "https://github.com/lidofinance/core/blob/"
            f"{pinned_sha}/contracts/0.8.25/sr/StakingRouter.sol#L930-L936"
        )
        write_json(source_map_path, wrong_span)
        run(
            fixture,
            False,
            "generate",
            "source span is not a verified semantic anchor",
        )

        unrelated_anchor = copy.deepcopy(source_map)
        unrelated_anchor["targets"][0]["spans"][0] = copy.deepcopy(
            source_map["targets"][1]["spans"][0]
        )
        write_json(source_map_path, unrelated_anchor)
        run(
            fixture,
            False,
            "generate",
            "source span is not a verified semantic anchor",
        )

        unrelated_accounting_coverage = copy.deepcopy(source_map)
        unrelated_accounting_coverage["targets"][4]["spans"] = [
            span for span in unrelated_accounting_coverage["targets"][4]["spans"]
            if span["function"] != "_handleConsensusReportData"
        ]
        write_json(source_map_path, unrelated_accounting_coverage)
        run(
            fixture,
            False,
            "generate",
            "P-ACCOUNT-1: source spans differ from verified semantic anchors",
        )

        missing_accounting_constant = copy.deepcopy(source_map)
        missing_accounting_constant["targets"][4]["spans"] = [
            span for span in missing_accounting_constant["targets"][4]["spans"]
            if span["function"] != "MAX_VALUE_GWEI"
        ]
        write_json(source_map_path, missing_accounting_constant)
        run(
            fixture,
            False,
            "generate",
            "P-ACCOUNT-1: source spans differ from verified semantic anchors",
        )

        downgraded_verified_target = copy.deepcopy(source_map)
        downgraded_verified_target["targets"][0] = {
            "id": source_map["targets"][0]["id"],
            "status": "UNMAPPED",
            "spans": [],
            "blocker": "Deliberate downgrade fixture.",
        }
        write_json(source_map_path, downgraded_verified_target)
        run(
            fixture,
            False,
            "generate",
            "verified source target must remain MAPPED",
        )

        duplicate_span = copy.deepcopy(source_map)
        duplicate_span["targets"][0]["spans"].append(copy.deepcopy(valid_span))
        write_json(source_map_path, duplicate_span)
        run(
            fixture,
            False,
            "generate",
            "duplicate source spans are forbidden",
        )

        undeclared_target_field = copy.deepcopy(source_map)
        undeclared_target_field["targets"][0]["audit_cert"] = True
        write_json(source_map_path, undeclared_target_field)
        run(
            fixture,
            False,
            "generate",
            "MAPPED source row requires exact id/status/spans fields",
        )

        undeclared_source_map_field = copy.deepcopy(source_map)
        undeclared_source_map_field["audit_cert"] = True
        write_json(source_map_path, undeclared_source_map_field)
        run(
            fixture,
            False,
            "generate",
            "source-map requires exact schema/pinned_source/policy/scope/"
            "accepted_risks/ssz_claim/targets fields",
        )

        unmapped_with_claim = copy.deepcopy(source_map)
        unmapped_with_claim["targets"][0]["status"] = "UNMAPPED"
        unmapped_with_claim["targets"][0]["blocker"] = "Deliberate fixture."
        write_json(source_map_path, unmapped_with_claim)
        run(
            fixture,
            False,
            "generate",
            "verified source target must remain MAPPED",
        )
        write_json(source_map_path, source_map)

        # The four P-DEPOSIT-1 spans are the evidence its LEAN_CHECKED source
        # plane rests on: unmapping or thinning them must fail the gate.
        deposit_unmapped = copy.deepcopy(source_map)
        deposit_unmapped["targets"][2] = {
            "id": "P-DEPOSIT-1",
            "status": "UNMAPPED",
            "spans": [],
            "blocker": "Deliberate unmapping fixture.",
        }
        write_json(source_map_path, deposit_unmapped)
        run(
            fixture,
            False,
            "generate",
            "P-DEPOSIT-1: verified source target must remain MAPPED",
        )
        write_json(source_map_path, source_map)

        deposit_dropped_span = copy.deepcopy(source_map)
        deposit_dropped_span["targets"][2]["spans"].pop()
        write_json(source_map_path, deposit_dropped_span)
        run(
            fixture,
            False,
            "generate",
            "P-DEPOSIT-1: source spans differ from verified semantic anchors",
        )
        write_json(source_map_path, source_map)

        deposit_shrunk_span = copy.deepcopy(source_map)
        deposit_shrunk_span["targets"][2]["spans"][0]["end_line"] = 996
        deposit_shrunk_span["targets"][2]["spans"][0]["permalink"] = (
            "https://github.com/lidofinance/core/blob/"
            f"{pinned_sha}/contracts/0.8.25/sr/StakingRouter.sol#L942-L996"
        )
        write_json(source_map_path, deposit_shrunk_span)
        run(
            fixture,
            False,
            "generate",
            "P-DEPOSIT-1: source span is not a verified semantic anchor",
        )
        write_json(source_map_path, source_map)

        # The five P-TOPUP-1 spans are the evidence its LEAN_CHECKED source
        # plane rests on.  The Lido-side pull span in particular is easy to drop
        # because the router span alone reads as self-contained.
        topup_unmapped = copy.deepcopy(source_map)
        topup_unmapped["targets"][3] = {
            "id": "P-TOPUP-1",
            "status": "UNMAPPED",
            "spans": [],
            "blocker": "Deliberate unmapping fixture.",
        }
        write_json(source_map_path, topup_unmapped)
        run(
            fixture,
            False,
            "generate",
            "P-TOPUP-1: verified source target must remain MAPPED",
        )
        write_json(source_map_path, source_map)

        topup_dropped_span = copy.deepcopy(source_map)
        topup_dropped_span["targets"][3]["spans"].pop()
        write_json(source_map_path, topup_dropped_span)
        run(
            fixture,
            False,
            "generate",
            "P-TOPUP-1: source spans differ from verified semantic anchors",
        )
        write_json(source_map_path, source_map)

        for helper in ("_checkAppAuth", "_getTopUpGateway", "_getModuleState",
                       "_requireWCType2", "_requireModuleIdExists",
                       "PUBKEY_LENGTH", "PUBLIC_KEY_LENGTH", "MIN_DEPOSIT"):
            topup_dropped_helper = copy.deepcopy(source_map)
            topup_dropped_helper["targets"][3]["spans"] = [
                span for span in topup_dropped_helper["targets"][3]["spans"]
                if span["function"] != helper
            ]
            write_json(source_map_path, topup_dropped_helper)
            run(
                fixture,
                False,
                "generate",
                "P-TOPUP-1: source spans differ from verified semantic anchors",
            )
        write_json(source_map_path, source_map)

        topup_shrunk_span = copy.deepcopy(source_map)
        topup_shrunk_span["targets"][3]["spans"][0]["end_line"] = 756
        topup_shrunk_span["targets"][3]["spans"][0]["permalink"] = (
            "https://github.com/lidofinance/core/blob/"
            f"{pinned_sha}/contracts/0.8.25/sr/StakingRouter.sol#L679-L756"
        )
        write_json(source_map_path, topup_shrunk_span)
        run(
            fixture,
            False,
            "generate",
            "P-TOPUP-1: source span is not a verified semantic anchor",
        )
        write_json(source_map_path, source_map)

        # P-SSZ-1's source-plane claim relies on all three deposit-data-root
        # spans: the data-root chain, signature-root helper, and endian loop.
        for helper in ("_computeDepositDataRootWithAmount", "_computeSignatureRoot",
                       "_toLittleEndian64"):
            ssz_dropped_span = copy.deepcopy(source_map)
            ssz_target = next(
                target for target in ssz_dropped_span["targets"]
                if target["id"] == "P-SSZ-1"
            )
            ssz_target["spans"] = [
                span for span in ssz_target["spans"]
                if span["function"] != helper
            ]
            write_json(source_map_path, ssz_dropped_span)
            run(
                fixture,
                False,
                "generate",
                "P-SSZ-1: source spans differ from verified semantic anchors",
            )
        write_json(source_map_path, source_map)

        ssz_overclaim = copy.deepcopy(source_map)
        ssz_overclaim["ssz_claim"]["level"] = "FULL_SSZ"
        write_json(source_map_path, ssz_overclaim)
        run(
            fixture,
            False,
            "generate",
            "source-map SSZ claim exceeds the structural-only boundary",
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
        "assumption records/links, authority, full manifest layer/theorem ledgers, "
        "all metadata schemas, proof baseline/revisions, "
        "canonical Lean toolchain and requested revisions, proof policy, "
        "source-map policy, reproduction evidence, "
        "strict source-span evidence, status vocabulary/plane/closure, "
        "P-DEPOSIT-1 source-plane downgrade/overclaim and span unmapping, "
        "P-TOPUP-1 source/tx-plane downgrade/overclaim, stale theorem "
        "and span unmapping, P-TOPUP-1 transitive-helper span, "
        "pinned-constant declaration span and no-wrap assumption drops, "
        "P-ACCOUNT-1 source/tx downgrade, transitive-helper and "
        "MAX_VALUE_GWEI declaration span drops, "
        "P-SSZ-1 deposit-data-root span drops, "
        "P-ALLOC-1 Eugene subordinate-row omission/promotion/wrong-parent, "
        "stale view"
    )


if __name__ == "__main__":
    main()
