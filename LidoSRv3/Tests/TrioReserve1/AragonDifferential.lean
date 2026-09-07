import LidoSRv3.Audit.Source.TrioReserve1.Aragon
import Lean

namespace LidoSRv3.Tests.TrioReserve1.AragonDifferential
open Lean LidoSRv3.Audit.Source.TrioReserve1 Live

def number (j : Json) (key : String) : Except String Nat := do
  let s ← j.getObjValAs? String key
  match s.toNat? with
  | some n => if n < 2^256 then pure n else throw "word overflow"
  | none => throw "invalid decimal"

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
  let external : External := fun _ w => if reject then .rejected reply else .success reply w
  let r := run (Aragon.setTarget external ctx (word requested)) ⟨core, fun _ => 0, []⟩
  let fault := match r.outcome with
    | .ok _ => "ok"
    | .error .empty => "empty"
    | .error (.reason s) => s
    | .error (.bubbled _) => "bubbled"
  pure <| Json.mkObj [
    ("name", ← j.getObjVal? "name"), ("fault", .str fault),
    ("reserve", .str (toString (r.world.core.readContractSlot self reserveSlot).val)),
    ("target", .str (toString (r.world.core.readContractSlot self targetSlot).val)),
    ("calls", toJson (r.attempts.map fun a => a.request.payload.map UInt8.toNat)),
    ("logs", toJson (r.world.logs.map fun l => (l.name, l.values.map fun v => toString v.val)))]

end LidoSRv3.Tests.TrioReserve1.AragonDifferential

def main (args : List String) : IO UInt32 := do
  match args with
  | [input, output] =>
    let raw ← IO.FS.readFile input
    match Lean.Json.parse raw >>= fun j => j.getArr? >>= fun rows =>
        rows.mapM LidoSRv3.Tests.TrioReserve1.AragonDifferential.execute with
    | .error e => IO.eprintln e; pure 1
    | .ok rows => IO.FS.writeFile output (Lean.Json.arr rows |>.pretty); pure 0
  | _ => IO.eprintln "usage: AragonDifferential.lean INPUT OUTPUT"; pure 2
