import LidoSRv3.Audit.Verity.TopupTx
import LidoSRv3.Audit.Source.TopupParentCorrespondence
import LidoSRv3.Audit.Guarantees.PTopup1

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

/-! ## Wave 4/5: guard-discharge examples and kill-line mutants (abstract parent plane)

The three `guard_discharge_at_*` theorems are *positive controls*: each
projects one conjunct of the registered parent
`LidoSRv3.Audit.Guarantees.PTopup1.source_topup_conserves_and_rolls_back` at a
concrete witness, confirming the HONEST `SolidityTopup.run` satisfies that
conjunct there.  (Waves 1--3 named them `kill_*`; that was a misnomer -- a
projection of the parent's own conclusion refutes nothing.)

The four `…_kill_line_refutes_parent` theorems are the real kill-lines.  Each
rests on a MUTANT of the parent's own model defined in this file -- a copy of
`SolidityTopup.run` with exactly one guard deleted or one reading changed --
and proves the NEGATION, on the mutant at a concrete witness, of the same
predicate the corresponding parent conjunct proves for the honest model.

Wave 5 made the conservation kill-line surgical.  Wave 4's
`mutantRunPushNoAssert` was a MULTI-edit mutant: it deleted the line 755
assert AND rewrote the pull field and balance-after to the wrapped reading, so
at `wrapInput` its lethality came from the pull rewrite, not the advertised
assert deletion (the honest exact-Nat assert was dead there).  Wave 5 routed
the on-chain `unchecked` reading through the honest `run` itself --
`SolidityTopup.accumulated` (the line 732 sum reduced mod 2^256) is now the
line 744 pull, the funded router balance, and the line 755 assert's reading --
so `mutantRunNoAssert` below differs from `run` by exactly ONE branch, and the
two characterization theorems pin that down in the P-DEPOSIT-1 style:
`mutantRunNoAssert_eq_run_of_assert_passing` (where the assert passes, the
mutant IS the honest run, branch for branch) and
`mutantRunNoAssert_commits_where_assert_fires` (where the honest run hits the
assert, the mutant commits the push the honest run rolls back).  The
wrap-ignoring reading survives as the assert-drop mutant's DUAL,
`mutantRunUnwrapped`: the conjunct (3) kill-line shows a model that ignores
the line 722 `unchecked` wrap commits the wrapping batch the honest run
reverts via the assert. -/

/-- Shared configuration for the abstract-plane witnesses: the pubkey
constants agree at 48, `gwei` and `MIN_DEPOSIT` are 1, and the `uint64` bound
is raised to 2^256 so the wrapping batch below passes the push loop. -/
private def killCfg : SourceTopupConfig := ⟨48, 48, 1, 1, uint256Modulus⟩

/-- A batch whose exact sum exceeds 2^256, so the on-chain `unchecked`
accumulator at source line 732 wraps.  Every limit, balance and cap is set
above the exact sum, so no OTHER guard fires at this witness. -/
private def wrapInput : SourceTopupInput :=
  { callerIsTopUpGateway := true, keyIndicesLength := 2, operatorIdsLength := 2,
    topUpLimits := [uint256Modulus + 1, uint256Modulus + 1],
    pubkeyLengths := [48, 48], moduleExists := true, moduleActive := true,
    wcTypeIsType2 := true, maxTopUpPerBlockGwei := uint256Modulus + 1,
    moduleAllocationEth := uint256Modulus + 1, lidoCanDeposit := true,
    allocations := [uint256Modulus - 1, 2], routerBalanceBefore := uint256Modulus,
    lidoDepositableEther := uint256Modulus + 1 }

/-- An unregistered-module input that passes every guard before source line
689 and commits once the tail is reached. -/
private def moduleMissingInput : SourceTopupInput :=
  { callerIsTopUpGateway := true, keyIndicesLength := 1, operatorIdsLength := 1,
    topUpLimits := [10], pubkeyLengths := [48], moduleExists := false,
    moduleActive := true, wcTypeIsType2 := true, maxTopUpPerBlockGwei := 100,
    moduleAllocationEth := 100, lidoCanDeposit := true,
    allocations := [5], routerBalanceBefore := 100,
    lidoDepositableEther := 100 }

/-- A non-type-2 withdrawal-credentials input that passes every guard before
source line 694 and commits once the tail is reached. -/
private def wcType1Input : SourceTopupInput :=
  { callerIsTopUpGateway := true, keyIndicesLength := 1, operatorIdsLength := 1,
    topUpLimits := [10], pubkeyLengths := [48], moduleExists := true,
    moduleActive := true, wcTypeIsType2 := false, maxTopUpPerBlockGwei := 100,
    moduleAllocationEth := 100, lidoCanDeposit := true,
    allocations := [5], routerBalanceBefore := 100,
    lidoDepositableEther := 100 }

/-- Positive control (NOT a kill-line): the honest wrap branch at `wrapInput`,
projected from the registered parent's third conjunct.  Wave 5 routed the
`unchecked` accumulator through `run` itself, so the projection now shows the
honest `run` REVERTING at the wrapping witness -- and the second conjunct pins
down that the revert is the line 755 `assert` firing (the wrapped pull `1`
against the exact push `2^256 + 1`), not any earlier guard. -/
theorem guard_discharge_at_wrapping_input :
    (run killCfg wrapInput).reverts = true ∧
      run killCfg wrapInput = .revertAssertBalanceUnchanged :=
  ⟨(LidoSRv3.Audit.Guarantees.PTopup1.source_topup_conserves_and_rolls_back
      (State := Unit) killCfg wrapInput () () [] ⟨[], [], []⟩).2.2.1
    (by unfold NoUncheckedWrap; decide),
   by decide⟩

/-- Positive control (NOT a kill-line): the honest `run` rejects the
unregistered-module witness, projected from the registered parent's second
conjunct. -/
theorem guard_discharge_at_unregistered_module_input :
    run killCfg moduleMissingInput = .revertStakingModuleUnregistered :=
  (LidoSRv3.Audit.Guarantees.PTopup1.source_topup_conserves_and_rolls_back
      (State := Unit) killCfg moduleMissingInput () () [] ⟨[], [], []⟩).2.1
    (by decide) (by decide) (by decide) (by decide) (by decide)

/-- Positive control (NOT a kill-line): the honest `run` rejects the
non-type-2 witness, projected from the registered parent's fourth conjunct. -/
theorem guard_discharge_at_non_type2_wc_input :
    run killCfg wcType1Input = .revertWrongWithdrawalCredentialsType :=
  (LidoSRv3.Audit.Guarantees.PTopup1.source_topup_conserves_and_rolls_back
      (State := Unit) killCfg wcType1Input () () [] ⟨[], [], []⟩).2.2.2
    (by decide) (by decide) (by decide) (by decide) (by decide) (by decide) (by decide)

/-- MUTANT of the value-moving tail `SolidityTopup.runPush`: the
`assert(etherBalanceBeforeDeposits == etherBalanceAfterDeposits)` at source
line 755 is deleted.  SINGLE edit, nothing else: the line 744 pull still reads
the on-chain `unchecked` accumulator (`SolidityTopup.accumulated`, reduced mod
2^256), the funded-balance guard at `BeaconChainDepositor.sol` line 106 still
reads it too, the commit still records the wrapped pull against the exact
push, and every other guard is unchanged.  (Wave 4's version of this mutant
additionally rewrote the pull field and balance-after to the wrapped reading;
wave 5 routed that reading through the honest `runPush` itself, so the assert
deletion is now the ONLY difference.) -/
private def mutantRunPushNoAssert (cfg : SourceTopupConfig) (inp : SourceTopupInput) : Outcome :=
  if inp.lidoCanDeposit = false then
    .revertLidoCannotDeposit
  else if totalAllocated inp = 0 then
    .revertLidoZeroAmount
  else if inp.lidoDepositableEther < totalAllocated inp then
    .revertLidoNotEnoughEther
  else if inp.pubkeyLengths.length ≠ inp.allocations.length then
    .revertArrayLengthMismatch
  else match pushLoop cfg inp.pubkeyLengths inp.allocations with
    | some o => o
    | none =>
      if inp.routerBalanceBefore + accumulated inp < pushedValue inp then
        .revertInsufficientRouterBalance
      else
        .committedTopUp inp.pubkeyLengths.length (accumulated inp) (pushedValue inp)
          (routerBalanceAfter inp)

/-- MUTANT of `SolidityTopup.run`: the guard chain is identical, but the
value-moving tail is `mutantRunPushNoAssert`. -/
private def mutantRunNoAssert (cfg : SourceTopupConfig) (inp : SourceTopupInput) : Outcome :=
  if inp.callerIsTopUpGateway = false then
    .revertNotAuthorized
  else if inp.keyIndicesLength = 0 then
    .revertEmptyKeysList
  else if inp.operatorIdsLength ≠ inp.keyIndicesLength
      ∨ inp.topUpLimits.length ≠ inp.keyIndicesLength
      ∨ inp.pubkeyLengths.length ≠ inp.keyIndicesLength then
    .revertArraysLengthMismatch
  else if inp.pubkeyLengths.any (fun l => l != cfg.pubkeyLength) then
    .revertWrongPubkeyLength
  else if inp.moduleExists = false then
    .revertStakingModuleUnregistered
  else if inp.moduleActive = false then
    .revertStakingModuleNotActive
  else if inp.wcTypeIsType2 = false then
    .revertWrongWithdrawalCredentialsType
  else if cfg.gwei = 0 then
    .revertGweiModuloByZero
  else if smDepositableEthAmountRounded cfg inp = 0 ∧ inp.lidoCanDeposit = false then
    .revertLidoDepositsPaused
  else match allocationLoop cfg inp.allocations inp.topUpLimits with
    | some o => o
    | none =>
      if smDepositableEthAmountRounded cfg inp < totalAllocated inp then
        .revertModuleReturnExceedTarget
      else if totalAllocated inp = 0 then
        .committedNoTopUp
      else
        mutantRunPushNoAssert cfg inp

/-- The mutation is surgical: wherever the line 755 assert passes, the mutant
coincides with the honest routed `run`, branch for branch. -/
theorem mutantRunNoAssert_eq_run_of_assert_passing {cfg : SourceTopupConfig}
    {inp : SourceTopupInput} (h : accumulated inp = pushedValue inp) :
    mutantRunNoAssert cfg inp = run cfg inp := by
  rw [mutantRunNoAssert, run]
  by_cases hAuth : inp.callerIsTopUpGateway = false
  · rw [if_pos hAuth, if_pos hAuth]
  rw [if_neg hAuth, if_neg hAuth]
  by_cases hKeys : inp.keyIndicesLength = 0
  · rw [if_pos hKeys, if_pos hKeys]
  rw [if_neg hKeys, if_neg hKeys]
  by_cases hLens : inp.operatorIdsLength ≠ inp.keyIndicesLength
      ∨ inp.topUpLimits.length ≠ inp.keyIndicesLength
      ∨ inp.pubkeyLengths.length ≠ inp.keyIndicesLength
  · rw [if_pos hLens, if_pos hLens]
  rw [if_neg hLens, if_neg hLens]
  by_cases hPub : (inp.pubkeyLengths.any fun l => l != cfg.pubkeyLength) = true
  · rw [if_pos hPub, if_pos hPub]
  rw [if_neg hPub, if_neg hPub]
  by_cases hMod : inp.moduleExists = false
  · rw [if_pos hMod, if_pos hMod]
  rw [if_neg hMod, if_neg hMod]
  by_cases hActive : inp.moduleActive = false
  · rw [if_pos hActive, if_pos hActive]
  rw [if_neg hActive, if_neg hActive]
  by_cases hWc : inp.wcTypeIsType2 = false
  · rw [if_pos hWc, if_pos hWc]
  rw [if_neg hWc, if_neg hWc]
  by_cases hGwei : cfg.gwei = 0
  · rw [if_pos hGwei, if_pos hGwei]
  rw [if_neg hGwei, if_neg hGwei]
  by_cases hPaused : smDepositableEthAmountRounded cfg inp = 0 ∧ inp.lidoCanDeposit = false
  · rw [if_pos hPaused, if_pos hPaused]
  rw [if_neg hPaused, if_neg hPaused]
  split
  · rename_i o hp; rw [hp]
  · rename_i hp; rw [hp]
    by_cases hOver : smDepositableEthAmountRounded cfg inp < totalAllocated inp
    · rw [if_pos hOver, if_pos hOver]
    rw [if_neg hOver, if_neg hOver]
    by_cases hZero : totalAllocated inp = 0
    · rw [if_pos hZero, if_pos hZero]
    rw [if_neg hZero, if_neg hZero]
    rw [mutantRunPushNoAssert, runPush]
    by_cases hCan : inp.lidoCanDeposit = false
    · rw [if_pos hCan, if_pos hCan]
    rw [if_neg hCan, if_neg hCan]
    by_cases hZeroTail : totalAllocated inp = 0
    · rw [if_pos hZeroTail, if_pos hZeroTail]
    rw [if_neg hZeroTail, if_neg hZeroTail]
    by_cases hLiq : inp.lidoDepositableEther < totalAllocated inp
    · rw [if_pos hLiq, if_pos hLiq]
    rw [if_neg hLiq, if_neg hLiq]
    by_cases hLen : inp.pubkeyLengths.length ≠ inp.allocations.length
    · rw [if_pos hLen, if_pos hLen]
    rw [if_neg hLen, if_neg hLen]
    split
    · rename_i o hp2; rw [hp2]
    · rename_i hp2; rw [hp2]
      by_cases hBal : inp.routerBalanceBefore + accumulated inp < pushedValue inp
      · rw [if_pos hBal, if_pos hBal]
      rw [if_neg hBal, if_neg hBal]
      rw [if_neg (not_not_intro h)]

/-- And the mutation bites exactly where the honest run hits the line 755
assert: there, and only there, the mutant commits the push the honest run
rolls back. -/
theorem mutantRunNoAssert_commits_where_assert_fires {cfg : SourceTopupConfig}
    {inp : SourceTopupInput} (hRun : run cfg inp = .revertAssertBalanceUnchanged) :
    mutantRunNoAssert cfg inp = .committedTopUp inp.pubkeyLengths.length
      (accumulated inp) (pushedValue inp) (routerBalanceAfter inp) := by
  rw [run] at hRun
  rw [mutantRunNoAssert]
  by_cases hAuth : inp.callerIsTopUpGateway = false
  · rw [if_pos hAuth] at hRun; cases hRun
  rw [if_neg hAuth] at hRun; rw [if_neg hAuth]
  by_cases hKeys : inp.keyIndicesLength = 0
  · rw [if_pos hKeys] at hRun; cases hRun
  rw [if_neg hKeys] at hRun; rw [if_neg hKeys]
  by_cases hLens : inp.operatorIdsLength ≠ inp.keyIndicesLength
      ∨ inp.topUpLimits.length ≠ inp.keyIndicesLength
      ∨ inp.pubkeyLengths.length ≠ inp.keyIndicesLength
  · rw [if_pos hLens] at hRun; cases hRun
  rw [if_neg hLens] at hRun; rw [if_neg hLens]
  by_cases hPub : (inp.pubkeyLengths.any fun l => l != cfg.pubkeyLength) = true
  · rw [if_pos hPub] at hRun; cases hRun
  rw [if_neg hPub] at hRun; rw [if_neg hPub]
  by_cases hMod : inp.moduleExists = false
  · rw [if_pos hMod] at hRun; cases hRun
  rw [if_neg hMod] at hRun; rw [if_neg hMod]
  by_cases hActive : inp.moduleActive = false
  · rw [if_pos hActive] at hRun; cases hRun
  rw [if_neg hActive] at hRun; rw [if_neg hActive]
  by_cases hWc : inp.wcTypeIsType2 = false
  · rw [if_pos hWc] at hRun; cases hRun
  rw [if_neg hWc] at hRun; rw [if_neg hWc]
  by_cases hGwei : cfg.gwei = 0
  · rw [if_pos hGwei] at hRun; cases hRun
  rw [if_neg hGwei] at hRun; rw [if_neg hGwei]
  by_cases hPaused : smDepositableEthAmountRounded cfg inp = 0 ∧ inp.lidoCanDeposit = false
  · rw [if_pos hPaused] at hRun; cases hRun
  rw [if_neg hPaused] at hRun; rw [if_neg hPaused]
  split at hRun
  · rename_i p hp
    rcases allocationLoop_range _ _ hp with h' | h' | h' <;> rw [h'] at hRun <;> cases hRun
  · rename_i hp
    rw [hp]
    by_cases hOver : smDepositableEthAmountRounded cfg inp < totalAllocated inp
    · rw [if_pos hOver] at hRun; cases hRun
    rw [if_neg hOver] at hRun; rw [if_neg hOver]
    by_cases hZero : totalAllocated inp = 0
    · rw [if_pos hZero] at hRun; cases hRun
    rw [if_neg hZero] at hRun; rw [if_neg hZero]
    rw [runPush] at hRun; rw [mutantRunPushNoAssert]
    by_cases hCan : inp.lidoCanDeposit = false
    · rw [if_pos hCan] at hRun; cases hRun
    rw [if_neg hCan] at hRun; rw [if_neg hCan]
    by_cases hZeroTail : totalAllocated inp = 0
    · rw [if_pos hZeroTail] at hRun; cases hRun
    rw [if_neg hZeroTail] at hRun; rw [if_neg hZeroTail]
    by_cases hLiq : inp.lidoDepositableEther < totalAllocated inp
    · rw [if_pos hLiq] at hRun; cases hRun
    rw [if_neg hLiq] at hRun; rw [if_neg hLiq]
    by_cases hLen : inp.pubkeyLengths.length ≠ inp.allocations.length
    · rw [if_pos hLen] at hRun; cases hRun
    rw [if_neg hLen] at hRun; rw [if_neg hLen]
    split at hRun
    · rename_i p hp2
      rcases pushLoop_range _ _ hp2 with h' | h' | h' <;> rw [h'] at hRun <;> cases hRun
    · rename_i hp2
      rw [hp2]
      by_cases hBal : inp.routerBalanceBefore + accumulated inp < pushedValue inp
      · rw [if_pos hBal] at hRun; cases hRun
      rw [if_neg hBal] at hRun; rw [if_neg hBal]

