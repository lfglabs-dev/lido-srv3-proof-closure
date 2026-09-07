import LidoSRv3.Audit.Source.TrioComposition.AllocationParentCalls

namespace LidoSRv3.Tests.TrioIntegration.AllocationGuards
open LidoSRv3.Audit.Source
open TrioAlloc1 TrioComposition

private def layout : Layout := ⟨word 0, fun _ => word 0⟩
private def storage (count : Nat) : Storage := fun _ => word count
private def oracle : StaticOracle := fun _ _ => .returned []
private def run (pointer count unit : Nat) :=
  CallTree.evaluate oracle (AllocationParentCalls.program (word pointer) layout
    (storage count) ⟨word unit,word 2048⟩ (word 320) false) []

#eval (show IO Unit from do
  let cases : List (String × (Except Failure ParentOutput × Transcript) ×
      (Except Failure ParentOutput × Transcript)) := [
    ("empty arrays overflow before division", run (2^64-64) 0 0,
      (Except.error (Failure.panic (word 0x41)), [])),
    ("empty arrays fit without division", run (2^64-96) 0 0,
      (Except.ok (ParentOutput.mk (word 0) [] []), [])),
    ("nonempty division precedes allocation", run (2^64-64) 1 0,
      (Except.error (Failure.panic (word 0x12)), [])),
    ("nonempty allocation precedes calls", run (2^64-64) 1 32,
      (Except.error (Failure.panic (word 0x41)), []))]
  for (name, actual, expected) in cases do
    let equal := match actual.1, expected.1 with
      | .ok got, .ok wanted => decide (got = wanted)
      | .error got, .error wanted => decide (got = wanted)
      | _, _ => false
    unless equal && decide (actual.2 = expected.2) do
      throw (IO.userError ("allocation guard mismatch: " ++ name))
  IO.println "ALLOCATION_PARENT_GUARDS_PASS: 4 source cases")

end LidoSRv3.Tests.TrioIntegration.AllocationGuards
