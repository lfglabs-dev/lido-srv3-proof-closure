import LidoSRv3.Audit.Guarantees.PTopupMemoryCalls
import LidoSRv3.Tests.TopupRootCallEffectsRegression
set_option autoImplicit false
namespace LidoSRv3.Tests.TopupModuleMemoryRegression
open Audit.Source TrioReserve1 Live
open TopupBatchConsumerRegression TopupBatchRootCallsRegression
set_option maxRecDepth 16384
set_option maxHeartbeats 4000000

theorem canonical_array : TopupModuleMemory.decodeReturn (word 128)
    (TopupModuleCall.encodeReturn [word 1,word 9]) = .ok ([word 1,word 9],word 352) := by decide +kernel

/-- Raw allocation precedes even the empty-head rejection. -/
theorem raw_allocation_first : TopupModuleMemory.decodeReturn (word (2^64)) [] =
    .error (.reason "Panic(0x41)") := by decide +kernel

/-- The same empty reply at an admitted cursor takes the head error. -/
theorem empty_head : TopupModuleMemory.decodeReturn (word 128) [] = .error .empty := by decide +kernel

/-- Count=1 but no element: array allocation can fail before payload extent. -/
theorem array_allocation_before_extent : TopupModuleMemory.decodeReturn (word (2^64-96))
    (encode 32 32 ++ encode 32 1) = .error (.reason "Panic(0x41)") := by decide +kernel

theorem short_payload : TopupModuleMemory.decodeReturn (word 128)
    (encode 32 32 ++ encode 32 1) = .error .empty := by decide +kernel

theorem count_panics : TopupModuleMemory.decodeReturn (word 128)
    (encode 32 32 ++ encode 32 (2^64)) = .error (.reason "Panic(0x41)") := by decide +kernel

/-- Unaligned offset and unpadded tail remain admitted; no canonical ABI premise. -/
theorem unaligned_empty : TopupModuleMemory.decodeReturn (word 128)
    (encode 32 33 ++ [0] ++ encode 32 0) = .ok ([],word 256) := by decide +kernel

def batch (cursor : Word) := TopupBatchMemory.run cursor mapHash twoModule reject env ctx
  (address 8) (word 7) [word 42,word 43] [word 3,word 4]
  [row,secondRow] (word (2^256-1))

theorem full_batch_success : (batch (word 128)).outcome = .ok () := by decide +kernel

theorem full_batch_same_world_attempts : batch (word 128) = twoBatch := by rfl

/-- Module changes have happened; the later scalar array-allocation failure
restores the complete root world, preserving two roots and successful CALL. -/
theorem full_batch_memory_failure :
    (batch (word (2^64-160))).outcome = .error (.module (.reason "Panic(0x41)")) ∧
    (batch (word (2^64-160))).world = env.before ∧
    (batch (word (2^64-160))).rootAttempts.length = 2 ∧
    (batch (word (2^64-160))).moduleAttempts.length = 1 ∧
    ((batch (word (2^64-160))).moduleAttempts.head?).map (fun a => a.accepted) = some true := by
  exact ⟨by decide +kernel,rfl,by decide +kernel,by decide +kernel,by decide +kernel⟩

/-- The full normal-kernel execution instantiates the public composed theorem. -/
def public_consumer := Audit.Guarantees.PTopupMemoryCalls.actual_root_module_memory_effects
  (word 128) mapHash twoModule reject env ctx (address 8) (word 7)
  [word 42,word 43] [word 3,word 4] [row,secondRow] (word (2^256-1)) full_batch_success

open TopupRootCallEffectsRegression in
def positive := TopupBatchMemory.run (word 128) mapHash
  (module [word (10^18),word 0,word (2*10^18)]) TopupRouterContinuationMutants.callee
  environment ctx (address 8) (word 7) [word 1,word 2,word 3] [word 4,word 5,word 6]
  rows (word (2^256-1))

theorem positive_preserves_physical_execution : positive = TopupRootCallEffectsRegression.positive := by rfl

theorem positive_success : positive.outcome = .ok () := by
  rw [positive_preserves_physical_execution]
  exact TopupRootCallEffectsRegression.positive_batch_succeeds

#print axioms canonical_array
#print axioms raw_allocation_first
#print axioms empty_head
#print axioms array_allocation_before_extent
#print axioms short_payload
#print axioms count_panics
#print axioms unaligned_empty
#print axioms full_batch_success
#print axioms full_batch_same_world_attempts
#print axioms full_batch_memory_failure
#print axioms public_consumer
#print axioms positive_preserves_physical_execution
#print axioms positive_success
end LidoSRv3.Tests.TopupModuleMemoryRegression
