#!/usr/bin/env python3
"""Fail closed unless every axiom emitted by Trust is explicitly allowed."""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
TRUST = ROOT / "LidoSRv3/Audit/Trust.lean"
ALLOWLIST = ROOT / "audit/trust-native-decide-allowlist.txt"
NATIVE_AXIOM = re.compile(r"\b(?:[A-Za-z_][\w]*\.)+_native\.native_decide\.ax_\d+(?:_\d+)*\b")
# Lean emits either a bracketed dependency list or the equally authoritative
# "does not depend on any axioms" spelling.  Both are named reports; the
# latter means precisely the empty dependency set, not a missing report.
NAMED_AXIOM_REPORT = re.compile(
    r"^'([^']+)' (depends on axioms:\s*\[([^\]]*)\]|does not depend on any axioms)\s*$",
    re.MULTILINE,
)
TRUST_PRINT = re.compile(r"^\s*#print\s+axioms\s+(\S+)\s*$", re.MULTILINE)
PHASE3 = "LidoSRv3.Audit.Verity.AllocCapacityPhase3.consumed_summary_function_spec_compiles._native.native_decide.ax_1_1"
SSZ_DIGEST = "LidoSRv3.Audit.Verity.SszAbstractDigest.deposit_data_root_compiles._native.native_decide.ax_1_1"
CONSOLIDATION_FLOW = "LidoSRv3.Audit.Verity.ConsolidationAbstractFlowModel.forward_compiles._native.native_decide.ax_1_1"
PRODUCTION_NATIVE_AXIOMS = {PHASE3, SSZ_DIGEST, CONSOLIDATION_FLOW}
FOUNDATIONAL_AXIOMS = {"propext", "Classical.choice", "Quot.sound"}


def fail(message: str) -> None:
    raise SystemExit(f"trust-axiom check failed: {message}")


def disclosed_names() -> set[str]:
    if not ALLOWLIST.is_file():
        fail(f"missing allowlist: {ALLOWLIST.relative_to(ROOT)}")
    names = {
        line.strip() for line in ALLOWLIST.read_text(encoding="utf-8").splitlines()
        if line.strip() and not line.lstrip().startswith("#")
    }
    if not PRODUCTION_NATIVE_AXIOMS <= names:
        fail("allowlist omits a documented production native-decision dependency")
    if any(name not in PRODUCTION_NATIVE_AXIOMS and not name.startswith("LidoSRv3.Tests.") for name in names):
        fail("allowlist contains a non-test native-decision dependency")
    return names


def checked_theorems() -> set[str]:
    registry = ROOT / "audit/guarantees.yaml"
    if not registry.is_file():
        fail(f"missing registry: {registry.relative_to(ROOT)}")
    try:
        rows = json.loads(registry.read_text(encoding="utf-8"))["guarantees"]
        names = {
            plane["theorem"]
            for row in rows
            for plane in (row["abstract"], row["verity"])
            if plane["status"] == "CHECKED"
        }
    except (KeyError, TypeError, ValueError) as error:
        fail(f"invalid checked-theorem registry: {error}")
    if not names or not all(isinstance(name, str) and name.startswith("LidoSRv3.") for name in names):
        fail("checked-theorem registry is incomplete")
    return names


def trust_printed_theorems() -> set[str]:
    if not TRUST.is_file():
        fail(f"missing Trust source: {TRUST.relative_to(ROOT)}")
    return set(TRUST_PRINT.findall(TRUST.read_text(encoding="utf-8")))


def observed_axioms(output: str) -> tuple[set[str], list[tuple[str, set[str]]]]:
    named_reports = NAMED_AXIOM_REPORT.findall(output)
    if not named_reports:
        fail("Trust output contains no named axiom reports")
    # A dependency line without a parsed named report must not be silently
    # discarded.  This also fails closed if Lean's report syntax changes.
    dependency_lines = re.findall(r"^.*depends on axioms:.*$", output, re.MULTILINE)
    parsed_dependency_lines = [report for report in named_reports if report[1].startswith("depends on axioms:")]
    if len(dependency_lines) != len(parsed_dependency_lines):
        fail("Trust output contains an unnamed or malformed axiom report")
    reports: list[tuple[str, set[str]]] = []
    for name, _, rendered_axioms in named_reports:
        reports.append((name, {
            axiom.strip()
            for axiom in (rendered_axioms or "").split(",")
            if axiom.strip()
        }))
    return set().union(*(axioms for _, axioms in reports)), reports


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--trust-output", type=Path,
                        help="validate saved Trust output instead of invoking Lean")
    args = parser.parse_args()
    if args.trust_output:
        output = args.trust_output.read_text(encoding="utf-8")
    else:
        env = os.environ.copy()
        # Avoid recursive remote dispatch when the workspace supplies Lake via
        # a policy shim; this is the actual Trust command, not a cached log.
        env.setdefault("SANDBOXED_REMOTE_EXECUTION", "1")
        build = subprocess.run(
            ["lake", "build", "LidoSRv3.Audit.Trust"],
            cwd=ROOT, env=env, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
        )
        if build.returncode:
            sys.stderr.write(build.stdout)
            fail(f"Trust build exited {build.returncode}")
        result = subprocess.run(
            ["lake", "env", "lean", str(TRUST.relative_to(ROOT))],
            cwd=ROOT, env=env, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
        )
        if result.returncode:
            sys.stderr.write(result.stdout)
            fail(f"Trust command exited {result.returncode}")
        output = result.stdout
    registered = checked_theorems()
    printed = trust_printed_theorems()
    source_missing = sorted(registered - printed)
    if source_missing:
        fail("Trust omits #print axioms for registered CHECKED theorem(s): " + ", ".join(source_missing))
    observed, reports = observed_axioms(output)
    output_missing = sorted(registered - {name for name, _ in reports})
    if output_missing:
        fail("Trust output omits registered CHECKED theorem report(s): " + ", ".join(output_missing))
    disclosed = disclosed_names()
    allowed = FOUNDATIONAL_AXIOMS | disclosed
    for theorem, axioms in reports:
        unexpected = sorted(axioms - allowed)
        if unexpected:
            fail(f"{theorem} emits undisclosed axiom(s): " + ", ".join(unexpected))
    if observed != allowed:
        missing = sorted(allowed - observed)
        unexpected = sorted(observed - allowed)
        details = []
        if missing:
            details.append("allowed but not emitted: " + ", ".join(missing))
        if unexpected:
            details.append("emitted but undisclosed: " + ", ".join(unexpected))
        fail("; ".join(details))
    observed_native = set(NATIVE_AXIOM.findall(output))
    if observed_native != disclosed:
        fail("native-decision extraction disagrees with the complete axiom report")
    print(f"trust-axiom check ok: {len(observed)} exact axioms ({len(observed_native) - 1} test/mutant-only native-decision axioms + Phase-3 + foundations)")


if __name__ == "__main__":
    main()
