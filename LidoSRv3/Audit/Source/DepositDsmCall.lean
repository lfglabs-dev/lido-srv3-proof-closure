import LidoSRv3.Audit.Guarantees.PDeposit1PhysicalAdmission

/-! core17005714, StakingRouter.deposit and _getDepositSecurityModule.
Actual solc0.8.25 return-valued STATICCALL has no code precheck. The immutable
locator and phase memory cursor are inputs; getDepositableEther/ALLOC remain
omitted. Separate typed static observations preserve the old suffix journal. -/
namespace LidoSRv3.Audit.Source.DepositDsmCall
set_option autoImplicit false
open TrioReserve1
open audit.trio.deposit
abbrev Keccak := TopupRouterCredentials.Keccak

def selector : Nat := 0x472c1776

def request (router locator : Live.Address) : Live.Request :=
  ⟨router,locator,Live.word 0,Live.encode 4 selector⟩

/-- The compiler reserves the copied min(32,returndatasize) bytes before the
length/canonical-address checks. Return data after the first word is ignored.
The cursor is the actual pointer at this phase, not an invented fixed bound. -/
def decodeAddress (cursor : Live.Word) (raw : Live.Bytes) : Except Live.Fault TrioAlloc1.Address := do
  let copied := min 32 (Live.word raw.length).val
  let _ ← ModuleCall.finalizeAllocation cursor copied
  if copied < 32 then .error .empty else
  let n := Live.decode (raw.take 32)
  if h : n < 2^160 then .ok ⟨n,h⟩ else .error .empty

structure LookupResult where
  outcome : Except Live.Fault TrioAlloc1.Address
  attempts : List Live.NestedAttempt
  deriving DecidableEq

/-- The existing low-level STATICCALL models ordinary no-code success with
empty bytes; the following decoder rejects that success. Precompile dispatch
is outside this inherited no-code arm. No writable reply World exists. -/
def lookup (locatorExternal : StaticCall.External) (router locator : Live.Address)
    (cursor : Live.Word) (before : Live.World) : LookupResult :=
  let r := audit.trio.consolidation.lowLevelStaticCall locatorExternal router locator
    (Live.encode 4 selector) before
  match r.outcome with
  | .error bytes => ⟨.error (.bubbled bytes),r.attempts⟩
  | .ok raw => ⟨decodeAddress cursor raw,r.attempts⟩

def resolvedContext (ctx : RouterDeposit.Context) (dsm : TrioAlloc1.Address) : RouterDeposit.Context :=
  {ctx with depositSecurityModule := dsm}

/-- Static observations have their actual isStatic flag. `attempts` is exactly
old module/suffix journal, never padded with a synthetic module CALL. -/
structure Result where
  outcome : Except Live.Fault Unit
  world : Live.World
  attempts : List Live.Attempt
  locatorAttempts : List Live.NestedAttempt

def program (locatorExternal : StaticCall.External) (locator : Live.Address) (cursor : Live.Word)
    (hash : Keccak) (m w : Live.External) (ctx : RouterDeposit.Context)
    (liveCtx : Live.Context) (i : ModuleCall.Input) (before : Live.World) : Result :=
  let q := lookup locatorExternal liveCtx.sender locator cursor before
  match q.outcome with
  | .error e => ⟨.error e,before,[],q.attempts⟩
  | .ok dsm =>
    let r := DepositPhysicalAdmission.program hash m w (resolvedContext ctx dsm) liveCtx i before
    ⟨r.outcome,r.world,r.attempts,q.attempts⟩

def execute (locatorExternal : StaticCall.External) (locator : Live.Address) (cursor : Live.Word)
    (hash : Keccak) (m w : Live.External) (ctx : RouterDeposit.Context)
    (liveCtx : Live.Context) (i : ModuleCall.Input) (before : Live.World) : Result :=
  let r := program locatorExternal locator cursor hash m w ctx liveCtx i before
  match r.outcome with
  | .ok () => r
  | .error e => ⟨.error e,before,r.attempts,r.locatorAttempts⟩