/-- MUTANT of `SolidityTopup.run`: the `_requireModuleIdExists` guard at
`SRUtils.sol` lines 45--47 (reached from source line 689) is deleted, so an
unregistered module falls through to the later guards.  Every other guard and
the honest `runPush` tail are unchanged. -/
private def mutantRunNoModuleGuard (cfg : SourceTopupConfig) (inp : SourceTopupInput) : Outcome :=
  if inp.callerIsTopUpGateway = false then
    .revertNotAuthorized
  else if inp.keyIndicesLength = 0 then
    .revertEmptyKeysList
  else if inp.operatorIdsLength ≠ inp.keyIndicesLength
      ∨ inp.topUpLimits.length ≠ inp.keyIndicesLength
      ∨ inp.pubkeyLengths.length ≠ inp.keyIndicesLength then
    .revertArraysLengthMismatch
  else if inp.pubkeyLengths.any (fun l => l != cfg.pubkeyLength) then
    .revertWrongPubkeyLength
  else if inp.moduleActive = false then
    .revertStakingModuleNotActive
  else if inp.wcTypeIsType2 = false then
    .revertWrongWithdrawalCredentialsType
  else if cfg.gwei = 0 then
    .revertGweiModuloByZero
  else if smDepositableEthAmountRounded cfg inp = 0 ∧ inp.lidoCanDeposit = false then
    .revertLidoDepositsPaused
  else match allocationLoop cfg inp.allocations inp.topUpLimits with
    | some o => o
    | none =>
      if smDepositableEthAmountRounded cfg inp < totalAllocated inp then
        .revertModuleReturnExceedTarget
      else if totalAllocated inp = 0 then
        .committedNoTopUp
      else
        runPush cfg inp

