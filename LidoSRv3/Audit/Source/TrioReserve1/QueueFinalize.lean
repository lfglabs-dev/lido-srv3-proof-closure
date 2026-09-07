import LidoSRv3.Audit.Source.TrioReserve1.Queue
import LidoSRv3.Audit.Source.TrioReserve1.ReplyABI

namespace LidoSRv3.Audit.Source.TrioReserve1.QueueFinalize
open Live

def checkpointsSlot : Nat := 0x445f3cbbc114a35d080f2a1953516d74e74d5106860bc2317840ba265f03b51a
def checkpointIndexSlot : Nat := 0x9d8be19d6a54e40bd767aa61b0f462241f5562ef6967d7045485bccac825b240
def lockedSlot : Nat := 0x0e27eaa2e71c8572ab988fef0b54cd45bbd1740de1e22343fb6cda7536edc12f
def resumeSlot : Nat := 0xe8b012900cb200ee5dfc3b895a32791b67d12891b09f117814f167a237783a02
def rolesSlot : Nat := 0x9a627a5d4aa7c17f87ff26e3fe9a42c2b6c559e8b41a42282d0ecebb17c0e4d3
def finalizeRole : Nat := 0x485191a2ef18512555bd4426d18a716ce8e98c80ec2de16394dcf86d7d91bc80

def checkpointSlot (keccak : Queue.Keccak) (index : Nat) : Nat :=
  (keccak (encode 32 index ++ encode 32 checkpointsSlot)).val

def memberSlot (keccak : Queue.Keccak) (account : Address) : Nat :=
  let roleBase := (keccak (encode 32 finalizeRole ++ encode 32 rolesSlot)).val
  (keccak (encode 32 account.val ++ encode 32 roleBase)).val

def hexDigit (n : Nat) : Char := Char.ofNat (if n < 10 then 48 + n else 87 + n)
def hexFixed (size n : Nat) : String :=
  "0x" ++ String.ofList ((encode size n).flatMap fun b => [hexDigit (b.toNat / 16), hexDigit (b.toNat % 16)])

def missingRole (account : Address) : Fault :=
  .reason ("AccessControl: account " ++ hexFixed 20 account.val ++ " is missing role " ++ hexFixed 32 finalizeRole)

def add (a b : Nat) : Exec Nat := do
  require (a + b < Verity.Core.UINT256_MODULUS) (.bubbled (Queue.panicBytes 0x11))
  pure (a + b)

def sub (a b : Nat) : Exec Nat := do
  require (b ≤ a) (.bubbled (Queue.panicBytes 0x11))
  pure (a - b)

/-- WithdrawalQueueBase.sol:332-362. Both cumulative fields are saved before
writes. The shares subtraction is deliberately late, as in the event expression. -/
def finalize (keccak : Queue.Keccak) (ctx : Context) (last amount rate : Word) : Exec Unit := do
  let tail ← read ctx Queue.lastSlot
  require (last.val ≤ tail.val) (.bubbled (encode 4 0xc969e0f2 ++ encode 32 last.val))
  let finalized ← read ctx Queue.finalizedSlot
  require (finalized.val < last.val) (.bubbled (encode 4 0xc969e0f2 ++ encode 32 last.val))
  let oldRow ← read ctx (Queue.requestSlot keccak finalized.val)
  let newRow ← read ctx (Queue.requestSlot keccak last.val)
  let stETH ← sub (newRow.val % width) (oldRow.val % width)
  require (amount.val ≤ stETH) (.bubbled (encode 4 0x252dfe81 ++ encode 32 amount.val ++ encode 32 stETH))
  let first ← add finalized.val 1
  let index ← read ctx checkpointIndexSlot
  let next ← add index.val 1
  let slot := checkpointSlot keccak next
  write ctx slot (word first)
  write ctx (word (slot + 1)).val rate
  write ctx checkpointIndexSlot (word next)
  let locked ← read ctx lockedSlot
  let updated ← add locked.val amount.val
  write ctx lockedSlot (word updated)
  write ctx Queue.finalizedSlot last
  let shares ← sub (newRow.val / width) (oldRow.val / width)
  let timestamp ← (fun w => (⟨.ok w.core.blockTimestamp, w, []⟩ : Result Word))
  emit ctx "WithdrawalsFinalized" [word first, last, amount, word shares, timestamp]

/-- WithdrawalQueueERC721.sol:149-159, including inherited pause and physical
AccessControl membership checks. Incoming value is already credited by CALL. -/
def entry (keccak : Queue.Keccak) (ctx : Context) (last amount rate : Word) : Exec Unit := do
  let resume ← read ctx resumeSlot
  let timestamp ← (fun w => (⟨.ok w.core.blockTimestamp, w, []⟩ : Result Word))
  require (resume.val ≤ timestamp.val) (.bubbled (encode 4 0x14378398))
  let member ← read ctx (memberSlot keccak ctx.sender)
  require (member.val % 256 ≠ 0) (missingRole ctx.sender)
  let finalized ← read ctx Queue.finalizedSlot
  let first ← add finalized.val 1
  finalize keccak ctx last amount rate
  let tail ← read ctx Queue.lastSlot
  emit ctx "BatchMetadataUpdate" [word first, tail]

/-- Payable two-word finalization entry. Short calldata fails before pause or
role admission; extra trailing data is accepted. Other selectors are delegated. -/
def dispatch (keccak : Queue.Keccak) (queue : Address) (other : External) : External := fun req w =>
  if req.target = queue ∧ req.payload.take 4 = encode 4 0xb6013cef then
    if req.payload.length < 68 then .rejected []
    else
      let last := word (decode ((req.payload.drop 4).take 32))
      let rate := word (decode ((req.payload.drop 36).take 32))
      ReplyABI.reply (fun _ => []) (entry keccak ⟨queue, req.caller⟩ last req.value rate) w
  else other req w

end LidoSRv3.Audit.Source.TrioReserve1.QueueFinalize
