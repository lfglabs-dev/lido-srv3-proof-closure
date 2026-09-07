import LidoSRv3.Audit.Source.TrioReserve1.Kernel
import LidoSRv3.Audit.Source.TrioReserve1.StaticCall
import LidoSRv3.Audit.Source.TrioReserve1.ACLSpec

namespace LidoSRv3.Audit.Source.TrioReserve1.ACL
open Live

def emptyParams : Nat := 0x290decd9548b62a8d60345a988386fc84ba6bc95484008f6362f93160ef3e563
def anyEntity : Address := Verity.Core.Address.ofNat (2^160 - 1)

def permissionSlot (k : Queue.Keccak) (who where_ : Address) (role : Word) : Nat :=
  let key := k ([80,69,82,77,73,83,83,73,79,78] ++ encode 20 who.val ++ encode 20 where_.val ++ encode 32 role.val)
  (k (encode 32 key.val ++ encode 32 0)).val

def paramsSlot (k : Queue.Keccak) (hash : Word) : Nat :=
  (k (encode 32 hash.val ++ encode 32 1)).val

structure Param where
  id : Nat
  op : Nat
  value : Nat
  deriving Repr

/-- Stored Param fields are uint8 id, uint8 op, uint240 value, in that order.
This layout differs from the encoded configuration word accepted by _saveParams. -/
def param (k : Queue.Keccak) (self : Address) (hash : Word) (index : Nat) (w : World) : Param :=
  let base := (k (encode 32 (paramsSlot k hash))).val
  let packed := (w.core.readContractSlot self.val (word (base + index)).val).val
  ⟨packed % 256, packed / 256 % 256, packed / 2^16⟩

inductive Halt where
  | exhausted
  | invalidOpcode
  deriving DecidableEq, Repr

structure Result (α : Type) where
  outcome : Except Halt α
  attempts : List NestedAttempt := []

def bindResult (r : Result α) (f : α → Result β) : Result β :=
  match r.outcome with
  | .error e => ⟨.error e, r.attempts⟩
  | .ok a => let s := f a; ⟨s.outcome, r.attempts ++ s.attempts⟩

instance : Monad Result where
  pure a := ⟨.ok a, []⟩
  bind := bindResult

def compare (op a b : Nat) : Bool :=
  if op = 1 then a == b else if op = 2 then a != b
  else if op = 3 then decide (a > b) else if op = 4 then decide (a < b)
  else if op = 5 then decide (a ≥ b) else if op = 6 then decide (a ≤ b) else false

def oraclePayload (who where_ : Address) (role : Word) (how : List Word) : Bytes :=
  encode 4 0x2a151090 ++ encode 32 who.val ++ encode 32 where_.val ++ encode 32 role.val ++
    encode 32 128 ++ encode 32 how.length ++ how.flatMap fun x => encode 32 x.val

/-- ACL uses raw STATICCALL, with no target-code guard. The primitive interpreter
must therefore cover no-code/precompile targets too. Failure or any return size
other than exactly 32 means false; these failures are not bubbled by ACL. -/
def oracle (external : StaticCall.External) (self target who where_ : Address)
    (role : Word) (how : List Word) (w : World) : Result Bool :=
  let req : Request := ⟨self, target, word 0, oraclePayload who where_ role how⟩
  match external req w with
  | .success data => ⟨.ok (data.length == 32 && (word (decode data)).val != 0),
      [⟨req, true, true, data, 1⟩]⟩
  | .rejected data => ⟨.ok false, [⟨req, true, false, data, 1⟩]⟩
  | .forbiddenStateChange => ⟨.ok false, [⟨req, true, false, [], 1⟩]⟩

