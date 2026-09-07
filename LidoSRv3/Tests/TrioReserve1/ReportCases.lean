import LidoSRv3.Audit.Source.TrioReserve1.Report

namespace LidoSRv3.Tests.TrioReserve1.ReportCases
open LidoSRv3.Audit.Source.TrioReserve1 Live

def address := Verity.Core.Address.ofNat
def ctx : Context := ⟨address 1, address 2⟩
def input : Report.Inputs := ⟨word 11, word 12, word 13, word 30, word 20, word 14, word 15, word 40⟩
def before : World :=
  let core := {Verity.defaultState with codeSize := fun _ => word 1}
  let core := core.writeContractSlot 1 activeSlot (word 1)
  let core := core.writeContractSlot 1 locatorSlot (word 3)
  let core := core.writeContractSlot 1 bufferSlot (pack 100 7)
  let core := core.writeContractSlot 1 reserveSlot (word 20)
  let core := core.writeContractSlot 1 targetSlot (word 50)
  ⟨core, fun a => if a = address 1 then 1000 else 0, []⟩

/-- Adversarial source-interpreter fixture: authorization changes the locator
slot; later vault replies change packed buffer data. This is not EVM evidence. -/
def replies : External := fun req w =>
  if req.target = address 3 then
    if req.payload = encode 4 0x9624e83e then
      .success (encode 32 2) {w with core := w.core.writeContractSlot 1 locatorSlot (word 99)}
    else if req.payload = encode 4 0xe441d25f then .success (encode 32 4) w
    else if req.payload = encode 4 0x69d42148 then .success (encode 32 5) w
    else if req.payload = encode 4 0x37d5fe99 then .success (encode 32 6) w
    else .rejected [255]
  else if req.target = address 4 ∧ req.payload = encode 4 0x9342c8f4 ++ encode 32 20 then
    .success [] {w with core := w.core.writeContractSlot 1 bufferSlot (pack 500 8)}
  else if req.target = address 5 ∧ req.payload = encode 4 0x3194528a ++ encode 32 30 then
    .success [] {w with core := w.core.writeContractSlot 1 bufferSlot (pack 700 9)}
  else if req.target = address 6 ∧ req.payload = encode 4 0xb6013cef ++ encode 32 14 ++ encode 32 15 then
    if req.value = word 40 then .success [] w else .rejected [254]
  else .rejected [253]

def succeeded (r : Result Unit) : Bool := match r.outcome with
  | .ok _ => true
  | .error _ => false

def failed (r : Result Unit) (fault : Fault) : Bool := match r.outcome with
  | .ok _ => false
  | .error e => decide (e = fault)

def good : Bool :=
  let r := run (Report.collect replies ctx input) before
  succeeded r &&
  (r.world.core.readContractSlot 1 bufferSlot).val == (pack 710 9).val &&
  (r.world.core.readContractSlot 1 reserveSlot).val == 50 &&
  (r.world.core.readContractSlot 1 locatorSlot).val == 99 &&
  r.attempts.map (fun a => a.request.target.val) == [3, 3, 4, 3, 5, 3, 6] &&
  r.world.balances (address 1) == 960 && r.world.balances (address 6) == 40 &&
  r.world.logs.map (fun l => (l.name, l.values.map (·.val))) ==
    [("DepositsReserveSet", [50]), ("ETHDistributed", [11, 13, 12, 30, 20, 710])]

def rejected : Bool :=
  let ext : External := fun req w => if req.target = address 6 then .rejected [42] else replies req w
  let r := run (Report.collect ext ctx input) before
  failed r (.bubbled [42]) && r.attempts.length == 7 &&
  (r.world.core.readContractSlot 1 bufferSlot).val == (pack 100 7).val &&
  (r.world.core.readContractSlot 1 locatorSlot).val == 3 &&
  r.world.balances (address 1) == 1000 && r.world.balances (address 6) == 0 && r.world.logs.isEmpty

def skipped : Bool :=
  let args := {input with rewards := word 0, withdrawals := word 0, lockAmount := word 0}
  let r := run (Report.collect replies ctx args) before
  succeeded r && r.attempts.length == 1 &&
  (r.world.core.readContractSlot 1 bufferSlot).val == (pack 100 7).val

def overflow : Bool :=
  let args := {input with rewards := word (2^256 - 1)}
  let r := run (Report.afterCalls ctx args) before
  failed r (.reason "MATH_ADD_OVERFLOW") &&
  (r.world.core.readContractSlot 1 bufferSlot).val == (pack 100 7).val && r.world.logs.isEmpty

def unauthorized : Bool :=
  let r := run (Report.collect replies {ctx with sender := address 9} input) before
  failed r (.reason "APP_AUTH_FAILED") && r.attempts.length == 1 &&
    (r.world.core.readContractSlot 1 locatorSlot).val == 3 && r.world.logs.isEmpty

def malformed : Bool :=
  let r := run (Report.collect (fun _ w => .success [] w) ctx input) before
  failed r .empty && r.attempts.length == 1 && r.world.logs.isEmpty

def underflow : Bool :=
  let args := {input with lockAmount := word 151}
  let r := run (Report.afterCalls ctx args) before
  failed r (.reason "MATH_SUB_UNDERFLOW") &&
    (r.world.core.readContractSlot 1 bufferSlot).val == (pack 100 7).val && r.world.logs.isEmpty

#eval (show IO Unit from do
  let checks := [("saved-locator/post-call-buffer/ABI/order", good), ("queue-rejection-rollback", rejected),
    ("zero-amount-call-skipping", skipped), ("checked-overflow-before-write", overflow),
    ("authorization-before-vaults", unauthorized), ("malformed-accounting-getter", malformed),
    ("checked-underflow-before-write", underflow)]
  for (name, ok) in checks do
    if !ok then throw (IO.userError ("report case failed: " ++ name))
    IO.println ("PASS " ++ name))

end LidoSRv3.Tests.TrioReserve1.ReportCases
