import LidoSRv3.Audit.Guarantees.PTopup2
import LidoSRv3.Audit.Verity.TopupUnboundedCount

/-!
# P-TOPUP-2 same-block n-call bound

The registered parent `aggregate_bounded_by_block_cap` is a **single-call**
leftover walk.  It does not thread a used-this-block gwei counter.

Pinned `lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`:

* `SRTypes.sol` slot 5 / `StakingRouter.sol:696` — `maxTopUpPerBlockGwei` is
  a config word, not an accumulator.  Each `topUp` (`:696-700`, `:736-738`)
  reapplies `min(moduleAllocation, maxTopUpPerBlockWei)` in full.
* `TopUpGateway.sol:42-48` packed storage writes `lastTopUpBlock` /
  `lastTopUpTimestamp` at `:340-345`, and only when `totalLimits > 0`
  (`:234-236`).
* `_isBlockDistancePassed` (`:324-329`) —
  `lastTopUpBlock == 0 || block.number - lastTopUpBlock >= minBlockDistance`.
* `_setMinBlockDistance` (`:361-365`) reverts `ZeroValue` on `0`.

There is therefore no persistent `transitionBudget` in pinned storage.
This module keeps the per-call leftover walk (fresh `transitionBudget`) and
persists the **actual** per-block counter: `lastTopUpBlock` together with
`minBlockDistance`.

On an initialized gateway (`minBlockDistance ≥ 1`) and a nonzero block
(so a write is distinguishable from the `lastTopUpBlock == 0` sentinel),
`n` sequential same-block calls allocate a sum ≤ `maxTopUpPerBlockGwei`.

A mutant that drops the `lastTopUpBlock` write, or admits
`minBlockDistance = 0`, lets two calls each take the full cap.  That
kill-line is not a published finding: the public entry refuses the second
positive same-block call, and `StakingRouter.topUp` is auth-gated to the
gateway (`:686`).
-/

namespace LidoSRv3.Audit.Verity.TopupMultiCallBlockCap

open LidoSRv3.Audit.Guarantees.PTopup2
open LidoSRv3.Audit.Verity.TopupUnboundedCount

/-- Pinned gateway words that admit or refuse a subsequent top-up
(`TopUpGateway.sol:42-46`, `:324-329`). -/
structure GatewayDistanceState where
  lastTopUpBlock : Nat
  minBlockDistance : Nat
  lastTopUpTimestamp : Nat
  deriving Repr, DecidableEq

/-- `TopUpGateway.sol:361-365` `_setMinBlockDistance`: `0` reverts
`ZeroValue`; `> type(uint16).max` reverts `TooLargeValue`. -/
def minBlockDistanceAdmitted (n : Nat) : Prop :=
  n ≠ 0 ∧ n ≤ 2 ^ 16 - 1

theorem setter_refuses_zero : ¬ minBlockDistanceAdmitted 0 := by
  intro h
  exact h.1 rfl

/-- `TopUpGateway.sol:324-329` `_isBlockDistancePassed`, with monotone
blocks so Nat subtraction matches the source `uint32` subtraction. -/
def BlockDistancePassed (s : GatewayDistanceState) (blockNumber : Nat) : Prop :=
  s.lastTopUpBlock = 0 ∨
    (s.lastTopUpBlock ≤ blockNumber ∧
      s.minBlockDistance ≤ blockNumber - s.lastTopUpBlock)

instance : Decidable (BlockDistancePassed s blockNumber) :=
  inferInstanceAs (Decidable (_ ∨ _))

/-- `TopUpGateway.sol:340-345` `_setLastTopUpData`. -/
def setLastTopUpData (s : GatewayDistanceState) (blockNumber timestamp : Nat) :
    GatewayDistanceState :=
  { s with lastTopUpBlock := blockNumber, lastTopUpTimestamp := timestamp }

/-- Sum of independently evaluated per-key limits.  Source `totalLimits`
(`TopUpGateway.sol:227`) is this quantity in wei; the unit drop is the
same as `Topup2Correspondence`. -/
def evaluatedLimits (b : TopupBatch) (cfg : TopupConfig) : List Nat :=
  b.validators.map (fun v => evaluated_topup_limit v cfg)

