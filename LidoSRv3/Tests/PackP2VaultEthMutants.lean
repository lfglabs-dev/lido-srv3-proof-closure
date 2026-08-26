import LidoSRv3.Audit.Guarantees.PVaultEth1

/-!
# P-VAULT-ETH-1 value-frame and exact-parent kill-lines

The mutant keeps the same nonzero source amount, route, target, source success,
and executable external-call primitive, but sends zero wei in the fresh frame.
It therefore refutes the new parent's value-bearing conjunct.  This is not the
older exclusion-only Lido mutant.

The second mutant keeps the source schedule, route, runtime target, and value
frame but drops the executable Lido-only caller binding. It refutes the
caller/endpoint parent conjunct without claiming an endpoint is deployment
identity or widening the WithdrawalQueue route.
-/

namespace LidoSRv3.Tests.PackP2VaultEthMutants

open _root_.Verity
open _root_.Contracts
open LidoSRv3.Audit.Spec
open LidoSRv3.Audit.Source.VaultEthCorrespondence
open LidoSRv3.Audit.Spec.VaultEthCorrespondence
open LidoSRv3.Audit.Verity.VaultEthTx
open LidoSRv3.Audit.Guarantees.PVaultEth1

def zeroValueEntry (endpoints : Endpoints) (inputs : Inputs) : ExternalCall :=
  linkedCallEntryTo (callName inputs.route)
    (targetOf endpoints inputs.route) 0 []

/-- Mutated frame: target, call name, and source input are retained, but
`value = 0`. -/
def zeroValueFrame (endpoints : Endpoints) (inputs : Inputs) : Contract Unit :=
  externalCallBindTo (targetOf endpoints inputs.route) 0 []
    (callName inputs.route) ([] : List Word)

def afterZeroValueFrame (endpoints : Endpoints) (inputs : Inputs)
    (entry : ContractState) : ContractState :=
  { entry with calls := entry.calls ++ [zeroValueEntry endpoints inputs] }

def executeZeroValueMutant
    (endpoints : Endpoints) (inputs : Inputs) : Contract Unit := fun entry =>
  match sourceRun endpoints inputs entry with
  | .reverted reason => .revert reason entry
  | .committed _ => zeroValueFrame endpoints inputs entry

theorem zeroValueEntry_value (endpoints : Endpoints) (inputs : Inputs) :
    (zeroValueEntry endpoints inputs).value = 0 := rfl

theorem zeroValueFrame_apply (endpoints : Endpoints) (inputs : Inputs)
    (entry : ContractState) :
    zeroValueFrame endpoints inputs entry =
      .success () (afterZeroValueFrame endpoints inputs entry) := by
  have hName : callName inputs.route ≠ "fail" := callName_ne_fail inputs.route
  simp [zeroValueFrame, afterZeroValueFrame, zeroValueEntry,
    externalCallBindTo, externalCallStubSuccess, hName]

theorem executeZeroValueMutant_commits
    (endpoints : Endpoints) (inputs : Inputs) (entry : ContractState)
    (hCaller : callerAuthorized endpoints inputs entry.sender = true)
    (hNonzero : inputs.amount ≠ 0)
    (hFunds : inputs.amount ≤ entry.selfBalance) :
    (executeZeroValueMutant endpoints inputs).run entry =
      .success () (afterZeroValueFrame endpoints inputs entry) := by
  rw [Contract.run]
  simp only [executeZeroValueMutant,
    sourceRun_commits_of_preconditions endpoints inputs entry
      hCaller hNonzero hFunds]
  rw [zeroValueFrame_apply endpoints inputs entry]

private def endpoints : Endpoints :=
  { lido := 1, withdrawalQueue := 2 }

private def inputs : Inputs :=
  { route := .lidoReceiveWithdrawals, caller := 1, amount := .ofNat 7 }

private def entry : ContractState :=
  { defaultState with selfBalance := .ofNat 10, sender := 1 }

theorem zero_value_frame_fails_value_bearing_conjunct :
    ¬ ValueBearingFrames endpoints inputs entry
        (afterZeroValueFrame endpoints inputs entry) := by
  intro hFrames
  have hValues := hFrames.2
  simp [freshFrameValues, freshCalls, afterZeroValueFrame, zeroValueEntry,
    specJournal, specLeg, specDestination, inputs, linkedCallEntryTo,
    linkedCallEntry] at hValues
  exact (by decide : (0 : Nat) ≠ 7 % Core.Uint256.modulus) hValues

/-- Parent-shaped kill-line: source success and executable success are
retained, but changing the Vault→Lido frame from seven wei to zero falsifies
the registered three-conjunct conclusion. -/
theorem zero_value_frame_kill_line_refutes_parent :
    sourceRun endpoints inputs entry =
        .committed (sourceJournal endpoints inputs) ∧
      (executeZeroValueMutant endpoints inputs).run entry =
        .success () (afterZeroValueFrame endpoints inputs entry) ∧
      ¬ ValueHopConclusion endpoints inputs entry
        (afterZeroValueFrame endpoints inputs entry) := by
  refine ⟨sourceRun_commits_of_preconditions
      endpoints inputs entry (by decide) (by decide) (by decide),
    executeZeroValueMutant_commits endpoints inputs entry (by decide) (by decide) (by decide), ?_⟩
  intro hParent
  exact zero_value_frame_fails_value_bearing_conjunct hParent.2.1

/-! ## Route-sensitive caller-binding regression and exact-parent kill-line -/

