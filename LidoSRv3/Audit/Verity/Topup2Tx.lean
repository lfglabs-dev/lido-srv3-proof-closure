import LidoSRv3.Audit.Source.Topup2Correspondence
import Verity.Core.Model.DenoteExternalCalls
import Verity.Core.Model.CallProgramRollback

/-!
# P-TOPUP-2 bounded transaction plane over the adversary-quantified call model

The gateway's value-bearing top-up calls are bound to the pinned Verity
compilation model's external-call boundary
(`Compiler.CompilationModel.DenoteExternalCalls`), the same boundary used by
the P-TOPUP-1 `TopupRollback` refinement: each call site carries its wei
`value`, an explicit `AdversaryModel` chooses every callee response and state
transition, and the theorems below quantify over all adversaries and initial
call states.

This module deliberately does **not** use `Contracts.Common.externalCallBind`:
at Verity pin `04729a9` that combinator is `pure ()`, so declared external
calls bound through it have no semantics — a `Contract.run` suffix built on it
observes no call, no value movement, and no callee effect, and a conservation
statement over it would be vacuous.  Here, by contrast:

* the observed call trace (`CallsIn`) is a genuine prefix of the planned
  value-bearing sites, and its aggregate wei value is bounded by the block cap
  for every adversary (`tx_aggregate_bounded_by_block_cap`), with exact
  conservation on fully successful runs (`tx_all_success_value_exact`);
* a transaction-level revert restores the exact initial world
  (`tx_revert_restores_world`), and a fully successful run commits exactly the
  fold of the adversary's per-site transitions
  (`tx_committed_world_is_commit_fold`).

**Retracted claim (failed-call provenance).**  This module previously carried
`tx_revert_has_failed_call`, asserting that "every transaction revert
originates from an actually observed failed or reverting call carrying the same
returndata".  Its conclusion was `∃ obs : CallObservation, ...`, with `obs`
unconstrained by the program, the adversary, the initial state, or the revert
hypothesis, so it was discharged by fabricating an observation and carried no
information about the executed call program.  It is removed rather than
restated.  The residual honest content is `gateway_abort_is_failed_call`, which
constrains a *given* observation.

Restoring the claim requires upstream work: at pin `04729a9` the supporting
lemma `forEachCall_revert_step_abort` has the same unconstrained existential,
and `ObservedCall` records only `site`/`preWorld` — not the gas and returndata
needed to rebuild the observation — so membership of the aborting observation
in `ObservedCalls` cannot even be stated against this pin.

**Scope of the plane.**  Avoiding `externalCallBind` also means this plane is
not a `Contract.run` observation: `gatewayCallProgram` is an abstract
`CallProgram` built directly from the source transition `execute batch cfg`, so
it constrains the modelled call schedule rather than an executed contract.  The
executed-program binding that P-ALLOC-1 obtains via
`Verity.AllocCapacityPhase3.executeObservedSummary` — a `Contract.run`
observation over a real `writeSlot` store that never routes through
`externalCallBind` — has no counterpart here.

The runtime-provenance witness remains an input of this historical bounded
theorem, but it is not a general closure gate. The active registry classifies
this evidence as PARTIAL until a real Contract.run entrypoint binds target,
kind, calldata, per-validator granularity, and same-run failure membership.
-/

namespace LidoSRv3.Audit.Verity.Topup2Tx

open Compiler.CompilationModel.DenoteExternalCalls
open LidoSRv3.Audit.Guarantees.PTopup2
open LidoSRv3.Audit.Source.Topup2

/-- Canonical beacon deposit contract, as in the P-TOPUP-1 call plane. -/
def beaconDepositAddress : Nat := 0x00000000219ab540356cBB839Cbe05303d7705Fa

/-- One value-bearing top-up call: `amount` gwei forwarded as wei. -/
def topUpSite (index amount : Nat) : CallSite :=
  { siteId := index, kind := .call, target := beaconDepositAddress,
    value := amount * GWEI, calldata := [], gas := _root_.Verity.Core.MAX_UINT256 }

