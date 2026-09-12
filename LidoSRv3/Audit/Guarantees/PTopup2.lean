import LidoSRv3.Audit.Guarantees.Registry
import LidoSRv3.Audit.Source.TopupCorrespondence
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

/-! ## Chantier 4 (mandate 2026-09-12): P-TOPUP-2 registered abstract parent on the real router mechanism

The prior registered abstract parent `aggregate_bounded_by_block_cap`
proves a property of `consumeBudget` — a leftover-budget walk that
`StakingRouter.topUp` does not execute. The pinned router mechanism at
`StakingRouter.sol:703-737` (as modeled by `SolidityTopup.run`) instead
applies per-index guards inside its allocation loop (line 728) and an
aggregate cap check on the WRAPPED accumulator (line 737); there is no
leftover-budget walk. The `valueWei/GWEI` term in the old parent's
`transitionBudget` (line 105) has NO source: `StakingRouter.topUp` is
not payable (no `payable` modifier and no `msg.value` reference on
lines 679-756 of the pinned Solidity).

**Public-claim narrowing signaled to Thomas per mandate 2026-09-12
chantier 4:** the aggregate check at line 737 is on the WRAPPED sum
(`SolidityTopup.accumulated inp = allocSumUnchecked inp.allocations`,
mod 2^256), NOT on the exact sum. Under a nonzero wrap the exact sum
can far exceed the cap while `run` still commits (the value-moving
tail then aborts via Lido-side amount guards or the line-755 assert —
P-TOPUP-1's third conjunct). So the honest P-TOPUP-2 aggregate bound
is on the wrapped sum.

`router_source_cap_within_block_cap` below is the new registered
abstract parent. Its ENUNCE names the ACTUAL router source constants
(`smDepositableEthAmount`, `smDepositableEthAmountRounded`,
`maxTopUpPerBlockWei`) from source lines 696, 700, 706 — not
`consumeBudget` / `transitionBudget`, which the router does not
execute. Combined with the router's aggregate guard at line 737 (given
as a hypothesis `hAggr`; a full derivation of `hAggr` from
`(run cfg inp).reverts = false` requires an inversion of `run` that
is disclosed as an open sub-obligation in
`fidelity.missing`), the theorem yields the router mechanism's actual
bound: the WRAPPED accumulator is at most `maxTopUpPerBlockGwei * 1
gwei = maxTopUpPerBlockWei`. -/

/-- The rounded cap at source line 706 is ≤ `maxTopUpPerBlockWei` at
source line 696, via the min at source line 700 and the subtraction
at line 706. Pure definitional chain of source constants. -/
theorem source_smDepRounded_le_maxTopUpPerBlockWei
    (cfg : SolidityTopup.SourceTopupConfig)
    (inp : SolidityTopup.SourceTopupInput) :
    SolidityTopup.smDepositableEthAmountRounded cfg inp ≤
      SolidityTopup.maxTopUpPerBlockWei cfg inp := by
  -- StakingRouter.sol:706  smDepositableEthAmountRounded = smDepositableEthAmount - (that % 1 gwei)
  have hRound : SolidityTopup.smDepositableEthAmountRounded cfg inp ≤
      SolidityTopup.smDepositableEthAmount cfg inp := Nat.sub_le _ _
  -- StakingRouter.sol:700  smDepositableEthAmount = min(_getModuleDepositAllocation(...), maxTopUpPerBlockWei)
  have hMin : SolidityTopup.smDepositableEthAmount cfg inp ≤
      SolidityTopup.maxTopUpPerBlockWei cfg inp := Nat.min_le_right _ _
  exact Nat.le_trans hRound hMin

/-- **P-TOPUP-2, abstract plane (chantier 4, mandate 2026-09-12): new
registered abstract parent on the real router mechanism.**

Given the router's aggregate guard at `StakingRouter.sol:737`
(hAggr: the WRAPPED accumulator does not exceed the rounded cap; on
the source `SolidityTopup.run` model this is the negation of the
`if_pos` branch at line 630 of `run`), the WRAPPED accumulator is
bounded by `maxTopUpPerBlockGwei * gwei = maxTopUpPerBlockWei`
(source line 696).

The bound is on `SolidityTopup.accumulated inp`, i.e., the WRAPPED
sum `allocSumUnchecked` (mod 2^256), NOT on the exact sum. Under a
nonzero wrap the exact sum can far exceed the cap; that's the
public-claim narrowing signaled to Thomas per mandate 2026-09-12.

