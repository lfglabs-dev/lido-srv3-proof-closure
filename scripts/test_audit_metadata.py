#!/usr/bin/env python3
"""Optimized fail-closed mutants for the v4 assurance contract."""

import copy
import json
import shutil
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def write(path, value):
    path.write_text(json.dumps(value, indent=2) + "\n", encoding="utf-8")


def invoke(root, ok, needle=None, command="generate"):
    result = subprocess.run(
        ["python3", "scripts/audit_metadata.py", command], cwd=root,
        text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
    )
    if (result.returncode == 0) != ok:
        raise AssertionError(f"unexpected rc={result.returncode}:\n{result.stdout}")
    if needle and needle not in result.stdout:
        raise AssertionError(f"missing {needle!r}:\n{result.stdout}")


def main():
    with tempfile.TemporaryDirectory(prefix="assurance-v4-mutants-") as tmp:
        fixture = Path(tmp)
        (fixture / "scripts").mkdir()
        (fixture / "audit").mkdir()
        (fixture / "verity/targets").mkdir(parents=True)
        shutil.copy2(ROOT / "scripts/audit_metadata.py", fixture / "scripts/audit_metadata.py")
        for name in ("guarantees.yaml", "assumptions.yaml", "artifacts.lock.json", "source-map.yaml"):
            shutil.copy2(ROOT / "audit" / name, fixture / "audit" / name)
        shutil.copy2(ROOT / "verity/targets/audit-manifest.json", fixture / "verity/targets/audit-manifest.json")

        gpath = fixture / "audit/guarantees.yaml"
        apath = fixture / "audit/assumptions.yaml"
        lpath = fixture / "audit/artifacts.lock.json"
        spath = fixture / "audit/source-map.yaml"
        mpath = fixture / "verity/targets/audit-manifest.json"
        guarantees = json.loads(gpath.read_text())
        assumptions = json.loads(apath.read_text())
        lock = json.loads(lpath.read_text())
        source = json.loads(spath.read_text())
        manifest = json.loads(mpath.read_text())

        invoke(fixture, True)
        invoke(fixture, True, command="check")

        mutants = []
        x = copy.deepcopy(guarantees); x["schema"] = "legacy-seven-planes"; mutants.append((gpath, x, "guarantee schema differs"))
        x = copy.deepcopy(guarantees); x["objective"] += " Prove EVM."; mutants.append((gpath, x, "project objective differs"))
        x = copy.deepcopy(guarantees); x["guarantees"][0], x["guarantees"][1] = x["guarantees"][1], x["guarantees"][0]; mutants.append((gpath, x, "IDs/order differ"))
        x = copy.deepcopy(guarantees); x["guarantees"][0]["abstract"]["theorem"] = None; mutants.append((gpath, x, "checked abstract lacks"))
        x = copy.deepcopy(guarantees); x["guarantees"][2]["verity"] = {"status":"CHECKED", "theorem":"LidoSRv3.Fake.nominal_tx"}; mutants.append((gpath, x, "canonical assurance claim differs"))
        x = copy.deepcopy(guarantees); x["guarantees"][8]["verity"]["theorem"] = "LidoSRv3.Fake.topup2"; mutants.append((gpath, x, "canonical assurance claim differs"))
        x = copy.deepcopy(guarantees); x["guarantees"][7]["verity"]["theorem"] = "LidoSRv3.Fake.address1"; mutants.append((gpath, x, "canonical assurance claim differs"))
        # Row index 2 (P-DEPOSIT-1) is classification NONE today; the mutant
        # adds an extra classification key to a NONE row. (Originally index 1,
        # stale since P-ALLOC-2 gained fidelity gaps and became
        # IMPLEMENTATION_PENDING.)
        x = copy.deepcopy(guarantees); x["guarantees"][2]["classification"]["consumer"] = "P-ALLOC-1"; mutants.append((gpath, x, "NONE may not hide extra claims"))
        x = copy.deepcopy(guarantees); x["guarantees"][6]["fidelity"]["missing"] = ["unclosed leg"]; x["guarantees"][6]["classification"] = {"kind":"PROPERTY_FALSE"}; mutants.append((gpath, x, "lacks counterexample"))
        x = copy.deepcopy(guarantees); x["guarantees"][6]["verity"] = {"status":"OPEN", "theorem":None}; x["guarantees"][6]["fidelity"]["missing"] = ["recursive dispatch absent"]; x["guarantees"][6]["classification"] = {"kind":"IMPLEMENTATION_PENDING", "work":"compose the ensemble"}; mutants.append((gpath, x, "canonical assurance claim differs"))
        x = copy.deepcopy(guarantees); x["guarantees"][3]["assumptions"].remove("A-TOPUP-NOWRAP"); mutants.append((gpath, x, "canonical assurance claim differs"))
        x = copy.deepcopy(guarantees); x["guarantees"][0]["next_gate"] = "Refine through generated Yul and EVM."; mutants.append((gpath, x, "canonical assurance detail differs"))
        x = copy.deepcopy(guarantees); x["guarantees"][0]["special_bindings"] = guarantees["guarantees"][10]["special_bindings"]; mutants.append((gpath, x, "bindings are SSZ-only"))
        x = copy.deepcopy(guarantees); x["guarantees"][10]["special_bindings"]["deployed_yul"]["scope"] = "entire runtime"; mutants.append((gpath, x, "targeted deployed-Yul binding differs"))
        x = copy.deepcopy(guarantees); x["guarantees"][5]["fidelity"]["missing"] = ["hidden gap"]; x["guarantees"][5]["classification"] = {"kind":"NONE"}; mutants.append((gpath, x, "NONE is reserved"))
        x = copy.deepcopy(guarantees); x["guarantees"][0]["reproduction"]["command"] = ""; mutants.append((gpath, x, "reproduction record is incomplete"))
        x = copy.deepcopy(guarantees); x["guarantees"][8]["summary"] = "Everything is proved."; mutants.append((gpath, x, "canonical assurance detail differs"))
        x = copy.deepcopy(guarantees); x["guarantees"][2]["roadmap_priority"] = "P3"; mutants.append((gpath, x, "roadmap priority differs"))

        for path, value, needle in mutants:
            write(path, value); invoke(fixture, False, needle); write(gpath, guarantees)

        x = copy.deepcopy(assumptions); x["schema"] = "v1"; write(apath, x); invoke(fixture, False, "assumption schema differs"); write(apath, assumptions)
        x = copy.deepcopy(assumptions); del x["assumptions"][0]["removal_path"]; write(apath, x); invoke(fixture, False, "assumption fields differ"); write(apath, assumptions)
        x = copy.deepcopy(assumptions); x["assumptions"][0]["severity"] = "UNKNOWN"; write(apath, x); invoke(fixture, False, "invalid severity"); write(apath, assumptions)
        x = copy.deepcopy(assumptions); x["assumptions"] = [a for a in x["assumptions"] if a["id"] != "A-SHA256-FFI"]; write(apath, x); invoke(fixture, False, "solc/SHA-256 trust boundaries"); write(apath, assumptions)

        x = copy.deepcopy(lock); x["pins"]["verity"]["commit"] = "0" * 40; write(lpath, x); invoke(fixture, False, "verity pin differs"); write(lpath, lock)
        x = copy.deepcopy(lock); x["pins"]["lean"]["toolchain"] = "latest"; write(lpath, x); invoke(fixture, False, "Lean toolchain pin differs"); write(lpath, lock)
        x = copy.deepcopy(lock); x["unavailable"]["canonical_eip7251_runtime"] = {"status":"MISSING", "blocked":True, "value":None}; write(lpath, x); invoke(fixture, False, "retired deployment-provenance blockers"); write(lpath, lock)
        x = copy.deepcopy(manifest); x["proof_policy"]["sorry"] = 1; write(mpath, x); invoke(fixture, False, "proof policy permits proof escapes"); write(mpath, manifest)
        x = copy.deepcopy(manifest); x["source_revisions"]["lido"] = "0" * 40; write(mpath, x); invoke(fixture, False, "manifest source revisions differ"); write(mpath, manifest)
        x = copy.deepcopy(source); x["pinned_source"] = "lidofinance/core@main"; write(spath, x); invoke(fixture, False, "source-map pin differs"); write(spath, source)
        x = copy.deepcopy(source); x["scope"]["general_yul_evm_deployment"] = "OPEN"; write(spath, x); invoke(fixture, False, "source-map assurance scope differs"); write(spath, source)
        x = copy.deepcopy(source); x["ssz_claim"]["deployed_yul_binding"] = "FULL_RUNTIME"; write(spath, x); invoke(fixture, False, "source-map SSZ boundary differs"); write(spath, source)
        x = copy.deepcopy(source); x["targets"][0]["spans"][0]["permalink"] = "https://github.com/lidofinance/core/blob/main/x"; write(spath, x); invoke(fixture, False, "permalink is not immutable/exact"); write(spath, source)
        x = copy.deepcopy(source); x["targets"][0]["spans"][0]["source_sha"] = "0" * 40; write(spath, x); invoke(fixture, False, "source span pin differs"); write(spath, source)

        invoke(fixture, True, command="generate")
        (fixture / "audit/STATUS.md").write_text("stale\n", encoding="utf-8")
        invoke(fixture, False, "STATUS.md is stale", command="check")

    print("optimized assurance-v4 mutants rejected: objective, canonical claims, classifications, assumptions, SSZ-only binding, pins, source spans, proof policy, and stale views")


if __name__ == "__main__":
    main()
