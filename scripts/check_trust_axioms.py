#!/usr/bin/env python3
"""Fail closed unless Trust's emitted native-decision boundary is disclosed."""

from __future__ import annotations

import argparse
import os
import re
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
TRUST = ROOT / "LidoSRv3/Audit/Trust.lean"
ALLOWLIST = ROOT / "audit/trust-native-decide-allowlist.txt"
NATIVE_AXIOM = re.compile(r"\b(?:[A-Za-z_][\w]*\.)+_native\.native_decide\.ax_\d+(?:_\d+)*\b")
PHASE3 = "LidoSRv3.Audit.Verity.AllocCapacityPhase3.consumed_summary_function_spec_compiles._native.native_decide.ax_1_1"


def fail(message: str) -> None:
    raise SystemExit(f"trust-axiom check failed: {message}")


def disclosed_names() -> set[str]:
    if not ALLOWLIST.is_file():
        fail(f"missing allowlist: {ALLOWLIST.relative_to(ROOT)}")
    names = {
        line.strip() for line in ALLOWLIST.read_text(encoding="utf-8").splitlines()
        if line.strip() and not line.lstrip().startswith("#")
    }
    if PHASE3 not in names:
        fail("allowlist omits the documented Phase-3 dependency")
    if any(name != PHASE3 and not name.startswith("LidoSRv3.Tests.") for name in names):
        fail("allowlist contains a non-test native-decision dependency")
    return names


def observed_names(output: str) -> set[str]:
    return set(NATIVE_AXIOM.findall(output))


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
    observed = observed_names(output)
    allowed = disclosed_names()
    if observed != allowed:
        missing = sorted(allowed - observed)
        unexpected = sorted(observed - allowed)
        details = []
        if missing:
            details.append("disclosed but not emitted: " + ", ".join(missing))
        if unexpected:
            details.append("emitted but undisclosed: " + ", ".join(unexpected))
        fail("; ".join(details))
    print(f"trust-axiom check ok: {len(observed)} exact native-decision axioms ({len(observed) - 1} test/mutant-only + Phase-3)")


if __name__ == "__main__":
    main()
