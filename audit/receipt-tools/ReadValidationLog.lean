import Lean

/-! Read-only retrieval through the registered runner's `lake env lean` form.
No tests or proof checks execute here. The retained log must identify the
requested candidate; a missing/mismatched log is an error, never fresh evidence. -/

private def expectedCandidate : String :=
  "cd2948767db4778a9db867946c9c1cbada4a563e"

#eval do
  let path := ".lake/candidate-validation/test.log"
  let contents ← IO.FS.readFile path
  unless (contents.splitOn ("candidate " ++ expectedCandidate)).length > 1 do
    throw (IO.userError "retained test.log does not identify the requested candidate")
  IO.println ("RETAINED_TEST_LOG_BEGIN candidate=" ++ expectedCandidate)
  let lines := contents.splitOn "\n"
  for (index, line) in lines.zipIdx do
    if index + 80 ≥ lines.length then
      IO.println (toString (index + 1) ++ ":" ++ line)
  IO.println "RETAINED_TEST_LOG_END"
