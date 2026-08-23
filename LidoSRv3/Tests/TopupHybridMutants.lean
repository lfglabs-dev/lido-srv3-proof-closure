import LidoSRv3.Audit.Verity.TopupHybrid

namespace LidoSRv3.Tests.TopupHybridMutants

open _root_.Verity
open LidoSRv3.Audit.SolidityTopup
open LidoSRv3.Audit.Verity.TopupHybrid

private def state : ContractState := { defaultState with sender := 17 }

private def revertedWith (expected : String) (result : ContractResult Unit) : Bool :=
  match result with
  | .revert reason rollback => reason == expected && rollback.sender == state.sender
  | .success _ _ => false

/- A mutant that lets the source-revert flag pass is rejected before either
external call and `Contract.run` exposes the original snapshot. -/
#guard revertedWith "SOURCE_TOPUP_REVERTED"
  ((TopupTxContract.executeTopup true 7 7 true).run state)

/- Pulling and pushing different aggregate values is a transaction revert. -/
#guard revertedWith "TOPUP_VALUE_MISMATCH"
  ((TopupTxContract.executeTopup false 7 8 true).run state)

/- A mutant that strands value in the router is rejected after the two declared
call sites by the balance observation. -/
#guard revertedWith "ROUTER_BALANCE_CHANGED"
  ((TopupTxContract.executeTopup false 7 7 false).run state)

/- A pull-side source failure reaches the pull call and reverts before the
beacon suffix. -/
#guard revertedWith "SOURCE_TOPUP_REVERTED_DURING_PULL"
  ((TopupTxContract.executePullRevert 7).run state)

/- A downstream source failure reaches both value-bearing calls before the
transaction snapshot is restored. -/
#guard revertedWith "SOURCE_TOPUP_REVERTED_DURING_PUSH"
  ((TopupTxContract.executePushRevert 7 7).run state)

/- The zero-top-up commit uses the call-free entrypoint. -/
#guard match (TopupTxContract.executeNoTopup false 0 0).run state with
  | .success _ after => after.sender == state.sender
  | .revert _ _ => false

/-! ## Wrap partition at the hybrid boundary

`verity_tx_simulates_source` no longer assumes `SolidityTopup.NoUncheckedWrap`,
so the two wrapping partitions of the registered abstract parent's third
conjunct (`source_wrap_precludes_value_moving_commit`) are executed here
rather than excluded by premise.  The witnesses mirror
`LidoSRv3/Tests/TopupTxMutants.lean` (`killCfg` / `wrapInput` /
`wrapToZeroInput`). -/

private def killCfg : SourceTopupConfig := ⟨48, 48, 1, 1, uint256Modulus⟩

/-- A batch whose exact sum `2^256 + 1` exceeds the word modulus, so the
on-chain `unchecked` accumulator wraps to `1`; every limit, balance and cap
sits above the exact sum, so no other guard fires. -/
private def wrapInput : SourceTopupInput :=
  { callerIsTopUpGateway := true, keyIndicesLength := 2, operatorIdsLength := 2,
    topUpLimits := [uint256Modulus + 1, uint256Modulus + 1],
    pubkeyLengths := [48, 48], moduleExists := true, moduleActive := true,
    wcTypeIsType2 := true, maxTopUpPerBlockGwei := uint256Modulus + 1,
    moduleAllocationEth := uint256Modulus + 1, lidoCanDeposit := true,
    allocations := [uint256Modulus - 1, 2], routerBalanceBefore := uint256Modulus,
    lidoDepositableEther := uint256Modulus + 1 }

/-- A batch whose exact sum is exactly `2^256`, so the accumulator wraps to
zero and the source takes the line-741 empty commit. -/
private def wrapToZeroInput : SourceTopupInput :=
  { wrapInput with allocations := [uint256Modulus - 1, 1] }

/-- The generalized hybrid parent covers a nonzero-wrap input: the witness
wraps (so the retired premise is refuted at it), and the executed Verity
observation still equals the source transaction reading. -/
theorem hybrid_simulation_covers_nonzero_wrap :
    ¬ NoUncheckedWrap wrapInput ∧
      observeVerity state ((executeSource killCfg wrapInput).run state)
        = sourceTx killCfg wrapInput state :=
  ⟨by unfold NoUncheckedWrap; decide,
    verity_tx_simulates_source killCfg wrapInput state⟩

/-- The generalized hybrid parent covers a wrap-to-zero input: the witness
wraps to zero (empty commit, not a revert), and the executed Verity
observation still equals the source transaction reading. -/
theorem hybrid_simulation_covers_wrap_to_zero :
    ¬ NoUncheckedWrap wrapToZeroInput ∧
      observeVerity state ((executeSource killCfg wrapToZeroInput).run state)
        = sourceTx killCfg wrapToZeroInput state :=
  ⟨by unfold NoUncheckedWrap; decide,
    verity_tx_simulates_source killCfg wrapToZeroInput state⟩

/- Nonzero wrap is an executed revert at the hybrid boundary: the source
outcome is the line-755 assert, so the typed program runs the deliberately
failing `executeTopup` tail (it is fed the exact total as both the pull and
the push word, so the equality guard passes and the false balance observation
fires), and `Contract.run` restores the original snapshot. -/
#guard revertedWith "ROUTER_BALANCE_CHANGED"
  ((executeSource killCfg wrapInput).run state)

/- Wrap-to-zero is an executed empty commit at the hybrid boundary: the
source outcome is `committedNoTopUp`, so the typed program runs the call-free
`executeNoTopup` entrypoint. -/
#guard match (executeSource killCfg wrapToZeroInput).run state with
  | .success _ after => after.sender == state.sender
  | .revert _ _ => false

#check verity_tx_simulates_source
#check verity_revert_restores_snapshot
#check source_value_observation_adequate

end LidoSRv3.Tests.TopupHybridMutants
