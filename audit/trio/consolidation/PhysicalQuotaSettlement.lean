import LidoSRv3.Audit.Guarantees.PConsolidationEth1Requests

/-! Typed suffix immediately before the quota at ConsolidationGateway:209.
The payable credit and role/pause/DSM/locator/witness prefix have already run.
As in GatewaySettlement, pure entry guards/count are replayed on the supplied
groups; this does not move quota before the omitted stateful preconditions.
Raw physical LimitData may be uninitialized or inconsistent: every checked
arithmetic error, division by zero and uint32 truncation is executed below. -/
set_option autoImplicit false
namespace audit.trio.consolidation.PhysicalQuotaSettlement
open LidoSRv3.Audit.Source.TrioReserve1 LidoSRv3.Audit.Source.TrioReserve1.Live

def position : Nat := 0xdbb01bb6dca1179d47b58b17828e02dd61fb4c11ad515bab6e3e9ce25440d797
def modulus32 : Nat := 2^32
def field (raw : Word) (offset : Nat) : Nat := raw.val / 2^offset % modulus32
theorem field_bound (raw : Word) (offset : Nat) : field raw offset < modulus32 :=
  Nat.mod_lt _ (by decide)

structure Data where
  maximum : Nat
  previous : Nat
  timestamp : Nat
  duration : Nat
  items : Nat
  deriving DecidableEq, Repr

def unpack (raw : Word) : Data :=
  ⟨field raw 0,field raw 32,field raw 64,field raw 96,field raw 128⟩

def arithmetic : Fault := .bubbled (GatewayCall.panic 0x11)
def division : Fault := .bubbled (GatewayCall.panic 0x12)

/-- calculateCurrentLimit, including its early return BEFORE division. -/
def current (d : Data) (time : Nat) : Except Fault Nat :=
  if time < d.timestamp then .error arithmetic else
  let seconds := time-d.timestamp
  if seconds < d.duration ∨ d.items = 0 then .ok d.previous else
  if d.duration = 0 then .error division else
  let restored := (seconds / d.duration) * d.items
  if restored ≥ Verity.Core.UINT256_MODULUS then .error arithmetic else
  let replenished := d.previous + restored
  if replenished ≥ Verity.Core.UINT256_MODULUS then .error arithmetic else
  .ok (min replenished d.maximum)

theorem current_bound (raw : Word) (time available : Nat)
    (h : current (unpack raw) time = .ok available) : available < modulus32 := by
  have hm : (unpack raw).maximum < modulus32 := field_bound raw 0
  have hp : (unpack raw).previous < modulus32 := field_bound raw 32
  unfold current at h
  split at h
  · contradiction
  · try dsimp only at h
    split at h
    · cases h; exact hp
    · split at h
      · contradiction
      · try dsimp only at h
        split at h
        · contradiction
        · try dsimp only at h
          split at h
          · contradiction
          · cases h
            exact Nat.lt_of_le_of_lt (Nat.min_le_right _ _) hm

/-- updatePrevLimit: the cast is BEFORE the checked uint32 multiplication. -/
def updatedTime (d : Data) (remaining time : Nat) : Except Fault Nat :=
  if d.maximum < remaining then .error (.bubbled (encode 4 0x3261c792)) else
  if time < d.timestamp then .error arithmetic else
  if d.duration = 0 then .error division else
  let passed := ((time-d.timestamp)/d.duration % modulus32) * d.duration
  if passed ≥ modulus32 then .error arithmetic else
  if d.timestamp + passed ≥ modulus32 then .error arithmetic else
  .ok (d.timestamp+passed)

theorem updatedTime_success (d : Data) (remaining time result : Nat)
    (h : updatedTime d remaining time = .ok result) :
    remaining ≤ d.maximum ∧ d.timestamp ≤ time ∧ d.duration ≠ 0 ∧
    result = d.timestamp + ((time-d.timestamp)/d.duration % modulus32)*d.duration ∧
    result < modulus32 := by
  unfold updatedTime at h
  split at h
  · contradiction
  · rename_i hm
    split at h
    · contradiction
    · rename_i ht
      split at h
      · contradiction
      · rename_i hd
        try dsimp only at h
        split at h
        · contradiction
        · split at h
          · contradiction
          · rename_i hb
            cases h
            exact ⟨by omega,by omega,hd,rfl,by omega⟩

