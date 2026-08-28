#!/usr/bin/env python3
"""Fail closed unless every axiom emitted by Trust is explicitly allowed."""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
TRUST = ROOT / "LidoSRv3/Audit/Trust.lean"
ALLOWLIST = ROOT / "audit/trust-native-decide-allowlist.txt"
NATIVE_AXIOM = re.compile(r"\b(?:[A-Za-z_][\w]*\.)+_native\.native_decide\.ax_\d+(?:_\d+)*\b")
# `_native` is the namespace segment Lean's compiler mints native-decision
# axioms under; every name NATIVE_AXIOM can match contains it.  Only Lean may
# introduce it, so its presence in a project source means a declaration is
# wearing generated spelling without generated provenance.
RESERVED_NATIVE_SEGMENT = re.compile(r"\b_native\b")
# Lean emits either a bracketed dependency list or the equally authoritative
# "does not depend on any axioms" spelling.  Both are named reports; the
# latter means precisely the empty dependency set, not a missing report.
NAMED_AXIOM_REPORT = re.compile(
    r"^'([^']+)' (depends on axioms:\s*\[([^\]]*)\]|does not depend on any axioms)\s*$",
    re.MULTILINE,
)
TRUST_PRINT = re.compile(r"^\s*#print\s+axioms\s+(\S+)\s*$", re.MULTILINE)
LEAN_MODULE = re.compile(r"[A-Za-z_][\w']*(?:\.[A-Za-z_][\w']*)*")
# Rows this checker's own Lean probe emits, one per disclosed name, plus a
# terminating count so a truncated or partially-elaborated probe fails closed.
PROBE_ROW = re.compile(
    r"^NDP\t([^\t\n]*)\t([^\t\n]*)\t([^\t\n]*)\t([^\t\n]*)\t([^\t\n]*)\t([^\t\n]*)$",
    re.MULTILINE,
)
PROBE_END = re.compile(r"^NDP-END\t(\d+)$", re.MULTILINE)
# `Lean.Meta.nativeEqTrue` — the sole minter of `_native.<tactic>.ax_*` axioms —
# adds `Declaration.axiomDecl` whose type is `mkApp3 (Eq) Bool e Bool.true` and
# then calls `addDeclarationRangesFromSyntax` with the deciding tactic's own
# syntax ref.  Both facts are recorded in the environment, so an axiom's kind,
# type shape, module and declaration line are compiler-written provenance that
# a project source cannot restate for itself.
NATIVE_PROVENANCE_PROBE = r"""import <<MODULE>>
import Lean

open Lean Elab Command

private def nativeProvenanceRow (env : Environment) (name : Name) :
    CommandElabM String := do
  let some info := env.find? name
    | return s!"NDP\t{name}\tmissing\t-\t-\t-\t-"
  let kind := match info with
    | .axiomInfo _ => "axiom"
    | .thmInfo _ => "theorem"
    | .defnInfo _ => "definition"
    | .opaqueInfo _ => "opaque"
    | _ => "other"
  let safety := if info.isUnsafe then "unsafe" else "safe"
  let type := info.type
  let shape :=
    if type.isAppOfArity ``Eq 3 && (type.getArg! 0).isConstOf ``Bool
        && (type.getArg! 2).isConstOf ``Bool.true then "eq-bool-true" else "other"
  let srcModule := match env.getModuleIdxFor? name with
    | some idx => toString env.header.moduleNames[idx.toNat]!
    | none => "-"
  let srcLine := match (← findDeclarationRanges? name) with
    | some ranges => toString ranges.range.pos.line
    | none => "-"
  return s!"NDP\t{name}\t{kind}\t{safety}\t{shape}\t{srcModule}\t{srcLine}"

#eval show CommandElabM Unit from do
  let env ← getEnv
  let names := (← IO.FS.readFile "<<NAMES>>").splitOn "\n" |>.filter (· != "")
  for name in names do
    IO.println (← nativeProvenanceRow env name.toName)
  IO.println s!"NDP-END\t{names.length}"
"""
PHASE3 = "LidoSRv3.Audit.Verity.AllocCapacityPhase3.consumed_summary_function_spec_compiles._native.native_decide.ax_1_1"
SSZ_DIGEST = "LidoSRv3.Audit.Verity.SszAbstractDigest.deposit_data_root_compiles._native.native_decide.ax_1_1"
CONSOLIDATION_FLOW = "LidoSRv3.Audit.Verity.ConsolidationAbstractFlowModel.forward_compiles._native.native_decide.ax_1_1"
PRODUCTION_NATIVE_AXIOMS = {PHASE3, SSZ_DIGEST, CONSOLIDATION_FLOW}
FOUNDATIONAL_AXIOMS = {"propext", "Classical.choice", "Quot.sound"}


