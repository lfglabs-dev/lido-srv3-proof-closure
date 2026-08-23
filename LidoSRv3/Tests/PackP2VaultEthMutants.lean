import LidoSRv3.Audit.Guarantees.PVaultEth1

/-!
# P-VAULT-ETH-1 value-frame kill-line

The mutant keeps the same nonzero source amount, route, target, source success,
and executable external-call primitive, but sends zero wei in the fresh frame.
It therefore refutes the new parent's value-bearing conjunct. This is not the
older exclusion-only Lido mutant.
-/

namespace LidoSRv3.Tests.PackP2VaultEthMutants

open _root_.Verity
open _root_.Contracts
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
  match sourceRun endpoints inputs entry.selfBalance with
  | .reverted reason => .revert reason entry
  | .committed _ => zeroValueFrame endpoints inputs entry

theorem zeroValueFrame_apply (endpoints : Endpoints) (inputs : Inputs)
    (entry : ContractState) :
    zeroValueFrame endpoints inputs entry =
      .success () (afterZeroValueFrame endpoints inputs entry) := by
  cases inputs with
  | mk route amount =>
      cases route <;>
        simp [zeroValueFrame, afterZeroValueFrame, zeroValueEntry, callName,
          externalCallBindTo, externalCallStubSuccess, linkedCallEntryTo,
          linkedCallEntry]

theorem executeZeroValueMutant_commits
    (endpoints : Endpoints) (inputs : Inputs) (entry : ContractState)
    (hNonzero : inputs.amount ≠ 0)
    (hFunds : inputs.amount ≤ entry.selfBalance) :
    (executeZeroValueMutant endpoints inputs).run entry =
      .success () (afterZeroValueFrame endpoints inputs entry) := by
  rw [Contract.run]
  simp only [executeZeroValueMutant,
    sourceRun_commits_of_preconditions endpoints inputs entry.selfBalance
      hNonzero hFunds]
  rw [zeroValueFrame_apply endpoints inputs entry]

private def endpoints : Endpoints :=
  { lido := 1, withdrawalQueue := 2 }

private def inputs : Inputs :=
  { route := .lidoReceiveWithdrawals, amount := .ofNat 7 }

private def entry : ContractState :=
  { defaultState with selfBalance := .ofNat 10 }

theorem zero_value_frame_fails_value_bearing_conjunct :
    ¬ ValueBearingFrames endpoints inputs entry
        (afterZeroValueFrame endpoints inputs entry) := by
  intro hFrames
  have hValues := hFrames.2
  simp [freshFrameValues, freshCalls, afterZeroValueFrame, zeroValueEntry,
    specJournal, specLeg, specDestination, inputs, linkedCallEntryTo,
    linkedCallEntry] at hValues

/-- Parent-shaped kill-line: source success and executable success are
retained, but changing the Vault→Lido frame from seven wei to zero falsifies
the registered three-conjunct conclusion. -/
theorem zero_value_frame_kill_line_refutes_parent :
    sourceRun endpoints inputs entry.selfBalance =
        .committed (sourceJournal endpoints inputs) ∧
      (executeZeroValueMutant endpoints inputs).run entry =
        .success () (afterZeroValueFrame endpoints inputs entry) ∧
      ¬ ValueHopConclusion endpoints inputs entry
        (afterZeroValueFrame endpoints inputs entry) := by
  refine ⟨sourceRun_commits_of_preconditions
      endpoints inputs entry.selfBalance (by decide) (by decide),
    executeZeroValueMutant_commits endpoints inputs entry (by decide) (by decide), ?_⟩
  intro hParent
  exact zero_value_frame_fails_value_bearing_conjunct hParent.2.1

end LidoSRv3.Tests.PackP2VaultEthMutants
