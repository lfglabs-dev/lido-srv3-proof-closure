import LidoSRv3.Audit.Guarantees.PDeposit1AllocationViews
import LidoSRv3.Audit.Guarantees.PTopupRouterAdmissionCall

/-!
# P-TOPUP-1 / P-TOPUP-2 allocation views as the producer of `Input.allocation`

The registered admission entry `TopupRouterAdmissionCall.run` takes
`Input.allocation`, the router's `_getModuleDepositAllocation(_stakingModuleId,
depositableEther, true)` word (`StakingRouter.sol:697-700`), as an upstream
input. This module produces it from executed calls:

* `LIDO.getDepositableEther()` through the router's STATICCALL and Lido's view
  body (`PDeposit1AllocationViews.readDepositableEther`,
  `lidoDepositableEther`);
* `topupSelect`: `_getModuleDepositAllocation` with the top-up flag, i.e. the
  ABI producer `getDepositAllocationsABI` over the router's physical words and
  the static-call oracle, indexed by the module's membership position (the
  deposit path's `DepositAllocation.select` with `isTopUp = true`);
* `allocationView`: both, on the entry world; a failure of either aborts.

`run` composes them with the registered entry: the router address is the one
the locator lookup returns, the views are evaluated on the gateway's entry
world (the source admission prefix before the router call is read-only, so
the values agree), and the registered `TopupRouterAdmissionCall.run` executes
with the produced allocation. `success` derives the lookup, the view results
and the registered `ActualEffects` at the produced allocation; `failure`
restores the entry world for every failing arm, including a failed view call.

Ordering caveat, stated rather than hidden: the composed model issues the two
view calls before the gateway's own admission prefix (role, pause, lengths,
timing, credentials, roots) rather than inside the router's body after its
status checks. Both are read-only STATICCALLs, so only the reported error and
the attempt trace can differ when both the prefix and a view fail; the final
state on every failure is the entry world in both orders.

The ABI producer's library call is the byte executor of `libraryThroughABI`;
the gateway-to-router ABI CALL frame between the Verity model and the EVM is
implicit, as for every registered executable parent.

Pinned `lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`.
-/

set_option autoImplicit false

namespace LidoSRv3.Audit.Guarantees.PTopup1AllocationViews
open Source Source.TrioReserve1 Source.TrioReserve1.Live Source.TopupGatewayWitnessBatch
open PDeposit1AllocationViews (readDepositableEther availableOf lidoDepositableEther view_success)
open Source.TrioAlloc1 (StaticOracle Config)
open Source.TopupRouterAdmissionCall (Input)

/-- `_getModuleDepositAllocation(_stakingModuleId, depositableEther, true)`
(`StakingRouter.sol:700`, `SRLib.sol:391-431`): the deposit-path selector
`DepositAllocation.select` with the top-up flag. -/
def topupSelect (hash : DepositAllocation.Keccak) (oracle : StaticOracle) (cfg : Config)
    (available id : TrioAlloc1.Word) (router : Address) (world : World) :
    TrioAlloc1.Execution TrioAlloc1.Word := do
  let out ← TrioComposition.getDepositAllocationsABI (DepositAllocation.layout hash)
    (DepositAllocation.physicalWords router world) oracle cfg available true
  let index ← TrioAlloc1.liftChecked (TrioAlloc1.checkedSub
    (DepositPhysicalAdmission.membership hash router id world) 1)
  match out.allocated[index.val]? with
  | none => TrioAlloc1.failExec (.panic (TrioAlloc1.word 0x32))
  | some value => pure value

/-- The view interpreters and configuration of the two allocation views. -/
structure Views where
  viewCall : StaticCall.External
  lido : Address
  viewCursor : Word
  hash : DepositAllocation.Keccak
  oracle : StaticOracle
  cfg : Config

structure ViewOutcome where
  outcome : Except Fault Word
  viewAttempts : List NestedAttempt
  allocationAttempts : TrioAlloc1.Transcript

/-- `StakingRouter.sol:697-700` on one world: `LIDO.getDepositableEther()`,
then the allocation view; a failure of either aborts. -/
def allocationView (vw : Views) (router : Address) (moduleId : Word) (w : World) : ViewOutcome :=
  let r := readDepositableEther vw.viewCall router vw.lido vw.viewCursor w
  match r.outcome with
  | .error e => ⟨.error e, r.attempts, []⟩
  | .ok (available, _) =>
    let a := topupSelect vw.hash vw.oracle vw.cfg (availableOf available)
      (TrioAlloc1.word moduleId.val) router w []
    match a.1 with
    | .error e => ⟨.error (DepositAllocation.fault e), r.attempts, a.2⟩
    | .ok amount => ⟨.ok (word amount.val), r.attempts, a.2⟩

structure Result where
  admission : TopupRouterAdmissionCall.Result
  viewAttempts : List NestedAttempt
  allocationAttempts : TrioAlloc1.Transcript

/-- A failed view call reverts the top-up at the entry world. -/
def viewFailure (i : Input) (e : Fault) (viewAttempts : List NestedAttempt)
    (allocationAttempts : TrioAlloc1.Transcript) : Result :=
  ⟨⟨.error (.admission e), i.gateway.before, none, [], none⟩, viewAttempts, allocationAttempts⟩

/-- The registered admission entry with its allocation produced by the views:
the router is the locator's answer, the views run on the entry world, and
`TopupRouterAdmissionCall.run` executes at the produced allocation. -/
def run (g : TopupRouterAdmissionCallGates.Environment) (vw : Views) (i : Input) : Result :=
  match (TopupRouterLocatorCall.lookup i.locatorCall i.gateway.gateway i.locator i.cursor
      i.gateway.before).outcome with
  | .error _ => ⟨TopupRouterAdmissionCall.run g i, [], []⟩
  | .ok (router, _) =>
    let v := allocationView vw router i.moduleId i.gateway.before
    match v.outcome with
    | .error e => viewFailure i e v.viewAttempts v.allocationAttempts
    | .ok alloc =>
      ⟨TopupRouterAdmissionCall.run g {i with allocation := alloc}, v.viewAttempts,
        v.allocationAttempts⟩

/-- A successful registered run passed its locator lookup. -/
theorem run_ok_lookup (g : TopupRouterAdmissionCallGates.Environment) (i : Input)
    (h : (TopupRouterAdmissionCall.run g i).outcome = .ok ()) :
    ∃ router next, (TopupRouterLocatorCall.lookup i.locatorCall i.gateway.gateway i.locator
      i.cursor i.gateway.before).outcome = .ok (router, next) := by
  unfold TopupRouterAdmissionCall.run TopupRouterAdmissionCall.walk at h
  cases hg : TopupEntryAdmission.gates i.gateway.gateway i.caller i.gateway.before with
  | «error» f => simp [hg] at h
  | ok u =>
    cases u
    simp only [hg] at h
    cases hl : checkLengths (TopupBatchRootCalls.environment i.gateway).cfg i.rows.length
        i.keys.length i.operators.length i.rows.length i.rows.length with
    | «error» f => simp [hl] at h
    | ok u =>
      cases u
      simp only [hl] at h
      cases ht : TopupTimingHistory.gates i.gateway with
      | «error» f => simp [ht] at h
      | ok u =>
        cases u
        simp only [ht] at h
        cases hq : (TopupRouterLocatorCall.lookup i.locatorCall i.gateway.gateway i.locator
            i.cursor i.gateway.before).outcome with
        | «error» f => simp [hq] at h
        | ok pair =>
          rcases pair with ⟨router, next⟩
          exact ⟨router, next, rfl⟩

/-- A produced allocation came from the two views: the decoded available-ETH
word and the allocation view at that word. -/
theorem allocationView_success (vw : Views) (router : Address) (moduleId : Word) (w : World)
    (alloc : Word) (h : (allocationView vw router moduleId w).outcome = .ok alloc) :
    ∃ v next amount trace,
      (readDepositableEther vw.viewCall router vw.lido vw.viewCursor w).outcome = .ok (v, next) ∧
      topupSelect vw.hash vw.oracle vw.cfg (availableOf v) (TrioAlloc1.word moduleId.val) router w [] =
        (.ok amount, trace) ∧
      alloc = word amount.val := by
  unfold allocationView at h
  cases hr : (readDepositableEther vw.viewCall router vw.lido vw.viewCursor w).outcome with
  | «error» e => simp [hr] at h
  | ok pair =>
    rcases pair with ⟨v, next⟩
    simp only [hr] at h
    cases ha : topupSelect vw.hash vw.oracle vw.cfg (availableOf v) (TrioAlloc1.word moduleId.val)
        router w [] with
    | mk outcome trace =>
      cases outcome with
      | «error» e => simp [ha] at h
      | ok amount =>
        simp only [ha, Except.ok.injEq] at h
        exact ⟨v, next, amount, trace, rfl, ha, h.symm⟩

/-- **Success.** The locator answered the router, both views succeeded on the
entry world, the composed result is the registered run at the produced
allocation, and the registered `ActualEffects` hold there. -/
theorem success (g : TopupRouterAdmissionCallGates.Environment) (vw : Views) (i : Input)
    (h : (run g vw i).admission.outcome = .ok ()) :
    ∃ router next alloc,
      (TopupRouterLocatorCall.lookup i.locatorCall i.gateway.gateway i.locator i.cursor
        i.gateway.before).outcome = .ok (router, next) ∧
      (allocationView vw router i.moduleId i.gateway.before).outcome = .ok alloc ∧
      (run g vw i).admission = TopupRouterAdmissionCall.run g {i with allocation := alloc} ∧
      PTopupRouterAdmissionCall.ActualEffects g {i with allocation := alloc} := by
  unfold run at h ⊢
  cases hq : (TopupRouterLocatorCall.lookup i.locatorCall i.gateway.gateway i.locator i.cursor
      i.gateway.before).outcome with
  | «error» f =>
    simp only [hq] at h
    obtain ⟨router, next, hl⟩ := run_ok_lookup g i h
    rw [hq] at hl
    cases hl
  | ok pair =>
    rcases pair with ⟨router, next⟩
    simp only [hq] at h ⊢
    cases hv : (allocationView vw router i.moduleId i.gateway.before).outcome with
    | «error» e =>
      simp only [hv] at h
      simp [viewFailure] at h
    | ok alloc =>
      simp only [hv] at h ⊢
      exact ⟨router, next, alloc, rfl, hv, rfl,
        PTopupRouterAdmissionCall.actual_router_admission_complete_prior g _ h⟩

/-- **Failure.** Every failing arm, including a failed view call, returns the
gateway's entry world. -/
theorem failure (g : TopupRouterAdmissionCallGates.Environment) (vw : Views) (i : Input)
    (f : TopupRouterAdmissionCall.Error) (h : (run g vw i).admission.outcome = .error f) :
    (run g vw i).admission.world = i.gateway.before := by
  unfold run at h ⊢
  cases hq : (TopupRouterLocatorCall.lookup i.locatorCall i.gateway.gateway i.locator i.cursor
      i.gateway.before).outcome with
  | «error» e =>
    simp only [hq] at h ⊢
    exact TopupRouterAdmissionCall.failure_restores g i f h
  | ok pair =>
    rcases pair with ⟨router, next⟩
    simp only [hq] at h ⊢
    cases hv : (allocationView vw router i.moduleId i.gateway.before).outcome with
    | «error» e =>
      simp only [hv]
      rfl
    | ok alloc =>
      simp only [hv] at h ⊢
      exact TopupRouterAdmissionCall.failure_restores g _ f h

/-- With Lido's `getDepositableEther` view serving the router's STATICCALL, a
successful composed run consumed `available = depositsReserve + unreserved`
of the allocation Lido computed on the entry world (`Lido.sol:605-616`). -/
theorem success_with_lido_view (g : TopupRouterAdmissionCallGates.Environment)
    (nested : External) (other : StaticCall.External) (lido : Address) (viewCursor : Word)
    (hash : DepositAllocation.Keccak) (oracle : StaticOracle) (cfg : Config) (i : Input)
    (h : (run g ⟨lidoDepositableEther nested lido other, lido, viewCursor, hash, oracle,
      cfg⟩ i).admission.outcome = .ok ()) :
    ∃ router next a v amount trace,
      (TopupRouterLocatorCall.lookup i.locatorCall i.gateway.gateway i.locator i.cursor
        i.gateway.before).outcome = .ok (router, next) ∧
      (getBufferedEtherAllocation nested ⟨lido, router⟩ i.gateway.before).outcome = .ok a ∧
      v.val = a.deposits + a.unreserved ∧
      topupSelect hash oracle cfg (availableOf v) (TrioAlloc1.word i.moduleId.val) router
        i.gateway.before [] = (.ok amount, trace) ∧
      PTopupRouterAdmissionCall.ActualEffects g {i with allocation := word amount.val} := by
  obtain ⟨router, next, alloc, hq, hv, -, he⟩ := success g _ i h
  obtain ⟨v, vnext, amount, trace, hr, hs, halloc⟩ :=
    allocationView_success ⟨lidoDepositableEther nested lido other, lido, viewCursor, hash, oracle, cfg⟩
      router i.moduleId i.gateway.before alloc hv
  obtain ⟨a, ha, hval⟩ := view_success nested lido other router viewCursor i.gateway.before v vnext hr
  subst halloc
  refine ⟨router, next, a, v, amount, trace, hq, ha, ?_, hs, he⟩
  rw [hval]
  exact (Spending.allocation_bounds nested ⟨lido, router⟩ i.gateway.before a ha).2.2

/-- The top-up allocation view is the Verity-VM allocation execution of
P-ALLOC-1's `account_allocation_result` with the top-up flag. -/
theorem topup_view_is_vm_execution (hash : DepositAllocation.Keccak) (router : Address)
    (w : World) (adversary : Compiler.CompilationModel.DenoteExternalCalls.AdversaryModel)
    (state : Compiler.CompilationModel.DenoteExternalCalls.CallState) (cfg : Config)
    (available : TrioAlloc1.Word) (t : TrioAlloc1.Transcript)
    (hstate : state.world = w.core) (hself : w.core.thisAddress = router) :
    TrioComposition.getDepositAllocationsABI (DepositAllocation.layout hash)
        (DepositAllocation.physicalWords router w)
        (TrioAlloc1.VerityProducer.sourceOracle adversary w.core) cfg available true t =
      (TrioComposition.VerityParentResult.execute (DepositAllocation.layout hash) cfg available
        true adversary state t).1 :=
  PDeposit1AllocationViews.allocation_view_is_vm_execution hash router w adversary state cfg
    available true t hstate hself

#print axioms run_ok_lookup
#print axioms allocationView_success
#print axioms success
#print axioms failure
#print axioms success_with_lido_view
#print axioms topup_view_is_vm_execution

end LidoSRv3.Audit.Guarantees.PTopup1AllocationViews
