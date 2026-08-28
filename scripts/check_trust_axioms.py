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
# Rows this checker's own dependency probe emits, one per disclosed theorem,
# plus a terminating count so a truncated probe fails closed.
DEP_ROW = re.compile(r"^TAX\t([^\t\n]*)\t([^\t\n]*)\t([^\t\n]*)$", re.MULTILINE)
DEP_END = re.compile(r"^TAX-END\t(\d+)$", re.MULTILINE)
# Trust's own stdout is not evidence of anything: `#print axioms T` can be
# wrapped in a block comment while `#eval IO.println "'T' does not depend on any
# axioms"` prints a report Lean never computed, and the resulting log is
# indistinguishable from an authentic one.  So the checker recomputes each
# printed theorem's dependencies itself, through the very API `#print axioms`
# uses (`Lean.collectAxioms`), in a process it controls, and confirms the log
# against that.  A fabricated line is then a disagreement, not a pass.
#
# The audited module is loaded as *data* and is never imported into the probe's
# syntactic scope.  Importing it would let it decide what the probe's own source
# means: a module may declare `macro "collectAxioms" ...`, and a macro matches a
# token sequence rather than a resolved name, so qualifying the call does not
# escape it -- `Lean.collectAxioms` and `_root_.Lean.collectAxioms` are just as
# interceptable as the bare spelling, and the substitute silently returns a
# filtered dependency set.  `Lean.importModules` gives the probe the audited
# environment without giving the audited code a say in how the probe elaborates,
# which removes the possibility instead of trying to out-spell it.
TRUST_DEPENDENCY_PROBE = r"""import Lean

private unsafe def trustDependenciesImpl (names : List Lean.Name) : IO Unit := do
  Lean.initSearchPath (← Lean.findSysroot)
  Lean.enableInitializersExecution
  let env ← Lean.importModules #[{ module := `<<MODULE>> }] {} (loadExts := true)
  let collect : Lean.CoreM Unit := do
    for name in names do
      match (← Lean.getEnv).find? name with
      | none => IO.println s!"TAX\t{name}\tmissing\t"
      | some info =>
        let kind := match info with
          | .thmInfo _ => "theorem"
          | .axiomInfo _ => "axiom"
          | .defnInfo _ => "definition"
          | .opaqueInfo _ => "opaque"
          | _ => "other"
        let axioms ← Lean.collectAxioms name
        let rendered :=
          String.intercalate "," ((axioms.qsort Lean.Name.lt).map toString).toList
        IO.println s!"TAX\t{name}\t{kind}\t{rendered}"
  let _ ← collect.toIO
    { fileName := "<trust-dependency-probe>", fileMap := default } { env := env }
  IO.println s!"TAX-END\t{names.length}"

@[implemented_by trustDependenciesImpl]
private opaque trustDependencies (names : List Lean.Name) : IO Unit

#eval do
  let names := (← IO.FS.readFile "<<NAMES>>").splitOn "\n" |>.filter (· != "")
  trustDependencies (names.map String.toName)
"""
# Rows this checker's own Lean probe emits, one per disclosed name, plus a
# terminating count so a truncated or partially-elaborated probe fails closed.
PROBE_ROW = re.compile(
    r"^NDP\t([^\t\n]*)\t([^\t\n]*)\t([^\t\n]*)\t([^\t\n]*)\t([^\t\n]*)\t([^\t\n]*)\t([^\t\n]*)$",
    re.MULTILINE,
)
PROBE_END = re.compile(r"^NDP-END\t(\d+)$", re.MULTILINE)
# Every field the environment records *about* a declaration is forgeable by the
# project code that declares it: a command elaborator may `addDecl` an
# `axiomDecl` under any name, give it any type, and `addDeclarationRanges` it
# onto any position, including a line that genuinely contains `native_decide`.
# So the probe does not ask who minted an axiom.  It re-establishes what the
# axiom asserts: a native-decision axiom says `e = true` for a closed `Bool`
# expression, and `evalExpr` compiles and runs that same `e` exactly as
# `native_decide` did.  An axiom whose own claim re-evaluates to `true` is worth
# precisely what a compiler-minted one is worth, whoever wrote it; one that does
# not is rejected no matter how convincing its recorded provenance looks.
#
# Like the dependency probe, this file imports only `Lean` and loads the audited
# module as data.  The re-evaluation below is exactly what a dishonest module
# would want to answer for: were it imported here, a `macro "Lean.Meta.evalExpr"`
# could return `true` for every claim and this whole check would attest to
# nothing.
NATIVE_PROVENANCE_PROBE = r"""import Lean

private unsafe def claimVerdictImpl (e : Lean.Expr) : Lean.MetaM String := do
  if e.hasFVar || e.hasMVar || e.hasLevelParam then return "open"
  try
    return if (← Lean.Meta.evalExpr Bool (Lean.mkConst ``Bool) e) then "true" else "false"
  catch _ => return "unevaluated"

@[implemented_by claimVerdictImpl]
private opaque claimVerdict (e : Lean.Expr) : Lean.MetaM String

private def nativeProvenanceRow (name : Lean.Name) : Lean.MetaM String := do
  let env ← Lean.getEnv
  let some info := env.find? name
    | return s!"NDP\t{name}\tmissing\t-\t-\t-\t-\t-"
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
  let srcLine := match (← Lean.findDeclarationRanges? name) with
    | some ranges => toString ranges.range.pos.line
    | none => "-"
  let verdict ← if shape == "eq-bool-true" then
      claimVerdict (type.getArg! 1)
    else pure "-"
  return s!"NDP\t{name}\t{kind}\t{safety}\t{shape}\t{srcModule}\t{srcLine}\t{verdict}"

private unsafe def nativeProvenanceImpl (names : List Lean.Name) : IO Unit := do
  Lean.initSearchPath (← Lean.findSysroot)
  Lean.enableInitializersExecution
  let env ← Lean.importModules #[{ module := `<<MODULE>> }] {} (loadExts := true)
  let rows : Lean.CoreM Unit := do
    for name in names do
      IO.println (← Lean.Meta.MetaM.run' (nativeProvenanceRow name))
  let _ ← rows.toIO
    { fileName := "<native-provenance-probe>", fileMap := default } { env := env }
  IO.println s!"NDP-END\t{names.length}"

@[implemented_by nativeProvenanceImpl]
private opaque nativeProvenance (names : List Lean.Name) : IO Unit

#eval do
  let names := (← IO.FS.readFile "<<NAMES>>").splitOn "\n" |>.filter (· != "")
  nativeProvenance (names.map String.toName)
"""
PHASE3 = "LidoSRv3.Audit.Verity.AllocCapacityPhase3.consumed_summary_function_spec_compiles._native.native_decide.ax_1_1"
SSZ_DIGEST = "LidoSRv3.Audit.Verity.SszAbstractDigest.deposit_data_root_compiles._native.native_decide.ax_1_1"
CONSOLIDATION_FLOW = "LidoSRv3.Audit.Verity.ConsolidationAbstractFlowModel.forward_compiles._native.native_decide.ax_1_1"
# Every production native-decision exception, each with the label the summary
# reports it under.  The set is derived from this map so a new exception cannot
# be recorded in one place and silently omitted from the audit summary in the
# other, which is how the SSZ digest and consolidation flow came to be counted
# as test evidence.
PRODUCTION_NATIVE_LABELS = {
    PHASE3: "Phase-3 capacity",
    SSZ_DIGEST: "SSZ digest",
    CONSOLIDATION_FLOW: "consolidation flow",
}
PRODUCTION_NATIVE_AXIOMS = set(PRODUCTION_NATIVE_LABELS)
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
    """`source path -> native_decide line numbers`, the reviewed tactic inventory.

    This is a lexical inventory of lines carrying the token, not evidence that a
    declaration recorded at one of them was elaborated by `native_decide`; an
    arbitrary declaration can be registered at a matching line.  It is used only
    to keep disclosed names inside the inventory `check_proof_escapes.py` pins by
    count and digest, so a new tactic use requires re-baselining that guard.
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


def lean_probe_output(template: str, label: str, module: str, names: list[str],
                      fixture: Path | None) -> str:
    """Run one of this checker's own Lean probes over `names` in a fresh process."""
    if not LEAN_MODULE.fullmatch(module):
        fail(f"refusing to probe a malformed module name: {module}")
    with tempfile.TemporaryDirectory() as scratch:
        names_file = Path(scratch) / "names.txt"
        names_file.write_text("\n".join(names) + "\n", encoding="utf-8")
        probe = Path(scratch) / f"{label}_probe.lean"
        probe.write_text(
            template
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
            fail(f"{label} probe exited {result.returncode}")
        return result.stdout


def verify_native_provenance(names: list[str], output: str, sites: dict[str, set[int]]) -> None:
    """Require every disclosed name to assert a claim that re-evaluates to `true`.

    Nothing the environment records *about* a declaration is evidence of who
    created it.  A project command elaborator can `addDecl` an `axiomDecl` under
    an assembled generated name, give it the `e = true` reflection type, and
    `addDeclarationRanges` it onto a line that really does contain
    `native_decide`; every recorded field then matches while the compiler minted
    nothing.  The decisive check is therefore not provenance but the claim
    itself: `e` is compiled and run, and the axiom is accepted only if it
    evaluates to `true`, which is exactly the evidence `native_decide` relies on.
    An axiom that passes is sound whoever declared it, and one that fails is
    rejected however authentic its recorded origin looks.

    The kind, type, module and declaration-site conditions are retained as
    containment, not as provenance: they keep a disclosed name inside the
    reviewed `native_decide` inventory so a new use cannot appear unnoticed.
    """
    rows: dict[str, tuple[str, ...]] = {}
    for name, kind, safety, shape, module, line, verdict in PROBE_ROW.findall(output):
        if name in rows:
            fail(f"native-decision claim probe reported {name} more than once")
        rows[name] = (kind, safety, shape, module, line, verdict)
    counted = PROBE_END.findall(output)
    if len(counted) != 1 or int(counted[0]) != len(names):
        fail("native-decision claim probe did not report on every disclosed name")
    unreported = sorted(set(names) - set(rows))
    if unreported:
        fail("native-decision claims are unreported for: " + ", ".join(unreported))
    for name in sorted(names):
        kind, safety, shape, module, line, verdict = rows[name]
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
            fail(f"{name} is not recorded at a reviewed native_decide site: "
                 f"Lean reports it at {source}:{line}")
        if verdict == "open":
            fail(f"{name} does not assert a closed Bool claim, so no evaluation can "
                 f"stand in for the decision native_decide would have made")
        if verdict == "unevaluated":
            fail(f"{name} asserts a claim the compiler could not evaluate, so it is "
                 f"not the reflection of a completed native decision")
        if verdict != "true":
            fail(f"{name} asserts a Bool claim that evaluates to {verdict}, so no "
                 f"native decision could have produced it")


def check_native_provenance(names: list[str], module: str, fixture: Path | None) -> None:
    ordered = sorted(names)
    sites = native_decide_sites(ROOT if fixture is None else fixture, pinned=fixture is None)
    output = lean_probe_output(NATIVE_PROVENANCE_PROBE, "native-decision claim",
                               module, ordered, fixture)
    verify_native_provenance(ordered, output, sites)


def environment_dependencies(names: list[str], module: str,
                             fixture: Path | None) -> dict[str, set[str]]:
    """Recompute each named theorem's axiom dependencies from the built environment.

    This is the checker's own answer, obtained through `Lean.collectAxioms` --
    the same call `#print axioms` makes -- in a process this script spawns and
    hands the name list to.  Nothing here reads Trust's source or its log, so a
    commented-out command or a fabricated `IO.println` cannot influence it, and
    the probe never imports the audited module, so nothing the module declares
    can influence how that call is elaborated either.
    """
    ordered = sorted(names)
    output = lean_probe_output(TRUST_DEPENDENCY_PROBE, "trust-dependency",
                               module, ordered, fixture)
    rows: dict[str, set[str]] = {}
    for name, kind, rendered in DEP_ROW.findall(output):
        if name in rows:
            fail(f"trust-dependency probe reported {name} more than once")
        if kind == "missing":
            fail(f"Trust prints axioms for {name}, which does not exist in the built "
                 f"environment")
        rows[name] = {axiom for axiom in rendered.split(",") if axiom}
    counted = DEP_END.findall(output)
    if len(counted) != 1 or int(counted[0]) != len(ordered):
        fail("trust-dependency probe did not report on every printed theorem")
    unreported = sorted(set(ordered) - set(rows))
    if unreported:
        fail("trust-dependency probe reported nothing for: " + ", ".join(unreported))
    return rows


def confirm_reported_dependencies(reports: list[tuple[str, set[str]]],
                                  computed: dict[str, set[str]]) -> None:
    """Require Trust's log to say exactly what the environment says.

    Trust's log is a convenience for readers, not evidence.  Any theorem it
    reports on must be one Trust actually prints for, and the dependency set it
    shows must equal the set this checker recomputed; either way round, a
    disagreement means the log describes something other than the code.
    """
    reported = {name for name, _ in reports}
    fabricated = sorted(reported - set(computed))
    if fabricated:
        fail("Trust output reports on theorem(s) no active #print axioms command "
             "requests, so the report was not produced by Trust: " + ", ".join(fabricated))
    silent = sorted(set(computed) - reported)
    if silent:
        fail("Trust output omits report(s) for printed theorem(s): " + ", ".join(silent))
    for name, axioms in sorted(reports):
        if axioms != computed[name]:
            missing = sorted(computed[name] - axioms)
            extra = sorted(axioms - computed[name])
            details = []
            if missing:
                details.append("hides " + ", ".join(missing))
            if extra:
                details.append("invents " + ", ".join(extra))
            fail(f"Trust output disagrees with {name}'s actual dependencies: "
                 + "; ".join(details))


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
    """Theorems Trust *actually* prints axioms for, ignoring inert command text.

    A `#print axioms T` line reads the same whether it is elaborated or sitting
    inside a `/- -/` block, so matching raw source would let a theorem be
    disclosed by commented-out text alone.  Comments and string literals are
    blanked first, exactly as the proof-escape scanner does, so only commands
    Lean will run count as disclosure.
    """
    if not TRUST.is_file():
        fail(f"missing Trust source: {TRUST.relative_to(ROOT)}")
    sys.path.insert(0, str(Path(__file__).resolve().parent))
    import check_proof_escapes

    active = check_proof_escapes.strip_comments_and_strings(
        TRUST.read_text(encoding="utf-8"))
    return set(TRUST_PRINT.findall(active))


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
                        help="verify native-decision claims only, against modules "
                             "compiled into this directory instead of the project build")
    parser.add_argument("--provenance-module", default="LidoSRv3.Audit.Trust",
                        help="module the provenance probe imports")
    parser.add_argument("--provenance-names", type=Path,
                        help="names to verify provenance for (default: the disclosure allowlist)")
    parser.add_argument("--dependency-fixture", type=Path,
                        help="confirm --trust-output against modules compiled into this "
                             "directory instead of the project build")
    parser.add_argument("--dependency-names", type=Path,
                        help="printed theorems to confirm dependencies for")
    args = parser.parse_args()
    if args.dependency_fixture or args.dependency_names:
        if not (args.trust_output and args.dependency_names):
            fail("confirming dependencies needs both --trust-output and --dependency-names")
        names = [
            line.strip()
            for line in args.dependency_names.read_text(encoding="utf-8").splitlines()
            if line.strip() and not line.lstrip().startswith("#")
        ]
        _, reports = observed_axioms(args.trust_output.read_text(encoding="utf-8"))
        computed = environment_dependencies(names, args.provenance_module,
                                            args.dependency_fixture)
        confirm_reported_dependencies(reports, computed)
        print(f"trust dependencies ok: {len(computed)} reports confirmed against the "
              f"built environment")
        return
    if args.provenance_fixture or args.provenance_names:
        names = (disclosed_names() if args.provenance_names is None else {
            line.strip()
            for line in args.provenance_names.read_text(encoding="utf-8").splitlines()
            if line.strip() and not line.lstrip().startswith("#")
        })
        check_native_provenance(sorted(names), args.provenance_module, args.provenance_fixture)
        print(f"native-decision claims ok: {len(names)} re-evaluated axioms")
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
    # Trust's log has said nothing verifiable so far: every line in it is just
    # text some command printed.  Recompute what each printed theorem really
    # depends on and require the log to match, so the axioms checked below are
    # the environment's and not the log's.  Saved-output mode has no environment
    # to consult and therefore certifies a report, not a build.
    if not args.trust_output:
        computed = environment_dependencies(sorted(printed), args.provenance_module, None)
        confirm_reported_dependencies(reports, computed)
        reports = sorted(computed.items())
        observed = set().union(*computed.values())
    # Provenance precedes disclosure: a native-decision name is only credible
    # as a Lean-generated dependency if no project source declared it.
    reject_source_declared_native_names()
    disclosed = disclosed_names()
    # ...and neither that lexical guard nor any recorded declaration metadata is
    # evidence of who minted a name, so each disclosed axiom's own Bool claim is
    # re-evaluated by the compiler.  Saved-output mode validates a report, not an
    # environment, and cannot reach the declarations.
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
    # Only the recorded production exceptions are production evidence; every
    # other disclosed native-decision axiom is test/mutant-only.  Subtracting a
    # single name would bury the exceptions this summary exists to surface.
    production = sorted(PRODUCTION_NATIVE_AXIOMS & observed_native)
    test_only = observed_native - PRODUCTION_NATIVE_AXIOMS
    exceptions = ", ".join(PRODUCTION_NATIVE_LABELS[name] for name in production)
    claims = "report-only" if args.trust_output else "re-evaluated"
    source = "saved report" if args.trust_output else "recomputed from the built environment"
    print(f"trust-axiom check ok: {len(observed)} exact axioms "
          f"({len(test_only)} test/mutant-only native-decision axioms + "
          f"{len(production)} production exceptions ({exceptions}) + foundations); "
          f"dependencies {source}; native-decision claims {claims}")


if __name__ == "__main__":
    main()
