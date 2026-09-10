import LidoSRv3.Audit.Guarantees.PTopup2ActualBatch

namespace LidoSRv3.Tests.TopupBatchConsumerRegression
open Audit.Source TrioReserve1 Live SszValidatorLeaf SszVerifierEntry SszWrapperIndex
open TopupGatewayWitnessBatch

set_option maxRecDepth 16384
set_option maxHeartbeats 2000000

def address (n : Nat) : Address := Verity.Core.Address.ofNat n
def ctx : Context := ⟨address 1,address 2⟩
def mapHash : TopupRouterCredentials.Keccak := fun _ => word 90
def witness : Witness :=
  ⟨List.replicate 48 0,32,false,0,0,BitVec.ofNat 64 (2^64-1),0⟩
def row : Row := ⟨⟨0,by decide⟩,witness,List.replicate 50 0,⟨0,by decide⟩⟩
def gi : Configuration := pinnedConfiguration ⟨0,by decide⟩
def beacon : BeaconData := ⟨1,0,0⟩
def oracle : RootOracle := fun _ _ => ⟨true,List.replicate 32 0⟩
-- Constant SHA is a structural fixture, not a cryptographic/root authenticity check.
def sha : Sha := fun _ => 0

def before : World :=
  let core := {Verity.defaultState with codeSize := fun _ => word 1}
  let core := core.writeContractSlot 2 90 (word (40+2*2^232))
  let core := core.writeContractSlot 3 TopupGatewayConfigWords.gatewayRoot (word (2+64*2^160))
  let core := core.writeContractSlot 3 (TopupGatewayConfigWords.gatewayRoot+1) (word 1)
  let core := core.writeContractSlot 2 (TopupRouterCredentials.routerRoot+5) (word (7+20*2^24+9*2^88))
  ⟨core,fun _ => 7,[]⟩
def changed : World := { before with
  balances := fun _ => 12
  logs := [⟨address 40,"ActualModuleEffect",[word 9]⟩] }
def expectedInput : TopupModuleCall.Input :=
  ⟨word 7,word 20000000000,[List.replicate 48 0],[word 42],[word 3],[word 32000000000]⟩
def reject : External := fun _ _ => .rejected [0xde,0xad]
def moduleWith (allocation : Word) : External := fun req _ =>
  if req.caller = address 2 ∧ req.target = address 40 ∧ req.value = word 0 ∧
      req.payload = TopupModuleCall.payload expectedInput then
    .success (TopupModuleCall.encodeReturn [allocation]) changed
  else .rejected [0xba,0xdd]
def runWith (allocation : Word) := TopupBatchConsumer.run mapHash (moduleWith allocation) reject (standardSha sha) oracle (fun _ => 0)
  gi beacon ⟨32,by decide⟩ 0 (address 3) ctx (address 8) (word 7)
  [word 42] [word 3] [row] (word (2^256-1)) before
def run := runWith (word 0)

theorem packed_cap : (TopupBatchConsumer.blockCap (address 2) before).val = 20 := by decide +kernel
example : (TopupBatchConsumer.target (address 2) (word (2^256-1)) before).val = 20000000000 := by decide +kernel
example : (TopupBatchConsumer.target (address 2) (word 19999999999) before).val = 19000000000 := by decide +kernel
example : (TopupBatchConsumer.target (address 2) (word 0) before).val = 0 := by decide +kernel

/-- The concrete callee accepts only the expected produced calldata. The real
zero-allocation reply still commits the module effect and the final top-up event. -/
theorem zero_batch_consumes_actual_module :
    run.map (fun r => (r.outcome,r.world.balances (address 2),r.world.logs.map (·.name),r.attempts.length)) =
      .ok (.ok (),12,["ActualModuleEffect","StakingRouterETHTopUp"],1) := by decide +kernel

/-- A reply below the witness's 32 Gwei limit but above the actual 20 Gwei
target is rejected after decoding. Provisional module balances and logs roll
back; the diagnostic attempt remains observable in the model. -/
theorem above_cap_restores_module_effects :
    (runWith (word 21000000000)).map (fun r =>
      (r.outcome,r.world.balances (address 2),r.world.logs.map (·.name),r.attempts.length)) =
      .ok (.error (.reason "ModuleReturnExceedTarget"),7,[],1) := by decide +kernel

#print axioms packed_cap
#print axioms zero_batch_consumes_actual_module
#print axioms above_cap_restores_module_effects
end LidoSRv3.Tests.TopupBatchConsumerRegression
