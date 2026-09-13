import LidoSRv3.Audit.Source.LidoStakingStateStorage

/-!
Kill-lines pinning `Source.LidoStakingStateStorage`
`canDepositFromStorage` source-model definition and the packed
StakeLimitStruct + bunker-storage bit derivations.
-/

namespace LidoSRv3.Tests.SourceLidoStakingStateKillLines

open LidoSRv3.Audit.Source.LidoStakingStateStorage

/-! ## `LidoStakingState` structure — two-field extraction. -/

private def running : LidoStakingState :=
  { isStakingPaused := false, isBunkerActive := false }

private def paused : LidoStakingState :=
  { isStakingPaused := true, isBunkerActive := false }

private def bunker : LidoStakingState :=
  { isStakingPaused := false, isBunkerActive := true }

theorem staking_paused_field : paused.isStakingPaused = true := rfl
theorem bunker_active_field : bunker.isBunkerActive = true := rfl

/-! ## `canDepositFromStorage` truth-table. -/

theorem canDeposit_running :
    canDepositFromStorage running = true := rfl

theorem canDeposit_paused :
    canDepositFromStorage paused = false := rfl

theorem canDeposit_bunker :
    canDepositFromStorage bunker = false := rfl

theorem canDeposit_both :
    canDepositFromStorage { isStakingPaused := true, isBunkerActive := true } =
      false := rfl

/-! ## `canDepositFromStorage_iff` — kill-line restatement. -/

theorem canDepositFromStorage_iff_restated (state : LidoStakingState) :
    canDepositFromStorage state = true ↔
      state.isStakingPaused = false ∧ state.isBunkerActive = false :=
  canDepositFromStorage_iff state

/-! ## `canDeposit_true_of_pinned_storage` — kill-line restatement. -/

theorem canDeposit_true_of_pinned_storage_restated
    {state : LidoStakingState}
    (hStakingNotPaused : state.isStakingPaused = false)
    (hBunkerNotActive : state.isBunkerActive = false) :
    canDepositFromStorage state = true :=
  canDeposit_true_of_pinned_storage hStakingNotPaused hBunkerNotActive

/-! ## Pinned bit-offset constants. -/

theorem stakingPausedBitOffset_val : stakingPausedBitOffset = 240 := rfl

theorem stakingPausedBitWidth_val : stakingPausedBitWidth = 1 := rfl

end LidoSRv3.Tests.SourceLidoStakingStateKillLines
