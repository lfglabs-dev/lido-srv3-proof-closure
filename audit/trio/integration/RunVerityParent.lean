import Lake

/-- Remote runner driver: compile the actual VM closure before executing cases. -/
def main : IO Unit := do
  for args in #[#["build", "LidoSRv3.Tests.TrioIntegration.VerityParent",
      "LidoSRv3.Tests.TrioIntegration.ParentDifferential",
      "LidoSRv3.Tests.TrioIntegration.ReturnMemoryVM"],
      #["env", "lean", "--run", "LidoSRv3/Tests/TrioIntegration/VerityParent.lean"],
      #["env", "lean", "--run", "LidoSRv3/Tests/TrioIntegration/ParentDifferential.lean"],
      #["env", "lean", "--run", "LidoSRv3/Tests/TrioIntegration/ReturnMemoryVM.lean"]] do
    let child ← IO.Process.spawn { cmd := "lake", args, stdout := .inherit, stderr := .inherit }
    let status ← child.wait
    if status != 0 then throw (IO.userError s!"VM parent validation failed: {status}")
