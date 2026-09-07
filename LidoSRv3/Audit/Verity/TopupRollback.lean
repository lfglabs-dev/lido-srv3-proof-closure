import LidoSRv3.Audit.Guarantees.PTopup1
import Compiler.CompilationModel
import Verity.Core.Model.AllocationExtraction
import Verity.Core.Model.CallProgramRollback
import Verity.Core.Model.DenoteExternalCalls
import Verity.Proofs.LoopSimulation

/-!
# P-TOPUP-1 Verity transaction refinement

This is the typed transaction program for the top-up path pinned at
`lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`.  In particular,
the allocation loop is the loop at `StakingRouter.sol` lines 722--734, the
Lido pull is line 744, and the value-bearing deposit calls are the loop in
`BeaconChainDepositor.sol` lines 79--107.

The source allocation boundary is deliberately the A.3 typed-source boundary
provided by Verity #2239: it relates a `SolidityFunction` to the very same
checked `FunctionSpec`, rather than claiming an unavailable Solidity-AST or EVM
translation.
-/

namespace LidoSRv3.Audit.Verity.TopupRollback

open Compiler
open Compiler.CompilationModel
open Compiler.CompilationModel.DenoteExternalCalls
open LidoSRv3.Audit
open LidoSRv3.Audit.SolidityTopup
open LidoSRv3.Audit.Guarantees.PTopup1
open Verity.Core.Model.AllocationExtraction

def lidoAddress : Nat := 0x0000000000000000000000000000000000000001
def beaconDepositAddress : Nat := 0x00000000219ab540356cBB839Cbe05303d7705Fa

/-- One loop body for lines 724--732.  `allocation` is the amount returned in
the pinned `_amounts[i]` array and accumulated by the unchecked source loop. -/
def allocationBody : List Stmt :=
  [ .letVar "allocation" (.arrayElement "allocations" (.localVar "i"))
  , .letVar "limit" (.arrayElement "topUpLimits" (.localVar "i"))
  , .require (.eq (.mod (.localVar "allocation") (.literal 1000000000)) (.literal 0))
      "AmountNotAlignedToGwei"
  , .require (.le (.localVar "allocation") (.localVar "limit"))
      "AllocationExceedsLimit"
  , .assignVar "amount" (.add (.localVar "amount") (.localVar "allocation")) ]

def topUpEntry : FunctionSpec :=
  { name := "topUp"
    params :=
      [{ name := "callerIsTopUpGateway", ty := .bool },
       { name := "keyCount", ty := .uint256 },
       { name := "allocations", ty := .array .uint256 },
       { name := "topUpLimits", ty := .array .uint256 },
       { name := "routerBalanceBefore", ty := .uint256 }]
    returnType := none
    reentrancyTrusted := true
    localObligations :=
      [{ name := "gateway_guard_runs_first"
         obligation := "StakingRouter.topUp line 686 authenticates the top-up gateway first."
         proofStatus := .proved },
       { name := "allocation_is_same_array_element"
         obligation := "The amount accumulated at line 732 and forwarded at line 750 is allocations[i]."
         proofStatus := .proved },
       { name := "allocation_loop_is_key_bounded"
         obligation := "The allocation loop is bounded by the validated key count."
         proofStatus := .proved },
       { name := "balance_assert_is_rollback_trigger"
         obligation := "The line 755 assertion is a top-level transaction revert."
         proofStatus := .proved }]
    body :=
      [ .require (.eq (.param "callerIsTopUpGateway") (.literal 1)) "NotAuthorized"
      , .calldatacopy (.literal 0) (.literal 4)
          (.mul (.param "keyCount") (.literal 48))
      , .letVar "amount" (.literal 0)
      , .mstore (.literal 96) (.literal 0)
      , .forEach "i" (.param "keyCount") allocationBody
      , .letVar "pull_ok"
          (.call (.literal Verity.Core.MAX_UINT256) (.literal lidoAddress) (.literal 0)
            (.literal 0) (.literal 0) (.literal 0) (.literal 0))
      , .require (.eq (.localVar "pull_ok") (.literal 1)) "Lido pull reverted"
      , .forEach "j" (.param "keyCount")
          [ .letVar "topupAmount" (.arrayElement "allocations" (.localVar "j"))
          , .mstore (.literal 128) (.localVar "topupAmount")
          , .letVar "deposit_ok"
              (.call (.literal Verity.Core.MAX_UINT256) (.literal beaconDepositAddress)
                (.localVar "topupAmount") (.literal 0) (.literal 0) (.literal 0) (.literal 0))
          , .require (.eq (.localVar "deposit_ok") (.literal 1))
              "BeaconChainDepositor top-up reverted" ]
      , .require (.eq .selfBalance (.param "routerBalanceBefore"))
          "Panic(0x01): StakingRouter.topUp line 755 assert"
      , .stop ] }

def spec : CompilationModel :=
  { name := "PTopup1TopupRollback"
    fields := []
    «constructor» := none
    functions := [topUpEntry] }

def topUpSelector : Nat := 0x0f6b3d8b

theorem topup_program_declared : spec.functions = [topUpEntry] := rfl

/-- A.3 source allocation extraction applied to the pinned top-up function. -/
def pinnedSolidityTopUp : SolidityFunction := topUpEntry

theorem topup_allocation_extracted_from_pinned_source :
    extractAllocation spec topUpEntry =
      extractAllocationFromSource spec pinnedSolidityTopUp := by
  exact extractAllocation_source_equiv spec pinnedSolidityTopUp topUpEntry rfl

