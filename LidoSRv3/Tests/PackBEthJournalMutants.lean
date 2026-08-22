import LidoSRv3.Audit.Spec
import LidoSRv3.Audit.Spec.EthJournalCorrespondence
import LidoSRv3.Audit.Guarantees.PConsolidationEth1

/-!
# Pack B fail-closed vectors

Unregistered Spec.EthJournal child. A third destination is not a Spec
approval even when `parentApproved` would accept a retired Lido tag.
-/

namespace LidoSRv3.Tests.PackBEthJournalMutants

open LidoSRv3.Audit.Spec
open LidoSRv3.Audit.Spec.EthJournalCorrespondence
open LidoSRv3.Audit.Guarantees.PConsolidationEth1

/-- Honest success journal on `(10, 2, 3)`: two fee legs plus refund. -/
private def honestMoves : List EthMove :=
  [{ amount := 3, destination := .consolidationContract },
   { amount := 3, destination := .consolidationContract },
   { amount := 4, destination := .refundRecipient }]

/-- Mutant third destination: a residual `.other` address. -/
private def otherMutantMoves : List EthMove :=
  honestMoves ++ [{ amount := 1, destination := .other 999 }]

/-- Mutant third destination: retired `.lido` tag. `parentApproved` accepts
it; Spec projection does not. -/
private def lidoMutantMoves : List EthMove :=
  honestMoves ++ [{ amount := 1, destination := .lido }]

/-- Positive: the honest success journal projects onto Spec.EthJournal. -/
theorem honest_success_projects :
    (∀ m, m ∈ honestMoves → specDest m.destination ≠ none) ∧
      (specJournal honestMoves).map (fun leg => leg.wei.value) = [3, 3, 4] := by
  decide

/-- Kill-line: injecting `.other 999` falsifies the Spec projection totality
conjunct of `success_journal_projects_to_spec`. -/
theorem third_destination_other_kill_line_refutes_spec_journal :
    ¬ (∀ m, m ∈ otherMutantMoves → specDest m.destination ≠ none) := by
  intro h
  have hNone : specDest (.other 999) = none := specDest_other 999
  exact (h { amount := 1, destination := .other 999 } (by decide)) hNone

/-- Kill-line: injecting retired `.lido` still fails Spec projection, even
though `parentApproved .lido` holds. Pack B does not widen the freeze. -/
theorem third_destination_lido_kill_line_refutes_spec_journal :
    parentApproved .lido ∧
      specDest .lido = none ∧
      ¬ (∀ m, m ∈ lidoMutantMoves → specDest m.destination ≠ none) := by
  refine ⟨by decide, specDest_lido, ?_⟩
  intro h
  exact (h { amount := 1, destination := .lido } (by decide)) specDest_lido

end LidoSRv3.Tests.PackBEthJournalMutants