Deriving `hAggr` from `(SolidityTopup.run cfg inp).reverts = false`
requires a full inversion of `run` past its earlier guards (lines
686-715) and the `runPush` disjunct's implicit consequence
`allocationLoop = none ∧ ¬ (smDep < accumulated)`. That derivation is
disclosed as an open sub-obligation in `fidelity.missing` and is
subordinate row `P-TOPUP-2.router-inversion` (not yet proved). -/
theorem router_source_cap_within_block_cap
    {cfg : SolidityTopup.SourceTopupConfig} {inp : SolidityTopup.SourceTopupInput}
    (hAggr : SolidityTopup.accumulated inp ≤
      SolidityTopup.smDepositableEthAmountRounded cfg inp) :
    SolidityTopup.accumulated inp ≤ inp.maxTopUpPerBlockGwei * cfg.gwei := by
  -- Compose the aggregate guard with the definitional cap chain
  -- (source lines 696, 700, 706).
  have hCap := source_smDepRounded_le_maxTopUpPerBlockWei cfg inp
  -- maxTopUpPerBlockWei cfg inp = inp.maxTopUpPerBlockGwei * cfg.gwei is `rfl`
  -- from the definition at TopupCorrespondence.lean:337-339.
  exact Nat.le_trans hAggr hCap

/-! ## Chantier 4bis (Thomas 2026-09-12): P-TOPUP-2 exact-sum bound under gateway-shape premise

The `router_source_cap_within_block_cap` above is honest at the router
level ALONE, but the wrap it disclosed is UNREACHABLE in the pinned
deployment because the pinned `TopUpGateway` constructs its
`topUpLimits[i]` as `_evaluateTopUpLimit(...) * 1 gwei`
(`TopUpGateway.sol:226`); the evaluator's output is bounded by
`targetBalanceGwei : uint64`, so every limit is at most
`(2^64 - 1) * 10^9 < 2^73`. The number of keys is bounded by
`maxValidatorsPerTopUp : uint64`, so at most `2^64 - 1`. And
`StakingRouter.topUp` at line 686 (`_checkAppAuth(_getTopUpGateway())`)
only admits the top-up gateway as caller — no other caller can supply
non-gateway-shaped limits.

Composing these gives:
- Each admitted allocation ≤ its `topUpLimits[i]` (source line 728) ≤
  `(2^64 - 1) * 10^9`.
- Sum over ≤ `2^64 - 1` keys of values < `2^73` is < `2^64 * 2^73 =
  2^137 << 2^256`.
- Therefore `allocSum inp.allocations < uint256Modulus`, so
  `allocSumUnchecked inp.allocations = allocSum inp.allocations`
  (no wrap; `allocSumUnchecked_eq_allocSum`).
- Combined with `hAggr`, the EXACT sum ≤ `maxTopUpPerBlockGwei * gwei`.

The registered signal narrowing therefore becomes: **exact under
gateway-shape premise, wrapped otherwise**. The premise is named in
the theorem's statement and captured by `GatewayShapedInput`; the
residual is what the premise assumes about the caller's construction
of `topUpLimits` and about the router's admission chain.

The `router_source_cap_within_block_cap` above is retained as an
unregistered lemma used inside this composition; the composition
below is the new registered abstract parent (per the general rule
from Thomas 2026-09-12 — a weakened claim must be composed with a
real-form premise before being registered). -/

/-- `2^64 - 1`, the Solidity uint64 upper bound. -/
def uint64Max : Nat := 2 ^ 64 - 1

/-- Gateway-shape premise: the pinned `TopUpGateway.sol:226`
constructs `topUpLimits[i] = _evaluateTopUpLimit(...) * 1 gwei` where
the evaluator's output is bounded by `targetBalanceGwei : uint64`,
and the number of keys is bounded by `maxValidatorsPerTopUp : uint64`.
This premise DOES NOT claim that any specific caller supplied the
limits; it only asserts that the limits and length have the shape a
gateway-constructed call would have. Under `StakingRouter.topUp:686`,
the top-up gateway is currently the only admitted caller (a
consequence of the pinned SR access-control chain, disclosed as the
premise residual). -/
structure GatewayShapedInput (inp : SolidityTopup.SourceTopupInput) : Prop where
  lengthBound : inp.allocations.length ≤ uint64Max
  perElementBound : ∀ a ∈ inp.allocations, a ≤ uint64Max * GWEI

