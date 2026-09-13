import LidoSRv3.Audit.Source.TopupFundedSource

/-!
Kill-lines pinning `Source.TopupFundedSource` `allocSum_eq_sum`
identity and `journal` empty base case.
-/

namespace LidoSRv3.Tests.SourceTopupFundedSourceAllocSumKillLines

open LidoSRv3.Audit.Source.TopupFundedSource
open LidoSRv3.Audit.SolidityTopup

/-! ## `allocSum_eq_sum` — restated. -/

theorem allocSum_eq_sum_restated (amounts : List Nat) :
    allocSum amounts = amounts.sum :=
  allocSum_eq_sum amounts

/-! ## `journal` on empty inputs/amounts is empty. -/

theorem journal_empty_inputs (amounts : List Nat) :
    journal [] amounts = [] := rfl

theorem journal_empty_amounts
    (inputs : List LidoSRv3.Audit.Source.DepositDataRootCorrespondence.SourceDepositDataRootInput) :
    journal inputs [] = [] := by
  simp [journal, List.zip]

end LidoSRv3.Tests.SourceTopupFundedSourceAllocSumKillLines
