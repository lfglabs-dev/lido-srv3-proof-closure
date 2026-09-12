import LidoSRv3.Audit.Guarantees.PDeposit1ModuleCalls

namespace audit.trio.deposit.Tests.Verity.ModulePhysicalMetadataTest
set_option autoImplicit false
set_option maxRecDepth 16384
set_option maxHeartbeats 4000000
open LidoSRv3.Audit.Source
open TrioReserve1
open ModuleCall ModulePhysicalMetadata

def addr (n : Nat) : Live.Address := Verity.Core.Address.ofNat n
def sw (n : Nat) : TrioAlloc1.Word := TrioAlloc1.word n
def hash : TopupRouterCredentials.Keccak := fun _ => Live.word 90
def ctx : RouterDeposit.Context :=
  ⟨⟨7,by decide⟩,⟨7,by decide⟩,true,some (sw 99),⟨8,by decide⟩,999,999⟩
def liveCtx : Live.Context := ⟨addr 1,addr 2⟩
def input : Input := ⟨sw 7,sw (3*DEPOSIT_SIZE),sw DEPOSIT_SIZE,[0xab,0xcd],Live.word 512⟩
def before : Live.World :=
  let core := {Verity.defaultState with codeSize := (fun _ => Live.word 1), blockTimestamp := Live.word 42,blockNumber := Live.word 99}
  let core := (core.writeContractSlot 2 90 (Live.word (40+2^232))).writeContractSlot 2 91
    (Live.word (7+8*2^64+2*2^128+9*2^192))
  ⟨core,fun _ => 7,[]⟩
def changed : Live.World :=
  let core := (before.core.writeContractSlot 2 90 (Live.word 41)).writeContractSlot 2 91
    (Live.word (12+13*2^64+17*2^128+18*2^192))
  let core := core.writeContractSlot 1 Live.locatorSlot (Live.word 3)
  {before with core := core,balances := (fun _ => 123),logs := [⟨addr 40,"ModuleEffect",[]⟩]}
def nested : List Live.NestedAttempt := [⟨⟨addr 40,addr 44,Live.word 0,[9]⟩,false,true,[8],1⟩]
def answer (raw : Live.Bytes) : Live.External := fun _ _ => .successWithTrace raw changed nested
def reject : Live.External := fun _ _ => .rejected [0xde,0xad]
def result (raw : Live.Bytes) := ModulePhysicalMetadata.execute hash (answer raw) reject ctx liveCtx input before

def zero := result (encodeReturn [] [1])

theorem zero_retains_module_changes :
    (zero.outcome,zero.world.balances (addr 2),zero.world.core.readContractSlot 2 90,
      zero.world.core.readContractSlot 2 91,zero.world.logs.map (·.name),zero.attempts.length) =
      (.ok (),123,Live.word 41,Live.word (42+99*2^64+17*2^128+18*2^192),
        ["ModuleEffect","StakingRouterETHDeposited"],1) := by decide +kernel

theorem zero_uses_entry_address_cap_and_payload :
    (zero.attempts.map (fun a => (a.request.caller.val,a.request.target.val,a.request.value.val,
      a.request.payload,a.nested))) =
    [(2,40,0,payload 2 [0xab,0xcd],nested)] := by decide +kernel

theorem zero_event_value : zero.world.logs.map (fun l => l.values.map (·.val)) = [[],[7,0]] := by
  decide +kernel

def malformed := result [1,2,3]
theorem malformed_outcome : malformed.outcome = .error .empty := by decide +kernel
theorem malformed_rollback : malformed.world = before :=
  ModulePhysicalMetadata.failure_restores hash (answer [1,2,3]) reject ctx liveCtx input before
    malformed.world .empty malformed.attempts (by
      have h := malformed_outcome
      cases he : malformed with
      | mk out world trace => simp only [he] at h; subst out; exact he)

theorem malformed_keeps_nested_attempt :
    malformed.attempts.map (fun a => (a.accepted,a.returned,a.nested)) = [(true,[1,2,3],nested)] := by decide +kernel

def over := result (encodeReturn (List.replicate 144 1) (List.replicate 288 2))
theorem over_target_rejects : over.outcome = .error (.reason "ModuleReturnExceedTarget") := by decide +kernel

def unaligned := result (encodeReturn (List.replicate 49 1) [])
theorem wrong_alignment_rejects : unaligned.outcome = .error (.reason "WrongPubkeyLength") := by decide +kernel