/-- Source evaluation with an explicit recursion-depth bound. `exhausted` is a
host evaluation limit, NOT a claim about EVM gas or an ACL denial. Correspondence
claims must exclude that result. Parameter cycles in arbitrary storage are allowed. -/
def eval (k : Queue.Keccak) (external : StaticCall.External) (self : Address)
    (hash : Word) (who where_ : Address) (role : Word) (how : List Word) (w : World) :
    Nat → Nat → Result Bool
  | 0, _ => ⟨.error .exhausted, []⟩
  | fuel+1, index => do
    let length := (w.core.readContractSlot self.val (paramsSlot k hash)).val
    if index ≥ length then return false
    let p := param k self hash index w
    if p.id = 204 then
      if p.op > 12 then return ← ⟨.error .invalidOpcode, []⟩
      let first := p.value % 2^32
      let second := p.value / 2^32 % 2^32
      let third := p.value / 2^64 % 2^32
      let r1 ← eval k external self hash who where_ role how w fuel first
      if p.op = 12 then
        return ← eval k external self hash who where_ role how w fuel (if r1 then second else third)
      if p.op = 8 then return !r1
      if r1 && p.op = 10 then return true
      if !r1 && p.op = 9 then return false
      let r2 ← eval k external self hash who where_ role how w fuel second
      return if p.op = 11 then r1 != r2 else r2
    else
      let compared := if p.id = 203 then 1 else p.value
      let value ← if p.id = 203 then do
          let result ← oracle external self (Verity.Core.Address.ofNat p.value) who where_ role how w
          pure (if result then 1 else 0)
        else if p.id = 200 then pure w.core.blockNumber.val
        else if p.id = 201 then pure w.core.blockTimestamp.val
        else if p.id = 205 then pure p.value
        else if p.id ≥ how.length then pure 0
        else pure ((how[p.id]!).val % 2^240)
      -- The out-of-range _how branch returns before the enum conversion.
      if p.id ≠ 203 ∧ p.id ≠ 200 ∧ p.id ≠ 201 ∧ p.id ≠ 205 ∧ p.id ≥ how.length then return false
      if p.op > 12 then return ← ⟨.error .invalidOpcode, []⟩
      return if p.op = 7 then value > 0 else compare p.op value compared

def evalParams (k : Queue.Keccak) (external : StaticCall.External) (self : Address)
    (hash : Word) (who where_ : Address) (role : Word) (how : List Word) (w : World)
    (fuel : Nat) : Result Bool :=
  if hash.val = emptyParams then pure true else eval k external self hash who where_ role how w fuel 0

/-- Specific permission is evaluated before ANY_ENTITY, with source short
circuiting. The wildcard evaluation receives ANY_ENTITY as its `who` argument. -/
def hasPermission (k : Queue.Keccak) (external : StaticCall.External) (self : Address)
    (ctx : Context) (role : Word) (how : List Word) (w : World) (fuel : Nat) : Result Bool := do
  let specific := w.core.readContractSlot self.val (permissionSlot k ctx.sender ctx.self role)
  if specific.val ≠ 0 then
    let ok ← evalParams k external self specific ctx.sender ctx.self role how w fuel
    if ok then return true
  let wildcard := w.core.readContractSlot self.val (permissionSlot k anyEntity ctx.self role)
  if wildcard.val ≠ 0 then
    let ok ← evalParams k external self wildcard anyEntity ctx.self role how w fuel
    if ok then return true
  return false

/-- Specialized ACL dispatcher for Lido's exact role query. Exhausted evaluation
is delegated explicitly; it is never silently turned into permission denial. -/
def dispatch (k : Queue.Keccak) (external : StaticCall.External) (self : Address)
    (ctx : Context) (role : Word) (fuel : Nat) (onExhausted other : External) : External := fun req w =>
  if req.target = self ∧ req.payload = Aragon.permissionPayload ctx role then
    if req.value.val ≠ 0 then .rejected []
    else
      let result := hasPermission k external self ctx role [] w fuel
      match result.outcome with
      | .error .exhausted => onExhausted req w
      | .error .invalidOpcode => .rejectedWithTrace [] result.attempts
      | .ok allowed => .successWithTrace (encode 32 (if allowed then 1 else 0)) w result.attempts
  else other req w

theorem compare_corresponds (op a b : Nat) : ACLSpec.Comparison op a b (compare op a b) := by
  unfold compare ACLSpec.Comparison
  by_cases h1 : op = 1 <;> by_cases h2 : op = 2 <;> by_cases h3 : op = 3 <;>
    by_cases h4 : op = 4 <;> by_cases h5 : op = 5 <;> by_cases h6 : op = 6 <;> simp_all

