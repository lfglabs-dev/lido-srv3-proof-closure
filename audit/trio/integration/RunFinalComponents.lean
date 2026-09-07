import Lake

/-- Targeted official-runner gate; this is not the full validation receipt. -/
def main : IO Unit := do
  for args in #[#["build", "LidoSRv3.Audit.Source.TrioComposition.ReserveLeafSpend",
      "LidoSRv3.Tests.TrioIntegration.MemoryParentVM"],
      #["env", "lean", "--run", "LidoSRv3/Tests/TrioIntegration/MemoryParentVM.lean"]] do
    let child ← IO.Process.spawn { cmd := "lake", args, stdout := .inherit, stderr := .inherit }
    let status ← child.wait
    if status != 0 then throw (IO.userError s!"Final component validation failed: {status}")
