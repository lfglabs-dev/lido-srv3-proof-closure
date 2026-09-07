import LidoSRv3.Audit.Source.TrioReserve1.Queue
import LidoSRv3.Audit.Source.TrioReserve1.Router
import LidoSRv3.Audit.Source.TrioReserve1.Locator
import Lean

/-!
JSON driver for matching-input Solidity/Verity-word execution. This is testing
infrastructure. Fixture replies and finite keccak preimages are input data, not
production callee assumptions or successful-call hypotheses in any theorem.
-/
namespace LidoSRv3.Tests.TrioReserve1.Differential
open Lean
open LidoSRv3.Audit.Source.TrioReserve1
open Live

private def field (j : Json) (key : String) : Except String Json := j.getObjVal? key
private def string (j : Json) : Except String String := j.getStr?
private def nat (j : Json) : Except String Nat := do
  let text ← string j
  match text.toNat? with
  | some n => pure n
  | none => throw s!"invalid decimal natural: {text}"
private def number (j : Json) (key : String) : Except String Nat := field j key >>= nat
private def list (j : Json) : Except String (List Json) := do pure (← j.getArr?).toList
private def bytes (j : Json) : Except String Bytes := do
  (← list j).mapM fun b => do
    let n ← b.getNat?
    if n < 256 then pure (UInt8.ofNat n) else throw "invalid byte"
private def address (j : Json) (key : String) : Except String Address := do
  let n ← number j key
  if n < 2^160 then pure (Verity.Core.Address.ofNat n) else throw "invalid address"

structure Cell where
  account : Address
  slot : Nat
  value : Word
private def cell (j : Json) : Except String Cell := do
  let value ← number j "value"
  if value ≥ 2^256 then throw "invalid word"
  pure ⟨← address j "account", ← number j "slot", word value⟩

structure Fixture where
  target : Address
  payload : Bytes
  returned : Bytes
  reject : Bool
private def fixture (j : Json) : Except String Fixture := do
  pure ⟨← address j "target", ← bytes (← field j "payload"),
    ← bytes (← field j "returned"), ← (← field j "reject").getBool?⟩

private def jnat (n : Nat) : Json := .str (toString n)
private def jbytes (b : Bytes) : Json := toJson (b.map UInt8.toNat)
private def requestJson (r : Attempt) : Json := Json.mkObj [
  ("target", jnat r.request.target.val), ("value", jnat r.request.value.val),
  ("payload", jbytes r.request.payload)]
private def logJson (r : Log) : Json := Json.mkObj [
  ("emitter", jnat r.emitter.val), ("name", .str r.name),
  ("values", .arr (r.values.map (jnat ∘ (·.val))).toArray)]
private def faultJson : Fault → Json
  | .empty => Json.mkObj [("kind", .str "empty")]
  | .reason text => Json.mkObj [("kind", .str "reason"), ("reason", .str text)]
  | .bubbled data => Json.mkObj [("kind", .str "bubbled"), ("data", jbytes data)]