/-- MUTANT of `SolidityTopup.run`: the `_requireWCType2` guard at
`SRUtils.sol` lines 41--43 (reached from source line 694) is deleted, so a
non-type-2 module falls through to the later guards.  Every other guard and
the honest `runPush` tail are unchanged. -/
private def mutantRunNoWcGuard (cfg : SourceTopupConfig) (inp : SourceTopupInput) : Outcome :=
  if inp.callerIsTopUpGateway = false then
    .revertNotAuthorized
  else if inp.keyIndicesLength = 0 then
    .revertEmptyKeysList
  else if inp.operatorIdsLength ≠ inp.keyIndicesLength
      ∨ inp.topUpLimits.length ≠ inp.keyIndicesLength
      ∨ inp.pubkeyLengths.length ≠ inp.keyIndicesLength then
    .revertArraysLengthMismatch
  else if inp.pubkeyLengths.any (fun l => l != cfg.pubkeyLength) then
    .revertWrongPubkeyLength
  else if inp.moduleExists = false then
    .revertStakingModuleUnregistered
  else if inp.moduleActive = false then
    .revertStakingModuleNotActive
  else if cfg.gwei = 0 then
    .revertGweiModuloByZero
  else if smDepositableEthAmountRounded cfg inp = 0 ∧ inp.lidoCanDeposit = false then
    .revertLidoDepositsPaused
  else match allocationLoop cfg inp.allocations inp.topUpLimits with
    | some o => o
    | none =>
      if smDepositableEthAmountRounded cfg inp < totalAllocated inp then
        .revertModuleReturnExceedTarget
      else if totalAllocated inp = 0 then
        .committedNoTopUp
      else
        runPush cfg inp

