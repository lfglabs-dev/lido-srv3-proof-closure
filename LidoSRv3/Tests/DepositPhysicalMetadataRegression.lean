import LidoSRv3.Audit.Guarantees.PDeposit1PhysicalMetadata
namespace LidoSRv3.Tests.DepositPhysicalMetadataRegression
open Audit.Source Audit.Source.TrioReserve1
open audit.trio.deposit
open TrioAlloc1
set_option maxRecDepth 16384
set_option maxHeartbeats 2000000

def layout : Layout where
  routerSlot := word 0
  keccak := fun bytes =>
    if bytes.length = 32 then word 100
    else if (decodeWord bytes 32).val = 2 then
      if (decodeWord bytes 0).val = 7 then word 300 else word 301
    else word 200
def prefixStorage : Storage := fun key =>
  if key.val = 1 then word 1
  else if key.val = 100 then word 7
  else if key.val = 200 then word (11 + 10000 * 2^192 + 2^232)
  else if key.val = 300 then word 1 else word 0
def oracle : StaticOracle := fun _ _ =>
  .returned (encodeWord (word 0) ++ encodeWord (word 1) ++ encodeWord (word 5))
def addr (n : Nat) : Live.Address := Verity.Core.Address.ofNat n
def oldWord : Nat := 9 + 10 * 2^64 + 11 * 2^128 + 12 * 2^192
def hash : TopupRouterCredentials.Keccak := fun bytes =>
  if bytes = Live.encode 32 7 ++ Live.encode 32 TopupRouterCredentials.routerRoot then
    Live.word 1234 else Live.word 4321
def ctx : RouterDeposit.Context :=
  ⟨⟨7,by decide⟩,⟨7,by decide⟩,true,some (word 99),⟨8,by decide⟩,2^64+42,2^64+99⟩
def inputs (count : Nat) : RouterDeposit.Inputs where
  layout := layout
  «storage» := prefixStorage
  oracle := oracle
  config := ⟨word DEPOSIT_SIZE,word (2 * DEPOSIT_SIZE)⟩
  requested := word (2 * DEPOSIT_SIZE + 1)
  moduleId := word 7
  limits := ⟨8⟩
  obtainDepositData := fun target => if target = 2 then
    .ok ⟨List.replicate (48*count) (byte 1),List.replicate (96*count) (byte 2)⟩
    else .error .exceptionalCall
  liveContext := ⟨addr 1,addr 2⟩
def before : PhysicalMetadata.World :=
  let c := {Verity.defaultState with codeSize := fun _ => Live.word 1, blockTimestamp := Live.word (2^64+42), blockNumber := Live.word (2^64+99)}
  let c := (c.writeContractSlot 1 Live.locatorSlot (Live.word 3)).writeContractSlot 1 Live.activeSlot (Live.word 1)
  ⟨[],⟨c.writeContractSlot 2 1235 (Live.word oldWord),fun _ => 100 * DEPOSIT_SIZE,[]⟩⟩
def callback : Live.External := fun _ w =>
  let packed := (w.core.readContractSlot 2 1235).val
  if packed % 2^64 = 42 ∧ packed / 2^64 % 2^64 = 99 ∧
      w.logs.map (·.name) = ["StakingRouterETHDeposited"] then .rejected [42]
  else .rejected [255]
def run (count : Nat) := PhysicalMetadata.execute hash callback ctx (inputs count) before

theorem zero_keys_commit_physical_word :
    ((run 0).outcome,(run 0).world.live.core.readContractSlot 2 1235,
      (run 0).world.live.logs.map (·.name),(run 0).attempts.length) =
    (.ok (),Live.word (42+99*2^64+11*2^128+12*2^192),["StakingRouterETHDeposited"],0) := by
  decide +kernel

/-- A source getter's actual callback sees the updated word and event.
The old post-suffix auxiliary metadata execution would return [255]. -/
theorem withdrawal_callback_consumes_updated_world :
    ((run 2).attempts.map (·.returned),(run 2).world.live.core.readContractSlot 2 1235,
      (run 2).world.live.logs.map (·.name)) = ([[42]],Live.word oldWord,[]) := by
  decide +kernel

theorem mapping_slot_addition_wraps :
    PhysicalMetadata.moduleDepositSlot (fun _ => Live.word (2^256-1)) (word 7) = 0 := by decide +kernel

#print axioms zero_keys_commit_physical_word
#print axioms withdrawal_callback_consumes_updated_world
#print axioms mapping_slot_addition_wraps
end LidoSRv3.Tests.DepositPhysicalMetadataRegression
