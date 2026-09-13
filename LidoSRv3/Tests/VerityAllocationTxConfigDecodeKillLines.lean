import LidoSRv3.Audit.Verity.AllocationTx

/-!
Kill-lines pinning `Verity.AllocationTx` packed-config decoders, slot
constants, and the `totalStake` static-call ABI shape. These match the
pinned Solidity `SRLib.sol:493-559` layout at Lido core pin
`17005714f151e5502c559932319a3f2f74ac2436`.
-/

namespace LidoSRv3.Tests.VerityAllocationTxConfigDecodeKillLines

open LidoSRv3.Audit.Verity.AllocationTx

/-! ## Storage slot constants (SRLib.sol:498-522 + phase-3 arrays) -/

theorem modulesCountSlot_val : modulesCountSlot = 29 := rfl
theorem moduleIdSlot_val : moduleIdSlot = 30 := rfl
theorem moduleConfigSlot_val : moduleConfigSlot = 31 := rfl
theorem accountingExitedSlot_val : accountingExitedSlot = 35 := rfl
theorem summaryExitedSlot_val : summaryExitedSlot = 36 := rfl
theorem summaryDepositedSlot_val : summaryDepositedSlot = 37 := rfl
theorem summaryDepositableSlot_val : summaryDepositableSlot = 38 := rfl
theorem summaryStakeSlot_val : summaryStakeSlot = 39 := rfl
theorem allocationSlot_val : allocationSlot = 40 := rfl
theorem capacitySlot_val : capacitySlot = 41 := rfl
theorem boundAddressSlot_val : boundAddressSlot = 42 := rfl
theorem totalSlot_val : totalSlot = 43 := rfl

/-! ## `getTotalModuleStake()` static call shape -/

theorem totalStakeSelector_val : totalStakeSelector = 0x0c852f5c := rfl
theorem totalStakeCalldata_val :
    totalStakeCalldata = [0x0c, 0x85, 0x2f, 0x5c] := rfl
theorem totalStakeCalldata_length : totalStakeCalldata.length = 4 := rfl
theorem totalStakeReturnBytes_val : totalStakeReturnBytes = 32 := rfl

/-! ## Packed-config field decoders — round-trip identities

  Solidity `ModuleStateConfig` layout: `[0..160)` moduleAddress,
  `[192..208)` shareLimit, `[224..232)` status, `[232..240)` wcType.
-/

theorem configModuleAddress_zero :
    configModuleAddress (Verity.Core.Uint256.ofNat 0) =
      Verity.Core.Uint256.ofNat 0 := by
  decide

theorem configStatus_zero :
    configStatus (Verity.Core.Uint256.ofNat 0) = 0 := by
  decide

theorem configWcType_zero :
    configWcType (Verity.Core.Uint256.ofNat 0) = 0 := by
  decide

theorem configShareLimit_zero :
    configShareLimit (Verity.Core.Uint256.ofNat 0) =
      Verity.Core.Uint256.ofNat 0 := by
  decide

/-- Status byte lives at bits `[224, 232)`: reading back the encoded byte
gives that byte modulo 256. -/
theorem configStatus_encoded_active :
    configStatus (Verity.Core.Uint256.ofNat (0 * 2 ^ 224)) = 0 := by
  decide

theorem configStatus_encoded_stopped :
    configStatus (Verity.Core.Uint256.ofNat (1 * 2 ^ 224)) = 1 := by
  decide

/-- wcType byte lives at bits `[232, 240)`. -/
theorem configWcType_encoded_type1 :
    configWcType (Verity.Core.Uint256.ofNat (1 * 2 ^ 232)) = 1 := by
  decide

theorem configWcType_encoded_type2 :
    configWcType (Verity.Core.Uint256.ofNat (2 * 2 ^ 232)) = 2 := by
  decide

end LidoSRv3.Tests.VerityAllocationTxConfigDecodeKillLines
