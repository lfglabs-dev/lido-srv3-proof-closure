import LidoSRv3.Audit.Guarantees.PTopup1AllocationViews

/-! # P-TOPUP-1 / P-TOPUP-2 allocation views at their source position (caveat C2, 2026-09-19)

`PTopup1AllocationViews.run` produced `Input.allocation` from the two
allocation views but issued them before the gateway's own admission prefix.
The pinned `StakingRouter.topUp` (`StakingRouter.sol:687-714`) reads
`LIDO.getDepositableEther()` and `_getModuleDepositAllocation(_, _, true)`
inside the router body, after `_checkAppAuth`, `_validateTopUpInputs`, the
module status and the 0x02 credential-type check, and before the zero-target
`LIDO.canDeposit()` gate and the module CALL.

This module re-seats the views there. The registered router-body gates
`TopupRouterAdmissionCallGates.run` split into `statusChecks` (auth, input
validation, module state) and `zeroTargetGate` (the conditional
`canDeposit`), `gates_split` proving the split exact, attempts included.
`runSeated` walks the gateway prefix (`TopupRouterAdmissionCall.walk`), runs
`statusChecks`, then the views, then `zeroTargetGate` and the registered
`finish` at the produced allocation. Consequences:

* `success`: a committed seated run passed the prefix, the status checks and
  both views, and its outcome, world, projection and `Ready` seam are those
  of the registered `TopupRouterAdmissionCall.run` at the produced
  allocation, with `ActualEffects` there; the attempt trace is
  `status ++ views ++ zero-target`, the registered chain's
  `status ++ zero-target` with the views inserted at the source position.
* `failure`: every failing arm restores the entry world.
* `status_before_views`: when a status check fails the views are not
  evaluated, so the reported error and trace are the router's, exactly as
  in the source; `prefix_before_views`: a failing gateway prefix reports
  its own error with no view or router attempt.

The deposit chain (`PDeposit1AllocationViews.execute`) already issues its
view at the source position (after the DSM, membership and status checks,
before the allocation view) and needs no re-seating.

**Status:** real theorems with complete proofs; axioms `propext`,
`Classical.choice`, `Quot.sound`. -/

set_option autoImplicit false

namespace LidoSRv3.Audit.Guarantees.PTopup1AllocationViewsSeated
open Source Source.TrioReserve1 Source.TrioReserve1.Live
open Source.TopupRouterAdmissionCall (Input Ready selected moduleInput finish walk consume
  walk_relation)
open PTopup1AllocationViews (Views allocationView)
open Source.TopupRouterAdmissionCallGates (authLookup validateInputs physical canDeposit)

/-- `StakingRouter.sol:687-695`: `_checkAppAuth`, `_validateTopUpInputs`,
module state and credential type, before the views. -/
def statusChecks (g : TopupRouterAdmissionCallGates.Environment)
    (hash : TopupRouterCredentials.Keccak) (gateway : Address) (ctx : Context)
    (i : TopupModuleCall.Input) (w : World) : TopupRouterAdmissionCallGates.Result :=
  let a := authLookup g ctx.sender w
  match a.outcome with
  | .error f => ⟨.error f, a.attempts⟩
  | .ok (allowed, _) =>
    if gateway ≠ allowed then ⟨.error (.bubbled (encode 4 0xea8e4eb5)), a.attempts⟩ else
    match validateInputs i with
    | .error f => ⟨.error f, a.attempts⟩
    | .ok () =>
      match physical hash ctx.sender i.moduleId w with
      | .error f => ⟨.error f, a.attempts⟩
      | .ok () => ⟨.ok (), a.attempts⟩

/-- `StakingRouter.sol:712-714`: the zero-target `LIDO.canDeposit()` gate,
after the views. -/
def zeroTargetGate (g : TopupRouterAdmissionCallGates.Environment) (ctx : Context)
    (i : TopupModuleCall.Input) (w : World) : TopupRouterAdmissionCallGates.Result :=
  if i.roundedTarget.val = 0 then
    let c := canDeposit g ctx.sender ctx.self w
    match c.outcome with
    | .error f => ⟨.error f, c.attempts⟩
    | .ok (allowed, _) =>
      if allowed then ⟨.ok (), c.attempts⟩
      else ⟨.error (.bubbled (encode 4 0x5609c247)), c.attempts⟩
  else ⟨.ok (), []⟩

