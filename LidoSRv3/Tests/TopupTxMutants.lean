import LidoSRv3.Audit.Verity.TopupTx
import LidoSRv3.Audit.Source.TopupParentCorrespondence

/-! # P-TOPUP-1 faithful-plane fail-closed vectors

Every mutant here mutates the *executable transaction*: it runs the same
`allocationStage` storage writes and the same `externalCallBindTo` call frames
through `Contract.run`, and is rejected by exactly the observable equality the
guarantee theorem asserts.  `mutant_none_reproduces_execute` pins
`Mutation.none` to the production `execute`, so these are rejections of a
mutated execution rather than of a hand-written journal list. -/

namespace LidoSRv3.Tests.TopupTxMutants

open Verity
open Contracts
open LidoSRv3.Audit.SolidityTopup
open LidoSRv3.Audit.Verity.TopupTx

private def twoBatch : List Nat := [11, 13]

/-- The entry frame of the guarantee theorem, at a concrete state. -/
private def frame : ContractState := entryFrame defaultState

inductive Mutation where
  | none
  | skipAllocationWrite
  | dropLastPush
  | misroutePush
  | corruptAmount
  | swapPushOrder
  | duplicateFirstPush
  deriving DecidableEq, Repr

/-- Aggregate-only bookkeeping: the batch total is still written, but the
per-validator mapping words are not.  This is the mutant an observable that
watched only `allocationTotalSlot` would have missed. -/
private def mutantAllocationStage (m : Mutation) (allocations : List Nat) : Contract Unit :=
  match m with
  | .skipAllocationWrite => fun state =>
      .success ()
        ((state.writeSlot allocationTotalSlot ((allocSum allocations : Nat) : Uint256)).writeSlot
          pulledTotalSlot 0)
  | _ => allocationStage allocations

/-- Destination and value mutations of one deposit frame. -/
private def mutantPush (m : Mutation) (index amount : Nat) : Contract Unit :=
  match m with
  | .misroutePush =>
      externalCallBindTo lidoAddress ((amount : Nat) : Uint256) [] "makeBeaconChainTopUp"
        ([((index : Nat) : Uint256), ((amount : Nat) : Uint256)] : List Uint256)
  | .corruptAmount => beaconPush index (amount - 1)
  | _ => beaconPush index amount

/-- Sequence mutations of the push schedule `pushLoop` walks. -/
private def mutantSchedule (m : Mutation) (allocations : List Nat) : List (Nat × Nat) :=
  match m with
  | .dropLastPush => (sourcePushes allocations 0).dropLast
  | .swapPushOrder => (sourcePushes allocations 0).reverse
  | .duplicateFirstPush => (sourcePushes allocations 0).take 1 ++ sourcePushes allocations 0
  | _ => sourcePushes allocations 0

private def runSchedule (m : Mutation) : List (Nat × Nat) → Contract Unit
  | [] => Verity.pure ()
  | p :: rest => do
      mutantPush m p.1 p.2
      runSchedule m rest

private def mutantExecute (m : Mutation) (allocations : List Nat) : Contract Unit := do
  mutantAllocationStage m allocations
  let total := allocSum allocations
  if total = 0 then Verity.pure ()
  else do
    lidoPull total
    creditPull total
    runSchedule m (mutantSchedule m allocations)

/-- The unmutated mutant *is* the production transaction. -/
theorem mutant_none_reproduces_execute :
    (mutantExecute .none twoBatch).run frame = (execute twoBatch .none).run frame := by
  rfl

/-- Positive control: the executable transaction reproduces the pinned-source
observables, journal destinations and argument words included. -/
theorem honest_run_matches_source :
    observe frame twoBatch.length ((execute twoBatch .none).run frame)
      = sourceObservables twoBatch :=
  execute_observes_source_from_entry twoBatch defaultState (by decide) (by decide)

/-- Aggregate bookkeeping without the per-validator writes is rejected. -/
theorem skipped_allocation_write_rejected :
    observe frame twoBatch.length ((mutantExecute .skipAllocationWrite twoBatch).run frame)
      ≠ sourceObservables twoBatch := by decide

/-- Omitting the second deposit frame is rejected. -/
theorem dropped_push_rejected :
    observe frame twoBatch.length ((mutantExecute .dropLastPush twoBatch).run frame)
      ≠ sourceObservables twoBatch := by decide

/-- Sending a deposit to Lido instead of the deposit contract is rejected even
though the wei total is unchanged. -/
theorem misrouted_push_rejected :
    observe frame twoBatch.length ((mutantExecute .misroutePush twoBatch).run frame)
      ≠ sourceObservables twoBatch := by decide

/-- Short-paying each validator by one wei is rejected. -/
theorem corrupted_amount_rejected :
    observe frame twoBatch.length ((mutantExecute .corruptAmount twoBatch).run frame)
      ≠ sourceObservables twoBatch := by decide

/-- Reordering the batch is rejected: the journal records call order. -/
theorem swapped_order_rejected :
    observe frame twoBatch.length ((mutantExecute .swapPushOrder twoBatch).run frame)
      ≠ sourceObservables twoBatch := by decide