def callback : Live.External := fun _ w =>
  if (w.core.readContractSlot 2 90).val = 41 ∧
    (w.core.readContractSlot 2 91).val = 42+99*2^64+17*2^128+18*2^192 ∧
    w.balances (addr 2) = 123 ∧
    w.logs.map (·.name) = ["ModuleEffect","StakingRouterETHDeposited"] then .rejected [42]
  else .rejected [255]
def shorter := ModulePhysicalMetadata.execute hash
  (answer (encodeReturn (List.replicate 48 1) (List.replicate 96 2))) callback ctx liveCtx input before

theorem below_target_actual_withdrawal_sees_module_and_metadata :
    (shorter.outcome,shorter.attempts.map (·.returned),shorter.world.core.readContractSlot 2 91,
      shorter.world.balances (addr 2),shorter.world.logs.length) =
    (.error (.bubbled [42]),[encodeReturn (List.replicate 48 1) (List.replicate 96 2),[42]],
      before.core.readContractSlot 2 91,7,0) := by decide +kernel

-- Independent hand-built raw bytes, deliberately not an encoder roundtrip.
def unpaddedReversed : Live.Bytes := Live.encode 32 100 ++ Live.encode 32 65 ++ [255] ++
  Live.encode 32 3 ++ [0xaa,0xbb,0xcc] ++ Live.encode 32 2 ++ [0xdd,0xee]
example : decodeReturn (Live.word 128) unpaddedReversed = .ok (⟨[0xdd,0xee],[0xaa,0xbb,0xcc]⟩,Live.word 416) := by decide +kernel
example : decodeReturn (Live.word 128) (List.replicate 64 0) = .ok (⟨[],[]⟩,Live.word 256) := by decide +kernel
example : decodeReturn (Live.word 128) (Live.encode 32 (2^64) ++ Live.encode 32 0) = .error .empty := by decide +kernel
example : decodeReturn (Live.word 128) (Live.encode 32 64 ++ Live.encode 32 (2^64) ++ Live.encode 32 (2^64)) = .error (.reason "Panic(0x41)") := by decide +kernel
example : decodeReturn (Live.word 128) (Live.encode 32 64 ++ Live.encode 32 0 ++ Live.encode 32 (2^64-1)) = .error (.reason "Panic(0x41)") := by decide +kernel
example : decodeReturn (Live.word (2^64-32)) (List.replicate 64 0) = .error (.reason "Panic(0x41)") := by decide +kernel
example : decodeReturn (Live.word (2^64-96)) (List.replicate 64 0) = .error (.reason "Panic(0x41)") := by decide +kernel
example : decodeReturn (Live.word (2^64-128)) (List.replicate 64 0) = .error (.reason "Panic(0x41)") := by decide +kernel
example : signedLt (Live.word (2^256-1)) (Live.word 64) = true := by decide +kernel
example : finalizeAllocation (Live.word 128) (2^256-1) = .ok (Live.word 128) := by decide +kernel
example : finalizeAllocation (Live.word (2^256-1)) 32 = .error (.reason "Panic(0x41)") := by decide +kernel
example : (payload 2 [0xab,0xcd]).take 4 = [0xbe,0xe4,0x1b,0x58] := by decide +kernel
example : (ModulePhysicalMetadata.execute hash (answer (encodeReturn [] [])) reject ctx liveCtx
    {input with selected := sw 0} before).attempts = [] := by decide +kernel
example : (ModulePhysicalMetadata.execute hash (answer (encodeReturn [] [])) reject ctx liveCtx
    {input with maxEB := sw 0} before).outcome = .error (.reason "Panic(0x12)") := by decide +kernel
example : (ModulePhysicalMetadata.execute hash (answer (encodeReturn [] [])) reject ctx liveCtx input
    {before with core := {before.core with codeSize := fun _ => Live.word 0}}).outcome = .error .empty := by decide +kernel
example : (ModulePhysicalMetadata.execute hash reject reject ctx liveCtx input before).outcome =
    .error (.bubbled [0xde,0xad]) := by decide +kernel

-- A fully funded world for the actual accepted RESERVE withdrawal and beacon.
def pipelineConfig : Pipeline.Config :=
  ⟨addr 3,⟨addr 4,addr 2,addr 5⟩,⟨Live.word 0,Live.word 1⟩,addr 6,⟨0,1,1,7⟩,addr 1⟩
