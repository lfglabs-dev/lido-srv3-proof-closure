import LidoSRv3.Audit.Source.DepositDsmCall
import LidoSRv3.Audit.Source.TrioComposition.ParentABI

/-! Execute the missing allocation stage after DSM/physical admission and before
obtainDepositData. Available ether, constructor config, phase memory cursors and
allocation STATICCALL realization are still explicit boundaries. The selected
module amount is produced, never supplied as a desired allocation. -/
namespace LidoSRv3.Audit.Source.DepositAllocation
set_option autoImplicit false
open TrioReserve1 audit.trio.deposit
abbrev Keccak := DepositDsmCall.Keccak

def layout (hash : Keccak) : TrioAlloc1.Layout :=
  { routerSlot := TrioAlloc1.word TopupRouterCredentials.routerRoot
    keccak := fun bytes => TrioAlloc1.word (hash (bytes.map (fun b => UInt8.ofNat b.val))).val }

def physicalWords (router : Live.Address) (world : Live.World) : TrioAlloc1.Storage :=
  fun key => TrioAlloc1.word (world.core.readContractSlot router.val key.val).val

/-- `_getModuleDepositAllocation` executes the whole allocation before reading
its one-based membership position, checked subtracting one, and indexing. -/
def select (hash : Keccak) (oracle : TrioAlloc1.StaticOracle)
    (cfg : TrioAlloc1.Config) (available id : TrioAlloc1.Word)
    (router : Live.Address) (world : Live.World) : TrioAlloc1.Execution TrioAlloc1.Word := do
  let out ← TrioComposition.getDepositAllocationsABI (layout hash) (physicalWords router world)
    oracle cfg available false
  let index ← TrioAlloc1.liftChecked (TrioAlloc1.checkedSub
    (DepositPhysicalAdmission.membership hash router id world) 1)
  match out.allocated[index.val]? with
  | none => TrioAlloc1.failExec (.panic (TrioAlloc1.word 0x32))
  | some value => pure value

def fault : TrioAlloc1.Failure → Live.Fault
  | .revertData data => .bubbled (data.map (fun b => UInt8.ofNat b.val))
  | .panic code => .bubbled (Live.encode 4 0x4e487b71 ++ Live.encode 32 code.val)
  | .decoderFailure | .exceptionalCall => .empty

structure Result where
  outcome : Except Live.Fault Unit
  world : Live.World
  attempts : List Live.Attempt
  locatorAttempts : List Live.NestedAttempt
  allocationAttempts : TrioAlloc1.Transcript

def withAllocation (i : ModuleCall.Input) (cfg : TrioAlloc1.Config)
    (amount : TrioAlloc1.Word) : ModuleCall.Input :=
  { i with selected := amount, maxEB := cfg.maxEBType1 }

/-- Pure admission guards are rechecked by the old suffix but no external call
is repeated. Allocation runs only after the source-ordered admission prefix. -/
def execute (q : StaticCall.External) (locator : Live.Address) (cursor : Live.Word)
    (hash : Keccak) (oracle : TrioAlloc1.StaticOracle) (cfg : TrioAlloc1.Config)
    (available : TrioAlloc1.Word) (m w : Live.External) (ctx : RouterDeposit.Context)
    (liveCtx : Live.Context) (i : ModuleCall.Input) (before : Live.World) : Result :=
  let lookup := DepositDsmCall.lookup q liveCtx.sender locator cursor before
  match lookup.outcome with
  | .error e => ⟨.error e,before,[],lookup.attempts,[]⟩
  | .ok dsm =>
    let resolved := DepositDsmCall.resolvedContext ctx dsm
    if resolved.caller != resolved.depositSecurityModule then
      ⟨.error (.reason "NotAuthorized"),before,[],lookup.attempts,[]⟩
    else if DepositPhysicalAdmission.membership hash liveCtx.sender i.moduleId before = 0 then
      ⟨.error (.reason "StakingModuleUnregistered"),before,[],lookup.attempts,[]⟩
    else if DepositPhysicalAdmission.status (DepositPhysicalAdmission.config hash liveCtx.sender i.moduleId before) ≥ 3 then
      ⟨.error (.reason "Panic(0x21)"),before,[],lookup.attempts,[]⟩
    else if DepositPhysicalAdmission.status (DepositPhysicalAdmission.config hash liveCtx.sender i.moduleId before) ≠ 0 then
      ⟨.error (.reason "StakingModuleNotActive"),before,[],lookup.attempts,[]⟩
    else
      let allocated := select hash oracle cfg available i.moduleId liveCtx.sender before []
      match allocated.1 with
      | .error e => ⟨.error (fault e),before,[],lookup.attempts,allocated.2⟩
      | .ok amount =>
        let suffix := DepositPhysicalAdmission.execute hash m w resolved liveCtx
          (withAllocation i cfg amount) before
        ⟨suffix.outcome,suffix.world,suffix.attempts,lookup.attempts,allocated.2⟩

