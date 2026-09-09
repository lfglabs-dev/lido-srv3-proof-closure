import LidoSRv3.Audit.Source.TopupModuleCall
import LidoSRv3.Tests.TopupRouterContinuationMutants

namespace LidoSRv3.Tests.TopupModuleCallMutants
open LidoSRv3.Audit.Source TrioReserve1 Live TopupModuleCall

set_option maxRecDepth 16384
set_option maxHeartbeats 2000000

def address (n : Nat) : Address := Verity.Core.Address.ofNat n
def ctx : Context := ⟨address 1,address 2⟩
def routerCtx : Context := ⟨address 2,address 1⟩
def mapHash : TopupRouterCredentials.Keccak := fun _ => word 90
def key (b : UInt8) : Bytes := b :: List.replicate 47 0
def input : Input := ⟨word 7,word 0,[key 1,key 255],[word 42,word (2^256-1)],
  [word 3,word 9],[word 1000000000,word 2000000000]⟩
def before : World :=
  let core := {Verity.defaultState with codeSize := fun _ => word 1}
  let core := core.writeContractSlot 2 90 (word (40+2*2^232))
  ⟨core,fun _ => 7,[]⟩
def changed : World :=
  ⟨before.core,fun _ => 12,[⟨address 40,"ActualModuleEffect",[word 9]⟩]⟩
def reject : External := fun _ _ => .rejected [0xde,0xad]
def answer (raw : Bytes) : External := fun _ _ => .success raw changed
def zeroResult := TopupModuleCall.execute mapHash (answer (encodeReturn [word 0,word 0]))
  reject ctx (address 8) input before

example : (moduleAddress mapHash (address 2) (word 7) before).val = 40 := by decide
example : (moduleAddress mapHash (address 2) (word 7)
  {before with core := before.core.writeContractSlot 2 90 (word (41+255*2^232))}).val = 41 := by decide
example : (payload input).take 4 = [0x78,0x3b,0x8a,0x65] := by decide
example : decodeReturn [] = .error .empty := by decide
example : decodeReturn (List.replicate 31 0) = .error .empty := by decide
example : decodeReturn (encode 32 (2^64)) = .error .empty := by decide
example : decodeReturn (encode 32 64 ++ encode 32 0) = .error .empty := by decide
example : decodeReturn (encode 32 32 ++ encode 32 (2^64)) = .error (.reason "Panic(0x41)") := by decide
-- Compiler allocation may panic before this logical extent guard. This
-- difference is retained explicitly; it is not a full compiler decoder model.
example : decodeReturn (encode 32 32 ++ encode 32 (2^59)) = .error .empty := by decide
example : decodeReturn (encode 32 32 ++ encode 32 2 ++ encode 32 9) = .error .empty := by decide
example : decodeReturn (encodeReturn [word 1,word (2^256-1)] ++ [0xab]) =
    .ok [word 1,word (2^256-1)] := decodeReturn_encoded _ _ (by decide)
-- The byte decoder does not invent an offset-alignment or canonicality guard.
example : decodeReturn (encode 32 0) = .ok [] := by decide
example : decodeReturn (encode 32 33 ++ [0xff] ++ encode 32 1 ++ encode 32 7) =
    .ok [word 7] := by decide

example : zeroResult.outcome = .ok () := by rfl
example : zeroResult.world.balances (address 2) = 12 := by rfl
example : before.balances (address 2) ≠ zeroResult.world.balances (address 2) := by decide
example : zeroResult.world.logs.map (·.name) = ["ActualModuleEffect","StakingRouterETHTopUp"] := by rfl
example : zeroResult.attempts.length = 1 := by rfl
example : zeroResult.attempts.map (fun a => (a.request.caller.val,a.request.target.val,a.request.value.val)) =
    [(2,40,0)] := by rfl
example : zeroResult.attempts.map (·.request.payload) = [payload input] := by rfl
example : zeroResult.attempts.map (·.returned) = [encodeReturn [word 0,word 0]] := by rfl

def malformed := TopupModuleCall.execute mapHash (answer [1,2,3]) reject ctx (address 8) input before
example : malformed.outcome = .error .empty := by rfl
example : malformed.world = before := TopupModuleCall.failure_restores _ _ _ _ _ _ _ _ (by rfl)
example : malformed.attempts.map (·.accepted) = [true] := by rfl
example : (TopupModuleCall.execute mapHash reject reject ctx (address 8) input before).outcome =
    .error (.bubbled [0xde,0xad]) := by rfl

def over := TopupModuleCall.execute mapHash (answer (encodeReturn [word 1000000000]))
  reject ctx (address 8) input before
example : over.outcome = .error (.reason "ModuleReturnExceedTarget") := by rfl
example : over.world = before := TopupModuleCall.failure_restores _ _ _ _ _ _ _ _ (by rfl)
example : over.attempts.length = 1 := by rfl

def noCode : World := {before with core := {before.core with codeSize := fun _ => word 0}}
example : TopupModuleCall.call mapHash (answer (encodeReturn [])) routerCtx input noCode =
    ⟨.error .empty,noCode,[]⟩ := by rfl

-- The accepted positive withdrawal/beacon scenario is now driven by a raw
-- module reply. The module's returned World is exactly that scenario's start.
def positiveInput : Input :=
  let i := TopupRouterContinuationMutants.input
  ⟨i.moduleId,i.roundedTarget,i.pubkeys,[word 1,word 2,word 3],
    [word 4,word 5,word 6],i.limits⟩
def positiveModule : External := fun _ _ => .success
  (encodeReturn TopupRouterContinuationMutants.input.allocations)
  TopupRouterContinuationMutants.before
def positiveProgram := program mapHash positiveModule TopupRouterContinuationMutants.callee
  ctx (address 8) positiveInput before

theorem positive_execution : positiveProgram.outcome = .ok () := by
  have hp := program_encoded mapHash positiveModule TopupRouterContinuationMutants.callee
    ctx (address 8) positiveInput before TopupRouterContinuationMutants.before
    TopupRouterContinuationMutants.input.allocations []
    [⟨⟨address 2,address 40,word 0,payload positiveInput⟩,true,
      encodeReturn TopupRouterContinuationMutants.input.allocations,[]⟩]
    (by decide) (by rfl)
  change positiveProgram = _ at hp
  rw [hp]
  have outcome_run (p : Exec Unit) (w : World) : (Live.run p w).outcome = (p w).outcome := by
    unfold Live.run
    cases hr : (p w).outcome <;> simp [hr]
  have h := TopupRouterContinuationMutants.positiveFacts.2.1
  unfold TopupRouterContinuation.execute at h
  rw [outcome_run] at h
  exact h

#print axioms TopupModuleCall.address_packed
#print axioms TopupModuleCall.call_success_origin
#print axioms TopupModuleCall.decodeReturn_encoded
#print axioms TopupModuleCall.program_success_origin
#print axioms TopupModuleCall.program_encoded
#print axioms TopupModuleCall.failure_restores
#print axioms positive_execution
end LidoSRv3.Tests.TopupModuleCallMutants