/-- The numerical amount extracted from source line 732 is the unchecked sum of
the pinned `allocations` array; under the campaign's explicit no-wrap premise it
is exactly the amount pulled and forwarded by the abstract source model. -/
theorem topup_amount_extraction_correct (inp : SourceTopupInput)
    (hNoWrap : NoUncheckedWrap inp) :
    allocSumUnchecked inp.allocations = totalAllocated inp :=
  source_unchecked_accumulation_faithful inp hNoWrap

/-- Executable bridge for the allocation accumulator used by the typed loop. -/
theorem allocation_loop_sum (amounts : List Nat) :
    Compiler.Proofs.LoopSimulation.forEach
        (Compiler.Proofs.LoopSimulation.sumStep amounts) 0 amounts.length =
      amounts.sum := by
  rw [Compiler.Proofs.LoopSimulation.forEach_sum_over_array]
  have fold_add (values : List Nat) (initial : Nat) :
      values.foldl (fun x y => x + y) initial = initial + values.sum := by
    induction values generalizing initial with
    | nil => simp
    | cons value rest ih => simp [ih, Nat.add_assoc]
  simpa using fold_add amounts 0

def lidoPullSite : CallSite :=
  { siteId := 0, kind := .call, target := lidoAddress, value := 0,
    calldata := [], gas := Verity.Core.MAX_UINT256 }

def topUpSite (index amount : Nat) : CallSite :=
  { siteId := index + 1, kind := .call, target := beaconDepositAddress,
    value := amount, calldata := [], gas := Verity.Core.MAX_UINT256 }

def topUpCalls (amounts : List Nat) : CallProgram Unit :=
  .bind lidoPullSite fun pull =>
    if pull.result.succeeded then
      let rec loop (index : Nat) : List Nat → CallProgram Unit
        | [] => .pure ()
        | amount :: rest => .bind (topUpSite index amount) fun _ => loop (index + 1) rest
      loop 0 amounts
    else .pure ()

structure TopupProgram (State : Type) where
  cfg : SourceTopupConfig
  inp : SourceTopupInput
  snapshot : State
  sourceOutcome : Outcome
  calls : CallProgram Unit

def topupProgram (cfg : SourceTopupConfig) (inp : SourceTopupInput)
    (before : State) : TopupProgram State :=
  { cfg := cfg, inp := inp, snapshot := before, sourceOutcome := run cfg inp,
    calls := topUpCalls inp.allocations }

def transactionObservation (program : TopupProgram State) (after : State)
    (attempts : List CallAttempt) (trace : CommitTrace) : TxObservation State :=
  observation program.snapshot after attempts trace program.sourceOutcome

/-- Successful top-up execution has the canonical expected post-state facts:
the pulled value equals the pushed value and the router balance is unchanged. -/
theorem topup_success_post_state_equiv
    (cfg : SourceTopupConfig) (inp : SourceTopupInput)
    {keys pulled pushed balanceAfter : Nat}
    (hRun : run cfg inp = .committedTopUp keys pulled pushed balanceAfter) :
    pulled = pushed ∧ balanceAfter = inp.routerBalanceBefore := by
  constructor
  · have hConserves := run_conserves cfg inp
    rw [hRun] at hConserves
    exact hConserves
  · exact source_router_balance_unchanged cfg inp hRun

/-- Whole-transaction snapshot rollback for every reverting source outcome. -/
theorem topup_rollback_restores_state {State : Type}
    (cfg : SourceTopupConfig) (inp : SourceTopupInput) (before after : State)
    (attempts : List CallAttempt) (trace : CommitTrace)
    (hRevert : (topupProgram cfg inp before).sourceOutcome.reverts = true) :
    (transactionObservation (topupProgram cfg inp before) after attempts trace).committedState = before ∧
      (transactionObservation (topupProgram cfg inp before) after attempts trace).committedTrace.ethMoves = [] ∧
      (transactionObservation (topupProgram cfg inp before) after attempts trace).committedTrace.logs = [] := by
  simpa [transactionObservation, topupProgram] using
    reverting_outcome_rolls_back before after attempts trace hRevert

/-- Transaction-plane refinement to the canonical P-TOPUP-1 post-state and
rollback theorem.  Projects the conservation/rollback conjunct out of the
registered parent (`source_topup_conserves_and_rolls_back`), which additionally
folds in the promoted guard and wrap-branch facts not needed here. -/
theorem topup_tx_refines_abstract {State : Type}
    (cfg : SourceTopupConfig) (inp : SourceTopupInput)
    (before after : State) (attempts : List CallAttempt) (trace : CommitTrace) :
    (run cfg inp).pulled = (run cfg inp).pushed ∧
      ((run cfg inp).reverts = true →
        (transactionObservation (topupProgram cfg inp before) after attempts trace).committedState = before ∧
        (transactionObservation (topupProgram cfg inp before) after attempts trace).committedTrace.ethMoves = [] ∧
        (transactionObservation (topupProgram cfg inp before) after attempts trace).committedTrace.logs = []) := by
  simpa [transactionObservation, topupProgram] using
    (source_topup_conserves_and_rolls_back cfg inp before after attempts trace).1

/-- Composable external-call denotation restores the exact world when each
dynamically observed call rolls back. -/
theorem topup_call_world_rollback
    (program : TopupProgram State) (adversary : AdversaryModel) (state : CallState)
    (h : ∀ entry ∈ ObservedCalls program.calls adversary state,
      RollsBack adversary entry) :
    (denote program.calls adversary state).2.world = state.world :=
  denoteCallProgram_all_revert_preserves_world program.calls adversary state h

end LidoSRv3.Audit.Verity.TopupRollback
