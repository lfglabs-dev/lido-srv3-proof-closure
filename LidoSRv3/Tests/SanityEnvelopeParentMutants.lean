import LidoSRv3.Audit.Guarantees.POracleSanity1

/-!
# Exact-parent kill-lines for P-ORACLE-SANITY-1

`LidoSRv3.Tests.SanityEnvelopeMutants` shows guards are load-bearing for
*the checker*: a mutant accepts where `checkerAccepts` rejects. That is a
weaker statement than the one this file makes.

Here each theorem refutes the **exact conclusion of the registered parent**
`POracleSanity1.oracle_sanity_commit_envelope`. For each of the six modeled
premises there is a concrete `(limits, report)` such that the one-premise-drop
mutant accepts the report and `CommitEnvelope limits report` is false. So no
conjunct of the parent survives dropping its premise: the parent is not
provable from any proper subset of the modeled guards, and it is not
discharged by reduction.

Each witness is refuted through a *named* envelope conjunct, so the kill-line
degrades loudly if the envelope is ever weakened.
-/

namespace LidoSRv3.Tests.SanityEnvelopeParentMutants

open LidoSRv3.Audit.SolidityAccounting.SanityEnvelope
open LidoSRv3.Audit.Guarantees.POracleSanity1

/-! ### Positive control

The parent is not vacuous: a well-behaved report is accepted, so the premise
`checkerAccepts limits s = true` is inhabited and the envelope holds there. -/

private def baseLimits : SanityLimits :=
  { annualBalanceIncreaseBPLimit := 100
    simulatedShareRateDeviationBPLimit := 500
    appearedEthAmountPerDayLimit := 1000000
    externalPendingBalanceCapEth := 1000 }

private def baseReport : SanityCheckInput :=
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

theorem parentAcceptsPositiveControl : CommitEnvelope baseLimits baseReport :=
  oracle_sanity_commit_envelope baseLimits baseReport (by decide)

/-! ### Kill-line 1: the `uint256` bound on `timeElapsed`

`timeElapsed = UINT256_MAX + 1` is not a value the Solidity entry point can
receive. Every arithmetic guard takes a no-increase or zero-proration path,
so the bound-free mutant accepts, but the envelope's first conjunct is false. -/

private def timeLimits : SanityLimits :=
  { annualBalanceIncreaseBPLimit := 0
    simulatedShareRateDeviationBPLimit := 0
    appearedEthAmountPerDayLimit := 0
    externalPendingBalanceCapEth := 0 }

private def timeReport : SanityCheckInput :=
  { baseReport with timeElapsed := UINT256_MAX + 1 }

theorem timeElapsedBoundKillLineRefutesParent :
    ∃ (limits : SanityLimits) (s : SanityCheckInput),
      checkerNoTimeElapsedBound limits s = true ∧ ¬ CommitEnvelope limits s :=
  ⟨timeLimits, timeReport, by decide, fun env => absurd env.1 (by decide)⟩

/-! ### Kill-line 2: the annual balance increase guard

CL pending balance surges from 0 to 500 ETH against a 32 ETH validators
balance. The other five premises accept; the envelope's annual multiplicative
bound is violated by a factor of more than `5 * 10 ^ 5`. -/

private def annualReport : SanityCheckInput :=
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

theorem annualKillLineRefutesParent :
    ∃ (limits : SanityLimits) (s : SanityCheckInput),
      checkerNoAnnual limits s = true ∧ ¬ CommitEnvelope limits s :=
  ⟨baseLimits, annualReport, by decide, fun env => absurd env.2.2.2.1 (by decide)⟩

/-! ### Kill-line 3: the CL pending balance cap

With a zero external pending cap, `postCLPendingBalance` may not exceed the
funded pending balance. The report shows 1 ETH of pending balance appearing
with no deposits; the remaining five premises accept. -/

private def pendingLimits : SanityLimits :=
  { annualBalanceIncreaseBPLimit := 1000000000000
    simulatedShareRateDeviationBPLimit := 0
    appearedEthAmountPerDayLimit := 1000000
    externalPendingBalanceCapEth := 0 }

