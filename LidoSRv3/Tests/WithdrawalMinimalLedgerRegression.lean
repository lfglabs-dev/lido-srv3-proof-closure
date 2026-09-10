import LidoSRv3.Audit.Guarantees.PDeposit1PhysicalLedger
import LidoSRv3.Audit.Guarantees.PTopup1MinimalLedger
import LidoSRv3.Tests.DepositPhysicalMetadataRegression

namespace LidoSRv3.Tests.WithdrawalMinimalLedgerRegression
open Audit.Source TrioReserve1 Live
open audit.trio.deposit
namespace Fixture
open DepositPhysicalMetadataRegression (addr)
def config : Pipeline.Config :=
  ⟨addr 3,⟨addr 3,addr 2,addr 3⟩,⟨word 0,word 1⟩,addr 5,⟨0,1,1,7⟩,addr 1⟩
def context : Context := ⟨addr 1,addr 2⟩
def before : PhysicalMetadata.World :=
  let w := DepositPhysicalMetadataRegression.before
  let c := {w.live.core with codeSize := fun a => if a = 5 then word 0 else word 1}
  let c := c.writeContractSlot 3 Oracle.consensusSlot (word 4)
  let c := c.writeContractSlot 3 Queue.bunkerSlot (word (2^256-1))
  let c := c.writeContractSlot 1 bufferSlot (word (100*DEPOSIT_SIZE))
  ⟨w.allocationTranscript,{w.live with core := c}⟩
def staticOther : StaticCall.External := fun _ _ => .success (encode 32 0 ++ encode 32 1)
def reject : External := fun _ _ => .rejected [255]
def callee := Pipeline.external (fun _ => word 0) config staticOther reject
def withdrawal := Live.run (withdrawDepositableEther callee context (word 7) (word 0)) before.live
def deposited := PhysicalMetadata.execute DepositPhysicalMetadataRegression.hash callee
  DepositPhysicalMetadataRegression.ctx (DepositPhysicalMetadataRegression.inputs 2) before
end Fixture
open Fixture
set_option maxRecDepth 16384
set_option maxHeartbeats 4000000

theorem removed_conditions_are_false :
    config.contracts.queue = config.locator ∧ config.contracts.oracle = config.locator ∧
    config.contracts.oracle = config.contracts.queue ∧
    config.consensus ≠ ConsensusCalls.consensusAddress config.contracts.oracle before.live ∧
    (before.live.core.codeSize config.consensus.val).val = 0 := by decide +kernel

theorem actual_aliased_getters_and_unbound_consensus_succeed :
    (withdrawal.outcome, withdrawal.world.balances context.self,
      withdrawal.world.balances context.sender, withdrawal.attempts.length) =
    (.ok (),100*DEPOSIT_SIZE-7,100*DEPOSIT_SIZE+7,8) := by decide +kernel

theorem locator_missing_code_rejects_without_calls :
    let w := {before.live with core := {before.live.core with codeSize := fun _ => word 0}}
    let r := Live.run (withdrawDepositableEther callee context (word 7) (word 0)) w
    (r.outcome,r.attempts,r.world.balances context.self) =
      (.error .empty,[],100*DEPOSIT_SIZE) := by decide +kernel

/-- The actual nested consensus callback observes the physical metadata before
withdrawal completes; its rejection then restores that metadata and all balances. -/
def metadataObserver : StaticCall.External := fun _ w =>
  if (w.core.readContractSlot 2 1235).val % 2^64 = 42 ∧
      w.logs.head?.map (·.name) = some "StakingRouterETHDeposited" then .rejected [42]
  else .rejected [255]
def observed := PhysicalMetadata.execute DepositPhysicalMetadataRegression.hash
  (Pipeline.external (fun _ => word 0) config metadataObserver reject)
  DepositPhysicalMetadataRegression.ctx (DepositPhysicalMetadataRegression.inputs 2) before

theorem physical_metadata_callback_then_root_rollback :
    observed.outcome = .error (.live (.bubbled [42])) ∧
    observed.world.live.balances context.self = 100*DEPOSIT_SIZE ∧
    observed.world.live.balances context.sender = 100*DEPOSIT_SIZE ∧
    (observed.world.live.core.readContractSlot 2 1235).val = DepositPhysicalMetadataRegression.oldWord ∧
    observed.world.live.logs.map (·.name) = [] ∧
    observed.attempts.getLast?.map (fun a => a.returned.map UInt8.toNat) = some [42] := by
  refine ⟨?_, ?_, ?_, ?_, ?_, ?_⟩ <;> decide +kernel

#print axioms removed_conditions_are_false
#print axioms actual_aliased_getters_and_unbound_consensus_succeed
#print axioms locator_missing_code_rejects_without_calls
#print axioms physical_metadata_callback_then_root_rollback
end LidoSRv3.Tests.WithdrawalMinimalLedgerRegression