/-- Exact-parent regression mutant: the former source guard read the auxiliary
input field instead of the executable state's sender. -/
def callerAuthorizedFromInputs (endpoints : Endpoints) (inputs : Inputs) : Bool :=
  match inputs.route with
  | .lidoReceiveWithdrawals => inputs.caller == endpoints.lido
  | .withdrawalQueueReturn => true

def sourceRunWithInputCaller
    (endpoints : Endpoints) (inputs : Inputs) (entry : ContractState) : SourceOutcome :=
  if !callerAuthorizedFromInputs endpoints inputs then .reverted "NotLido"
  else if inputs.amount = 0 then .reverted "ZeroAmount"
  else if inputs.amount ≤ entry.selfBalance then
    .committed (sourceJournal endpoints inputs)
  else .reverted "NotEnoughEther"

def executeWithInputCallerGuard
    (endpoints : Endpoints) (inputs : Inputs) : Contract Unit := fun entry =>
  match sourceRunWithInputCaller endpoints inputs entry with
  | .reverted reason => .revert reason entry
  | .committed _ => returnFrame endpoints inputs entry

private def unauthorizedLidoInputs : Inputs :=
  { route := .lidoReceiveWithdrawals, caller := 1, amount := .ofNat 7 }

private def unauthorizedEntry : ContractState :=
  { entry with sender := 9 }

private def queueInputsWithDistinctCaller : Inputs :=
  { route := .withdrawalQueueReturn, caller := 9, amount := .ofNat 7 }

/-- WithdrawalQueue remains source-shaped: a distinct model caller and
executable sender must not be rejected by the Lido-only boundary guard. -/
theorem withdrawal_queue_distinct_caller_commits :
    (execute endpoints queueInputsWithDistinctCaller).run entry =
      .success () (afterFrame endpoints queueInputsWithDistinctCaller entry) := by
  exact execute_commits_of_preconditions endpoints queueInputsWithDistinctCaller entry
    (by decide) (by decide) (by decide)

theorem unauthorized_lido_mutant_commits :
    (executeWithInputCallerGuard endpoints unauthorizedLidoInputs).run unauthorizedEntry =
      .success () (afterFrame endpoints unauthorizedLidoInputs unauthorizedEntry) := by
  have hFunds : unauthorizedLidoInputs.amount ≤ unauthorizedEntry.selfBalance := by decide
  have hNonzero : Core.Uint256.ofNat 7 ≠ 0 := by decide
  have hConcreteFunds : 7 % Core.Uint256.modulus ≤ 10 % Core.Uint256.modulus := by decide
  have hSource :
      sourceRunWithInputCaller endpoints unauthorizedLidoInputs unauthorizedEntry =
        .committed (sourceJournal endpoints unauthorizedLidoInputs) := by
    simp [sourceRunWithInputCaller, callerAuthorizedFromInputs,
      unauthorizedLidoInputs, unauthorizedEntry, entry, endpoints,
      hNonzero, hConcreteFunds]
  rw [Contract.run]
  simp [executeWithInputCallerGuard, hSource,
    returnFrame_apply endpoints unauthorizedLidoInputs unauthorizedEntry hFunds]

/-- **Exact-parent mutant.** With an unauthorized executable sender, restoring
the exact-parent input-field guard still emits the same seven-wei Lido frame
and refutes the registered `LidoCallerEndpointBinding` conjunct. -/
theorem input_caller_guard_refutes_exact_parent :
    (executeWithInputCallerGuard endpoints unauthorizedLidoInputs).run unauthorizedEntry =
        .success () (afterFrame endpoints unauthorizedLidoInputs unauthorizedEntry) ∧
      ¬ ValueHopConclusion endpoints unauthorizedLidoInputs unauthorizedEntry
        (afterFrame endpoints unauthorizedLidoInputs unauthorizedEntry) := by
  refine ⟨unauthorized_lido_mutant_commits, ?_⟩
  intro hParent
  have hBinding := hParent.2.2.1 rfl
  exact (by decide : (9 : _root_.Verity.Core.Address) ≠ 1) hBinding.1

/-- Mutant projection: keep the Vault→Lido source hop and wei, but journal
it as the deposit/top-up `lidoPull` constructor. That is not the new
protocol-return dest. -/
def mutantApprovedDestination : Destination → Option ApprovedDestination
  | .lidoReceiveWithdrawals => some .lidoPull
  | .withdrawalQueueReturn => some .vaultToWithdrawalQueue
  | .ownerWithdrawal _ => none

def mutantLidoPullJournal : EthJournal :=
  [{ dest := .lidoPull, wei := ⟨inputs.amount.val⟩ }]

/-- Parent-shaped dest kill-line: the honest Spec journal of this hop is
`vaultToLido`, so retagging it as `lidoPull` falsifies lossless projection.
This is not the P-ETH-JOURNAL-1 exclusion mutant. -/
theorem mutant_vault_lido_as_lidoPull_refutes_projection :
    specDestination inputs.route = .vaultToLido ∧
      mutantApprovedDestination .lidoReceiveWithdrawals = some .lidoPull ∧
      SourceJournalProjectsToEthJournal
        (sourceJournal endpoints inputs) (specJournal inputs) ∧
      ¬ SourceJournalProjectsToEthJournal
          (sourceJournal endpoints inputs) mutantLidoPullJournal := by
  refine ⟨rfl, rfl, sourceJournal_projects endpoints inputs, ?_⟩
  intro h
  simp [SourceJournalProjectsToEthJournal, specLegOfSource, approvedDestination,
    sourceJournal, destinationOf, mutantLidoPullJournal, inputs] at h

end LidoSRv3.Tests.PackP2VaultEthMutants
