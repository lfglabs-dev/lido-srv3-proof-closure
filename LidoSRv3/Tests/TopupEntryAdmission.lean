import LidoSRv3.Audit.Guarantees.PTopupEntryAdmission
import LidoSRv3.Tests.TopupRouterLocatorCall
set_option autoImplicit false
namespace LidoSRv3.Tests.TopupEntryAdmission
open Audit.Source TrioReserve1 Live TopupGatewayWitnessBatch
open TopupEntryAdmission
open TopupBatchConsumerRegression
set_option maxRecDepth 16384
set_option maxHeartbeats 4000000

-- Constant storage avoids kernel Keccak evaluation for these admission cases;
-- native diagnostics separately use actual nested physical mapping slots.
def uniform (value time : Nat) : World :=
  ⟨{Verity.defaultState with storageWords := fun _ => word value,blockTimestamp := word time},fun _ => 0,[]⟩
def caller := address 11

theorem zero_role_first : gates (address 3) caller (uniform 0 0) = .error (.bubbled (unauthorized caller)) := by decide +kernel
theorem high_bits_only_not_role : gates (address 3) caller (uniform 256 0) = .error (.bubbled (unauthorized caller)) := by decide +kernel
theorem noncanonical_lowbyte_role : gates (address 3) caller (uniform 2 2) = .ok () := by decide +kernel
theorem highbits_lowbyte_role : gates (address 3) caller (uniform (2^255+2) (2^255+2)) = .ok () := by decide +kernel
theorem pause_after_role : gates (address 3) caller (uniform 2 1) = .error (.bubbled (encode 4 0x14378398)) := by decide +kernel
theorem full_pause_word : gates (address 3) caller (uniform (2^255+2) 2) = .error (.bubbled (encode 4 0x14378398)) := by decide +kernel
theorem equality_resumed : gates (address 3) caller (uniform 255 255) = .ok () := by decide +kernel
theorem infinite_pause_before_max : gates (address 3) caller (uniform (2^256-1) (2^256-2)) = .error (.bubbled (encode 4 0x14378398)) := by decide +kernel
theorem infinite_pause_at_max : gates (address 3) caller (uniform (2^256-1) (2^256-1)) = .ok () := by decide +kernel
theorem error_calldata : (unauthorized caller).length = 68 ∧ (unauthorized caller).take 4 = [0xe2,0x51,0x7d,0x3f] ∧ (unauthorized caller).drop 4 = encode 32 11 ++ encode 32 role := by decide +kernel

def blocked : TopupGatewayRootCalls.Environment := {TopupTimingHistory.base with before := uniform 0 0}
def rejected := TopupEntryAdmission.run caller TopupRouterLocatorCall.rejected TopupRouterLocatorCall.locator
  (word 128) (word 128) TopupPhysicalCredentialGetter.hash TopupBatchConsumerRegression.reject TopupBatchConsumerRegression.reject blocked
  TopupRouterLocatorCall.supplied (address 8) (word 7) [] [] [] (word 0)

theorem role_before_lengths_lookup : rejected.outcome = .error (.admission (.bubbled (unauthorized caller))) ∧ rejected.suffix.isNone = true := by decide +kernel

theorem public_rollback : rejected.world = blocked.before :=
  Audit.Guarantees.PTopupEntryAdmission.actual_physical_entry_failure_restores
    caller TopupRouterLocatorCall.rejected TopupRouterLocatorCall.locator (word 128) (word 128)
    TopupPhysicalCredentialGetter.hash TopupBatchConsumerRegression.reject TopupBatchConsumerRegression.reject blocked
    TopupRouterLocatorCall.supplied (address 8) (word 7) [] [] [] (word 0) _ role_before_lengths_lookup.1

#print axioms public_rollback
end LidoSRv3.Tests.TopupEntryAdmission
