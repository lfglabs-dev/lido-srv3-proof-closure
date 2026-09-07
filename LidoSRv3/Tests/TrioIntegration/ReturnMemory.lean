import LidoSRv3.Audit.Source.TrioComposition.ReturnMemory

namespace LidoSRv3.Tests.TrioIntegration.ReturnMemory
open LidoSRv3.Audit.Source
open TrioAlloc1 TrioComposition

private def checkSummary (pointer : Nat) (response : CallResponse)
    (expected : Except Failure (Summary × Word)) : IO Unit := do
  let oracle : StaticOracle := fun _ _ => response
  let (actual, trace) := CallTree.evaluate oracle (ReturnMemory.summary (word pointer) ⟨7,by decide⟩) []
  let equal := match actual, expected with
    | .ok got, .ok wanted => decide (got = wanted)
    | .error got, .error wanted => decide (got = wanted)
    | _, _ => false
  unless equal && decide (trace = [⟨⟨⟨7,by decide⟩,summaryPayload⟩,response⟩]) do
    throw (IO.userError "summary response-memory mismatch")

#eval checkSummary 128 (.returned [byte 1]) (.error .decoderFailure)
#eval checkSummary (2^64-32) (.returned [byte 1]) (.error (.panic (word 0x41)))
#eval checkSummary (2^64-32) (.returned []) (.error .decoderFailure)
#eval checkSummary (2^256-1) (.reverted [byte 0xde,byte 0xad])
  (.error (.revertData [byte 0xde,byte 0xad]))
#eval checkSummary (2^256-1) .exceptional (.error .exceptionalCall)
#eval checkSummary 128 (.returned (encodeWord (word 1) ++ encodeWord (word 2) ++
  encodeWord (word 3) ++ List.replicate 100 (byte 255)))
  (.ok (⟨word 1,word 2,word 3⟩,word 224))

#eval (show IO Unit from do
  let data := encodeWord (word 7) ++ List.replicate 100 (byte 255)
  let oracle : StaticOracle := fun _ _ => .returned data
  let (result, trace) := CallTree.evaluate oracle (ReturnMemory.stake (word 128) ⟨7,by decide⟩) []
  let equal := match result with
    | .ok (stake,next) => decide (stake = word 7 ∧ next = word 160)
    | .error _ => false
  unless equal && trace.length == 1 do throw (IO.userError "stake response-memory mismatch")
  IO.println "RETURN_MEMORY_PASS: 7 source cases")

end LidoSRv3.Tests.TrioIntegration.ReturnMemory
