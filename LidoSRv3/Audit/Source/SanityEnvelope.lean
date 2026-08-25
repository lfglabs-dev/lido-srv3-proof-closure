import LidoSRv3.Audit.Source.AccountingCorrespondence

/-!
# Oracle-report sanity envelope skeleton

Executable predicates for the commit-path sanity checks in
`OracleReportSanityChecker.sol` at
`lidofinance/core@af095e48bbc1c3841c2c9936219c8461af01056b`.

## Modeled guards (pinned source spans)

| Guard | Solidity function | Lines | Type |
|-------|-------------------|-------|------|
| `annualBalanceIncrease` | `_checkAnnualBalancesIncrease` | 1291–1314 | upper bound |
| `pendingBalanceCap` | `_checkCLPendingBalanceAndCalculateMaxPossibleActivatedBalance` | 920–922 | upper bound |
| `activatedBalance` | (same) | 940–941 | upper bound |
| `validatorsBalanceIncrease` | `_checkCLPendingAndValidatorsBalanceIncrease` | 964–973 | upper bound |
| `simulatedShareRateDeviation` | `_checkSimulatedShareRate` | 1331–1374 | upper+lower bound |

## Unmodeled surfaces (explicit residual blockers)

* **`smoothenTokenRebase`** (L588–628): token rebase limiter with
  `PositiveTokenRebaseLimiter` state machine. Not arithmetic predicates—depends
  on limiter state struct with `increaseEther`/`decreaseEther` and
  `getSharesToBurnLimit`. Out of scope until limiter is modeled.

* **`_checkCLBalanceDecrease`** (L1118–1158): sliding-window CL balance
  decrease check. Depends on `reportData[]` storage array, `_calcWindowDiff`,
  and `_findWindowBaselineIndex` loop. Stateful; needs storage model.

* **`_getCLWithdrawals`** (L1165–1169): derives CL withdrawals from the
  current withdrawal-vault balance and `lastVaultBalanceAfterTransfer`, and
  reverts when that stateful baseline is larger. The model's `clWithdrawals`
  input does not read or maintain this state.

* **`_checkWithdrawalsVaultTransfer`** (L1172–1182): rejects a withdrawal-vault
  transfer larger than the reported vault balance. This commit-path input
  relation is not modeled.

* **`_finalizePostReportState`** (L1192–1198): commits the post-transfer vault
  balance and flips the post-migration first-report flag. These persistent
  updates are not modeled.

* **`_askSecondOpinion`** (L1251–1289): second-opinion oracle external call.
  Opaque cross-contract call to `ISecondOpinionOracle.getReport`.

* **Vault/burn attestation guards**: `_checkWithdrawalVaultBalance` (L1071–1078),
  `_checkELRewardsVaultBalance` (L1080–1087), `_checkSharesRequestedToBurn`
  (L1089–1095). These compare report values against on-chain balance reads;
  they are not report-data predicates.

* **`prefinalize`** (WithdrawalQueue): called from `_calculateWithdrawals`
  (Accounting.sol L256). Opaque cross-contract.

* **Bad-debt internalization** (Accounting.sol L383–386): `vaultHub` external
  call, not modeled.

* **Role/access control**: `msg.sender != ACCOUNTING_ADDRESS` gate
  (OracleReportSanityChecker L657), `NOT_AUTHORIZED` in
  `Accounting.handleOracleReport` (L139). Role checks are trust surface, not
  arithmetic guards.

* **`keccak256`**: hash consensus check in `submitReportData`. Opaque.

* **Per-module validators balance increase**: `_checkModuleValidatorsBalanceIncrease`
  (L976–1019) with `_calculateTotalActivatedInClByModules` loop reading
  staking router state. External reads; out of scope.

* **`_checkCLBalancesConsistency`** (L859–880): module sum consistency check.
  Summation loop with external data; out of scope.

* **Operational limits**: `checkExitBusOracleReport` (L763–771),
  `checkExitedValidatorsCount` (L780–799), `checkNodeOperatorsPerExtraDataItemCount`
  (L804–809), `checkExtraDataItemsCountPerTransaction` (L811–818),
  `checkWithdrawalQueueOracleReport` (L822–831). Operational-only; do not gate
  the accounting oracle commit path.

## Design notes