def seq (s z : TopupRouterAdmissionCallGates.Result) : TopupRouterAdmissionCallGates.Result :=
  match s.outcome with
  | .error f => ⟨.error f, s.attempts⟩
  | .ok () => ⟨z.outcome, s.attempts ++ z.attempts⟩

/-- The registered router-body gates are exactly the status checks followed by
the zero-target gate, attempts concatenated. -/
theorem gates_split (g : TopupRouterAdmissionCallGates.Environment)
    (hash : TopupRouterCredentials.Keccak) (gateway : Address) (ctx : Context)
    (i : TopupModuleCall.Input) (w : World) :
    TopupRouterAdmissionCallGates.run g hash gateway ctx i w =
      seq (statusChecks g hash gateway ctx i w) (zeroTargetGate g ctx i w) := by
  unfold TopupRouterAdmissionCallGates.run statusChecks zeroTargetGate seq
  cases ha : (authLookup g ctx.sender w).outcome with
  | «error» f => simp only [ha]
  | ok pr =>
    rcases pr with ⟨allowed, next⟩
    simp only [ha]
    by_cases hg : gateway ≠ allowed
    · simp only [if_pos hg]
    · simp only [if_neg hg]
      cases hv : validateInputs i with
      | «error» f => simp only [hv]
      | ok u =>
        cases u
        simp only [hv]
        cases hp : physical hash ctx.sender i.moduleId w with
        | «error» f => simp only [hp]
        | ok u =>
          cases u
          simp only [hp]
          by_cases hz : i.roundedTarget.val = 0
          · simp only [if_pos hz]
            cases hc : (canDeposit g ctx.sender ctx.self w).outcome with
            | «error» f => simp only [hc]
            | ok pr =>
              rcases pr with ⟨allowed', next'⟩
              simp only [hc]
              cases allowed' <;> simp
          · simp only [if_neg hz]
            simp

structure Result where
  admission : TopupRouterAdmissionCall.Result
  allocationAttempts : TrioAlloc1.Transcript

/-- A failing gateway prefix: the registered early result, no view attempt. -/
def early (i : Input) (f : TopupEntryAdmission.Error) (r : TopupEntryAdmission.Result) : Result :=
  ⟨⟨.error (.prior f), i.gateway.before, some r, [], none⟩, []⟩

/-- The router body at its source order: status checks, the two views, the
zero-target gate, then the registered `finish` at the produced allocation. -/
def body (g : TopupRouterAdmissionCallGates.Environment) (vw : Views) (i : Input) (p : Ready) :
    Result :=
  let s := statusChecks g i.hash i.gateway.gateway (selected i p) (moduleInput i p) i.gateway.before
  match s.outcome with
  | .error f => ⟨⟨.error (.admission f), i.gateway.before, none, s.attempts, some p⟩, []⟩
  | .ok () =>
    let v := allocationView vw p.router i.moduleId i.gateway.before
    match v.outcome with
    | .error e =>
      ⟨⟨.error (.admission e), i.gateway.before, none, s.attempts ++ v.viewAttempts, some p⟩,
        v.allocationAttempts⟩
    | .ok alloc =>
      let z := zeroTargetGate g (selected i p) (moduleInput {i with allocation := alloc} p)
        i.gateway.before
      match z.outcome with
      | .error f =>
        ⟨⟨.error (.admission f), i.gateway.before, none,
          s.attempts ++ v.viewAttempts ++ z.attempts, some p⟩, v.allocationAttempts⟩
      | .ok () =>
        let r := finish {i with allocation := alloc} p
        ⟨⟨r.outcome.mapError TopupRouterAdmissionCall.Error.prior, r.world, some r,
          s.attempts ++ v.viewAttempts ++ z.attempts, some p⟩, v.allocationAttempts⟩

