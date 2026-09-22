import LidoSRv3.Audit.Guarantees.PDeposit1DsmCall
import LidoSRv3.Audit.Guarantees.PAlloc1
import LidoSRv3.Audit.Source.TrioReserve1.Spending
import LidoSRv3.Audit.Source.TopupCredentialCall

/-!
# P-DEPOSIT-1 allocation views: available ETH and the allocation STATICCALL

The registered `actual_deposit_call_slot_success_and_revert` executes
`DepositAllocation.execute` with two free inputs: `available`, the
`depositableEther` word of `StakingRouter.deposit` (`StakingRouter.sol:951`,
`LIDO.getDepositableEther()`), and `oracle`, the static-call interpreter of
the allocation view (`_getModuleDepositAllocation`, `SRLib.sol:391-431`).

This module supplies both from executed calls:

* `lidoDepositableEther` is Lido's `getDepositableEther()` view
  (`Lido.sol:823-825`): `_getDepositableEther(_getBufferedEtherAllocation())`,
  where `getBufferedEtherAllocation` is the existing source-shaped body
  (`Lido.sol:605-616`: buffered ether, stored deposits reserve, and the
  withdrawal queue's `unfinalizedStETH()` read through the locator STATICCALL).
  It replies with the ABI word; as a `view` it returns no world.
* `readDepositableEther` is the router's STATICCALL to that view through the
  existing `lowLevelStaticCall` and the canonical word decoder
  (`TopupCredentialCall.decodeCredentials`) with a memory cursor.
* `execute` is `DepositAllocation.execute` with the view issued at its source
  position (after the DSM, membership and status checks, before the allocation
  view), the decoded word becoming `available`.
* `execute_effects`: every failure restores the entry world; a success exposes
  the Lido allocation `a` the view computed, `available = depositsReserve +
  unreserved` (`Lido.sol:831-833`), and the registered
  `DepositAllocation.Effects` at that `available`.
* `allocation_view_is_vm_execution`: the allocation-view producer `select`
  consumes, `getDepositAllocationsABI` over the router's physical words and the
  static-call oracle, is the Verity-VM allocation execution of P-ALLOC-1's
  `account_allocation_result` (`VerityParentResult.execute`) when the VM world
  is the router's frame of the entry world.

Not composed here: the origin of the memory cursors (explicit inputs, as in
the registered parent) and the deployed identities of Lido, the locator and
the queue (`A-RUNTIME-PROVENANCE`). The library call inside the allocation view
is the byte executor of `libraryThroughABI`, not compiled `DELEGATECALL`.

Pinned `lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`.
-/

set_option autoImplicit false

namespace LidoSRv3.Audit.Guarantees.PDeposit1AllocationViews
open Source Source.TrioReserve1 Source.TrioReserve1.Live
open Source.TrioAlloc1 (StaticOracle Config Layout)

/-- `getDepositableEther()` (`Lido.json` methodIdentifiers). -/
def depositableEtherSelector : Nat := 0xf2cfa87d

/-- Lido's view body: `_getDepositableEther(_getBufferedEtherAllocation())`
(`Lido.sol:823-825`), with the locator and queue reads of
`getBufferedEtherAllocation` executed through `nested`. A view returns no
world; a failed nested read rejects. Other requests go to `other`. -/
def lidoDepositableEther (nested : External) (lido : Address) (other : StaticCall.External) :
    StaticCall.External := fun req w =>
  if req.target = lido ∧ req.payload = encode 4 depositableEtherSelector then
    match (getBufferedEtherAllocation nested ⟨lido, req.caller⟩ w).outcome with
    | .ok a => .success (encode 32 (getDepositableEther a).val)
    | .error _ => .rejected []
  else other req w

structure ViewResult where
  outcome : Except Fault (Word × Word)
  attempts : List NestedAttempt

/-- The router's `LIDO.getDepositableEther()` STATICCALL (`StakingRouter.sol:951`)
and its canonical one-word decode at `cursor`. -/
def readDepositableEther (viewCall : StaticCall.External) (router lido : Address) (cursor : Word)
    (w : World) : ViewResult :=
  let r := audit.trio.consolidation.lowLevelStaticCall viewCall router lido
    (encode 4 depositableEtherSelector) w
  match r.outcome with
  | .error b => ⟨.error (.bubbled b), r.attempts⟩
  | .ok raw => ⟨TopupCredentialCall.decodeCredentials cursor raw, r.attempts⟩

/-- Live word to producer word, value-preserving. -/
def availableOf (v : Word) : TrioAlloc1.Word := TrioAlloc1.word v.val

theorem availableOf_val (v : Word) : (availableOf v).val = v.val := by
  show v.val % 2 ^ 256 = v.val
  exact Nat.mod_eq_of_lt v.isLt

structure Result where
  outcome : Except Fault Unit
  world : World
  attempts : List Attempt
  locatorAttempts : List NestedAttempt
  viewAttempts : List NestedAttempt
  allocationAttempts : TrioAlloc1.Transcript

/-- `DepositAllocation.execute` with the available-ETH view at its source
position: DSM lookup and authorization, module membership and status, then
`LIDO.getDepositableEther()`, then the allocation view and the suffix. -/
def execute (q viewCall : StaticCall.External) (locator lido : Address) (cursor viewCursor : Word)
    (hash : DepositAllocation.Keccak) (oracle : StaticOracle) (cfg : Config)
    (m w : External) (ctx : audit.trio.deposit.RouterDeposit.Context) (liveCtx : Context)
    (i : audit.trio.deposit.ModuleCall.Input) (before : World) : Result :=
  let lookup := DepositDsmCall.lookup q liveCtx.sender locator cursor before
  match lookup.outcome with
  | .error e => ⟨.error e, before, [], lookup.attempts, [], []⟩
  | .ok dsm =>
    let resolved := DepositDsmCall.resolvedContext ctx dsm
    if resolved.caller != resolved.depositSecurityModule then
      ⟨.error (.reason "NotAuthorized"), before, [], lookup.attempts, [], []⟩
    else if DepositPhysicalAdmission.membership hash liveCtx.sender i.moduleId before = 0 then
      ⟨.error (.reason "StakingModuleUnregistered"), before, [], lookup.attempts, [], []⟩
    else if DepositPhysicalAdmission.status
        (DepositPhysicalAdmission.config hash liveCtx.sender i.moduleId before) ≥ 3 then
      ⟨.error (.reason "Panic(0x21)"), before, [], lookup.attempts, [], []⟩
    else if DepositPhysicalAdmission.status
        (DepositPhysicalAdmission.config hash liveCtx.sender i.moduleId before) ≠ 0 then
      ⟨.error (.reason "StakingModuleNotActive"), before, [], lookup.attempts, [], []⟩
    else
      let viewRead := readDepositableEther viewCall liveCtx.sender lido viewCursor before
      match viewRead.outcome with
      | .error e => ⟨.error e, before, [], lookup.attempts, viewRead.attempts, []⟩
      | .ok (available, _) =>
        let allocated := DepositAllocation.select hash oracle cfg (availableOf available)
          i.moduleId liveCtx.sender before []
        match allocated.1 with
        | .error e =>
          ⟨.error (DepositAllocation.fault e), before, [], lookup.attempts, viewRead.attempts, allocated.2⟩
        | .ok amount =>
          let suffix := DepositPhysicalAdmission.execute hash m w resolved liveCtx
            (DepositAllocation.withAllocation i cfg amount) before
          ⟨suffix.outcome, suffix.world, suffix.attempts, lookup.attempts, viewRead.attempts, allocated.2⟩

/-- A successful view read came from Lido's body: the reply is the ABI word of
`getDepositableEther` on the allocation `getBufferedEtherAllocation` computed
on the entry world, and the decoded word is its value. -/
theorem view_success (nested : External) (lido : Address) (other : StaticCall.External)
    (router : Address) (cursor : Word) (w : World) (v next : Word)
    (h : (readDepositableEther (lidoDepositableEther nested lido other) router lido cursor w).outcome =
      .ok (v, next)) :
    ∃ a, (getBufferedEtherAllocation nested ⟨lido, router⟩ w).outcome = .ok a ∧
      v.val = (getDepositableEther a).val := by
  unfold readDepositableEther at h
  cases hr : (audit.trio.consolidation.lowLevelStaticCall (lidoDepositableEther nested lido other)
      router lido (encode 4 depositableEtherSelector) w).outcome with
  | «error» b => simp [hr] at h
  | ok raw =>
    simp only [hr] at h
    obtain ⟨hlen, hwc, -, -, -⟩ := TopupCredentialCall.decode_fields cursor raw v next h
    unfold audit.trio.consolidation.lowLevelStaticCall at hr
    by_cases hc : audit.trio.consolidation.emptyCodeAccount w lido
    · simp only [hc, if_true, Except.ok.injEq] at hr
      subst hr
      have h0 : (word ([] : Bytes).length).val = 0 := rfl
      rw [h0] at hlen
      omega
    · simp only [hc, if_false] at hr
      simp only [lidoDepositableEther, eq_self_iff_true, and_self, if_true] at hr
      cases ha : (getBufferedEtherAllocation nested ⟨lido, router⟩ w).outcome with
      | «error» e => simp [ha] at hr
      | ok a =>
        simp only [ha, Except.ok.injEq] at hr
        have hraw : raw = encode 32 (getDepositableEther a).val := hr.symm
        refine ⟨a, rfl, ?_⟩
        have hn : (getDepositableEther a).val < 256 ^ 32 :=
          Nat.lt_of_lt_of_eq (getDepositableEther a).isLt (by decide)
        have htake : (encode 32 (getDepositableEther a).val).take 32 =
            encode 32 (getDepositableEther a).val :=
          List.take_of_length_le (le_of_eq (ABI.encode_length 32 _))
        rw [hwc, hraw, htake, ABI.decode_encode_bounded 32 _ hn]
        exact Nat.mod_eq_of_lt (getDepositableEther a).isLt

/-- Success binds the DSM lookup, the available-ETH view, the allocation view
at the decoded word and the physical suffix; failure restores the entry world. -/
def Effects (q viewCall : StaticCall.External) (locator lido : Address) (cursor viewCursor : Word)
    (hash : DepositAllocation.Keccak) (oracle : StaticOracle) (cfg : Config)
    (m w : External) (ctx : audit.trio.deposit.RouterDeposit.Context) (liveCtx : Context)
    (i : audit.trio.deposit.ModuleCall.Input) (before : World) (r : Result) : Prop :=
  match r.outcome with
  | .error _ => r.world = before
  | .ok _ => ∃ dsm v next amount,
      DepositDsmCall.lookup q liveCtx.sender locator cursor before = ⟨.ok dsm, r.locatorAttempts⟩ ∧
      readDepositableEther viewCall liveCtx.sender lido viewCursor before = ⟨.ok (v, next), r.viewAttempts⟩ ∧
      DepositAllocation.select hash oracle cfg (availableOf v) i.moduleId liveCtx.sender before [] =
        (.ok amount, r.allocationAttempts) ∧
      DepositPhysicalAdmission.Effects hash m w (DepositDsmCall.resolvedContext ctx dsm)
        liveCtx (DepositAllocation.withAllocation i cfg amount) before r.world r.attempts

theorem execute_effects (q viewCall : StaticCall.External) (locator lido : Address)
    (cursor viewCursor : Word) (hash : DepositAllocation.Keccak) (oracle : StaticOracle)
    (cfg : Config) (m w : External) (ctx : audit.trio.deposit.RouterDeposit.Context) (liveCtx : Context)
    (i : audit.trio.deposit.ModuleCall.Input) (before : World) :
    Effects q viewCall locator lido cursor viewCursor hash oracle cfg m w ctx liveCtx i before
      (execute q viewCall locator lido cursor viewCursor hash oracle cfg m w ctx liveCtx i before) := by
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
            · cases hv : readDepositableEther viewCall liveCtx.sender lido viewCursor before with
              | mk vo vt =>
                cases vo with
                | «error» e => rfl
                | ok pair =>
                  rcases pair with ⟨v, next⟩
                  dsimp only
                  cases ha : DepositAllocation.select hash oracle cfg (availableOf v) i.moduleId
                      liveCtx.sender before [] with
                  | mk outcome allocatedTrace =>
                    cases outcome with
                    | «error» e => rfl
                    | ok amount =>
                      dsimp only
                      cases hs : DepositPhysicalAdmission.execute hash m w
                          (DepositDsmCall.resolvedContext ctx dsm) liveCtx
                          (DepositAllocation.withAllocation i cfg amount) before with
                      | mk outcome after attempts =>
                        cases outcome with
                        | «error» e =>
                          exact DepositPhysicalAdmission.failure_restores hash m w
                            (DepositDsmCall.resolvedContext ctx dsm) liveCtx
                            (DepositAllocation.withAllocation i cfg amount) before after attempts e hs
                        | ok value =>
                          cases value
                          exact ⟨dsm, v, next, amount, hq, hv, ha,
                            DepositPhysicalAdmission.success_effects hash m w
                              (DepositDsmCall.resolvedContext ctx dsm) liveCtx
                              (DepositAllocation.withAllocation i cfg amount) before after attempts hs⟩

/-- **Available ETH from Lido's view.** With Lido's `getDepositableEther`
view serving the router's STATICCALL, a successful deposit allocation
consumed `available = depositsReserve + unreserved` of the allocation
`getBufferedEtherAllocation` computed on the entry world (`Lido.sol:605-616`,
`:831-833`), and the registered effects hold at that `available`; every
failure restores the entry world. -/
theorem deposit_with_lido_view (q : StaticCall.External) (nested : External)
    (other : StaticCall.External) (locator lido : Address) (cursor viewCursor : Word)
    (hash : DepositAllocation.Keccak) (oracle : StaticOracle) (cfg : Config)
    (m w : External) (ctx : audit.trio.deposit.RouterDeposit.Context) (liveCtx : Context)
    (i : audit.trio.deposit.ModuleCall.Input) (before : World) :
    let r := execute q (lidoDepositableEther nested lido other) locator lido cursor viewCursor hash
      oracle cfg m w ctx liveCtx i before
    match r.outcome with
    | .error _ => r.world = before
    | .ok _ => ∃ dsm a v next amount,
        DepositDsmCall.lookup q liveCtx.sender locator cursor before = ⟨.ok dsm, r.locatorAttempts⟩ ∧
        (getBufferedEtherAllocation nested ⟨lido, liveCtx.sender⟩ before).outcome = .ok a ∧
        v.val = a.deposits + a.unreserved ∧
        readDepositableEther (lidoDepositableEther nested lido other) liveCtx.sender lido viewCursor
          before = ⟨.ok (v, next), r.viewAttempts⟩ ∧
        DepositAllocation.select hash oracle cfg (availableOf v) i.moduleId liveCtx.sender before [] =
          (.ok amount, r.allocationAttempts) ∧
        DepositPhysicalAdmission.Effects hash m w (DepositDsmCall.resolvedContext ctx dsm)
          liveCtx (DepositAllocation.withAllocation i cfg amount) before r.world r.attempts := by
  have he := execute_effects q (lidoDepositableEther nested lido other) locator lido cursor
    viewCursor hash oracle cfg m w ctx liveCtx i before
  unfold Effects at he
  dsimp only
  cases ho : (execute q (lidoDepositableEther nested lido other) locator lido cursor viewCursor hash
      oracle cfg m w ctx liveCtx i before).outcome with
  | «error» e =>
    rw [ho] at he
    exact he
  | ok u =>
    rw [ho] at he
    obtain ⟨dsm, v, next, amount, hq, hv, ha, hs⟩ := he
    obtain ⟨a, halloc, hval⟩ := view_success nested lido other liveCtx.sender viewCursor before v next
      (by rw [hv])
    refine ⟨dsm, a, v, next, amount, hq, halloc, ?_, hv, ha, hs⟩
    rw [hval]
    exact (Spending.allocation_bounds nested ⟨lido, liveCtx.sender⟩ before a halloc).2.2

/-- The router's physical words are the executing account's words of the
Verity world when that world is the router's frame of the entry world. -/
theorem physicalWords_eq_accountStorage (router : Address) (w : World)
    (h : w.core.thisAddress = router) :
    DepositAllocation.physicalWords router w = TrioAlloc1.VerityProducer.accountStorage w.core := by
  funext key
  unfold DepositAllocation.physicalWords TrioAlloc1.VerityProducer.accountStorage
  rw [h]
  apply Fin.ext
  exact Nat.mod_eq_of_lt (w.core.readContractSlot router.val key.val).isLt

/-- **The allocation view is the VM execution.** The producer
`DepositAllocation.select` consumes (`getDepositAllocationsABI` over the
router's physical words and the static-call oracle) is the Verity-VM
allocation execution of P-ALLOC-1's `account_allocation_result`
(`VerityParentResult.execute`), when the VM world is the router's frame of the
entry world and the oracle is its call adversary. -/
theorem allocation_view_is_vm_execution (hash : DepositAllocation.Keccak) (router : Address)
    (w : World) (adversary : Compiler.CompilationModel.DenoteExternalCalls.AdversaryModel)
    (state : Compiler.CompilationModel.DenoteExternalCalls.CallState) (cfg : Config)
    (available : TrioAlloc1.Word) (isTopUp : Bool) (t : TrioAlloc1.Transcript)
    (hstate : state.world = w.core) (hself : w.core.thisAddress = router) :
    TrioComposition.getDepositAllocationsABI (DepositAllocation.layout hash)
        (DepositAllocation.physicalWords router w)
        (TrioAlloc1.VerityProducer.sourceOracle adversary w.core) cfg available isTopUp t =
      (TrioComposition.VerityParentResult.execute (DepositAllocation.layout hash) cfg available
        isTopUp adversary state t).1 := by
  rw [physicalWords_eq_accountStorage router w hself, ← hstate]
  exact (TrioComposition.VerityParentResult.execute_correspondence _ cfg available isTopUp
    adversary state t).1.symm

#print axioms availableOf_val
#print axioms view_success
#print axioms execute_effects
#print axioms deposit_with_lido_view
#print axioms physicalWords_eq_accountStorage
#print axioms allocation_view_is_vm_execution

end LidoSRv3.Audit.Guarantees.PDeposit1AllocationViews
