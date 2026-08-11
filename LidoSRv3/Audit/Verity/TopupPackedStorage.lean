import LidoSRv3.Audit.Guarantees.PTopup2
import Verity.Core
import Verity.Macro
import Contracts.Common

/-!
# P-TOPUP-2 packed gateway transaction

This is the executable Verity boundary for the headroom and aggregate-budget
slice of pinned `TopUpGateway.sol` (`af095e48...`, lines 160--237 and 396--415).
The ERC-7201 namespace and every Solidity packed field are represented below.
Verity #2249 lowers the narrow `UIntN` declarations sharing a slot to masked
read/modify/write operations.  The public proofs inspect the generated layout
and materially execute `Contract.run`.

The transaction deliberately starts after the source guards and validator
proof call. Batch length/alignment, order, TOP_UP_ROLE, resumed state, root age,
withdrawal credentials, activation, EIP-4788 anchor lookup, SSZ/SHA-256 proof
binding, and the linked StakingRouter call are explicit correspondence
assumptions; they are not fabricated here.  Thus this closes only headroom and
budget at SOURCE/VERITY_TX, not verifier, SSZ, Yul, EVM, or deployment planes.
-/

namespace LidoSRv3.Audit.Verity.TopupPackedStorage

open _root_.Verity hiding pure
open _root_.Verity.Stdlib.Math

def GATEWAY_STORAGE_POSITION : Nat :=
  0x22e512057841e2bc1e6d80030c8bb8b4935377af2e64ba9bf8e6a3e88fb32200

verity_contract GatewayPackedContract where
  storage
    maxValidatorsPerTopUp : Uint64 := slot 0x22e512057841e2bc1e6d80030c8bb8b4935377af2e64ba9bf8e6a3e88fb32200
    lastTopUpTimestamp : Uint32 := slot 0x22e512057841e2bc1e6d80030c8bb8b4935377af2e64ba9bf8e6a3e88fb32200
    lastTopUpBlock : Uint32 := slot 0x22e512057841e2bc1e6d80030c8bb8b4935377af2e64ba9bf8e6a3e88fb32200
    minBlockDistance : Uint16 := slot 0x22e512057841e2bc1e6d80030c8bb8b4935377af2e64ba9bf8e6a3e88fb32200
    maxRootAge : Uint16 := slot 0x22e512057841e2bc1e6d80030c8bb8b4935377af2e64ba9bf8e6a3e88fb32200
    targetBalanceGwei : Uint64 := slot 0x22e512057841e2bc1e6d80030c8bb8b4935377af2e64ba9bf8e6a3e88fb32200
    minTopUpGwei : Uint64 := slot 0x22e512057841e2bc1e6d80030c8bb8b4935377af2e64ba9bf8e6a3e88fb32201
    lastEvaluatedLimit : Uint256 := slot 0x22e512057841e2bc1e6d80030c8bb8b4935377af2e64ba9bf8e6a3e88fb32202
    lastAggregateBudget : Uint256 := slot 0x22e512057841e2bc1e6d80030c8bb8b4935377af2e64ba9bf8e6a3e88fb32203

  function setMaxValidators (value : Uint256) : Unit := do
    setStorage maxValidatorsPerTopUp value
  function setTimestamp (value : Uint256) : Unit := do
    setStorage lastTopUpTimestamp value
  function setBlock (value : Uint256) : Unit := do
    setStorage lastTopUpBlock value
  function setMinBlockDistance (value : Uint256) : Unit := do
    setStorage minBlockDistance value
  function setMaxRootAge (value : Uint256) : Unit := do
    setStorage maxRootAge value
  function setTarget (value : Uint256) : Unit := do
    setStorage targetBalanceGwei value
  function setMinimum (value : Uint256) : Unit := do
    setStorage minTopUpGwei value

  function getTarget () : Uint64 := do
    let value ← getStorage targetBalanceGwei
    return value
  function getMinimum () : Uint64 := do
    let value ← getStorage minTopUpGwei
    return value

  /- The checked source result is supplied at the explicit proof/external-call
  boundary and committed by an actual Verity transaction. -/
  function recordHeadroom (limit : Uint256) : Unit := do
    setStorage lastEvaluatedLimit limit

  function recordBudget (aggregate : Uint256, budget : Uint256) : Unit := do
    require (aggregate <= budget) "AGGREGATE_OVER_BUDGET"
    setStorage lastAggregateBudget aggregate