/-- Replaying the first deposit overspends the pull, and the ETH-aware call
frame reverts rather than minting wei. -/
theorem duplicated_push_rejected :
    observe frame twoBatch.length ((mutantExecute .duplicateFirstPush twoBatch).run frame)
      ≠ sourceObservables twoBatch := by decide

/-! ## Rollback after real prefix effects -/

/-- The allocation writes really happened before the injected failure. -/
theorem allocation_write_prefix_is_real :
    (execute twoBatch .afterAllocationWrite frame).snd.readSlot allocationTotalSlot
      = ((24 : Nat) : Uint256) := by rfl

/-- The Lido pull frame was really journalled before the injected failure. -/
theorem lido_pull_prefix_is_real :
    (execute twoBatch .afterLidoPull frame).snd.calls = [pullEntry 24] := by rfl

/-- The first deposit frame was really journalled and really debited. -/
theorem first_push_prefix_is_real :
    (execute twoBatch .afterFirstBeaconPush frame).snd.calls
      = [pullEntry 24, pushEntry (0, 11)] ∧
    (execute twoBatch .afterFirstBeaconPush frame).snd.selfBalance = ((13 : Nat) : Uint256) := by
  exact ⟨rfl, rfl⟩

/-- Each of those failures is normalized by `Contract.run` back to the exact
entry snapshot, and observes nothing at all. -/
theorem allocation_write_failure_rolls_back :
    (execute twoBatch .afterAllocationWrite).run frame
      = .revert "FAIL_AFTER_ALLOCATION_WRITE" frame := by rfl

theorem lido_pull_failure_rolls_back :
    (execute twoBatch .afterLidoPull).run frame
      = .revert "FAIL_AFTER_LIDO_PULL" frame := by rfl

theorem first_beacon_failure_rolls_back :
    (execute twoBatch .afterFirstBeaconPush).run frame
      = .revert "FAIL_AFTER_FIRST_BEACON_PUSH" frame := by rfl

theorem reverted_batch_observes_nothing (failure : FailurePoint)
    (h : failure ≠ .none) :
    observe frame twoBatch.length ((execute twoBatch failure).run frame)
      = ⟨false, [], 0, 0, 0, [], [], [], []⟩ := by
  cases failure <;> simp at h ⊢ <;> rfl

/-! ## Wave 1 kill-line mutants (parent-level) -/

open LidoSRv3.Audit.SolidityTopupParent in
/-- Mutant: wrap the unchecked sum AND skip the balance assert.  Under a wrap,
`accumulated ≠ pushedValue`, so skipping the assert allows a non-conserving
commit.  The kill line is source line 755 (`assert`). -/
theorem kill_wrap_skip_assert :
    let allocs := [uint256Modulus - 1, 2]
    let inp : SourceTopupInput :=
      { callerIsTopUpGateway := true, keyIndicesLength := 2, operatorIdsLength := 2,
        topUpLimits := [uint256Modulus, uint256Modulus],
        pubkeyLengths := [48, 48], moduleExists := true, moduleActive := true,
        wcTypeIsType2 := true, maxTopUpPerBlockGwei := uint256Modulus,
        moduleAllocationEth := uint256Modulus, lidoCanDeposit := true,
        allocations := allocs, routerBalanceBefore := uint256Modulus,
        lidoDepositableEther := uint256Modulus }
    accumulated inp ≠ pushedValue inp := by decide

/-- Mutant: remove `moduleExists` require.  An unregistered module that would
be rejected at source line 689 now reaches a later branch; the guard is
exercised. -/
theorem kill_remove_module_exists :
    let cfg : SourceTopupConfig := ⟨48, 48, 1, 1, uint256Modulus⟩
    let inp : SourceTopupInput :=
      { callerIsTopUpGateway := true, keyIndicesLength := 1, operatorIdsLength := 1,
        topUpLimits := [10], pubkeyLengths := [48], moduleExists := false,
        moduleActive := true, wcTypeIsType2 := true, maxTopUpPerBlockGwei := 100,
        moduleAllocationEth := 100, lidoCanDeposit := true,
        allocations := [5], routerBalanceBefore := 100,
        lidoDepositableEther := 100 }
    run cfg inp = .revertStakingModuleUnregistered := by decide

/-- Mutant: remove `wcTypeIsType2` require.  A non-type-2 module that would be
rejected at source line 694 now reaches a later branch; the guard is
exercised. -/
theorem kill_remove_wc_type2 :
    let cfg : SourceTopupConfig := ⟨48, 48, 1, 1, uint256Modulus⟩
    let inp : SourceTopupInput :=
      { callerIsTopUpGateway := true, keyIndicesLength := 1, operatorIdsLength := 1,
        topUpLimits := [10], pubkeyLengths := [48], moduleExists := true,
        moduleActive := true, wcTypeIsType2 := false, maxTopUpPerBlockGwei := 100,
        moduleAllocationEth := 100, lidoCanDeposit := true,
        allocations := [5], routerBalanceBefore := 100,
        lidoDepositableEther := 100 }
    run cfg inp = .revertWrongWithdrawalCredentialsType := by decide

end LidoSRv3.Tests.TopupTxMutants
