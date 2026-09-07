import Lake

/-! Focused validation of the additive byte-copy leaves in the real root package.
The earlier full RunValidation receipt remains bound to its own source commit. -/
def main : IO Unit := do
  let commands : Array (String × Array String) := #[
    ("lake", #["build", "audit.trio.alloc2.runtime.ByteABIVectors", "audit.trio.alloc2.runtime.ByteWordCopy"]),
    ("lake", #["env", "lean", "audit/trio/alloc2/runtime/ByteABIVectors.lean"]),
    ("lake", #["env", "lean", "audit/trio/alloc2/runtime/ByteWordCopy.lean"])
  ]
  for (cmd, args) in commands do
    let label := s!"{cmd} {String.intercalate " " args.toList}"
    IO.println s!"BYTE_ABI_GATE_START {label}"
    let child ← IO.Process.spawn {
      cmd := cmd, args := args, stdout := .inherit, stderr := .inherit
    }
    let status ← child.wait
    IO.println s!"BYTE_ABI_GATE_EXIT {status} {label}"
    if status != 0 then
      throw (IO.userError s!"byte ABI gate failed: {label}: exit {status}")
