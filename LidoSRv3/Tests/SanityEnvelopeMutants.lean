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

/-- This is outside the pinned Solidity execution domain: L1337 asserts a
nonzero ether numerator and L1338–1340 rejects a zero shares denominator.
The source-faithful predicate must reject it before Lean `Nat` division can
silently return zero. -/
private def zeroShareDomainWitness : SanityCheckInput :=
  { timeElapsed := 86400
    preCLValidatorsBalance := 1000000000000000000000
    preCLPendingBalance := 0
    postCLValidatorsBalance := 1000000000000000000000
    postCLPendingBalance := 0
    deposits := 0
    clWithdrawals := 0
    postInternalEther := 0
    postInternalShares := 0
    simulatedShareRate := 0 }

theorem sourceDomainRejectsZeroEtherAndShares :
    simulatedShareRateAccepts testLimits zeroShareDomainWitness = false := by native_decide

/-- Dropping the source-domain guard admits the zero/zero input because Lean
`Nat` division returns zero. This makes the correction load-bearing. -/
theorem zeroDomainMutantAcceptsWitness :
    simulatedShareRateNoSourceDomainAccepts testLimits zeroShareDomainWitness = true := by native_decide

theorem zeroDomainGuardIsLoadBearing :
    ∃ (limits : SanityLimits) (s : SanityCheckInput),
      simulatedShareRateNoSourceDomainAccepts limits s = true ∧
      simulatedShareRateAccepts limits s = false :=
  ⟨testLimits, zeroShareDomainWitness,
    zeroDomainMutantAcceptsWitness, sourceDomainRejectsZeroEtherAndShares⟩

/-! ### Regression: clWithdrawals in annual balance increase (Finding 2)

Witness: validators balance drops from 100 to 95 ETH, but 10 ETH was
withdrawn. Solidity reconstructs post = 95+0+10 = 105 > pre = 100,
annualized at 182 500 BP (far above 100 BP limit). Without clWithdrawals
in post, the model sees post = 95 ≤ pre = 100 and accepts unconditionally. -/

private def withdrawalWitness : SanityCheckInput :=
  { timeElapsed := 86400
    preCLValidatorsBalance := 100000000000000000000
    preCLPendingBalance := 0
    postCLValidatorsBalance := 95000000000000000000
    postCLPendingBalance := 0
    deposits := 0
    clWithdrawals := 10000000000000000000
    postInternalEther := 1000000000000000000000
    postInternalShares := 1000000000000000000000
    simulatedShareRate := SHARE_RATE_PRECISION_E27 }

theorem annualWithWithdrawalsRejectsWitness :
    annualBalanceIncreaseAccepts testLimits withdrawalWitness = false := by native_decide

theorem annualNoWithdrawalsAcceptsWitness :
    annualBalanceIncreaseNoWithdrawalsAccepts testLimits withdrawalWitness = true := by native_decide

theorem withdrawalsCorrectionIsLoadBearing :
    ∃ (limits : SanityLimits) (s : SanityCheckInput),
      annualBalanceIncreaseNoWithdrawalsAccepts limits s = true ∧
      annualBalanceIncreaseAccepts limits s = false :=
  ⟨testLimits, withdrawalWitness,
    annualNoWithdrawalsAcceptsWitness, annualWithWithdrawalsRejectsWitness⟩

/-! ### Regression: zero computed actual share rate (Finding 1)

Witness: postInternalEther = 1, postInternalShares = 10^28. Both nonzero,
but actualShareRate = 1×10^27 / 10^28 = 0 in Nat division. Solidity's
checked division by actualShareRate at L1346 would revert. Without the
zero-rate domain condition the model accepts (Lean's 0/0 = 0 ≤ limit). -/

private def zeroComputedRateWitness : SanityCheckInput :=
  { timeElapsed := 86400
    preCLValidatorsBalance := 1000000000000000000000
    preCLPendingBalance := 0
    postCLValidatorsBalance := 1000000000000000000000
    postCLPendingBalance := 0
    deposits := 0
    clWithdrawals := 0
    postInternalEther := 1
    postInternalShares := 10000000000000000000000000000
    simulatedShareRate := 0 }

theorem correctedRejectsZeroComputedRate :
    simulatedShareRateAccepts testLimits zeroComputedRateWitness = false := by native_decide

theorem noZeroRateCheckAcceptsWitness :
    simulatedShareRateNoZeroRateCheckAccepts testLimits zeroComputedRateWitness = true := by native_decide

theorem zeroRateCorrectionIsLoadBearing :
    ∃ (limits : SanityLimits) (s : SanityCheckInput),
      simulatedShareRateNoZeroRateCheckAccepts limits s = true ∧
      simulatedShareRateAccepts limits s = false :=
  ⟨testLimits, zeroComputedRateWitness,
    noZeroRateCheckAcceptsWitness, correctedRejectsZeroComputedRate⟩

/-! ### Regression: uint256 multiplication overflow (Finding 3)

Witness: postInternalEther = postInternalShares = UINT256_MAX. Lean's
unbounded Nat computes actualShareRate = UINT256_MAX×10^27 / UINT256_MAX =
10^27, matching simulatedShareRate. But Solidity's checked multiplication
UINT256_MAX * 10^27 overflows uint256 and reverts. Without the overflow
domain condition the model accepts. -/

private def overflowWitness : SanityCheckInput :=
  { timeElapsed := 86400
    preCLValidatorsBalance := 1000000000000000000000
    preCLPendingBalance := 0
    postCLValidatorsBalance := 1000000000000000000000
    postCLPendingBalance := 0
    deposits := 0
    clWithdrawals := 0
    postInternalEther := UINT256_MAX
    postInternalShares := UINT256_MAX
    simulatedShareRate := SHARE_RATE_PRECISION_E27 }

theorem correctedRejectsOverflow :
    simulatedShareRateAccepts testLimits overflowWitness = false := by native_decide

theorem noOverflowCheckAcceptsWitness :
    simulatedShareRateNoOverflowCheckAccepts testLimits overflowWitness = true := by native_decide

theorem overflowCorrectionIsLoadBearing :
    ∃ (limits : SanityLimits) (s : SanityCheckInput),
      simulatedShareRateNoOverflowCheckAccepts limits s = true ∧
      simulatedShareRateAccepts limits s = false :=
  ⟨testLimits, overflowWitness,
    noOverflowCheckAcceptsWitness, correctedRejectsOverflow⟩

end LidoSRv3.Tests.SanityEnvelopeMutants
