import LidoSRv3.Audit.Guarantees.PDeposit1DsmCall

/-! Exact local admission errors only; core17005714 deposit943–950.
One DSM lookup, one unchanged module continuation. Allocation/capture and all
other inherited boundaries remain unchanged. No downstream string remapping. -/
namespace LidoSRv3.Audit.Source.DepositAdmissionErrors
set_option autoImplicit false
open TrioReserve1 audit.trio.deposit
abbrev Keccak := DepositDsmCall.Keccak
inductive AdmissionError where
  | unauthorized | unregistered | invalidEnum | inactive
  deriving DecidableEq, Repr

def errorBytes : AdmissionError → Live.Bytes
  | .unauthorized => Live.encode 4 0xea8e4eb5
  | .unregistered => Live.encode 4 0xd41d6282
  | .invalidEnum => Live.encode 4 0x4e487b71 ++ Live.encode 32 0x21
  | .inactive => Live.encode 4 0x645cc9f6

def gate (hash : Keccak) (ctx : RouterDeposit.Context) (liveCtx : Live.Context)
    (i : ModuleCall.Input) (before : Live.World) : Option AdmissionError :=
  if ctx.caller != ctx.depositSecurityModule then some .unauthorized
  else if DepositPhysicalAdmission.membership hash liveCtx.sender i.moduleId before = 0 then some .unregistered
  else if DepositPhysicalAdmission.status (DepositPhysicalAdmission.config hash liveCtx.sender i.moduleId before) ≥ 3 then some .invalidEnum
  else if DepositPhysicalAdmission.status (DepositPhysicalAdmission.config hash liveCtx.sender i.moduleId before) ≠ 0 then some .inactive
  else none

/-- Exact first-failing-guard predicate, including all preceding guards. -/
def Origin (hash : Keccak) (ctx : RouterDeposit.Context) (liveCtx : Live.Context)
    (i : ModuleCall.Input) (before : Live.World) (e : AdmissionError) : Prop :=
  let member := DepositPhysicalAdmission.membership hash liveCtx.sender i.moduleId before
  let status := DepositPhysicalAdmission.status (DepositPhysicalAdmission.config hash liveCtx.sender i.moduleId before)
  match e with
  | .unauthorized => ctx.caller ≠ ctx.depositSecurityModule
  | .unregistered => ctx.caller = ctx.depositSecurityModule ∧ member = 0
  | .invalidEnum => ctx.caller = ctx.depositSecurityModule ∧ member ≠ 0 ∧ 3 ≤ status
  | .inactive => ctx.caller = ctx.depositSecurityModule ∧ member ≠ 0 ∧ status < 3 ∧ status ≠ 0

theorem gate_origin (hash : Keccak) (ctx : RouterDeposit.Context) (liveCtx : Live.Context)
    (i : ModuleCall.Input) (before : Live.World) (e : AdmissionError)
    (h : gate hash ctx liveCtx i before = some e) : Origin hash ctx liveCtx i before e := by
  unfold gate at h
  split at h
  · cases h; simpa [Origin] using ‹(ctx.caller != ctx.depositSecurityModule) = true›
  · split at h
    · cases h; simp_all [Origin]
    · split at h
      · cases h; simp_all [Origin]
      · split at h
        · cases h; simp_all [Origin]
        · contradiction

structure Result where
  result : DepositDsmCall.Result
  localFailure : Option (TrioAlloc1.Address × AdmissionError)

def program (q : StaticCall.External) (locator : Live.Address) (cursor : Live.Word)
    (hash : Keccak) (m w : Live.External) (ctx : RouterDeposit.Context)
    (liveCtx : Live.Context) (i : ModuleCall.Input) (before : Live.World) : Result :=
  let looked := DepositDsmCall.lookup q liveCtx.sender locator cursor before
  match looked.outcome with
  | .error f => ⟨⟨.error f,before,[],looked.attempts⟩,none⟩
  | .ok dsm =>
    let resolved := DepositDsmCall.resolvedContext ctx dsm
    match gate hash resolved liveCtx i before with
    | some e => ⟨⟨.error (.bubbled (errorBytes e)),before,[],looked.attempts⟩,some (dsm,e)⟩
    | none =>
      let r := ModulePhysicalMetadata.program hash m w
        (DepositPhysicalAdmission.derivedContext hash resolved liveCtx.sender i.moduleId before) liveCtx i before
      ⟨⟨r.outcome,r.world,r.attempts,looked.attempts⟩,none⟩

def execute (q : StaticCall.External) (locator : Live.Address) (cursor : Live.Word)
    (hash : Keccak) (m w : Live.External) (ctx : RouterDeposit.Context)
    (liveCtx : Live.Context) (i : ModuleCall.Input) (before : Live.World) : Result :=
  let r := program q locator cursor hash m w ctx liveCtx i before
  match r.result.outcome with
  | .ok () => r
  | .error f => {r with result := ⟨.error f,before,r.result.attempts,r.result.locatorAttempts⟩}

/-- Successful gate inversion identifies the actual unchanged continuation. -/
theorem gate_none_program (hash : Keccak) (m w : Live.External) (ctx : RouterDeposit.Context)
    (liveCtx : Live.Context) (i : ModuleCall.Input) (before : Live.World)
    (h : gate hash ctx liveCtx i before = none) :
    DepositPhysicalAdmission.program hash m w ctx liveCtx i before =
      ModulePhysicalMetadata.program hash m w
        (DepositPhysicalAdmission.derivedContext hash ctx liveCtx.sender i.moduleId before) liveCtx i before := by
  unfold gate at h
  unfold DepositPhysicalAdmission.program
  split_ifs at h ⊢ <;> simp_all