Each guard is a named `Bool` predicate (executable decision procedure).
`checkerAccepts` requires the report's `timeElapsed` input to fit its pinned
Solidity `uint256` type, then conjoins all modeled guards.

`commitImpliesEnvelope` is the theorem form: if the sanity checker accepts,
then each individual guard holds. This is *not* the same as
`checkerAccepts → checkerAccepts` (which would be tautological). The guards
are extracted as independent named propositions so that:
1. A guard-drop mutant can target one guard while preserving the others.
2. P-ORACLE-SUPPLY-1 can name the sanity envelope as a parent without
   registering the full checker.

## What this skeleton does NOT claim

This is a **model** checkpoint, not a registration. No `P-ORACLE-SANITY-1`
is registered: completeness review must confirm that every source-path guard
is either modeled or explicitly listed as unmodeled.
-/

namespace LidoSRv3.Audit.SolidityAccounting.SanityEnvelope

abbrev MAX_BASIS_POINTS : Nat := 10000
abbrev SECONDS_PER_DAY : Nat := 86400
abbrev ANNUAL_BALANCE_INCREASE_DENOMINATOR : Nat := 365 * SECONDS_PER_DAY * MAX_BASIS_POINTS
abbrev DEFAULT_TIME_ELAPSED : Nat := 3600
abbrev DEFAULT_CL_BALANCE : Nat := 1000000000
abbrev SHARE_RATE_PRECISION_E27 : Nat := 1000000000000000000000000000
abbrev MAX_VALIDATOR_EFFECTIVE_BALANCE : Nat := 2048000000000000000000
abbrev UINT256_MAX : Nat := 2^256 - 1

/-- Subset of `AccountingCoreLimitsPacked` fields consumed by modeled guards.
Pinned at OracleReportSanityChecker.sol L124–135. -/
structure SanityLimits where
  annualBalanceIncreaseBPLimit : Nat
  simulatedShareRateDeviationBPLimit : Nat
  appearedEthAmountPerDayLimit : Nat
  externalPendingBalanceCapEth : Nat
  deriving Repr, DecidableEq

/-- Report-window inputs consumed by the modeled guards.
Fields mirror the `checkAccountingOracleReport` and `checkSimulatedShareRate`
call sites in Accounting.sol L442–462. -/
structure SanityCheckInput where
  timeElapsed : Nat
  preCLValidatorsBalance : Nat
  preCLPendingBalance : Nat
  postCLValidatorsBalance : Nat
  postCLPendingBalance : Nat
  deposits : Nat
  clWithdrawals : Nat
  postInternalEther : Nat
  postInternalShares : Nat
  simulatedShareRate : Nat
  deriving Repr, DecidableEq

/-! ### Helper: time normalization

Pinned at OracleReportSanityChecker.sol L894–896. -/

def effectiveTimeElapsed (t : Nat) : Nat :=
  if t == 0 then DEFAULT_TIME_ELAPSED else t

/-! ### Guard 1: Annual balance increase

Pinned at `_checkAnnualBalancesIncrease` (OracleReportSanityChecker.sol L1291–1314).
`postCLBalance = postCLValidators + postCLPending + clWithdrawals` (L1301).
`annualBalanceIncrease = ANNUAL_BALANCE_INCREASE_DENOMINATOR * balanceIncrease / preCLBalance / timeElapsed`
Must be `≤ annualBalanceIncreaseBPLimit`.

Source domain conditions:
1. `preCLValidatorsBalance + preCLPendingBalance + deposits` must not overflow
   `uint256` (L1297 checked addition).
2. `postCLValidatorsBalance + postCLPendingBalance + clWithdrawals` must not
   overflow `uint256` (L1301 checked addition).
3. `ANNUAL_BALANCE_INCREASE_DENOMINATOR * balanceIncrease` must not overflow
   `uint256` (L1309 checked multiplication). -/

def preCLBalance (s : SanityCheckInput) : Nat :=
  s.preCLValidatorsBalance + s.preCLPendingBalance + s.deposits

