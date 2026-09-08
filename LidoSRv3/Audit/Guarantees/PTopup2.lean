import LidoSRv3.Audit.Guarantees.Registry
import Mathlib.Data.List.Forall2

namespace LidoSRv3.Audit.Guarantees.PTopup2

/-- One Gwei in wei.  The gateway rejects values not aligned to this unit. -/
def GWEI : Nat := 10 ^ 9

/-- Validator fields consumed by the pinned verifier and `_evaluateTopUpLimit`. -/
structure Validator where
  pubkey : ByteArray
  index : Nat
  wc : Nat
  activated : Bool
  slashed : Bool
  exiting : Bool
  effectiveBalanceGwei : Nat
  pendingBalanceGwei : Nat
  deriving Inhabited

/-- Configurable gateway limits.  In particular, the target is not the
32-ETH minimum activation balance; Electra deployments may configure a larger
compounding-validator target. -/
structure TopupConfig where
  targetBalanceGwei : Nat
  minTopUpGwei : Nat
  maxTopUpPerBlockGwei : Nat
  maxValidatorsPerCall : Nat
  moduleAllocationLimitGwei : Nat
  maxRootAge : Nat

/-- Mathematical Gwei model of `_evaluateTopUpLimit` on inputs whose addition
does not overflow a Solidity `uint256`.  This definition deliberately uses
`Nat`; it is not source correspondence for unchecked inputs because Solidity's
checked addition reverts where `Nat` addition remains total. -/
def evaluated_topup_limit (v : Validator) (cfg : TopupConfig) : Nat :=
  if v.exiting || v.slashed then 0
  else
    let currentTotal := v.effectiveBalanceGwei + v.pendingBalanceGwei
    if currentTotal >= cfg.targetBalanceGwei then 0
    else
      let gap := cfg.targetBalanceGwei - currentTotal
      if gap < cfg.minTopUpGwei then 0 else gap

/-- Strict ordering is the source's duplicate-validator exclusion rule. -/
def strictlyIncreasing : List Nat → Prop
  | [] | [_] => True
  | a :: b :: rest => a < b ∧ strictlyIncreasing (b :: rest)

/-- A call and the allocations produced by its budget-consuming transition. -/
structure TopupBatch where
  validators : List Validator
  requestedGwei : List Nat
  allocations : List Nat
  valueWei : Nat
  beaconRootTimestamp : Nat
  currentTimestamp : Nat

/-- Consume `budget` from left to right.  This is the state transition from
per-validator candidate amounts to actual allocations. -/
def consumeBudget : Nat → List Nat → List Nat
  | _, [] => []
  | budget, amount :: amounts =>
      let allocated := min amount budget
      allocated :: consumeBudget (budget - allocated) amounts

private theorem consumeBudget_sum_le (budget : Nat) (amounts : List Nat) :
    (consumeBudget budget amounts).sum ≤ budget := by
  induction amounts generalizing budget with
  | nil => simp [consumeBudget]
  | cons amount amounts ih =>
      simp only [consumeBudget, List.sum_cons]
      have hmin : min amount budget ≤ budget := Nat.min_le_right _ _
      have htail := ih (budget - min amount budget)
      exact Nat.le_trans (Nat.add_le_add_left htail _)
        (Nat.le_of_eq (Nat.add_sub_of_le hmin))

private theorem consumeBudget_sum_le_sum (budget : Nat) (amounts : List Nat) :
    (consumeBudget budget amounts).sum ≤ amounts.sum := by
  induction amounts generalizing budget with
  | nil => simp [consumeBudget]
  | cons amount amounts ih =>
      simp only [consumeBudget, List.sum_cons]
      exact Nat.add_le_add (Nat.min_le_left _ _) (ih _)

/-- The leftover walk never gives a key more than its independently evaluated
candidate. This is pointwise, not merely an aggregate consequence. -/
theorem consumeBudget_per_key_le (budget : Nat) (amounts : List Nat) :
    List.Forall₂ (fun allocated candidate => allocated ≤ candidate)
      (consumeBudget budget amounts) amounts := by
  induction amounts generalizing budget with
  | nil => simp [consumeBudget]
  | cons amount amounts ih =>
      simp only [consumeBudget]
      exact .cons (Nat.min_le_left _ _) (ih _)