def totalLimits (b : TopupBatch) (cfg : TopupConfig) : Nat :=
  (evaluatedLimits b cfg).sum

theorem zipWith_min_sum_le_rights :
    ∀ (req lim : List Nat), (List.zipWith min req lim).sum ≤ lim.sum
  | [], _ => by
      cases lim <;> simp
  | _ :: _, [] => by simp
  | r :: rs, l :: ls => by
      simp only [List.zipWith_cons_cons, List.sum_cons]
      exact Nat.add_le_add (Nat.min_le_right _ _) (zipWith_min_sum_le_rights rs ls)

theorem totalLimits_zero_implies_transition_zero
    (b : TopupBatch) (cfg : TopupConfig)
    (h : totalLimits b cfg = 0) :
    (transition b cfg).sum = 0 := by
  have hcand : (candidates b cfg).sum ≤ (evaluatedLimits b cfg).sum :=
    zipWith_min_sum_le_rights b.requestedGwei (evaluatedLimits b cfg)
  have hz : (candidates b cfg).sum = 0 :=
    Nat.eq_zero_of_le_zero (hcand.trans (Nat.le_of_eq h))
  have hwalk := leftover_walk_sum_le_keys (transitionBudget b cfg) (candidates b cfg)
  exact Nat.eq_zero_of_le_zero (hwalk.trans (Nat.le_of_eq hz))

inductive CallOutcome
  | reverted
  | committed (used : Nat)
  deriving Repr, DecidableEq

def usedOf : CallOutcome → Nat
  | .reverted => 0
  | .committed used => used

