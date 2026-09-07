import LidoSRv3.Audit.Source.TrioComposition.FinalMemoryStoredProducer
import LidoSRv3.Tests.TrioIntegration.ParentFixtures

namespace LidoSRv3.Tests.TrioIntegration.FinalMemoryStoredProducer
open LidoSRv3.Audit.Source
open TrioAlloc1 TrioComposition

private def initial : MemoryWords := fun address => word (address+700)
private def storage (count status wc : Nat) : Storage := fun slot =>
  if slot.val = 200 then word (11+10000*2^192+status*2^224+wc*2^232)
  else ParentFixtures.storage count status slot

private def check (name : String) (pointer count status wc : Nat) (oracle : StaticOracle)
    (expected : Except Failure (Nat × Nat)) (calls : Nat) : IO Unit := do
  let (actual,trace) := CallTree.evaluate oracle
    (FinalMemoryStoredProducer.producer initial (word pointer) ParentFixtures.layout
      (storage count status wc) ⟨ParentFixtures.config 32,word 0,false⟩) []
  unless trace.length == calls do
    throw (IO.userError s!"stored producer call count mismatch: {name}: {trace.length}")
  match actual,expected with
  | .error got,.error wanted =>
    unless got = wanted do throw (IO.userError s!"stored producer failure mismatch: {name}: {repr got}")
  | .ok out,.ok (cp,ending) =>
    unless out.allocationPointer.val == pointer+128 && out.capacityPointer.val == cp && out.pointer.val == ending do
      throw (IO.userError s!"stored producer pointer mismatch: {name}")
    let allocations := TrioAlloc2.readMemoryArray out.memory out.allocationPointer.val
    let capacities := TrioAlloc2.readMemoryArray out.memory out.capacityPointer.val
    unless allocations = out.produced.allocations && capacities = out.produced.capacities &&
        allocations.length == count && capacities.length == count do
      throw (IO.userError s!"stored producer physical array mismatch: {name}")
    unless out.memory 0 = initial 0 do
      throw (IO.userError s!"stored producer modified outside word: {name}")
  | _,_ => throw (IO.userError s!"stored producer outcome mismatch: {name}")

#eval check "one-row-writes-one-call" 128 1 0 1 (ParentFixtures.summary 1) (.ok (1472,1536)) 1
#eval check "two-rows-write-twice" 128 2 0 1 (ParentFixtures.summary 1) (.ok (2400,2496)) 2
#eval check "zero-rows-distinct-headers" 128 0 0 1 ParentFixtures.rejects (.ok (544,576)) 0
#eval check "type2-row-two-calls" 128 1 0 2
  (fun before request => if request.payload = stakePayload then .returned (encodeWord (word 64))
    else ParentFixtures.summary 1 before request) (.ok (1632,1696)) 2
#eval check "slot-fails-before-calls" (2^64-65) 1 0 1 ParentFixtures.rejects
  (.error (.panic (word 0x41))) 0
#eval check "capacity-fails-after-firstpass-write" (2^64-1345) 1 0 1 (ParentFixtures.summary 1)
  (.error (.panic (word 0x41))) 1
#eval check "firstpass-error-before-capacity" (2^64-1345) 1 0 1
  (fun _ _ => .returned (encodeWord (word 2) ++ encodeWord (word 1) ++ encodeWord (word 0)))
  (.error (.panic (word 0x11))) 1
#eval check "secondpass-error-after-capacityzero" 128 1 0 1 (ParentFixtures.summary (2^256-1))
  (.error (.panic (word 0x11))) 1
#eval check "adversarial-revert-not-replayed" 128 1 0 1 ParentFixtures.rejects
  (.error (.revertData [byte 0xab])) 1
#eval check "malformed-reply-not-replayed" 128 1 0 1 (fun _ _ => .returned [])
  (.error .decoderFailure) 1
#eval IO.println "FINAL_MEMORY_STORED_PRODUCER_PASS: 10 interleaved guard/store cases"
end LidoSRv3.Tests.TrioIntegration.FinalMemoryStoredProducer
