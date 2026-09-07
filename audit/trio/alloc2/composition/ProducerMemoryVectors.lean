import audit.trio.alloc2.composition.ProducerMemory
import audit.trio.alloc2.composition.ParentVectors

namespace LidoSRv3.Audit.Source.TrioAlloc2.ProducerMemoryVectors
open _root_.LidoSRv3.Audit.Source.TrioAlloc1 (Bytes word byte encodeWord encodeArray)
open ParentVectors (hex)

private def emit (name : String) (count wc status : Nat) (summary stake : Bytes)
    (reject : Bool := false) : IO Unit := do
  let storage : TrioAlloc1.Storage := fun slot =>
    if slot.val = 1028 then word (21 + 10000*2^192 + status*2^224 + wc*2^232)
    else ParentVectors.storage count 10000 10000 slot
  let oracle : TrioAlloc1.StaticOracle := fun _ call =>
    if reject then .reverted summary
    else if call.payload = TrioAlloc1.stakePayload then .returned stake else .returned summary
  let (result, after) := ProducerMemory.produceM ParentVectors.layout storage oracle
    ⟨⟨word 32, word 2048⟩, word 10, false⟩ ⟨word 128, []⟩
  let (reverted, bytes) := match result with
    | .ok out => (false, encodeWord (word 64) ++ encodeWord (word (64+32*(out.allocations.length+1))) ++
        encodeArray out.allocations ++ encodeArray out.capacities)
    | .error reason => (true, ParentVectors.failure reason)
  let calls := after.trace.map fun c => "\"" ++ (if c.request.target.val = 21 then "0:" else "1:") ++
    ((hex c.request.payload).drop 2).toString ++ "\""
  IO.println ("ALLOC2_PRODUCER_MEMORY_VECTOR {\"name\":\"" ++ name ++ "\",\"count\":" ++ toString count ++
    ",\"wc\":" ++ toString wc ++ ",\"status\":" ++ toString status ++ ",\"summary\":\"" ++ hex summary ++
    "\",\"stake\":\"" ++ hex stake ++ "\",\"reject\":" ++ (if reject then "true" else "false") ++
    ",\"pointer\":\"" ++ toString after.pointer.val ++ "\",\"reverted\":" ++ (if reverted then "true" else "false") ++
    ",\"actual\":\"" ++ hex bytes ++ "\",\"calls\":[" ++ String.intercalate "," calls ++ "]}")

#eval do
  emit "one-row" 1 1 0 (ParentVectors.summary 1 1) (encodeWord (word 64))
  emit "two-rows" 2 1 0 (ParentVectors.summary 1 1) (encodeWord (word 64))
  emit "type-two" 1 2 0 (ParentVectors.summary 1 1) (encodeWord (word 64))
  emit "short-summary" 1 1 0 [byte 0xde, byte 0xad] (encodeWord (word 64))
  emit "rejected-summary" 1 1 0 [byte 0xde, byte 0xad] (encodeWord (word 64)) true
  emit "invalid-status" 1 1 3 (ParentVectors.summary 1 1) (encodeWord (word 64))
end LidoSRv3.Audit.Source.TrioAlloc2.ProducerMemoryVectors
