import LidoSRv3.Audit.Guarantees.PReserve1LiveWriters
import LidoSRv3.Audit.Source.TrioReserve1.ACLPermission

/-!
# P-RESERVE-1 reserve-target setter: access control as an admission stage

The registered physical writer history (`PReserve1LiveWriters`) runs the
internal target writer `setDepositsReserveTarget` for `Action.target`. The
public setter `Lido.setDepositsReserveTarget` (`Lido.sol:656-660`) is
`_auth(BUFFER_RESERVE_MANAGER_ROLE)` (`:1389-1391`: `canPerform(msg.sender,
role, [])` through the Aragon kernel and ACL) followed by that writer.
`Aragon.setTarget` already models the guard: `canPerform` is an actual CALL
into the kernel address stored in Lido's `kernelSlot`, decoded to a word, and
the writer runs only when it is nonzero (`APP_AUTH_FAILED` otherwise).

This module composes that admission stage into the history as
`executeGuarded`: the target action is the guarded public setter, the other
actions are unchanged. `GuardedHistoryEffects` threads the returned worlds as
the registered history does; a successful target step exposes the accepted
`canPerform` reply and the writer specification on the kernel-returned world,
a failed one restores the entry world. The physical corollary instantiates
the kernel/ACL interpreter of `ACLCalls.external`, so denial and admission
follow from the stored permission graph (`ACLPermission.target_denied`,
`ACLPermission.target_allowed`).

The setter's ABI frame is a single `uint256` argument; its outer transport is
the shared source-shaped entry assumption, as for the other writers.

Pinned `lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`.

Binder names avoid the Verity DSL keywords (`slot`, `external`, `error`)
reserved by the `Compiler.Proofs` import of `PReserve1LiveWriters`.
-/

set_option autoImplicit false

namespace LidoSRv3.Audit.Guarantees.PReserve1TargetAdmission
open Source.TrioReserve1 Source.TrioReserve1.Live
open PReserve1LiveWriters (Action Effects HistoryEffects execute physicalExternal step_effects)

/-- A failed `Live.run` returns the entry world. -/
theorem run_failure_restores {α : Type} (program : Exec α) (w : World) (f : Fault)
    (h : (run program w).outcome = .error f) : (run program w).world = w := by
  unfold run at h ⊢
  cases hp : (program w).outcome with
  | «error» e => simp [hp]
  | ok a => simp [hp] at h

/-- The public setter: Aragon `_auth` through the kernel/ACL CALL, then the
internal writer. Every other action is the registered writer. -/
def executeGuarded (aclCallee callee : External) (ctx : Context) : Action → World → Result Unit
  | .target requested => run (Aragon.setTarget aclCallee ctx requested)
  | .rebalance => execute callee ctx .rebalance
  | .report input => execute callee ctx (.report input)
  | .withdraw amount seeds => execute callee ctx (.withdraw amount seeds)

/-- A successful guarded target write: the kernel CALL replied `true` on the
entry world and the writer specification holds on the kernel-returned world. -/
theorem target_success (aclCallee : External) (ctx : Context) (requested : Word) (before : World)
    (h : (run (Aragon.setTarget aclCallee ctx requested) before).outcome = .ok ()) :
    ∃ after trace,
      Aragon.canPerform aclCallee ctx Aragon.bufferReserveManagerRole before =
        ⟨.ok true, after, trace⟩ ∧
      WriterSpec.Target (Writers.project ctx after) requested.val
        (Writers.project ctx (run (Aragon.setTarget aclCallee ctx requested) before).world) := by
  cases hc : Aragon.canPerform aclCallee ctx Aragon.bufferReserveManagerRole before with
  | mk o after trace =>
    cases o with
    | «error» f =>
      have hf := Aragon.permission_failure aclCallee ctx requested before f (by simp [hc])
      rw [hf] at h
      simp at h
    | ok b =>
      cases b with
      | false =>
        rw [Aragon.denied aclCallee ctx requested before after trace hc] at h
        simp at h
      | true =>
        exact ⟨after, trace, rfl, Aragon.allowed aclCallee ctx requested before after trace hc⟩

/-- Denied permission: no write, the entry world, the kernel/ACL trace. -/
theorem target_denied (aclCallee callee : External) (ctx : Context) (requested : Word)
    (before after : World) (trace : List Attempt)
    (h : Aragon.canPerform aclCallee ctx Aragon.bufferReserveManagerRole before =
      ⟨.ok false, after, trace⟩) :
    executeGuarded aclCallee callee ctx (.target requested) before =
      ⟨.error (.reason "APP_AUTH_FAILED"), before, trace⟩ :=
  Aragon.denied aclCallee ctx requested before after trace h

/-- Guarded step postcondition: the registered effects for the writers, and for
the target action the admission reply plus the writer specification on
success or the entry world on failure. -/
def GuardedEffects (aclCallee callee : External) (ctx : Context) : Action → World → Prop
  | .target requested, before =>
    let r := run (Aragon.setTarget aclCallee ctx requested) before
    (r.outcome = .ok () →
      ∃ after trace,
        Aragon.canPerform aclCallee ctx Aragon.bufferReserveManagerRole before =
          ⟨.ok true, after, trace⟩ ∧
        WriterSpec.Target (Writers.project ctx after) requested.val (Writers.project ctx r.world)) ∧
    (∀ f, r.outcome = .error f → r.world = before)
  | .rebalance, before => Effects callee ctx .rebalance before
  | .report input, before => Effects callee ctx (.report input) before
  | .withdraw amount seeds, before => Effects callee ctx (.withdraw amount seeds) before