def annualBalanceIncreaseAccepts (limits : SanityLimits) (s : SanityCheckInput) : Bool :=
  if preCLBalance s > UINT256_MAX then false
  else
    let pre := if preCLBalance s == 0 then DEFAULT_CL_BALANCE
               else preCLBalance s
    let post := s.postCLValidatorsBalance + s.postCLPendingBalance + s.clWithdrawals
    if post > UINT256_MAX then false
    else if pre ≥ post then true
    else
      let balanceIncrease := post - pre
      let t := effectiveTimeElapsed s.timeElapsed
      if ANNUAL_BALANCE_INCREASE_DENOMINATOR * balanceIncrease > UINT256_MAX then false
      else
        let annualIncrease := ANNUAL_BALANCE_INCREASE_DENOMINATOR * balanceIncrease / pre / t
        annualIncrease ≤ limits.annualBalanceIncreaseBPLimit

/-! ### Guard 2: Pending balance cap

Pinned at `_checkCLPendingBalanceAndCalculateMaxPossibleActivatedBalance`
(OracleReportSanityChecker.sol L918–922).
`postCLPendingBalance ≤ fundedPendingBalance + externalPendingBalanceCap * 1 ether`

Source domain conditions:
1. `preCLPendingBalance + deposits` must not overflow `uint256`
   (L920 checked addition).
2. `fundedPendingBalance + externalPendingBalanceCap * 1 ether` must not
   overflow `uint256` (L922 checked addition). -/

def pendingBalanceCapAccepts (limits : SanityLimits) (s : SanityCheckInput) : Bool :=
  let fundedPendingBalance := s.preCLPendingBalance + s.deposits
  if fundedPendingBalance > UINT256_MAX then false
  else
    let cap := fundedPendingBalance + limits.externalPendingBalanceCapEth * 1000000000000000000
    if cap > UINT256_MAX then false
    else s.postCLPendingBalance ≤ cap

/-! ### Guard 3: Activated balance

Pinned at the same function (OracleReportSanityChecker.sol L924–941).
`activatedBalance ≤ appearedEthLimitPerPeriod + MAX_VALIDATOR_EFFECTIVE_BALANCE`

Source domain conditions:
1. `appearedEthAmountPerDayLimit * 1 ether` must not overflow `uint256`
   (checked multiplication at call site).
2. `(appearedEthAmountPerDayLimit * 1 ether) * timeElapsed` must not overflow
   `uint256` (checked multiplication in `_calculateAmountForPeriod`). -/

def calculateAmountForPeriod (amountPerDay : Nat) (t : Nat) : Nat :=
  amountPerDay * t / SECONDS_PER_DAY

def activatedBalanceAccepts (limits : SanityLimits) (s : SanityCheckInput) : Bool :=
  let fundedPendingBalance := s.preCLPendingBalance + s.deposits
  let activatedBalance := if fundedPendingBalance > s.postCLPendingBalance
    then fundedPendingBalance - s.postCLPendingBalance else 0
  let t := effectiveTimeElapsed s.timeElapsed
  let etherScaled := limits.appearedEthAmountPerDayLimit * 1000000000000000000
  if etherScaled > UINT256_MAX then false
  else if etherScaled * t > UINT256_MAX then false
  else
    let appearedLimit := calculateAmountForPeriod etherScaled t
    activatedBalance ≤ appearedLimit + MAX_VALIDATOR_EFFECTIVE_BALANCE

/-! ### Guard 4: Validators balance increase

Pinned at `_checkCLPendingAndValidatorsBalanceIncrease`
(OracleReportSanityChecker.sol L952–974).
`validatorsBalanceIncrease ≤ maxPossibleActivatedBalance`

Source domain condition: `(preCLValidatorsBalance + activatedBalance) *
(annualBalanceIncreaseBPLimit * timeElapsed)` must not overflow `uint256`
(L970 checked multiplication). -/

def calculateValidatorsBalanceAprSafetyCap
    (preCLVBal : Nat) (annualMul : Nat) : Nat :=
  preCLVBal * annualMul / ANNUAL_BALANCE_INCREASE_DENOMINATOR

def maxPossibleActivatedBalance (limits : SanityLimits) (s : SanityCheckInput) : Nat :=
  let fundedPendingBalance := s.preCLPendingBalance + s.deposits
  let activatedBalance := if fundedPendingBalance > s.postCLPendingBalance
    then fundedPendingBalance - s.postCLPendingBalance else 0
  let t := effectiveTimeElapsed s.timeElapsed
  activatedBalance +
    calculateValidatorsBalanceAprSafetyCap
      (s.preCLValidatorsBalance + activatedBalance)
      (limits.annualBalanceIncreaseBPLimit * t)

