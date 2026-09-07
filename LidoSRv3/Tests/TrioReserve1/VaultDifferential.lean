import LidoSRv3.Audit.Source.TrioReserve1.Report
import LidoSRv3.Audit.Source.TrioReserve1.ReportVaults
import Lean

namespace LidoSRv3.Tests.TrioReserve1.VaultDifferential
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
  let self ← number j "self"
  let sender ← number j "sender"
  let locator ← number j "locator"
  let vault ← number j "vault"
  let withdrawalVault ← number j "withdrawalVault"
  let rewardBalance ← number j "rewardBalance"
  let withdrawalBalance ← number j "withdrawalBalance"
  let totalRewards ← number j "totalRewards"
  let queue ← number j "queue"
  if [self,sender,locator,vault,withdrawalVault,queue].any (· ≥ 2^160) then throw "address overflow"
  let active ← number j "active"
  let packed ← number j "packed"
  let reserve ← number j "reserve"
  let target ← number j "target"
  let balance ← number j "balance"
  let queueBalance ← number j "queueBalance"
  let args ← (← j.getObjVal? "args").getArr?
  let vals ← args.toList.mapM fun x => do
    let s ← x.getStr?
    match s.toNat? with
    | some n => if n < 2^256 then pure (word n) else throw "argument overflow"
    | none => throw "invalid argument"
  let input ← match vals with
    | [a,b,c,d,e,f,g,h] => pure (Report.Inputs.mk a b c d e f g h)
    | _ => throw "report needs eight arguments"
  let rows ← (← j.getObjVal? "replies").getArr?
  let replies ← rows.toList.mapM fun row => do
    let target ← number row "target"
    let payload ← rawBytes (← row.getObjVal? "payload")
    let data ← rawBytes (← row.getObjVal? "data")
    let reject ← row.getObjValAs? Bool "reject"
    pure (target, payload, data, reject)
  let ctx : Context := ⟨Verity.Core.Address.ofNat self, Verity.Core.Address.ofNat sender⟩
  let core := {Verity.defaultState with codeSize := fun a =>
    if a = self ∨ a = locator ∨ a = vault ∨ a = withdrawalVault ∨ a = queue then word 1 else word 0}
  let core := core.writeContractSlot self activeSlot (word active)
  let core := core.writeContractSlot self locatorSlot (word locator)
  let core := core.writeContractSlot self bufferSlot (word packed)
  let core := core.writeContractSlot self reserveSlot (word reserve)
  let core := core.writeContractSlot self targetSlot (word target)
  let core := core.writeContractSlot self VaultCallbacks.totalRewardsSlot (word totalRewards)
  let boundary : External := fun req w =>
    match replies.find? (fun (a,p,_,_) => a = req.target.val && p == req.payload) with
    | none => .rejected [255]
    | some (_,_,data,reject) => if reject then .rejected data else .success data w
  let addr := Verity.Core.Address.ofNat
  let external := ReportVaults.external boundary (addr self) (addr vault) (addr withdrawalVault)
  let before : World := ⟨core, fun a => if a.val = self then balance else if a.val = queue then queueBalance else if a.val = vault then rewardBalance else if a.val = withdrawalVault then withdrawalBalance else 0, []⟩
  let r := run (Report.collect external ctx input) before
  let returned := match r.outcome with
    | .ok _ => []
    | .error f => (ReplyABI.fault f).map UInt8.toNat
  let success := match r.outcome with | .ok _ => true | .error _ => false
  pure <| Json.mkObj [
    ("name", ← j.getObjVal? "name"), ("success", .bool success), ("returned", toJson returned),
    ("packed", .str (toString (r.world.core.readContractSlot self bufferSlot).val)),
    ("reserve", .str (toString (r.world.core.readContractSlot self reserveSlot).val)),
    ("target", .str (toString (r.world.core.readContractSlot self targetSlot).val)),
    ("balance", .str (toString (r.world.balances ctx.self))),
    ("queueBalance", .str (toString (r.world.balances (Verity.Core.Address.ofNat queue)))),
    ("rewardBalance", .str (toString (r.world.balances (addr vault)))),
    ("withdrawalBalance", .str (toString (r.world.balances (addr withdrawalVault)))),
    ("totalRewards", .str (toString (r.world.core.readContractSlot self VaultCallbacks.totalRewardsSlot).val)),
    ("calls", toJson ((ReplyABI.nested r.attempts).map fun a => Json.mkObj [
      ("depth", toJson a.depth), ("target", .str (toString a.request.target.val)), ("value", .str (toString a.request.value.val)),
      ("payload", toJson (a.request.payload.map UInt8.toNat)), ("accepted", .bool a.accepted),
      ("returned", toJson (a.returned.map UInt8.toNat))])),
    ("logs", toJson (r.world.logs.map fun l => (l.name, l.values.map fun v => toString v.val)))]

end LidoSRv3.Tests.TrioReserve1.VaultDifferential

def main (args : List String) : IO UInt32 := do
  match args with
  | [input, output] =>
    let raw ← IO.FS.readFile input
    match Lean.Json.parse raw >>= fun j => j.getArr? >>= fun rows =>
        rows.mapM LidoSRv3.Tests.TrioReserve1.VaultDifferential.execute with
    | .error e => IO.eprintln e; pure 1
    | .ok rows => IO.FS.writeFile output (Lean.Json.arr rows |>.pretty); pure 0
  | _ => IO.eprintln "usage: VaultDifferential.lean INPUT OUTPUT"; pure 2
