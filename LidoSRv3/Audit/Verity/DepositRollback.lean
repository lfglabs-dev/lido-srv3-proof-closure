import Compiler.CompilationModel
import Verity.Core.Model.AllocationExtraction
import Verity.Core.Model.Denote
import Verity.Core.Model.DenoteExternalCalls

/-!
# P-DEPOSIT-1: source-shaped deposit prefix scaffold (OPEN)

Pinned source: `lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`.

This artifact deliberately does **not** claim an end-to-end deposit model.  It
uses Verity's official contract-separated storage identities for the router,
Lido, withdrawal queue, and accounting oracle, but has no faithful primitive
for composing the router, Lido, withdrawal queue, oracle, module-returned dynamic byte arrays,
and DepositContract into one reverting transaction.  The checked FunctionSpec
therefore ends at the first unavailable component: the allocation helper.

The prefix below checks exactly these source operations, in order:

* locator-derived DSM lookup and caller equality (StakingRouter 942--944,
  1173--1179);
* EnumerableSet membership used by `_requireModuleIdExists`;
* config extraction: module address at bits 0--159, status at bits 224--231,
  and withdrawal-credentials type at bits 232--239;
* router withdrawal-credentials slot 4 with the source `setType` conversion;
* immutable `LIDO.getDepositableEther()` target and propagating failure.

Everything after that boundary is listed in `openComponents`; no
caller-supplied allocation, module bytes, or deposit-data-root stands in for
the missing execution.
-/

namespace LidoSRv3.Audit.Verity.DepositRollback

open Compiler
open Compiler.CompilationModel
open Verity.Core.Model.AllocationExtraction

/-! Stable positive identities for the four source contracts whose storage
worlds participate in the deposit transaction. These are deliberately distinct;
contract id zero is Verity's legacy unqualified storage world. -/
def stakingRouterNamespace : Nat := 1
def lidoNamespace : Nat := 2
def withdrawalQueueNamespace : Nat := 3
def accountingOracleNamespace : Nat := 4

def routerStateSlot : Nat :=
  0x5648d366b9f342bdcc64be95cdcf5f05da808509be70eaa548a8795901d5d000

def moduleConfigStatusShift : Nat := 224
def moduleConfigWCTypeShift : Nat := 232
def addressModulus : Nat := 2 ^ 160
def byteModulus : Nat := 2 ^ 8
def uint248Modulus : Nat := 2 ^ 248

def depositSecurityModuleSelector : Nat := 0x472c1776
def getDepositableEtherSelector : Nat := 0xf2cfa87d

def canonicalRouterFields : List Field :=
  [ { name := "moduleStates", ty := .mappingTyped (.simple .uint256), slot := some routerStateSlot }
  , { name := "moduleIds", ty := .dynamicArray .uint256, slot := some (routerStateSlot + 1) }
  , { name := "moduleIdPositions", ty := .mappingTyped (.simple .uint256), slot := some (routerStateSlot + 2) }
  , { name := "withdrawalCredentials", ty := .uint256, slot := some (routerStateSlot + 4) }
  ]

