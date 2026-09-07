import LidoSRv3.Audit.Source.TrioComposition.FinalMemoryStoredParent
import LidoSRv3.Tests.TrioIntegration.ParentFixtures

/-! Executed source-model regressions for the single fused parent. These checks
include the full static/delegate event stream and live final memory. They do not
claim deployed EVM execution or arbitrary linked-library behavior. -/
namespace LidoSRv3.Tests.TrioIntegration.FinalMemoryStoredParent
open LidoSRv3.Audit.Source
open TrioAlloc1 TrioComposition
open FinalMemoryStoredParentMemory

private def target : Address := ⟨77,by decide⟩
private def memory : MemoryWords := fun address => word (address+500)
private def prior : CallObservation := ⟨⟨⟨5,by decide⟩,[byte 0xaa]⟩,.exceptional⟩
private def history : MemoryTransportCall.Trace :=
  [⟨⟨.delegateCall,⟨19,by decide⟩,word 0,[byte 0xff]⟩,.reverted []⟩,
    MemoryTransportCall.staticEvent prior]

private def check (name : String) (pointer count status unit amount : Nat) (oracle : StaticOracle)
    (expected : Except Failure ParentOutput) (staticCount delegateCount : Nat) : IO Unit := do
  let run := FinalMemoryStoredParent.program target memory (word pointer) ParentFixtures.layout
    (ParentFixtures.storage count status) oracle (ParentFixtures.config unit) (word amount) false [prior] history
  let observed := run.result.map observe
  let equal := match observed,expected with
    | .ok a,.ok b => decide (a = b)
    | .error a,.error b => decide (a = b)
    | _,_ => false
  unless equal do throw (IO.userError s!"stored parent output mismatch: {name}: {repr observed}")
  unless run.modules.take 1 = [prior] && run.modules.length == staticCount+1 do
    throw (IO.userError s!"stored parent source prefix mismatch: {name}")
  unless run.calls.take history.length = history do
    throw (IO.userError s!"stored parent full prefix changed: {name}")
  let suffix := run.calls.drop history.length
  unless suffix.length == staticCount+delegateCount &&
      suffix.take staticCount = (run.modules.drop 1).map MemoryTransportCall.staticEvent do
    throw (IO.userError s!"stored parent static suffix duplicated/reordered: {name}")
  for event in suffix.drop staticCount do
    unless event.request.kind = .delegateCall && event.request.target = target &&
        event.request.transferredValue = word 0 && event.request.payload.take 4 = MemoryTransportCall.selector do
      throw (IO.userError s!"stored parent delegate metadata mismatch: {name}")
  match run.result with
  | .error _ => pure ()
  | .ok out =>
    unless out.ap.val+32*(count+1) ≤ out.rp.val && out.rp.val+32*(count+1) ≤ out.pointer.val &&
        out.pointer.val < 2^64 do throw (IO.userError s!"stored parent overlapping output memory: {name}")

#eval check "outer-before-division" (2^64-65) 1 0 0 0 ParentFixtures.rejects (.error (.panic (word 0x41))) 0 0
#eval check "nominal-division" 128 1 0 0 0 ParentFixtures.rejects (.error (.panic (word 0x12))) 0 0
#eval check "empty-memory-and-prefix" 128 0 0 0 0 ParentFixtures.rejects (.ok ⟨word 0,[],[]⟩) 0 0
#eval check "positive-memory-and-single-delegate" 128 1 0 32 65 (ParentFixtures.summary 1)
  (.ok ⟨word 64,[word 64],[word 96]⟩) 1 1
#eval check "two-module-order" 128 2 0 32 64 (ParentFixtures.summary 1)
  (.ok ⟨word 64,[word 32,word 32],[word 64,word 64]⟩) 2 1
#eval check "zero-demand-no-delegate" 128 1 0 32 31 (ParentFixtures.summary 1)
  (.ok ⟨word 0,[word 0],[word 32]⟩) 1 0
#eval check "producer-rejection-prefix" 128 1 0 32 32 ParentFixtures.rejects
  (.error (.revertData [byte 0xab])) 1 0
#eval check "malformed-module-prefix" 128 1 0 32 32 (fun _ _ => .returned [])
  (.error .decoderFailure) 1 0
#eval check "invalid-enum-before-calls" 128 1 3 32 32 ParentFixtures.rejects
  (.error (.panic (word 0x21))) 0 0
#eval check "raw-allocation-failure-retains-delegate" (2^64-1664) 1 0 32 32 (ParentFixtures.summary 1)
  (.error (.panic (word 0x41))) 1 1
#eval check "decoded-allocation-failure-retains-delegate" (2^64-1728) 1 0 32 32 (ParentFixtures.summary 1)
  (.error (.panic (word 0x41))) 1 1
#eval check "capacity-failure-has-no-delegate" (2^64-1473) 1 0 32 32 (ParentFixtures.summary 1)
  (.error (.panic (word 0x41))) 1 0
#eval check "zero-result-allocation-failure" (2^64-1537) 1 0 32 0 (ParentFixtures.summary 1)
  (.error (.panic (word 0x41))) 1 0
#eval check "late-conversion-error-retains-delegate" 128 1 0 (2^255) (2^255) (ParentFixtures.summary 1)
  (.error (.panic (word 0x11))) 1 1
#eval check "late-zero-conversion-error" 128 1 1 32 0 (ParentFixtures.summary (2^256-1))
  (.error (.panic (word 0x11))) 1 0
#eval check "transcript-sensitive-oracle-single-run" 128 1 0 32 65
  (fun before request => if before.length = 1 then ParentFixtures.summary 1 before request else .exceptional)
  (.ok ⟨word 64,[word 64],[word 96]⟩) 1 1

private def concreteCopy : IO Unit := do
  let run := FinalMemoryStoredParent.program target memory (word 128) ParentFixtures.layout
    (ParentFixtures.storage 1 0) (ParentFixtures.summary 1) (ParentFixtures.config 32) (word 65) false [prior] history
  match run.result,run.calls.getLast? with
  | .ok out,some event =>
    let result : TrioAlloc2.StepOutput := {amount := word 2,buckets := [word 3]}
    let wanted := MemoryTransportCall.selector ++ TrioAlloc2.LibraryABI.encodeArguments
      ⟨[word 1],[word 3],word 2⟩
    unless event.request.payload = wanted && event.response = .returned (TrioAlloc2.LibraryABI.encodeReturn result) do
      throw (IO.userError "stored parent argument/raw-return byte mismatch")
    unless out.ap = word 384 && out.rp = word 1792 && out.pointer = word 1856 &&
        out.memory 416 = word 64 && out.memory 1824 = word 96 && out.memory 1760 = word 3 do
      throw (IO.userError "stored parent live decode copy aliased raw buffer or old array")
  | _,_ => throw (IO.userError "stored parent concrete copy did not succeed")
#eval concreteCopy
#eval IO.println "FINAL_MEMORY_STORED_PARENT_PASS: 16 full-parent cases plus exact ABI/raw-copy memory check"
end LidoSRv3.Tests.TrioIntegration.FinalMemoryStoredParent
