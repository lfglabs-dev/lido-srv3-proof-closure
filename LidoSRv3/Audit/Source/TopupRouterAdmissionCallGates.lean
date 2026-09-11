import LidoSRv3.Audit.Guarantees.PTopupEntryAdmission
import LidoSRv3.Audit.Source.DepositPhysicalAdmission

/-! core17005714 StakingRouter.topUp admission at the post-root/pre-module
seam. Router immutable locator and Lido identity are independent inputs. The
preceding allocation-view phase and outer gateway CALL are not modeled here.
Static transport has no writable reply World; neither call is a mutable CALL. -/
set_option autoImplicit false
namespace LidoSRv3.Audit.Source.TopupRouterAdmissionCallGates
open TrioReserve1 Live TopupGatewayWitnessBatch

structure Environment where
  locator : Address
  locatorCall : StaticCall.External
  canDepositCall : StaticCall.External
  authCursor : Word
  canDepositCursor : Word

def authSelector : Nat := 0x644862de
def canDepositSelector : Nat := 0xe78a5875

def request (router target : Address) (selector : Nat) : Request :=
  ⟨router,target,word 0,encode 4 selector⟩

/-- The same canonical address decoder as stakingRouter(), but distinct actual
request bytes, router caller and independently supplied router locator. -/
def authLookup (g : Environment) (router : Address) (w : World) : TopupRouterLocatorCall.LookupResult :=
  let r := audit.trio.consolidation.lowLevelStaticCall g.locatorCall router g.locator
    (request router g.locator authSelector).payload w
  match r.outcome with
  | .error b => ⟨.error (.bubbled b),r.attempts⟩
  | .ok raw => ⟨TopupRouterLocatorCall.decodeRouter g.authCursor raw,r.attempts⟩

def decodeBool (cursor : Word) (raw : Bytes) : Except Fault (Bool × Word) := do
  let (value,next) ← TopupCredentialCall.decodeCredentials cursor raw
  if value.val ≤ 1 then .ok (value.val = 1,next) else .error .empty

theorem decodeBool_fields (cursor : Word) (raw : Bytes) (value : Bool) (next : Word)
    (h : decodeBool cursor raw = .ok (value,next)) :
    32 ≤ (word raw.length).val ∧
    (word (decode (raw.take 32))).val ≤ 1 ∧
    value = decide ((word (decode (raw.take 32))).val = 1) ∧
    audit.trio.deposit.ModuleCall.finalizeAllocation cursor 32 = .ok next ∧
    cursor.val + 32 = next.val ∧ next.val < 2^64 := by
  unfold decodeBool at h
  cases hd : TopupCredentialCall.decodeCredentials cursor raw with
  | «error» f => simp [hd,bind,Except.bind] at h
  | ok pair =>
    rcases pair with ⟨v,n⟩
    simp only [hd,bind,Except.bind] at h
    split at h
    · rename_i hv
      cases h
      obtain ⟨hl,he,ha,hp,hb⟩ := TopupCredentialCall.decode_fields cursor raw v next hd
      subst v
      exact ⟨hl,hv,rfl,ha,hp,hb⟩
    · cases h

structure BoolResult where
  outcome : Except Fault (Bool × Word)
  attempts : List NestedAttempt
  deriving DecidableEq

def canDeposit (g : Environment) (router lido : Address) (w : World) : BoolResult :=
  let r := audit.trio.consolidation.lowLevelStaticCall g.canDepositCall router lido
    (request router lido canDepositSelector).payload w
  match r.outcome with
  | .error b => ⟨.error (.bubbled b),r.attempts⟩
  | .ok raw => ⟨decodeBool g.canDepositCursor raw,r.attempts⟩

def validateInputs (i : TopupModuleCall.Input) : Except Fault Unit :=
  if i.keyIndices.length = 0 then .error (.bubbled (encode 4 0xc4d88632)) else
  if i.operatorIds.length ≠ i.keyIndices.length ∨ i.limits.length ≠ i.keyIndices.length ∨
      i.pubkeys.length ≠ i.keyIndices.length then .error (.bubbled (encode 4 0xfc235960)) else
  if i.pubkeys.any (fun p => p.length != 48) then .error (.bubbled (encode 4 0x500585ad)) else .ok ()

