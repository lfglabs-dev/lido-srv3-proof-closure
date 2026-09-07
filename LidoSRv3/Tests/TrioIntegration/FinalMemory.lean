import LidoSRv3.Audit.Source.TrioComposition.FinalMemoryParent
import LidoSRv3.Tests.TrioIntegration.ParentFixtures

/-! Runtime regressions for newly interleaved slot buffers and the canonical
caller boundary. These execute the source models, not an EVM interpreter. -/
namespace LidoSRv3.Tests.TrioIntegration.FinalMemory
open LidoSRv3.Audit.Source
open TrioAlloc1 TrioComposition

private def checkParent (name : String) (pointer count status unit amount : Nat)
    (oracle : StaticOracle) (expected : Except Failure ParentOutput) (calls : Nat) : IO Unit := do
  let (actual,trace) := CallTree.evaluate oracle
    (FinalMemoryParent.program (word pointer) ParentFixtures.layout (ParentFixtures.storage count status)
      (ParentFixtures.config unit) (word amount) false) []
  let equal := match actual,expected with
    | .ok a,.ok b => decide (a = b)
    | .error a,.error b => decide (a = b)
    | _,_ => false
  unless equal && trace.length == calls do
    throw (IO.userError s!"final memory parent mismatch: {name}: {repr actual}, calls={trace.length}")

-- First64 succeeds; second64 fails before the nonempty branch's division.
#eval checkParent "outer-slot-before-division" (2^64-65) 1 0 0 0 ParentFixtures.rejects
  (.error (.panic (word 0x41))) 0
#eval checkParent "bounded-slot-then-division" 128 1 0 0 0 ParentFixtures.rejects
  (.error (.panic (word 0x12))) 0
#eval checkParent "outer-slot-before-empty" (2^64-65) 0 0 0 0 ParentFixtures.rejects
  (.error (.panic (word 0x41))) 0
#eval checkParent "empty-before-division" 128 0 0 0 0 ParentFixtures.rejects
  (.ok ⟨word 0,[],[]⟩) 0
#eval checkParent "positive-canonical-return" 128 1 0 32 65 (ParentFixtures.summary 1)
  (.ok ⟨word 64,[word 64],[word 96]⟩) 1
#eval checkParent "zero-demand-conversion" 128 1 0 32 31 (ParentFixtures.summary 1)
  (.ok ⟨word 0,[word 0],[word 32]⟩) 1
#eval checkParent "rejection-preserves-call" 128 1 0 32 0 ParentFixtures.rejects
  (.error (.revertData [byte 0xab])) 1
#eval checkParent "malformed-summary-preserves-call" 128 1 0 32 0 (fun _ _ => .returned [])
  (.error .decoderFailure) 1
#eval checkParent "conversion-overflow-after-producer" 128 1 1 32 0
  (ParentFixtures.summary (2^256-1)) (.error (.panic (word 0x11))) 1

private def produced (old : Nat) : CapacityOutput :=
  ⟨[⟨word 7,⟨11,by decide⟩⟩],[word old],[word 2],rfl,rfl⟩

private def checkCaller (name : String) (pointer demand old code : Nat) : IO Unit := do
  let (actual,trace) := CallTree.evaluate ParentFixtures.rejects
    (FinalMemoryCaller.afterProducer (word pointer) (word 1) (ParentFixtures.config (2^255))
      (word demand) (produced old)) []
  match actual with
  | .error (.panic got) =>
    unless got = word code && trace.isEmpty do
      throw (IO.userError s!"final memory caller wrong failure: {name}")
  | _ => throw (IO.userError s!"final memory caller expected failure: {name}: {repr actual}")

-- The same canonical allocation result overflows at Ether conversion for a
-- small pointer. Near the limit, raw128 or decoded64 allocation takes priority.
#eval checkCaller "raw-return-before-conversion" (2^64-128) 1 1 0x41
#eval checkCaller "decoded-array-before-conversion" (2^64-192) 1 1 0x41
#eval checkCaller "bounded-return-then-conversion" 128 1 1 0x11
#eval checkCaller "zero-array-before-conversion" (2^64-64) 0 2 0x41
#eval checkCaller "bounded-zero-array-then-conversion" 128 0 2 0x11

example : AllocationMemory.finalize (word (2^64-65)) (word 64) = .ok (word (2^64-1)) := by rfl
example : FinalMemoryRows.slot (word (2^64-65)) = .error (.panic (word 0x41)) := by rfl
example : AllocationMemory.finalize (word (2^64-192)) (word 128) = .ok (word (2^64-64)) := by rfl
example : AllocationMemory.allocateArray (word (2^64-64)) (word 1) = .error (.panic (word 0x41)) := by rfl
example : FinalMemoryCaller.canonicalReply (word (2^64-1)) (.error [byte 0xab]) =
    .error (.revertData [byte 0xab]) := FinalMemoryCaller.library_failure _ _

/-- The counterexample does not depend on how the storage/configuration is
chosen: the slot-allocation panic wins before inspecting the parent guard. -/
theorem outer_slot_failure_precedes_parent (layout : Layout) (storage : Storage)
    (config : Config) (amount : Word) (isTopUp : Bool) :
    FinalMemoryParent.program (word (2^64-65)) layout storage config amount isTopUp =
      .done (.error (.panic (word 0x41))) :=
  FinalMemoryParent.outer_allocation_failure _ _ _ _ _ _ _ (by rfl)

#print axioms outer_slot_failure_precedes_parent
#eval IO.println "FINAL_MEMORY_PASS: 14 source runtime cases and 5 allocation boundary checks"
end LidoSRv3.Tests.TrioIntegration.FinalMemory
