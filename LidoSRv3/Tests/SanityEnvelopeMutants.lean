import LidoSRv3.Audit.Source.SanityEnvelope

/-!
# Sanity envelope guard-drop mutants

Focused fail-closed vectors for the sanity-envelope skeleton. Each test
demonstrates that at least one modeled guard is load-bearing: there exists a
concrete input accepted by the guard-drop mutant but rejected by the full
checker.

## Design

The annual balance increase guard is the surgical target. The witness uses:
- A scenario where CL pending balance surges (external pending deposits appear)
  with no change in validators balance. The pending-cap guard accepts because
  the increase is within `externalPendingBalanceCapEth`, the validators-balance
  guard accepts trivially (no validators increase), and the remaining guards
  are satisfied. But the annual guard sees the total CL balance jump from
  32 ETH to 532 ETH and rejects it at 57 031 250 BP annualized, far above
  the 100 BP limit.

This proves the annual guard is not entailed by the remaining four guards:
dropping it widens the accepted set.
-/

namespace LidoSRv3.Tests.SanityEnvelopeMutants

open LidoSRv3.Audit.SolidityAccounting.SanityEnvelope

/-- Limits: 1% annual (100 BP), generous other limits. -/
private def testLimits : SanityLimits :=
  { annualBalanceIncreaseBPLimit := 100
    simulatedShareRateDeviationBPLimit := 500
    appearedEthAmountPerDayLimit := 1000000
    externalPendingBalanceCapEth := 1000 }

/-- Witness: pending balance surges from 0 to 500 ETH with no change in
validators (32 ETH). The total CL balance jumps from 32 ETH to 532 ETH,
which the annual guard rejects (57 031 250 BP annualized ≫ 100 BP limit).
The remaining four guards accept: no validators increase, pending within
the 1000 ETH external cap, no activation, and share rates match. -/
private def annualWitness : SanityCheckInput :=
  { timeElapsed := 86400
    preCLValidatorsBalance := 32000000000000000000
    preCLPendingBalance := 0
    postCLValidatorsBalance := 32000000000000000000
    postCLPendingBalance := 500000000000000000000
    deposits := 0
    clWithdrawals := 0
    postInternalEther := 1000000000000000000000
    postInternalShares := 1000000000000000000000
    simulatedShareRate := SHARE_RATE_PRECISION_E27 }

/-- The annual guard rejects the witness. -/
theorem annualGuardRejectsWitness :
    annualBalanceIncreaseAccepts testLimits annualWitness = false := by native_decide

/-- The remaining guards accept the witness. -/
theorem otherGuardsAcceptWitness :
    checkerNoAnnual testLimits annualWitness = true := by native_decide

/-- The full checker rejects the witness. -/
theorem fullCheckerRejectsWitness :
    checkerAccepts testLimits annualWitness = false := by native_decide

/-- The annual guard is load-bearing: the mutant accepts but the full checker
rejects. -/
theorem annualGuardIsLoadBearing :
    ∃ (limits : SanityLimits) (s : SanityCheckInput),
      checkerNoAnnual limits s = true ∧
      checkerAccepts limits s = false :=
  ⟨testLimits, annualWitness, otherGuardsAcceptWitness, fullCheckerRejectsWitness⟩

/-- Positive control: a well-behaved input passes all guards. No balance
change, rates match. -/
private def normalInput : SanityCheckInput :=
  { timeElapsed := 86400
    preCLValidatorsBalance := 1000000000000000000000
    preCLPendingBalance := 0
    postCLValidatorsBalance := 1000000000000000000000
    postCLPendingBalance := 0
    deposits := 0
    clWithdrawals := 0
    postInternalEther := 1000000000000000000000
    postInternalShares := 1000000000000000000000
    simulatedShareRate := SHARE_RATE_PRECISION_E27 }

theorem positiveControl :
    checkerAccepts testLimits normalInput = true := by native_decide

/-- The annual guard is not entailed by the other four guards. -/
theorem annualNotRedundant :
    ¬ (∀ (l : SanityLimits) (s : SanityCheckInput),
        checkerNoAnnual l s = true → annualBalanceIncreaseAccepts l s = true) := by
  intro h
  have := h testLimits annualWitness otherGuardsAcceptWitness
  simp [annualGuardRejectsWitness] at this

end LidoSRv3.Tests.SanityEnvelopeMutants