private theorem list_sum_le_length_mul_bound (xs : List Nat) (bound : Nat)
    (hAll : ∀ a ∈ xs, a ≤ bound) :
    xs.sum ≤ xs.length * bound := by
  induction xs with
  | nil => simp
  | cons x rest ih =>
      simp only [List.sum_cons, List.length_cons]
      have hx : x ≤ bound := hAll x List.mem_cons_self
      have htail : rest.sum ≤ rest.length * bound :=
        ih (fun a ha => hAll a (List.mem_cons_of_mem _ ha))
      calc x + rest.sum ≤ bound + rest.length * bound := Nat.add_le_add hx htail
        _ = (rest.length + 1) * bound := by
              rw [Nat.add_mul, Nat.one_mul, Nat.add_comm]

private theorem gateway_sum_lt_uint256Modulus
    {inp : SolidityTopup.SourceTopupInput}
    (hShape : GatewayShapedInput inp) :
    SolidityTopup.allocSum inp.allocations < SolidityTopup.uint256Modulus := by
  -- Chain: allocSum ≤ len * (uint64Max * GWEI) ≤ uint64Max * (uint64Max * GWEI)
  --                                             < 2^64 * 2^64 * 10^9 = 2^128 * 10^9
  --                                             < 2^128 * 2^30 = 2^158 < 2^256.
  have hlist : List.sum inp.allocations ≤
      inp.allocations.length * (uint64Max * GWEI) :=
    list_sum_le_length_mul_bound _ _ hShape.perElementBound
  have hlist' : SolidityTopup.allocSum inp.allocations ≤
      inp.allocations.length * (uint64Max * GWEI) := by
    have hEq : SolidityTopup.allocSum inp.allocations = List.sum inp.allocations := by
      induction inp.allocations with
      | nil => rfl
      | cons a rest ih => simp [SolidityTopup.allocSum, List.sum_cons, ih]
    rw [hEq]; exact hlist
  have hlen : inp.allocations.length * (uint64Max * GWEI) ≤
      uint64Max * (uint64Max * GWEI) := Nat.mul_le_mul_right _ hShape.lengthBound
  have hStrict : uint64Max * (uint64Max * GWEI) < SolidityTopup.uint256Modulus := by
    unfold uint64Max GWEI SolidityTopup.uint256Modulus
    decide
  exact Nat.lt_of_le_of_lt (Nat.le_trans hlist' hlen) hStrict

/-- **P-TOPUP-2, abstract plane (chantier 4bis, Thomas 2026-09-12):
new registered abstract parent under the gateway-shape premise.**

Under the pinned gateway construction of `topUpLimits[i]` (bounded by
uint64 * gwei) and key-count bound (bounded by uint64), the sum is
under `2^256`, so no wrap occurs. Combined with the router's aggregate
guard at line 737, the EXACT sum is bounded by
`maxTopUpPerBlockGwei * gwei`.

Residual named in `fidelity.missing`: the premise assumes the caller
constructs its `topUpLimits` as the pinned `TopUpGateway.sol:226`
does; under `StakingRouter.topUp:686` (`_checkAppAuth(_getTopUpGateway())`)
this is the only admitted caller today. Under any non-gateway caller
the `router_source_cap_within_block_cap` (retained as lemma) bounds
only the WRAPPED sum. -/
theorem router_exact_sum_bounded_under_gateway_shape
    {cfg : SolidityTopup.SourceTopupConfig} {inp : SolidityTopup.SourceTopupInput}
    (hShape : GatewayShapedInput inp)
    (hAggr : SolidityTopup.accumulated inp ≤
      SolidityTopup.smDepositableEthAmountRounded cfg inp) :
    SolidityTopup.allocSum inp.allocations ≤ inp.maxTopUpPerBlockGwei * cfg.gwei := by
  -- Under the gateway-shape premise, wrap is unreachable.
  have hNoWrap : SolidityTopup.allocSum inp.allocations <
      SolidityTopup.uint256Modulus :=
    gateway_sum_lt_uint256Modulus hShape
  -- Under no-wrap: allocSum = allocSumUnchecked = accumulated.
  have hEq : SolidityTopup.allocSumUnchecked inp.allocations =
      SolidityTopup.allocSum inp.allocations :=
    SolidityTopup.allocSumUnchecked_eq_allocSum hNoWrap
  have hAccu : SolidityTopup.accumulated inp =
      SolidityTopup.allocSum inp.allocations := by
    unfold SolidityTopup.accumulated
    exact hEq
  -- Compose with router_source_cap_within_block_cap to lift to block cap.
  have hCap := router_source_cap_within_block_cap hAggr
  rw [hAccu] at hCap
  exact hCap

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