/-- The registered admission entry with the views seated inside the router
body. -/
def runSeated (g : TopupRouterAdmissionCallGates.Environment) (vw : Views) (i : Input) : Result :=
  walk i (early i) (body g vw i)

/-- The `Ready` seam the gateway prefix reaches, if any. -/
def reached (i : Input) : Option Ready := walk i (fun _ _ => none) some

theorem reached_allocation (i : Input) (a : Word) : reached {i with allocation := a} = reached i :=
  rfl

theorem walk_of_reached {α : Type} (i : Input) {p : Ready} (hr : reached i = some p)
    (e : TopupEntryAdmission.Error → TopupEntryAdmission.Result → α) (f : Ready → α) :
    walk i e f = f p :=
  walk_relation i (fun _ _ => none) e some f (fun x y => x = some p → y = f p)
    (fun _ _ h => by cases h) (fun _ h => by cases h; rfl) hr

theorem walk_of_not_reached {α : Type} (i : Input) (hr : reached i = none)
    (e : TopupEntryAdmission.Error → TopupEntryAdmission.Result → α) (f : Ready → α) :
    ∃ fault r, walk i e f = e fault r :=
  walk_relation i (fun _ _ => none) e some f (fun x y => x = none → ∃ fault r, y = e fault r)
    (fun fault r _ => ⟨fault, r, rfl⟩) (fun _ h => by cases h) hr

theorem run_of_reached (g : TopupRouterAdmissionCallGates.Environment) (i : Input) {p : Ready}
    (hr : reached i = some p) : TopupRouterAdmissionCall.run g i = consume g i p :=
  walk_of_reached i hr _ _

