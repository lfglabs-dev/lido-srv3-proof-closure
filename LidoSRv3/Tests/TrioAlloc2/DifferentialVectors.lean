import LidoSRv3.Audit.Source.TrioAlloc2.Loop

/-! Actual decoded-Lean executions exported for comparison with pinned Solidity.
This is not a Verity runtime or a byte-memory correspondence theorem. -/
namespace LidoSRv3.Tests.TrioAlloc2.DifferentialVectors
open LidoSRv3.Audit.Source.TrioAlloc2

private def w (n : Nat) : Word := ⟨n % 2 ^ 256, Nat.mod_lt _ (by decide)⟩
private def quoted (n : Nat) : String := "\"" ++ toString n ++ "\""
private def words (ws : List Word) : String :=
  "[" ++ String.intercalate "," (ws.map fun x => quoted x.val) ++ "]"
private def outcome : Result StepOutput → String
  | .ok out => "{\"amount\":" ++ quoted out.amount.val ++ ",\"buckets\":" ++ words out.buckets ++ "}"
  | .error e => "{\"panic\":" ++ toString (match e with
    | .arithmetic => 17 | .divisionByZero => 18 | .arrayBounds => 50) ++ "}"
private def emit (name : String) (bs cs : List Word) (d : Word) : IO Unit :=
  IO.println ("ALLOC2_VECTOR {\"name\":\"" ++ name ++ "\",\"buckets\":" ++ words bs ++
    ",\"capacities\":" ++ words cs ++ ",\"demand\":" ++ quoted d.val ++
    ",\"step\":" ++ outcome (step bs cs d) ++ ",\"run\":" ++ outcome (allocate bs cs d) ++ "}")

#eval do
  emit "zero-short" [w 7] [] zero
  emit "empty" [] [] (w 5)
  emit "short-first" [zero] [] one
  emit "short-after-open" [zero, one] [w 9] (w 3)
  emit "short-after-closed" [w 8, one] [w 7] (w 3)
  emit "surplus" [zero] [w 5, zero] (w 3)
  emit "overfull" [w 9] [w 8] (w 3)
  emit "illustration" [w 9998, w 70, zero] [w 10000, w 101, w 100] (w 101)
  emit "max-demand" [zero] [maxWord] maxWord
  emit "max-saturated" [maxWord] [maxWord] maxWord
  emit "max-last-unit" [w (2^256-2)] [maxWord] maxWord
  emit "two-ties" [zero, zero] [w 100, w 100] (w 31)
  emit "three-ties" [w 4, w 4, w 4] [w 50, w 50, w 50] (w 8)
  emit "tie-first-cap" [zero, zero] [one, w 20] (w 9)
  emit "skip-saturated-tie" [zero, zero, zero] [zero, w 5, w 6] (w 3)
  emit "higher-closed" [zero, one, w 3] [w 20, one, w 30] (w 9)
  emit "higher-open" [zero, w 7, w 4] [w 20, w 8, w 30] (w 6)
  emit "tiny-demand" [w 3, w 3, w 3, w 3] [w 4, w 4, w 4, w 4] one
  emit "zero-capacities" [zero, zero] [zero, zero] maxWord
  emit "nonmonotone" [w 10, w 1, w 7, w 1] [w 9, w 13, w 15, w 3] (w 25)
  for n in List.range 12 do
    emit ("generated-" ++ toString n)
      [w (n % 5), w ((n * 7) % 9), w ((n + 4) % 6)]
      [w ((n + 3) % 10), w ((n * 3) % 13), w (n + 2)] (w (n * 2 + 1))

end LidoSRv3.Tests.TrioAlloc2.DifferentialVectors