/-- The gateway's planned call schedule for the budget-consumed allocations. -/
def plannedSites : Nat → List Nat → List CallSite
  | _, [] => []
  | index, amount :: rest => topUpSite index amount :: plannedSites (index + 1) rest

/-- Aggregate wei value carried by a list of call sites. -/
def valueSum (sites : List CallSite) : Nat := (sites.map (·.value)).sum

@[simp] theorem topUpSite_value (index amount : Nat) :
    (topUpSite index amount).value = amount * GWEI := rfl

@[simp] theorem valueSum_nil : valueSum [] = 0 := rfl

@[simp] theorem valueSum_cons (site : CallSite) (rest : List CallSite) :
    valueSum (site :: rest) = site.value + valueSum rest := by
  simp [valueSum]

@[simp] theorem denoteCall_result (adversary : AdversaryModel) (site : CallSite)
    (state : CallState) :
    (denoteCall adversary site state).result = adversary.result site state.world := rfl

/-- The gateway tolerates nothing: any failed or reverting top-up call aborts
the enclosing transaction with the callee's returndata. -/
def gatewayPolicy (obs : CallObservation) : LoopStep Unit :=
  if obs.result.succeeded then .next else .abort obs.result.returndata

/-- The P-TOPUP-2 transaction program: iterate the planned value-bearing calls
for the pinned budget-consuming transition, aborting on the first failure. -/
def gatewayCallProgram (batch : TopupBatch) (cfg : TopupConfig) :
    CallProgram (TransactionResult Unit) :=
  forEachCall gatewayPolicy () (plannedSites 0 (execute batch cfg))

theorem plannedSites_value_sum (index : Nat) (amounts : List Nat) :
    valueSum (plannedSites index amounts) = amounts.sum * GWEI := by
  induction amounts generalizing index with
  | nil => simp [plannedSites]
  | cons amount rest ih => simp [plannedSites, ih (index + 1), Nat.add_mul]

theorem valueSum_take_le (sites : List CallSite) (n : Nat) :
    valueSum (sites.take n) ≤ valueSum sites := by
  induction sites generalizing n with
  | nil => simp
  | cons site rest ih =>
      cases n with
      | zero => exact Nat.zero_le _
      | succ n =>
          simpa [List.take_succ_cons] using Nat.add_le_add_left (ih n) site.value

/-- Under the gateway policy, a run in which every observed call succeeds
performs exactly the planned call schedule. -/
theorem callsIn_all_success_eq_planned (sites : List CallSite)
    (adversary : AdversaryModel) (state : CallState)
    (h : ∀ entry ∈ ObservedCalls (forEachCall gatewayPolicy () sites) adversary state,
      Succeeds adversary entry) :
    CallsIn (forEachCall gatewayPolicy () sites) adversary state = sites := by
  induction sites generalizing state with
  | nil => rfl
  | cons site rest ih =>
      have hhead : Succeeds adversary { site := site, preWorld := state.world } := by
        apply h
        simp [ObservedCalls, forEachCall]
      obtain ⟨data, hdata⟩ := hhead
      have hpolicy : gatewayPolicy (denoteCall adversary site state) = .next := by
        simp [gatewayPolicy, hdata, ExternalCallResult.succeeded]
      have htail : ∀ entry ∈ ObservedCalls (forEachCall gatewayPolicy () rest)
          adversary (denoteCall adversary site state).state, Succeeds adversary entry := by
        intro entry hentry
        apply h
        simp [ObservedCalls, forEachCall, hpolicy, hentry]
      have hrest := ih (denoteCall adversary site state).state htail
      simp [CallsIn, ObservedCalls, forEachCall, hpolicy] at hrest ⊢
      exact hrest