/-- Exact composition equation used by executable regressions. The public
success theorem does not require this lookup equation as an input. -/
theorem execute_of_lookup (locatorExternal : StaticCall.External) (locator : Live.Address) (cursor : Live.Word)
    (hash : Keccak) (m w : Live.External) (ctx : RouterDeposit.Context)
    (liveCtx : Live.Context) (i : ModuleCall.Input) (before : Live.World)
    (dsm : TrioAlloc1.Address) (trace : List Live.NestedAttempt)
    (hq : lookup locatorExternal liveCtx.sender locator cursor before = ⟨.ok dsm,trace⟩) :
    execute locatorExternal locator cursor hash m w ctx liveCtx i before =
      let r := DepositPhysicalAdmission.execute hash m w (resolvedContext ctx dsm) liveCtx i before
      ⟨r.outcome,r.world,r.attempts,trace⟩ := by
  unfold execute program
  rw [hq]
  unfold DepositPhysicalAdmission.execute Live.run
  dsimp only
  cases hr : DepositPhysicalAdmission.program hash m w (resolvedContext ctx dsm) liveCtx i before with
  | mk outcome world attempts => cases outcome <;> rfl

theorem decodeAddress_fields (cursor : Live.Word) (raw : Live.Bytes) (dsm : TrioAlloc1.Address)
    (h : decodeAddress cursor raw = .ok dsm) :
    32 ≤ (Live.word raw.length).val ∧ dsm.val = Live.decode (raw.take 32) := by
  unfold decodeAddress at h
  cases ha : ModuleCall.finalizeAllocation cursor (min 32 (Live.word raw.length).val) with
  | «error» e => simp [ha,bind,Except.bind] at h
  | ok next =>
    simp only [ha] at h
    split at h
    · contradiction
    · rename_i hl
      split at h
      · cases h
        exact ⟨by omega,rfl⟩
      · contradiction

/-- An accepted address came from the actual coded locator response, with
canonical high bits and its successful STATICCALL observation. -/
theorem lookup_origin (locatorExternal : StaticCall.External) (router locator : Live.Address)
    (cursor : Live.Word) (before : Live.World) (dsm : TrioAlloc1.Address)
    (trace : List Live.NestedAttempt) (h : lookup locatorExternal router locator cursor before = ⟨.ok dsm,trace⟩) :
    (before.core.codeSize locator.val).val ≠ 0 ∧ ∃ raw,
      locatorExternal (request router locator) before = .success raw ∧
      decodeAddress cursor raw = .ok dsm ∧
      32 ≤ (Live.word raw.length).val ∧ dsm.val = Live.decode (raw.take 32) ∧
      trace = [⟨request router locator,true,true,raw,1⟩] := by
  unfold lookup audit.trio.consolidation.lowLevelStaticCall at h
  split at h
  · have he : ∀ cursor, decodeAddress cursor [] ≠ .ok dsm := by
      intro c hc
      have hb := (decodeAddress_fields c [] dsm hc).1
      norm_num [Live.word] at hb
    simp only at h
    have hh := congrArg LookupResult.outcome h
    exact False.elim (he cursor hh)
  · rename_i hc
    cases hr : locatorExternal (request router locator) before with
    | rejected data => unfold request at hr; simp [hr] at h
    | forbiddenStateChange => unfold request at hr; simp [hr] at h
    | success raw =>
      unfold request at hr
      simp only [hr] at h
      have hd := congrArg LookupResult.outcome h
      have ht := congrArg LookupResult.attempts h
      exact ⟨hc,raw,rfl,hd,(decodeAddress_fields cursor raw dsm hd).1,
        (decodeAddress_fields cursor raw dsm hd).2,ht.symm⟩

