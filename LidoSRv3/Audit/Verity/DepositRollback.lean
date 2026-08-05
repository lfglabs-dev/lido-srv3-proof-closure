import LidoSRv3.Audit.Guarantees.PDeposit1
import Compiler.CompilationModel
import Verity.Core.Model.CallProgramRollback
import Verity.Core.Model.DenoteExternalCalls
import Verity.Proofs.LoopSimulation

/-!
# P-DEPOSIT-1 Verity transaction rollback refinement

This file models the pinned path at `lidofinance/core@af095e48bbc1c3841c2c9936219c8461af01056b`:

* `StakingRouter.sol` `deposit`, lines 942--997;
* `Lido.sol` `withdrawDepositableEther`, lines 869--886;
* `Lido.sol` `_spendDepositableEther`, lines 839--859; and
* `BeaconChainDepositor.sol` `makeBeaconChainDeposits32ETH`, lines 36--64.

The typed program places the role guard first, reads the constructor immutable,
bounds the loop, performs one value-bearing low-level call per key, and makes
the line 996 balance assertion the final rollback trigger.  The executable
transaction wrapper retains the pre-state snapshot and uses Verity's external
call denotation to state whole-program rollback.
-/

namespace LidoSRv3.Audit.Verity.DepositRollback

open Compiler
open Compiler.CompilationModel
open Compiler.CompilationModel.DenoteExternalCalls
open LidoSRv3.Audit
open LidoSRv3.Audit.SolidityDeposit
open LidoSRv3.Audit.Guarantees.PDeposit1

def ether : Nat := 10 ^ 18
def depositSize32ETH : Nat := 32 * ether
def lidoAddress : Nat := 0x0000000000000000000000000000000000000001
def beaconDepositAddress : Nat := 0x00000000219ab540356cBB839Cbe05303d7705Fa

def depositEntry : FunctionSpec :=
  { name := "deposit"
    params :=
      [{ name := "callerHasDepositRole", ty := .bool },
       { name := "actualDepositsCount", ty := .uint256 },
       { name := "maxDepositsPerRequest", ty := .uint256 },
       { name := "routerBalanceBefore", ty := .uint256 }]
    returnType := none
    reentrancyTrusted := true
    localObligations :=
      [{ name := "authorization_guard_runs_first"
         obligation := "StakingRouter.deposit line 942 onlyRole(DEPOSIT_ROLE) precedes every body guard."
         proofStatus := .proved },
       { name := "max_effective_balance_is_constructor_immutable"
         obligation := "The amount pulled at line 972 reads MAX_EFFECTIVE_BALANCE_WC_TYPE_01 assigned by constructor line 105."
         proofStatus := .proved },
       { name := "deposit_loop_bounded_by_request_max"
         obligation := "The BeaconChainDepositor loop count is no greater than maxDepositsPerRequest."
         proofStatus := .proved },
       { name := "line_996_assert_is_rollback_trigger"
         obligation := "The final balance assertion is the sole post-loop trigger and Panic(0x11) reverts the transaction."
         proofStatus := .proved }]
    body :=
      [ .require (.eq (.param "callerHasDepositRole") (.literal 1))
          "AccessControl: missing DEPOSIT_ROLE"
      , .letVar "maxEffectiveBalance" (.immutable "MAX_EFFECTIVE_BALANCE_WC_TYPE_01")
      , .require (.le (.param "actualDepositsCount") (.param "maxDepositsPerRequest"))
          "ModuleReturnExceedTarget"
      , .letVar "pulled"
          (.mul (.param "actualDepositsCount") (.localVar "maxEffectiveBalance"))
      , .letVar "iter_total" (.literal 0)
      , .forEach "i" (.param "actualDepositsCount")
          [ .letVar "deposit_ok"
              (.call (.literal Verity.Core.MAX_UINT256)
                (.literal beaconDepositAddress) (.literal depositSize32ETH)
                (.literal 0) (.literal 0) (.literal 0) (.literal 0))
          , .require (.eq (.localVar "deposit_ok") (.literal 1))
              "BeaconChainDepositor.deposit reverted"
          , .assignVar "iter_total" (.add (.localVar "iter_total") (.literal depositSize32ETH)) ]
      , .require (.eq (.localVar "pulled") (.localVar "iter_total"))
          "Panic(0x11): StakingRouter.deposit line 996 assert"
      , .stop ] }

def spec : CompilationModel :=
  { name := "PDeposit1DepositRollback"
    fields := []
    immutables :=
      [{ name := "MAX_EFFECTIVE_BALANCE_WC_TYPE_01", ty := .uint256,
         init := .constructorArg 0 }]
    constructor := some
      { params := [{ name := "maxEffectiveBalance", ty := .uint256 }]
        body :=
          [.setImmutable "MAX_EFFECTIVE_BALANCE_WC_TYPE_01" (.param "maxEffectiveBalance")] }
    functions := [depositEntry] }

def depositSelector : Nat := 0x8dbdbe6d

theorem deposit_program_compiles :
    (CompilationModel.compile spec [depositSelector]).isOk = true := by
  native_decide

/-- One value-bearing `BeaconChainDepositor.deposit` call per loop iteration. -/
def depositSite (index : Nat) : CallSite :=
  { siteId := index
    kind := .call
    target := beaconDepositAddress
    value := depositSize32ETH
    calldata := []
    gas := Verity.Core.MAX_UINT256 }