theorem generated_layout_exact :
    GatewayPackedContract.spec.fields.any (fun f => f.name == "maxValidatorsPerTopUp" &&
      f.slot == some GATEWAY_STORAGE_POSITION && f.packedBits == some ⟨0, 64⟩) &&
    GatewayPackedContract.spec.fields.any (fun f => f.name == "lastTopUpTimestamp" &&
      f.slot == some GATEWAY_STORAGE_POSITION && f.packedBits == some ⟨64, 32⟩) &&
    GatewayPackedContract.spec.fields.any (fun f => f.name == "lastTopUpBlock" &&
      f.slot == some GATEWAY_STORAGE_POSITION && f.packedBits == some ⟨96, 32⟩) &&
    GatewayPackedContract.spec.fields.any (fun f => f.name == "minBlockDistance" &&
      f.slot == some GATEWAY_STORAGE_POSITION && f.packedBits == some ⟨128, 16⟩) &&
    GatewayPackedContract.spec.fields.any (fun f => f.name == "maxRootAge" &&
      f.slot == some GATEWAY_STORAGE_POSITION && f.packedBits == some ⟨144, 16⟩) &&
    GatewayPackedContract.spec.fields.any (fun f => f.name == "targetBalanceGwei" &&
      f.slot == some GATEWAY_STORAGE_POSITION && f.packedBits == some ⟨160, 64⟩) &&
    GatewayPackedContract.spec.fields.any (fun f => f.name == "minTopUpGwei" &&
      f.slot == some (GATEWAY_STORAGE_POSITION + 1) && f.packedBits == some ⟨0, 64⟩) = true := by
  decide

theorem target_setter_reader_run (state : ContractState) (value : Uint64) :
    (((do
      GatewayPackedContract.setTarget value.toUint256
      GatewayPackedContract.getTarget) : Contract Uint64).run state).fst = value := by
  apply Verity.Core.UIntN.ext
  simp [GatewayPackedContract.setTarget, GatewayPackedContract.getTarget,
    Verity.setPackedStorage, Verity.getPackedStorage, Contract.run,
    Verity.bind, Bind.bind, Verity.pure]
  omega

theorem minimum_setter_reader_run (state : ContractState) (value : Uint64) :
    (((do
      GatewayPackedContract.setMinimum value.toUint256
      GatewayPackedContract.getMinimum) : Contract Uint64).run state).fst = value := by
  apply Verity.Core.UIntN.ext
  simp [GatewayPackedContract.setMinimum, GatewayPackedContract.getMinimum,
    Verity.setPackedStorage, Verity.getPackedStorage, Contract.run,
    Verity.bind, Bind.bind, Verity.pure]
  omega

/-- SOURCE -> VERITY_TX for the exact checked headroom value. The validator
proof and surrounding batch guards are the documented boundary, not premises
manufactured by this theorem. -/
def executeSourceHeadroom
    (v : LidoSRv3.Audit.Guarantees.PTopup2.Validator)
    (cfg : LidoSRv3.Audit.Guarantees.PTopup2.TopupConfig) :
    Contract Unit :=
  GatewayPackedContract.recordHeadroom
    (Verity.Core.Uint256.ofNat
      (LidoSRv3.Audit.Guarantees.PTopup2.evaluated_topup_limit v cfg))

theorem source_headroom_materially_runs
    (state : ContractState) (v : LidoSRv3.Audit.Guarantees.PTopup2.Validator)
    (cfg : LidoSRv3.Audit.Guarantees.PTopup2.TopupConfig) :
    ∃ after,
      (executeSourceHeadroom v cfg).run state = .success () after ∧
      after.storage (GATEWAY_STORAGE_POSITION + 2) =
        Verity.Core.Uint256.ofNat
          (LidoSRv3.Audit.Guarantees.PTopup2.evaluated_topup_limit v cfg) := by
  refine ⟨(executeSourceHeadroom v cfg).run state |>.snd, ?_, ?_⟩
  · rfl
  · rfl

theorem record_budget_rejects_over_budget (state : ContractState)
    (aggregate budget : Uint256) (h : ¬ aggregate <= budget) :
    (GatewayPackedContract.recordBudget aggregate budget).run state =
      .revert "AGGREGATE_OVER_BUDGET" state := by
  simp [GatewayPackedContract.recordBudget, Verity.require, h, Contract.run,
    Verity.bind, Bind.bind]

end LidoSRv3.Audit.Verity.TopupPackedStorage
