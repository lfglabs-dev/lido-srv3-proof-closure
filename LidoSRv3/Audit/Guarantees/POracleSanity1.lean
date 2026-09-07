import LidoSRv3.Audit.Source.SanityEnvelope
import LidoSRv3.Audit.Guarantees.Registry

/-!
# P-ORACLE-SANITY-1 (bounded)

Registered parent for the modeled commit-path guards of
`OracleReportSanityChecker` at `17005714`.

The conclusion is `CommitEnvelope`: fifteen quantitative `Nat` facts about the
report window and the configured limits. It mentions no `...Accepts` `Bool`,
so `checkerAccepts → CommitEnvelope` is not a conjunction projection and is
not discharged by reduction — every conjunct that came from an integer-division
comparison in Solidity is carried across as the equivalent multiplicative
bound (`SanityEnvelope.lt_mul_of_div_le` / `lt_mul_of_div_div_le`).

The registered scope is exactly the five modeled guards plus the `uint256`
entry bound on `timeElapsed`. It is **bounded, not complete**: the residual
commit-path checks listed at the end of
`LidoSRv3/Audit/Source/SanityEnvelope.lean` are outside this parent and are
not claimed. `LidoSRv3.Tests.SanityEnvelopeParentMutants` carries the
exact-parent kill-lines: for each dropped guard there is a concrete report the
one-guard-drop mutant accepts and on which this parent's exact conclusion is
false.
-/

namespace LidoSRv3.Audit.Guarantees.POracleSanity1

open LidoSRv3.Audit.SolidityAccounting.SanityEnvelope

/-- Supplemental bounded parent over the modeled sanity-checker commit path.
Model layer only: there is no Verity executable transaction for the checker. -/
def guarantee : Guarantee := ⟨.pOracleSanity1, [.model]⟩

/-- P-ORACLE-SANITY-1 parent: an accepted report satisfies the quantitative
commit envelope.

Each conjunct is arithmetic over the report fields and the configured limits.
The four division guards are reported multiplicatively, which is the form that
constrains the report rather than restating the guard. -/
theorem oracle_sanity_commit_envelope
    (limits : SanityLimits) (s : SanityCheckInput)
    (h : checkerAccepts limits s = true) :
    CommitEnvelope limits s := by
  have hTime : s.timeElapsed ≤ UINT256_MAX := by
    have hb := checker_implies_time_elapsed_bound limits s h
    simpa [TimeElapsedFitsUint256, timeElapsedFitsUint256] using hb
  have hA := annual_bounds limits s (checker_implies_annual limits s h)
  have hP := pending_bounds limits s (checker_implies_pending limits s h)
  have hAct := activated_bounds limits s (checker_implies_activated limits s h)
  have hV := validators_bound limits s (checker_implies_validators limits s h)
  have hS := simulated_bounds limits s (checker_implies_simulated limits s h)
  exact ⟨hTime, hA.1, hA.2.1, hA.2.2, hP.2.1, hP.2.2, hAct.2.1, hAct.2.2, hV,
    hS.1, hS.2.1, hS.2.2.1, hS.2.2.2.1, hS.2.2.2.2.1, hS.2.2.2.2.2⟩

end LidoSRv3.Audit.Guarantees.POracleSanity1
