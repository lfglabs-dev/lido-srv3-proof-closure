import LidoSRv3.Audit.Verity.AddressRecipientCallBridge

namespace LidoSRv3.Tests.PackDAddressClaimMutants
open LidoSRv3.Audit.Verity.AddressRecipientCallBridge
open LidoSRv3.Audit.Source.TrioReserve1.Live (Fault)

private def ctx : Context := ⟨1000, 1001⟩
private def before : World := { core := Verity.defaultState, balances := fun _ => 100 }

/-- The actual empty-calldata CALL exposes order; reversing payouts changes
its actual request list. No fabricated storage-only journal is used. -/
theorem swapped_payout_order_changes_actual_attempts :
    (emptyValueCall rejectingCallee ctx 1002 30 before).attempts ++
      (emptyValueCall rejectingCallee ctx 1002 40 before).attempts ≠
    (emptyValueCall rejectingCallee ctx 1002 40 before).attempts ++
      (emptyValueCall rejectingCallee ctx 1002 30 before).attempts := by decide +kernel

/-- Changing the real CALL target changes the actual recorded request. -/
theorem wrong_recipient_changes_actual_attempt :
    (emptyValueCall rejectingCallee ctx 1002 30 before).attempts ≠
      (emptyValueCall rejectingCallee ctx 1003 30 before).attempts := by decide +kernel

/-- The source entry guard precedes any physical claim and emits no attempts. -/
theorem zero_recipient_rejects_before_claim :
    (runClaimWithdrawalsTo acceptingCallee ctx [1] [1] 0 before).outcome =
      .error (.reason "ZeroRecipient") ∧
    (runClaimWithdrawalsTo acceptingCallee ctx [1] [1] 0 before).attempts = [] := by decide +kernel

/-- A genuine root failure restores any state, not only a test fixture. -/
theorem failed_batch_restores_world (callee : External) (context : Context)
    (ids hints : List Nat) (recipient : Verity.Address) (world : World) (fault : Fault)
    (h : (runClaimWithdrawalsTo callee context ids hints recipient world).outcome = .error fault) :
    (runClaimWithdrawalsTo callee context ids hints recipient world).world = world :=
  claim_withdrawals_to_revert_restores_caller_and_callee_world callee context ids hints recipient world fault h
end LidoSRv3.Tests.PackDAddressClaimMutants