def rejectStatic : StaticCall.External := fun _ _ => .rejected []
def withdrawalExternal := Pipeline.external (fun _ => Live.word 0) pipelineConfig rejectStatic reject
def funded : Live.World :=
  let core := {changed.core with blockTimestamp := Live.word 1,blockNumber := Live.word 3}
  let core := (core.writeContractSlot 1 Live.locatorSlot (Live.word 3)).writeContractSlot 5 Oracle.consensusSlot (Live.word 6)
  let core := (core.writeContractSlot 1 Live.activeSlot (Live.word 1)).writeContractSlot 1 Live.bufferSlot (Live.word (100*10^18))
  let core := core.writeContractSlot 4 Queue.bunkerSlot (Live.word (2^256-1))
  let core := (core.writeContractSlot 6 7 (Live.word (2^64))).writeContractSlot 1 Live.seedSlot (Live.word 9)
  let core := core.writeContractSlot 8 TopupBeaconCallee.countSlot (Live.word 3)
  ⟨core,fun a => if a=addr 1 then 100*10^18 else if a=addr 2 then 123 else if a=addr 8 then 11 else 0,
    [⟨addr 40,"ModuleEffect",[]⟩]⟩
def rawPositive : Live.Bytes := encodeReturn (List.replicate 96 1) (List.replicate 192 2)
def positiveModule : Live.External := fun _ _ => .successWithTrace rawPositive funded nested
def prepared : PreparedDeposit :=
  ⟨sw 7,sw DEPOSIT_SIZE,⟨List.replicate 96 (TrioAlloc1.byte 1),List.replicate 192 (TrioAlloc1.byte 2)⟩,
    ⟨3*DEPOSIT_SIZE,2,2*DEPOSIT_SIZE,DEPOSIT_SIZE,2*DEPOSIT_SIZE⟩⟩
def updated := PhysicalMetadata.update hash ctx liveCtx.sender prepared funded
def positive := ModulePhysicalMetadata.execute hash positiveModule withdrawalExternal ctx liveCtx input before

/-- A positive execution proved with the existing actual withdrawal and beacon
semantics. The module returned `funded`; its changed physical word and event
are updated before those calls. SHA remains symbolic in the kernel proof. -/
theorem positive_execution : positive.outcome = .ok () := by
  obtain ⟨withdrawn,hwithdraw,hbalance,hcode,hcount,_⟩ := LiveBeacon.withdrawal_success
    (fun _ => Live.word 0) pipelineConfig rejectStatic reject liveCtx updated prepared 0 0 1 0
    (by decide) (by decide) (by decide) (by constructor <;> decide) (by decide) (by decide)
    rfl (by rfl) (by decide) (by rfl) (by rfl) (by decide) (by decide) rfl (by decide) (by decide)
  have hrouter : withdrawn.balances liveCtx.sender = updated.balances liveCtx.sender + 2*DEPOSIT_SIZE :=
    hbalance.router_credit
  have hadm := LiveBeacon.keyInputs_admissible (TrioAlloc1.encodeWord (sw 99)) prepared
    (TrioAlloc1.encodeWord_length _) (by decide) (by decide) 2 0 (by decide)
  obtain ⟨after,hloop,hledger,_,_,_⟩ := TopupBeaconBatch.loop_success
    (LiveBeacon.routerContext liveCtx ctx) (LiveBeacon.beaconAddress ctx) (LiveBeacon.amounts 2)
    (LiveBeacon.keyInputs (TrioAlloc1.encodeWord (sw 99)) prepared 2 0) withdrawn hadm
    (by decide) (by rw [hcode]; decide)
    (by rw [LiveBeacon.allocSum_amounts]; change 2*DEPOSIT_SIZE ≤ withdrawn.balances liveCtx.sender; rw [hrouter]; omega)
    (by rw [hcount,LiveBeacon.nonzeroCount_amounts]; decide)
  have hassert : after.balances liveCtx.sender = updated.balances liveCtx.sender := by
    have hh := hledger liveCtx.sender
    rw [LiveBeacon.allocSum_amounts] at hh
    change after.balances liveCtx.sender + (if liveCtx.sender = liveCtx.sender then 2*DEPOSIT_SIZE else 0) =
      withdrawn.balances liveCtx.sender + (if liveCtx.sender = LiveBeacon.beaconAddress ctx then 2*DEPOSIT_SIZE else 0) at hh
    have hne : liveCtx.sender ≠ LiveBeacon.beaconAddress ctx := by decide
    simp only [ite_true,if_neg hne,Nat.add_zero] at hh
    omega
  have hsuffix := LiveBeacon.suffix_success withdrawalExternal ctx liveCtx (sw 99) prepared
    updated withdrawn after _ _ (by decide) hwithdraw (by decide) hloop hassert
  have hdecode : decodeReturn input.returnBuffer rawPositive =
    .ok (⟨List.replicate 96 1,List.replicate 192 2⟩,Live.word 1280) := by decide +kernel
  have hprepare : prepare input 2 ⟨List.replicate 96 1,List.replicate 192 2⟩ = .ok prepared := by decide +kernel
  have hp := program_of_call hash positiveModule withdrawalExternal ctx liveCtx input before funded
    (sw 99) rawPositive [⟨⟨addr 2,addr 40,Live.word 0,payload 2 input.depositCalldata⟩,true,rawPositive,nested⟩]
    rfl rfl rfl (by decide) (by decide) (by rfl)
  have ht : target hash liveCtx.sender input before = 2 := by decide +kernel
  rw [ht] at hp
  simp only [continuation,hdecode,hprepare] at hp
  change ModulePhysicalMetadata.program hash positiveModule withdrawalExternal ctx liveCtx input before = _ at hp
  simp only [updated] at hsuffix
  rw [hsuffix] at hp
  simp only [positive,ModulePhysicalMetadata.execute,Live.run,hp]

