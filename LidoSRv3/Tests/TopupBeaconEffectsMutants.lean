import LidoSRv3.Audit.Source.TopupBeaconEffects

namespace LidoSRv3.Tests.TopupBeaconEffectsMutants
open LidoSRv3.Audit.Source TopupBeaconCallee TopupBeaconEffects TrioReserve1 Live

/-! Deterministic kernel regressions use an explicit zero hash to isolate
ABI/control-flow/world effects. These do NOT validate SHA or cryptographic
field binding. The separate pinned0.6.11 Solidity receipt uses actual SHA. -/
def zeroHash : Hash := fun _ => Inhabited.default
def router : Address := Verity.Core.Address.ofNat 10
def beacon : Address := Verity.Core.Address.ofNat 20
def outsider : Address := Verity.Core.Address.ofNat 30
def ctx : Context := ⟨router, outsider⟩
def ether : Nat := 10^18
def fields : Fields :=
  ⟨1 :: List.replicate 47 0, 2 :: List.replicate 31 0, List.replicate 96 0, word 0⟩
def payload : Bytes := canonicalPayload fields
def before : World :=
  ⟨{Verity.defaultState with
      codeSize := fun _ => word 1
      storageWords := fun k => if k = Verity.StorageKey.contractSlot beacon.val countSlot then word 3 else word 77},
    fun a => if a = router then 5*ether+7 else if a = beacon then 3*ether+11 else 13, []⟩
def first : Result Bytes := push zeroHash ctx beacon payload (word ether) before

set_option maxRecDepth 16384
set_option maxHeartbeats 2000000

example : payload.length = 420 := by decide
example : payload.take 4 = [0x22,0x89,0x51,0x18] := by decide
example : decodePayload payload = some fields := by decide
example : first.outcome = .ok [] := by decide
example : first.world.balances router = 4*ether+7 ∧
    first.world.balances beacon = 4*ether+11 ∧ first.world.balances outsider = 13 := by decide
example : (first.world.core.readContractSlot beacon.val countSlot).val = 4 := by decide
/-- Count3→4 carries past two old branch nodes and writes exactly slot2. -/
example : (first.world.core.readContractSlot beacon.val 2).val = 0 ∧
    (first.world.core.readContractSlot beacon.val 0).val = 77 ∧
    (first.world.core.readContractSlot beacon.val 1).val = 77 ∧
    (first.world.core.readContractSlot beacon.val 3).val = 77 := by decide
example : first.world.logs.map (·.emitter) = [beacon] ∧
    first.world.logs.map (fun l => l.values.length) = [192] := by decide
example : (first.world.logs[0]?.map (fun l => l.values.take 2)) = some [word 1,word 0] ∧
    (first.world.logs[0]?.map (fun l => (l.values.drop 184).take 8)) =
      some [word 3,word 0,word 0,word 0,word 0,word 0,word 0,word 0] := by decide
example : first.attempts.map (fun a => (a.request.target,a.request.value,a.request.payload)) =
    [(beacon,word ether,payload)] := by decide

/-- Selector written as32 bytes is not the actual call's4-byte selector. -/
def wrongSelectorWidth : Bytes := encode 32 selector ++ payload.drop 4
example : decodePayload wrongSelectorWidth = none := by decide
/-- Head offset corrupted while keeping all field bytes and declared lengths. -/
def badOffset : Bytes := payload.take 4 ++ encode 32 1000 ++ payload.drop 36
example : decodePayload badOffset = none := by decide

def wrongRoot : Bytes := canonicalPayload {fields with suppliedRoot := word 1}
def rootFailure := push zeroHash ctx beacon wrongRoot (word ether) before
example : rootFailure.outcome = .error (.bubbled "reconstructed root mismatch".toUTF8.toList) := by rfl
example : rootFailure.world.balances router = 5*ether+7 ∧
    rootFailure.world.balances beacon = 3*ether+11 ∧ rootFailure.world.logs.length = 0 := by decide

