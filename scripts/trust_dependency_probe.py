"""Controlled Lean probe; imported project modules supply data, not probe syntax."""

TRUST_DEPENDENCY_PROBE = r"""import Lean

private unsafe def trustDependenciesImpl (names : List Lean.Name) : IO Unit := do
  Lean.initSearchPath (← Lean.findSysroot)
  Lean.enableInitializersExecution
  let env ← Lean.importModules <<MODULES>> {} (loadExts := true)
  -- Module ownership comes from the environment, not a filename/name guess.
  -- Test claims enter through explicit disclosures, with their dependencies intact.
  let discovered := if <<DISCOVER>> then (env.constants.toList.filterMap fun (name, info) =>
    match info, env.getModuleIdxFor? name with
    | .thmInfo _, some idx =>
      let owner := toString env.header.moduleNames[idx.toNat]!
      if (owner == "LidoSRv3" || owner.startsWith "LidoSRv3.") &&
          !(owner.splitOn ".").contains "Tests" &&
          !(owner.splitOn ".").contains "Regression" then some name else none
    | _, _ => none)
    else []
  let names := (names ++ discovered).eraseDups
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
