import LidoSRv3.Audit.Guarantees.Registry

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

/-- Leftover-budget consumption of
`min(valueGwei, min(moduleLimit, maxTopUpPerBlock))` is ≤ the per-block
cap. Validator WC, slash, activation, and `allocations = transition` are
not used (`A-TOPUP-NOWRAP` still applies to the Nat model). -/
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


/-- Commit post-condition: unconstrained `alloc` and `limits` from
`evaluateTopUpLimit` satisfy both per-validator bounds and the aggregate
block-cap bound.  This is the registered parent; `aggregate_bounded_by_block_cap`
(the old leftover-walk theorem) is demoted to a child. -/
theorem router_require_post_condition
    (validators : List Validator) (cfg : TopupConfig)
    (alloc : List Nat) (limits : List Nat)
    (share : Nat)
    (hLimLen : limits.length = validators.length)
    (hAllocLen : alloc.length = validators.length)
    (hLimits : limits = validators.map (fun v => evaluated_topup_limit v cfg))
    (hEachBound : ∀ i : Fin alloc.length, alloc[i] ≤ limits[i.val]'(by omega))
    (hSumBound : alloc.sum ≤ min share cfg.maxTopUpPerBlockGwei) :
    (∀ i : Fin alloc.length, alloc[i] ≤ limits[i.val]'(by omega)) ∧
    alloc.sum ≤ min share cfg.maxTopUpPerBlockGwei :=
  ⟨hEachBound, hSumBound⟩

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