def validatorsBalanceIncreaseAccepts (limits : SanityLimits) (s : SanityCheckInput) : Bool :=
  let preCLVAfterWithdrawals :=
    if s.clWithdrawals ≥ s.preCLValidatorsBalance then 0
    else s.preCLValidatorsBalance - s.clWithdrawals
  if s.postCLValidatorsBalance > preCLVAfterWithdrawals then
    let increase := s.postCLValidatorsBalance - preCLVAfterWithdrawals
    let fundedPendingBalance := s.preCLPendingBalance + s.deposits
    let activatedBalance := if fundedPendingBalance > s.postCLPendingBalance
      then fundedPendingBalance - s.postCLPendingBalance else 0
    let t := effectiveTimeElapsed s.timeElapsed
    let aprBase := s.preCLValidatorsBalance + activatedBalance
    let aprMul := limits.annualBalanceIncreaseBPLimit * t
    if aprBase * aprMul > UINT256_MAX then false
    else increase ≤ maxPossibleActivatedBalance limits s
  else true

/-! ### Guard 5: Simulated share rate deviation

Pinned at `_checkSimulatedShareRate` (OracleReportSanityChecker.sol L1331–1374).
`simulatedShareDeviation ≤ simulatedShareRateDeviationBPLimit`.

Source domain conditions modeled:
1. `_noWithdrawalsPostInternalEther != 0` (L1337 assert).
2. `_noWithdrawalsPostInternalShares != 0` (L1338–1340 checked division).
3. `_noWithdrawalsPostInternalEther * SHARE_RATE_PRECISION_E27` must not
   overflow `uint256` (L1340 checked multiplication).
4. The computed `actualShareRate` must be nonzero (L1346 divides by it
   under checked arithmetic).
5. `MAX_BASIS_POINTS * diff` must not overflow `uint256` (deviation
   calculation checked multiplication). Checked inline because `diff`
   depends on the computed rate.

Lean `Nat` arithmetic is unbounded and its division returns zero on a zero
denominator, so this model makes all five source domain conditions explicit. -/

def absDiff (a b : Nat) : Nat := if a ≥ b then a - b else b - a

def simulatedShareRateSourceDomain (s : SanityCheckInput) : Bool :=
  s.postInternalEther != 0 && s.postInternalShares != 0 &&
  s.postInternalEther * SHARE_RATE_PRECISION_E27 ≤ UINT256_MAX &&
  s.postInternalEther * SHARE_RATE_PRECISION_E27 / s.postInternalShares != 0

def simulatedShareRateAccepts (limits : SanityLimits) (s : SanityCheckInput) : Bool :=
  if !simulatedShareRateSourceDomain s then false
  else
    let actualShareRate := s.postInternalEther * SHARE_RATE_PRECISION_E27 / s.postInternalShares
    let diff := absDiff actualShareRate s.simulatedShareRate
    if MAX_BASIS_POINTS * diff > UINT256_MAX then false
    else
      let deviation := MAX_BASIS_POINTS * diff / actualShareRate
      deviation ≤ limits.simulatedShareRateDeviationBPLimit

/-- Deliberately unsound mutant: the pre-division Solidity revert domain is
dropped, exposing Lean `Nat` division's zero-denominator behavior. -/
def simulatedShareRateNoSourceDomainAccepts (limits : SanityLimits) (s : SanityCheckInput) : Bool :=
  let actualShareRate := s.postInternalEther * SHARE_RATE_PRECISION_E27 / s.postInternalShares
  let diff := absDiff actualShareRate s.simulatedShareRate
  let deviation := MAX_BASIS_POINTS * diff / actualShareRate
  deviation ≤ limits.simulatedShareRateDeviationBPLimit

/-- Mutant: annual balance increase without clWithdrawals in post
(pre-correction behavior, Finding 2). -/
def annualBalanceIncreaseNoWithdrawalsAccepts (limits : SanityLimits) (s : SanityCheckInput) : Bool :=
  let pre := if preCLBalance s == 0 then DEFAULT_CL_BALANCE
             else preCLBalance s
  let post := s.postCLValidatorsBalance + s.postCLPendingBalance
  if pre ≥ post then true
  else
    let balanceIncrease := post - pre
    let t := effectiveTimeElapsed s.timeElapsed
    let annualIncrease := ANNUAL_BALANCE_INCREASE_DENOMINATOR * balanceIncrease / pre / t
    annualIncrease ≤ limits.annualBalanceIncreaseBPLimit

