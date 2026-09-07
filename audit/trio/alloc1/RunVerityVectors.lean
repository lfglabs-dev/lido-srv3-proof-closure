import Lake

/-- Remote-only driver: build the full imported VM modules before executing them. -/
def main : IO Unit := do
  let build ← IO.Process.output {
    cmd := "lake", args := #["build", "LidoSRv3.Tests.TrioAlloc1.VerityVectors",
      "LidoSRv3.Audit.Source.TrioAlloc1.CapacitySpec",
      "LidoSRv3.Audit.Source.TrioAlloc1.Memory",
      "LidoSRv3.Audit.Source.TrioAlloc1.Determinism",
      "LidoSRv3.Audit.Source.TrioAlloc1.ShareWriter",
      "LidoSRv3.Audit.Source.TrioAlloc1.WriterInvariant",
      "LidoSRv3.Audit.Source.TrioAlloc1.AdmissionChecks",
      "LidoSRv3.Audit.Source.TrioAlloc1.EnumerationWriter",
      "LidoSRv3.Audit.Source.TrioAlloc1.AllocationMemory",
      "LidoSRv3.Tests.TrioAlloc1.Correspondence"] }
  (← IO.getStderr).putStr build.stdout
  (← IO.getStderr).putStr build.stderr
  if build.exitCode != 0 then throw (IO.userError s!"Verity vector build failed: {build.exitCode}")
  let trust ← IO.Process.output {
    cmd := "lake", args := #["env", "lean", "audit/trio/alloc1/InspectAxioms.lean"] }
  (← IO.getStderr).putStr trust.stdout
  (← IO.getStderr).putStr trust.stderr
  if trust.exitCode != 0 then throw (IO.userError s!"Owned axiom inspection failed: {trust.exitCode}")
  let run ← IO.Process.output {
    cmd := "lake", args := #["env", "lean", "--run", "LidoSRv3/Tests/TrioAlloc1/VerityVectors.lean"] }
  (← IO.getStderr).putStr run.stderr
  if run.exitCode != 0 then
    (← IO.getStderr).putStr run.stdout
    throw (IO.userError s!"Verity vector execution failed: {run.exitCode}")
  IO.print run.stdout
