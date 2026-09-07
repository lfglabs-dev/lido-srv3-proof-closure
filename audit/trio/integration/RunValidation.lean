import Lake

/-! Driver for the supported remote Lean runner. It executes the repository's
full gates without replacing any check with the bounded integration checker.
Invoke only in a private remote checkout at the recorded source SHA. -/
def main : IO Unit := do
  let systemPath := (← IO.getEnv "PATH").getD "/usr/local/bin:/usr/bin:/bin"
  let tools := (← IO.currentDir) / ".lake/trio-tools/foundry-v1.3.1"
  let searchTools := (← IO.currentDir) / ".lake/trio-tools/ripgrep-14.1.1"
  let commands : Array (String × Array String) := #[
    ("bash", #["scripts/prepare_trio_validation.sh"]),
    ("lake", #["build", "LidoSRv3", "LidoSRv3Test", "LidoSRv3Audit", "TrioIntegrationChecks"]),
    ("make", #["prove"]),
    ("make", #["test"]),
    ("lake", #["env", "lean", "--run", "audit/trio/alloc1/RunVerityVectors.lean"]),
    ("lake", #["env", "lean", "--run", "audit/trio/integration/RunVerityParent.lean"])
  ]
  let mut failures : Array String := #[]
  let mut results : Array String := #[]
  for (cmd, args) in commands do
    IO.println s!"INTEGRATION_GATE_START {cmd} {String.intercalate " " args.toList}"
    let child ← IO.Process.spawn {
      cmd := cmd
      args := args
      stdout := .inherit
      stderr := .inherit
      env := #[("PATH", some s!"{tools}:{searchTools}:{systemPath}")]
    }
    let status ← child.wait
    IO.println s!"INTEGRATION_GATE_EXIT {status} {cmd} {String.intercalate " " args.toList}"
    results := results.push s!"INTEGRATION_GATE_SUMMARY {status} {cmd} {String.intercalate " " args.toList}"
    if status != 0 then
      failures := failures.push s!"{cmd} {String.intercalate " " args.toList}: exit {status}"
  -- Repeat every gate outcome at the end so capped remote tails retain them.
  for result in results do
    IO.println result
  if !failures.isEmpty then
    throw (IO.userError s!"integration gates failed: {String.intercalate "; " failures.toList}")