def fail(message: str) -> None:
    raise SystemExit(f"trust-axiom check failed: {message}")


def reject_source_declared_native_names() -> None:
    """Reject project declarations spelled like Lean-generated native axioms.

    Shape is forgeable: `opaque LidoSRv3.Tests.X.fake._native.native_decide.ax_1_1`
    satisfies NATIVE_AXIOM and the test-scope prefix while Lean generated
    nothing, and `opaque` is not one of the proof-escape scanner's forbidden
    spellings.  Disclosure may therefore only vouch for a native-decision name
    once no project source declares anything in the generated namespace.
    """
    sources = sorted(
        path for path in ROOT.rglob("*.lean")
        if ".lake" not in path.relative_to(ROOT).parts
    )
    if not sources:
        fail("no project Lean sources to verify native-decision provenance against")
    offenders: list[str] = []
    for path in sources:
        text = path.read_text(encoding="utf-8")
        if "_native" not in text:
            continue
        relative = path.relative_to(ROOT).as_posix()
        for number, line in enumerate(text.splitlines(), 1):
            if RESERVED_NATIVE_SEGMENT.search(line):
                offenders.append(f"{relative}:{number}: {line.strip()}")
    if offenders:
        fail("project source declares a name in Lean's generated native-decision "
             "namespace, which only the compiler may mint: " + "; ".join(offenders))


def native_decide_sites(root: Path, pinned: bool) -> dict[str, set[int]]:
    """`source path -> native_decide line numbers` Lean could have minted from.

    For the project tree this is the same inventory `check_proof_escapes.py`
    pins by count and digest, so widening it to legitimise a forged axiom's
    declaration line requires deliberately re-baselining that guard.
    """
    # Imported lazily: saved-output validation is self-contained, and its
    # negative regressions exercise this script on its own.
    sys.path.insert(0, str(Path(__file__).resolve().parent))
    import check_proof_escapes

    files = None if pinned else sorted(root.rglob("*.lean"))
    sites = check_proof_escapes.native_decide_sites(root, files)
    if pinned:
        digest = check_proof_escapes.native_decide_digest(sites)
        if (len(sites) != check_proof_escapes.NATIVE_DECIDE_COUNT
                or digest != check_proof_escapes.NATIVE_DECIDE_SHA256):
            fail("native_decide inventory differs from the recorded project baseline")
    index: dict[str, set[int]] = {}
    for path, line, _ in sites:
        index.setdefault(path, set()).add(line)
    return index


def native_provenance_output(module: str, names: list[str], fixture: Path | None) -> str:
    """Ask Lean itself what the disclosed names actually are in the environment."""
    if not LEAN_MODULE.fullmatch(module):
        fail(f"refusing to probe a malformed module name: {module}")
    with tempfile.TemporaryDirectory() as scratch:
        names_file = Path(scratch) / "names.txt"
        names_file.write_text("\n".join(names) + "\n", encoding="utf-8")
        probe = Path(scratch) / "native_provenance_probe.lean"
        probe.write_text(
            NATIVE_PROVENANCE_PROBE
            .replace("<<MODULE>>", module)
            .replace("<<NAMES>>", str(names_file).replace("\\", "\\\\").replace('"', '\\"')),
            encoding="utf-8",
        )
        env = os.environ.copy()
        env.setdefault("SANDBOXED_REMOTE_EXECUTION", "1")
        if fixture is None:
            command = ["lake", "env", "lean", str(probe)]
        else:
            command = ["lean", str(probe)]
            env["LEAN_PATH"] = os.pathsep.join(
                [str(fixture.resolve()), *filter(None, [env.get("LEAN_PATH")])])
        result = subprocess.run(
            command, cwd=ROOT, env=env, text=True,
            stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
        )
        if result.returncode:
            sys.stderr.write(result.stdout)
            fail(f"native-decision provenance probe exited {result.returncode}")
        return result.stdout


