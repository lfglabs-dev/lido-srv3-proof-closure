import LidoSRv3.Audit.Spec
import LidoSRv3.Audit.Source.VaultEthCorrespondence

/-!
# P-VAULT-ETH-1 Spec ↔ source correspondence

Protocol-return provenance is supplied by the source route constructor, not
by comparing an address with a pin.  The two approved source constructors
project losslessly onto the new `Spec.ApprovedDestination` constructors and
preserve wei.  An owner-controlled withdrawal recipient projects to `none`.

The older `EthJournalCorrespondence.specDest` remains the intentionally narrow
fee/refund projection used by P-ETH-JOURNAL-1.  This module is the separate
projection for P-VAULT-ETH-1.
-/

namespace LidoSRv3.Audit.Spec.VaultEthCorrespondence

open LidoSRv3.Audit.Common
open LidoSRv3.Audit.Spec
open LidoSRv3.Audit.Source.VaultEthCorrespondence

def approvedDestination : Destination → Option ApprovedDestination
  | .lidoReceiveWithdrawals => some .vaultToLido
  | .withdrawalQueueReturn => some .vaultToWithdrawalQueue
  | .ownerWithdrawal _ => none

def specDestination : Route → ApprovedDestination
  | .lidoReceiveWithdrawals => .vaultToLido
  | .withdrawalQueueReturn => .vaultToWithdrawalQueue

def specLeg (inputs : Inputs) : EthJournalLeg :=
  { dest := specDestination inputs.route
    wei := ⟨inputs.amount.val⟩ }

def specJournal (inputs : Inputs) : EthJournal :=
  [specLeg inputs]

def specLegOfSource (leg : SourceLeg) : Option EthJournalLeg :=
  match approvedDestination leg.destination with
  | some destination => some { dest := destination, wei := ⟨leg.value.val⟩ }
  | none => none

/-- Lossless projection: every source leg must correspond to one Spec leg.
Unlike `filterMap`, an unapproved source leg cannot disappear. -/
def SourceJournalProjectsToEthJournal
    (source : SourceJournal) (journal : EthJournal) : Prop :=
  source.map specLegOfSource = journal.map some

theorem sourceJournal_projects (endpoints : Endpoints) (inputs : Inputs) :
    SourceJournalProjectsToEthJournal
      (sourceJournal endpoints inputs) (specJournal inputs) := by
  cases hRoute : inputs.route <;>
    simp [SourceJournalProjectsToEthJournal, sourceJournal, specJournal,
      specLeg, specLegOfSource, approvedDestination, destinationOf,
      specDestination, hRoute]

/-- Every successful source journal is the lossless Spec journal for the same
modeled return input. -/
theorem every_source_success_journal_projects
    (endpoints : Endpoints) (inputs : Inputs) (vaultBalance : Word)
    (journal : SourceJournal)
    (hSuccess : sourceRun endpoints inputs vaultBalance = .committed journal) :
    SourceJournalProjectsToEthJournal journal (specJournal inputs) := by
  unfold sourceRun at hSuccess
  split at hSuccess <;> try contradiction
  split at hSuccess <;> try contradiction
  split at hSuccess <;> try contradiction
  injection hSuccess with hJournal
  subst journal
  exact sourceJournal_projects endpoints inputs

/-- Owner-controlled withdrawals remain outside the widened journal regardless
of recipient address. -/
def OwnerWithdrawalRecipientsExcluded : Prop :=
  ∀ recipient, approvedDestination (.ownerWithdrawal recipient) = none

theorem owner_withdrawal_recipients_excluded :
    OwnerWithdrawalRecipientsExcluded := by
  intro recipient
  rfl

end LidoSRv3.Audit.Spec.VaultEthCorrespondence