def Effects (locatorExternal : StaticCall.External) (locator : Live.Address) (cursor : Live.Word)
    (hash : Keccak) (m w : Live.External) (ctx : RouterDeposit.Context)
    (liveCtx : Live.Context) (i : ModuleCall.Input) (before after : Live.World)
    (attempts : List Live.Attempt) (staticTrace : List Live.NestedAttempt) : Prop :=
  ∃ dsm raw,
    (before.core.codeSize locator.val).val ≠ 0 ∧
    locatorExternal (request liveCtx.sender locator) before = .success raw ∧
    decodeAddress cursor raw = .ok dsm ∧
    32 ≤ (Live.word raw.length).val ∧ dsm.val = Live.decode (raw.take 32) ∧
    staticTrace = [⟨request liveCtx.sender locator,true,true,raw,1⟩] ∧
    ctx.caller = dsm ∧
    DepositPhysicalAdmission.Effects hash m w (resolvedContext ctx dsm) liveCtx i before after attempts

theorem success_effects (locatorExternal : StaticCall.External) (locator : Live.Address) (cursor : Live.Word)
    (hash : Keccak) (m w : Live.External) (ctx : RouterDeposit.Context)
    (liveCtx : Live.Context) (i : ModuleCall.Input) (before after : Live.World)
    (attempts : List Live.Attempt) (staticTrace : List Live.NestedAttempt)
    (h : execute locatorExternal locator cursor hash m w ctx liveCtx i before = ⟨.ok (),after,attempts,staticTrace⟩) :
    Effects locatorExternal locator cursor hash m w ctx liveCtx i before after attempts staticTrace := by
  have hp : program locatorExternal locator cursor hash m w ctx liveCtx i before = ⟨.ok (),after,attempts,staticTrace⟩ := by
    unfold execute at h
    dsimp only at h
    split at h
    · exact h
    · cases h
  cases hq : lookup locatorExternal liveCtx.sender locator cursor before with
  | mk outcome trace =>
    cases outcome with
    | «error» e => simp [program,hq] at hp
    | ok dsm =>
      simp only [program,hq] at hp
      have ho := congrArg Result.outcome hp
      have hw := congrArg Result.world hp
      have ht := congrArg Result.attempts hp
      have hst := congrArg Result.locatorAttempts hp
      have old : DepositPhysicalAdmission.execute hash m w (resolvedContext ctx dsm) liveCtx i before =
          ⟨.ok (),after,attempts⟩ := by
        unfold DepositPhysicalAdmission.execute Live.run
        simp only at ho hw ht
        dsimp only
        rw [ho]
        cases he : DepositPhysicalAdmission.program hash m w (resolvedContext ctx dsm) liveCtx i before with
        | mk outcome world trace =>
          simp only [he] at ho hw ht
          cases ho
          cases hw
          cases ht
          rfl
      have effects := LidoSRv3.Audit.Guarantees.PDeposit1.actual_registered_module_call_metadata_suffix
        hash m w (resolvedContext ctx dsm) liveCtx i before after attempts old
      obtain ⟨hc,raw,hr,hd,hl,hv,htrace⟩ := lookup_origin locatorExternal liveCtx.sender locator cursor before dsm trace hq
      exact ⟨dsm,raw,hc,hr,hd,hl,hv,(by simpa only using hst.symm.trans htrace), effects.1,effects⟩

theorem failure_restores (locatorExternal : StaticCall.External) (locator : Live.Address) (cursor : Live.Word)
    (hash : Keccak) (m w : Live.External) (ctx : RouterDeposit.Context)
    (liveCtx : Live.Context) (i : ModuleCall.Input) (before after : Live.World)
    (attempts : List Live.Attempt) (staticTrace : List Live.NestedAttempt) (fault : Live.Fault)
    (h : execute locatorExternal locator cursor hash m w ctx liveCtx i before = ⟨.error fault,after,attempts,staticTrace⟩) :
    after = before := by
  unfold execute at h
  dsimp only at h
  split at h
  · have ho := congrArg Result.outcome h
    simp_all
  · exact (Result.mk.inj h).2.1.symm
end LidoSRv3.Audit.Source.DepositDsmCall