/-- MUTANT of the value-moving tail `SolidityTopup.runPush`, the DUAL of the
assert-drop mutant: the `unchecked` wrap at source line 722 is ignored and the
line 744 pull, the funded-balance guard, and the line 755 assert all read the
exact `Nat` sum (`totalAllocated`) instead of the wrapped `accumulated`.
This is exactly the pre-wave-5 honest `runPush`; it still carries information
as the wrap discharge's dual -- on this reading a wrapping batch COMMITS,
which is what the registered parent's third conjunct rules out for the honest
routed model. -/
private def mutantRunPushUnwrapped (cfg : SourceTopupConfig) (inp : SourceTopupInput) : Outcome :=
  if inp.lidoCanDeposit = false then
    .revertLidoCannotDeposit
  else if totalAllocated inp = 0 then
    .revertLidoZeroAmount
  else if inp.lidoDepositableEther < totalAllocated inp then
    .revertLidoNotEnoughEther
  else if inp.pubkeyLengths.length ≠ inp.allocations.length then
    .revertArrayLengthMismatch
  else match pushLoop cfg inp.pubkeyLengths inp.allocations with
    | some o => o
    | none =>
      if inp.routerBalanceBefore + totalAllocated inp < pushedValue inp then
        .revertInsufficientRouterBalance
      else if totalAllocated inp ≠ pushedValue inp then
        .revertAssertBalanceUnchanged
      else
        .committedTopUp inp.pubkeyLengths.length (totalAllocated inp) (pushedValue inp)
          (inp.routerBalanceBefore + totalAllocated inp - pushedValue inp)