theorem no_permission (k : Queue.Keccak) (external : StaticCall.External) (self : Address)
    (ctx : Context) (role : Word) (how : List Word) (w : World) (fuel : Nat)
    (hs : (w.core.readContractSlot self.val (permissionSlot k ctx.sender ctx.self role)).val = 0)
    (ha : (w.core.readContractSlot self.val (permissionSlot k anyEntity ctx.self role)).val = 0) :
    hasPermission k external self ctx role how w fuel = ⟨.ok false, []⟩ := by
  simp [hasPermission, hs, ha, pure, bind, bindResult]

theorem unconditional_specific (k : Queue.Keccak) (external : StaticCall.External) (self : Address)
    (ctx : Context) (role : Word) (how : List Word) (w : World) (fuel : Nat)
    (hs : (w.core.readContractSlot self.val (permissionSlot k ctx.sender ctx.self role)).val = emptyParams) :
    hasPermission k external self ctx role how w fuel = ⟨.ok true, []⟩ := by
  simp [hasPermission, hs, emptyParams, evalParams, bind, bindResult, pure]

theorem unconditional_wildcard (k : Queue.Keccak) (external : StaticCall.External) (self : Address)
    (ctx : Context) (role : Word) (how : List Word) (w : World) (fuel : Nat)
    (hs : (w.core.readContractSlot self.val (permissionSlot k ctx.sender ctx.self role)).val = 0)
    (ha : (w.core.readContractSlot self.val (permissionSlot k anyEntity ctx.self role)).val = emptyParams) :
    hasPermission k external self ctx role how w fuel = ⟨.ok true, []⟩ := by
  simp [hasPermission, hs, ha, emptyParams, evalParams, bind, bindResult, pure]

theorem oracle_rejection_is_false (external : StaticCall.External) (self target who where_ : Address)
    (role : Word) (how : List Word) (w : World) (data : Bytes)
    (h : external ⟨self, target, word 0, oraclePayload who where_ role how⟩ w = .rejected data) :
    (oracle external self target who where_ role how w).outcome = .ok false := by
  simp [oracle, h]

theorem oracle_wrong_size_is_false (external : StaticCall.External) (self target who where_ : Address)
    (role : Word) (how : List Word) (w : World) (data : Bytes) (hlen : data.length ≠ 32)
    (h : external ⟨self, target, word 0, oraclePayload who where_ role how⟩ w = .success data) :
    (oracle external self target who where_ role how w).outcome = .ok false := by
  simp [oracle, h, hlen]

/-- Source permission selection refines independent grant rules when the two
physical parameter evaluations terminate. The wildcard input is ANY_ENTITY,
not the original sender. Parameter-tree correspondence remains separate. -/
theorem grants_corresponds (k : Queue.Keccak) (external : StaticCall.External) (self : Address)
    (ctx : Context) (role : Word) (how : List Word) (w : World) (fuel : Nat)
    (specificAllowed wildcardAllowed : Bool)
    (hs : (evalParams k external self
      (w.core.readContractSlot self.val (permissionSlot k ctx.sender ctx.self role))
      ctx.sender ctx.self role how w fuel).outcome = .ok specificAllowed)
    (ha : (evalParams k external self
      (w.core.readContractSlot self.val (permissionSlot k anyEntity ctx.self role))
      anyEntity ctx.self role how w fuel).outcome = .ok wildcardAllowed) :
    ∃ allowed, (hasPermission k external self ctx role how w fuel).outcome = .ok allowed ∧
      ACLSpec.Grants
        (decide ((w.core.readContractSlot self.val (permissionSlot k ctx.sender ctx.self role)).val ≠ 0))
        specificAllowed
        (decide ((w.core.readContractSlot self.val (permissionSlot k anyEntity ctx.self role)).val ≠ 0))
        wildcardAllowed allowed := by
  by_cases h1 : (w.core.readContractSlot self.val (permissionSlot k ctx.sender ctx.self role)).val = 0 <;>
    by_cases h2 : (w.core.readContractSlot self.val (permissionSlot k anyEntity ctx.self role)).val = 0 <;>
    cases specificAllowed <;> cases wildcardAllowed <;>
    simp [hasPermission, h1, h2, bind, bindResult, pure, hs, ha, ACLSpec.Grants]

end LidoSRv3.Audit.Source.TrioReserve1.ACL
