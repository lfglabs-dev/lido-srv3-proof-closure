import LidoSRv3.Audit.Source.TopupParentCorrespondence

/-!
Kill-lines pinning `Source.TopupParentCorrespondence` call-observation
constructors, `CallResponse` shape, `callSucceeded` / `allCallsSucceeded`
/ `positiveCount` semantics, and `missingResponse` witness.
-/

namespace LidoSRv3.Tests.SourceTopupParentCallShapeKillLines

open LidoSRv3.Audit.SolidityTopupParent

/-! ## `CallResponse` — control + returndata. -/

private def ok0 : CallResponse := ⟨.success, []⟩
private def failed : CallResponse := ⟨.failure, []⟩
private def reverted : CallResponse := ⟨.revert, []⟩

/-! ## `callSucceeded` — .success = true; others = false. -/

theorem callSucceeded_success : callSucceeded ok0 = true := rfl
theorem callSucceeded_failure : callSucceeded failed = false := rfl
theorem callSucceeded_revert : callSucceeded reverted = false := rfl

/-! ## `missingResponse` is the .failure default. -/

theorem missingResponse_val : missingResponse = ⟨.failure, []⟩ := rfl

theorem missingResponse_control : missingResponse.control = .failure := rfl

theorem missingResponse_returndata : missingResponse.returndata = [] := rfl

/-! ## `allCallsSucceeded` on an empty list is `true`. -/

theorem allCallsSucceeded_empty : allCallsSucceeded [] = true := rfl

/-! ## `positiveCount` filters nonzero amounts. -/

theorem positiveCount_empty : positiveCount [] = 0 := rfl

theorem positiveCount_all_zero : positiveCount [0, 0, 0] = 0 := by decide

theorem positiveCount_mixed : positiveCount [0, 1, 0, 2] = 2 := by decide

theorem positiveCount_all_positive : positiveCount [1, 2, 3] = 3 := by decide

/-! ## `beaconCalls` — three cases in the recursive definition. -/

theorem beaconCalls_empty_amounts :
    beaconCalls [] [ok0] = [] := rfl

theorem beaconCalls_zero_amount_skipped :
    beaconCalls [0] [ok0] = [] := rfl

/-! ## `allocationCall` and `lidoCall` — value = 0 (Lido pull and
    module call carry no ETH). -/

theorem allocationCall_value_zero (iface : CalleeInterface) :
    (allocationCall iface).value = 0 := rfl

theorem allocationCall_kind (iface : CalleeInterface) :
    (allocationCall iface).kind = .allocation := rfl

theorem lidoCall_value_zero (iface : CalleeInterface) :
    (lidoCall iface).value = 0 := rfl

theorem lidoCall_kind (iface : CalleeInterface) :
    (lidoCall iface).kind = .lidoPull := rfl

/-! ## `beaconCall` — carries the exact ETH value. -/

theorem beaconCall_value (amount : Nat) (response : CallResponse) :
    (beaconCall amount response).value = amount := rfl

theorem beaconCall_kind (amount : Nat) (response : CallResponse) :
    (beaconCall amount response).kind = .beaconPush := rfl

end LidoSRv3.Tests.SourceTopupParentCallShapeKillLines
