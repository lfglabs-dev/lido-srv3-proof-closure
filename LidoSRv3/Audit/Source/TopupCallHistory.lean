import LidoSRv3.Audit.Source.TopupWeiBounds

/-!
# TOPUP-2: the gateway's post-call timing state

Source: lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436,
TopUpGateway.sol:234-236, 323-330, 340-345, 362-366.
This small arithmetic slice does not model full call histories or authorized
reentrancy. In particular, the router call at 232 happens BEFORE `finish`.
A temporal guard witness alone is not an authorized exploit trace.

`Configured` is reachability only through the relevant configuration/update
operations. It derives positive delay from the actual setter, allows arbitrary
valid subsequent delay changes, and is NOT full protocol-state reachability.
Raw storage writes/upgrades, access control, initialization lifecycle, external
call effects, rollback, root admission and chain provenance are not modeled.
-/
namespace LidoSRv3.Audit.Source.TopupCallHistory
open TopupWeiBounds

def uint16Modulus : Nat := 2 ^ 16
def uint32Modulus : Nat := 2 ^ 32

structure TimingState where
  lastBlock : Fin uint32Modulus
  lastTimestamp : Fin uint32Modulus
  distance : Fin uint16Modulus
  deriving DecidableEq, Repr

/-- The uint16 setter rejects zero and out-of-range values before casting. -/
def setDistance (s : TimingState) (n : Nat) : Option TimingState :=
  if n = 0 then none
  else if h : n < uint16Modulus then some { s with distance := ⟨n, h⟩ }
  else none

/-- Caller uses the state AFTER the external router call has returned.
A positive sum of limits triggers this update even if actual allocations are
zero. Explicit uint32 casts truncate; there is no checked-cast guard. -/
def finish (s : TimingState) (blockNumber timestamp totalLimits : Nat) : TimingState :=
  if totalLimits > 0 then
    { s with
      lastBlock := ⟨blockNumber % uint32Modulus, Nat.mod_lt _ (by decide)⟩
      lastTimestamp := ⟨timestamp % uint32Modulus, Nat.mod_lt _ (by decide)⟩ }
  else s

/-- Exact short-circuit and checked subtraction of `_isBlockDistancePassed`.
`none` represents a checked-subtraction panic, distinct from `some false`. -/
def distancePassed (s : TimingState) (blockNumber : Nat) : Option Bool :=
  if s.lastBlock.val = 0 then some true
  else if blockNumber < s.lastBlock.val then none
  else some (decide (s.distance.val ≤ blockNumber - s.lastBlock.val))

def emptyTiming : TimingState :=
  ⟨⟨0, by decide⟩, ⟨0, by decide⟩, ⟨0, by decide⟩⟩

/-- Scoped configuration reachability, not an EVM or protocol history. -/
inductive Configured : TimingState → Prop
  | initialized (n : Nat) (s : TimingState)
      (h : setDistance emptyTiming n = some s) : Configured s
  | reconfigured (s t : TimingState) (n : Nat) (hs : Configured s)
      (h : setDistance s n = some t) : Configured t
  | returned (s : TimingState) (blockNumber timestamp totalLimits : Nat)
      (hs : Configured s) : Configured (finish s blockNumber timestamp totalLimits)

theorem setter_positive (s t : TimingState) (n : Nat)
    (h : setDistance s n = some t) : 0 < t.distance.val := by
  unfold setDistance at h
  split at h
  · contradiction
  next hn =>
    split at h
    · have he := Option.some.inj h
      subst t
      simp only
      omega
    · contradiction

theorem configured_positive (s : TimingState) (h : Configured s) :
    0 < s.distance.val := by
  induction h with
  | initialized n t ht => exact setter_positive emptyTiming t n ht
  | reconfigured s t n _ ht _ => exact setter_positive s t n ht
  | returned s b t total _ ih =>
    unfold finish
    split <;> exact ih

/-- No fixed delay is assumed: any successful setter preserves the last block. -/
theorem setter_preserves_last (s t : TimingState) (n : Nat)
    (h : setDistance s n = some t) :
    t.lastBlock = s.lastBlock ∧ t.lastTimestamp = s.lastTimestamp := by
  unfold setDistance at h
  split at h
  · contradiction
  · split at h
    · have he := Option.some.inj h
      subst t
      exact ⟨rfl, rfl⟩
    · contradiction

/-- Within the explicit uint32 block horizon, positive delay rejects another
entry after the previous positive-limit call returned. The horizon is an
operational condition, NOT a proved fact about protocol reachability. -/
theorem same_block_rejects_after_return (s : TimingState) (blockNumber timestamp total : Nat)
    (hs : Configured s) (hblock : 0 < blockNumber)
    (hwidth : blockNumber < uint32Modulus) (htotal : 0 < total) :
    distancePassed (finish s blockNumber timestamp total) blockNumber = some false := by
  have hd := configured_positive s hs
  simp [finish, htotal, distancePassed, Nat.mod_eq_of_lt hwidth,
    Nat.ne_of_gt hblock, Nat.not_le_of_gt hd]

/-- A valid delay change cannot reopen that same block after the return. -/
theorem same_block_rejects_after_setter (s t : TimingState)
    (blockNumber timestamp total n : Nat) (hblock : 0 < blockNumber)
    (hwidth : blockNumber < uint32Modulus) (htotal : 0 < total)
    (hset : setDistance (finish s blockNumber timestamp total) n = some t) :
    distancePassed t blockNumber = some false := by
  have hd := setter_positive _ t n hset
  have hl := (setter_preserves_last _ t n hset).1
  have hb : t.lastBlock.val = blockNumber := by
    rw [hl]
    simp [finish, htotal, Nat.mod_eq_of_lt hwidth]
  simp [distancePassed, hb, Nat.ne_of_gt hblock, Nat.not_le_of_gt hd]

/-- Zero limits means zero allocated value under the real per-key guards.
This uses the earlier uint64-derived no-overflow proof, not a no-wrap premise. -/
theorem zero_limits_zero_allocations (cfg : GatewayConfig) (vs : List ValidatorInput)
    (ns allocations : List Nat) (hcount : vs.length ≤ cfg.maxValidators.val)
    (h : limits cfg vs = some ns) (hg : allocationGuards allocations (weiLimits ns))
    (hz : uncheckedSum 0 (weiLimits ns) = 0) : allocations.sum = 0 := by
  have he := (gateway_wei_bounds cfg vs ns hcount h).2.2
  have hb := allocations_sum_le allocations (weiLimits ns) hg
  omega

/-- Calls whose sum of limits is zero leave these two timing fields unchanged.
Nothing here says that the external module call has no other effects. -/
theorem zero_limits_no_timing_update (s : TimingState) (b t : Nat) :
    finish s b t 0 = s := by simp [finish]

end LidoSRv3.Audit.Source.TopupCallHistory