def verify_native_provenance(names: list[str], output: str, sites: dict[str, set[int]]) -> None:
    """Require every disclosed name to be a declaration `native_decide` minted.

    Rejecting project sources that spell `_native` is necessary but not
    sufficient: a project command elaborator can assemble the very same name
    from fragments and `addDecl` a `Declaration.axiomDecl` under it, leaving no
    literal token to scan for.  Disclosure is therefore vouched for by what the
    environment records about each name — that Lean holds it as a safe axiom,
    typed as the `e = true` reflection `nativeEqTrue` is the only source of, and
    minted at a `native_decide` site in the module its own name lives in.
    """
    rows: dict[str, tuple[str, ...]] = {}
    for name, kind, safety, shape, module, line in PROBE_ROW.findall(output):
        if name in rows:
            fail(f"native-decision provenance probe reported {name} more than once")
        rows[name] = (kind, safety, shape, module, line)
    counted = PROBE_END.findall(output)
    if len(counted) != 1 or int(counted[0]) != len(names):
        fail("native-decision provenance probe did not report on every disclosed name")
    unreported = sorted(set(names) - set(rows))
    if unreported:
        fail("native-decision provenance is unreported for: " + ", ".join(unreported))
    for name in sorted(names):
        kind, safety, shape, module, line = rows[name]
        if kind == "missing":
            fail(f"{name} is disclosed as a native-decision axiom but no such "
                 f"declaration exists in the built environment")
        if kind != "axiom" or safety != "safe":
            fail(f"{name} is disclosed as a native-decision axiom but Lean holds it as "
                 f"a {safety} {kind}")
        if shape != "eq-bool-true":
            fail(f"{name} does not carry the `_ = true` reflection type Lean mints "
                 f"native-decision axioms with, so native_decide did not generate it")
        if not LEAN_MODULE.fullmatch(module) or not name.startswith(module + "."):
            fail(f"{name} was minted by module {module}, which does not own its name")
        source = module.replace(".", "/") + ".lean"
        if not line.isdigit() or int(line) not in sites.get(source, set()):
            fail(f"{name} is not bound to a compiler-generated native_decide site: "
                 f"Lean minted it at {source}:{line}")


def check_native_provenance(names: list[str], module: str, fixture: Path | None) -> None:
    ordered = sorted(names)
    sites = native_decide_sites(ROOT if fixture is None else fixture, pinned=fixture is None)
    verify_native_provenance(ordered, native_provenance_output(module, ordered, fixture), sites)


def disclosed_names() -> set[str]:
    if not ALLOWLIST.is_file():
        fail(f"missing allowlist: {ALLOWLIST.relative_to(ROOT)}")
    names = {
        line.strip() for line in ALLOWLIST.read_text(encoding="utf-8").splitlines()
        if line.strip() and not line.lstrip().startswith("#")
    }
    # Disclosure may only document a native-decision axiom.  Without this the
    # allowed set below could be widened to an arbitrary project axiom, which
    # is exactly the foundations-only boundary this check exists to hold.
    unshaped = sorted(name for name in names if not NATIVE_AXIOM.fullmatch(name))
    if unshaped:
        fail("allowlist documents non-native axiom(s): " + ", ".join(unshaped))
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
    parser.add_argument("--provenance-fixture", type=Path,
                        help="verify native-decision provenance only, against modules "
                             "compiled into this directory instead of the project build")
    parser.add_argument("--provenance-module", default="LidoSRv3.Audit.Trust",
                        help="module the provenance probe imports")
    parser.add_argument("--provenance-names", type=Path,
                        help="names to verify provenance for (default: the disclosure allowlist)")
    args = parser.parse_args()
    if args.provenance_fixture or args.provenance_names:
        names = (disclosed_names() if args.provenance_names is None else {
            line.strip()
            for line in args.provenance_names.read_text(encoding="utf-8").splitlines()
            if line.strip() and not line.lstrip().startswith("#")
        })
        check_native_provenance(sorted(names), args.provenance_module, args.provenance_fixture)
        print(f"native-decision provenance ok: {len(names)} compiler-generated axioms")
        return
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
    # Provenance precedes disclosure: a native-decision name is only credible
    # as a Lean-generated dependency if no project source declared it.
    reject_source_declared_native_names()
    disclosed = disclosed_names()
    # ...and the lexical guard above only rules out the spellings a source can
    # be scanned for, so the disclosed names are additionally checked against
    # what Lean recorded when it generated them.  Saved-output mode validates a
    # report, not an environment, and cannot reach the declarations.
    if not args.trust_output:
        check_native_provenance(sorted(disclosed), args.provenance_module, None)
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
    provenance = "report-only" if args.trust_output else "compiler-generated"
    print(f"trust-axiom check ok: {len(observed)} exact axioms ({len(observed_native) - 1} test/mutant-only native-decision axioms + Phase-3 + foundations); native-decision provenance {provenance}")


if __name__ == "__main__":
    main()
