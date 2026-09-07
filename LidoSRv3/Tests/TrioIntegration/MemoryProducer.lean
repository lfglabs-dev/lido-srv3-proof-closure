import LidoSRv3.Audit.Source.TrioComposition.MemoryProducer
import LidoSRv3.Tests.TrioIntegration.ParentFixtures

namespace LidoSRv3.Tests.TrioIntegration.MemoryProducer
open LidoSRv3.Audit.Source
open TrioAlloc1 TrioComposition

private def check (name : String) (pointer count : Nat) (oracle : StaticOracle)
    (expected : Except Failure Word) (calls : Nat) : IO Unit := do
  let (actual,trace) := CallTree.evaluate oracle
    (MemoryProducer.producer (word pointer) ParentFixtures.layout (ParentFixtures.storage count 0)
      ⟨ParentFixtures.config 32,word 0,false⟩) []
  let equal := match actual,expected with
    | .ok (_,next),.ok wanted => decide (next = wanted)
    | .error got,.error wanted => decide (got = wanted)
    | _,_ => false
  unless equal && trace.length == calls do
    throw (IO.userError s!"producer memory mismatch: {name}")

#eval check "one-row" 128 1 (ParentFixtures.summary 1) (.ok (word 1024)) 1
#eval check "scratch-before-call" (2^64-512) 1 ParentFixtures.rejects
  (.error (.panic (word 0x41))) 0
#eval check "capacity-after-call" (2^64-896) 1 (ParentFixtures.summary 1)
  (.error (.panic (word 0x41))) 1
#eval check "first-pass-before-capacity" (2^64-896) 1
  (fun _ _ => .returned (encodeWord (word 2) ++ encodeWord (word 1) ++ encodeWord (word 0)))
  (.error (.panic (word 0x11))) 1
#eval check "capacity-before-second-pass" (2^64-896) 1 (ParentFixtures.summary (2^256-1))
  (.error (.panic (word 0x41))) 1
#eval check "second-pass-overflow" 128 1 (ParentFixtures.summary (2^256-1))
  (.error (.panic (word 0x11))) 1
#eval check "prefix-before-call" 128 (2^64) ParentFixtures.rejects
  (.error (.panic (word 0x41))) 0
#eval check "two-rows" 128 2 (ParentFixtures.summary 1) (.ok (word 1600)) 2
#eval IO.println "MEMORY_PRODUCER_PASS: 8 source cases"

end LidoSRv3.Tests.TrioIntegration.MemoryProducer
