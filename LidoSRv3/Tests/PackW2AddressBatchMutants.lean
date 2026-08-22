import LidoSRv3.Audit.Spec.AddressClaimBatchCorrespondence
import LidoSRv3.Audit.Verity.AddressClaimBatchTx

/-!
# Wave 2 W2-ADDR fail-closed vectors

Swapped payout order on the three-item claim-batch disagrees with the
honest observe journal. Pack D remains the two-item kill-line.
-/

namespace LidoSRv3.Tests.PackW2AddressBatchMutants

open LidoSRv3.Audit.Verity.AddressClaimBatchTx
open LidoSRv3.Audit.Spec.AddressClaimBatchCorrespondence
open _root_.Verity

/-- Honest three-item journal. -/
private def honestJournal : List ExternalCall :=
  [payoutEntry (2 : Address) 30, payoutEntry (2 : Address) 40,
    payoutEntry (2 : Address) 10]

/-- Mutant: swap the first two payout amounts. -/
private def swappedJournal : List ExternalCall :=
  [payoutEntry (2 : Address) 40, payoutEntry (2 : Address) 30,
    payoutEntry (2 : Address) 10]

theorem swapped_payout_order_kill_line_refutes_three_item_batch :
    threeClaimPayouts = [some 30, some 40, some 10] ∧
      observe [1, 2, 3]
          ((executeClaimWithdrawalsTo [1, 2, 3] [1, 1, 1] (2 : Address)).run
            threeClaimState) =
        ⟨.committed, [true, true, true], 0, honestJournal⟩ ∧
      swappedJournal ≠ honestJournal := by
  refine ⟨three_claim_payouts_match_reads.1, three_claim_payouts_match_reads.2, by decide⟩

end LidoSRv3.Tests.PackW2AddressBatchMutants