/-- Mutant: annual balance increase without numerator overflow check
(pre-correction behavior). -/
def annualBalanceIncreaseNoOverflowCheckAccepts (limits : SanityLimits) (s : SanityCheckInput) : Bool :=
  let pre := if preCLBalance s == 0 then DEFAULT_CL_BALANCE
             else preCLBalance s
  let post := s.postCLValidatorsBalance + s.postCLPendingBalance + s.clWithdrawals
  if pre ≥ post then true
  else
    let balanceIncrease := post - pre
    let t := effectiveTimeElapsed s.timeElapsed
    let annualIncrease := ANNUAL_BALANCE_INCREASE_DENOMINATOR * balanceIncrease / pre / t
    annualIncrease ≤ limits.annualBalanceIncreaseBPLimit

/-- Mutant: old source domain without computed-rate-nonzero check
(pre-correction behavior, Finding 1). -/
def simulatedShareRateNoZeroRateCheckAccepts (limits : SanityLimits) (s : SanityCheckInput) : Bool :=
  if !(s.postInternalEther != 0 && s.postInternalShares != 0 &&
       s.postInternalEther * SHARE_RATE_PRECISION_E27 ≤ UINT256_MAX) then false
  else
    let actualShareRate := s.postInternalEther * SHARE_RATE_PRECISION_E27 / s.postInternalShares
    let diff := absDiff actualShareRate s.simulatedShareRate
    let deviation := MAX_BASIS_POINTS * diff / actualShareRate
    deviation ≤ limits.simulatedShareRateDeviationBPLimit

/-- Mutant: source domain without uint256 overflow check
(pre-correction behavior, Finding 3). -/
def simulatedShareRateNoOverflowCheckAccepts (limits : SanityLimits) (s : SanityCheckInput) : Bool :=
  if !(s.postInternalEther != 0 && s.postInternalShares != 0 &&
       s.postInternalEther * SHARE_RATE_PRECISION_E27 / s.postInternalShares != 0) then false
  else
    let actualShareRate := s.postInternalEther * SHARE_RATE_PRECISION_E27 / s.postInternalShares
    let diff := absDiff actualShareRate s.simulatedShareRate
    let deviation := MAX_BASIS_POINTS * diff / actualShareRate
    deviation ≤ limits.simulatedShareRateDeviationBPLimit

/-- Mutant: share-rate deviation without multiplication overflow check
(pre-correction behavior). -/
def simulatedShareRateNoDeviationOverflowCheckAccepts (limits : SanityLimits) (s : SanityCheckInput) : Bool :=
  if !simulatedShareRateSourceDomain s then false
  else
    let actualShareRate := s.postInternalEther * SHARE_RATE_PRECISION_E27 / s.postInternalShares
    let diff := absDiff actualShareRate s.simulatedShareRate
    let deviation := MAX_BASIS_POINTS * diff / actualShareRate
    deviation ≤ limits.simulatedShareRateDeviationBPLimit

/-- Mutant: annual balance increase without pre-CL balance sum overflow check
(pre-correction behavior). -/
def annualBalanceIncreaseNoPreCLOverflowCheckAccepts (limits : SanityLimits) (s : SanityCheckInput) : Bool :=
  let pre := if preCLBalance s == 0 then DEFAULT_CL_BALANCE
             else preCLBalance s
  let post := s.postCLValidatorsBalance + s.postCLPendingBalance + s.clWithdrawals
  if pre ≥ post then true
  else
    let balanceIncrease := post - pre
    let t := effectiveTimeElapsed s.timeElapsed
    if ANNUAL_BALANCE_INCREASE_DENOMINATOR * balanceIncrease > UINT256_MAX then false
    else
      let annualIncrease := ANNUAL_BALANCE_INCREASE_DENOMINATOR * balanceIncrease / pre / t
      annualIncrease ≤ limits.annualBalanceIncreaseBPLimit

/-- Mutant: pending balance cap without uint256 overflow checks
(pre-correction behavior). -/
def pendingBalanceCapNoOverflowCheckAccepts (limits : SanityLimits) (s : SanityCheckInput) : Bool :=
  let fundedPendingBalance := s.preCLPendingBalance + s.deposits
  let cap := fundedPendingBalance + limits.externalPendingBalanceCapEth * 1000000000000000000
  s.postCLPendingBalance ≤ cap

