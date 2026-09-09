import Mathlib.Data.List.Basic
import Mathlib.Algebra.BigOperators.Group.List.Basic
import Lean.Elab.Tactic.Omega

/-!
# TOPUP-2: source-sized wei arithmetic

Pinned source: lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436.
This is an independent arithmetic slice, not an EVM execution theorem.
`GatewayConfig` uses the actual uint64 storage widths (TopUpGateway.sol:42,47),
not an assumed no-overflow predicate. `evaluate` transcribes lines 403-414,
including the early exit/slash return and checked uint256 addition.
`limits` processes the paired validator/pending inputs after length checks;
`weiLimits` and `uncheckedSum` model lines 226-227. Admission's other checks,
SSZ validity, external calls and state updates are not interpreted here.

The router results quantify over arbitrary returned allocations; no greedy
allocator is substituted. `allocationGuards` transcribes StakingRouter.sol:
723-734, including out-of-bounds failure if allocations is longer than limits.
The module may return fewer allocations, as in this source loop. Their sum is
shown exact before using the post-loop cap check at 737. This closes a numeric
circularity: a wrapped sum cannot falsely pass that check on this domain.
-/
namespace LidoSRv3.Audit.Source.TopupWeiBounds

def wordModulus : Nat := 2 ^ 256
def uint64Modulus : Nat := 2 ^ 64
def gwei : Nat := 10 ^ 9

structure GatewayConfig where
  target : Fin uint64Modulus
  maxValidators : Fin uint64Modulus
  minTopUp : Fin uint64Modulus
  deriving DecidableEq, Repr

structure ValidatorInput where
  effective : Fin uint64Modulus
  pending : Fin wordModulus
  exitEpoch : Fin uint64Modulus
  slashed : Bool
  deriving DecidableEq, Repr

/-- Function calls do not inherit the caller's unchecked block. -/
def evaluate (cfg : GatewayConfig) (v : ValidatorInput) : Option Nat :=
  if v.exitEpoch.val != uint64Modulus - 1 || v.slashed then some 0
  else
    let currentTotal := v.effective.val + v.pending.val
    if currentTotal >= wordModulus then none
    else if currentTotal >= cfg.target.val then some 0
    else
      let topUpLimit := cfg.target.val - currentTotal
      if topUpLimit < cfg.minTopUp.val then some 0 else some topUpLimit

/-- Independent mathematical postcondition for each successful evaluation. -/
theorem evaluate_bound (cfg : GatewayConfig) (v : ValidatorInput) (n : Nat)
    (h : evaluate cfg v = some n) : n ≤ cfg.target.val := by
  unfold evaluate at h
  split at h
  · have := Option.some.inj h; omega
  · dsimp only at h
    split at h
    · contradiction
    · split at h
      · have := Option.some.inj h; omega
      · split at h <;> (have := Option.some.inj h; omega)

def limits (cfg : GatewayConfig) : List ValidatorInput → Option (List Nat)
  | [] => some []
  | v :: vs => do
      let n ← evaluate cfg v
      let ns ← limits cfg vs
      pure (n :: ns)

theorem limits_bounds (cfg : GatewayConfig) (vs : List ValidatorInput) (ns : List Nat)
    (h : limits cfg vs = some ns) :
    ns.length = vs.length ∧ ∀ n ∈ ns, n ≤ cfg.target.val := by
  induction vs generalizing ns with
  | nil => simp [limits] at h; subst ns; simp
  | cons v vs ih =>
    simp only [limits] at h
    cases hv : evaluate cfg v with
    | none => simp [hv] at h
    | some n =>
      cases hs : limits cfg vs with
      | none => simp [hv, hs] at h
      | some tail =>
        simp [hv, hs] at h
        subst ns
        obtain ⟨hl, hb⟩ := ih tail hs
        refine ⟨by simp [hl], ?_⟩
        intro x hx
        simp only [List.mem_cons] at hx
        rcases hx with rfl | hx
        · exact evaluate_bound cfg v x hv
        · exact hb x hx

/-- EVM unchecked multiplication on uint256 values, line 226. -/
def weiLimits (ns : List Nat) : List Nat := ns.map (fun n => n * gwei % wordModulus)

/-- Left-to-right unchecked accumulator, used by gateway and router. -/
def uncheckedSum : Nat → List Nat → Nat
  | acc, [] => acc
  | acc, x :: xs => uncheckedSum ((acc + x) % wordModulus) xs