/-- MUTANT of `SolidityTopup.run`, the wrap-discharge dual: the guard chain is
identical, but the value-moving tail is `mutantRunPushUnwrapped`. -/
private def mutantRunUnwrapped (cfg : SourceTopupConfig) (inp : SourceTopupInput) : Outcome :=
  if inp.callerIsTopUpGateway = false then
    .revertNotAuthorized
  else if inp.keyIndicesLength = 0 then
    .revertEmptyKeysList
  else if inp.operatorIdsLength ≠ inp.keyIndicesLength
      ∨ inp.topUpLimits.length ≠ inp.keyIndicesLength
      ∨ inp.pubkeyLengths.length ≠ inp.keyIndicesLength then
    .revertArraysLengthMismatch
  else if inp.pubkeyLengths.any (fun l => l != cfg.pubkeyLength) then
    .revertWrongPubkeyLength
  else if inp.moduleExists = false then
    .revertStakingModuleUnregistered
  else if inp.moduleActive = false then
    .revertStakingModuleNotActive
  else if inp.wcTypeIsType2 = false then
    .revertWrongWithdrawalCredentialsType
  else if cfg.gwei = 0 then
    .revertGweiModuloByZero
  else if smDepositableEthAmountRounded cfg inp = 0 ∧ inp.lidoCanDeposit = false then
    .revertLidoDepositsPaused
  else match allocationLoop cfg inp.allocations inp.topUpLimits with
    | some o => o
    | none =>
      if smDepositableEthAmountRounded cfg inp < totalAllocated inp then
        .revertModuleReturnExceedTarget
      else if totalAllocated inp = 0 then
        .committedNoTopUp
      else
        mutantRunPushUnwrapped cfg inp