def checkedPrefix : FunctionSpec :=
  { name := "depositCheckedPrefix"
    params :=
      [ { name := "stakingModuleId", ty := .uint256 }
      , { name := "depositCalldata", ty := .bytes }
      ]
    returnType := none
    reentrancyTrusted := true
    localObligations :=
      [ { name := "OPEN_allocation_and_suffix"
          obligation := "OPEN: `_getModuleDepositAllocation` and every later source operation are outside this checked prefix; see openComponents."
          proofStatus := .unchecked }
      ]
    body :=
      [ -- LIDO_LOCATOR.depositSecurityModule(); returndata is forwarded on failure.
        .mstore (.literal 0) (.shl (.literal 224) (.literal depositSecurityModuleSelector))
      , .letVar "locatorOk"
          (.staticcall (.literal Verity.Core.MAX_UINT256) (.immutable "LIDO_LOCATOR")
            (.literal 0) (.literal 4) (.literal 0) (.literal 32))
      , .ite (.eq (.localVar "locatorOk") (.literal 0)) [.revertReturndata] []
      , .require (.le (.literal 32) .returndataSize) "LocatorShortReturndata"
      , .letVar "depositSecurityModule" (.mload (.literal 0))
      , .require (.eq .caller (.localVar "depositSecurityModule")) "NotAuthorized"

      -- EnumerableSet._positions[bytes32(moduleId)] != 0.
      , .require
          (.lt (.literal 0) (.mapping "moduleIdPositions" (.param "stakingModuleId")))
          "StakingModuleUnregistered"
      , .letVar "moduleConfig" (.mappingWord "moduleStates" (.param "stakingModuleId") 0)
      , .letVar "moduleAddress" (.mod (.localVar "moduleConfig") (.literal addressModulus))
      , .letVar "moduleStatus"
          (.mod (.div (.localVar "moduleConfig") (.literal (2 ^ moduleConfigStatusShift)))
            (.literal byteModulus))
      , .require (.eq (.localVar "moduleStatus") (.literal 0)) "StakingModuleNotActive"
      , .letVar "withdrawalCredentialsType"
          (.mod (.div (.localVar "moduleConfig") (.literal (2 ^ moduleConfigWCTypeShift)))
            (.literal byteModulus))
      , .letVar "withdrawalCredentials"
          (.add (.mod (.storage "withdrawalCredentials") (.literal uint248Modulus))
            (.mul (.localVar "withdrawalCredentialsType") (.literal (2 ^ 248))))

      -- LIDO.getDepositableEther(); returndata is forwarded on failure.
      , .mstore (.literal 0) (.shl (.literal 224) (.literal getDepositableEtherSelector))
      , .letVar "lidoOk"
          (.staticcall (.literal Verity.Core.MAX_UINT256) (.immutable "LIDO")
            (.literal 0) (.literal 4) (.literal 0) (.literal 32))
      , .ite (.eq (.localVar "lidoOk") (.literal 0)) [.revertReturndata] []
      , .require (.le (.literal 32) .returndataSize) "LidoShortReturndata"
      , .letVar "depositableEther" (.mload (.literal 0))
      , .stop
      ] }

def spec : CompilationModel :=
  { name := "PDeposit1CheckedPrefix"
    contractId := stakingRouterNamespace
    fields := canonicalRouterFields
    immutables :=
      [ { name := "LIDO", ty := .address, init := .constructorArg 0 }
      , { name := "DEPOSIT_CONTRACT", ty := .address, init := .constructorArg 1 }
      , { name := "LIDO_LOCATOR", ty := .address, init := .constructorArg 2 }
      , { name := "MAX_EFFECTIVE_BALANCE_WC_TYPE_01", ty := .uint256, init := .constructorArg 3 }
      ]
    constructor := some
      { params :=
          [ { name := "lido", ty := .address }
          , { name := "depositContract", ty := .address }
          , { name := "lidoLocator", ty := .address }
          , { name := "maxEffectiveBalance", ty := .uint256 }
          ]
        body :=
          [ .setImmutable "LIDO" (.param "lido")
          , .setImmutable "DEPOSIT_CONTRACT" (.param "depositContract")
          , .setImmutable "LIDO_LOCATOR" (.param "lidoLocator")
          , .setImmutable "MAX_EFFECTIVE_BALANCE_WC_TYPE_01" (.param "maxEffectiveBalance")
          ] }
    functions := [checkedPrefix] }

/-! The remaining source participants are explicit Verity contract models even
though their bodies remain outside the checked prefix.  Their distinct positive
`contractId`s select the official contract-separated storage worlds introduced
by `verity@54f1e002`. -/
def lidoSpec : CompilationModel :=
  { name := "Lido"
    contractId := lidoNamespace
    fields := []
    constructor := none
    functions := [] }

def withdrawalQueueSpec : CompilationModel :=
  { name := "WithdrawalQueue"
    contractId := withdrawalQueueNamespace
    fields := []
    constructor := none
    functions := [] }

def accountingOracleSpec : CompilationModel :=
  { name := "AccountingOracle"
    contractId := accountingOracleNamespace
    fields := []
    constructor := none
    functions := [] }

def officialSeparatedNamespaces : List Nat :=
  [spec.contractId, lidoSpec.contractId, withdrawalQueueSpec.contractId,
    accountingOracleSpec.contractId]

def checkedPrefixSelector : Nat := 0x5d303519

theorem checked_prefix_is_actual_function_spec : spec.functions = [checkedPrefix] := rfl