theorem uint64_product_fits (a b : Nat) (ha : a < uint64Modulus)
    (hb : b < uint64Modulus) : a * b * gwei < wordModulus := by
  have hm := Nat.mul_le_mul (Nat.le_of_lt ha) (Nat.le_of_lt hb)
  have hm' := Nat.mul_le_mul_right gwei hm
  have hn : uint64Modulus * uint64Modulus * gwei < wordModulus := by decide
  omega

theorem uint64_wei_fits (a : Nat) (ha : a < uint64Modulus) :
    a * gwei < wordModulus := by
  simpa using uint64_product_fits 1 a (by decide) ha

theorem conversion_exact (cfg : GatewayConfig) (n : Nat) (hn : n ≤ cfg.target.val) :
    n * gwei % wordModulus = n * gwei :=
  Nat.mod_eq_of_lt (uint64_wei_fits n (Nat.lt_of_le_of_lt hn cfg.target.isLt))

theorem conversion_roundtrip (cfg : GatewayConfig) (n : Nat) (hn : n ≤ cfg.target.val) :
    (n * gwei % wordModulus) / gwei = n := by
  rw [conversion_exact cfg n hn]
  exact Nat.mul_div_cancel n (by decide)

theorem sum_le_length_mul (ns : List Nat) (cap : Nat)
    (hb : ∀ n ∈ ns, n ≤ cap) : ns.sum ≤ ns.length * cap := by
  induction ns with
  | nil => simp
  | cons n ns ih =>
    have hn := hb n (by simp)
    have ht := ih (fun x hx => hb x (by simp [hx]))
    simp only [List.sum_cons, List.length_cons, Nat.add_mul, Nat.one_mul]
    omega

theorem uncheckedSum_exact (ns : List Nat) (acc : Nat)
    (h : acc + ns.sum < wordModulus) : uncheckedSum acc ns = acc + ns.sum := by
  induction ns generalizing acc with
  | nil => simp [uncheckedSum]
  | cons n ns ih =>
    have hp : acc + n < wordModulus := by simp only [List.sum_cons] at h; omega
    simp only [uncheckedSum, Nat.mod_eq_of_lt hp]
    rw [ih (acc + n) (by simp only [List.sum_cons] at h; omega)]
    simp [Nat.add_assoc]

/-- The full cardinality guard and actual uint64 target imply that even the
sum of all per-validator limits, before allocation, fits in a uint256. -/
theorem gateway_wei_bounds (cfg : GatewayConfig) (vs : List ValidatorInput)
    (ns : List Nat) (hcount : vs.length ≤ cfg.maxValidators.val)
    (h : limits cfg vs = some ns) :
    (∀ n ∈ ns, (n * gwei % wordModulus) / gwei = n) ∧
    (weiLimits ns).sum < wordModulus ∧
    uncheckedSum 0 (weiLimits ns) = (weiLimits ns).sum := by
  obtain ⟨hl, hb⟩ := limits_bounds cfg vs ns h
  have hw : ∀ x ∈ weiLimits ns, x ≤ cfg.target.val * gwei := by
    intro x hx
    obtain ⟨n, hn, rfl⟩ := List.mem_map.mp hx
    rw [conversion_exact cfg n (hb n hn)]
    exact Nat.mul_le_mul_right gwei (hb n hn)
  have hs := sum_le_length_mul (weiLimits ns) (cfg.target.val * gwei) hw
  have hc : (weiLimits ns).length < uint64Modulus := by
    simp only [weiLimits, List.length_map, hl]
    exact Nat.lt_of_le_of_lt hcount cfg.maxValidators.isLt
  have hf := uint64_product_fits (weiLimits ns).length cfg.target.val hc cfg.target.isLt
  rw [Nat.mul_assoc] at hf
  have hsum : (weiLimits ns).sum < wordModulus := Nat.lt_of_le_of_lt hs hf
  exact ⟨fun n hn => conversion_roundtrip cfg n (hb n hn), hsum,
    by simpa using uncheckedSum_exact (weiLimits ns) 0 (by simpa using hsum)⟩

/-- Runtime checks in the router's loop; a short allocation list is allowed,
but a long one indexes beyond limits and therefore reverts. -/
def allocationGuards : List Nat → List Nat → Prop
  | [], _ => True
  | _ :: _, [] => False
  | a :: allocations, l :: ls =>
      a % gwei = 0 ∧ a ≤ l ∧ allocationGuards allocations ls

