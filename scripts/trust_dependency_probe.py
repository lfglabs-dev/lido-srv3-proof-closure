"""Controlled Lean probe; imported project modules supply data, not probe syntax."""

import re


TRUST_DEPENDENCY_PROBE = r"""import Lean

private unsafe def trustDependenciesImpl (names : List Lean.Name) : IO Unit := do
  Lean.initSearchPath (← Lean.findSysroot)
  let mut rows : Std.HashMap Lean.Name (Lean.Expr × String × Array Lean.Name) := {}
  for modules in <<MODULE_GROUPS>> do
    Lean.enableInitializersExecution
    let env ← Lean.importModules modules {} (loadExts := true)
    -- Ownership comes from the compiled environment, not declaration spelling.
    let discovered := if <<DISCOVER>> then (env.constants.toList.filterMap fun (name, info) =>
      match info, env.getModuleIdxFor? name with
      | .thmInfo _, some idx =>
        let owner := toString env.header.moduleNames[idx.toNat]!
        if (owner == "LidoSRv3" || owner.startsWith "LidoSRv3.") &&
            !(owner.splitOn ".").contains "Tests" &&
            !(owner.splitOn ".").contains "Regression" then some name else none
      | _, _ => none)
      else []
    let selected := (names.filter env.contains ++ discovered).eraseDups
    let collect : Lean.CoreM (Array (Lean.Name × Lean.Expr × String × Array Lean.Name)) := do
      let mut found := #[]
      for name in selected do
        if let some info := (← Lean.getEnv).find? name then
          let kind := match info with
            | .thmInfo _ => "theorem"
            | .axiomInfo _ => "axiom"
            | .defnInfo _ => "definition"
            | .opaqueInfo _ => "opaque"
            | _ => "other"
          let axioms ← Lean.collectAxioms name
          found := found.push (name, info.type, kind, axioms.qsort Lean.Name.lt)
      return found
    let (found, _) ← collect.toIO
      { fileName := "<trust-dependency-probe>", fileMap := default } { env := env }
    for (name, type, kind, axioms) in found do
      if let some (previousType, previousKind, previousAxioms) := rows[name]? then
        unless previousType == type && previousKind == kind && previousAxioms == axioms do
          throw <| IO.userError s!"conflicting compiled declaration across trust environments: {name}"
      else
        rows := rows.insert name (type, kind, axioms)
  let missing := names.filter fun name => !rows.contains name
  for name in missing do
    IO.println s!"TAX\t{name}\tmissing\t"
  for (name, (_, kind, axioms)) in rows.toArray.qsort (fun a b => Lean.Name.lt a.1 b.1) do
    let rendered := String.intercalate "," (axioms.map toString).toList
    IO.println s!"TAX\t{name}\t{kind}\t{rendered}"
  IO.println s!"TAX-END\t{rows.size + missing.length}"

@[implemented_by trustDependenciesImpl]
private opaque trustDependencies (names : List Lean.Name) : IO Unit

#eval do
  let names := (← IO.FS.readFile "<<NAMES>>").splitOn "\n" |>.filter (· != "")
  trustDependencies (names.map String.toName)
"""

DEP_ROW = re.compile(r"^TAX\t([^\t\n]*)\t([^\t\n]*)\t([^\t\n]*)$", re.MULTILINE)
DEP_END = re.compile(r"^TAX-END\t(\d+)$", re.MULTILINE)


def dependency_rows(output, ordered, discover, fail):
    """Require complete, named dependency rows and the terminating count."""
    rows = {}
    for name, kind, rendered in DEP_ROW.findall(output):
        if name in rows:
            fail(f"trust-dependency probe reported {name} more than once")
        if kind == "missing":
            fail(f"Trust prints axioms for {name}, which does not exist in the built "
                 f"environment")
        rows[name] = {axiom for axiom in rendered.split(",") if axiom}
    counted = DEP_END.findall(output)
    if len(counted) != 1 or int(counted[0]) != len(rows) or (not discover and len(rows) != len(ordered)):
        fail("trust-dependency probe did not report on every printed theorem")
    unreported = sorted(set(ordered) - set(rows))
    if unreported:
        fail("trust-dependency probe reported nothing for: " + ", ".join(unreported))
    return rows


def collect_environment_dependencies(names, module, fixture, discover, modules, run_probe, fail):
    """Inspect every module; standalone CLI drivers may each define `main`.

    Partitioning never excludes a module or theorem. The Lean probe compares
    repeated declarations' exact compiled types, kinds and dependencies.
    """
    standalone = sorted(name for name in set(modules) if name.endswith("SourceEntry"))
    common = sorted(set(modules) - set(standalone))
    groups = ([common] if common else []) + [[name] for name in standalone]
    imports = "#[" + ", ".join(
        "#[" + ", ".join("{ module := `" + name + " }" for name in group) + "]"
        for group in groups) + "]"
    probe = (TRUST_DEPENDENCY_PROBE
             .replace("<<DISCOVER>>", "true" if discover else "false")
             .replace("<<MODULE_GROUPS>>", imports))
    ordered = sorted(names)
    output = run_probe(probe, "trust-dependency", module, ordered, fixture)
    return dependency_rows(output, ordered, discover, fail)