private def pendingReport : SanityCheckInput :=
  { baseReport with
      preCLValidatorsBalance := 32000000000000000000
      postCLValidatorsBalance := 32000000000000000000
      postCLPendingBalance := 1000000000000000000 }

theorem pendingCapKillLineRefutesParent :
    ∃ (limits : SanityLimits) (s : SanityCheckInput),
      checkerNoPending limits s = true ∧ ¬ CommitEnvelope limits s :=
  ⟨pendingLimits, pendingReport, by decide, fun env => absurd env.2.2.2.2.2.1 (by decide)⟩

/-! ### Kill-line 4: the activated balance limiter

5000 ETH of deposits are activated in one report window against a zero
appeared-ETH-per-day limit. The annual guard accepts because the CL total
falls, and the remaining premises accept; the envelope's activation bound
(`appearedEthLimitPerPeriod + MAX_VALIDATOR_EFFECTIVE_BALANCE`) is exceeded. -/

private def activatedLimits : SanityLimits :=
  { annualBalanceIncreaseBPLimit := 100
    simulatedShareRateDeviationBPLimit := 0
    appearedEthAmountPerDayLimit := 0
    externalPendingBalanceCapEth := 1000 }

private def activatedReport : SanityCheckInput :=
  { baseReport with
      preCLValidatorsBalance := 32000000000000000000
      postCLValidatorsBalance := 32000000000000000000
      deposits := 5000000000000000000000 }

theorem activatedBalanceKillLineRefutesParent :
    ∃ (limits : SanityLimits) (s : SanityCheckInput),
      checkerNoActivated limits s = true ∧ ¬ CommitEnvelope limits s :=
  ⟨activatedLimits, activatedReport, by decide,
    fun env => absurd env.2.2.2.2.2.2.2.1 (by decide)⟩

/-! ### Kill-line 5: the validators balance increase guard

One wei of validators balance appears with no activation and a zero APR
safety cap. The increase is small enough that the annual guard's integer
division rounds to zero, so every other premise accepts, but the envelope's
`postCLValidatorsBalance ≤ withdrawal-adjusted pre + maxPossibleActivated`
conjunct is false by exactly one wei. -/

private def validatorsLimits : SanityLimits :=
  { annualBalanceIncreaseBPLimit := 0
    simulatedShareRateDeviationBPLimit := 0
    appearedEthAmountPerDayLimit := 0
    externalPendingBalanceCapEth := 0 }

private def validatorsReport : SanityCheckInput :=
  { baseReport with
      preCLValidatorsBalance := 1000000000000000000000000000000
      postCLValidatorsBalance := 1000000000000000000000000000001 }

theorem validatorsIncreaseKillLineRefutesParent :
    ∃ (limits : SanityLimits) (s : SanityCheckInput),
      checkerNoValidators limits s = true ∧ ¬ CommitEnvelope limits s :=
  ⟨validatorsLimits, validatorsReport, by decide,
    fun env => absurd env.2.2.2.2.2.2.2.2.1 (by decide)⟩

/-! ### Kill-line 6: the simulated share rate deviation guard

The reported simulated share rate is twice the rate the report's own ether and
shares compute. Every other premise accepts; the envelope's deviation bound
is violated. -/

private def simulatedReport : SanityCheckInput :=
  { baseReport with simulatedShareRate := 2 * SHARE_RATE_PRECISION_E27 }

theorem simulatedShareRateKillLineRefutesParent :
    ∃ (limits : SanityLimits) (s : SanityCheckInput),
      checkerNoSimulated limits s = true ∧ ¬ CommitEnvelope limits s :=
  ⟨baseLimits, simulatedReport, by decide,
    fun env => absurd env.2.2.2.2.2.2.2.2.2.2.2.2.2.2 (by decide)⟩

end LidoSRv3.Tests.SanityEnvelopeParentMutants