/-- Five low uint32 fields are assigned; the upper 96 storage bits survive.
Only previous limit and timestamp change within the decoded LimitData. -/
def packed (raw : Word) (remaining time : Nat) : Word :=
  word (field raw 0 + remaining%modulus32*2^32 + time%modulus32*2^64 +
    field raw 96*2^96 + field raw 128*2^128 + raw.val/2^160*2^160)

set_option maxHeartbeats 4000000 in
theorem packed_fields (raw : Word) (remaining time : Nat) :
    field (packed raw remaining time) 0 = field raw 0 ∧
    field (packed raw remaining time) 32 = remaining%modulus32 ∧
    field (packed raw remaining time) 64 = time%modulus32 ∧
    field (packed raw remaining time) 96 = field raw 96 ∧
    field (packed raw remaining time) 128 = field raw 128 ∧
    (packed raw remaining time).val/2^160 = raw.val/2^160 := by
  have h0 := field_bound raw 0
  have h96 := field_bound raw 96
  have h128 := field_bound raw 128
  have hr : remaining%modulus32 < modulus32 := Nat.mod_lt _ (by decide)
  have ht : time%modulus32 < modulus32 := Nat.mod_lt _ (by decide)
  have hw : raw.val < 2^256 := raw.isLt
  have hu : raw.val/2^160 < 2^96 := by omega
  have hf : field raw 0 + remaining%modulus32*2^32 + time%modulus32*2^64 +
      field raw 96*2^96 + field raw 128*2^128 + raw.val/2^160*2^160 < 2^256 := by
    dsimp [modulus32] at *
    omega
  have hv : (packed raw remaining time).val = field raw 0 + remaining%modulus32*2^32 +
      time%modulus32*2^64 + field raw 96*2^96 + field raw 128*2^128 + raw.val/2^160*2^160 :=
    Nat.mod_eq_of_lt hf
  simp only [field, hv]
  dsimp [field,modulus32] at *
  omega

structure Update where
  available : Nat
  remaining : Nat
  timestamp : Nat
  raw : Word
  deriving DecidableEq, Repr

/-- Disabled maxLimit skips all arithmetic and performs no storage write. -/
def transition (raw : Word) (time count : Nat) : Except Fault (Option Update) :=
  let d := unpack raw
  if d.maximum = 0 then .ok none else
  match current d time with
  | .error f => .error f
  | .ok available =>
    if available < count then
      .error (.bubbled (GatewayCall.error2 0xd0e5bff5 count available))
    else match updatedTime d (available-count) time with
    | .error f => .error f
    | .ok timestamp =>
      .ok (some ⟨available,available-count,timestamp,packed raw (available-count) timestamp⟩)

theorem transition_success (raw : Word) (time count : Nat) (u : Update)
    (h : transition raw time count = .ok (some u)) :
    (unpack raw).maximum ≠ 0 ∧ current (unpack raw) time = .ok u.available ∧
    count + u.remaining = u.available ∧ u.remaining ≤ (unpack raw).maximum ∧
    u.remaining < modulus32 ∧ u.timestamp < modulus32 ∧
    updatedTime (unpack raw) u.remaining time = .ok u.timestamp ∧
    u.raw = packed raw u.remaining u.timestamp := by
  unfold transition at h
  try dsimp only at h
  split at h
  · simp at h
  · rename_i hm
    cases hc : current (unpack raw) time with
    | «error» f => simp [hc] at h
    | ok a =>
      simp only [hc] at h
      split at h
      · contradiction
      · rename_i ha
        cases ht : updatedTime (unpack raw) (a-count) time with
        | «error» f => simp [ht] at h
        | ok t =>
          simp only [ht,Except.ok.injEq,Option.some.injEq] at h
          subst u
          have hu := updatedTime_success _ _ _ _ ht
          have bound : (unpack raw).maximum < modulus32 := field_bound raw 0
          exact ⟨hm,rfl,by dsimp; omega,hu.1,by dsimp; omega,hu.2.2.2.2,ht,rfl⟩