/-- KILL-LINE for the registered parent's first conjunct (conservation).  On
`mutantRunNoAssert` -- the parent's own routed model with ONLY the line 755
assert deleted (`mutantRunNoAssert_eq_run_of_assert_passing` /
`mutantRunNoAssert_commits_where_assert_fires` pin the single edit down) --
the wrapping batch `wrapInput` COMMITS with `pulled = 1 ≠ 2^256 + 1 = pushed`:
the wrapped pull against the exact push, the negation of the `pulled = pushed`
predicate the parent proves for the honest `run`.  The honest `run` cannot
exhibit this: at the same witness it hits the line 755 assert
(`guard_discharge_at_wrapping_input`), so the assert deletion alone is what
lets the wrap through. -/
theorem dropped_conservation_assert_kill_line_refutes_parent :
    (mutantRunNoAssert killCfg wrapInput).reverts = false ∧
      (mutantRunNoAssert killCfg wrapInput).pulled ≠
        (mutantRunNoAssert killCfg wrapInput).pushed := by
  decide

/-- KILL-LINE for the registered parent's second conjunct (module guard).  At
`moduleMissingInput` every antecedent of the conjunct holds, yet the mutant
without the `moduleExists` require does NOT return
`.revertStakingModuleUnregistered` -- it commits.  Antecedents conjoined with
the negated consequent refute the conjunct's implication on the mutant. -/
theorem dropped_module_guard_kill_line_refutes_parent :
    moduleMissingInput.moduleExists = false ∧
      moduleMissingInput.callerIsTopUpGateway = true ∧
      moduleMissingInput.keyIndicesLength ≠ 0 ∧
      ¬ (moduleMissingInput.operatorIdsLength ≠ moduleMissingInput.keyIndicesLength
          ∨ moduleMissingInput.topUpLimits.length ≠ moduleMissingInput.keyIndicesLength
          ∨ moduleMissingInput.pubkeyLengths.length ≠ moduleMissingInput.keyIndicesLength) ∧
      moduleMissingInput.pubkeyLengths.any (fun l => l != killCfg.pubkeyLength) = false ∧
      (mutantRunNoModuleGuard killCfg moduleMissingInput).reverts = false ∧
      mutantRunNoModuleGuard killCfg moduleMissingInput ≠ .revertStakingModuleUnregistered := by
  decide