private def exceptUnitDecEq : DecidableEq (Except String Unit) := fun x y =>
  match x, y with
  | .ok _, .ok _ => isTrue rfl
  | .error a, .error b =>
    if h : a = b then isTrue (h ▸ rfl)
    else isFalse (by intro heq; cases heq; exact h rfl)
  | .ok _, .error _ => isFalse (by intro h; cases h)
  | .error _, .ok _ => isFalse (by intro h; cases h)

local instance : DecidableEq (Except String Unit) := exceptUnitDecEq

/- Check the declared obligations before assembling the compiled contract. -/
set_option maxRecDepth 16384 in
set_option maxHeartbeats 800000 in
private theorem compiler_function_validates : validateFunctionSpec checkedPrefix = .ok () := by
  have documented : checkedPrefix.localObligations.isEmpty = false := rfl
  simp only [validateFunctionSpec, documented, Bool.and_false, Bool.false_and]
  decide +kernel

/- Full transparency evaluates the compiler's private validation definitions.
The result is a reflexivity proof checked by Lean's kernel, not a native witness.
Keeping the validation expression intact avoids duplicating its nested matches. -/
set_option maxRecDepth 16384 in
set_option maxHeartbeats 800000 in
private theorem compiler_inputs_validate : validateCompileInputs spec [checkedPrefixSelector] = .ok () := by
  run_tac Lean.Elab.Tactic.liftMetaTactic fun goal => Lean.Meta.withTransparency .all do
    goal.refl
    pure []

set_option maxRecDepth 16384 in
set_option maxHeartbeats 800000 in
private theorem compiler_body_compiles :
    (compileStmtListWithFork canonicalRouterFields [] [] .calldata [] false
      ["stakingModuleId", "depositCalldata"] [] .cancun checkedPrefix.body []).isOk = true := by
  simp [checkedPrefix, canonicalRouterFields, compileStmtListWithFork, compileStmtWithFork,
    compileExprWithInternals, compileRequireFailCondWithInternals,
    Bind.bind, Except.bind, Pure.pure, Except.pure, Except.isOk, Except.toBool]
  all_goals decide +kernel

set_option maxRecDepth 16384 in
set_option maxHeartbeats 800000 in
private theorem compiler_constructor_compiles :
    (compileConstructor canonicalRouterFields [] [] [] spec.constructor).isOk = true := by
  simp [spec, compileConstructor, compileStmtListWithFork,
    compileStmtWithFork, compileExprWithInternals,
    Bind.bind, Except.bind, Pure.pure, Except.pure, Except.isOk, Except.toBool]

set_option maxRecDepth 16384 in
set_option maxHeartbeats 800000 in
private theorem compiler_no_templates : (templateIntrinsicItems spec).isEmpty = true := by
  decide +kernel

set_option maxRecDepth 16384 in
set_option maxHeartbeats 800000 in
private theorem compiler_core_compiles :
    (compileValidatedCore spec [checkedPrefixSelector]).isOk = true := by
  have hi : checkedPrefix.isInternal = false := rfl
  have hn : checkedPrefix.name = "depositCheckedPrefix" := rfl
  have hs : isInteropEntrypointName "depositCheckedPrefix" = false := by decide +kernel
  have hf : applySlotAliasRanges canonicalRouterFields [] = canonicalRouterFields := rfl
  have hp : checkedPrefix.params =
      [{ name := "stakingModuleId", ty := .uint256 },
       { name := "depositCalldata", ty := .bytes }] := rfl
  have hl : checkedPrefix.nonReentrantLock = none := rfl
  have hr : CompilationModel.functionReturns checkedPrefix = .ok [] := rfl
  have ht := List.nil_of_isEmpty compiler_no_templates
  have hbody := compiler_body_compiles
  have hctor := compiler_constructor_compiles
  cases hb : compileStmtListWithFork canonicalRouterFields [] [] .calldata [] false
      ["stakingModuleId", "depositCalldata"] [] .cancun checkedPrefix.body [] with
  | error err => simp [hb, Except.isOk, Except.toBool] at hbody
  | ok body =>
    cases hc : compileConstructor canonicalRouterFields [] [] [] spec.constructor with
    | error err => simp [hc, Except.isOk, Except.toBool] at hctor
    | ok ctor =>
      simp only [spec] at hc
      unfold compileValidatedCore
      rw [ht]
      simp [spec, compileGuardedFunctionSpec, compileFunctionSpec,
        compiler_function_validates, hi, hn, hs, hf, hp, hl, hr, hb, hc,
        attachNonReentrantGuard, pickUniqueFunctionByName,
        List.mapM_cons, List.map_cons, List.map_nil,
        Bind.bind, Except.bind, Pure.pure, Except.pure, Except.isOk, Except.toBool]