def stored (gateway : Address) (before : World) : Word :=
  before.core.readContractSlot gateway.val position
def postQuota (gateway : Address) (before : World) (update : Option Update) : World :=
  match update with
  | none => before
  | some u => {before with core := before.core.writeContractSlot gateway.val position u.raw}

/-- Replayed pure guards/count, not the omitted stateful source prefix. -/
def prepare (ctx : Context) (msgValue : Word) (groups : List WitnessGroupBytes)
    (before : World) : Except Fault Nat :=
  if before.balances ctx.self < msgValue.val then .error arithmetic else
  if msgValue.val = 0 then
    .error (.bubbled (GatewayCall.errorBytes 0x56e42893 "msg.value".toUTF8.toList)) else
  if groups.length = 0 then
    .error (.bubbled (GatewayCall.errorBytes 0x56e42893 "groups".toUTF8.toList)) else
  GatewaySettlement.countGroups groups 0 0

theorem prepare_success (ctx : Context) (msgValue : Word) (groups : List WitnessGroupBytes)
    (before : World) (count : Nat) (h : prepare ctx msgValue groups before = .ok count) :
    count = GatewaySettlement.requestCount groups ∧ count < Verity.Core.UINT256_MODULUS := by
  unfold prepare at h
  split at h
  · contradiction
  · split at h
    · contradiction
    · split at h
      · contradiction
      · simpa using GatewaySettlement.countGroups_success groups 0 0 count (by decide) h

theorem transition_none (raw : Word) (time count : Nat)
    (h : transition raw time count = .ok none) : (unpack raw).maximum = 0 := by
  unfold transition at h
  try dsimp only at h
  split at h
  · assumption
  · cases hc : current (unpack raw) time with
    | «error» f => simp [hc] at h
    | ok a =>
      simp only [hc] at h
      split at h
      · contradiction
      · cases ht : updatedTime (unpack raw) (a-count) time with
        | «error» f => simp [ht] at h
        | ok t => simp [ht] at h

/-- Effects describe the actual pre-callback quota state, never a final frame. -/
def QuotaEffects (gateway : Address) (before : World) (count : Nat)
    (u : Option Update) : Prop :=
  match u with
  | none => (unpack (stored gateway before)).maximum = 0 ∧ postQuota gateway before u = before
  | some q =>
    let raw := stored gateway before
    (unpack raw).maximum ≠ 0 ∧ current (unpack raw) before.core.blockTimestamp.val = .ok q.available ∧
    q.available < modulus32 ∧
    count+q.remaining = q.available ∧ q.remaining ≤ (unpack raw).maximum ∧
    q.remaining < modulus32 ∧ q.timestamp < modulus32 ∧
    updatedTime (unpack raw) q.remaining before.core.blockTimestamp.val = .ok q.timestamp ∧
    q.raw = packed raw q.remaining q.timestamp ∧
    postQuota gateway before u = {before with core := before.core.writeContractSlot gateway.val position q.raw}

theorem quota_effects (gateway : Address) (before : World) (count : Nat) (u : Option Update)
    (h : transition (stored gateway before) before.core.blockTimestamp.val count = .ok u) :
    QuotaEffects gateway before count u := by
  cases u with
  | none => exact ⟨transition_none _ _ _ h,rfl⟩
  | some q =>
    obtain ⟨hm,hc,hs,hle,hr,ht,hu,hraw⟩ := transition_success _ _ _ _ h
    exact ⟨hm,hc,current_bound _ _ _ hc,hs,hle,hr,ht,hu,hraw,rfl⟩