/-- **P-TOPUP-2 transaction-plane cap conservation.**  For every adversary and
initial call state, the aggregate wei value of the dynamically observed
value-bearing calls of the gateway program is bounded by the per-block cap,
conditional on the explicit runtime-provenance witness and the pinned source
guards. -/
theorem tx_aggregate_bounded_by_block_cap
    (provenance : RuntimeProvenance) (hProvenance : provenance.Valid)
    (batch : TopupBatch) (cfg : TopupConfig) (hBatch : well_formed_batch batch cfg)
    (adversary : AdversaryModel) (state : CallState) :
    valueSum (CallsIn (gatewayCallProgram batch cfg) adversary state) ≤
      cfg.maxTopUpPerBlockGwei * GWEI := by
  have hCap : (execute batch cfg).sum ≤ cfg.maxTopUpPerBlockGwei :=
    source_aggregate_bounded_by_block_cap provenance hProvenance batch cfg hBatch
  obtain ⟨n, hn⟩ := forEachCall_callsIn_take gatewayPolicy ()
    (plannedSites 0 (execute batch cfg)) adversary state
  unfold gatewayCallProgram
  rw [hn]
  calc valueSum ((plannedSites 0 (execute batch cfg)).take n)
      ≤ valueSum (plannedSites 0 (execute batch cfg)) := valueSum_take_le _ n
    _ = (execute batch cfg).sum * GWEI := plannedSites_value_sum 0 _
    _ ≤ cfg.maxTopUpPerBlockGwei * GWEI := Nat.mul_le_mul hCap (Nat.le_refl GWEI)

/-- A fully successful run moves exactly the budget-consumed aggregate. -/
theorem tx_all_success_value_exact (batch : TopupBatch) (cfg : TopupConfig)
    (adversary : AdversaryModel) (state : CallState)
    (h : ∀ entry ∈ ObservedCalls (gatewayCallProgram batch cfg) adversary state,
      Succeeds adversary entry) :
    valueSum (CallsIn (gatewayCallProgram batch cfg) adversary state) =
      (execute batch cfg).sum * GWEI := by
  unfold gatewayCallProgram at h ⊢
  rw [callsIn_all_success_eq_planned _ adversary state h]
  exact plannedSites_value_sum 0 _

/-- A transaction-level revert restores the exact initial world. -/
theorem tx_revert_restores_world (batch : TopupBatch) (cfg : TopupConfig)
    (adversary : AdversaryModel) (state : CallState) (data : List Nat)
    (h : (denote (gatewayCallProgram batch cfg) adversary state).1 = .revert data) :
    (denoteTransaction (gatewayCallProgram batch cfg) adversary state).state.world =
      state.world :=
  denoteTransaction_revert_world _ adversary state data h

/-- When every observed call rolls back, the program preserves the world. -/
theorem tx_all_rollback_preserves_world (batch : TopupBatch) (cfg : TopupConfig)
    (adversary : AdversaryModel) (state : CallState)
    (h : ∀ entry ∈ ObservedCalls (gatewayCallProgram batch cfg) adversary state,
      RollsBack adversary entry) :
    (denote (gatewayCallProgram batch cfg) adversary state).2.world = state.world :=
  denoteCallProgram_all_revert_preserves_world _ adversary state h

/-- A fully successful run commits exactly the fold of the adversary's
per-site transitions over the observed call sites. -/
theorem tx_committed_world_is_commit_fold (batch : TopupBatch) (cfg : TopupConfig)
    (adversary : AdversaryModel) (state : CallState)
    (h : ∀ entry ∈ ObservedCalls (gatewayCallProgram batch cfg) adversary state,
      Succeeds adversary entry) :
    (denote (gatewayCallProgram batch cfg) adversary state).2.world =
      commitWorlds adversary state.world
        (CallsIn (gatewayCallProgram batch cfg) adversary state) :=
  denoteCallProgram_all_succeed_commits_world _ adversary state h

/-- The gateway policy aborts only on an observation that actually failed, with
that observation's returndata.  This constrains a given `obs`; it does not
assert that such an `obs` belongs to any particular run's `ObservedCalls`. -/
theorem gateway_abort_is_failed_call (obs : CallObservation) (data : List Nat)
    (h : gatewayPolicy obs = .abort data) :
    obs.result.succeeded = false ∧ obs.result.returndata = data := by
  cases hsucc : obs.result.succeeded with
  | true => simp [gatewayPolicy, hsucc] at h
  | false =>
      simp [gatewayPolicy, hsucc] at h
      exact ⟨rfl, h⟩

end LidoSRv3.Audit.Verity.Topup2Tx
