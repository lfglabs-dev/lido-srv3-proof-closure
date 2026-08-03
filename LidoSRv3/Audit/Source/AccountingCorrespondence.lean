import LidoSRv3.Audit.Arithmetic

/-!
Pinned source/Verity transaction correspondence for P-ACCOUNT-1 at
`lidofinance/core@af095e48bbc1c3841c2c9936219c8461af01056b`.

The covered transaction enters through `AccountingOracle.submitReportData`
(`contracts/0.8.9/oracle/AccountingOracle.sol`, lines 360--366), then
`_handleConsensusReportData` (lines 477--558), specifically the call sites at
lines 504 and 517--521. Its transitive accounting helpers are
`_checkStakingRouterModuleBalances` (lines 711--740),
`_normalizeStakingRouterValidatorBalancesToWei` (lines 742--752), and
`_processStakingRouterValidatorBalancesByModule` (lines 609--619);
`StakingRouter.validateReportValidatorBalancesByStakingModule` (lines 292--298)
and `reportValidatorBalancesByStakingModule` (lines 283--290);
`SRLib._validateReportValidatorBalancesByStakingModule` (lines 853--870) and
`_reportValidatorBalancesByStakingModule` (lines 872--892); and
`SRUtils.MAX_VALUE_GWEI` (line 23) and `_ensureAmountGwei` (lines 75--83). The written fields are
`SRTypes.ModuleStateAccounting.validatorsBalanceGwei` (lines 157--164) and
`RouterStateAccounting.validatorsBalanceGwei` (lines 166--171).

The model deliberately begins after the other `submitReportData` consensus,
time, Lido, withdrawal-queue, and sanity-check calls have succeeded.  Those are
explicit transaction preconditions, not silently proved here.  Authorization
for the router write is also an input observation because it is storage owned
by `AccessControlEnumerable`.

No handwritten Yul, precompile, hash, runtime bytecode, or cryptographic
operation is crossed by this guarantee, so those planes remain open or not
applicable.  `verityExecute` is an executable transaction semantics over the
pinned Verity `Uint256` and `safeAdd`; `simulateVerityTx` is the refinement into
the independently stated abstract accounting transaction.
-/

namespace LidoSRv3.Audit.SolidityAccounting

open Verity Verity.Stdlib.Math

abbrev Word := Verity.Core.Uint256

/-- Exact `SRUtils.MAX_VALUE_GWEI`: one billion ether expressed in gwei. -/
def maxAmountGwei : Word := Verity.Core.Uint256.ofNat (1_000_000_000 * 1_000_000_000)

/-- Largest value storable in the source `uint64` accounting accumulator. -/
def maxUint64 : Word := Verity.Core.Uint256.ofNat (2^64 - 1)

structure AccountingState where
  moduleIds : List Word
  moduleBalancesGwei : List Word
  routerBalanceGwei : Word
  deriving DecidableEq, Repr

structure Report where
  moduleIds : List Word
  balancesGwei : List Word
  deriving DecidableEq, Repr

structure TxInput where
  /-- Observation of the router's `REPORT_EXITED_VALIDATORS_ROLE` modifier. -/
  callerAuthorized : Bool
  /-- All earlier `AccountingOracle.submitReportData` checks/calls succeeded. -/
  oraclePrefixSucceeded : Bool
  report : Report
  deriving DecidableEq, Repr

inductive RevertReason
  | oraclePrefix | unauthorized | arraysLengthMismatch | unexpectedModuleId
  | invalidAmountGwei | totalBalanceOverflow
  deriving DecidableEq, Repr

inductive TxResult
  | reverted (reason : RevertReason)
  | committed (state : AccountingState)
  deriving DecidableEq, Repr

/-- Solidity 0.8 checked `uint64` addition, expressed using Verity's pinned
checked-Uint256 addition plus the exact destination-type bound. -/
def checkedAddGwei (a b : Word) : Option Word := do
  let total ← safeAdd a b
  if total ≤ maxUint64 then some total else none