/-- Candidate amounts are independently capped by the evaluated validator
limits before the aggregate budget is consumed. -/
def candidates (b : TopupBatch) (cfg : TopupConfig) : List Nat :=
  List.zipWith min b.requestedGwei (b.validators.map (fun v => evaluated_topup_limit v cfg))

/-- The transition budget is constrained by the call value, module allocation
limit, and per-block cap. -/
def transitionBudget (b : TopupBatch) (cfg : TopupConfig) : Nat :=
  min (b.valueWei / GWEI)
    (min cfg.moduleAllocationLimitGwei cfg.maxTopUpPerBlockGwei)

def transition (b : TopupBatch) (cfg : TopupConfig) : List Nat :=
  consumeBudget (transitionBudget b cfg) (candidates b cfg)

/-- Public per-key bound for P-TOPUP-2. Each produced allocation is paired
with, and bounded by, the corresponding requested/evaluated candidate. -/
theorem per_key_bounded_by_candidate (b : TopupBatch) (cfg : TopupConfig) :
    List.Forall₂ (fun allocated candidate => allocated ≤ candidate)
      (transition b cfg) (candidates b cfg) :=
  consumeBudget_per_key_le _ _

private theorem candidates_sum_le (validators : List Validator)
    (requests : List Nat) (cfg : TopupConfig)
    (hlen : validators.length = requests.length) :
    (List.zipWith min requests
      (validators.map (fun v => evaluated_topup_limit v cfg))).sum ≤
      (validators.map (fun v => evaluated_topup_limit v cfg)).sum := by
  induction validators generalizing requests with
  | nil =>
      cases requests <;> simp_all
  | cons validator validators ih =>
      cases requests with
      | nil => simp at hlen
      | cons requested requests =>
          simp only [List.length_cons, Nat.succ.injEq] at hlen
          simp only [List.map_cons, List.zipWith_cons_cons, List.sum_cons]
          exact Nat.add_le_add (Nat.min_le_right _ _) (ih requests hlen)

/-- Source guards represented by the abstract batch, without assuming the
result of the leftover-budget transition. -/
def well_formed_pre (b : TopupBatch) (cfg : TopupConfig) : Prop :=
  (∀ v ∈ b.validators,
    v.wc = 0x02 ∧ v.activated = true ∧ v.slashed = false ∧ v.exiting = false) ∧
  strictlyIncreasing (b.validators.map (fun v => v.index)) ∧
  (b.validators.map (fun v => v.pubkey)).Nodup ∧
  b.validators.length = b.requestedGwei.length ∧
  b.validators.length = b.allocations.length ∧
  b.validators.length ≤ cfg.maxValidatorsPerCall ∧
  b.beaconRootTimestamp ≤ b.currentTimestamp ∧
  b.currentTimestamp - b.beaconRootTimestamp ≤ cfg.maxRootAge ∧
  b.valueWei % GWEI = 0

/-- A well-formed batch is a pre-validated call whose allocations are exactly
the leftover-budget transition. Conservation is a consequence of that
equality, not an extra hypothesis of the bound theorems below. -/
def well_formed_batch (b : TopupBatch) (cfg : TopupConfig) : Prop :=
  well_formed_pre b cfg ∧ b.allocations = transition b cfg

/-- The leftover-budget transition is bounded by the independent per-validator
limits. -/
theorem aggregate_bounded_by_individual (b : TopupBatch) (cfg : TopupConfig) :
    well_formed_pre b cfg →
      (transition b cfg).sum ≤
        (b.validators.map (fun v => evaluated_topup_limit v cfg)).sum := by
  intro h
  rcases h with ⟨_, _, _, hreq, _, _, _, _, _⟩
  apply Nat.le_trans (consumeBudget_sum_le_sum _ _)
  exact candidates_sum_le b.validators b.requestedGwei cfg hreq

/-- **P-TOPUP-2, abstract plane.**  The sum of the top-up amounts allocated in
a batch is at most the protocol's per-block cap, in gwei, with no hypothesis on
the batch.

**Registered P-TOPUP-2 parent.** Leftover-budget consumption of
`min(valueGwei, min(moduleLimit, maxTopUpPerBlock))` is ≤ the per-block
cap. Validator WC, slash, activation, and `allocations = transition` are
not used. `A-TOPUP-NOWRAP` is not attached to this row: its recorded
StakingRouter line-732 accumulator belongs to P-TOPUP-1.

