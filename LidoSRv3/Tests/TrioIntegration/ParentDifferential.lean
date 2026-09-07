import LidoSRv3.Audit.Source.TrioComposition.VerityParent
import LidoSRv3.Tests.TrioIntegration.VMFixtures

namespace LidoSRv3.Tests.TrioIntegration.ParentDifferential
open LidoSRv3.Audit.Source
open TrioAlloc1 TrioComposition
open TrioAlloc2 (zero)
open _root_.LidoSRv3.Audit.Source.TrioAlloc1 (Bytes encodeWord encodeArray word byte)

/-- Test-only slot projection and normalized module addresses. The Solidity
runner uses physical keccak slots and normalizes its two deployed module addresses. -/
private def layout : TrioAlloc1.Layout where
  routerSlot := word 10
  keccak := fun bs =>
    if bs.length = 32 then word 100 else word (1000 + (TrioAlloc1.decodeWord bs 0).val*4)
private def storage (count share0 share1 : Nat) : TrioAlloc1.Storage := fun slot =>
  if slot.val = 11 then word count
  else if slot.val = 100 then word 7
  else if slot.val = 101 then word 9
  else if slot.val = 1028 then word (21 + share0*2^192 + 2^232)
  else if slot.val = 1036 then word (22 + share1*2^192 + 2^232)
  else zero
private def summary (deposited depositable : Nat) : Bytes :=
  encodeWord zero ++ encodeWord (word deposited) ++ encodeWord (word depositable)
private def oracle (s0 s1 : Bytes) (reject1 : Bool) : TrioAlloc1.StaticOracle := fun _ call =>
  if call.target.val = 21 then .returned s0
  else if reject1 then .reverted s1 else .returned s1
private def hex (bytes : Bytes) : String := "0x" ++ String.ofList (bytes.flatMap fun b =>
  [("0123456789abcdef".toList)[b.val/16]!, ("0123456789abcdef".toList)[b.val%16]!])
private def encodeOutput (out : ParentOutput) : Bytes :=
  encodeWord out.totalAllocated ++ encodeWord (word 96) ++
  encodeWord (word (96+32*(out.allocated.length+1))) ++
  encodeArray out.allocated ++ encodeArray out.newAllocations
private def failure : TrioAlloc1.Failure → Bytes
  | .revertData bs => bs
  | .decoderFailure => []
  | .panic code => [byte 0x4e,byte 0x48,byte 0x7b,byte 0x71] ++ encodeWord code
  | .exceptionalCall => [] -- no exceptional-call vector; not normalized into decoder failure claims
/-- The VM executes the parent; expected Solidity results are not inputs. -/
private def runVM (l : Layout) (s : Storage) (o : StaticOracle) (c : Config)
    (amount : Word) (topup : Bool) : Execution ParentOutput := fun before =>
  (TrioComposition.VerityParent.execute l c amount topup (VMFixtures.vmAdversary o)
    { world := VMFixtures.vmWorld s, gasRemaining := 2^256-1 } before).1

private def emit (name : String) (count share0 share1 unit amount : Nat)
    (s0 s1 : Bytes) (reject1 : Bool := false) : IO Unit := do
  let (result, trace) := runVM layout (storage count share0 share1) (oracle s0 s1 reject1)
    ⟨word unit, word 2048⟩ (word amount) false []
  match result with
  | .error .exceptionalCall => throw (IO.userError "unexpected exceptional call in parent vectors")
  | _ => pure ()
  let (reverted, bytes) := match result with
    | .ok out => (false, encodeOutput out)
    | .error reason => (true, failure reason)
  let calls := trace.map fun c => "\"" ++ (if c.request.target.val = 21 then "0:" else "1:") ++
    ((hex c.request.payload).drop 2).toString ++ "\""
  IO.println ("VERITY_PARENT_DIFFERENTIAL_VECTOR {\"name\":\"" ++ name ++ "\",\"actual\":\"" ++ hex bytes ++
    "\",\"reverted\":" ++ (if reverted then "true" else "false") ++
    ",\"count\":" ++ toString count ++ ",\"shares\":[" ++ toString share0 ++ "," ++ toString share1 ++
    "],\"unit\":\"" ++ toString unit ++ "\",\"amount\":\"" ++ toString amount ++
    "\",\"summaries\":[\"" ++ hex s0 ++ "\",\"" ++ hex s1 ++ "\"],\"reject1\":" ++
    (if reject1 then "true" else "false") ++ ",\"calls\":[" ++ String.intercalate "," calls ++ "]}")

def runVectors : IO Unit := do
  emit "normal" 1 10000 10000 32 320 (summary 1 1) (summary 1 1)
  emit "zero-demand" 1 10000 10000 32 31 (summary 1 1) (summary 1 1)
  emit "empty-zero-divisor" 0 10000 10000 0 320 (summary 1 1) (summary 1 1)
  emit "division-before-producer" 1 10000 10000 0 320 (summary 1 1) (summary 1 1)
  emit "zero-demand-overflow" 1 10000 10000 (2^20) 0 (summary (2^240) 0) (summary 1 1)
  emit "late-second-row-overflow" 2 0 10000 (2^20) (2^20) (summary 1 0) (summary (2^240) 1)
  emit "zero-demand-late-rejection" 2 10000 10000 32 0 (summary 1 1) [byte 0xde,byte 0xad] true
  emit "malformed-summary" 1 10000 10000 32 320 [byte 0xde,byte 0xad] (summary 1 1)
end LidoSRv3.Tests.TrioIntegration.ParentDifferential

def main : IO Unit := LidoSRv3.Tests.TrioIntegration.ParentDifferential.runVectors
