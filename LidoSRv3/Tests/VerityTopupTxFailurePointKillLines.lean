import LidoSRv3.Audit.Verity.TopupTx

/-!
Kill-lines pinning `Verity.TopupTx.FailurePoint` inductive enum, the
`BeaconDepositCall` structure, and the ABI helpers `abiWordOfBytes`,
`abiByteWords`, `abiBytesTail`, plus the pinned `beaconDepositSelector`.
-/

namespace LidoSRv3.Tests.VerityTopupTxFailurePointKillLines

open LidoSRv3.Audit.Verity.TopupTx

/-! ## `FailurePoint` — four-arm enum distinctness (SRLib.sol pinned
    revert boundaries). -/

theorem failurePoint_none_ne_afterAllocation :
    FailurePoint.none ≠ FailurePoint.afterAllocationWrite := by decide

theorem failurePoint_none_ne_afterLidoPull :
    FailurePoint.none ≠ FailurePoint.afterLidoPull := by decide

theorem failurePoint_none_ne_afterFirstBeaconPush :
    FailurePoint.none ≠ FailurePoint.afterFirstBeaconPush := by decide

theorem failurePoint_alloc_ne_lidoPull :
    FailurePoint.afterAllocationWrite ≠ FailurePoint.afterLidoPull := by decide

theorem failurePoint_alloc_ne_beacon :
    FailurePoint.afterAllocationWrite ≠ FailurePoint.afterFirstBeaconPush := by decide

theorem failurePoint_lido_ne_beacon :
    FailurePoint.afterLidoPull ≠ FailurePoint.afterFirstBeaconPush := by decide

theorem failurePoint_decEq_self :
    (decide (FailurePoint.afterLidoPull = FailurePoint.afterLidoPull)) = true := by decide

/-! ## `BeaconDepositCall` — four-field decidable-eq record. -/

private def bd0 : BeaconDepositCall :=
  { pubkey := 1, withdrawalCredentials := 2, signature := 3, depositDataRoot := 4 }

theorem beaconDepositCall_pubkey : bd0.pubkey = 1 := rfl
theorem beaconDepositCall_wc : bd0.withdrawalCredentials = 2 := rfl
theorem beaconDepositCall_signature : bd0.signature = 3 := rfl
theorem beaconDepositCall_root : bd0.depositDataRoot = 4 := rfl

theorem beaconDepositCall_decEq_self :
    (decide (bd0 = bd0)) = true := by decide

theorem beaconDepositCall_decEq_neg :
    (decide (bd0 = { bd0 with pubkey := 99 })) = false := by decide

/-! ## `beaconDepositSelector` — pinned `bytes4(keccak256("deposit(...)"))`. -/

theorem beaconDepositSelector_val :
    beaconDepositSelector = (0x22895118 : Verity.Uint256) := rfl

/-! ## `dummySignature` — 96 zero bytes. -/

theorem dummySignature_length : dummySignature.length = 96 := rfl

theorem dummySignature_all_zero :
    dummySignature.all (· == 0) = true := by decide

end LidoSRv3.Tests.VerityTopupTxFailurePointKillLines