/-- The caller helper's minimum/uint64 guards omit this actual callee check. -/
def unaligned := push zeroHash ctx beacon payload (word (ether+1)) before
example : unaligned.outcome = .error (.bubbled "deposit value not multiple of gwei".toUTF8.toList) := by rfl
/-- Length errors precede minimum; alignment precedes uint64/root/tree checks. -/
example : (deposit zeroHash {fields with pubkey := []} ⟨router,beacon,word 0,payload⟩ before) =
    rejected "invalid pubkey length" := by rfl
example : (push zeroHash ctx beacon wrongRoot (word 0) before).outcome =
    .error (.bubbled "deposit value too low".toUTF8.toList) := by rfl

def full : World := {before with core := before.core.writeContractSlot beacon.val countSlot (word maxCount)}
example : (push zeroHash ctx beacon payload (word ether) full).outcome =
    .error (.bubbled "merkle tree full".toUTF8.toList) := by rfl
example : (push zeroHash ctx beacon wrongRoot (word ether) full).outcome =
    .error (.bubbled "reconstructed root mismatch".toUTF8.toList) := by rfl

/-- Late callee root failure follows an accepted first deposit, but outer run
restores its transferred ETH, physical tree write/count and committed event. -/
def late := execute zeroHash ctx beacon [(payload,word ether),(wrongRoot,word ether)] before
example : late.outcome = .error (.bubbled "reconstructed root mismatch".toUTF8.toList) := by rfl
example : late.world.balances router = 5*ether+7 ∧ late.world.balances beacon = 3*ether+11 ∧
    (late.world.core.readContractSlot beacon.val countSlot).val = 3 ∧
    (late.world.core.readContractSlot beacon.val 2).val = 77 ∧ late.world.logs.length = 0 := by decide
example : late.attempts.map (·.accepted) = [true,false] := by decide

example : (first.world.logs[0]?.map (fun l => (l.values.drop 80).take 8)) =
    some [word 0,word 202,word 154,word 59,word 0,word 0,word 0,word 0] := by decide

/-- Code/funds failures occur in the real CALL primitive before dispatch. -/
def noCode : World := {before with core := {before.core with codeSize := fun _ => word 0}}
example : (push zeroHash ctx beacon payload (word ether) noCode).outcome = .error .empty ∧
    (push zeroHash ctx beacon payload (word ether) noCode).attempts = [] := by decide
example : (push zeroHash ctx beacon payload (word (6*ether)) before).outcome =
    .error (.bubbled []) ∧
    (push zeroHash ctx beacon payload (word (6*ether)) before).world.balances beacon = 3*ether+11 := by decide

/-- uint64-overflow amount is rejected by the callee after alignment passes. -/
example : deposit zeroHash fields ⟨router,beacon,word ((2^64)*10^9),payload⟩ before =
    rejected "deposit value too high" := by rfl

/-- Deepest possible carry writes slot31 and retains the count at slot32. -/
def deep : World := {before with core := before.core.writeContractSlot beacon.val countSlot (word (2^31-1))}
def deepResult := push zeroHash ctx beacon payload (word ether) deep
example : deepResult.outcome = .ok [] ∧
    (deepResult.world.core.readContractSlot beacon.val 31).val = 0 ∧
    (deepResult.world.core.readContractSlot beacon.val 30).val = 77 ∧
    (deepResult.world.core.readContractSlot beacon.val countSlot).val = 2^31 := by decide

end LidoSRv3.Tests.TopupBeaconEffectsMutants

#print axioms LidoSRv3.Audit.Source.TopupBeaconCallee.insert_selection
#print axioms LidoSRv3.Audit.Source.TopupBeaconCallee.dispatch_balances
#print axioms LidoSRv3.Audit.Source.TopupBeaconCallee.reconstructed_source
#print axioms LidoSRv3.Audit.Source.TopupBeaconCallee.source_deposit_success
#print axioms LidoSRv3.Audit.Source.TopupBeaconEffects.sourcePayload_eq
#print axioms LidoSRv3.Audit.Source.TopupBeaconEffects.decode_sourcePayload
#print axioms LidoSRv3.Audit.Source.TopupBeaconEffects.source_push_success
#print axioms LidoSRv3.Audit.Source.TopupBeaconEffects.failure_restores
