import LidoSRv3.Audit.Verity.DepositRollback

namespace LidoSRv3.Audit.Verity.Tests.DepositRollback

open LidoSRv3.Audit.Verity.DepositRollback

#guard moduleConfigStatusShift == 224
#guard moduleConfigWCTypeShift == 232
#guard sourceDerivedExpectedFootprint.length == 3
#guard openComponents.length == 9

def wrongStatusShiftMutantRejected : Bool := moduleConfigStatusShift != 240
#guard wrongStatusShiftMutantRejected

def literalTargetMutantRejected : Bool :=
  let immutableNames := spec.immutables.map (fun immutable => immutable.name)
  immutableNames.contains "LIDO" && immutableNames.contains "DEPOSIT_CONTRACT" &&
    immutableNames.contains "LIDO_LOCATOR"
#guard literalTargetMutantRejected

end LidoSRv3.Audit.Verity.Tests.DepositRollback
