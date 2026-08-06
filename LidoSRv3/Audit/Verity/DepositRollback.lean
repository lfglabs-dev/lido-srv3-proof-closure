import Compiler.CompilationModel
import Verity.Core.Model.AllocationExtraction
import Verity.Core.Model.Denote
import Verity.Core.Model.DenoteExternalCalls

/-!
# P-DEPOSIT-1: source-faithful checked prefix and explicit open boundary

Pinned source: `lidofinance/core@af095e48bbc1c3841c2c9936219c8461af01056b`.

This artifact deliberately does **not** claim an end-to-end deposit model.  The
current Verity `CompilationModel` is single-contract (`AllocationExtraction`
assigns contract id zero), and it has no faithful primitive for composing the
router, Lido, withdrawal queue, oracle, module-returned dynamic byte arrays,
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
      , .letVar "depositableEther" (.mload (.literal 0))
      , .stop
      ] }

def spec : CompilationModel :=
  { name := "PDeposit1CheckedPrefix"
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

def checkedPrefixSelector : Nat := 0x8dbdbe6d

theorem checked_prefix_is_actual_function_spec : spec.functions = [checkedPrefix] := rfl

theorem checked_prefix_compiles :
    (CompilationModel.compile spec [checkedPrefixSelector]).isOk = true := by
  native_decide

/-! The expected footprint is independently written from the pinned source
prefix.  It is not obtained by aliasing `checkedPrefix` to a second name. -/
def sourceDerivedExpectedFootprint : List (ContractId × Nat × AllocKind) :=
  [ (0, routerStateSlot + 2, .read)
  , (0, routerStateSlot, .read)
  , (0, routerStateSlot + 4, .read)
  ]

def extractedFootprint : List (ContractId × Nat × AllocKind) :=
  (extractAllocation spec checkedPrefix).slots.map fun entry =>
    (entry.contract, entry.slot, entry.kind)

theorem allocation_extraction_matches_source_derived_prefix :
    extractedFootprint = sourceDerivedExpectedFootprint := by
  native_decide

/-! Actual FunctionSpec execution: malformed ABI input reverts before any body
statement and the denotation returns the transaction-context snapshot.  This
is intentionally only a prefix rollback theorem, not A.1 for the full path. -/
def zeroOracle : Denote.DenoteOracle :=
  { mappingSlot := fun _ _ => 0, keccakMemorySlice := fun _ _ _ => 0 }

def malformedTx : Denote.DenoteTransaction :=
  { sender := 7, thisAddress := 9, functionSelector := checkedPrefixSelector, args := [] }

theorem malformed_actual_function_spec_reverts :
    (Denote.denoteFunction zeroOracle spec checkedPrefix malformedTx Verity.defaultState).reverted = true := by
  native_decide

def openComponents : List String :=
  [ "OPEN allocation: module capacity/summary calls, type-2 total stake, MinFirst.allocate, module-index lookup, zero-module branch, and all arithmetic/array bounds"
  , "OPEN module ABI: IStakingModule(moduleAddress).obtainDepositData and its two returned memory byte arrays/revert propagation"
  , "OPEN router suffix: max-deposit arithmetic, returned-array validation, exact timestamp/block-number low-128-bit write, StakingRouterETHDeposited log, and zero-key return"
  , "OPEN Lido authorization/gate: canDeposit, locator->stakingRouter caller equality, nonzero amount, seed counter/log, and nested payable receiveDepositableEther"
  , "OPEN Lido spend: buffered allocation, withdrawalQueue bunker/unfinalized calls, reserves, packed buffered/post-report and next-report/nonce writes, accountingOracle frame call, and all logs"
  , "OPEN beacon memory/calldata: module-returned memory slicing, free-memory allocation, exact per-validator 420-byte ABI payload, and immutable DEPOSIT_CONTRACT call"
  , "OPEN deposit-data-root: per-validator SHA-256 composition from that validator's pubkey/signature, withdrawal credentials, and 32 ETH amount"
  , "OPEN transaction proof: propagating module/Lido/queue/oracle/beacon failures, full nested-loop execution, conservation, and whole-world rollback"
  , "OPEN multi-contract allocation extraction: Verity AllocationExtraction currently assigns contract id zero"
  ]

end LidoSRv3.Audit.Verity.DepositRollback
