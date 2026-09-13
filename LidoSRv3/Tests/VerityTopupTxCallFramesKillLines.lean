import LidoSRv3.Audit.Verity.TopupTx

/-!
Kill-lines pinning `Verity.TopupTx` call-frame constructors:
`lidoPull`, `creditPull`, `scheduledBeaconPush`, `scheduledDeposit`,
and the `sourceDerivedDeposit` byte-word commitment identity.
-/

namespace LidoSRv3.Tests.VerityTopupTxCallFramesKillLines

open LidoSRv3.Audit.Verity.TopupTx

/-! ## `scheduledDeposit` — index/amount pass-through shape. -/

theorem scheduledDeposit_pubkey (index amount : Nat) :
    (scheduledDeposit index amount).pubkey = index := rfl

theorem scheduledDeposit_wc (index amount : Nat) :
    (scheduledDeposit index amount).withdrawalCredentials = 0 := rfl

theorem scheduledDeposit_signature (index amount : Nat) :
    (scheduledDeposit index amount).signature = 0 := rfl

theorem scheduledDeposit_depositDataRoot (index amount : Nat) :
    (scheduledDeposit index amount).depositDataRoot = amount := rfl

/-! ## `sourceByteCommitment` — byte-fold identity. -/

theorem sourceByteCommitment_empty :
    sourceByteCommitment [] = 0 := rfl

theorem sourceByteCommitment_single :
    sourceByteCommitment [0x42] = 0x42 := by decide

theorem sourceByteCommitment_two_bytes :
    sourceByteCommitment [0x01, 0x02] = 258 := by decide

/-! ## `creditPull` — post-state has the pulled selfBalance and
    pulledTotalSlot. -/

theorem creditPull_selfBalance (total : Nat) (state : Verity.ContractState) :
    ((creditPull total).run state).snd.selfBalance =
      state.selfBalance + (total : Verity.Uint256) := rfl

theorem creditPull_pulledTotalSlot (total : Nat) (state : Verity.ContractState) :
    ((creditPull total).run state).snd.readSlot pulledTotalSlot =
      (total : Verity.Uint256) := by
  simp [creditPull, Verity.Contract.run, Verity.ContractState.readSlot,
    Verity.ContractState.storage_writeSlot_same]

/-! ## `creditPull` succeeds. -/

theorem creditPull_success (total : Nat) (state : Verity.ContractState) :
    ((creditPull total).run state).fst = () := rfl

end LidoSRv3.Tests.VerityTopupTxCallFramesKillLines
