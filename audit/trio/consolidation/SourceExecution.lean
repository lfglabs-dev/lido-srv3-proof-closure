import audit.trio.consolidation.Spec
import LidoSRv3.Audit.Verity.ConsolidationFee
import Verity.Core.Model.CallProgramRollback

/-!
# Executed consolidation source bridge

This module connects bounded vault control flow to the external-call
denotation used by the pinned Solidity scaffold at
`lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`.

Unlike the independent pure specification in `Spec.lean`, execution here asks
an `AdversaryModel` for the result of the actual `feeSite` STATICCALL and each
actual `requestSite` CALL. Every response is evaluated against the world at
that call boundary, and successful mutable calls thread their world transition
into the following iteration.

The decision tree follows pinned source order: payable frame credit and the
modifier snapshot, gateway authorization, empty/length guards, fee STATICCALL
and returndata shape, checked multiplication, exact fee, per-iteration key
checks and CALLs, then
the modifier assertion. Construction is separate: runtime execution requires
a `DeployedVault` witness and never reruns constructor guards.

Revert is a transaction boundary, not an outcome containing a caller-supplied
balance. `rollback` restores the complete entry world after any guard, call,
or modifier failure while retaining gas consumption and returndata. The
modifier assertion has its pinned `Panic(0x01)` result; it is not represented
as `IncorrectFee`.
-/

namespace audit.trio.consolidation

open Compiler.CompilationModel.DenoteExternalCalls

structure ConstructorArgs where
  lido : Word
  treasury : Word
  triggerableWithdrawalsGateway : Word
  consolidationGateway : Word
  withdrawalRequest : Word
  consolidationRequest : Word
  deriving DecidableEq, Repr

def constructorConditions (args : ConstructorArgs) : Bool :=
  args.withdrawalRequest.val != 0 && args.consolidationRequest.val != 0 &&
    args.lido.val != 0 && args.treasury.val != 0 &&
    args.triggerableWithdrawalsGateway.val != 0 &&
    args.consolidationGateway.val != 0

/-- Runtime code can only be entered after successful construction. -/
structure DeployedVault where
  args : ConstructorArgs
  constructorAccepted : constructorConditions args = true

inductive SourceExecutionError where
  | notConsolidationGateway
  | zeroArgument
  | arraysLengthMismatch
  | feeReadFailed (returndata : List Nat)
  | feeInvalidData (returndata : List Nat)
  | feeMultiplicationPanic
  | incorrectFee (required provided : Nat)
  | invalidSourceLength (index actual : Nat)
  | invalidTargetLength (index actual : Nat)
  | requestAdditionFailed (index : Nat) (returndata : List Nat)
  | modifierAssertionPanic
  deriving DecidableEq, Repr

inductive SourceExecutionExit where
  | openExit
  | reverted (error : SourceExecutionError)
  | committed (pairs : List (Pubkey × Pubkey))
  deriving DecidableEq, Repr

inductive SourceExecutionOutcome where
  | openExit (state : CallState)
  | reverted (error : SourceExecutionError) (entryWorld : Verity.ContractState)
      (gasRemaining : Nat) (returndata : List Nat)
  | committed (pairs : List (Pubkey × Pubkey)) (state : CallState)

def SourceExecutionOutcome.exit : SourceExecutionOutcome → SourceExecutionExit
  | .openExit _ => .openExit
  | .reverted error _ _ _ => .reverted error
  | .committed pairs _ => .committed pairs

def SourceExecutionOutcome.state : SourceExecutionOutcome → CallState
  | .openExit state | .committed _ state => state
  | .reverted _ entryWorld gasRemaining returndata =>
      { world := entryWorld, gasRemaining, returndata }

private def rollback (entry post : CallState) (error : SourceExecutionError) :
    SourceExecutionOutcome :=
  .reverted error entry.world post.gasRemaining post.returndata

private def asBytes (key : Pubkey) :
    LidoSRv3.Audit.Verity.ConsolidationFee.Pubkey :=
  List.replicate key.length
    ⟨key.identity % 256, Nat.mod_lt _ (by decide)⟩

private def asRequest (source target : Pubkey) :
    LidoSRv3.Audit.Verity.ConsolidationFee.MemoryRequest :=
  LidoSRv3.Audit.Verity.ConsolidationFee.encodeRequest
    { source := asBytes source, target := asBytes target }

