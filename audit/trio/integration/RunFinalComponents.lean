import Lake

/-- Targeted official-runner gate; this is not the full validation receipt. -/
def main : IO Unit := do
  let mut failed := false
  for args in #[#["build", "LidoSRv3.Audit.Source.TrioComposition.ReserveLeafSpend",
      "LidoSRv3.Tests.TrioIntegration.MemoryParentVM"],
      #["env", "lean", "--run", "audit/trio/integration/RunVerityParent.lean"]] do
    let child ← IO.Process.spawn { cmd := "lake", args, stdout := .inherit, stderr := .inherit }
    let status ← child.wait
    IO.println s!"FINAL_COMPONENT_GATE {status} {String.intercalate " " args.toList}"
    if status != 0 then failed := true
  if failed then throw (IO.userError "Final component validation failed")