/-- Source-shaped loop at `SRLib.sol` lines 881--889. -/
def checkedTotal : List Word → Option Word
  | [] => some 0
  | x :: xs => do
      let tail ← checkedTotal xs
      checkedAddGwei x tail

def allAmountsValid (xs : List Word) : Bool :=
  xs.all (fun x => x ≤ maxAmountGwei)

/-- Minimal abstract accounting specification: accept exactly the report and
store its checked aggregate. -/
def abstractTransaction (before : AccountingState) (report : Report) : Option AccountingState := do
  if report.moduleIds.length = before.moduleIds.length ∧
      report.balancesGwei.length = before.moduleIds.length ∧
      report.moduleIds = before.moduleIds ∧ allAmountsValid report.balancesGwei then
    if report.moduleIds.isEmpty then some before
    else
      let total ← checkedTotal report.balancesGwei
      some { before with moduleBalancesGwei := report.balancesGwei, routerBalanceGwei := total }
  else none

/-- Source-shaped first-failing-guard presentation of the pinned Solidity. -/
def sourceRun (before : AccountingState) (input : TxInput) : TxResult :=
  if !input.oraclePrefixSucceeded then .reverted .oraclePrefix
  else if input.report.moduleIds.length != before.moduleIds.length ||
      input.report.balancesGwei.length != before.moduleIds.length then
    .reverted .arraysLengthMismatch
  else if input.report.moduleIds != before.moduleIds then .reverted .unexpectedModuleId
  else if !allAmountsValid input.report.balancesGwei then .reverted .invalidAmountGwei
  else if input.report.moduleIds.isEmpty then .committed before
  else if !input.callerAuthorized then .reverted .unauthorized
  else match checkedTotal input.report.balancesGwei with
    | none => .reverted .totalBalanceOverflow
    | some total => .committed
        { before with moduleBalancesGwei := input.report.balancesGwei, routerBalanceGwei := total }

/-- Verity transaction observables at the boundary used by P-ACCOUNT-1. -/
structure VerityTxObservation where
  success : Bool
  finalState : AccountingState
  revertReason : Option RevertReason
  deriving DecidableEq, Repr

/-- Executable pinned-Verity transaction semantics. Reverts restore the input
state; successful execution exposes the committed accounting storage. -/
def verityExecute (before : AccountingState) (input : TxInput) : VerityTxObservation :=
  match sourceRun before input with
  | .reverted reason => ⟨false, before, some reason⟩
  | .committed after => ⟨true, after, none⟩

def refinesAbstract (before : AccountingState) (input : TxInput)
    (obs : VerityTxObservation) : Prop :=
  if input.oraclePrefixSucceeded &&
      (input.report.moduleIds.isEmpty || input.callerAuthorized) then
    match abstractTransaction before input.report with
    | some after => obs = ⟨true, after, none⟩
    | none => obs.success = false ∧ obs.finalState = before
  else obs.success = false ∧ obs.finalState = before

theorem source_committed_matches_abstract
    (before after : AccountingState) (input : TxInput)
    (h : sourceRun before input = .committed after) :
    abstractTransaction before input.report = some after := by
  grind [sourceRun, abstractTransaction]

/-- MODEL → SOURCE: the exact checked source run implements the abstract
accounting transaction on every committed branch. -/
theorem source_refines_model
    (before after : AccountingState) (input : TxInput)
    (h : sourceRun before input = .committed after) :
    abstractTransaction before input.report = some after :=
  source_committed_matches_abstract before after input h

/-- SOURCE → VERITY_TX: simulation from executable pinned-Verity observables
into the abstract transaction, including rollback on every rejected branch. -/
theorem simulateVerityTx (before : AccountingState) (input : TxInput) :
    refinesAbstract before input (verityExecute before input) := by
  grind [refinesAbstract, verityExecute, sourceRun, abstractTransaction]

end LidoSRv3.Audit.SolidityAccounting
