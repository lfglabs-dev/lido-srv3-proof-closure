import LidoSRv3.Audit.Source.LidoStakingStateStorage

/-! # Kill-lines for `LidoStakingStateStorage`

**Chantier 2 (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the pinned `Lido.canDeposit()` two-conjunct derivation from
`LidoStakingState { isStakingPaused, isBunkerActive }`.**

These kill-lines exhibit that `canDepositFromStorage` is exactly
`!isStakingPaused && !isBunkerActive` and demonstrate boundary cases. -/

namespace LidoSRv3.Tests.LidoStakingStateKillLines

open LidoSRv3.Audit.Source.LidoStakingStateStorage

/-- **Kill-line: canDeposit is true iff both flags are false.** -/
theorem canDeposit_true_at_both_false :
    canDepositFromStorage ⟨false, false⟩ = true := rfl

/-- **Kill-line: canDeposit is false when staking is paused.** -/
theorem canDeposit_false_when_paused :
    canDepositFromStorage ⟨true, false⟩ = false := rfl

/-- **Kill-line: canDeposit is false when bunker is active.** -/
theorem canDeposit_false_when_bunker :
    canDepositFromStorage ⟨false, true⟩ = false := rfl

/-- **Kill-line: canDeposit is false when both are active.** -/
theorem canDeposit_false_when_both :
    canDepositFromStorage ⟨true, true⟩ = false := rfl

/-- **Kill-line: canDepositFromStorage is exactly the AND-of-negations.** -/
theorem canDeposit_formula (state : LidoStakingState) :
    canDepositFromStorage state = (!state.isStakingPaused && !state.isBunkerActive) :=
  rfl

/-- **Kill-line: stakingPausedBitOffset is exactly 240.** -/
theorem stakingPausedBitOffset_pinned :
    stakingPausedBitOffset = 240 := rfl

/-- **Kill-line: stakingPausedBitWidth is exactly 1.** -/
theorem stakingPausedBitWidth_pinned :
    stakingPausedBitWidth = 1 := rfl

#print axioms canDeposit_true_at_both_false
#print axioms canDeposit_false_when_paused
#print axioms canDeposit_false_when_bunker
#print axioms canDeposit_false_when_both
#print axioms canDeposit_formula
#print axioms stakingPausedBitOffset_pinned
#print axioms stakingPausedBitWidth_pinned

end LidoSRv3.Tests.LidoStakingStateKillLines
