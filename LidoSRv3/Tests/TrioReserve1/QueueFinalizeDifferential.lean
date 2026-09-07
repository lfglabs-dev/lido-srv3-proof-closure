import LidoSRv3.Audit.Source.TrioReserve1.QueueFinalize
import LidoSRv3.Audit.Source.TrioReserve1.CallData
import Lean

namespace LidoSRv3.Tests.TrioReserve1.QueueFinalizeDifferential
open Lean LidoSRv3.Audit.Source.TrioReserve1 Live


def number (j : Json) (key : String) : Except String Nat := do
  let s ← j.getObjValAs? String key
  match s.toNat? with
  | some n => if n < 2^256 then pure n else throw "word overflow"
  | none => throw "invalid decimal"

def rawBytes (j : Json) : Except String Bytes := do
  (← j.getArr?).toList.mapM fun x => do
    let n ← x.getNat?
    if n < 256 then pure (UInt8.ofNat n) else throw "invalid byte"

def execute (j : Json) : Except String Json := do
  let queue ← number j "queue"
  let sender ← number j "sender"
  if queue ≥ 2^160 ∨ sender ≥ 2^160 then throw "address overflow"
  let timestamp ← number j "timestamp"
  let balance ← number j "balance"
  let amount ← number j "amount"
  let payload ← rawBytes (← j.getObjVal? "payload")
  let storage ← (← (← j.getObjVal? "storage").getArr?).toList.mapM fun row => do
    pure (← number row "slot", ← number row "value")
  let hashes ← (← (← j.getObjVal? "hashes").getArr?).toList.mapM fun row => do
    pure (← rawBytes (← row.getObjVal? "input"), ← number row "output")
  let get (slot : Nat) := (storage.find? (fun row => row.1 == slot)).map Prod.snd |>.getD 0
  let roleInput := encode 32 QueueFinalize.finalizeRole ++ encode 32 QueueFinalize.rolesSlot
  let roleBase := (hashes.find? (fun row => row.1 == roleInput)).map Prod.snd |>.getD 0
  let required := [roleInput, encode 32 sender ++ encode 32 roleBase,
    encode 32 (get Queue.finalizedSlot) ++ encode 32 Queue.queueSlot,
    encode 32 (decode ((payload.drop 4).take 32)) ++ encode 32 Queue.queueSlot,
    encode 32 (word (get QueueFinalize.checkpointIndexSlot + 1)).val ++ encode 32 QueueFinalize.checkpointsSlot]
  if payload.length ≥ 68 && required.any (fun input => !(hashes.any (fun row => row.1 == input))) then
    throw "missing required mapping preimage"
  let hash : Queue.Keccak := fun data => word ((hashes.find? (fun row => row.1 == data)).map Prod.snd |>.getD 0)
  let addr := Verity.Core.Address.ofNat
  let core := {Verity.defaultState with
    blockTimestamp := word timestamp
    codeSize := fun a => if a = queue then word 1 else word 0}
  let core := storage.foldl (fun core (slot,value) => core.writeContractSlot queue slot (word value)) core
  let before : World := ⟨core, fun a => if a.val = queue then balance else if a.val = sender then 10^18 else 0, []⟩
  let external := QueueFinalize.dispatch hash (addr queue) (fun _ _ => .rejected [255])
  let r := run (CallData.invoke external ⟨addr sender,addr sender⟩ (addr queue) payload (word amount)) before
  let success := match r.outcome with | .ok _ => true | _ => false
  let returned := match r.outcome with | .ok data => data | .error f => ReplyABI.fault f
  pure <| Json.mkObj [
    ("name", ← j.getObjVal? "name"), ("success", .bool success),
    ("returned", toJson (returned.map UInt8.toNat)),
    ("balance", .str (toString (r.world.balances (addr queue)))),
    ("senderValueDebit", .str (toString (before.balances (addr sender) - r.world.balances (addr sender)))),
    ("storage", toJson (storage.map fun (slot,_) =>
      (toString slot,toString (r.world.core.readContractSlot queue slot).val))),
    ("nestedCalls", toJson (r.attempts.flatMap (·.nested) |>.length)),
    ("logs", toJson (r.world.logs.map fun l => (l.name,l.values.map fun v => toString v.val)))]

end LidoSRv3.Tests.TrioReserve1.QueueFinalizeDifferential

def main (args : List String) : IO UInt32 := do
  match args with
  | [input, output] =>
    let raw ← IO.FS.readFile input
    match Lean.Json.parse raw >>= fun j => j.getArr? >>= fun rows =>
        rows.mapM LidoSRv3.Tests.TrioReserve1.QueueFinalizeDifferential.execute with
    | .error e => IO.eprintln e; pure 1
    | .ok rows => IO.FS.writeFile output (Lean.Json.arr rows |>.pretty); pure 0
  | _ => IO.eprintln "usage: QueueFinalizeDifferential.lean INPUT OUTPUT"; pure 2
