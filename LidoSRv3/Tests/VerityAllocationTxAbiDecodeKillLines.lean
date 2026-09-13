import LidoSRv3.Audit.Verity.AllocationTx

/-!
Kill-lines pinning `Verity.AllocationTx` ABI decoders `decodeUint256At`,
`decodeSummary`, `decodeTotalStake`, and the `sourceTotalStakeSite`
staticcall shape. These pin exactly the returndata semantics that
consume `getStakingModuleSummary()` and `getTotalModuleStake()` at
Lido core pin `17005714f151e5502c559932319a3f2f74ac2436`.
-/

namespace LidoSRv3.Tests.VerityAllocationTxAbiDecodeKillLines

open LidoSRv3.Audit.Verity.AllocationTx

/-! ## `decodeUint256At` big-endian ABI decoding -/

theorem decodeUint256At_empty :
    decodeUint256At [] 0 = Verity.Core.Uint256.ofNat 0 := by
  decide

theorem decodeUint256At_zeros_32 :
    decodeUint256At (List.replicate 32 0) 0 = Verity.Core.Uint256.ofNat 0 := by
  decide

theorem decodeUint256At_one_at_end :
    decodeUint256At (List.replicate 31 0 ++ [1]) 0 =
      Verity.Core.Uint256.ofNat 1 := by
  decide

theorem decodeUint256At_offset_zero :
    decodeUint256At (List.replicate 32 0 ++ List.replicate 31 0 ++ [42]) 32 =
      Verity.Core.Uint256.ofNat 42 := by
  decide

/-! ## `decodeSummary` — needs exactly 96 bytes -/

theorem decodeSummary_too_short :
    decodeSummary (List.replicate 95 0) = none := by
  decide

theorem decodeSummary_zero_triple :
    decodeSummary (List.replicate 96 0) =
      some { exitedCount := Verity.Core.Uint256.ofNat 0
             depositedCount := Verity.Core.Uint256.ofNat 0
             depositableCount := Verity.Core.Uint256.ofNat 0 } := by
  decide

theorem decodeSummary_trailing_ok :
    (decodeSummary (List.replicate 100 0)).isSome = true := by
  decide

/-! ## `decodeTotalStake` — needs exactly 32 bytes -/

theorem decodeTotalStake_too_short :
    decodeTotalStake (List.replicate 31 0) = none := by
  decide

theorem decodeTotalStake_zero :
    decodeTotalStake (List.replicate 32 0) =
      some (Verity.Core.Uint256.ofNat 0) := by
  decide

theorem decodeTotalStake_trailing_ok :
    (decodeTotalStake (List.replicate 40 0)).isSome = true := by
  decide

/-! ## `sourceTotalStakeSite` staticcall shape -/

theorem sourceTotalStakeSite_zero_address_siteId :
    (sourceTotalStakeSite 0).siteId = 1 := rfl

theorem sourceTotalStakeSite_kind :
    (sourceTotalStakeSite 0).kind =
      Compiler.CompilationModel.DenoteExternalCalls.CallKind.staticcall := rfl

theorem sourceTotalStakeSite_value :
    (sourceTotalStakeSite 0).value = 0 := rfl

theorem sourceTotalStakeSite_calldata :
    (sourceTotalStakeSite 0).calldata = totalStakeCalldata := rfl

end LidoSRv3.Tests.VerityAllocationTxAbiDecodeKillLines