theorem guarded_step (aclCallee callee : External) (ctx : Context) (action : Action)
    (before : World) : GuardedEffects aclCallee callee ctx action before := by
  cases action with
  | target requested =>
    exact ⟨target_success aclCallee ctx requested before,
      fun f hf => run_failure_restores _ before f hf⟩
  | rebalance => exact step_effects callee ctx .rebalance before
  | report input => exact step_effects callee ctx (.report input) before
  | withdraw amount seeds => exact step_effects callee ctx (.withdraw amount seeds) before

/-- The guarded history threads each returned world into the next action. -/
def GuardedHistoryEffects (aclCallee callee : External) (ctx : Context) :
    List Action → World → Prop
  | [], _ => True
  | action :: rest, before =>
    GuardedEffects aclCallee callee ctx action before ∧
      GuardedHistoryEffects aclCallee callee ctx rest
        (executeGuarded aclCallee callee ctx action before).world

theorem actual_reserve_guarded_history (aclCallee callee : External) (ctx : Context) :
    ∀ (actions : List Action) (before : World),
      GuardedHistoryEffects aclCallee callee ctx actions before
  | [], _ => trivial
  | action :: rest, before =>
    ⟨guarded_step aclCallee callee ctx action before,
      actual_reserve_guarded_history aclCallee callee ctx rest _⟩

/-- **Registered-style corollary.** The physical writer history with the
public setter's role check: the target action is admitted through the actual
Lido→Kernel→ACL CALL interpreter (`ACLCalls.external`), every other action
uses the physical callee of `actual_reserve_physical_history`. -/
theorem actual_reserve_guarded_physical_history (c : Pipeline.Config)
    (staticOther : StaticCall.External) (other : External) (k : Queue.Keccak)
    (staticAcl : StaticCall.External) (kernel acl : Address) (fuel : Nat) (ctx : Context)
    (actions : List Action) (before : World) :
    GuardedHistoryEffects
      (ACLCalls.external k staticAcl kernel acl ctx Aragon.bufferReserveManagerRole fuel other)
      (physicalExternal c staticOther other) ctx actions before :=
  actual_reserve_guarded_history _ _ ctx actions before

/-- Physical denial: a stored permission graph evaluating to `false` for the
caller (and the wildcard entity) refuses the target write with
`APP_AUTH_FAILED`, the entry world and the Lido→Kernel→ACL attempt trace. -/
theorem physical_target_denied (k : Queue.Keccak) (staticAcl : StaticCall.External)
    (other callee : External) (ctx : Context) (requested : Word) (w : World)
    (trace : List NestedAttempt)
    (hi : Aragon.initialized ctx w = true) (hk : (Aragon.kernel ctx w).val ≠ 0)
    (hkc : (w.core.codeSize (Aragon.kernel ctx w).val).val ≠ 0)
    (ha : (Kernel.acl k (Aragon.kernel ctx w) w).val ≠ 0)
    (hac : (w.core.codeSize (Kernel.acl k (Aragon.kernel ctx w) w).val).val ≠ 0)
    (hs : ACLPermission.Describes k staticAcl (Kernel.acl k (Aragon.kernel ctx w) w)
      ctx Aragon.bufferReserveManagerRole [] w (.value false) trace) :
    ∃ fuel, ∀ extra,
      executeGuarded (ACLCalls.external k staticAcl (Aragon.kernel ctx w)
        (Kernel.acl k (Aragon.kernel ctx w) w) ctx Aragon.bufferReserveManagerRole (fuel + extra) other)
        callee ctx (.target requested) w =
      ⟨.error (.reason "APP_AUTH_FAILED"), w,
        ACLPermission.admissionTrace k ctx Aragon.bufferReserveManagerRole w false trace⟩ :=
  ACLPermission.target_denied k staticAcl other ctx requested w trace hi hk hkc ha hac hs

/-- Physical admission: a stored permission graph evaluating to `true` admits
the target write, and the writer specification holds. -/
theorem physical_target_allowed (k : Queue.Keccak) (staticAcl : StaticCall.External)
    (other callee : External) (ctx : Context) (requested : Word) (w : World)
    (trace : List NestedAttempt)
    (hi : Aragon.initialized ctx w = true) (hk : (Aragon.kernel ctx w).val ≠ 0)
    (hkc : (w.core.codeSize (Aragon.kernel ctx w).val).val ≠ 0)
    (ha : (Kernel.acl k (Aragon.kernel ctx w) w).val ≠ 0)
    (hac : (w.core.codeSize (Kernel.acl k (Aragon.kernel ctx w) w).val).val ≠ 0)
    (hs : ACLPermission.Describes k staticAcl (Kernel.acl k (Aragon.kernel ctx w) w)
      ctx Aragon.bufferReserveManagerRole [] w (.value true) trace) :
    ∃ fuel, ∀ extra, WriterSpec.Target (Writers.project ctx w) requested.val
      (Writers.project ctx (executeGuarded (ACLCalls.external k staticAcl (Aragon.kernel ctx w)
        (Kernel.acl k (Aragon.kernel ctx w) w) ctx Aragon.bufferReserveManagerRole (fuel + extra) other)
        callee ctx (.target requested) w).world) :=
  ACLPermission.target_allowed k staticAcl other ctx requested w trace hi hk hkc ha hac hs

#print axioms run_failure_restores
#print axioms target_success
#print axioms target_denied
#print axioms guarded_step
#print axioms actual_reserve_guarded_history
#print axioms actual_reserve_guarded_physical_history
#print axioms physical_target_denied
#print axioms physical_target_allowed

end LidoSRv3.Audit.Guarantees.PReserve1TargetAdmission
