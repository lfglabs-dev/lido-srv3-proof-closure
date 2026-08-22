import LidoSRv3.Audit.Spec.AddressClaimCorrespondence
import LidoSRv3.Audit.Verity.AddressClaimBatchTx

/-!
# Pack D fail-closed vectors

Swapped payout order and a wrong recipient disagree with the honest
two-item claim-batch observe.
-/

namespace LidoSRv3.Tests.PackDAddressClaimMutants

open LidoSRv3.Audit.Verity.AddressClaimBatchTx
open LidoSRv3.Audit.Spec.AddressClaimCorrespondence
open _root_.Verity

/-- Honest two-item journal. -/
private def honestJournal : List ExternalCall :=
  [payoutEntry (2 : Address) 30, payoutEntry (2 : Address) 40]

/-- Mutant: swap the two payout amounts. -/
private def swappedJournal : List ExternalCall :=
  [payoutEntry (2 : Address) 40, payoutEntry (2 : Address) 30]

/-- Mutant: pay the same amounts to a different recipient. -/
private def wrongRecipientJournal : List ExternalCall :=
  [payoutEntry (3 : Address) 30, payoutEntry (3 : Address) 40]

theorem swapped_payout_order_kill_line_refutes_batch :
    twoClaimPayouts = [some 30, some 40] ∧
      observe [1, 2]
          ((executeClaimWithdrawalsTo [1, 2] [1, 1] (2 : Address)).run twoClaimState) =
        ⟨.committed, [true, true], 0, honestJournal⟩ ∧
      swappedJournal ≠ honestJournal := by
  refine ⟨by decide, two_claim_batch_observe, by decide⟩

theorem wrong_recipient_kill_line_refutes_batch :
    observe [1, 2]
        ((executeClaimWithdrawalsTo [1, 2] [1, 1] (2 : Address)).run twoClaimState) =
      ⟨.committed, [true, true], 0, honestJournal⟩ ∧
      wrongRecipientJournal ≠ honestJournal := by
  refine ⟨two_claim_batch_observe, by decide⟩

end LidoSRv3.Tests.PackDAddressClaimMutants
