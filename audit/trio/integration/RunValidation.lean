import Lake

/-! Driver for the supported remote Lean runner. It executes the repository's
full gates without replacing any check with the bounded integration checker.
Invoke only in a private remote checkout at the recorded source SHA. -/
def main : IO Unit := do
  let commands : Array (String × Array String) := #[
    ("lake", #["build", "LidoSRv3", "LidoSRv3Test", "LidoSRv3Audit"]),
    ("make", #["prove"]),
    ("make", #["test"]),
    ("lake", #["env", "lean", "--run", "audit/trio/alloc1/RunVerityVectors.lean"])
  ]
  let mut failures : Array String := #[]
  for (cmd, args) in commands do
    IO.println s!"INTEGRATION_GATE_START {cmd} {String.intercalate " " args.toList}"
    let child ← IO.Process.spawn { cmd, args, stdout := .inherit, stderr := .inherit }
    let status ← child.wait
    IO.println s!"INTEGRATION_GATE_EXIT {status} {cmd} {String.intercalate " " args.toList}"
    if status != 0 then
      failures := failures.push s!"{cmd} {String.intercalate " " args.toList}: exit {status}"
  if !failures.isEmpty then
    throw (IO.userError s!"integration gates failed: {String.intercalate "; " failures.toList}")