/-- KILL-LINE for the registered parent's fourth conjunct (WC-type guard).  At
`wcType1Input` every antecedent of the conjunct holds, yet the mutant without
the `wcTypeIsType2` require does NOT return
`.revertWrongWithdrawalCredentialsType` -- it commits.  Antecedents conjoined
with the negated consequent refute the conjunct's implication on the
mutant. -/
theorem dropped_wc_guard_kill_line_refutes_parent :
    wcType1Input.wcTypeIsType2 = false ∧
      wcType1Input.callerIsTopUpGateway = true ∧
      wcType1Input.keyIndicesLength ≠ 0 ∧
      ¬ (wcType1Input.operatorIdsLength ≠ wcType1Input.keyIndicesLength
          ∨ wcType1Input.topUpLimits.length ≠ wcType1Input.keyIndicesLength
          ∨ wcType1Input.pubkeyLengths.length ≠ wcType1Input.keyIndicesLength) ∧
      wcType1Input.pubkeyLengths.any (fun l => l != killCfg.pubkeyLength) = false ∧
      wcType1Input.moduleExists = true ∧
      wcType1Input.moduleActive = true ∧
      (mutantRunNoWcGuard killCfg wcType1Input).reverts = false ∧
      mutantRunNoWcGuard killCfg wcType1Input ≠ .revertWrongWithdrawalCredentialsType := by
  decide

/-- KILL-LINE for the registered parent's third conjunct (wrap discharge), the
assert-drop mutant's DUAL.  At the wrapping witness `wrapInput` the conjunct's
antecedent holds and the honest routed `run` reverts -- via the line 755
assert, as `guard_discharge_at_wrapping_input` pins -- but the wrap-ignoring
mutant COMMITS with `pulled = pushed = 2^256 + 1`: the conjunct's consequent
fails on the mutant reading.  Routing the `unchecked` accumulator through
`run`'s value-moving tail is therefore load-bearing for the discharge --
exactly the fidelity gap wave 4 recorded and wave 5 closed. -/
theorem unwrapped_accumulator_kill_line_refutes_parent :
    ¬ NoUncheckedWrap wrapInput ∧
      run killCfg wrapInput = .revertAssertBalanceUnchanged ∧
      (mutantRunUnwrapped killCfg wrapInput).reverts = false ∧
      (mutantRunUnwrapped killCfg wrapInput).pulled =
        (mutantRunUnwrapped killCfg wrapInput).pushed := by
  unfold NoUncheckedWrap
  decide

end LidoSRv3.Tests.TopupTxMutants
