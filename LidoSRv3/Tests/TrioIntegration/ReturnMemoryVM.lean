import LidoSRv3.Audit.Source.TrioComposition.ReturnMemory
import LidoSRv3.Tests.TrioIntegration.VMFixtures

/-! Executed call-VM checks of the response-allocation helpers. The free
pointer is an explicit source value; these are not physical-memory tests. -/
namespace LidoSRv3.Tests.TrioIntegration.ReturnMemoryVM
open LidoSRv3.Audit.Source
open TrioAlloc1 TrioComposition
open Compiler.CompilationModel

private def check [DecidableEq α] (name : String) (program : CallTree.Program α)
    (response : CallResponse) (expected : Except Failure α) (payload : List Byte) : IO Unit := do
  let oracle : StaticOracle := fun _ _ => response
  let world := VMFixtures.vmWorld (fun _ => word 0)
  let actual := DenoteExternalCalls.denote (VerityProducer.translate [] program)
    (VMFixtures.vmAdversary oracle) { world, gasRemaining := 2^256-1 }
  let equal := match actual.1.1, expected with
    | .ok got, .ok wanted => decide (got = wanted)
    | .error got, .error wanted => decide (got = wanted)
    | _, _ => false
  let trace : Transcript := [⟨⟨⟨7,by decide⟩,payload⟩,response⟩]
  unless equal && decide (actual.1.2 = trace) &&
      actual.2.world.selfBalance.val == world.selfBalance.val do
    throw (IO.userError s!"VM response-memory mismatch: {name}")
  IO.println s!"VERITY_RETURN_MEMORY_PASS {name}"

def runVectors : IO Unit := do
  let summaryAt := fun n => ReturnMemory.summary (word n) ⟨7,by decide⟩
  check "short-safe" (summaryAt 128) (.returned [byte 1])
    (.error .decoderFailure) summaryPayload
  check "allocation-before-short-decode" (summaryAt (2^64-32)) (.returned [byte 1])
    (.error (.panic (word 0x41))) summaryPayload
  check "empty-response-no-growth" (summaryAt (2^64-32)) (.returned [])
    (.error .decoderFailure) summaryPayload
  check "rejection-before-allocation" (summaryAt (2^256-1))
    (.reverted [byte 0xde,byte 0xad])
    (.error (.revertData [byte 0xde,byte 0xad])) summaryPayload
  check "exception-before-allocation" (summaryAt (2^256-1)) .exceptional
    (.error .exceptionalCall) summaryPayload
  check "summary-copy-cap" (summaryAt 128)
    (.returned (encodeWord (word 1) ++ encodeWord (word 2) ++
      encodeWord (word 3) ++ List.replicate 100 (byte 255)))
    (.ok (⟨word 1,word 2,word 3⟩,word 224)) summaryPayload
  check "stake-copy-cap" (ReturnMemory.stake (word 128) ⟨7,by decide⟩)
    (.returned (encodeWord (word 7) ++ List.replicate 100 (byte 255)))
    (.ok (word 7,word 160)) stakePayload

end LidoSRv3.Tests.TrioIntegration.ReturnMemoryVM

def main : IO Unit := LidoSRv3.Tests.TrioIntegration.ReturnMemoryVM.runVectors