This is unconditional in `b` and `cfg`: unlike a post-condition that takes
the sum bound as a hypothesis and hands it back, this theorem's content is
in the *proof* — induction over `consumeBudget` showing the leftover walk
never exceeds the budget it was given, composed with `transitionBudget`'s
`min _ (min _ maxTopUpPerBlockGwei)`. `Tests.Topup2DistributionTxMutants`
shows the bound is not vacuous: a mutant budget that drops the
`maxTopUpPerBlockGwei` term from that `min` lets the identical leftover walk
allocate above the cap (`block_cap_kill_line_refutes_parent`). -/
theorem aggregate_bounded_by_block_cap (b : TopupBatch) (cfg : TopupConfig) :
    (transition b cfg).sum ≤ cfg.maxTopUpPerBlockGwei :=
  Nat.le_trans (consumeBudget_sum_le _ _)
    (Nat.le_trans (Nat.min_le_right _ _) (Nat.min_le_right _ _))

/-- The module allocation limit is conserved by the same transition. -/
theorem aggregate_bounded_by_module_limit (b : TopupBatch) (cfg : TopupConfig) :
    well_formed_pre b cfg →
      (transition b cfg).sum ≤ cfg.moduleAllocationLimitGwei := by
  intro _h
  exact Nat.le_trans (consumeBudget_sum_le _ _)
    (Nat.le_trans (Nat.min_le_right _ _) (Nat.min_le_left _ _))

theorem aggregate_bounded_by_block_cap_of_well_formed
    (b : TopupBatch) (cfg : TopupConfig) :
    well_formed_batch b cfg →
      b.allocations.sum ≤ cfg.maxTopUpPerBlockGwei := by
  intro h
  rw [h.2]
  exact aggregate_bounded_by_block_cap b cfg

/-- Counterexample to reading `aggregate_bounded_by_block_cap` as depending
on `well_formed_pre`. Allocations `[99]` with no validators fail the
pre-filter (length mismatch) but leftover-budget consumption is still
`0 ≤ 1`. -/
private def illFormedCapCfg : TopupConfig :=
  { targetBalanceGwei := 32, minTopUpGwei := 1
    maxTopUpPerBlockGwei := 1, maxValidatorsPerCall := 1
    moduleAllocationLimitGwei := 10 ^ 18, maxRootAge := 0 }

private def illFormedCapBatch : TopupBatch :=
  { validators := [], requestedGwei := [], allocations := [99]
    valueWei := 0, beaconRootTimestamp := 0, currentTimestamp := 0 }

example : ¬ well_formed_pre illFormedCapBatch illFormedCapCfg := by
  intro h
  cases h.2.2.2.2.1

example : (transition illFormedCapBatch illFormedCapCfg).sum ≤
    illFormedCapCfg.maxTopUpPerBlockGwei :=
  aggregate_bounded_by_block_cap illFormedCapBatch illFormedCapCfg


/- **Retracted (Wave 1 review, P-TOPUP-2 issue).** A prior revision
registered `router_require_post_condition` as the parent: unconstrained
`alloc` and `limits`, with `hEachBound : ∀ i, alloc[i] ≤ limits[i]` and
`hSumBound : alloc.sum ≤ min share cfg.maxTopUpPerBlockGwei` as *hypotheses*,
concluding exactly `⟨hEachBound, hSumBound⟩`. That conclusion is syntactically
identical to its hypotheses — the "proof" is `⟨hEachBound, hSumBound⟩` — so
the theorem holds for any `alloc`/`limits`/`share` whatsoever, including ones
no execution of `transition`/`consumeBudget` could ever produce. It does not
depend on `evaluated_topup_limit`, `transition`, or any router execution
semantics, so no mutant of the actual leftover-budget walk could ever be
written that this statement would catch: the kill-line mutant that used to
sit next to it (`Tests.Topup2DistributionTxMutants`) fed concrete numbers
into the conclusion directly, never through the theorem itself, and so
"refuted" a general fact about `Nat` inequalities rather than the registered
parent. It has been removed rather than restated; `aggregate_bounded_by_block_cap`
above is the registered parent, and its kill-line mutant is stated against
`transitionBudget`/`consumeBudget`, the functions the parent's proof actually
uses. -/

/-! ## Wei / Gwei conversion model