def physical (hash : TopupRouterCredentials.Keccak) (router : Address)
    (id : Word) (w : World) : Except Fault Unit :=
  if DepositPhysicalAdmission.membership hash router (TrioAlloc1.word id.val) w = 0 then
    .error (.bubbled (encode 4 0xd41d6282)) else
  let packed := DepositPhysicalAdmission.config hash router (TrioAlloc1.word id.val) w
  if 3 ≤ DepositPhysicalAdmission.status packed then
    .error (.bubbled (encode 4 0x4e487b71 ++ encode 32 0x21)) else
  if DepositPhysicalAdmission.status packed ≠ 0 then
    .error (.bubbled (encode 4 0x645cc9f6)) else
  if TopupRouterCredentials.typeOf packed ≠ 2 then
    .error (.bubbled (encode 4 0x2e5c948c)) else .ok ()

def Physical (hash : TopupRouterCredentials.Keccak) (router : Address) (id : Word) (w : World) : Prop :=
  DepositPhysicalAdmission.membership hash router (TrioAlloc1.word id.val) w ≠ 0 ∧
  DepositPhysicalAdmission.status (DepositPhysicalAdmission.config hash router (TrioAlloc1.word id.val) w) = 0 ∧
  TopupRouterCredentials.typeOf (DepositPhysicalAdmission.config hash router (TrioAlloc1.word id.val) w) = 2

theorem physical_success (hash : TopupRouterCredentials.Keccak) (router : Address) (id : Word) (w : World)
    (h : physical hash router id w = .ok ()) : Physical hash router id w := by
  simp only [physical] at h
  split_ifs at h <;> simp_all [Physical]

structure Result where
  outcome : Except Fault Unit
  attempts : List NestedAttempt
  deriving DecidableEq

/-- Actual gateway sender is compared with the decoded immutable-locator result.
All input and physical checks precede the conditional zero-target Lido call.
Its target is ctx.self, not either locator or the router. -/
def run (g : Environment) (hash : TopupRouterCredentials.Keccak)
    (gateway : Address) (ctx : Context) (i : TopupModuleCall.Input) (w : World) : Result :=
  let a := authLookup g ctx.sender w
  match a.outcome with
  | .error f => ⟨.error f,a.attempts⟩
  | .ok (allowed,_) =>
    if gateway ≠ allowed then ⟨.error (.bubbled (encode 4 0xea8e4eb5)),a.attempts⟩ else
    match validateInputs i with
    | .error f => ⟨.error f,a.attempts⟩
    | .ok () =>
      match physical hash ctx.sender i.moduleId w with
      | .error f => ⟨.error f,a.attempts⟩
      | .ok () =>
        if i.roundedTarget.val = 0 then
          let c := canDeposit g ctx.sender ctx.self w
          match c.outcome with
          | .error f => ⟨.error f,a.attempts ++ c.attempts⟩
          | .ok (allowed,_) =>
            if allowed then ⟨.ok (),a.attempts ++ c.attempts⟩
            else ⟨.error (.bubbled (encode 4 0x5609c247)),a.attempts ++ c.attempts⟩
        else ⟨.ok (),a.attempts⟩

def Admitted (g : Environment) (hash : TopupRouterCredentials.Keccak)
    (gateway : Address) (ctx : Context) (i : TopupModuleCall.Input) (w : World) : Prop :=
  (∃ next, (authLookup g ctx.sender w).outcome = .ok (gateway,next)) ∧
  validateInputs i = .ok () ∧ Physical hash ctx.sender i.moduleId w ∧
  (i.roundedTarget.val = 0 → ∃ next, (canDeposit g ctx.sender ctx.self w).outcome = .ok (true,next))

