import LidoSRv3.Audit.Source.TrioReserve1.ACL
import Lean

namespace LidoSRv3.Tests.TrioReserve1.ACLDifferential
open Lean LidoSRv3.Audit.Source.TrioReserve1 Live

def number (j : Json) (key : String) : Except String Nat := do
  let s ← j.getObjValAs? String key
  match s.toNat? with
  | some n => if n < 2^256 then pure n else throw "word overflow"
  | none => throw "invalid decimal"

def callJson (r : Request) (accepted : Bool) (returned : Bytes) (depth : Nat) (isStatic : Bool) : Json :=
  Json.mkObj [("target", .str (toString r.target.val)), ("value", .str (toString r.value.val)),
    ("payload", toJson (r.payload.map UInt8.toNat)), ("accepted", .bool accepted),
    ("returned", toJson (returned.map UInt8.toNat)), ("depth", toJson depth), ("isStatic", .bool isStatic)]

def execute (j : Json) : Except String Json := do
  let self ← number j "self"
  let sender ← number j "sender"
  let kernel ← number j "kernel"
  if self ≥ 2^160 ∨ sender ≥ 2^160 ∨ kernel ≥ 2^160 then throw "address overflow"
  let ctx : Context := ⟨Verity.Core.Address.ofNat self, Verity.Core.Address.ofNat sender⟩
  let initialization ← number j "initialization"
  let blockNumber ← number j "blockNumber"
  let code ← number j "code"
  let reserve ← number j "reserve"
  let target ← number j "target"
  let requested ← number j "requested"
  let raw ← (← j.getObjVal? "reply").getArr?
  let reply ← raw.toList.mapM fun x => do
    let n ← x.getNat?
    if n < 256 then pure (UInt8.ofNat n) else throw "invalid byte"
  let reject ← j.getObjValAs? Bool "reject"
  let core := { Verity.defaultState with
    blockNumber := word blockNumber
    codeSize := fun a => if a = kernel then word code else word 0 }
  let core := core.writeContractSlot self Aragon.initializationSlot (word initialization)
  let core := core.writeContractSlot self Aragon.kernelSlot (word kernel)
  let core := core.writeContractSlot self reserveSlot (word reserve)
  let core := core.writeContractSlot self targetSlot (word target)
  let acl ← number j "acl"
  let aclCode ← number j "aclCode"
  let middle ← number j "middle"
  let aclCell ← number j "aclCell"
  if acl ≥ 2^160 then throw "ACL address overflow"
  let hashes ← (← (← j.getObjVal? "hashes").getArr?).toList.mapM fun row => do
    let raw ← (← row.getObjVal? "input").getArr?
    let input ← raw.toList.mapM fun x => do
      let n ← x.getNat?
      if n < 256 then pure (UInt8.ofNat n) else throw "invalid hash byte"
    pure (input, word (← number row "output"))
  let k : Queue.Keccak := fun data => ((hashes.find? (fun x => x.1 = data)).map (·.2)).getD (word 0)
  if (k (encode 32 Kernel.appNamespace ++ encode 32 0)).val != middle ∨
      Kernel.aclSlot k != aclCell then throw "missing kernel hash preimage"
  let cells ← (← (← j.getObjVal? "storage").getArr?).toList.mapM fun row => do
    pure (← number row "slot", word (← number row "value"))
  let core := core.writeContractSlot kernel (Kernel.aclSlot k) (word acl)
  let core := cells.foldl (fun c row => c.writeContractSlot acl row.1 row.2) core
  let timestamp ← number j "timestamp"
  let core := {core with
    codeSize := fun a => if a = kernel then word code else if a = acl then word aclCode else word 0
    blockTimestamp := word timestamp}
  let mode ← j.getObjValAs? String "oracleMode"
  let oracleTarget ← number j "oracleTarget"
  let staticExternal : StaticCall.External := fun req _ =>
    if req.target.val != oracleTarget then .rejected []
    else if mode = "write" then .forbiddenStateChange
    else if mode = "no-code" then .success []
    else if reject then .rejected reply else .success reply
  let selfACL := Verity.Core.Address.ofNat acl
  let w : World := ⟨core, fun _ => 0, []⟩
  match (ACL.hasPermission k staticExternal selfACL ctx Aragon.bufferReserveManagerRole [] w 64).outcome with
  | .error .exhausted => throw "ACL recursion bound exhausted"
  | _ => pure ()
  let aclExternal := ACL.dispatch k staticExternal selfACL ctx Aragon.bufferReserveManagerRole 64
    (fun _ _ => .rejected []) (fun _ _ => .rejected [])
  let external := Kernel.dispatch k (Verity.Core.Address.ofNat kernel) ctx
    Aragon.bufferReserveManagerRole aclExternal (fun _ _ => .rejected [])
  let r := run (Aragon.setTarget external ctx (word requested)) ⟨core, fun _ => 0, []⟩
  let fault := match r.outcome with
    | .ok _ => "ok"
    | .error .empty => "empty"
    | .error (.reason s) => s
    | .error (.bubbled data) => if data.isEmpty then "empty" else "bubbled"
  pure <| Json.mkObj [
    ("name", ← j.getObjVal? "name"), ("fault", .str fault),
    ("reserve", .str (toString (r.world.core.readContractSlot self reserveSlot).val)),
    ("target", .str (toString (r.world.core.readContractSlot self targetSlot).val)),
    ("calls", .arr (r.attempts.flatMap fun a => callJson a.request a.accepted a.returned 0 false ::
      a.nested.map fun n => callJson n.request n.accepted n.returned n.depth n.isStatic).toArray),
    ("logs", toJson (r.world.logs.map fun l => (l.name, l.values.map fun v => toString v.val)))]

end LidoSRv3.Tests.TrioReserve1.ACLDifferential

def main (args : List String) : IO UInt32 := do
  match args with
  | [input, output] =>
    let raw ← IO.FS.readFile input
    match Lean.Json.parse raw >>= fun j => j.getArr? >>= fun rows =>
        rows.mapM LidoSRv3.Tests.TrioReserve1.ACLDifferential.execute with
    | .error e => IO.eprintln e; pure 1
    | .ok rows => IO.FS.writeFile output (Lean.Json.arr rows |>.pretty); pure 0
  | _ => IO.eprintln "usage: ACLDifferential.lean INPUT OUTPUT"; pure 2
