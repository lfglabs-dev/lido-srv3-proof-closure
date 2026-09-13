import LidoSRv3.Audit.Source.TopupCorrespondence

/-! # Kill-lines for `TopupCorrespondence.Outcome` distinctness

**Chantier 1 (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the pinned StakingRouter.topUp revert-branch enumeration
(revertNotAuthorized / revertEmptyKeysList /
revertArraysLengthMismatch / revertWrongPubkeyLength / etc.). -/

namespace LidoSRv3.Tests.TopupOutcomeEnumKillLines

open LidoSRv3.Audit.SolidityTopup

/-- **Kill-line: pinned StakingRouter.topUp NotAuthorized is a distinct
enum constructor.**

A mutant that collapsed two revert branches at the source-line-686
guard would obscure the caller-authorization diagnostic. -/
theorem revertNotAuthorized_ne_revertEmptyKeysList :
    Outcome.revertNotAuthorized ≠ Outcome.revertEmptyKeysList := by decide

/-- **Kill-line: `revertNotAuthorized` ≠ `revertArraysLengthMismatch`.** -/
theorem revertNotAuthorized_ne_arraysMismatch :
    Outcome.revertNotAuthorized ≠ Outcome.revertArraysLengthMismatch := by decide

/-- **Kill-line: `revertWrongPubkeyLength` ≠ `revertWrongWithdrawalCredentialsType`.** -/
theorem revertWrongPubkeyLength_ne_revertWrongWc :
    Outcome.revertWrongPubkeyLength ≠
      Outcome.revertWrongWithdrawalCredentialsType := by decide

/-- **Kill-line: `revertStakingModuleUnregistered` ≠
`revertStakingModuleNotActive`.**

Two distinct SRUtils checks; mutants can't collapse them. -/
theorem revertStakingModuleUnregistered_ne_notActive :
    Outcome.revertStakingModuleUnregistered ≠
      Outcome.revertStakingModuleNotActive := by decide

/-- **Kill-line: Lido guards distinct: `revertLidoDepositsPaused` ≠
`revertLidoCannotDeposit`.** -/
theorem revertLidoDepositsPaused_ne_cannotDeposit :
    Outcome.revertLidoDepositsPaused ≠
      Outcome.revertLidoCannotDeposit := by decide

/-- **Kill-line: `revertLidoZeroAmount` ≠ `revertLidoNotEnoughEther`.** -/
theorem revertLidoZeroAmount_ne_notEnoughEther :
    Outcome.revertLidoZeroAmount ≠
      Outcome.revertLidoNotEnoughEther := by decide

/-- **Kill-line: BeaconChainDepositor guards distinct:
`revertArrayLengthMismatch` ≠ `revertInvalidPublicKeyLength`.** -/
theorem revertArrayLengthMismatch_ne_invalidPk :
    Outcome.revertArrayLengthMismatch ≠
      Outcome.revertInvalidPublicKeyLength := by decide

/-- **Kill-line: `revertDepositAmountTooLow` ≠ `revertAmountTooLarge`
(range guards symmetric).** -/
theorem revertDepositAmountTooLow_ne_tooLarge :
    Outcome.revertDepositAmountTooLow ≠ Outcome.revertAmountTooLarge := by decide

/-- **Kill-line: wrap-plane guards distinct:
`revertInsufficientRouterBalance` ≠ `revertAssertBalanceUnchanged`.**

Two wrap-plane failure modes at StakingRouter.sol lines 106 vs
752-755. -/
theorem revertInsufficientRouterBalance_ne_assertBalance :
    Outcome.revertInsufficientRouterBalance ≠
      Outcome.revertAssertBalanceUnchanged := by decide

#print axioms revertNotAuthorized_ne_revertEmptyKeysList
#print axioms revertWrongPubkeyLength_ne_revertWrongWc
#print axioms revertStakingModuleUnregistered_ne_notActive
#print axioms revertLidoDepositsPaused_ne_cannotDeposit
#print axioms revertLidoZeroAmount_ne_notEnoughEther
#print axioms revertInsufficientRouterBalance_ne_assertBalance

end LidoSRv3.Tests.TopupOutcomeEnumKillLines