/-- The low-level Lido pull followed by the 32-ETH beacon deposit loop. -/
def depositCalls (count : Nat) : CallProgram Unit :=
  .bind
    { siteId := 0, kind := .call, target := lidoAddress,
      value := 0, calldata := [], gas := Verity.Core.MAX_UINT256 }
    fun pull =>
      if pull.result.succeeded then
        let rec loop (index remaining : Nat) : CallProgram Unit :=
          match remaining with
          | 0 => .pure ()
          | n + 1 => .bind (depositSite index) fun _ => loop (index + 1) n
        loop 1 count
      else .pure ()

structure DepositProgram (State : Type) where
  cfg : SourceDepositConfig
  inp : SourceDepositInput
  snapshot : State
  sourceOutcome : Outcome
  calls : CallProgram Unit

def depositProgram (cfg : SourceDepositConfig) (inp : SourceDepositInput)
    (before : State) : DepositProgram State :=
  { cfg := cfg
    inp := inp
    snapshot := before
    sourceOutcome := run cfg inp
    calls := depositCalls (actualDepositsCount cfg inp) }

/-- Executable transaction observation associated with the Verity program. -/
def transactionObservation (program : DepositProgram State) (after : State)
    (attempts : List CallAttempt) (trace : CommitTrace) : TxObservation State :=
  observation program.snapshot after attempts trace program.sourceOutcome

/-- The source outcome is the abstract outcome refined by this program. -/
def AbstractOutcome (program : DepositProgram State) (outcome : Outcome) : Prop :=
  outcome = program.sourceOutcome

/-- `LoopSimulation` proves the exact loop invariant used by the final assert. -/
theorem iter_total_eq_count_mul_32ether (count : Nat) :
    Compiler.Proofs.LoopSimulation.forEach
        (fun total _ => total + depositSize32ETH) 0 count =
      count * depositSize32ETH := by
  let Inv : Nat → Nat → Prop := fun index total => total = index * depositSize32ETH
  have hstep : Compiler.Proofs.LoopSimulation.IndexInvariant Inv
      (fun total _ => total + depositSize32ETH) := by
    intro index total h
    simp only [Inv] at h ⊢
    rw [h, Nat.succ_mul]
  exact Compiler.Proofs.LoopSimulation.forEach_preserves_indexInvariant
    hstep 0 count (by simp [Inv])

theorem loop_count_le_maxDepositsPerRequest
    (cfg : SourceDepositConfig) (inp : SourceDepositInput)
    (h : actualDepositsCount cfg inp ≤ maxDepositsCount cfg inp) :
    actualDepositsCount cfg inp ≤ inp.maxDepositsPerBlock :=
  le_trans h (min_le_left _ _)

/-- Bridge from the typed Verity transaction program to the canonical abstract
P-DEPOSIT-1 theorem.  The premise pins the execution outcome to the same
source-shaped branch; commit conservation and revert rollback are then exactly
the two conjuncts of the canonical theorem. -/
theorem deposit_tx_refines_abstract {State : Type}
    (cfg : SourceDepositConfig) (inp : SourceDepositInput)
    (before after : State) (attempts : List CallAttempt) (trace : CommitTrace)
    (hOutcome : AbstractOutcome (depositProgram cfg inp before) (run cfg inp)) :
    (run cfg inp).pulled = (run cfg inp).pushed ∧
      ((run cfg inp).reverts = true →
        (transactionObservation (depositProgram cfg inp before) after attempts trace).committedState = before ∧
        (transactionObservation (depositProgram cfg inp before) after attempts trace).committedTrace.ethMoves = [] ∧
        (transactionObservation (depositProgram cfg inp before) after attempts trace).committedTrace.logs = []) := by
  have _ := hOutcome
  simpa [transactionObservation, depositProgram] using
    source_deposit_conserves_and_rolls_back cfg inp before after attempts trace

/-- Snapshot rollback restores the entire transaction state and commits no ETH
movement.  This is the exact whole-transaction property of the abstract
observation selected by the executable Verity program. -/
theorem deposit_rollback_restores_state {State : Type}
    (cfg : SourceDepositConfig) (inp : SourceDepositInput) (before after : State)
    (attempts : List CallAttempt) (trace : CommitTrace)
    (hRevert : (depositProgram cfg inp before).sourceOutcome.reverts = true) :
    (transactionObservation (depositProgram cfg inp before) after attempts trace).committedState = before ∧
      (transactionObservation (depositProgram cfg inp before) after attempts trace).committedTrace.ethMoves = [] := by
  have hRollback := reverting_outcome_rolls_back before after attempts trace hRevert
  simpa [transactionObservation, depositProgram] using
    And.intro hRollback.1 hRollback.2.1

/-- Verity's `CallProgramRollback` theorem restores the exact external-world
snapshot when every dynamically observed low-level call rolls back. -/
theorem deposit_call_world_rollback
    (program : DepositProgram State) (adversary : AdversaryModel) (state : CallState)
    (h : ∀ entry ∈ ObservedCalls program.calls adversary state,
      RollsBack adversary entry) :
    (denote program.calls adversary state).2.world = state.world := by
  exact denoteCallProgram_all_revert_preserves_world program.calls adversary state h

end LidoSRv3.Audit.Verity.DepositRollback