/-- Equation for transporting actual nonempty executions; no callback rerun. -/
theorem execute_of_admitted_lookup (q : StaticCall.External) (locator : Live.Address) (cursor : Live.Word)
    (hash : Keccak) (m w : Live.External) (ctx : RouterDeposit.Context)
    (liveCtx : Live.Context) (i : ModuleCall.Input) (before : Live.World)
    (dsm : TrioAlloc1.Address) (trace : List Live.NestedAttempt)
    (hl : DepositDsmCall.lookup q liveCtx.sender locator cursor before = ⟨.ok dsm,trace⟩)
    (hg : gate hash (DepositDsmCall.resolvedContext ctx dsm) liveCtx i before = none) :
    execute q locator cursor hash m w ctx liveCtx i before =
      ⟨DepositDsmCall.execute q locator cursor hash m w ctx liveCtx i before,none⟩ := by
  have hp := gate_none_program hash m w (DepositDsmCall.resolvedContext ctx dsm) liveCtx i before hg
  unfold execute program DepositDsmCall.execute DepositDsmCall.program
  simp only [hl,hg,hp]
  split <;> simp_all

theorem success_projection (q : StaticCall.External) (locator : Live.Address) (cursor : Live.Word)
    (hash : Keccak) (m w : Live.External) (ctx : RouterDeposit.Context)
    (liveCtx : Live.Context) (i : ModuleCall.Input) (before : Live.World)
    (h : (execute q locator cursor hash m w ctx liveCtx i before).result.outcome = .ok ()) :
    (execute q locator cursor hash m w ctx liveCtx i before).localFailure = none ∧
    (execute q locator cursor hash m w ctx liveCtx i before).result =
      DepositDsmCall.execute q locator cursor hash m w ctx liveCtx i before := by
  unfold execute at h ⊢
  cases hl : DepositDsmCall.lookup q liveCtx.sender locator cursor before with
  | mk out trace =>
    cases out with
    | «error» f => simp [program,hl] at h
    | ok dsm =>
      cases hg : gate hash (DepositDsmCall.resolvedContext ctx dsm) liveCtx i before with
      | some e => simp [program,hl,hg] at h
      | none =>
        have hp := gate_none_program hash m w (DepositDsmCall.resolvedContext ctx dsm) liveCtx i before hg
        simp only [program,hl,hg] at h ⊢
        unfold DepositDsmCall.execute DepositDsmCall.program
        simp only [hl,hp]
        split at h <;> simp_all

def LocalRejection (q : StaticCall.External) (locator : Live.Address) (cursor : Live.Word)
    (hash : Keccak) (ctx : RouterDeposit.Context) (liveCtx : Live.Context)
    (i : ModuleCall.Input) (before : Live.World) (r : Result)
    (dsm : TrioAlloc1.Address) (e : AdmissionError) : Prop :=
  DepositDsmCall.lookup q liveCtx.sender locator cursor before = ⟨.ok dsm,r.result.locatorAttempts⟩ ∧
  Origin hash (DepositDsmCall.resolvedContext ctx dsm) liveCtx i before e ∧
  r.result.outcome = .error (.bubbled (errorBytes e)) ∧ r.result.world = before ∧ r.result.attempts = []

theorem local_rejection (q : StaticCall.External) (locator : Live.Address) (cursor : Live.Word)
    (hash : Keccak) (m w : Live.External) (ctx : RouterDeposit.Context)
    (liveCtx : Live.Context) (i : ModuleCall.Input) (before : Live.World)
    (dsm : TrioAlloc1.Address) (e : AdmissionError)
    (h : (execute q locator cursor hash m w ctx liveCtx i before).localFailure = some (dsm,e)) :
    LocalRejection q locator cursor hash ctx liveCtx i before
      (execute q locator cursor hash m w ctx liveCtx i before) dsm e := by
  unfold execute at h ⊢
  cases hl : DepositDsmCall.lookup q liveCtx.sender locator cursor before with
  | mk out trace =>
    cases out with
    | «error» f => simp [program,hl] at h
    | ok found =>
      cases hg : gate hash (DepositDsmCall.resolvedContext ctx found) liveCtx i before with
      | some fault =>
        simp only [program,hl,hg] at h ⊢
        cases h
        exact ⟨hl,gate_origin _ _ _ _ _ _ hg,rfl,rfl,rfl⟩
      | none =>
        simp only [program,hl,hg] at h
        split at h <;> contradiction

theorem failure_restores (q : StaticCall.External) (locator : Live.Address) (cursor : Live.Word)
    (hash : Keccak) (m w : Live.External) (ctx : RouterDeposit.Context)
    (liveCtx : Live.Context) (i : ModuleCall.Input) (before : Live.World) (f : Live.Fault)
    (h : (execute q locator cursor hash m w ctx liveCtx i before).result.outcome = .error f) :
    (execute q locator cursor hash m w ctx liveCtx i before).result.world = before := by
  unfold execute at h ⊢
  dsimp only at h ⊢
  split at h <;> simp_all

#print axioms gate_origin
#print axioms gate_none_program
#print axioms execute_of_admitted_lookup
#print axioms success_projection
#print axioms local_rejection
#print axioms failure_restores
end LidoSRv3.Audit.Source.DepositAdmissionErrors