/-- One gateway-then-router step: distance check, then a fresh leftover
walk (`transitionBudget` is **not** persisted — the router has no such
slot), then `_setLastTopUpData` iff `totalLimits > 0`. -/
def runOne (cfg : TopupConfig) (blockNumber timestamp : Nat)
    (b : TopupBatch) (s : GatewayDistanceState) :
    CallOutcome × GatewayDistanceState :=
  if BlockDistancePassed s blockNumber then
    let used := (transition b cfg).sum
    let s' :=
      if 0 < totalLimits b cfg then setLastTopUpData s blockNumber timestamp else s
    (.committed used, s')
  else
    (.reverted, s)

def runMany (cfg : TopupConfig) (blockNumber timestamp : Nat) :
    GatewayDistanceState → List TopupBatch → List Nat × GatewayDistanceState
  | s, [] => ([], s)
  | s, b :: bs =>
      let (o, s') := runOne cfg blockNumber timestamp b s
      let (rest, s'') := runMany cfg blockNumber timestamp s' bs
      (usedOf o :: rest, s'')

/-- Router-only schedule: each call gets a fresh `transitionBudget`.
Pinned `StakingRouter.topUp` does this; it is the mutant relative to a
persisted gwei remaining. -/
def routerOnlyMany (cfg : TopupConfig) (calls : List TopupBatch) : List Nat :=
  calls.map (fun b => (transition b cfg).sum)

theorem runMany_nil (cfg : TopupConfig) (blockNumber timestamp : Nat)
    (s : GatewayDistanceState) :
    runMany cfg blockNumber timestamp s [] = ([], s) := rfl

theorem runOne_blocked
    (cfg : TopupConfig) (blockNumber timestamp : Nat)
    (b : TopupBatch) (s : GatewayDistanceState)
    (h : ¬ BlockDistancePassed s blockNumber) :
    runOne cfg blockNumber timestamp b s = (.reverted, s) := by
  simp [runOne, h]

theorem distance_fails_after_set
    (s : GatewayDistanceState) (blockNumber timestamp : Nat)
    (hBlock : blockNumber ≠ 0)
    (hDist : 0 < s.minBlockDistance) :
    ¬ BlockDistancePassed (setLastTopUpData s blockNumber timestamp) blockNumber := by
  intro h
  have hlast : (setLastTopUpData s blockNumber timestamp).lastTopUpBlock = blockNumber := rfl
  have hmin : (setLastTopUpData s blockNumber timestamp).minBlockDistance =
      s.minBlockDistance := rfl
  rcases h with h0 | ⟨_, hge⟩
  · exact hBlock (by simpa [hlast] using h0)
  · have : s.minBlockDistance ≤ 0 := by
      simpa [hmin, Nat.sub_self] using hge
    exact Nat.not_lt.mpr this hDist

theorem runMany_all_zero_of_blocked
    (cfg : TopupConfig) (blockNumber timestamp : Nat)
    (s : GatewayDistanceState) (calls : List TopupBatch)
    (h : ¬ BlockDistancePassed s blockNumber) :
    (runMany cfg blockNumber timestamp s calls).1.sum = 0 ∧
      (runMany cfg blockNumber timestamp s calls).2 = s := by
  induction calls generalizing s with
  | nil => simp [runMany]
  | cons b bs ih =>
      have hr := runOne_blocked cfg blockNumber timestamp b s h
      simp [runMany, hr, usedOf] at ih ⊢
      exact ih h

theorem minBlockDistance_preserved_set (s : GatewayDistanceState)
    (blockNumber timestamp : Nat) :
    (setLastTopUpData s blockNumber timestamp).minBlockDistance =
      s.minBlockDistance := rfl

/-- `n` sequential same-block gateway calls: at most one committed positive
allocation, and that allocation is the leftover walk, hence ≤ the cap.

Hypotheses are the setter invariant (`TopUpGateway.sol:361-365`), the
`lastTopUpBlock == 0` sentinel (`:327`), and monotone blocks.  They are
not renamed parent premises. -/
theorem same_block_sum_le_cap
    (cfg : TopupConfig) (blockNumber timestamp : Nat)
    (s : GatewayDistanceState) (calls : List TopupBatch)
    (hDist : 0 < s.minBlockDistance)
    (hBlock : blockNumber ≠ 0)
    (hMono : s.lastTopUpBlock ≤ blockNumber) :
    (runMany cfg blockNumber timestamp s calls).1.sum ≤
      cfg.maxTopUpPerBlockGwei := by
  induction calls generalizing s with
  | nil =>
      simp [runMany]
  | cons b bs ih =>
      unfold runMany
      by_cases hp : BlockDistancePassed s blockNumber
      · have hrun : runOne cfg blockNumber timestamp b s =
            let used := (transition b cfg).sum
            let s' :=
              if 0 < totalLimits b cfg then
                setLastTopUpData s blockNumber timestamp else s
            (.committed used, s') := by
          simp [runOne, hp]
        simp only [hrun]
        by_cases hlim : 0 < totalLimits b cfg
        · have hs' : (if 0 < totalLimits b cfg then
              setLastTopUpData s blockNumber timestamp else s) =
              setLastTopUpData s blockNumber timestamp := by
            simp [hlim]
          simp only [hs', usedOf]
          have hblocked :
              ¬ BlockDistancePassed
                (setLastTopUpData s blockNumber timestamp) blockNumber :=
            distance_fails_after_set s blockNumber timestamp hBlock hDist
          have hrest :=
            runMany_all_zero_of_blocked cfg blockNumber timestamp
              (setLastTopUpData s blockNumber timestamp) bs hblocked
          have hhead := aggregate_bounded_by_block_cap b cfg
          simpa [hrest.1] using hhead
        · have hs' : (if 0 < totalLimits b cfg then
              setLastTopUpData s blockNumber timestamp else s) = s := by
            simp [hlim]
          have hzero : totalLimits b cfg = 0 :=
            Nat.eq_zero_of_le_zero (Nat.not_lt.mp hlim)
          have hused : (transition b cfg).sum = 0 :=
            totalLimits_zero_implies_transition_zero b cfg hzero
          simp only [hs', usedOf, hused]
          exact ih s hDist hMono
      · have hr := runOne_blocked cfg blockNumber timestamp b s hp
        simp [hr, usedOf]
        exact ih s hDist hMono

/-- Mutant: skip `_setLastTopUpData`.  Distance never locks. -/
def runOneNoLock (cfg : TopupConfig) (blockNumber timestamp : Nat)
    (b : TopupBatch) (s : GatewayDistanceState) :
    CallOutcome × GatewayDistanceState :=
  if BlockDistancePassed s blockNumber then
    (.committed (transition b cfg).sum, s)
  else
    (.reverted, s)

def runManyNoLock (cfg : TopupConfig) (blockNumber timestamp : Nat) :
    GatewayDistanceState → List TopupBatch → List Nat × GatewayDistanceState
  | s, [] => ([], s)
  | s, b :: bs =>
      let (o, s') := runOneNoLock cfg blockNumber timestamp b s
      let (rest, s'') := runManyNoLock cfg blockNumber timestamp s' bs
      (usedOf o :: rest, s'')

/-- Concrete two-call vector used by the kill-line: each leftover walk
commits the full 10-gwei cap. -/
def killCfg : TopupConfig :=
  { targetBalanceGwei := 32, minTopUpGwei := 1
    maxTopUpPerBlockGwei := 10, maxValidatorsPerCall := 100
    moduleAllocationLimitGwei := 100, maxRootAge := 0 }

def killValidator : Validator :=
  { pubkey := ⟨#[1]⟩, index := 0, wc := 2, activated := true
    slashed := false, exiting := false
    effectiveBalanceGwei := 12, pendingBalanceGwei := 0 }

def killBatch : TopupBatch :=
  { validators := [killValidator], requestedGwei := [10], allocations := []
    valueWei := 100 * GWEI, beaconRootTimestamp := 0, currentTimestamp := 0 }

def killState : GatewayDistanceState :=
  { lastTopUpBlock := 0, minBlockDistance := 1, lastTopUpTimestamp := 0 }

theorem kill_transition_sum :
    (transition killBatch killCfg).sum = 10 := by
  decide

theorem kill_totalLimits_pos : 0 < totalLimits killBatch killCfg := by
  decide

/-- Honest two-call same-block schedule: first call takes the cap and
writes `lastTopUpBlock`; second call reverts.  Sum = cap. -/
theorem honest_two_call_sum_eq_cap :
    (runMany killCfg 1 1 killState [killBatch, killBatch]).1.sum = 10 := by
  decide

theorem honest_two_call_respects_parent :
    (runMany killCfg 1 1 killState [killBatch, killBatch]).1.sum ≤
      killCfg.maxTopUpPerBlockGwei :=
  same_block_sum_le_cap killCfg 1 1 killState [killBatch, killBatch]
    (by decide) (by decide) (by decide)

/-- Kill-line: dropping `_setLastTopUpData` lets both same-block calls
commit 10 gwei.  Sum 20 ≰ 10. -/
theorem no_lock_two_call_exceeds_cap :
    (runManyNoLock killCfg 1 1 killState [killBatch, killBatch]).1.sum = 20 ∧
      ¬ (runManyNoLock killCfg 1 1 killState [killBatch, killBatch]).1.sum ≤
        killCfg.maxTopUpPerBlockGwei := by
  decide

/-- Router-only schedule (fresh `transitionBudget` each call, no gateway
lock).  Two calls sum to `2 * cap`.  This is what pinned
`StakingRouter.topUp` would do if invoked twice; the gateway auth +
distance lock refuse that public path. -/
theorem router_only_two_call_exceeds_cap :
    (routerOnlyMany killCfg [killBatch, killBatch]).sum = 20 ∧
      ¬ (routerOnlyMany killCfg [killBatch, killBatch]).sum ≤
        killCfg.maxTopUpPerBlockGwei := by
  decide

theorem no_lock_kill_line_refutes_unconditional_sum :
    ¬ ∀ (cfg : TopupConfig) (blockNumber timestamp : Nat)
        (s : GatewayDistanceState) (calls : List TopupBatch),
      (runManyNoLock cfg blockNumber timestamp s calls).1.sum ≤
        cfg.maxTopUpPerBlockGwei := by
  intro h
  exact absurd (h killCfg 1 1 killState [killBatch, killBatch])
    (no_lock_two_call_exceeds_cap.2)

#print axioms leftover_walk_sum_le_budget
#print axioms setter_refuses_zero
#print axioms zipWith_min_sum_le_rights
#print axioms totalLimits_zero_implies_transition_zero
#print axioms distance_fails_after_set
#print axioms runMany_all_zero_of_blocked
#print axioms same_block_sum_le_cap
#print axioms honest_two_call_sum_eq_cap
#print axioms honest_two_call_respects_parent
#print axioms no_lock_two_call_exceeds_cap
#print axioms router_only_two_call_exceeds_cap
#print axioms no_lock_kill_line_refutes_unconditional_sum

end LidoSRv3.Audit.Verity.TopupMultiCallBlockCap