private def execute (j : Json) : Except String Json := do
  let ctx : Context := ⟨← address j "self", ← address j "sender"⟩
  let queue ← address j "queue"
  let cells ← (← list (← field j "storage")).mapM cell
  let funds ← (← list (← field j "balances")).mapM fun v => do
    let amount ← number v "value"
    if amount ≥ 2^256 then throw "invalid account balance"
    pure (← address v "account", amount)
  let codes ← (← list (← field j "code")).mapM fun v => do
    pure (← address v "account", ← number v "size")
  let fixtures ← (← list (← field j "fixtures")).mapM fixture
  let fixtureTargets ← (← list (← field j "fixtureTargets")).mapM fun v => do
    let n ← nat v
    pure (Verity.Core.Address.ofNat n)
  let sourceRouters ← match j.getObjVal? "sourceRouters" with
    | .error _ => pure []
    | .ok rows => (← list rows).mapM fun v => do
        pure (← address v "router", ← address v "lido")
  let sourceLocators ← match j.getObjVal? "sourceLocators" with
    | .error _ => pure []
    | .ok rows => (← list rows).mapM fun v => do
        let config : Locator.Config := ⟨← address v "queue", ← address v "router", ← address v "oracle"⟩
        pure (← address v "locator", config)
  let hashes ← (← list (← field j "hashes")).mapM fun v => do
    pure (← bytes (← field v "input"), word (← number v "output"))
  let core := cells.foldl (fun s c => s.writeContractSlot c.account.val c.slot c.value)
    Verity.defaultState
  let core := { core with codeSize := fun n => word (((codes.find? (fun x => x.1.val = n)).map (·.2)).getD 0) }
  let before : World := ⟨core, fun a => ((funds.find? (fun x => x.1 = a)).map (·.2)).getD 0, []⟩
  -- Check that the finite hash fixture covers both physical rows actually read.
  let last := Queue.getLastRequestId queue before
  let finalized := Queue.getLastFinalizedRequestId queue before
  for id in [last.val, finalized.val] do
    if !(hashes.any (fun x => x.1 = encode 32 id ++ encode 32 Queue.queueSlot)) then
      throw "missing concrete queue mapping preimage"
  let keccak : Queue.Keccak := fun input =>
    ((hashes.find? (fun x => x.1 = input)).map (·.2)).getD (word 0)
  let fixtureExternal : External := fun req w =>
    match fixtures.find? (fun f => f.target = req.target ∧ f.payload = req.payload) with
    | some f => if f.reject then .rejected f.returned else .success f.returned w
    | none => if fixtureTargets.contains req.target then .success [] w else .rejected []
  let mutation := (j.getObjValAs? String "mutation").toOption.getD "none"
  if !(["none", "cached-demand", "omit-rollback", "receiver-no-auth", "receiver-no-event"].contains mutation) then
    throw "unknown mutation"
  let receiverExternal := sourceRouters.foldr (fun (router, lido) other =>
    Router.dispatch router (if mutation = "receiver-no-auth" then ctx.self else lido) other) fixtureExternal
  let receiverExternal : External := if mutation = "receiver-no-event" then
    fun req w => match receiverExternal req w with
      | .success data after =>
        if sourceRouters.any (fun (router, _) => req.target = router) ∧
            req.payload = encode 4 0x13ae8460 then .success data {after with logs := w.logs}
        else .success data after
      | .rejected data => .rejected data
    else receiverExternal
  let locatorExternal := sourceLocators.foldr (fun (locator, config) other =>
    Locator.dispatch locator config other) receiverExternal
  let external := Queue.dispatch keccak queue locatorExternal
  -- Executed negative control: replace the live queue body by a cached word.
  let external : External := if mutation = "cached-demand" then
    fun req w => if req.payload = encode 4 0xd0fb84e8 then .success (encode 32 50) w
      else external req w
    else external
  let amount ← number j "amount"
  let seeds ← number j "seeds"
  if amount ≥ 2^256 ∨ seeds ≥ 2^256 then throw "invalid calldata word"
  let program := withdrawDepositableEther external ctx (word amount) (word seeds)
  -- Executed negative control: expose intermediate writes after oracle rejection.
  let r := if mutation = "omit-rollback" then program before else run program before
  let result := match r.outcome with
    | .ok _ => Json.mkObj [("success", .bool true)]
    | .error e => Json.mkObj [("success", .bool false), ("fault", faultJson e)]
  pure (Json.mkObj [
    ("name", ← field j "name"), ("result", result),
    ("storage", .arr (cells.map fun c => Json.mkObj [
      ("account", jnat c.account.val), ("slot", jnat c.slot),
      ("value", jnat (r.world.core.readContractSlot c.account.val c.slot).val)]).toArray),
    ("balances", .arr (funds.map fun (a, _) => Json.mkObj [
      ("account", jnat a.val), ("value", jnat (r.world.balances a))]).toArray),
    ("calls", .arr (r.attempts.map requestJson).toArray),
    ("logs", .arr (r.world.logs.map logJson).toArray)])

end LidoSRv3.Tests.TrioReserve1.Differential

/-- No default output, no fallback success: malformed test vectors fail closed. -/
def main (args : List String) : IO UInt32 := do
  match args with
  | [input, output] =>
      let raw ← IO.FS.readFile input
      match Lean.Json.parse raw >>= fun j => j.getArr? >>= fun rows =>
          rows.mapM LidoSRv3.Tests.TrioReserve1.Differential.execute with
      | .error error => IO.eprintln error; pure 1
      | .ok results => IO.FS.writeFile output (Lean.Json.arr results |>.pretty); pure 0
  | _ => IO.eprintln "usage: Differential.lean INPUT.json OUTPUT.json"; pure 2
