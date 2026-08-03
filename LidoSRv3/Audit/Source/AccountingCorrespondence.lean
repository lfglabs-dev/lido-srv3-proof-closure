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

The transaction plane below is an executable `Verity.Contract` at the pinned
Verity revision.  `Contract.run` supplies Verity's rollback semantics, and the
observation projects the committed accounting storage.  This is deliberately
not a claim that the pinned Solidity was translated or compiled: Yul, EVM,
runtime-bytecode, crypto, and end-to-end report execution remain open.
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

/-! ## Pinned Verity transaction execution

The three storage channels are an explicit abstraction boundary: slot-array 0
is the registered module order, slot-array 1 is the per-module balance array,
and scalar slot 2 is the router aggregate.  Other AccountingOracle and router
storage is represented by the two checked input observations above.
-/

def encodeState (state : AccountingState) : Verity.ContractState :=
  { Verity.defaultState with
    storage := fun slot => if slot = 2 then state.routerBalanceGwei else 0
    storageArray := fun slot =>
      if slot = 0 then state.moduleIds
      else if slot = 1 then state.moduleBalancesGwei
      else [] }

def decodeState (world : Verity.ContractState) : AccountingState :=
  ⟨world.storageArray 0, world.storageArray 1, world.storage 2⟩

def commitState (world : Verity.ContractState) (state : AccountingState) : Verity.ContractState :=
  { world with
    storage := fun slot => if slot = 2 then state.routerBalanceGwei else world.storage slot
    storageArray := fun slot =>
      if slot = 0 then state.moduleIds
      else if slot = 1 then state.moduleBalancesGwei
      else world.storageArray slot }

/-- Independent executable Verity presentation of the pinned guard/write
sequence.  In particular it does not call `sourceRun`; equality with that
source presentation is proved below. -/
def verityAccountingTx (input : TxInput) : Verity.Contract Unit := fun world =>
  let before := decodeState world
  if !input.oraclePrefixSucceeded then .revert "oracle-prefix" world
  else if input.report.moduleIds.length != before.moduleIds.length ||
      input.report.balancesGwei.length != before.moduleIds.length then
    .revert "arrays-length-mismatch" world
  else if input.report.moduleIds != before.moduleIds then .revert "unexpected-module-id" world
  else if !allAmountsValid input.report.balancesGwei then .revert "invalid-amount-gwei" world
  else if input.report.moduleIds.isEmpty then .success () world
  else if !input.callerAuthorized then .revert "unauthorized-router-write" world
  else match checkedTotal input.report.balancesGwei with
    | none => .revert "uint64-total-overflow" world
    | some total => .success () (commitState world
        ⟨before.moduleIds, input.report.balancesGwei, total⟩)

structure VerityTxObservation where
  outcome : TxResult
  finalState : AccountingState
  deriving DecidableEq, Repr

def observeVerityTx (before : AccountingState) (input : TxInput) : VerityTxObservation :=
  match (verityAccountingTx input).run (encodeState before) with
  | .success _ world => ⟨.committed (decodeState world), decodeState world⟩
  | .revert reason world =>
      let typedReason :=
        if reason = "oracle-prefix" then .oraclePrefix
        else if reason = "arrays-length-mismatch" then .arraysLengthMismatch
        else if reason = "unexpected-module-id" then .unexpectedModuleId
        else if reason = "invalid-amount-gwei" then .invalidAmountGwei
        else if reason = "unauthorized-router-write" then .unauthorized
        else .totalBalanceOverflow
      ⟨.reverted typedReason, decodeState world⟩

@[simp] theorem decode_encode (state : AccountingState) :
    decodeState (encodeState state) = state := by
  simp [decodeState, encodeState]

def verityResult (before : AccountingState) : TxResult → Verity.ContractResult Unit
  | .reverted .oraclePrefix => .revert "oracle-prefix" (encodeState before)
  | .reverted .arraysLengthMismatch => .revert "arrays-length-mismatch" (encodeState before)
  | .reverted .unexpectedModuleId => .revert "unexpected-module-id" (encodeState before)
  | .reverted .invalidAmountGwei => .revert "invalid-amount-gwei" (encodeState before)
  | .reverted .unauthorized => .revert "unauthorized-router-write" (encodeState before)
  | .reverted .totalBalanceOverflow => .revert "uint64-total-overflow" (encodeState before)
  | .committed after => .success () (encodeState after)

theorem verity_run_eq_source (before : AccountingState) (input : TxInput) :
    (verityAccountingTx input).run (encodeState before) =
      verityResult before (sourceRun before input) := by
  simp only [verityAccountingTx, Contract.run, decode_encode]
  unfold sourceRun
  repeat' first | split
  all_goals simp_all [verityResult, encodeState, commitState]

/-- SOURCE -> VERITY_TX: actual pinned `Contract.run` execution produces the
same result as the independently stated pinned-Solidity guard/write model. -/
theorem verity_tx_simulates_source (before : AccountingState) (input : TxInput) :
    (observeVerityTx before input).outcome = sourceRun before input := by
  rw [observeVerityTx, verity_run_eq_source]
  cases h : sourceRun before input with
  | reverted reason => cases reason <;> simp [verityResult, decode_encode]
  | committed after => simp [verityResult, decode_encode]

theorem verity_tx_final_state (before : AccountingState) (input : TxInput) :
    (observeVerityTx before input).finalState =
      match sourceRun before input with
      | .reverted _ => before
      | .committed after => after := by
  rw [observeVerityTx, verity_run_eq_source]
  cases h : sourceRun before input with
  | reverted reason => cases reason <;> simp [verityResult, decode_encode]
  | committed after => simp [verityResult, decode_encode]

/-- MODEL -> SOURCE -> VERITY_TX: every committed pinned Verity observation is
exactly an abstract accounting transaction result. -/
theorem verity_tx_refines_model (before after : AccountingState) (input : TxInput)
    (h : (observeVerityTx before input).outcome = .committed after) :
    abstractTransaction before input.report = some after := by
  apply source_refines_model before after input
  rw [← verity_tx_simulates_source before input]
  exact h

end LidoSRv3.Audit.SolidityAccounting