/-- Success binds the actual selected allocation and transcript to the exact
physical module/metadata/per-key suffix commitment. Failure restores entry. -/
def Effects (q : StaticCall.External) (locator : Live.Address) (cursor : Live.Word)
    (hash : Keccak) (oracle : TrioAlloc1.StaticOracle) (cfg : TrioAlloc1.Config)
    (available : TrioAlloc1.Word) (m w : Live.External) (ctx : RouterDeposit.Context)
    (liveCtx : Live.Context) (i : ModuleCall.Input) (before : Live.World) (r : Result) : Prop :=
  match r.outcome with
  | .error _ => r.world = before
  | .ok _ => ∃ dsm amount,
      DepositDsmCall.lookup q liveCtx.sender locator cursor before = ⟨.ok dsm,r.locatorAttempts⟩ ∧
      select hash oracle cfg available i.moduleId liveCtx.sender before [] =
        (.ok amount,r.allocationAttempts) ∧
      DepositPhysicalAdmission.Effects hash m w (DepositDsmCall.resolvedContext ctx dsm)
        liveCtx (withAllocation i cfg amount) before r.world r.attempts

theorem execute_effects (q : StaticCall.External) (locator : Live.Address) (cursor : Live.Word)
    (hash : Keccak) (oracle : TrioAlloc1.StaticOracle) (cfg : TrioAlloc1.Config)
    (available : TrioAlloc1.Word) (m w : Live.External) (ctx : RouterDeposit.Context)
    (liveCtx : Live.Context) (i : ModuleCall.Input) (before : Live.World) :
    Effects q locator cursor hash oracle cfg available m w ctx liveCtx i before
      (execute q locator cursor hash oracle cfg available m w ctx liveCtx i before) := by
  unfold execute
  cases hq : DepositDsmCall.lookup q liveCtx.sender locator cursor before with
  | mk outcome trace =>
    cases outcome with
    | «error» e => rfl
    | ok dsm =>
      dsimp only
      split
      · rfl
      · split
        · rfl
        · split
          · rfl
          · split
            · rfl
            · cases ha : select hash oracle cfg available i.moduleId liveCtx.sender before [] with
              | mk outcome allocatedTrace =>
                cases outcome with
                | «error» e => rfl
                | ok amount =>
                  dsimp only
                  cases hs : DepositPhysicalAdmission.execute hash m w
                    (DepositDsmCall.resolvedContext ctx dsm) liveCtx (withAllocation i cfg amount) before with
                  | mk outcome after attempts =>
                    cases outcome with
                    | «error» e =>
                      exact DepositPhysicalAdmission.failure_restores hash m w
                        (DepositDsmCall.resolvedContext ctx dsm) liveCtx (withAllocation i cfg amount)
                        before after attempts e hs
                    | ok value =>
                      cases value
                      exact ⟨dsm,amount,hq,ha,DepositPhysicalAdmission.success_effects hash m w
                        (DepositDsmCall.resolvedContext ctx dsm) liveCtx (withAllocation i cfg amount)
                        before after attempts hs⟩

/-- A reached allocation failure is terminal, including decoder failures and
checked arithmetic failures. This records the complete result, not just rollback:
no module/withdrawal/beacon CALL is issued and both preceding transcripts survive.
The premises describe the executed prefix and allocation, never a desired result. -/
def AllocationFailureStops (q : StaticCall.External) (locator : Live.Address)
    (cursor : Live.Word) (hash : Keccak) (oracle : TrioAlloc1.StaticOracle)
    (cfg : TrioAlloc1.Config) (available : TrioAlloc1.Word) (m w : Live.External)
    (ctx : RouterDeposit.Context) (liveCtx : Live.Context) (i : ModuleCall.Input)
    (before : Live.World) : Prop :=
  ∀ dsm staticTrace e allocationTrace,
    DepositDsmCall.lookup q liveCtx.sender locator cursor before = ⟨.ok dsm,staticTrace⟩ →
    ctx.caller = dsm →
    DepositPhysicalAdmission.membership hash liveCtx.sender i.moduleId before ≠ 0 →
    DepositPhysicalAdmission.status
      (DepositPhysicalAdmission.config hash liveCtx.sender i.moduleId before) = 0 →
    select hash oracle cfg available i.moduleId liveCtx.sender before [] =
      (.error e,allocationTrace) →
    execute q locator cursor hash oracle cfg available m w ctx liveCtx i before =
      ⟨.error (fault e),before,[],staticTrace,allocationTrace⟩

theorem allocation_failure_stops (q : StaticCall.External) (locator : Live.Address)
    (cursor : Live.Word) (hash : Keccak) (oracle : TrioAlloc1.StaticOracle)
    (cfg : TrioAlloc1.Config) (available : TrioAlloc1.Word) (m w : Live.External)
    (ctx : RouterDeposit.Context) (liveCtx : Live.Context) (i : ModuleCall.Input)
    (before : Live.World) :
    AllocationFailureStops q locator cursor hash oracle cfg available m w ctx liveCtx i before := by
  intro dsm staticTrace e allocationTrace lookup authorized member active allocated
  simp [execute, lookup, DepositDsmCall.resolvedContext, authorized, member, active, allocated]

#print axioms execute_effects
end LidoSRv3.Audit.Source.DepositAllocation