The gateway operates in gwei; the router and EVM operate in wei.
`valueWei / GWEI` is the gwei reading of `msg.value`, and
`well_formed_pre` requires `valueWei % GWEI = 0` (the alignment guard at
`TopUpGateway.sol`).  The theorems below connect the wei-domain batch
value to the gwei-domain budget without assuming the alignment — the
alignment hypothesis is an explicit premise.  This is the model-side
anchor for the router's `amount % 1 gwei != 0` revert at source line 724.
-/

def weiToGwei (wei : Nat) : Nat := wei / GWEI
def gweiToWei (gwei : Nat) : Nat := gwei * GWEI

theorem gweiToWei_weiToGwei_of_aligned (w : Nat) (h : w % GWEI = 0) :
    gweiToWei (weiToGwei w) = w := by
  simp only [gweiToWei, weiToGwei]
  exact Nat.div_mul_cancel (Nat.dvd_of_mod_eq_zero h)

theorem weiToGwei_gweiToWei (g : Nat) : weiToGwei (gweiToWei g) = g := by
  simp only [weiToGwei, gweiToWei, GWEI]
  exact Nat.mul_div_cancel g (by decide)

theorem weiToGwei_mono {a b : Nat} (h : a ≤ b) : weiToGwei a ≤ weiToGwei b :=
  Nat.div_le_div_right h

theorem transitionBudget_uses_gwei_value (b : TopupBatch) (cfg : TopupConfig) :
    transitionBudget b cfg =
      min (weiToGwei b.valueWei)
        (min cfg.moduleAllocationLimitGwei cfg.maxTopUpPerBlockGwei) := rfl

theorem transition_sum_le_valueGwei (b : TopupBatch) (cfg : TopupConfig) :
    (transition b cfg).sum ≤ weiToGwei b.valueWei :=
  Nat.le_trans (consumeBudget_sum_le _ _) (Nat.min_le_left _ _)

theorem transition_sum_wei_le_valueWei (b : TopupBatch) (cfg : TopupConfig)
    (hAlign : b.valueWei % GWEI = 0) :
    gweiToWei (transition b cfg).sum ≤ b.valueWei := by
  have hGwei := transition_sum_le_valueGwei b cfg
  calc gweiToWei (transition b cfg).sum
      = (transition b cfg).sum * GWEI := rfl
    _ ≤ weiToGwei b.valueWei * GWEI := Nat.mul_le_mul_right _ hGwei
    _ = b.valueWei := Nat.div_mul_cancel (Nat.dvd_of_mod_eq_zero hAlign)

/-! ## Top-up freshness model

The beacon root consumed by the verifier must be recent enough: the
`TopUpGateway` rejects calls whose `beaconBlockRoot` timestamp is more
than `maxRootAge` seconds behind `block.timestamp`.  `well_formed_pre`
already carries this as
`b.beaconRootTimestamp ≤ b.currentTimestamp` and
`b.currentTimestamp - b.beaconRootTimestamp ≤ cfg.maxRootAge`.

The theorems below are the model-level reading of that freshness guard:
a stale root is rejected, and a fresh root's age is bounded.  These are
independent of the transition budget or allocation walk.
-/

def rootIsFresh (b : TopupBatch) (cfg : TopupConfig) : Prop :=
  b.beaconRootTimestamp ≤ b.currentTimestamp ∧
    b.currentTimestamp - b.beaconRootTimestamp ≤ cfg.maxRootAge

theorem well_formed_pre_implies_fresh (b : TopupBatch) (cfg : TopupConfig)
    (h : well_formed_pre b cfg) : rootIsFresh b cfg :=
  ⟨h.2.2.2.2.2.2.1, h.2.2.2.2.2.2.2.1⟩

def staleBatch : TopupBatch :=
  { validators := [], requestedGwei := [], allocations := []
    valueWei := 0, beaconRootTimestamp := 0, currentTimestamp := 100 }

def staleCfg : TopupConfig :=
  { targetBalanceGwei := 32, minTopUpGwei := 1
    maxTopUpPerBlockGwei := 1, maxValidatorsPerCall := 1
    moduleAllocationLimitGwei := 10 ^ 18, maxRootAge := 50 }

example : ¬ rootIsFresh staleBatch staleCfg := by
  intro ⟨_, h⟩
  simp [staleBatch, staleCfg] at h

example : rootIsFresh { staleBatch with currentTimestamp := 30 } staleCfg := by
  constructor <;> simp [staleBatch, staleCfg]