structure Result where
  outcome : Except Fault Unit
  world : World
  trace : List NestedAttempt
  quota : Option (Nat × Option Update)
  suffix : Option GatewaySettlement.Result

def ofPrior (count : Nat) (u : Option Update) (r : GatewaySettlement.Result) : Result :=
  ⟨r.outcome,r.world,r.trace,some (count,u),some r⟩

def body (callee : External) (sexternal : StaticCall.External) (ctx : Context)
    (vault gateway inbox recipient : Address) (msgValue : Word)
    (groups : List WitnessGroupBytes) (before : World) : Result :=
  match prepare ctx msgValue groups before with
  | .error f => ⟨.error f,before,[],none,none⟩
  | .ok count =>
    match transition (stored ctx.self before) before.core.blockTimestamp.val count with
    | .error f => ⟨.error f,before,[],none,none⟩
    | .ok u => ofPrior count u (GatewaySettlement.execute callee callee sexternal ctx
        vault gateway inbox recipient msgValue groups (postQuota ctx.self before u))

def execute (callee : External) (sexternal : StaticCall.External) (ctx : Context)
    (vault gateway inbox recipient : Address) (msgValue : Word)
    (groups : List WitnessGroupBytes) (before : World) : Result :=
  let r := body callee sexternal ctx vault gateway inbox recipient msgValue groups before
  match r.outcome with
  | .ok () => r
  | .error _ => {r with world := before}

theorem failure_restores (callee : External) (sexternal : StaticCall.External) (ctx : Context)
    (vault gateway inbox recipient : Address) (msgValue : Word)
    (groups : List WitnessGroupBytes) (before : World) (f : Fault)
    (h : (execute callee sexternal ctx vault gateway inbox recipient msgValue groups before).outcome = .error f) :
    (execute callee sexternal ctx vault gateway inbox recipient msgValue groups before).world = before := by
  unfold execute at h ⊢
  dsimp only at h ⊢
  split <;> simp_all

theorem execute_success (callee : External) (sexternal : StaticCall.External) (ctx : Context)
    (vault gateway inbox recipient : Address) (msgValue : Word)
    (groups : List WitnessGroupBytes) (before : World)
    (h : (execute callee sexternal ctx vault gateway inbox recipient msgValue groups before).outcome = .ok ()) :
    ∃ count u,
      prepare ctx msgValue groups before = .ok count ∧
      transition (stored ctx.self before) before.core.blockTimestamp.val count = .ok u ∧
      (GatewaySettlement.execute callee callee sexternal ctx vault gateway inbox recipient msgValue groups
        (postQuota ctx.self before u)).outcome = .ok () ∧
      execute callee sexternal ctx vault gateway inbox recipient msgValue groups before =
        ofPrior count u (GatewaySettlement.execute callee callee sexternal ctx vault gateway inbox recipient
          msgValue groups (postQuota ctx.self before u)) := by
  have hb : (body callee sexternal ctx vault gateway inbox recipient msgValue groups before).outcome = .ok () ∧
      execute callee sexternal ctx vault gateway inbox recipient msgValue groups before =
        body callee sexternal ctx vault gateway inbox recipient msgValue groups before := by
    unfold execute at h ⊢
    dsimp only at h ⊢
    split <;> simp_all
  rw [hb.2]
  have hs := hb.1
  unfold body at hs ⊢
  cases hp : prepare ctx msgValue groups before with
  | «error» f => simp [hp] at hs
  | ok count =>
    simp only [hp] at hs ⊢
    cases ht : transition (stored ctx.self before) before.core.blockTimestamp.val count with
    | «error» f => simp [ht] at hs
    | ok u =>
      simp only [ht] at hs ⊢
      exact ⟨count,u,rfl,ht,hs,rfl⟩

#print axioms field_bound
#print axioms current_bound
#print axioms packed_fields
#print axioms updatedTime_success
#print axioms transition_success
#print axioms transition_none
#print axioms prepare_success
#print axioms quota_effects
#print axioms execute_success
#print axioms failure_restores
end audit.trio.consolidation.PhysicalQuotaSettlement
