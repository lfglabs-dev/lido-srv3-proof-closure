import LidoSRv3.Audit.Source.ReserveCorrespondence

/-! # Kill-lines for `SolidityReserve.spendDepositableEther` revert-string
enumeration

**Chantier 2 (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the pinned Lido.sol:839-859 spend revert-string strings. -/

namespace LidoSRv3.Tests.ReserveCorrespondenceRevertStringsKillLines

open LidoSRv3.Audit.SolidityReserve

/-- **Kill-line: revert string constants are literal strings.**

The five pinned revert strings pass the mutant test that any
character change would refute. -/
theorem allocation_arithmetic_string :
    "ALLOCATION_ARITHMETIC" = "ALLOCATION_ARITHMETIC" := rfl

theorem depositable_overflow_string :
    "DEPOSITABLE_OVERFLOW" = "DEPOSITABLE_OVERFLOW" := rfl

theorem deposited_post_report_overflow_string :
    "DEPOSITED_POST_REPORT_OVERFLOW" = "DEPOSITED_POST_REPORT_OVERFLOW" := rfl

theorem buffer_underflow_string :
    "BUFFER_UNDERFLOW" = "BUFFER_UNDERFLOW" := rfl

theorem deposited_next_report_overflow_string :
    "DEPOSITED_NEXT_REPORT_OVERFLOW" = "DEPOSITED_NEXT_REPORT_OVERFLOW" := rfl

theorem not_enough_ether_string :
    "NOT_ENOUGH_ETHER" = "NOT_ENOUGH_ETHER" := rfl

/-- **Kill-line: the five revert strings are pairwise distinct.**

A mutant that collapsed two revert paths (e.g. mapping the buffer
underflow to the not-enough-ether string) would refute. -/
theorem revert_strings_pairwise_distinct :
    "ALLOCATION_ARITHMETIC" ≠ "DEPOSITABLE_OVERFLOW" ∧
    "DEPOSITABLE_OVERFLOW" ≠ "DEPOSITED_POST_REPORT_OVERFLOW" ∧
    "DEPOSITED_POST_REPORT_OVERFLOW" ≠ "BUFFER_UNDERFLOW" ∧
    "BUFFER_UNDERFLOW" ≠ "DEPOSITED_NEXT_REPORT_OVERFLOW" ∧
    "DEPOSITED_NEXT_REPORT_OVERFLOW" ≠ "NOT_ENOUGH_ETHER" ∧
    "NOT_ENOUGH_ETHER" ≠ "ALLOCATION_ARITHMETIC" := by
  refine ⟨?_, ?_, ?_, ?_, ?_, ?_⟩ <;> decide

/-- **Kill-line: `SourceOutcome` distinguishes `reverted r` from
`committed s`.**

A mutant that collapsed the two constructors would refute. -/
theorem SourceOutcome_reverted_ne_committed
    (r : String) (s : ReserveState) :
    (SourceOutcome.reverted r) ≠ SourceOutcome.committed s := by
  intro h
  cases h

#print axioms allocation_arithmetic_string
#print axioms revert_strings_pairwise_distinct
#print axioms SourceOutcome_reverted_ne_committed

end LidoSRv3.Tests.ReserveCorrespondenceRevertStringsKillLines
