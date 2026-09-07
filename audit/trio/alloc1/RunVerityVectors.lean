import Lake

/-- Remote-only driver: build the full imported VM modules before executing them. -/
def main : IO Unit := do
  let build ← IO.Process.output {
    cmd := "lake", args := #["build", "LidoSRv3.Tests.TrioAlloc1.VerityVectors"] }
  (← IO.getStderr).putStr build.stdout
  (← IO.getStderr).putStr build.stderr
  if build.exitCode != 0 then throw (IO.userError s!"Verity vector build failed: {build.exitCode}")
  let run ← IO.Process.output {
    cmd := "lake", args := #["env", "lean", "--run", "LidoSRv3/Tests/TrioAlloc1/VerityVectors.lean"] }
  (← IO.getStderr).putStr run.stderr
  if run.exitCode != 0 then
    (← IO.getStderr).putStr run.stdout
    throw (IO.userError s!"Verity vector execution failed: {run.exitCode}")
  IO.print run.stdout
