import Verity.Core

/-!
Executable source-shaped Lido 0.4.24 reserve path at
17005714f151e5502c559932319a3f2f74ac2436. Uses the pinned Verity storage lenses
and words. Whole-world balances/logs are explicit contract state; attempted
calls are separate observations. External CALLs accept arbitrary return bytes,
rejection and successful world changes, including callback effects.

This is an executable under an explicit external interpreter, NOT yet a
correspondence theorem or a claim that arbitrary callees preserve invariants.
Function boundaries and local values survive across effectful calls. Physical
slots are the literals in Lido.sol:120-176 and Pausable.sol:15-16.
-/
namespace LidoSRv3.Audit.Source.TrioReserve1.Live

abbrev Word := Verity.Core.Uint256
abbrev Address := Verity.Core.Address
abbrev Bytes := List UInt8

def word (n : Nat) : Word := Verity.Core.Uint256.ofNat n

def width : Nat := 2 ^ 128

def locatorSlot : Nat := 0xd92bc31601d11a10411d08f59b7146d8a5915af253cde25f8e66b67beb4be223
def bufferSlot : Nat := 0x81a11fa1111afa59b50051f60ccf604a39d96acb484dc467ad8eadb4a63f0a5f
def nextSlot : Nat := 0x8d3ed945c7718edcdb639b1235f2bbe3fa81f4a6cec7a436d8ea13fbc502d957
def seedSlot : Nat := 0x3f0eaa2c0f16ff9775c078f3df30470d8c042317b24ad1defa240b1c3e10b238
def reserveSlot : Nat := 0xda4fbe3b9cbd98dfae5dff538bbff4ba61f38979d4d7419bcd006f3e6250ec13
def targetSlot : Nat := 0x3d3e9bd6e90e5d1f1c6839835bcbe5746a47c9a013d1eae6e80c248264c06a81
def activeSlot : Nat := 0x644132c4ddd5bb6f0655d5fe2870dcec7870e6be4758890f366b83441f9fdece

structure Log where
  emitter : Address
  name : String
  values : List Word
  deriving Repr

/-- Physical storage uses Verity's contract-indexed word lenses. Account balances
and address-qualified event logs are additional source-visible world components,
not instrumentation stored in synthetic EVM slots. Other `core` fields are not
used as hidden call counters, authorization flags, queue caches or failure hooks. -/
structure World where
  core : Verity.ContractState
  balances : Address → Nat
  logs : List Log := []

structure Context where
  self : Address
  sender : Address

structure Request where
  caller : Address
  target : Address
  value : Word
  payload : Bytes
  deriving DecidableEq, Repr

