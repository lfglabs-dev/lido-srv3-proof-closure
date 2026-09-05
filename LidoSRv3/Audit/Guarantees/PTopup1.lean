import LidoSRv3.Audit.Allocation
import LidoSRv3.Audit.Trace
import LidoSRv3.Audit.Source.TopupCorrespondence
import LidoSRv3.Audit.Source.TopupParentCorrespondence
import LidoSRv3.Audit.Verity.TopupTx
import LidoSRv3.Audit.Guarantees.Registry

namespace LidoSRv3.Audit.Guarantees.PTopup1

open LidoSRv3.Audit
open LidoSRv3.Audit.SolidityTopup

/-- The active registry exposes MODEL, SOURCE, and abstract rollback evidence.
The Verity transaction layer composes the pinned-source observables with the
executable external-call frames (post-#2362/#2365). -/
def guarantee : Guarantee := ⟨.pTopup1, [.model, .abstractTx, .source, .verityTx]⟩

/-- Model-side pin used by the executable call journal. Equality of this
literal with the production deployment is tracked separately as the OPEN
assumption `A-TOPUP-BEACON-ADDRESS`; this definition does not discharge that
deployment-provenance obligation. -/
def canonicalBeaconDepositAddress : Nat :=
  0x00000000219ab540356cBB839Cbe05303d7705Fa

/-- Source-shaped allocation-model ordering fact; extraction is not established. -/
theorem valid_result_preserves_router_order
    {snapshot : LidoSRv3.Audit.AllocationSnapshot}
    {result : LidoSRv3.Audit.AllocationResult} :
    LidoSRv3.Audit.validAllocationResult snapshot result →
      List.map LidoSRv3.Audit.AllocationResultRow.moduleId result.rows =
        List.map LidoSRv3.Audit.AllocationRow.moduleId snapshot.rows :=
  @LidoSRv3.Audit.valid_result_preserves_router_order snapshot result

/-- Abstract transaction rollback, not an executable EVM trace. -/
theorem revert_restores_state_value_and_logs {State : Type} :
    ∀ (tx : LidoSRv3.Audit.TxObservation State),
      tx.result = LidoSRv3.Audit.TxResult.reverted →
        tx.committedState = tx.before ∧ tx.committedTrace.ethMoves = [] ∧
          tx.committedTrace.logs = [] :=
  @LidoSRv3.Audit.revert_restores_state_value_and_logs State

/--
**Wrap-plane conjunct: wrap precludes a value-moving commit
(A-TOPUP-NOWRAP discharge), stated about `run` itself.**

Over-target (line 737), zero-sum (line 741), Lido-side amount guards
(`Lido.sol` 842/873), the line 744 pull, the funded router balance, and the
line 755 `assert` all read `accumulated` (`wrappedTotal = exactTotal % 2^256`).
A nonzero wrap still aborts on the value-moving tail.  A sum that wraps to
exactly zero takes the line 741 empty commit, so wrap-implies-revert is false.
The honest fact is `pulled = pushed = 0`.

Folded into `source_topup_conserves_and_rolls_back` below as its third
conjunct, so a regression here breaks the *registered* P-TOPUP-1 claim, not
only this standalone lemma. -/
theorem source_wrap_precludes_value_moving_commit
    (cfg : SourceTopupConfig) (inp : SourceTopupInput)
    (hWrap : ¬ NoUncheckedWrap inp) :
    (run cfg inp).pulled = 0 ∧ (run cfg inp).pushed = 0 :=
  run_wrap_precludes_value_moving_commit cfg inp hWrap

/--
**Wave 1: `moduleExists` guard is exercised.**

The `_requireModuleIdExists` guard at `SRUtils.sol` lines 45–47 (reached from
source line 689) is live in the registered interpreter: when the module does
not exist, `run` reverts with `revertStakingModuleUnregistered` regardless of
any other input.

Folded into `source_topup_conserves_and_rolls_back` below as its second
conjunct, so a regression here breaks the *registered* P-TOPUP-1 claim, not
only this standalone lemma. -/
theorem source_module_guard_required
    (cfg : SourceTopupConfig) (inp : SourceTopupInput)
    (hMod : inp.moduleExists = false)
    (hAuth : inp.callerIsTopUpGateway = true)
    (hKeys : inp.keyIndicesLength ≠ 0)
    (hLens : ¬(inp.operatorIdsLength ≠ inp.keyIndicesLength
        ∨ inp.topUpLimits.length ≠ inp.keyIndicesLength
        ∨ inp.pubkeyLengths.length ≠ inp.keyIndicesLength))
    (hPub : inp.pubkeyLengths.any (fun l => l != cfg.pubkeyLength) = false) :
    run cfg inp = .revertStakingModuleUnregistered := by
  simp only [run, hAuth, hKeys, hPub, hMod, ite_false, ite_true]
  simp at hLens
  simp [hLens.1, hLens.2.1, hLens.2.2]

/--
**Wave 1: `wcTypeIsType2` guard is exercised.**

The `_requireWCType2` guard at `SRUtils.sol` lines 41–43 (reached from source
line 694) is live: when withdrawal credentials are not type-2, `run` reverts
with `revertWrongWithdrawalCredentialsType`, provided earlier guards pass.

Folded into `source_topup_conserves_and_rolls_back` below as its fourth
conjunct, so a regression here breaks the *registered* P-TOPUP-1 claim, not
only this standalone lemma. -/
theorem source_wc_type2_guard_required
    (cfg : SourceTopupConfig) (inp : SourceTopupInput)
    (hWc : inp.wcTypeIsType2 = false)
    (hAuth : inp.callerIsTopUpGateway = true)
    (hKeys : inp.keyIndicesLength ≠ 0)
    (hLens : ¬(inp.operatorIdsLength ≠ inp.keyIndicesLength
        ∨ inp.topUpLimits.length ≠ inp.keyIndicesLength
        ∨ inp.pubkeyLengths.length ≠ inp.keyIndicesLength))
    (hPub : inp.pubkeyLengths.any (fun l => l != cfg.pubkeyLength) = false)
    (hMod : inp.moduleExists = true)
    (hActive : inp.moduleActive = true) :
    run cfg inp = .revertWrongWithdrawalCredentialsType := by
  simp only [run, hAuth, hKeys, hPub, hMod, hActive, hWc, ite_false, ite_true]
  simp at hLens
  simp [hLens.1, hLens.2.1, hLens.2.2]

/--
**The returndata guards of source lines 722--734 are exercised.**

`IStakingModuleV2.allocateDeposits` (source lines 717--718) is an *untrusted*
module call: its returndata is arbitrary.  The router guards it before any wei
moves -- the gwei alignment at source line 724 and the per-index
`_topUpLimits[i]` bound at source line 728, whose read panics when the module
returns more entries than there are keys.  This lemma is guard *liveness*: once
the earlier guards pass, whichever of those three the returndata trips is the
outcome of the whole call.

Folded into `source_topup_conserves_and_rolls_back` below as the first half of
its fifth conjunct, so deleting the loop from `run` breaks the *registered*
claim. -/
theorem source_allocation_guards_required
    (cfg : SourceTopupConfig) (inp : SourceTopupInput) (o : SolidityTopup.Outcome)
    (hAuth : inp.callerIsTopUpGateway = true)
    (hKeys : inp.keyIndicesLength ≠ 0)
    (hLens : ¬(inp.operatorIdsLength ≠ inp.keyIndicesLength
        ∨ inp.topUpLimits.length ≠ inp.keyIndicesLength
        ∨ inp.pubkeyLengths.length ≠ inp.keyIndicesLength))
    (hPub : inp.pubkeyLengths.any (fun l => l != cfg.pubkeyLength) = false)
    (hMod : inp.moduleExists = true)
    (hActive : inp.moduleActive = true)
    (hWc : inp.wcTypeIsType2 = true)
    (hGwei : cfg.gwei ≠ 0)
    (hPaused : ¬(smDepositableEthAmountRounded cfg inp = 0 ∧ inp.lidoCanDeposit = false))
    (hLoop : allocationLoop cfg inp.allocations inp.topUpLimits = some o) :
    run cfg inp = o := by
  unfold run
  rw [if_neg (by simp [hAuth]), if_neg hKeys, if_neg hLens, if_neg (by simp [hPub]),
    if_neg (by simp [hMod]), if_neg (by simp [hActive]), if_neg (by simp [hWc]),
    if_neg hGwei, if_neg hPaused, hLoop]

/--
**The aggregate over-target guard of source line 737 is exercised.**

Even a returndata array that passes every per-index guard is rejected when its
`unchecked` accumulation (source line 732, read mod 2^256 as
`SolidityTopup.accumulated`) exceeds the rounded module target.  This is the
sum guard the reviewers found uncovered.

Folded into `source_topup_conserves_and_rolls_back` below as the second half of
its fifth conjunct. -/
theorem source_over_target_guard_required
    (cfg : SourceTopupConfig) (inp : SourceTopupInput)
    (hAuth : inp.callerIsTopUpGateway = true)
    (hKeys : inp.keyIndicesLength ≠ 0)
    (hLens : ¬(inp.operatorIdsLength ≠ inp.keyIndicesLength
        ∨ inp.topUpLimits.length ≠ inp.keyIndicesLength
        ∨ inp.pubkeyLengths.length ≠ inp.keyIndicesLength))
    (hPub : inp.pubkeyLengths.any (fun l => l != cfg.pubkeyLength) = false)
    (hMod : inp.moduleExists = true)
    (hActive : inp.moduleActive = true)
    (hWc : inp.wcTypeIsType2 = true)
    (hGwei : cfg.gwei ≠ 0)
    (hPaused : ¬(smDepositableEthAmountRounded cfg inp = 0 ∧ inp.lidoCanDeposit = false))
    (hLoop : allocationLoop cfg inp.allocations inp.topUpLimits = none)
    (hOver : smDepositableEthAmountRounded cfg inp < accumulated inp) :
    run cfg inp = .revertModuleReturnExceedTarget := by
  unfold run
  rw [if_neg (by simp [hAuth]), if_neg hKeys, if_neg hLens, if_neg (by simp [hPub]),
    if_neg (by simp [hMod]), if_neg (by simp [hActive]), if_neg (by simp [hWc]),
    if_neg hGwei, if_neg hPaused, hLoop]
  exact if_pos hOver

/-! ## Vocabulary for the registered abstract statement

Each `abbrev` below names one clause of the English guarantee ("pulled =
pushed on the source-shaped run, and a reverting outcome maps to the abstract
`TxObservation` rollback.  An unregistered module or a non-type-2 module
reverts.  If the unchecked sum wraps mod 2^256, the run moves no wei.").  They
are `abbrev`s, never `def`s, so unfolding them gives back the very same `Prop`
and every projection (`.1`, `.2.1`, ...) and every kill-line in
`LidoSRv3.Tests.TopupTxMutants` keeps working unchanged. -/

/-- The wei pulled from Lido by the source-shaped run (source line 744). -/
abbrev pulled (cfg : SourceTopupConfig) (inp : SourceTopupInput) : Nat :=
  (run cfg inp).pulled

/-- The wei pushed to the beacon deposit contract by the source-shaped run
(`BeaconChainDepositor.sol` lines 79--107). -/
abbrev pushed (cfg : SourceTopupConfig) (inp : SourceTopupInput) : Nat :=
  (run cfg inp).pushed

/-- "pulled = pushed on the source-shaped run." -/
abbrev Conserves (cfg : SourceTopupConfig) (inp : SourceTopupInput) : Prop :=
  pulled cfg inp = pushed cfg inp

/-- "A reverting outcome maps to the abstract `TxObservation` rollback
(A-ABSTRACT-TX)": the committed state is `before`, and the committed trace has
no ETH move and no log. -/
abbrev RevertRestoresSnapshot {State : Type}
    (cfg : SourceTopupConfig) (inp : SourceTopupInput)
    (before after : State) (attempts : List CallAttempt) (trace : CommitTrace) : Prop :=
  (run cfg inp).reverts = true →
    (observation before after attempts trace (run cfg inp)).committedState = before ∧
      (observation before after attempts trace (run cfg inp)).committedTrace.ethMoves = [] ∧
      (observation before after attempts trace (run cfg inp)).committedTrace.logs = []

/-- Conjunct 1: "pulled = pushed on the source-shaped run, and a reverting
outcome maps to the abstract `TxObservation` rollback." -/
abbrev ConservesAndRollsBack {State : Type}
    (cfg : SourceTopupConfig) (inp : SourceTopupInput)
    (before after : State) (attempts : List CallAttempt) (trace : CommitTrace) : Prop :=
  Conserves cfg inp ∧ RevertRestoresSnapshot cfg inp before after attempts trace

/-- "Given well-formed inputs, `P`": the four `_validateTopUpInputs` guards of
source lines 761--782 (caller is the top-up gateway, nonzero key count, the
three arrays have the key count as length, every pubkey has the pinned length)
are assumed, curried exactly as the registered statement takes them, and then
`P` follows. -/
abbrev GivenWellFormedInputs (cfg : SourceTopupConfig) (inp : SourceTopupInput)
    (P : Prop) : Prop :=
  inp.callerIsTopUpGateway = true →
  inp.keyIndicesLength ≠ 0 →
  ¬(inp.operatorIdsLength ≠ inp.keyIndicesLength
      ∨ inp.topUpLimits.length ≠ inp.keyIndicesLength
      ∨ inp.pubkeyLengths.length ≠ inp.keyIndicesLength) →
  inp.pubkeyLengths.any (fun l => l != cfg.pubkeyLength) = false →
  P

/-- "Given a registered, active module, `P`": the `moduleExists` and
`moduleActive` guards of source lines 689--692 pass, and then `P` follows. -/
abbrev GivenActiveModule (inp : SourceTopupInput) (P : Prop) : Prop :=
  inp.moduleExists = true → inp.moduleActive = true → P

/-- Conjunct 2: "An unregistered module reverts" -- given well-formed inputs,
`moduleExists = false` makes `run` revert `revertStakingModuleUnregistered`. -/
abbrev UnregisteredModuleReverts (cfg : SourceTopupConfig) (inp : SourceTopupInput) : Prop :=
  inp.moduleExists = false →
    GivenWellFormedInputs cfg inp (run cfg inp = .revertStakingModuleUnregistered)

/-- Conjunct 3: "If the unchecked sum wraps mod 2^256, the run moves no wei"
(`pulled = pushed = 0`; A-TOPUP-NOWRAP discharge). -/
abbrev WrapMovesNoValue (cfg : SourceTopupConfig) (inp : SourceTopupInput) : Prop :=
  ¬ NoUncheckedWrap inp → pulled cfg inp = 0 ∧ pushed cfg inp = 0

/-- Conjunct 4: "A non-type-2 module reverts" -- given well-formed inputs and
an active module, `wcTypeIsType2 = false` makes `run` revert
`revertWrongWithdrawalCredentialsType`. -/
abbrev WrongWcTypeReverts (cfg : SourceTopupConfig) (inp : SourceTopupInput) : Prop :=
  inp.wcTypeIsType2 = false →
    GivenWellFormedInputs cfg inp
      (GivenActiveModule inp (run cfg inp = .revertWrongWithdrawalCredentialsType))

/-- Conjunct 5: "Under every earlier guard, `run` follows the allocation
loop": an allocation-loop failure is `run`'s outcome, and when the loop
passes but the unchecked total exceeds the rounded target, `run` reverts
`revertModuleReturnExceedTarget`. -/
abbrev RunFollowsAllocationLoop (cfg : SourceTopupConfig) (inp : SourceTopupInput) : Prop :=
  GivenWellFormedInputs cfg inp
    (GivenActiveModule inp
      (inp.wcTypeIsType2 = true →
        cfg.gwei ≠ 0 →
        ¬(smDepositableEthAmountRounded cfg inp = 0 ∧ inp.lidoCanDeposit = false) →
        (∀ o : SolidityTopup.Outcome,
            allocationLoop cfg inp.allocations inp.topUpLimits = some o → run cfg inp = o) ∧
          (allocationLoop cfg inp.allocations inp.topUpLimits = none →
            smDepositableEthAmountRounded cfg inp < accumulated inp →
            run cfg inp = .revertModuleReturnExceedTarget)))

/--
**P-TOPUP-1, abstract plane.**  pulled = pushed on the source-shaped run, and a
reverting outcome maps to the abstract `TxObservation` rollback
(A-ABSTRACT-TX).  An unregistered module or a non-type-2 module reverts.  If
the unchecked sum wraps mod 2^256, the run moves no wei.  Under every earlier
guard, `run` follows the allocation loop and its over-target check.

`run cfg inp` conserves `pulled = pushed`. If that run reverts, the abstract
`TxObservation` (`A-ABSTRACT-TX`) restores `before` and erases ETH moves and
logs.  The registered claim additionally folds in the wrap-plane discharge
(`A-TOPUP-NOWRAP` lives in its antecedent: wrap precludes a value-moving
commit) and the
`moduleExists`/`wcTypeIsType2` guard liveness facts as further conjuncts, so a
kill-line mutant that defeats any one of them falsifies *this* theorem -- the
one tracked as P-TOPUP-1's CHECKED abstract claim in `audit/guarantees.yaml`
-- and not merely a sibling lemma that the registry never cites.

Pinned-source conservation and rollback correspondence for the SRv3 beacon-chain
top-up push at `lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`:

* `contracts/0.8.25/sr/StakingRouter.sol`, `topUp`, lines 679--759;
* `contracts/0.8.25/sr/StakingRouter.sol`, `_validateTopUpInputs`, lines 761--782;
* `contracts/0.8.25/sr/StakingRouter.sol`, `_checkAppAuth`, lines 1177--1179;
* `contracts/0.8.25/sr/StakingRouter.sol`, `_getTopUpGateway`, lines 1169--1171;
* `contracts/0.8.25/sr/StakingRouter.sol`, `_getModuleState`, lines 1099--1107;
* `contracts/0.8.25/sr/SRUtils.sol`, `_requireWCType2`, lines 41--43;
* `contracts/0.8.25/sr/SRUtils.sol`, `_requireModuleIdExists`, lines 45--47;
* `contracts/0.8.25/sr/StakingRouter.sol`, `PUBKEY_LENGTH`, line 57;
* `contracts/0.8.25/lib/BeaconChainDepositor.sol`, `PUBLIC_KEY_LENGTH`, line 21;
* `contracts/0.8.25/lib/BeaconChainDepositor.sol`, `MIN_DEPOSIT`, line 28;
* `contracts/0.4.24/Lido.sol`, `withdrawDepositableEther`, lines 869--886;
* `contracts/0.4.24/Lido.sol`, `_spendDepositableEther`, lines 839--859;
* `contracts/0.8.25/lib/BeaconChainDepositor.sol`, `makeBeaconChainTopUp`,
  lines 66--108.

Two claims, one per half of the guarantee wording.

*Conservation.* On every branch of the source-shaped path -- each authorization,
input-validation, module-status, allocation-loop, Lido-side and per-key guard, the
empty-top-up early commit at source line 741, and the full push -- the wei pulled
from Lido at source line 744 equals the wei pushed to the beacon deposit contract
by the loop at `BeaconChainDepositor.sol` lines 79--107.

The pull is the on-chain `unchecked` reading of the line 732 accumulation (the
sum reduced mod 2^256, `SolidityTopup.accumulated`); the push is the exact
per-key total (`SolidityTopup.pushedValue`, with the
`if (amount == 0) continue` skip at `BeaconChainDepositor.sol` line 89 losing
nothing, per `SolidityTopup.loopPushed_eq_allocSum`).  On the commit branch the
two agree *because the line 755 `assert` has passed*: reaching the commit means
the wrapped pull equalled the exact push (`SolidityTopup.committed_topup_spec`),
and under an actual wrap a value-moving commit is unreachable -- the third
conjunct shows wrap precludes `pulled ≠ 0` (`SolidityTopup.run_wrap_precludes_value_moving_commit`).
Wrap-to-zero is a no-top-up commit, not a revert.  So
conservation here is genuinely assert-backed, not a same-array `Nat` coincidence,
and it still needs no deployment-configuration side condition: unlike the 32-ETH
deposit path (P-DEPOSIT-1), the pull and the push are two readings of the *same*
`_amounts` array, not a count multiplied by two separately-configured constants.

*Rollback.* Every guard on that path is a whole-transaction abort -- the pinned
span contains no `try`/`catch` and no failure-swallowing low-level call, and a
failing `assert` is a Solidity 0.8 `Panic(0x01)` -- so a reverting outcome maps
onto the abstract-transaction model's `.reverted` result, and
`revert_restores_state_value_and_logs` restores the pre-state and erases all
committed ETH moves and logs. That includes the
`_checkAppAuth(_getTopUpGateway())` at source line 686 -- whose helper bodies at
lines 1169--1171 and 1177--1179 are pinned above rather than assumed -- which is
modelled as the
*first* guard: `SolidityTopup.unauthorized_reverts` shows an unauthorized caller
reverts before the line 687 input validation, and
`SolidityTopup.committing_implies_authorized` shows neither committing branch is
reachable without the gateway. The branch correspondence therefore covers every
source execution rather than silently assuming an authorized caller.

Caveats, stated rather than hidden:

* Arithmetic is read as unbounded `Nat` (`A-SOURCE-SHAPED`): truncating `Nat`
  division matches EVM `DIV`, and the one place the pinned path can overflow --
  the `amount += _amounts[i]` at source line 732, inside the `unchecked` block
  opened at line 722 -- is modelled faithfully rather than assumed away: the
  over-target comparison at line 737, the zero-sum test at line 741, the
  Lido-side amount guards at `Lido.sol` lines 842/873, the line 744 pull, the
  funded router balance, and the line 755 `assert` all read the sum reduced
  mod 2^256 (`SolidityTopup.accumulated`, `wrappedTotal = exactTotal % 2^256`).
  Under a nonzero wrap the wrapped pull is strictly below the exact push, so
  the transaction aborts.  Under wrap-to-zero line 741 commits
  `committedNoTopUp`.  This theorem's third conjunct is the honest discharge:
  wrap precludes a value-moving commit
  (`SolidityTopup.run_wrap_precludes_value_moving_commit`).  On the no-wrap
  branch `source_balance_guards_discharged` shows the two value guards are
  unreachable, taking the no-wrap fact as an explicit hypothesis
  (`A-TOPUP-NOWRAP`) rather than a bounded-arithmetic proof, because the bound
  is not derivable from the pinned P-TOPUP-1 spans.
* The `moduleExists` and `wcTypeIsType2` guards (source lines 689 and 694) are
  not merely assumed live -- this theorem's second and fourth conjuncts prove
  each one reverts with its named `Outcome` constructor whenever the earlier
  guards pass and the named condition fails, so a regression that drops either
  guard from `run` breaks this registered theorem directly, not only a sibling
  lemma that the assurance registry never cites.
* The guards the router applies to the *untrusted* module returndata are
  covered by the fifth conjunct: the gwei alignment at source line 724, the
  per-index `_topUpLimits[i]` bound and its out-of-bounds panic at source line
  728, and the aggregate over-target comparison at source line 737 read on the
  line 732 `unchecked` accumulator.  Deleting the loop or the over-target
  branch from `run` refutes this theorem
  (`LidoSRv3.Tests.TopupTxMutants.dropped_allocation_guards_kill_line_refutes_parent`
  and `…dropped_over_target_guard_kill_line_refutes_parent`).  What the
  conjunct does *not* claim is anything about where the returndata came from:
  `_amounts` enters the model as an input, and the module-side allocation
  algorithm remains P-ALLOC-1/P-ALLOC-2.
* The empty-top-up branch at source line 741 is a *commit*, not a revert:
  `SolidityTopup.committedNoTopUp_is_not_a_rollback` records this, so no reader
  can mistake the rollback theorem for a claim that a zero-amount top-up aborts.
* The rollback half is stated against the abstract transaction model
  (`A-ABSTRACT-TX`), so the EVM plane stays open.
* Out of scope here and left open: the per-validator top-up *amount computation*
  and limit accounting (P-TOPUP-2), the allocation algorithm producing
  `_amounts` (P-ALLOC-1/2), and the SSZ deposit-data-root construction at
  `BeaconChainDepositor.sol` lines 120--146 (P-SSZ-1).
-/
theorem source_topup_conserves_and_rolls_back {State : Type}
    (cfg : SourceTopupConfig) (inp : SourceTopupInput)
    (before after : State) (attempts : List CallAttempt) (trace : CommitTrace) :
    ConservesAndRollsBack cfg inp before after attempts trace ∧
    UnregisteredModuleReverts cfg inp ∧
    WrapMovesNoValue cfg inp ∧
    WrongWcTypeReverts cfg inp ∧
    RunFollowsAllocationLoop cfg inp :=
  ⟨⟨run_conserves cfg inp, fun h => reverting_outcome_rolls_back before after attempts trace h⟩,
   fun hMod hAuth hKeys hLens hPub => source_module_guard_required cfg inp hMod hAuth hKeys hLens hPub,
   fun hWrap => source_wrap_precludes_value_moving_commit cfg inp hWrap,
   fun hWc hAuth hKeys hLens hPub hMod hActive =>
     source_wc_type2_guard_required cfg inp hWc hAuth hKeys hLens hPub hMod hActive,
   fun hAuth hKeys hLens hPub hMod hActive hWc hGwei hPaused =>
     ⟨fun o hLoop => source_allocation_guards_required cfg inp o hAuth hKeys hLens hPub hMod
        hActive hWc hGwei hPaused hLoop,
      fun hLoop hOver => source_over_target_guard_required cfg inp hAuth hKeys hLens hPub hMod
        hActive hWc hGwei hPaused hLoop hOver⟩⟩

/--
The `assert(etherBalanceBeforeTopUp == etherBalanceAfterTopUp)` at
`StakingRouter.sol` line 755 holds on the committing push branch: the router
forwards every pulled wei and retains none.
-/
theorem source_router_balance_unchanged
    (cfg : SourceTopupConfig) (inp : SourceTopupInput)
    {keys pulled pushed balanceAfter : Nat}
    (hRun : run cfg inp = .committedTopUp keys pulled pushed balanceAfter) :
    balanceAfter = inp.routerBalanceBefore :=
  (committed_balance_preserved hRun).2

/--
A reverting branch of the pinned path moves no wei in either direction: the pull
at source line 744 is strictly after every guard at lines 686--741, and the line
755 `assert` rolls the whole transaction back.
-/
theorem source_reverting_branch_moves_no_ether
    {o : SolidityTopup.Outcome} (h : o.reverts = true) :
    o.pulled = 0 ∧ o.pushed = 0 :=
  reverting_moves_no_ether h

/--
The two value-conservation guards on the pinned path are *discharged*, not
assumed: no input reaches the line 755 `assert` failure, and no input reaches a
push that exceeds the router's funded balance. This is strictly stronger than the
32-ETH deposit path, where the analogous assert is load-bearing and only holds
under a deployment-configuration side condition.

The honest reading of this pair is: given that the accumulation at source line
732 does not wrap, a top-up can never strand wei in the router *and* can never
attempt to push wei it does not hold. That no-wrap fact is carried as the
explicit `SolidityTopup.NoUncheckedWrap` hypothesis rather than left implicit,
because it is not derivable from the pinned P-TOPUP-1 spans -- the per-index cap
at source line 728 comes from `TopUpGateway` (P-TOPUP-2) and the key count is
unbounded here. It is recorded as `A-TOPUP-NOWRAP` in `audit/assumptions.yaml`,
and `SolidityTopup.totalAllocated_faithful` proves that under exactly this
hypothesis the source's `unchecked` accumulation and the model's `Nat` sum are
the same number, which is what makes the discharge a statement about line 732.
-/
theorem source_balance_guards_discharged
    (cfg : SourceTopupConfig) (inp : SourceTopupInput)
    (hNoWrap : NoUncheckedWrap inp) :
    run cfg inp ≠ .revertAssertBalanceUnchanged ∧
      run cfg inp ≠ .revertInsufficientRouterBalance :=
  ⟨run_ne_revertAssertBalanceUnchanged cfg inp hNoWrap,
    run_ne_revertInsufficientRouterBalance cfg inp hNoWrap⟩

/--
The bridge that makes `source_balance_guards_discharged` a claim about the
`unchecked` accumulation at `StakingRouter.sol` line 732 rather than only about
this module's `Nat` sum: under `NoUncheckedWrap` the two readings coincide.

This is the proved half of `A-TOPUP-NOWRAP`. The assumption is exactly the
`inp.NoUncheckedWrap` premise; everything downstream of it is checked.
-/
theorem source_unchecked_accumulation_faithful
    (inp : SourceTopupInput) (hNoWrap : NoUncheckedWrap inp) :
    allocSumUnchecked inp.allocations = totalAllocated inp :=
  totalAllocated_faithful hNoWrap

/--
In the pinned deployment the router's own pubkey-length validation at source
lines 777--779 discharges `BeaconChainDepositor`'s per-key check at
`BeaconChainDepositor.sol` lines 82--84, because `StakingRouter.PUBKEY_LENGTH`
(source line 57) and `BeaconChainDepositor.PUBLIC_KEY_LENGTH`
(`BeaconChainDepositor.sol` line 21) are both 48.

The hypothesis is discharged by `SolidityTopup.pinnedConfig_pubkey_lengths_agree`
rather than assumed, so a hypothetical redeployment that split the two constants
is a real falsifier and is not papered over.
-/
theorem source_pinned_config_discharges_pubkey_guard (inp : SourceTopupInput) :
    run pinnedConfig inp ≠ .revertInvalidPublicKeyLength :=
  run_ne_revertInvalidPublicKeyLength pinnedConfig_pubkey_lengths_agree

/--
Composed faithful `VERITY_TX` closure for the committing P-TOPUP-1 path.

The premise is the pinned source interpreter's committing classification; the
executable side independently folds `inp.allocations` through `writeMapUint`
and `writeSlot`, then runs two *real* Verity external-call frames
(`externalCallBindTo`) -- the zero-value Lido pull and one value-bearing
beacon push per nonzero allocation.  The journal is produced by execution, not
appended: `Verity.TopupTx.execute` never mentions `expectedCalls`.

The first conjunct compares outcome observables, and those observables now
include the journal's destination addresses, wei values, argument words and
order, plus the per-allocation mapping words -- so a misrouted call, a
corrupted amount, a dropped argument or a reordered batch all falsify it.
The final conjunct states rollback for every injected failure point, each of
which fires after real storage writes and, past the first, after a real
journalled and balance-debiting call frame.

`hLen` bounds the batch length by the word modulus; it is what makes the
per-allocation mapping keys injective, and a `List` longer than `2^256` has no
EVM counterpart.  `hAmt` is the uint256-word bound on each allocation; it is
strictly weaker than `NoUncheckedWrap` (which bounded the *sum*).  Wrap is
not assumed away: a wrap-to-zero commit is included, and a nonzero wrap is
excluded only because the source run reverts (`hCommit`).
-/
theorem verity_tx_simulates_source
    (cfg : SourceTopupConfig) (inp : SourceTopupInput)
    (state : Verity.ContractState)
    (hLen : inp.allocations.length ≤ uint256Modulus)
    (hAmt : ∀ a ∈ inp.allocations, a < uint256Modulus)
    (hCommit : (run cfg inp).reverts = false) :
    let before := Verity.TopupTx.entryFrame state
    Verity.TopupTx.observe before inp.allocations.length
        ((Verity.TopupTx.execute inp.allocations .none).run before) =
          Verity.TopupTx.sourceObservables inp.allocations ∧
      (run cfg inp).pulled =
        (Verity.TopupTx.sourceObservables inp.allocations).pulled ∧
      (run cfg inp).pushed =
        (Verity.TopupTx.sourceObservables inp.allocations).pushed ∧
      ∀ failure reason rollback,
        (Verity.TopupTx.execute inp.allocations failure).run before =
            .revert reason rollback →
          rollback = before := by
  dsimp
  have hObs :
      Verity.TopupTx.observe (Verity.TopupTx.entryFrame state) inp.allocations.length
        ((Verity.TopupTx.execute inp.allocations .none).run
          (Verity.TopupTx.entryFrame state)) =
        Verity.TopupTx.sourceObservables inp.allocations := by
    rcases committed_implies_nowrap_or_wrapped_zero hCommit with hNoWrap | hWrappedZero
    · exact Verity.TopupTx.execute_observes_source_from_entry inp.allocations state hNoWrap hLen
    · exact Verity.TopupTx.execute_observes_source_wrapped_zero_from_entry
        inp.allocations state hWrappedZero hLen hAmt
  refine ⟨hObs, ?_, ?_, ?_⟩
  · cases hRun : run cfg inp with
    | committedNoTopUp =>
        have hZero := committedNoTopUp_implies_zero_total hRun
        simpa [Outcome.pulled, Verity.TopupTx.sourceObservables, accumulated]
          using hZero.symm
    | committedTopUp keys pulled pushed balanceAfter =>
        have hSpec := committed_topup_spec hRun
        simpa [hRun, Outcome.pulled, Verity.TopupTx.sourceObservables, accumulated]
          using hSpec.2.2.2.1
    | _ => simp_all [Outcome.reverts]
  · cases hRun : run cfg inp with
    | committedNoTopUp =>
        have hZero := committedNoTopUp_implies_zero_total hRun
        simpa [Outcome.pushed, Verity.TopupTx.sourceObservables, accumulated]
          using hZero.symm
    | committedTopUp keys pulled pushed balanceAfter =>
        have hSpec := committed_topup_spec hRun
        have hPushed : pushed = accumulated inp :=
          (hSpec.2.2.2.2.2.1.symm).trans hSpec.2.2.2.1
        simpa [hRun, Outcome.pushed, Verity.TopupTx.sourceObservables, accumulated]
          using hPushed
    | _ => simp_all [Outcome.reverts]
  · intro failure reason rollback hRevert
    exact Verity.TopupTx.revert_restores_snapshot inp.allocations failure
      _ rollback reason hRevert

/-- Executed wrap-to-zero subcase on the Verity plane. Under an actual wrap
whose unchecked accumulator is zero, `execute` commits the empty pull/push
schedule and its observable journal is empty. The complementary nonzero-wrap
case is `verity_nonzero_wrap_reverts_and_restores` below; together they
partition wrapping batches. This theorem does not use `hCommit`. -/
theorem verity_wrap_to_zero_is_empty_commit
    (inp : SourceTopupInput) (state : Verity.ContractState)
    (_hWrap : ¬ NoUncheckedWrap inp)
    (hZero : allocSumUnchecked inp.allocations = 0)
    (hLen : inp.allocations.length ≤ uint256Modulus)
    (hAmt : ∀ a ∈ inp.allocations, a < uint256Modulus) :
    let before := Verity.TopupTx.entryFrame state
    Verity.TopupTx.observe before inp.allocations.length
        ((Verity.TopupTx.execute inp.allocations .none).run before) =
          Verity.TopupTx.sourceObservables inp.allocations ∧
      (Verity.TopupTx.sourceObservables inp.allocations).pulled = 0 ∧
      (Verity.TopupTx.sourceObservables inp.allocations).pushed = 0 ∧
      (Verity.TopupTx.sourceObservables inp.allocations).callNames = [] := by
  dsimp
  refine ⟨Verity.TopupTx.execute_observes_source_wrapped_zero_from_entry
    inp.allocations state hZero hLen hAmt, ?_⟩
  simp [Verity.TopupTx.sourceObservables, hZero]

/-- Executed nonzero-wrap witness retained as a concrete regression instance
of the universal close below. -/
theorem verity_nonzero_wrap_witness_reverts_and_restores
    (state : Verity.ContractState) :
    let before := Verity.TopupTx.entryFrame state
    ∃ reason,
      (Verity.TopupTx.execute [uint256Modulus - 1, 2] .none).run before =
          Verity.ContractResult.revert reason before ∧
        (Verity.TopupTx.observe before 2
          ((Verity.TopupTx.execute [uint256Modulus - 1, 2] .none).run before)).committed =
            false := by
  dsimp
  rcases Verity.TopupTx.execute_nonzero_wrap_witness_reverts state with
    ⟨reason, rollback, hRun, hRollback⟩
  subst rollback
  refine ⟨reason, hRun, ?_⟩
  rw [hRun]
  rfl

/-- Universal nonzero-wrap close on the Verity plane.  For every list of
uint256-word allocations, if the exact sum reaches the modulus while its
unchecked wrapped total is nonzero, the wrapped pull is strictly smaller than
the exact push schedule.  A real value-bearing frame therefore reverts,
`Contract.run` restores the entry snapshot, and the outcome is non-committing. -/
theorem verity_nonzero_wrap_reverts_and_restores
    (allocations : List Nat) (state : Verity.ContractState)
    (hWrap : uint256Modulus ≤ allocSum allocations)
    (hNz : allocSumUnchecked allocations ≠ 0)
    (hAmt : ∀ a ∈ allocations, a < uint256Modulus) :
    let before := Verity.TopupTx.entryFrame state
    ∃ reason,
      (Verity.TopupTx.execute allocations .none).run before =
          Verity.ContractResult.revert reason before ∧
        (Verity.TopupTx.observe before allocations.length
          ((Verity.TopupTx.execute allocations .none).run before)).committed = false :=
  Verity.TopupTx.execute_nonzero_wrap_reverts allocations state hWrap hNz hAmt

/-- Predicate packaged from the existing committing-source Verity parent. -/
def VerityCommittingSimulation (cfg : SourceTopupConfig) (inp : SourceTopupInput)
    (state : Verity.ContractState) : Prop :=
  let before := Verity.TopupTx.entryFrame state
  Verity.TopupTx.observe before inp.allocations.length
      ((Verity.TopupTx.execute inp.allocations .none).run before) =
        Verity.TopupTx.sourceObservables inp.allocations ∧
    (run cfg inp).pulled =
      (Verity.TopupTx.sourceObservables inp.allocations).pulled ∧
    (run cfg inp).pushed =
      (Verity.TopupTx.sourceObservables inp.allocations).pushed ∧
    ∀ failure reason rollback,
      (Verity.TopupTx.execute inp.allocations failure).run before =
          .revert reason rollback →
        rollback = before

/--
Executable returndata plane: what `Verity.TopupTx.executeGuarded` does with the
words `IStakingModuleV2.allocateDeposits` returns at source lines 717--718.

`verity_tx_simulates_source` above is stated about `Verity.TopupTx.execute`,
which takes the allocation array as a free argument -- it has no module frame
and no returndata guards.  This predicate is the correction, and it is
quantified over *every* returndata array, because the module is untrusted:

1. **Binding.**  `executeGuarded` journals the `allocateDeposits` frame and
   then runs the guard-and-spend stage on *that frame's* `returndata`.  The
   guarded array is not a separate input.
2. **Alignment / per-index limit / out-of-bounds fail closed**, each with the
   source guard's own name (`Verity.TopupTx.guardReason` pairs the executable
   revert string with the `SolidityTopup.Outcome` constructor), and
   `Contract.run` restores the entry snapshot.
3. **Aggregate over-target fails closed**, read on the same mod-2^256
   accumulator the source line 737 comparison uses.
4. **Liveness.**  When every guard passes, the transaction really runs: its
   observables are the pinned source schedule with the module frame at the
   head.  Without this the three fail-closed conjuncts would be satisfied by a
   transaction that always reverts.

Boundary, stated rather than hidden: Verity's single-contract `Contract`
surface has no callee, so the returned words are supplied by whoever
instantiates the frame rather than computed by an executed module.  Quantifying
over all returndata is the honest reading of an untrusted module, but it is not
an executed callee and nothing here claims otherwise; the module-side
allocation algorithm stays P-ALLOC-1/P-ALLOC-2. -/
def VerityGuardedReturndataSimulation (cfg : SourceTopupConfig)
    (call : Verity.TopupTx.TopupCall) (state : Verity.ContractState) : Prop :=
  let before := Verity.TopupTx.entryFrame state
  (∀ failure : Verity.TopupTx.FailurePoint,
      Verity.TopupTx.executeGuarded cfg call failure before =
        Verity.TopupTx.guardedStage cfg call.topUpLimits call.roundedTarget
            (Verity.TopupTx.allocateEntry call.keyCount call.moduleReturndata).returndata
            failure
          { before with
            calls := before.calls
              ++ [Verity.TopupTx.allocateEntry call.keyCount call.moduleReturndata] }) ∧
    (∀ (o : SolidityTopup.Outcome) (failure : Verity.TopupTx.FailurePoint),
        allocationLoop cfg call.moduleReturndata call.topUpLimits = some o →
          (Verity.TopupTx.executeGuarded cfg call failure).run before =
            Verity.ContractResult.revert (Verity.TopupTx.guardReason o) before) ∧
    (∀ failure : Verity.TopupTx.FailurePoint,
        allocationLoop cfg call.moduleReturndata call.topUpLimits = none →
          call.roundedTarget < allocSumUnchecked call.moduleReturndata →
          (Verity.TopupTx.executeGuarded cfg call failure).run before =
            Verity.ContractResult.revert "ModuleReturnExceedTarget" before) ∧
    (allocationLoop cfg call.moduleReturndata call.topUpLimits = none →
      ¬ call.roundedTarget < allocSumUnchecked call.moduleReturndata →
      allocSum call.moduleReturndata < uint256Modulus →
      call.moduleReturndata.length ≤ uint256Modulus →
      Verity.TopupTx.observe before call.moduleReturndata.length
          ((Verity.TopupTx.executeGuarded cfg call .none).run before) =
        Verity.TopupTx.guardedObservables call)

/-! ## Vocabulary for the registered Verity statement -/

/-- "Any nonzero wrapping batch reverts without moving value and restores the
snapshot": for every list of uint256 words whose exact sum reaches the modulus
while its unchecked total is nonzero, `execute` reverts, `Contract.run` hands
back the entry frame, and the observation is non-committing. -/
abbrev NonzeroWrapRevertsAndRestores (state : Verity.ContractState) : Prop :=
  ∀ allocations : List Nat,
    uint256Modulus ≤ allocSum allocations →
    allocSumUnchecked allocations ≠ 0 →
    (∀ a ∈ allocations, a < uint256Modulus) →
    (let before := Verity.TopupTx.entryFrame state
      ∃ reason,
        (Verity.TopupTx.execute allocations .none).run before =
            Verity.ContractResult.revert reason before ∧
          (Verity.TopupTx.observe before allocations.length
            ((Verity.TopupTx.execute allocations .none).run before)).committed = false)

/-- "Every `allocateDeposits` return is guarded": the returndata-conditioned
module-call plane holds for every possible top-up call. -/
abbrev EveryReturndataIsGuarded (cfg : SourceTopupConfig)
    (state : Verity.ContractState) : Prop :=
  ∀ call : Verity.TopupTx.TopupCall, VerityGuardedReturndataSimulation cfg call state

/-- **P-TOPUP-1, Verity plane.**  If the source run commits and each allocation
is a uint256 word, `observe` of `execute` equals the source observables (with
`pulled`/`pushed` matching and every injected failure rolling back to the entry
snapshot); any nonzero wrapping batch reverts without moving value and restores
the snapshot; and every `allocateDeposits` return is guarded.

Registered Verity parent: the full committing-source correspondence,
including universal injected-failure rollback, conjoined with the universal
nonzero-wrap revert/non-commit/snapshot-restore close above and with the
returndata-conditioned module-call plane, quantified over every possible
`allocateDeposits` return. -/
theorem verity_tx_simulates_source_with_nonzero_wrap_close
    (cfg : SourceTopupConfig) (inp : SourceTopupInput)
    (state : Verity.ContractState)
    (hLen : inp.allocations.length ≤ uint256Modulus)
    (hAmt : ∀ a ∈ inp.allocations, a < uint256Modulus)
    (hCommit : (run cfg inp).reverts = false) :
    VerityCommittingSimulation cfg inp state ∧
      NonzeroWrapRevertsAndRestores state ∧
      EveryReturndataIsGuarded cfg state :=
  ⟨verity_tx_simulates_source cfg inp state hLen hAmt hCommit,
    (fun allocations hWrap hNz hWords =>
      verity_nonzero_wrap_reverts_and_restores allocations state hWrap hNz hWords),
    fun call =>
      ⟨fun failure =>
          Verity.TopupTx.executeGuarded_binds_returndata cfg call failure _,
        fun o failure hLoop =>
          Verity.TopupTx.executeGuarded_reverts_on_allocation_guard cfg call o failure _ hLoop,
        fun failure hLoop hOver =>
          Verity.TopupTx.executeGuarded_reverts_on_over_target cfg call failure _ hLoop hOver,
        fun hLoop hTarget hNoWrap hLenRd =>
          Verity.TopupTx.executeGuarded_observes_source cfg call state hLoop hTarget
            hNoWrap hLenRd⟩⟩

end LidoSRv3.Audit.Guarantees.PTopup1
