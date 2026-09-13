import LidoSRv3.Audit.Verity.TopupTx

/-!
Kill-lines pinning `Verity.TopupTx.allocationPass` recursion base
case and `allocationStage` post-state (StakingRouter.sol:722-734
allocation loop and the pull-slot zero write).
-/

namespace LidoSRv3.Tests.VerityTopupTxAllocationPassKillLines

open LidoSRv3.Audit.Verity.TopupTx

/-! ## `allocationPass` on empty allocations writes `total` to the
    allocation-total slot and preserves the rest. -/

theorem allocationPass_empty
    (index total : Nat) (state : Verity.ContractState) :
    allocationPass [] index total state =
      state.writeSlot allocationTotalSlot total := rfl

/-! ## `allocationPass` empty writes `total` value to the total slot. -/

theorem allocationPass_empty_readSlot_via_writeSlot
    (state : Verity.ContractState) :
    allocationPass [] 0 42 state =
      state.writeSlot allocationTotalSlot 42 := rfl

/-! ## `allocationStage` on empty writes both slots. -/

theorem allocationStage_success (state : Verity.ContractState) :
    ((allocationStage []).run state).fst = () := rfl

/-! ## `allocationStage` on empty zeros `pulledTotalSlot`. -/

theorem allocationStage_empty_pulled_zero (state : Verity.ContractState) :
    ((allocationStage []).run state).snd.readSlot pulledTotalSlot =
      (0 : Verity.Uint256) := by
  simp [allocationStage, allocationPass, Verity.Contract.run,
    Verity.ContractState.readSlot, Verity.ContractState.storage_writeSlot_same]

/-! ## Pinned storage-slot literals for the transaction plane. -/

theorem allocationSlot_val : allocationSlot = 7100 := rfl
theorem allocationTotalSlot_val : allocationTotalSlot = 7101 := rfl
theorem pulledTotalSlot_val : pulledTotalSlot = 7102 := rfl

/-! ## Slot pairwise distinctness (three writes never collide). -/

theorem allocationSlot_ne_allocationTotalSlot :
    allocationSlot ≠ allocationTotalSlot := by decide

theorem allocationSlot_ne_pulledTotalSlot :
    allocationSlot ≠ pulledTotalSlot := by decide

theorem allocationTotalSlot_ne_pulledTotalSlot :
    allocationTotalSlot ≠ pulledTotalSlot := by decide

/-! ## Pinned deployment address literals. -/

theorem lidoAddress_val :
    lidoAddress = (0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84 : Verity.Address) := rfl

theorem beaconAddress_val :
    beaconAddress = (0x00000000219ab540356cBB839Cbe05303d7705Fa : Verity.Address) := rfl

end LidoSRv3.Tests.VerityTopupTxAllocationPassKillLines