instance (a l : List Nat) : Decidable (allocationGuards a l) := by
  induction a generalizing l with
  | nil => exact isTrue trivial
  | cons a as ih =>
    cases l with
    | nil => exact isFalse (fun h => h)
    | cons l ls =>
      haveI := ih ls
      exact inferInstanceAs (Decidable (a % gwei = 0 ∧ a ≤ l ∧ allocationGuards as ls))

theorem allocations_sum_le (allocations ls : List Nat)
    (h : allocationGuards allocations ls) : allocations.sum ≤ ls.sum := by
  induction allocations generalizing ls with
  | nil => simp
  | cons a as ih =>
    cases ls with
    | nil => contradiction
    | cons l ls =>
      obtain ⟨_, ha, ht⟩ := h
      have hs := ih ls ht
      simp only [List.sum_cons]
      omega

/-- Uses the source loop's successful guards on arbitrary module results,
then proves the unchecked accumulator cannot conceal an excessive total. -/
theorem router_unchecked_sum_exact (cfg : GatewayConfig) (vs : List ValidatorInput)
    (ns allocations : List Nat) (hcount : vs.length ≤ cfg.maxValidators.val)
    (h : limits cfg vs = some ns)
    (hg : allocationGuards allocations (weiLimits ns)) :
    uncheckedSum 0 allocations = allocations.sum := by
  have hs := (gateway_wei_bounds cfg vs ns hcount h).2.1
  have ha := allocations_sum_le allocations (weiLimits ns) hg
  simpa using uncheckedSum_exact allocations 0 (by omega)

/-- The cap check is applied to an exact sum, not an assumed exact sum.
`budgetWei` is the rounded module budget from router line 706; its provenance
from share allocation and cap calculation is separate from this theorem. -/
theorem router_accepted_budget (cfg : GatewayConfig) (vs : List ValidatorInput)
    (ns allocations : List Nat) (budgetWei : Nat)
    (hcount : vs.length ≤ cfg.maxValidators.val) (h : limits cfg vs = some ns)
    (hg : allocationGuards allocations (weiLimits ns))
    (hcap : uncheckedSum 0 allocations ≤ budgetWei) : allocations.sum ≤ budgetWei := by
  rwa [router_unchecked_sum_exact cfg vs ns allocations hcount h hg] at hcap


/-- Router lines 696,700,706: block cap conversion, minimum, then round down. -/
def routerBudget (moduleAllocationWei : Nat) (blockCapGwei : Fin uint64Modulus) : Nat :=
  let available := min moduleAllocationWei (blockCapGwei.val * gwei)
  available - available % gwei

/-- Source-shaped arithmetic admission of a module result. The call that
produces allocations and subsequent ETH/beacon effects are not modeled. -/
def routerAccept (allocations ls : List Nat) (budgetWei : Nat) : Option Nat :=
  if allocationGuards allocations ls then
    let amount := uncheckedSum 0 allocations
    if amount > budgetWei then none else some amount
  else none

/-- Successful arithmetic admission yields the true sum and actual uint64
block-cap bound, regardless of how the external module chose allocations. -/
theorem router_success (cfg : GatewayConfig) (vs : List ValidatorInput)
    (ns allocations : List Nat) (moduleAllocationWei amount : Nat)
    (blockCapGwei : Fin uint64Modulus)
    (hcount : vs.length ≤ cfg.maxValidators.val) (h : limits cfg vs = some ns)
    (hr : routerAccept allocations (weiLimits ns)
      (routerBudget moduleAllocationWei blockCapGwei) = some amount) :
    amount = allocations.sum ∧ allocations.sum ≤ blockCapGwei.val * gwei := by
  unfold routerAccept at hr
  split at hr
  next hg =>
    dsimp only at hr
    split at hr
    · contradiction
    next hc =>
      have he := router_unchecked_sum_exact cfg vs ns allocations hcount h hg
      have hm := Option.some.inj hr
      have hb : routerBudget moduleAllocationWei blockCapGwei ≤ blockCapGwei.val * gwei := by
        unfold routerBudget
        exact Nat.le_trans (Nat.sub_le _ _) (Nat.min_le_right _ _)
      constructor <;> omega
  · contradiction

end LidoSRv3.Audit.Source.TopupWeiBounds