/-! ## Inter-call policy model

The top-up path makes two sequential external calls: first
`allocateDeposits` (source line 718) to obtain the allocation array, then
the beacon push loop (source line 750) to deposit.  The inter-call
invariant is that the allocation array consumed by the push loop is
exactly the array returned by the module call — no transformation,
reordering, or injection between the two.

At the model level this is captured by `well_formed_batch`: the batch's
`allocations` field IS `transition b cfg`, which in turn consumes the
budget from the `candidates` derived from `requestedGwei` (the module
return) and the validator limits.  The inter-call policy says: the
allocation array that the push loop deposits is the transition applied
to the module's return, not an independently supplied list.
-/

def interCallConsistent (b : TopupBatch) (cfg : TopupConfig) : Prop :=
  b.allocations = transition b cfg

theorem well_formed_batch_implies_interCallConsistent
    (b : TopupBatch) (cfg : TopupConfig)
    (h : well_formed_batch b cfg) : interCallConsistent b cfg :=
  h.2

theorem interCall_allocations_bounded (b : TopupBatch) (cfg : TopupConfig)
    (h : interCallConsistent b cfg) :
    b.allocations.sum ≤ cfg.maxTopUpPerBlockGwei := by
  rw [h]
  exact aggregate_bounded_by_block_cap b cfg

theorem interCall_allocations_per_key (b : TopupBatch) (cfg : TopupConfig)
    (h : interCallConsistent b cfg) :
    List.Forall₂ (fun allocated candidate => allocated ≤ candidate)
      b.allocations (candidates b cfg) := by
  rw [h]
  exact per_key_bounded_by_candidate b cfg

/-! ## Freshness + budget composition

A well-formed batch simultaneously satisfies freshness, inter-call
consistency, the per-block cap, and the value-budget constraint. -/

theorem well_formed_batch_composition (b : TopupBatch) (cfg : TopupConfig)
    (h : well_formed_batch b cfg) :
    rootIsFresh b cfg ∧
    interCallConsistent b cfg ∧
    b.allocations.sum ≤ cfg.maxTopUpPerBlockGwei ∧
    (transition b cfg).sum ≤ weiToGwei b.valueWei :=
  ⟨well_formed_pre_implies_fresh b cfg h.1,
   h.2,
   aggregate_bounded_by_block_cap_of_well_formed b cfg h,
   transition_sum_le_valueGwei b cfg⟩

/-! ## Allocation length preservation

The transition preserves the length relationship between validators and
allocations, which is critical for the push loop's index correspondence. -/

private theorem consumeBudget_length (budget : Nat) (amounts : List Nat) :
    (consumeBudget budget amounts).length = amounts.length := by
  induction amounts generalizing budget with
  | nil => simp [consumeBudget]
  | cons _ amounts ih => simp [consumeBudget, ih]

private theorem candidates_length (b : TopupBatch) (cfg : TopupConfig) :
    (candidates b cfg).length =
      min b.requestedGwei.length b.validators.length := by
  simp [candidates, List.length_zipWith]

theorem transition_length (b : TopupBatch) (cfg : TopupConfig) :
    (transition b cfg).length = (candidates b cfg).length := by
  simp [transition, consumeBudget_length]

theorem well_formed_batch_allocation_length (b : TopupBatch) (cfg : TopupConfig)
    (h : well_formed_batch b cfg) :
    b.allocations.length = b.validators.length := by
  rw [h.2, transition_length, candidates_length]
  have hreq := h.1.2.2.2.1
  have hlen := h.1.2.2.2.2.1
  rw [← hreq]
  exact Nat.min_self _

/-- P-TOPUP-2 is closed on the abstract Nat cap and on a composed faithful
`Contract.run` transaction that computes allocation/share observables.
The composed Verity theorem lives in this namespace via
`LidoSRv3.Audit.Guarantees.PTopup2Verity`. -/
def guarantee : Guarantee := ⟨.pTopup2, [.model, .source, .verityTx]⟩

/- Out of scope for P-TOPUP-2: identifying the deployed verifier address and
codehash. The active assurance contract asks for a faithful Verity model of the
guarantee-relevant call behavior, not a general deployment-provenance chain.
For SSZ only, audit metadata separately tracks whether the imported Yul fragment
matches the deployed fragment. -/

end LidoSRv3.Audit.Guarantees.PTopup2
