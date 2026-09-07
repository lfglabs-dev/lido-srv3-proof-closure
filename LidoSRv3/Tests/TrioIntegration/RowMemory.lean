import LidoSRv3.Audit.Source.TrioComposition.RowMemory
import LidoSRv3.Tests.TrioIntegration.ParentFixtures

namespace LidoSRv3.Tests.TrioIntegration.RowMemory
open LidoSRv3.Audit.Source
open TrioAlloc1 TrioComposition

private def check (name : String) (pointer status wc : Nat) (oracle : StaticOracle)
    (expected : Except Failure Word) (calls : Nat) : IO Unit := do
  let storage : Storage := fun slot =>
    if slot.val = 200 then word (11+10000*2^192+status*2^224+wc*2^232)
    else ParentFixtures.storage 1 status slot
  let program := RowMemory.firstRow (word pointer) ParentFixtures.layout storage
    ⟨ParentFixtures.config 32,word 0,false⟩ 0 (word 0)
  let (actual,trace) := CallTree.evaluate oracle program []
  let equal := match actual,expected with
    | .ok (_,next),.ok wanted => decide (next = wanted)
    | .error got,.error wanted => decide (got = wanted)
    | _,_ => false
  unless equal && trace.length == calls do
    throw (IO.userError s!"row memory mismatch: {name}")

#eval check "config-before-enum" (2^64-224) 3 1 ParentFixtures.rejects
  (.error (.panic (word 0x41))) 0
#eval check "enum-before-call" 128 3 1 ParentFixtures.rejects
  (.error (.panic (word 0x21))) 0
#eval check "summary-after-config" 128 0 1 (fun _ _ => .returned [])
  (.error .decoderFailure) 1
#eval check "summary-success" 128 0 1 (ParentFixtures.summary 1) (.ok (word 448)) 1
#eval check "stake-success" 128 0 2
  (fun _ request => if request.payload = stakePayload then .returned (encodeWord (word 64))
    else ParentFixtures.summary 1 [] request)
  (.ok (word 480)) 2
private def checkLoop (pointer : Nat) (expected : Except Failure Word) (calls : Nat) : IO Unit := do
  let (actual,trace) := CallTree.evaluate (ParentFixtures.summary 1)
    (RowMemory.firstLoop ParentFixtures.layout (ParentFixtures.storage 2 0)
      ⟨ParentFixtures.config 32,word 0,false⟩ 2 0 (word 0) (word pointer)) []
  let equal := match actual,expected with
    | .ok (_,next),.ok wanted => decide (next = wanted)
    | .error got,.error wanted => decide (got = wanted)
    | _,_ => false
  unless equal && trace.length == calls do throw (IO.userError "loop memory mismatch")

#eval checkLoop 128 (.ok (word 768)) 2
#eval checkLoop (2^64-544) (.error (.panic (word 0x41))) 1
#eval IO.println "ROW_MEMORY_PASS: 7 source cases"

end LidoSRv3.Tests.TrioIntegration.RowMemory