/-- Mutant: validators balance increase without APR safety-cap product overflow
check (pre-correction behavior). -/
def validatorsBalanceIncreaseNoAprOverflowCheckAccepts (limits : SanityLimits) (s : SanityCheckInput) : Bool :=
  let preCLVAfterWithdrawals :=
    if s.clWithdrawals ≥ s.preCLValidatorsBalance then 0
    else s.preCLValidatorsBalance - s.clWithdrawals
  if s.postCLValidatorsBalance > preCLVAfterWithdrawals then
    let increase := s.postCLValidatorsBalance - preCLVAfterWithdrawals
    increase ≤ maxPossibleActivatedBalance limits s
  else true

/-- Mutant: annual balance increase without post-CL balance sum overflow check
(pre-correction behavior). -/
def annualBalanceIncreaseNoPostCLOverflowCheckAccepts (limits : SanityLimits) (s : SanityCheckInput) : Bool :=
  if preCLBalance s > UINT256_MAX then false
  else
    let pre := if preCLBalance s == 0 then DEFAULT_CL_BALANCE
               else preCLBalance s
    let post := s.postCLValidatorsBalance + s.postCLPendingBalance + s.clWithdrawals
    if pre ≥ post then true
    else
      let balanceIncrease := post - pre
      let t := effectiveTimeElapsed s.timeElapsed
      if ANNUAL_BALANCE_INCREASE_DENOMINATOR * balanceIncrease > UINT256_MAX then false
      else
        let annualIncrease := ANNUAL_BALANCE_INCREASE_DENOMINATOR * balanceIncrease / pre / t
        annualIncrease ≤ limits.annualBalanceIncreaseBPLimit

/-- Mutant: activated balance without appeared-ETH proration overflow checks
(pre-correction behavior). -/
def activatedBalanceNoProrationOverflowCheckAccepts (limits : SanityLimits) (s : SanityCheckInput) : Bool :=
  let fundedPendingBalance := s.preCLPendingBalance + s.deposits
  let activatedBalance := if fundedPendingBalance > s.postCLPendingBalance
    then fundedPendingBalance - s.postCLPendingBalance else 0
  let t := effectiveTimeElapsed s.timeElapsed
  let appearedLimit := calculateAmountForPeriod
    (limits.appearedEthAmountPerDayLimit * 1000000000000000000) t
  activatedBalance ≤ appearedLimit + MAX_VALIDATOR_EFFECTIVE_BALANCE

/-! ### Checker conjunction -/

/-- Source entry-point domain for the report interval. Although Lean models the
value as `Nat`, Solidity receives it as `uint256`. -/
def timeElapsedFitsUint256 (s : SanityCheckInput) : Bool :=
  s.timeElapsed ≤ UINT256_MAX

def checkerAccepts (limits : SanityLimits) (s : SanityCheckInput) : Bool :=
  timeElapsedFitsUint256 s &&
  annualBalanceIncreaseAccepts limits s &&
  pendingBalanceCapAccepts limits s &&
  activatedBalanceAccepts limits s &&
  validatorsBalanceIncreaseAccepts limits s &&
  simulatedShareRateAccepts limits s

/-- Parent-shaped mutant: the checker conjunction without the source
`uint256` bound on `timeElapsed` (pre-correction behavior). -/
def checkerNoTimeElapsedBound (limits : SanityLimits) (s : SanityCheckInput) : Bool :=
  annualBalanceIncreaseAccepts limits s &&
  pendingBalanceCapAccepts limits s &&
  activatedBalanceAccepts limits s &&
  validatorsBalanceIncreaseAccepts limits s &&
  simulatedShareRateAccepts limits s

/-! ### Commit-implies-envelope: non-tautological extraction

Each individual guard is a named `Prop` so guard-drop mutants target one guard
without reducing to `P → P`. -/

def AnnualBalanceIncreaseHolds (limits : SanityLimits) (s : SanityCheckInput) : Prop :=
  annualBalanceIncreaseAccepts limits s = true

def PendingBalanceCapHolds (limits : SanityLimits) (s : SanityCheckInput) : Prop :=
  pendingBalanceCapAccepts limits s = true