/-- The positive fixture reaches the public consumer without a supplied
successful stage. It therefore has a real module/suffix commitment. -/
theorem positive_has_commitment : Nonempty (Commitment hash positiveModule withdrawalExternal
    ctx liveCtx input before positive.world positive.attempts) := by
  have heq : ModulePhysicalMetadata.execute hash positiveModule withdrawalExternal ctx liveCtx input before =
      ⟨.ok (),positive.world,positive.attempts⟩ := by
    have h := positive_execution
    cases he : positive with
    | mk out world trace =>
      simp only [he] at h
      subst out
      exact he
  obtain ⟨c,_⟩ := LidoSRv3.Audit.Guarantees.PDeposit1.actual_module_call_metadata_suffix
    hash positiveModule withdrawalExternal ctx liveCtx input before positive.world positive.attempts heq
  exact ⟨c⟩

-- This fixture computes the real entire suffix; SHA-heavy checks use #eval.
-- The public necessary-success theorem remains checked by the normal kernel.
def checkPositive : IO Unit := do
  unless positive.outcome == .ok () && positive.world.balances (addr 2) == 123 &&
      positive.world.balances (addr 1) + 2*DEPOSIT_SIZE == 100*10^18 &&
      positive.world.balances (addr 8) == 11+2*DEPOSIT_SIZE &&
      (positive.world.core.readContractSlot 8 TopupBeaconCallee.countSlot).val == 5 &&
      (positive.world.core.readContractSlot 2 90).val == 41 &&
      (positive.world.core.readContractSlot 2 91).val == 1+3*2^64+17*2^128+18*2^192 &&
      ((positive.world.logs.take 2).map (·.name)) == ["ModuleEffect","StakingRouterETHDeposited"] do
    throw (IO.userError "actual module + physical metadata + withdrawal/beacon positive failed")
#eval checkPositive

def lateModule : Live.External := fun _ _ => .successWithTrace rawPositive
  {funded with core := (funded.core.writeContractSlot 8 TopupBeaconCallee.countSlot (Live.word (TopupBeaconCallee.maxCount-1)))} nested

def lateRaw := ModulePhysicalMetadata.program hash lateModule withdrawalExternal ctx liveCtx input before
def late := ModulePhysicalMetadata.execute hash lateModule withdrawalExternal ctx liveCtx input before

def checkLate : IO Unit := do
  unless late.outcome == .error (.bubbled "merkle tree full".toUTF8.toList) &&
      late.world.balances (addr 2) == before.balances (addr 2) &&
      late.world.balances (addr 8) == before.balances (addr 8) &&
      late.world.core.readContractSlot 2 90 == before.core.readContractSlot 2 90 &&
      late.world.core.readContractSlot 2 91 == before.core.readContractSlot 2 91 &&
      late.world.logs.length == 0 &&
      (lateRaw.world.core.readContractSlot 8 TopupBeaconCallee.countSlot).val == TopupBeaconCallee.maxCount &&
      lateRaw.world.balances (addr 8) == 11+DEPOSIT_SIZE &&
      (late.attempts.filter (fun a => a.request.target == addr 8)).map (·.accepted) == [true,false] do
    throw (IO.userError "late actual beacon failure lost partial attempt history or root rollback")
#eval checkLate

#print axioms positive_execution
#print axioms positive_has_commitment
#print axioms zero_retains_module_changes
#print axioms zero_uses_entry_address_cap_and_payload
#print axioms malformed_rollback
#print axioms below_target_actual_withdrawal_sees_module_and_metadata
end audit.trio.deposit.Tests.Verity.ModulePhysicalMetadataTest
