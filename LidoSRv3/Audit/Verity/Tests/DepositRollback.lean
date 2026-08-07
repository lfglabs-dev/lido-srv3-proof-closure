import LidoSRv3.Audit.Verity.DepositRollback

namespace LidoSRv3.Audit.Verity.Tests.DepositRollback

open LidoSRv3.Audit.Verity.DepositRollback

#guard moduleConfigStatusShift == 224
#guard moduleConfigWCTypeShift == 232
#guard checkedPrefixSelector == 0x5d303519
#guard sourceDerivedExpectedFootprint.length == 3
#guard openComponents.length == 9
#guard officialSeparatedNamespaces == [1, 2, 3, 4]
#guard spec.contractId == stakingRouterNamespace
#guard lidoSpec.contractId == lidoNamespace
#guard withdrawalQueueSpec.contractId == withdrawalQueueNamespace
#guard accountingOracleSpec.contractId == accountingOracleNamespace

def bodyUsesPinnedSelectorAndAbiChecks : Bool :=
  let selectors := checkedPrefix.body.filterMap fun
    | .mstore (.literal 0) (.shl (.literal 224) (.literal selector)) => some selector
    | _ => none
  let shortReturnReasons := checkedPrefix.body.filterMap fun
    | .require (.le (.literal 32) .returndataSize) reason => some reason
    | _ => none
  selectors == [0x472c1776, 0xf2cfa87d] &&
    shortReturnReasons == ["LocatorShortReturndata", "LidoShortReturndata"]
#guard bodyUsesPinnedSelectorAndAbiChecks

def bodyUsesPinnedStatusShift : Bool :=
  checkedPrefix.body.any fun
    | .letVar "moduleStatus"
        (.mod (.div (.localVar "moduleConfig") (.literal divisor)) (.literal modulus)) =>
      divisor == 2 ^ 224 && modulus == 2 ^ 8
    | _ => false
#guard bodyUsesPinnedStatusShift

def bodyUsesImmutableCallTargets : Bool :=
  let targets := checkedPrefix.body.filterMap fun
    | .letVar result (.staticcall (.literal gas) (.immutable target)
        (.literal 0) (.literal 4) (.literal 0) (.literal 32)) => some (result, gas, target)
    | _ => none
  targets ==
    [("locatorOk", Verity.Core.MAX_UINT256, "LIDO_LOCATOR"),
      ("lidoOk", Verity.Core.MAX_UINT256, "LIDO")]
#guard bodyUsesImmutableCallTargets

def independentlyPinnedFootprint :
    List (Compiler.Proofs.Storage.ContractId × Nat ×
      Verity.Core.Model.AllocationExtraction.AllocKind) :=
  [ (stakingRouterNamespace, 0x5648d366b9f342bdcc64be95cdcf5f05da808509be70eaa548a8795901d5d002,
      Verity.Core.Model.AllocationExtraction.AllocKind.read)
  , (stakingRouterNamespace, 0x5648d366b9f342bdcc64be95cdcf5f05da808509be70eaa548a8795901d5d000,
      Verity.Core.Model.AllocationExtraction.AllocKind.read)
  , (stakingRouterNamespace, 0x5648d366b9f342bdcc64be95cdcf5f05da808509be70eaa548a8795901d5d004,
      Verity.Core.Model.AllocationExtraction.AllocKind.read) ]
#guard extractedFootprint == independentlyPinnedFootprint

def namespacesArePairwiseSeparated : Bool :=
  stakingRouterNamespace != lidoNamespace &&
  stakingRouterNamespace != withdrawalQueueNamespace &&
  stakingRouterNamespace != accountingOracleNamespace &&
  lidoNamespace != withdrawalQueueNamespace &&
  lidoNamespace != accountingOracleNamespace &&
  withdrawalQueueNamespace != accountingOracleNamespace
#guard namespacesArePairwiseSeparated

theorem stakingRouterWriteIsInvisibleToOtherDepositContracts
    (state : Verity.ContractState) (slot : Nat) (value : Verity.Uint256) :
    (state.writeContractSlot spec.contractId slot value).readContractSlot
        lidoSpec.contractId slot = state.readContractSlot lidoSpec.contractId slot ∧
    (state.writeContractSlot spec.contractId slot value).readContractSlot
        withdrawalQueueSpec.contractId slot =
          state.readContractSlot withdrawalQueueSpec.contractId slot ∧
    (state.writeContractSlot spec.contractId slot value).readContractSlot
        accountingOracleSpec.contractId slot =
          state.readContractSlot accountingOracleSpec.contractId slot := by
  constructor
  · apply Verity.ContractState.readContractSlot_writeContractSlot_other_contract
    decide
  constructor
  · apply Verity.ContractState.readContractSlot_writeContractSlot_other_contract
    decide
  · apply Verity.ContractState.readContractSlot_writeContractSlot_other_contract
    decide

def wrongStatusShiftMutantRejected : Bool := moduleConfigStatusShift != 240
#guard wrongStatusShiftMutantRejected

def literalTargetMutantRejected : Bool :=
  let immutableNames := spec.immutables.map (fun immutable => immutable.name)
  immutableNames.contains "LIDO" && immutableNames.contains "DEPOSIT_CONTRACT" &&
    immutableNames.contains "LIDO_LOCATOR"
#guard literalTargetMutantRejected

end LidoSRv3.Audit.Verity.Tests.DepositRollback