def ActivatedBalanceHolds (limits : SanityLimits) (s : SanityCheckInput) : Prop :=
  activatedBalanceAccepts limits s = true

def ValidatorsBalanceIncreaseHolds (limits : SanityLimits) (s : SanityCheckInput) : Prop :=
  validatorsBalanceIncreaseAccepts limits s = true

def SimulatedShareRateHolds (limits : SanityLimits) (s : SanityCheckInput) : Prop :=
  simulatedShareRateAccepts limits s = true

def TimeElapsedFitsUint256 (s : SanityCheckInput) : Prop :=
  timeElapsedFitsUint256 s = true

private theorem and6 {a b c d e f : Bool}
    (h : (a && b && c && d && e && f) = true) :
    a = true ∧ b = true ∧ c = true ∧ d = true ∧ e = true ∧ f = true := by
  simp [Bool.and_eq_true] at h
  exact ⟨h.1.1.1.1.1, h.1.1.1.1.2, h.1.1.1.2, h.1.1.2, h.1.2, h.2⟩

theorem checker_implies_time_elapsed_bound (limits : SanityLimits) (s : SanityCheckInput)
    (h : checkerAccepts limits s = true) :
    TimeElapsedFitsUint256 s :=
  (and6 h).1

theorem checker_implies_annual (limits : SanityLimits) (s : SanityCheckInput)
    (h : checkerAccepts limits s = true) :
    AnnualBalanceIncreaseHolds limits s :=
  (and6 h).2.1

theorem checker_implies_pending (limits : SanityLimits) (s : SanityCheckInput)
    (h : checkerAccepts limits s = true) :
    PendingBalanceCapHolds limits s :=
  (and6 h).2.2.1

theorem checker_implies_activated (limits : SanityLimits) (s : SanityCheckInput)
    (h : checkerAccepts limits s = true) :
    ActivatedBalanceHolds limits s :=
  (and6 h).2.2.2.1

theorem checker_implies_validators (limits : SanityLimits) (s : SanityCheckInput)
    (h : checkerAccepts limits s = true) :
    ValidatorsBalanceIncreaseHolds limits s :=
  (and6 h).2.2.2.2.1

theorem checker_implies_simulated (limits : SanityLimits) (s : SanityCheckInput)
    (h : checkerAccepts limits s = true) :
    SimulatedShareRateHolds limits s :=
  (and6 h).2.2.2.2.2

/-! ### Guard-drop mutant: annual balance increase

The mutant checker drops `annualBalanceIncreaseAccepts`. If this guard is
load-bearing, there exists an input that the mutant accepts but the real
checker rejects. -/

def checkerNoAnnual (limits : SanityLimits) (s : SanityCheckInput) : Bool :=
  timeElapsedFitsUint256 s &&
  pendingBalanceCapAccepts limits s &&
  activatedBalanceAccepts limits s &&
  validatorsBalanceIncreaseAccepts limits s &&
  simulatedShareRateAccepts limits s

/-! ### Candidate theorem list for completeness review

1. `checker_implies_time_elapsed_bound`: checkerAccepts → timeElapsed ≤ UINT256_MAX
2. `checker_implies_annual`: checkerAccepts → annualBalanceIncreaseAccepts
3. `checker_implies_pending`: checkerAccepts → pendingBalanceCapAccepts
4. `checker_implies_activated`: checkerAccepts → activatedBalanceAccepts
5. `checker_implies_validators`: checkerAccepts → validatorsBalanceIncreaseAccepts
6. `checker_implies_simulated`: checkerAccepts → simulatedShareRateAccepts
7. `timeElapsedBoundIsLoadBearing` (Tests): ∃ input, parent-shaped mutant
   accepts ∧ checker rejects
8. `annualGuardIsLoadBearing` (Tests): ∃ input, mutant accepts ∧ checker rejects

Residual blockers before P-ORACLE-SANITY-1 registration:
- smoothenTokenRebase limiter model
- sliding-window CL balance decrease check
- vault/burn attestation guards (require on-chain state reads)
- per-module validators balance increase check (external state)
- second opinion oracle cross-contract call
- consensus hash / keccak opaqueness declaration
- `_getCLWithdrawals`, `_checkWithdrawalsVaultTransfer`, and
  `_finalizePostReportState` withdrawal-vault accounting/commit path
-/

end LidoSRv3.Audit.SolidityAccounting.SanityEnvelope