/-- A nested observation is outside EVM storage and committed events. Depth is
relative to the direct Lido call (its callee's call has depth 1). -/
structure NestedAttempt where
  request : Request
  isStatic : Bool
  accepted : Bool
  returned : Bytes
  depth : Nat := 1
  deriving DecidableEq, Repr

inductive Reply where
  | success (data : Bytes) (world : World)
  | rejected (data : Bytes)
  | successWithTrace (data : Bytes) (world : World) (nested : List NestedAttempt)
  | rejectedWithTrace (data : Bytes) (nested : List NestedAttempt)

/-- The callee receives the world AFTER the CALL's value transfer. Rejection
rolls that transfer and all callee effects back. No successful-call premise. -/
abbrev External := Request → World → Reply

inductive Fault where
  | empty
  | reason (text : String)
  | bubbled (data : Bytes)
  deriving DecidableEq, Repr

structure Attempt where
  request : Request
  accepted : Bool
  returned : Bytes
  nested : List NestedAttempt := []
  deriving DecidableEq, Repr

structure Result (α : Type) where
  outcome : Except Fault α
  world : World
  attempts : List Attempt := []

abbrev Exec (α : Type) := World → Result α

def pureExec (value : α) : Exec α := fun w => ⟨.ok value, w, []⟩
def bindExec (first : Exec α) (next : α → Exec β) : Exec β := fun w =>
  let r := first w
  match r.outcome with
  | .error e => ⟨.error e, r.world, r.attempts⟩
  | .ok a =>
      let s := next a r.world
      ⟨s.outcome, s.world, r.attempts ++ s.attempts⟩

instance : Monad Exec where
  pure := pureExec
  bind := bindExec

/-- Root transaction rollback restores every physical account slot, balance and
committed event; attempted calls remain separately observable to the audit. -/
def run (program : Exec α) (before : World) : Result α :=
  let r := program before
  match r.outcome with
  | .ok _ => r
  | .error e => ⟨.error e, before, r.attempts⟩

def fail (fault : Fault) : Exec α := fun w => ⟨.error fault, w, []⟩
def require (condition : Bool) (fault : Fault) : Exec Unit :=
  if condition then pure () else fail fault

def read (ctx : Context) (slot : Nat) : Exec Word := fun w =>
  ⟨.ok (w.core.readContractSlot ctx.self.val slot), w, []⟩
def write (ctx : Context) (slot : Nat) (value : Word) : Exec Unit := fun w =>
  ⟨.ok (), {w with core := w.core.writeContractSlot ctx.self.val slot value}, []⟩
def emit (ctx : Context) (name : String) (values : List Word) : Exec Unit := fun w =>
  ⟨.ok (), {w with logs := w.logs ++ [⟨ctx.self, name, values⟩]}, []⟩

def encode (size n : Nat) : Bytes :=
  (List.range size).map fun i => UInt8.ofNat (n / 256 ^ (size - 1 - i) % 256)
def decode (data : Bytes) : Nat := data.foldl (fun n b => n * 256 + b.toNat) 0

def decodeWord (data : Bytes) (offset : Nat := 0) : Exec Word := do
  require (offset + 32 ≤ data.length) .empty
  pure (word (decode ((data.drop offset).take 32)))

def transfer (w : World) (sender recipient : Address) (value : Nat) : World :=
  let debited := fun a => if a = sender then w.balances a - value else w.balances a
  {w with balances := fun a => if a = recipient then debited a + value else debited a}

/-- Solidity high-level CALL checks target code before issuing the call. An
insufficient balance still yields a failed CALL attempt. Callee failure bubbles
its bytes; malformed successful return data fails in the caller's decoder. -/
def call (external : External) (ctx : Context) (target : Address)
    (selector : Nat) (value : Word := word 0) : Exec Bytes := fun w =>
  let req : Request := ⟨ctx.self, target, value, encode 4 selector⟩
  if (w.core.codeSize target.val).val = 0 then ⟨.error .empty, w, []⟩
  else if w.balances ctx.self < value.val then
    ⟨.error (.bubbled []), w, [⟨req, false, [], []⟩]⟩
  else
    match external req (transfer w ctx.self target value.val) with
    | .rejected data => ⟨.error (.bubbled data), w, [⟨req, false, data, []⟩]⟩
    | .success data after => ⟨.ok data, after, [⟨req, true, data, []⟩]⟩
    | .successWithTrace data after nested => ⟨.ok data, after, [⟨req, true, data, nested⟩]⟩
    | .rejectedWithTrace data nested => ⟨.error (.bubbled data), w, [⟨req, false, data, nested⟩]⟩

/-- Lido.sol:1557-1558: locator occupies low 160 bits of its physical word. -/
def getLidoLocator (ctx : Context) : Exec Address := do
  let packed ← read ctx locatorSlot
  pure (Verity.Core.Address.ofNat packed.val)

def locatorAddress (external : External) (ctx : Context) (selector : Nat) : Exec Address := do
  let locator ← getLidoLocator ctx
  let data ← call external ctx locator selector
  let value ← decodeWord data
  pure (Verity.Core.Address.ofNat value.val)

/-- Lido.sol:1398-1400, 1406-1408. These getters execute separate locator calls. -/
def stakingRouter (external : External) (ctx : Context) : Exec Address :=
  locatorAddress external ctx 0xef6c064c

def withdrawalQueue (external : External) (ctx : Context) : Exec Address :=
  locatorAddress external ctx 0x37d5fe99

/-- Lido.sol:815-816: bunker read precedes the short-circuited local pause read. -/
def canDeposit (external : External) (ctx : Context) : Exec Bool := do
  let queue ← withdrawalQueue external ctx
  let data ← call external ctx queue 0x2b95b781
  let bunker ← decodeWord data
  if bunker.val ≠ 0 then pure false
  else
    let active ← read ctx activeSlot
    pure (active.val ≠ 0)

structure Allocation where
  total : Nat
  deposits : Nat
  withdrawals : Nat
  unreserved : Nat
  deriving DecidableEq, Repr

/-- Lido.sol:605-616: do not re-read total or deposit reserve after the live
queue call, even if the external call mutates their physical storage. -/
def getBufferedEtherAllocation (external : External) (ctx : Context) : Exec Allocation := do
  let packed ← read ctx bufferSlot
  let total := packed.val % width
  let reserve ← read ctx reserveSlot
  let deposits := min total reserve.val
  let remaining := total - deposits
  let queue ← withdrawalQueue external ctx
  let data ← call external ctx queue 0xd0fb84e8
  let demand ← decodeWord data
  let withdrawals := min remaining demand.val
  pure ⟨total, deposits, withdrawals, remaining - withdrawals⟩

/-- Lido.sol:831-833 raw 0.4.24 addition. -/
def getDepositableEther (a : Allocation) : Word := word (a.deposits + a.unreserved)

/-- UnstructuredStorageExt.sol:44-46 numeric interpretation of word packing.
There is intentionally no uint128 bound guard. PhysicalPacking proves the
bitwise mask/shift/OR correspondence separately. -/
def pack (low high : Nat) : Word := word (low % width + width * (high % width))

def checkedAdd (a b : Nat) : Exec Nat := do
  require (a + b < Verity.Core.UINT256_MODULUS) (.reason "MATH_ADD_OVERFLOW")
  pure (a + b)

def checkedSub (a b : Nat) : Exec Nat := do
  require (b ≤ a) (.reason "MATH_SUB_UNDERFLOW")
  pure (a - b)

/-- Lido.sol:807-809 via _accountingOracle().getCurrentFrame(). -/
def getCurrentFrame (external : External) (ctx : Context) : Exec (Nat × Nat) := do
  let oracle ← locatorAddress external ctx 0x5a2031f9
  let data ← call external ctx oracle 0x72f79b13
  -- Solidity tuple decoder rejects fewer than 64 bytes before returning either field.
  require (64 ≤ data.length) .empty
  let nonce ← decodeWord data
  let timestamp ← decodeWord data 32
  pure (nonce.val, timestamp.val)

/-- Lido.sol:795-804: saved pair read before the current-frame external call. -/
def getDepositedNextReportAdjusted (external : External) (ctx : Context) : Exec (Nat × Nat) := do
  let packed ← read ctx nextSlot
  let next := packed.val % width
  let lastNonce := packed.val / width
  let (nonce, _) ← getCurrentFrame external ctx
  pure (if nonce ≠ lastNonce then 0 else next, nonce)

def setDepositsReserve (ctx : Context) (reserve : Nat) : Exec Unit := do
  write ctx reserveSlot (word reserve)
  emit ctx "DepositsReserveSet" [word reserve]

/-- Lido.sol:839-859, preserving effects before the frame call. -/
def spendDepositableEther (external : External) (ctx : Context) (amount : Word) : Exec Unit := do
  let allocation ← getBufferedEtherAllocation external ctx
  require (amount.val ≤ (getDepositableEther allocation).val) (.reason "NOT_ENOUGH_ETHER")
  let current ← read ctx bufferSlot
  let post ← checkedAdd (current.val / width) amount.val
  let buffer ← checkedSub allocation.total amount.val
  write ctx bufferSlot (pack buffer post)
  emit ctx "DepositedPostReportUpdated" [word post]
  emit ctx "Unbuffered" [amount]
  let (next, nonce) ← getDepositedNextReportAdjusted external ctx
  let updatedNext ← checkedAdd next amount.val
  write ctx nextSlot (pack updatedNext nonce)
  let reserve ← read ctx reserveSlot
  if reserve.val > 0 then
    setDepositsReserve ctx (if reserve.val > amount.val then reserve.val - amount.val else 0)

/-- Lido.sol:869-886: admission derives from caller, packed locator, locator CALL
and live bunker/local pause state; router address is retained across spending. -/
def withdrawDepositableEther (external : External) (ctx : Context)
    (amount seeds : Word) : Exec Unit := do
  let allowed ← canDeposit external ctx
  require allowed (.reason "CAN_NOT_DEPOSIT")
  let router ← stakingRouter external ctx
  require (ctx.sender = router) (.reason "APP_AUTH_FAILED")
  require (amount.val ≠ 0) (.reason "ZERO_AMOUNT")
  spendDepositableEther external ctx amount
  if seeds.val > 0 then
    let packed ← read ctx seedSlot
    let count ← checkedAdd (packed.val % width) seeds.val
    write ctx seedSlot (pack count (packed.val / width))
    emit ctx "DepositedValidatorsChanged" [word count]
  let _ ← call external ctx router 0x13ae8460 amount
  pure ()

/-- Internal writer only, Lido.sol:670-680. External ACL admission remains open. -/
def setDepositsReserveTarget (ctx : Context) (target : Word) : Exec Unit := do
  write ctx targetSlot target
  emit ctx "DepositsReserveTargetSet" [target]
  let reserve ← read ctx reserveSlot
  if target.val < reserve.val then setDepositsReserve ctx target.val

/-- Internal report rebalance only, Lido.sol:1125-1132. Report parent remains open. -/
def updateBufferedEtherAllocation (ctx : Context) : Exec Unit := do
  let target ← read ctx targetSlot
  let reserve ← read ctx reserveSlot
  if reserve.val < target.val then setDepositsReserve ctx target.val

end LidoSRv3.Audit.Source.TrioReserve1.Live