/-- **Success.** A committed seated run passed the prefix, the status checks
and both views; its outcome, world, projection and seam are those of the
registered run at the produced allocation, with the registered
`ActualEffects`; the attempt trace is the registered `status ++ zero-target`
trace with the view attempts inserted at the source position. -/
theorem success (g : TopupRouterAdmissionCallGates.Environment) (vw : Views) (i : Input)
    (h : (runSeated g vw i).admission.outcome = .ok ()) :
    ∃ p alloc,
      reached i = some p ∧
      (allocationView vw p.router i.moduleId i.gateway.before).outcome = .ok alloc ∧
      (TopupRouterAdmissionCall.run g {i with allocation := alloc}).outcome = .ok () ∧
      (runSeated g vw i).admission.world =
        (TopupRouterAdmissionCall.run g {i with allocation := alloc}).world ∧
      (runSeated g vw i).admission.projection =
        (TopupRouterAdmissionCall.run g {i with allocation := alloc}).projection ∧
      (runSeated g vw i).admission.ready = some p ∧
      (runSeated g vw i).admission.admissionAttempts =
        (statusChecks g i.hash i.gateway.gateway (selected i p) (moduleInput i p)
          i.gateway.before).attempts ++
        (allocationView vw p.router i.moduleId i.gateway.before).viewAttempts ++
        (zeroTargetGate g (selected i p) (moduleInput {i with allocation := alloc} p)
          i.gateway.before).attempts ∧
      (TopupRouterAdmissionCall.run g {i with allocation := alloc}).admissionAttempts =
        (statusChecks g i.hash i.gateway.gateway (selected i p) (moduleInput i p)
          i.gateway.before).attempts ++
        (zeroTargetGate g (selected i p) (moduleInput {i with allocation := alloc} p)
          i.gateway.before).attempts ∧
      PTopupRouterAdmissionCall.ActualEffects g {i with allocation := alloc} := by
  cases hr : reached i with
  | none =>
    obtain ⟨fault, r, hw⟩ := walk_of_not_reached i hr (early i) (body g vw i)
    have hw' : runSeated g vw i = early i fault r := hw
    rw [hw'] at h
    simp [early] at h
  | some p =>
    have hw : runSeated g vw i = body g vw i p := walk_of_reached i hr (early i) (body g vw i)
    rw [hw] at h ⊢
    unfold body at h ⊢
    cases hs : (statusChecks g i.hash i.gateway.gateway (selected i p) (moduleInput i p)
        i.gateway.before).outcome with
    | «error» f => simp [hs] at h
    | ok u =>
      cases u
      simp only [hs] at h ⊢
      cases hv : (allocationView vw p.router i.moduleId i.gateway.before).outcome with
      | «error» e => simp [hv] at h
      | ok alloc =>
        simp only [hv] at h ⊢
        cases hz : (zeroTargetGate g (selected i p) (moduleInput {i with allocation := alloc} p)
            i.gateway.before).outcome with
        | «error» f => simp [hz] at h
        | ok u =>
          cases u
          simp only [hz] at h ⊢
          have hrun : TopupRouterAdmissionCall.run g {i with allocation := alloc} =
              consume g {i with allocation := alloc} p :=
            walk_of_reached {i with allocation := alloc} hr _ _
          have hs' : (statusChecks g ({i with allocation := alloc} : Input).hash ({i with allocation := alloc} : Input).gateway.gateway
              (selected ({i with allocation := alloc} : Input) p) (moduleInput ({i with allocation := alloc} : Input) p) ({i with allocation := alloc} : Input).gateway.before).outcome = .ok () := hs
          have hz' : (zeroTargetGate g (selected ({i with allocation := alloc} : Input) p) (moduleInput ({i with allocation := alloc} : Input) p)
              ({i with allocation := alloc} : Input).gateway.before).outcome = .ok () := hz
          have hcons : consume g ({i with allocation := alloc} : Input) p =
              ⟨(finish ({i with allocation := alloc} : Input) p).outcome.mapError TopupRouterAdmissionCall.Error.prior,
                (finish ({i with allocation := alloc} : Input) p).world, some (finish ({i with allocation := alloc} : Input) p),
                (statusChecks g ({i with allocation := alloc} : Input).hash ({i with allocation := alloc} : Input).gateway.gateway (selected ({i with allocation := alloc} : Input) p)
                  (moduleInput ({i with allocation := alloc} : Input) p) ({i with allocation := alloc} : Input).gateway.before).attempts ++
                (zeroTargetGate g (selected ({i with allocation := alloc} : Input) p) (moduleInput ({i with allocation := alloc} : Input) p)
                  ({i with allocation := alloc} : Input).gateway.before).attempts, some p⟩ := by
            unfold consume
            rw [gates_split]
            simp only [seq, hs', hz']
          refine ⟨p, alloc, rfl, hv, ?_, ?_, ?_, rfl, rfl, ?_, ?_⟩
          · rw [hrun, hcons] <;> exact h
          · rw [hrun, hcons] <;> rfl
          · rw [hrun, hcons] <;> rfl
          · rw [hrun, hcons] <;> rfl
          · exact PTopupRouterAdmissionCall.actual_router_admission_complete_prior g _
              (by rw [hrun, hcons] <;> exact h)