theorem run_admitted (g : Environment) (hash : TopupRouterCredentials.Keccak)
    (gateway : Address) (ctx : Context) (i : TopupModuleCall.Input) (w : World)
    (h : (run g hash gateway ctx i w).outcome = .ok ()) : Admitted g hash gateway ctx i w := by
  unfold run at h
  cases ha : (authLookup g ctx.sender w).outcome with
  | «error» f => simp [ha] at h
  | ok pair =>
    rcases pair with ⟨allowed,next⟩
    simp only [ha] at h
    split at h
    · cases h
    · rename_i he
      have heq : gateway = allowed := by simpa using he
      subst allowed
      cases hi : validateInputs i with
      | «error» f => simp [hi] at h
      | ok u =>
        cases u
        simp only [hi] at h
        cases hp : physical hash ctx.sender i.moduleId w with
        | «error» f => simp [hp] at h
        | ok u =>
          cases u
          simp only [hp] at h
          refine ⟨⟨next,ha⟩,hi,physical_success _ _ _ _ hp,?_⟩
          intro hz
          simp only [hz,if_true] at h
          cases hc : (canDeposit g ctx.sender ctx.self w).outcome with
          | «error» f => simp [hc] at h
          | ok pair =>
            rcases pair with ⟨b,n⟩
            cases b <;> simp [hc] at h
            exact ⟨n,rfl⟩

theorem auth_origin (g : Environment) (router : Address) (before : World) (allowed : Address) (next : Word) (trace : List NestedAttempt)
    (h : authLookup g router before = ⟨.ok (allowed,next),trace⟩) :
    (before.core.codeSize g.locator.val).val ≠ 0 ∧ ∃ raw,
      g.locatorCall (request router g.locator authSelector) before = .success raw ∧
      TopupRouterLocatorCall.decodeRouter g.authCursor raw = .ok (allowed,next) ∧
      32 ≤ (word raw.length).val ∧ allowed.val = (word (decode (raw.take 32))).val ∧
      allowed.val < 2^160 ∧ audit.trio.deposit.ModuleCall.finalizeAllocation g.authCursor 32 = .ok next ∧
      g.authCursor.val + 32 = next.val ∧ next.val < 2^64 ∧
      trace = [⟨request router g.locator authSelector,true,true,raw,1⟩] := by
  unfold authLookup audit.trio.consolidation.lowLevelStaticCall at h
  by_cases hc : (before.core.codeSize g.locator.val).val = 0
  · simp only [hc,if_true] at h
    have hd := congrArg TopupRouterLocatorCall.LookupResult.outcome h
    have hb := (TopupRouterLocatorCall.decode_fields g.authCursor [] allowed next hd).1
    norm_num [word,Verity.Core.Uint256.modulus,Verity.Core.UINT256_MODULUS] at hb
  · simp only [hc,if_false] at h
    cases hr : g.locatorCall (request router g.locator authSelector) before with
    | rejected data => simp only [request] at hr h; simp [hr] at h
    | forbiddenStateChange => simp only [request] at hr h; simp [hr] at h
    | success raw =>
      simp only [request] at hr h
      simp only [hr] at h
      have hd := congrArg TopupRouterLocatorCall.LookupResult.outcome h
      have ht := congrArg TopupRouterLocatorCall.LookupResult.attempts h
      obtain ⟨hl,hv,h160,ha,he,hb⟩ := TopupRouterLocatorCall.decode_fields g.authCursor raw allowed next hd
      exact ⟨hc,raw,rfl,hd,hl,hv,h160,ha,he,hb,ht.symm⟩

theorem canDeposit_origin (g : Environment) (router lido : Address) (before : World)
    (value : Bool) (next : Word) (trace : List NestedAttempt)
    (h : canDeposit g router lido before = ⟨.ok (value,next),trace⟩) :
    (before.core.codeSize lido.val).val ≠ 0 ∧ ∃ raw,
      g.canDepositCall (request router lido canDepositSelector) before = .success raw ∧
      decodeBool g.canDepositCursor raw = .ok (value,next) ∧
      32 ≤ (word raw.length).val ∧ (word (decode (raw.take 32))).val ≤ 1 ∧
      value = decide ((word (decode (raw.take 32))).val = 1) ∧
      audit.trio.deposit.ModuleCall.finalizeAllocation g.canDepositCursor 32 = .ok next ∧
      g.canDepositCursor.val + 32 = next.val ∧ next.val < 2^64 ∧
      trace = [⟨request router lido canDepositSelector,true,true,raw,1⟩] := by
  unfold canDeposit audit.trio.consolidation.lowLevelStaticCall at h
  by_cases hc : (before.core.codeSize lido.val).val = 0
  · simp only [hc,if_true] at h
    have hd := congrArg BoolResult.outcome h
    have hb := (decodeBool_fields g.canDepositCursor [] value next hd).1
    norm_num [word,Verity.Core.Uint256.modulus,Verity.Core.UINT256_MODULUS] at hb
  · simp only [hc,if_false] at h
    cases hr : g.canDepositCall (request router lido canDepositSelector) before with
    | rejected data => simp only [request] at hr h; simp [hr] at h
    | forbiddenStateChange => simp only [request] at hr h; simp [hr] at h
    | success raw =>
      simp only [request] at hr h
      simp only [hr] at h
      have hd := congrArg BoolResult.outcome h
      have ht := congrArg BoolResult.attempts h
      obtain ⟨hl,hv,hvEq,ha,he,hb⟩ := decodeBool_fields g.canDepositCursor raw value next hd
      exact ⟨hc,raw,rfl,hd,hl,hv,hvEq,ha,he,hb,ht.symm⟩

