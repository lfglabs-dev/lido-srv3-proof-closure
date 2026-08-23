import LidoSRv3.Audit.Spec.VaultEthCorrespondence
import LidoSRv3.Audit.Verity.VaultEthTx
import LidoSRv3.Audit.Guarantees.Registry

/-!
# P-VAULT-ETH-1 protocol-return value-hop parent

For every modeled route, amount, endpoint set, entry state, and successful
execution, one named conclusion connects:

1. the successful source journal losslessly to `Spec.EthJournal`;
2. the fresh `externalCallBindTo` frame value to the Spec leg's wei; and
3. the continued exclusion of owner-controlled arbitrary recipients.

The new constructors are provenance tags backed by executable value-bearing
frames. Endpoint addresses are runtime inputs and do not establish
provenance. This parent does not say that Lido never drains ETH and does not
claim all SRv3 ETH.
-/

namespace LidoSRv3.Audit.Guarantees.PVaultEth1

open _root_.Verity
open LidoSRv3.Audit.Source.VaultEthCorrespondence
open LidoSRv3.Audit.Spec.VaultEthCorrespondence
open LidoSRv3.Audit.Verity.VaultEthTx

def guarantee : Guarantee := ⟨.pVaultEth1, [.model, .source, .verityTx]⟩

/-- Conjunct 1: every source success journal for this input projects
losslessly, including the new destination constructor and exact wei. -/
def EverySuccessfulJournalProjects
    (endpoints : Endpoints) (inputs : Inputs) (entry : ContractState) : Prop :=
  ∀ journal,
    sourceRun endpoints inputs entry.selfBalance = .committed journal →
      SourceJournalProjectsToEthJournal journal (specJournal inputs)

/-- Conjunct 2: execution contributes exactly one fresh call frame, and its
value list equals the Spec journal's wei list. The exact-frame equality also
binds target and call name, not only value. -/
def ValueBearingFrames
    (endpoints : Endpoints) (inputs : Inputs)
    (entry after : ContractState) : Prop :=
  freshCalls entry after = [returnEntry endpoints inputs] ∧
    freshFrameValues entry after =
      (specJournal inputs).map (fun leg => leg.wei.value)

/-- The single named three-part conclusion required by P-VAULT-ETH-1. -/
def ValueHopConclusion
    (endpoints : Endpoints) (inputs : Inputs)
    (entry after : ContractState) : Prop :=
  EverySuccessfulJournalProjects endpoints inputs entry ∧
    ValueBearingFrames endpoints inputs entry after ∧
    OwnerWithdrawalRecipientsExcluded

/-- **P-VAULT-ETH-1 parent.** Universal over modeled vault-return inputs and
entry state: any successful executable run has a lossless Spec projection,
value-bearing frame equality, and the arbitrary owner-recipient exclusion. -/
theorem protocol_return_value_hops
    (endpoints : Endpoints) (inputs : Inputs) (entry after : ContractState)
    (hSuccess : (execute endpoints inputs).run entry = .success () after) :
    ValueHopConclusion endpoints inputs entry after := by
  obtain ⟨_hSource, hAfter⟩ :=
    execute_success_corresponds_to_source endpoints inputs entry after hSuccess
  refine ⟨?_, ?_, owner_withdrawal_recipients_excluded⟩
  · intro journal hJournal
    exact every_source_success_journal_projects
      endpoints inputs entry.selfBalance journal hJournal
  · subst after
    constructor
    · exact afterFrame_freshCalls endpoints inputs entry
    · cases inputs.route <;>
        simp [freshFrameValues, afterFrame_freshCalls, returnEntry_value,
          specJournal, specLeg, specDestination]

private def witnessEndpoints : Endpoints :=
  { lido := 1, withdrawalQueue := 2 }

private def witnessEntry : ContractState :=
  { defaultState with selfBalance := .ofNat 10 }

private def lidoWitnessInput : Inputs :=
  { route := .lidoReceiveWithdrawals, amount := .ofNat 7 }

private def queueWitnessInput : Inputs :=
  { route := .withdrawalQueueReturn, amount := .ofNat 7 }

/-- Non-vacuity: the Vault→Lido constructor is inhabited by a successful
seven-wei `externalCallBindTo` frame. -/
theorem vault_to_lido_value_frame_inhabited :
    (execute witnessEndpoints lidoWitnessInput).run witnessEntry =
        .success ()
          (afterFrame witnessEndpoints lidoWitnessInput witnessEntry) ∧
      specDestination lidoWitnessInput.route = .vaultToLido ∧
      (returnEntry witnessEndpoints lidoWitnessInput).value = 7 := by
  refine ⟨execute_commits_of_preconditions
    witnessEndpoints lidoWitnessInput witnessEntry (by decide) (by decide), rfl, rfl⟩

/-- Non-vacuity: the WithdrawalQueue return constructor is inhabited by a
successful seven-wei `externalCallBindTo` frame. -/
theorem vault_to_withdrawal_queue_value_frame_inhabited :
    (execute witnessEndpoints queueWitnessInput).run witnessEntry =
        .success ()
          (afterFrame witnessEndpoints queueWitnessInput witnessEntry) ∧
      specDestination queueWitnessInput.route = .vaultToWithdrawalQueue ∧
      (returnEntry witnessEndpoints queueWitnessInput).value = 7 := by
  refine ⟨execute_commits_of_preconditions
    witnessEndpoints queueWitnessInput witnessEntry (by decide) (by decide), rfl, rfl⟩

end LidoSRv3.Audit.Guarantees.PVaultEth1