private def executeRequests : Nat → Nat → Nat → Nat →
    List (Pubkey × Pubkey) → AdversaryModel → CallState → CallState →
    Word → SourceExecutionOutcome
  | _, _, _, _, [], _, entry, post, balanceBefore =>
      if post.world.selfBalance = balanceBefore then
        .committed [] post
      else rollback entry post .modifierAssertionPanic
  | 0, _, _, _, _ :: _, _, _, post, _ =>
      .openExit post
  | fuel + 1, index, requestTarget, fee, (source, target) :: rest,
      adversary, entry, post, balanceBefore =>
      if source.length != pubkeyLength then
        rollback entry post (.invalidSourceLength index source.length)
      else if target.length != pubkeyLength then
        rollback entry post (.invalidTargetLength index target.length)
      else
        let site := LidoSRv3.Audit.Verity.ConsolidationFee.requestSite
          requestTarget fee index (asRequest source target)
        let observation := denoteCall adversary site post
        match observation.result with
        | .success _ =>
            let result := executeRequests fuel (index + 1) requestTarget fee rest
              adversary entry observation.state balanceBefore
            match result with
            | .committed pairs resultState =>
                .committed ((source, target) :: pairs) resultState
            | _ => result
        | .failure data | .revert data =>
            rollback entry observation.state (.requestAdditionFailed index data)

/-- Execute the pinned runtime path from the transaction-entry snapshot.
`runtimeState` applies the payable frame credit before the modifier reads the
balance. Thus every revert restores the genuinely earlier `state.world`, while
a commit retains the world produced by successful CALLs. As in the EVM,
reachable account balances are assumed not to overflow the 256-bit word when
the frame credit is applied. -/
def executeSourceBounded (fuel : Nat) (deployment : DeployedVault)
    (caller : Word) (msgValue : Word) (sources targets : List Pubkey)
    (adversary : AdversaryModel) (state : CallState) : SourceExecutionOutcome :=
  let balanceBefore := state.world.selfBalance
  let runtimeState : CallState :=
    { state with world := { state.world with
        selfBalance := word (state.world.selfBalance.val + msgValue.val)
        msgValue := msgValue } }
  if caller != deployment.args.consolidationGateway then
      rollback state runtimeState .notConsolidationGateway
    else if sources.isEmpty then
      rollback state runtimeState .zeroArgument
    else if sources.length != targets.length then
      rollback state runtimeState .arraysLengthMismatch
    else
      let feeObservation := denoteCall adversary
        (LidoSRv3.Audit.Verity.ConsolidationFee.feeSite
          deployment.args.consolidationRequest.val) runtimeState
      match feeObservation.result with
      | .failure data | .revert data =>
          rollback state feeObservation.state (.feeReadFailed data)
      | .success data =>
          if data.length != 32 then
            rollback state feeObservation.state (.feeInvalidData data)
          else
            let fee := LidoSRv3.Audit.Verity.ConsolidationFee.decodeWord data
            let required := sources.length * fee
            if Verity.Core.MAX_UINT256 < required then
              rollback state feeObservation.state .feeMultiplicationPanic
            else if msgValue.val != required then
              rollback state feeObservation.state (.incorrectFee required msgValue.val)
            else
              executeRequests fuel 0 deployment.args.consolidationRequest.val fee
                (sources.zip targets) adversary state feeObservation.state balanceBefore

/-- Constructor rejection is deployment-time: rejected arguments cannot
produce the witness required by runtime execution. -/
theorem rejected_constructor_has_no_deployment (args : ConstructorArgs)
    (h : constructorConditions args = false) :
    ¬ ∃ deployment : DeployedVault, deployment.args = args := by
  rintro ⟨deployment, rfl⟩
  have accepted := deployment.constructorAccepted
  rw [h] at accepted
  contradiction

/-- Revert outcomes restore their stored transaction-entry snapshot by
construction; they cannot carry an invented `initialBalance`. -/
theorem reverted_outcome_restores_snapshot (error : SourceExecutionError)
    (entry : Verity.ContractState) (gas : Nat) (data : List Nat) :
    (SourceExecutionOutcome.reverted error entry gas data).state.world = entry := rfl

end audit.trio.consolidation