/-- Each successful call is tied to its real request, decoder and ordered journal.
Successful static responses consume this same pre-module World, by construction. -/
def CallFacts (g : Environment) (gateway : Address) (ctx : Context)
    (i : TopupModuleCall.Input) (w : World) : Prop :=
  (∃ raw next, g.locatorCall (request ctx.sender g.locator authSelector) w = .success raw ∧
    TopupRouterLocatorCall.decodeRouter g.authCursor raw = .ok (gateway,next) ∧
    (authLookup g ctx.sender w).attempts = [⟨request ctx.sender g.locator authSelector,true,true,raw,1⟩] ∧
    32 ≤ (word raw.length).val ∧ gateway.val = (word (decode (raw.take 32))).val ∧
    g.authCursor.val + 32 = next.val ∧ next.val < 2^64) ∧
  (i.roundedTarget.val = 0 → ∃ raw next,
    g.canDepositCall (request ctx.sender ctx.self canDepositSelector) w = .success raw ∧
    decodeBool g.canDepositCursor raw = .ok (true,next) ∧
    (canDeposit g ctx.sender ctx.self w).attempts = [⟨request ctx.sender ctx.self canDepositSelector,true,true,raw,1⟩] ∧
    32 ≤ (word raw.length).val ∧ (word (decode (raw.take 32))).val = 1 ∧
    g.canDepositCursor.val + 32 = next.val ∧ next.val < 2^64)

theorem admitted_calls (g : Environment) (hash : TopupRouterCredentials.Keccak)
    (gateway : Address) (ctx : Context) (i : TopupModuleCall.Input) (w : World)
    (h : Admitted g hash gateway ctx i w) : CallFacts g gateway ctx i w := by
  obtain ⟨⟨next,ha⟩,_,_,hz⟩ := h
  have hae : authLookup g ctx.sender w = ⟨.ok (gateway,next),(authLookup g ctx.sender w).attempts⟩ := by
    exact congrArg (fun outcome => TopupRouterLocatorCall.LookupResult.mk outcome (authLookup g ctx.sender w).attempts) ha
  obtain ⟨_,raw,hr,hd,hl,hv,_,_,hp,hb,ht⟩ := auth_origin g ctx.sender w gateway next _ hae
  refine ⟨⟨raw,next,hr,hd,ht,hl,hv,hp,hb⟩,?_⟩
  intro hzero
  obtain ⟨n,hc⟩ := hz hzero
  have hce : canDeposit g ctx.sender ctx.self w = ⟨.ok (true,n),(canDeposit g ctx.sender ctx.self w).attempts⟩ := by
    exact congrArg (fun outcome => BoolResult.mk outcome (canDeposit g ctx.sender ctx.self w).attempts) hc
  obtain ⟨_,data,hr,hd,hl,_,hv,_,hp,hb,ht⟩ := canDeposit_origin g ctx.sender ctx.self w true n _ hce
  have hv' : (word (decode (data.take 32))).val = 1 := by simpa using hv.symm
  exact ⟨data,n,hr,hd,ht,hl,hv',hp,hb⟩

#print axioms auth_origin
#print axioms canDeposit_origin
#print axioms admitted_calls

#print axioms decodeBool_fields
#print axioms physical_success
#print axioms run_admitted
end LidoSRv3.Audit.Source.TopupRouterAdmissionCallGates
