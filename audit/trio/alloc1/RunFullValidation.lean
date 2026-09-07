import Lake

/-- Remote-only full gate driver. Each gate executes even when another gate fails;
logs retain the command and actual exit code. This never changes canonical files
in the writer checkout: run only via the full-source remote build wrapper. -/
def main : IO UInt32 := do
  let commands : Array (String × Array String) := #[
    ("lake", #["build", "LidoSRv3", "LidoSRv3Test", "LidoSRv3Audit", "LidoSRv3Legacy",
      "LidoSRv3.Audit.Source.TrioAlloc1.ProxyGenesis",
      "LidoSRv3.Audit.Source.TrioAlloc1.AllocationMemory",
      "LidoSRv3.Tests.TrioAlloc1.VerityVectors", "LidoSRv3.Tests.TrioAlloc1.Correspondence"]),
    ("lake", #["env", "lean", "audit/trio/alloc1/InspectAdmissionAxioms.lean"]),
    ("lake", #["env", "lean", "audit/trio/alloc1/InspectAxioms.lean"]),
    ("lake", #["env", "lean", "--run", "LidoSRv3/Tests/TrioAlloc1/VerityVectors.lean"]),
    ("make", #["prove"]),
    ("make", #["test"]),
    ("python3", #["scripts/check_trust_axioms.py"]),
    ("python3", #["scripts/check_proof_escapes.py"]),
    ("python3", #["scripts/check_source_annotations.py"]),
    ("python3", #["scripts/check_report_theorem_inventory.py"]),
    ("python3", #["scripts/check_verity_provenance.py"]),
    ("python3", #["scripts/check_pinned_source.py"]),
    ("python3", #["scripts/audit_metadata.py", "check"])
  ]
  let mut failed := false
  for (cmd, args) in commands do
    IO.println s!"ALLOC1_GATE_START {cmd} {args}"
    let result ← IO.Process.output {cmd, args}
    IO.print result.stdout
    (← IO.getStderr).putStr result.stderr
    IO.println s!"ALLOC1_GATE_EXIT {result.exitCode} {cmd} {args}"
    if result.exitCode != 0 then failed := true
  return if failed then 1 else 0