/-- Compiler acceptance is composed from validation, body and constructor checks. -/
theorem checked_prefix_compiles :
    (CompilationModel.compile spec [checkedPrefixSelector]).isOk = true := by
  unfold CompilationModel.compile
  rw [compiler_inputs_validate]
  exact compiler_core_compiles

/-! The expected footprint is independently written from the pinned source
prefix.  It is not obtained by aliasing `checkedPrefix` to a second name. -/
def sourceDerivedExpectedFootprint :
    List (Compiler.Proofs.Storage.ContractId × Nat × AllocKind) :=
  [ (stakingRouterNamespace, 0x5648d366b9f342bdcc64be95cdcf5f05da808509be70eaa548a8795901d5d002, .read)
  , (stakingRouterNamespace, 0x5648d366b9f342bdcc64be95cdcf5f05da808509be70eaa548a8795901d5d000, .read)
  , (stakingRouterNamespace, 0x5648d366b9f342bdcc64be95cdcf5f05da808509be70eaa548a8795901d5d004, .read)
  ]

def extractedFootprint :
    List (Compiler.Proofs.Storage.ContractId × Nat × AllocKind) :=
  (extractAllocation spec checkedPrefix).slots.map fun entry =>
    (entry.contract, entry.slot, entry.kind)

theorem allocation_extraction_matches_source_derived_prefix :
    extractedFootprint = sourceDerivedExpectedFootprint := by
  decide +kernel

/-! Actual FunctionSpec execution rejects malformed ABI input before any body
statement. `DenoteResult` exposes encoded final storage but this artifact does
not prove snapshot equality, so rollback remains OPEN below. -/
def zeroOracle : Denote.DenoteOracle :=
  { mappingSlot := fun _ _ => 0, keccakMemorySlice := fun _ _ _ => 0 }

def malformedTx : Denote.DenoteTransaction :=
  { sender := 7, thisAddress := 9, functionSelector := checkedPrefixSelector, args := [] }

theorem malformed_actual_function_spec_rejects :
    (Denote.denoteFunction zeroOracle spec checkedPrefix malformedTx
      Verity.defaultState).success = false := by
  decide +kernel

def openComponents : List String :=
  [ "OPEN allocation: module capacity/summary calls, type-2 total stake, MinFirst.allocate, module-index lookup, zero-module branch, and all arithmetic/array bounds"
  , "OPEN module ABI: IStakingModule(moduleAddress).obtainDepositData and its two returned memory byte arrays/revert propagation"
  , "OPEN router suffix: max-deposit arithmetic, returned-array validation, exact timestamp/block-number low-128-bit write, StakingRouterETHDeposited log, and zero-key return"
  , "OPEN Lido authorization/gate: canDeposit, locator->stakingRouter caller equality, nonzero amount, seed counter/log, and nested payable receiveDepositableEther"
  , "OPEN Lido spend: buffered allocation, withdrawalQueue bunker/unfinalized calls, reserves, packed buffered/post-report and next-report/nonce writes, accountingOracle frame call, and all logs"
  , "OPEN beacon memory/calldata: module-returned memory slicing, free-memory allocation, exact per-validator 420-byte ABI payload, and immutable DEPOSIT_CONTRACT call"
  , "OPEN deposit-data-root: per-validator SHA-256 composition from that validator's pubkey/signature, withdrawal credentials, and 32 ETH amount"
  , "OPEN rollback/transaction proof: malformed-ABI snapshot equality, propagating module/Lido/queue/oracle/beacon failures, full nested-loop execution, conservation, and whole-world rollback"
  , "OPEN multi-contract execution: storage namespaces are separated, but the checked prefix does not execute Lido, withdrawal queue, or accounting oracle bodies"
  ]

end LidoSRv3.Audit.Verity.DepositRollback
