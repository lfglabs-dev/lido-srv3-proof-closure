import LidoSRv3.Audit.Source.ReserveCorrespondence

/-!
Kill-lines pinning `Source.ReserveCorrespondence.WithdrawInputs`
def-accessors (`canDeposit`, `authorizedRouter`) that eliminate the
two free-Bool fields under chantier 2 Piste A. Also pins
`effectiveWithdrawalsReserve` on the zero state.
-/

namespace LidoSRv3.Tests.SourceReserveWithdrawInputsKillLines

open LidoSRv3.Audit.SolidityReserve

/-! ## `canDeposit` def-accessor identity — no longer a free Bool. -/

theorem canDeposit_is_def_accessor (inputs : WithdrawInputs) :
    inputs.canDeposit =
      LidoSRv3.Audit.Source.LidoStakingStateStorage.canDepositFromStorage
        inputs.lidoState := rfl

/-! ## `authorizedRouter` def-accessor identity — no longer a free Bool. -/

theorem authorizedRouter_is_def_accessor (inputs : WithdrawInputs) :
    inputs.authorizedRouter =
      LidoSRv3.Audit.Source.AragonACLSource.isAuthorizedRouter inputs.acl := rfl

/-! ## Running-state witness: canDeposit = true when Lido storage is
    not paused and bunker is not active. -/

private def runningLidoState :
    LidoSRv3.Audit.Source.LidoStakingStateStorage.LidoStakingState :=
  { isStakingPaused := false, isBunkerActive := false }

private def emptyACL : LidoSRv3.Audit.Source.AragonACLSource.ACLState :=
  { stakingRouterRole := false, topUpGatewayApp := false }

private def grantedACL : LidoSRv3.Audit.Source.AragonACLSource.ACLState :=
  { stakingRouterRole := true, topUpGatewayApp := false }

private def running : WithdrawInputs :=
  { lidoState := runningLidoState, acl := grantedACL }

theorem canDeposit_running :
    running.canDeposit = true := rfl

theorem authorizedRouter_running :
    running.authorizedRouter = true := rfl

/-! ## Off-state: canDeposit = false when staking is paused. -/

private def pausedInputs : WithdrawInputs :=
  { lidoState := { isStakingPaused := true, isBunkerActive := false }
    acl := grantedACL }

theorem canDeposit_paused :
    pausedInputs.canDeposit = false := rfl

private def unauthorizedInputs : WithdrawInputs :=
  { lidoState := runningLidoState, acl := emptyACL }

theorem authorizedRouter_unauthorized :
    unauthorizedInputs.authorizedRouter = false := rfl

/-! ## `effectiveWithdrawalsReserve` on zero state. -/

private def zeroState : ReserveState :=
  { buffered := 0, storedDepositsReserve := 0, unfinalizedStETH := 0
    depositedPostReport := 0, depositedNextReportAdjusted := 0 }

theorem effectiveWithdrawalsReserve_zero :
    effectiveWithdrawalsReserve zeroState = (0 : Word) := by decide

/-! ## `WithdrawInputs` decidable equality — pin the two-field record. -/

theorem withdrawInputs_decEq_self :
    (decide (running = running)) = true := by decide

theorem withdrawInputs_decEq_paused_ne_running :
    (decide (running = pausedInputs)) = false := by decide

end LidoSRv3.Tests.SourceReserveWithdrawInputsKillLines