/-- **Failure.** Every failing arm, in the prefix, in a status check, in a
view, in the zero-target gate or in the registered finish, restores the
gateway's entry world. -/
theorem failure (g : TopupRouterAdmissionCallGates.Environment) (vw : Views) (i : Input)
    (f : TopupRouterAdmissionCall.Error) (h : (runSeated g vw i).admission.outcome = .error f) :
    (runSeated g vw i).admission.world = i.gateway.before := by
  cases hr : reached i with
  | none =>
    obtain ⟨fault, r, hw⟩ := walk_of_not_reached i hr (early i) (body g vw i)
    have hw' : runSeated g vw i = early i fault r := hw
    rw [hw']
    rfl
  | some p =>
    have hw : runSeated g vw i = body g vw i p := walk_of_reached i hr (early i) (body g vw i)
    rw [hw] at h ⊢
    unfold body at h ⊢
    cases hs : (statusChecks g i.hash i.gateway.gateway (selected i p) (moduleInput i p)
        i.gateway.before).outcome with
    | «error» f' => simp only [hs]
    | ok u =>
      cases u
      simp only [hs] at h ⊢
      cases hv : (allocationView vw p.router i.moduleId i.gateway.before).outcome with
      | «error» e => simp only [hv]
      | ok alloc =>
        simp only [hv] at h ⊢
        cases hz : (zeroTargetGate g (selected i p) (moduleInput {i with allocation := alloc} p)
            i.gateway.before).outcome with
        | «error» f' => simp only [hz]
        | ok u =>
          cases u
          simp only [hz] at h ⊢
          have hrun : TopupRouterAdmissionCall.run g {i with allocation := alloc} =
              consume g {i with allocation := alloc} p :=
            walk_of_reached {i with allocation := alloc} hr _ _
          have hs' : (statusChecks g ({i with allocation := alloc} : Input).hash ({i with allocation := alloc} : Input).gateway.gateway
              (selected ({i with allocation := alloc} : Input) p) (moduleInput ({i with allocation := alloc} : Input) p) ({i with allocation := alloc} : Input).gateway.before).outcome = .ok () := hs
          have hz' : (zeroTargetGate g (selected ({i with allocation := alloc} : Input) p) (moduleInput ({i with allocation := alloc} : Input) p)
              ({i with allocation := alloc} : Input).gateway.before).outcome = .ok () := hz
          have hcons : consume g ({i with allocation := alloc} : Input) p =
              ⟨(finish ({i with allocation := alloc} : Input) p).outcome.mapError TopupRouterAdmissionCall.Error.prior,
                (finish ({i with allocation := alloc} : Input) p).world, some (finish ({i with allocation := alloc} : Input) p),
                (statusChecks g ({i with allocation := alloc} : Input).hash ({i with allocation := alloc} : Input).gateway.gateway (selected ({i with allocation := alloc} : Input) p)
                  (moduleInput ({i with allocation := alloc} : Input) p) ({i with allocation := alloc} : Input).gateway.before).attempts ++
                (zeroTargetGate g (selected ({i with allocation := alloc} : Input) p) (moduleInput ({i with allocation := alloc} : Input) p)
                  ({i with allocation := alloc} : Input).gateway.before).attempts, some p⟩ := by
            unfold consume
            rw [gates_split]
            simp only [seq, hs', hz']
          have hfail := TopupRouterAdmissionCall.failure_restores g ({i with allocation := alloc} : Input) f
            (by rw [hrun, hcons] <;> exact h)
          rw [hrun, hcons] at hfail
          exact hfail

/-- **Source error order.** When a router status check fails, the seated run
reports that failure with the router's attempts only: the views are not
evaluated and no view or allocation attempt is recorded. -/
theorem status_before_views (g : TopupRouterAdmissionCallGates.Environment) (vw : Views)
    (i : Input) {p : Ready} (hr : reached i = some p) (f : Fault)
    (hs : (statusChecks g i.hash i.gateway.gateway (selected i p) (moduleInput i p)
      i.gateway.before).outcome = .error f) :
    runSeated g vw i = ⟨⟨.error (.admission f), i.gateway.before, none,
      (statusChecks g i.hash i.gateway.gateway (selected i p) (moduleInput i p)
        i.gateway.before).attempts, some p⟩, []⟩ := by
  have hw : runSeated g vw i = body g vw i p := walk_of_reached i hr (early i) (body g vw i)
  rw [hw]
  unfold body
  simp only [hs]

/-- A failing gateway prefix reports its own error with no router or view
attempt, exactly as the registered entry. -/
theorem prefix_before_views (g : TopupRouterAdmissionCallGates.Environment) (vw : Views)
    (i : Input) (hr : reached i = none) :
    (∃ fault r, runSeated g vw i = early i fault r) ∧
    (∃ fault r, TopupRouterAdmissionCall.run g i =
      ⟨.error (.prior fault), i.gateway.before, some r, [], none⟩) :=
  ⟨walk_of_not_reached i hr (early i) (body g vw i),
    walk_of_not_reached i hr
      (fun f r => (⟨.error (.prior f), i.gateway.before, some r, [], none⟩ :
        TopupRouterAdmissionCall.Result)) (consume g i)⟩

#print axioms gates_split
#print axioms success
#print axioms failure
#print axioms status_before_views
#print axioms prefix_before_views

end LidoSRv3.Audit.Guarantees.PTopup1AllocationViewsSeated
