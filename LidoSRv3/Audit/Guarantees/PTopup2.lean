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

/-- Faithful Gwei reading of pinned `_evaluateTopUpLimit`. -/
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

/-- All source guards represented by the abstract batch.  Conservation is
deliberately absent: it is a consequence of `allocations = transition`. -/
def well_formed_batch (b : TopupBatch) (cfg : TopupConfig) : Prop :=
  (∀ v ∈ b.validators,
    v.wc = 0x02 ∧ v.activated = true ∧ v.slashed = false ∧ v.exiting = false) ∧
  strictlyIncreasing (b.validators.map (fun v => v.index)) ∧
  (b.validators.map (fun v => v.pubkey)).Nodup ∧
  b.validators.length = b.requestedGwei.length ∧
  b.validators.length = b.allocations.length ∧
  b.validators.length ≤ cfg.maxValidatorsPerCall ∧
  b.beaconRootTimestamp ≤ b.currentTimestamp ∧
  b.currentTimestamp - b.beaconRootTimestamp ≤ cfg.maxRootAge ∧
  b.valueWei % GWEI = 0 ∧
  b.allocations = transition b cfg

/-- The aggregate bound by individual evaluated limits follows from the
transition and aligned arrays, rather than from an assumed aggregate bound. -/
theorem aggregate_bounded_by_individual (b : TopupBatch) (cfg : TopupConfig) :
    well_formed_batch b cfg →
      b.allocations.sum ≤
        (b.validators.map (fun v => evaluated_topup_limit v cfg)).sum := by
  intro h
  rcases h with ⟨_, _, _, hreq, halloc, _, _, _, _, htransition⟩
  rw [htransition]
  apply Nat.le_trans (consumeBudget_sum_le_sum _ _)
  exact candidates_sum_le b.validators b.requestedGwei cfg hreq

/-- Per-block conservation is derived from the budget-consuming transition. -/
theorem aggregate_bounded_by_block_cap (b : TopupBatch) (cfg : TopupConfig) :
    well_formed_batch b cfg →
      b.allocations.sum ≤ cfg.maxTopUpPerBlockGwei := by
  intro h
  rw [h.2.2.2.2.2.2.2.2.2]
  exact Nat.le_trans (consumeBudget_sum_le _ _)
    (Nat.le_trans (Nat.min_le_right _ _) (Nat.min_le_right _ _))

/-- The module allocation limit is conserved by the same transition. -/
theorem aggregate_bounded_by_module_limit (b : TopupBatch) (cfg : TopupConfig) :
    well_formed_batch b cfg →
      b.allocations.sum ≤ cfg.moduleAllocationLimitGwei := by
  intro h
  rw [h.2.2.2.2.2.2.2.2.2]
  exact Nat.le_trans (consumeBudget_sum_le _ _)
    (Nat.le_trans (Nat.min_le_right _ _) (Nat.min_le_left _ _))

/-- The model theorem is extended by source and bounded-Verity transaction
correspondence in `Source.Topup2Correspondence` and `Verity.Topup2Tx`. -/
def guarantee : Guarantee := ⟨.pTopup2, [.model, .source, .verityTx]⟩

/- TODO(P-TOPUP-2 verifier binding): establish from runtime provenance that the
deployed verifier address and codehash bind an accepted SSZ proof to the intended
validator. EVM closure remains BLOCKED until then; source and transaction
statements take the provenance witness explicitly as an input. -/

end LidoSRv3.Audit.Guarantees.PTopup2
