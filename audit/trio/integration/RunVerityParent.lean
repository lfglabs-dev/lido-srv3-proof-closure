import Lake

/-- Remote runner driver: compile the actual VM closure before executing cases. -/
def main : IO Unit := do
  for args in #[#["build", "LidoSRv3.Tests.TrioIntegration.VerityParent"],
      #["env", "lean", "--run", "LidoSRv3/Tests/TrioIntegration/VerityParent.lean"]] do
    let child ← IO.Process.spawn { cmd := "lake", args, stdout := .inherit, stderr := .inherit }
    let status ← child.wait
    if status != 0 then throw (IO.userError s!"VM parent validation failed: {status}")
