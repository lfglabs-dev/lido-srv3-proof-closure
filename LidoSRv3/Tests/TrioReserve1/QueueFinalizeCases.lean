import LidoSRv3.Audit.Source.TrioReserve1.QueueFinalize

namespace LidoSRv3.Tests.TrioReserve1.QueueFinalizeCases
open LidoSRv3.Audit.Source.TrioReserve1 Live QueueFinalize

def addr := Verity.Core.Address.ofNat
def ctx : Context := ⟨addr 9, addr 1⟩
/-- Explicit collision-free-on-these-vectors mapping fixture, not a Keccak implementation. -/
def hashFixture : Queue.Keccak := fun data =>
  let id := decode (data.take 32)
  let slot := decode ((data.drop 32).take 32)
  if slot = Queue.queueSlot then word (1000 + id * 4)
  else if slot = checkpointsSlot then word (2000 + id * 2)
  else if slot = rolesSlot then word 3000 else word 4000

def store (w : World) (slot value : Nat) : World :=
  {w with core := w.core.writeContractSlot 9 slot (word value)}
def load (w : World) (slot : Nat) : Nat := (w.core.readContractSlot 9 slot).val

def initial : World :=
  let w : World := ⟨{Verity.defaultState with blockTimestamp := word 77}, fun _ => 80, []⟩
  let w := store w resumeSlot 70
  let w := store w (memberSlot hashFixture ctx.sender) 257
  let w := store w Queue.lastSlot 3
  let w := store w Queue.finalizedSlot 1
  let w := store w checkpointIndexSlot 2
  let w := store w lockedSlot 5
  let w := store w (Queue.requestSlot hashFixture 1) (pack 100 10).val
  store w (Queue.requestSlot hashFixture 3) (pack 180 18).val

def succeeded (r : Result Unit) : Bool := match r.outcome with | .ok _ => true | _ => false
def failed (r : Result Unit) (fault : Fault) : Bool := match r.outcome with
  | .error e => decide (e = fault) | _ => false

def execute (w : World) (last := 3) (amount := 60) : Result Unit :=
  run (entry hashFixture ctx (word last) (word amount) (word 123)) w

def restored (w : World) (r : Result Unit) : Bool :=
  [Queue.finalizedSlot,checkpointIndexSlot,lockedSlot,2006,2007].all
    (fun slot => load r.world slot == load w slot) && r.world.logs.isEmpty &&
    r.world.balances ctx.self == w.balances ctx.self && r.attempts.isEmpty

def success : Bool :=
  let r := execute initial
  succeeded r && [load r.world Queue.finalizedSlot,load r.world checkpointIndexSlot,load r.world lockedSlot,
    load r.world 2006,load r.world 2007] == [3,3,65,2,123] &&
    (match Queue.unfinalizedStETH hashFixture ctx.self r.world with | .ok n => n == 0 | _ => false) &&
    r.world.logs.map (fun l => (l.name,l.values.map (·.val))) ==
      [("WithdrawalsFinalized",[2,3,60,8,77]),("BatchMetadataUpdate",[2,3])] &&
    r.world.balances ctx.self == 80 && r.attempts.isEmpty

def lateRollback : Bool :=
  let w := store initial (Queue.requestSlot hashFixture 3) (pack 180 8).val
  let raw := entry hashFixture ctx (word 3) (word 60) (word 123) w
  let root := execute w
  failed raw (.bubbled (Queue.panicBytes 0x11)) && load raw.world lockedSlot == 65 &&
    load raw.world Queue.finalizedSlot == 3 && restored w root && failed root (.bubbled (Queue.panicBytes 0x11))

def rejects (w : World) (fault : Fault) (last := 3) (amount := 60) : Bool :=
  let r := execute w last amount
  failed r fault && restored w r

def check (name : String) (result : Bool) : IO Unit :=
  if result then IO.println ("PASS " ++ name) else throw (IO.userError ("FAIL " ++ name))

#eval check "finalization-checkpoint-events-live-demand" success
#eval check "late-share-underflow-restores-written-state" lateRollback
#eval check "paused-before-role-and-id" (rejects (store initial resumeSlot 78) (.bubbled (encode 4 0x14378398)) 4)
#eval check "role-low-byte-admission" (rejects (store initial (memberSlot hashFixture ctx.sender) 256) (missingRole ctx.sender))
#eval check "invalid-upper-id" (rejects initial (.bubbled (encode 4 0xc969e0f2 ++ encode 32 4)) 4)
#eval check "already-finalized-id" (rejects initial (.bubbled (encode 4 0xc969e0f2 ++ encode 32 1)) 1)
#eval check "too-much-ether" (rejects initial (.bubbled (encode 4 0x252dfe81 ++ encode 32 81 ++ encode 32 80)) 3 81)
#eval check "entry-first-id-overflow-before-core-guards" (rejects (store initial Queue.finalizedSlot Verity.Core.MAX_UINT256) (.bubbled (Queue.panicBytes 0x11)) 0)
#eval check "steth-underflow-before-checkpoint" (rejects (store initial (Queue.requestSlot hashFixture 3) (pack 90 18).val) (.bubbled (Queue.panicBytes 0x11)))
#eval check "checkpoint-overflow" (rejects (store initial checkpointIndexSlot Verity.Core.MAX_UINT256) (.bubbled (Queue.panicBytes 0x11)))
#eval check "locked-overflow-restores-checkpoint" (rejects (store initial lockedSlot (Verity.Core.MAX_UINT256 - 50)) (.bubbled (Queue.panicBytes 0x11)))
#eval check "zero-value-finalization-allowed" (succeeded (execute initial 3 0))
#eval check "short-calldata-before-pause" (match dispatch hashFixture ctx.self (fun _ _ => .rejected [255])
    ⟨ctx.sender,ctx.self,word 0,encode 4 0xb6013cef⟩ (store initial resumeSlot 78) with
  | .rejected data => data.isEmpty | _ => false)

end LidoSRv3.Tests.TrioReserve1.QueueFinalizeCases
