import LidoSRv3.Audit.Verity.AddressRecipientCallBridge
open LidoSRv3.Audit.Verity.AddressRecipientCallBridge
open LidoSRv3.Audit.Verity.AddressClaimBatchTx
open LidoSRv3.Audit.Source.TrioReserve1.Live (Fault)

-- Runtime evaluations of the actual physical storage/CALL executor. These
-- checks are not kernel proof declarations and introduce no receipt axioms.
def check (label : String) (condition : Bool) : IO Unit :=
  if condition then IO.println s!"PASS {label}" else throw (IO.userError label)

def runtimeContext : Context := ⟨1000, 1⟩
def runtimeWorld : World :=
  { core := { twoClaimState with codeSize := fun a => if a = 1002 then 1 else 0 }
    balances := fun a => if a = runtimeContext.self then 70 else 0 }

def observingCallee : External := fun req w =>
  if req.payload == [] && req.target == (1002 : Address) &&
      (requestClaimed (requestMetadataWord w.core 1)) &&
      (w.core.readSlot lockedEtherAmountPosition).val == 40 then
    .success [7] { w with core := w.core.writeSlot 17 99 }
  else .rejected [42]

def main : IO Unit := do
  let good := runClaimWithdrawalsTo acceptingCallee runtimeContext [1,2] [1,1] 1002 runtimeWorld
  check "two physical claims and ordered CALL amounts" (good.outcome == .ok () &&
    good.attempts.map (fun a => a.request.value.val) == [30,40] &&
    good.world.balances runtimeContext.self == 0 && good.world.balances 1002 == 70 &&
    (good.world.core.readSlot lockedEtherAmountPosition).val == 0 &&
    requestClaimed (requestMetadataWord good.world.core 1) &&
    requestClaimed (requestMetadataWord good.world.core 2))
  let seen := runClaimWithdrawalsTo observingCallee runtimeContext [1] [1] 1002 runtimeWorld
  check "callback observes physical claim and returned storage commits before events" (seen.outcome == .ok () &&
    (seen.world.core.readSlot 17).val == 99 && seen.attempts.map (fun a => a.returned) == [[7]] &&
    seen.world.logs.map (fun l => l.name) == ["WithdrawalClaimed", "Transfer"])
  let later := runClaimWithdrawalsTo observingCallee runtimeContext [1,2] [1,1] 1002 runtimeWorld
  check "later callback rejection restores prior callback storage, balance and events" (
    later.outcome == .error (.reason "CantSendValueRecipientMayHaveReverted") &&
    (later.world.core.readSlot 17).val == (runtimeWorld.core.readSlot 17).val &&
    later.world.balances runtimeContext.self == 70 && later.world.logs.length == 0 &&
    later.attempts.map (fun a => a.accepted) == [true,false])
  let funding := runClaimWithdrawalsTo acceptingCallee runtimeContext [1] [1] 1002
    {runtimeWorld with balances := fun _ => 0}
  check "insufficient funding rolls physical claimed bit back" (
    funding.outcome == .error (.reason "NotEnoughEther") &&
    !(requestClaimed (requestMetadataWord funding.world.core 1)))
  let duplicate := runClaimWithdrawalsTo acceptingCallee runtimeContext [1,1] [1,1] 1002 runtimeWorld
  check "duplicate claim rejects and restores first transfer" (
    duplicate.outcome == .error (.reason "RequestAlreadyClaimed") &&
    duplicate.world.balances runtimeContext.self == 70 && duplicate.world.logs.length == 0)
