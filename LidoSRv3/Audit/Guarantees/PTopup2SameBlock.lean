import LidoSRv3.Audit.Guarantees.PTopup2ActualBatch
import LidoSRv3.Audit.Source.TopupTimingHistory

/-!
# P-TOPUP-2 same-block bound on the actual batch consumer

`Composition/TopupMultiCallBlockCap.same_block_sum_le_cap` bounds the sum of
`n` sequential same-block calls on the historical leftover-budget model
(`runMany` over an abstract `GatewayDistanceState`). This module ports that
argument to the registered consumer `TopupBatchConsumer.run`
(`PTopup2ActualBatch.actual_module_batch_bound`): the timing words are read
from the gateway's packed storage word (`TopupTimingHistory.lastBlock`,
`TopupTimingHistory.minDistance`, `TopUpGateway.sol:42-46`), the distance gate
is `_isBlockDistancePassed` (`:324-329`), and `_setLastTopUpData` (`:340-345`)
is written iff the loop's `totalLimits` is positive (`:234-236`). Each call is
the actual value path: witness loop, module CALL, decode, continuation.

Pinned `lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`.

Premises, stated once for the chain:

* `blockNumber ≠ 0` — the `lastTopUpBlock == 0` sentinel must be
  distinguishable from a written block (`:327`);
* `blockNumber < 2^32` — the source stores the block in a `uint32`; at block
  `2^32` or beyond the stored value truncates and the guard is broken
  (`audit/topup-call-history/README.md`, item 2), so the bound is stated on
  the uint32 domain;
* `0 < minDistance gateway w0` — the gateway is initialized with
  `minBlockDistance ≥ 1` (`_setMinBlockDistance` refuses `0`, `:361-365`);
* `ConfigStable` — a successful batch leaves the gateway's `minBlockDistance`
  field and the router's packed block cap unchanged. On the pinned source only
  `_setMinBlockDistance` and the router's own setters write those words; in
  this model the module and withdrawal callees are arbitrary interpreters that
  may return any world, so this module states the preservation as a premise.
  `PTopup2ConfigNoReentry.configStable_of_noReentry` derives it from
  A-NO-REENTRY (module callee, beacon deposit contract, Lido's dispatch) up to
  the router's own `receiveDepositableEther` callback keeping the cap word,
  and `same_block_actual_batches_le_cap_no_reentry` is the same-block bound
  without this premise.

The historical premise `lastTopUpBlock ≤ blockNumber` is not needed: a stored
block above the current one fails the gate and the call reverts.

Calls are sequential: the chain composes completed transactions. A nested
admission during the module CALL (the interval before `_setLastTopUpData`) is
outside this chain, as it is for the historical model.
-/

set_option autoImplicit false

namespace LidoSRv3.Audit.Guarantees.PTopup2SameBlock
open Source Source.TrioReserve1.Live Source.SszValidatorLeaf Source.SszVerifierEntry
open Source.SszWrapperIndex Source.TopupGatewayWitnessBatch
open Source.TopupBatchConsumer (blockCap moduleInput)

/-- Everything one gateway call supplies to `TopupBatchConsumer.run` except the
gateway address, the withdrawal context and the entry world. -/
structure Batch where
  hash : TopupRouterCredentials.Keccak
  moduleExternal : External
  withdrawalExternal : External
  precompile : Precompile
  oracle : RootOracle
  scratch : Fin 32 → Byte
  gi : Configuration
  beacon : BeaconData
  divisor : Index
  credentials : Digest
  depositContract : Address
  moduleId : Word
  keyIndices : List Word
  operatorIds : List Word
  rows : List Row
  moduleAllocation : Word

/-- The registered consumer on one call's inputs. -/
def consume (gateway : Address) (ctx : Context) (b : Batch) (w : World) :
    Except GatewayFault (Result Unit) :=
  TopupBatchConsumer.run b.hash b.moduleExternal b.withdrawalExternal b.precompile b.oracle
    b.scratch b.gi b.beacon b.divisor b.credentials gateway ctx b.depositContract b.moduleId
    b.keyIndices b.operatorIds b.rows b.moduleAllocation w

/-- Wei allocated by the module reply of one call, read from the same witness
loop, CALL and decoder the consumer executes; `0` when any of them fails. -/
def allocated (gateway : Address) (ctx : Context) (b : Batch) (w : World) : Nat :=
  match loop b.precompile b.oracle b.scratch b.gi (TopupGatewayConfigWords.readConfig gateway w)
      b.beacon b.divisor b.credentials none 0 b.rows with
  | .error _ => 0
  | .ok out =>
    match (TopupModuleCall.call b.hash b.moduleExternal
        (LidoSRv3.Audit.Verity.TopupBeaconFundedTx.routerContext ctx)
        (moduleInput out b.moduleId b.keyIndices b.operatorIds ctx.sender b.moduleAllocation w) w).outcome with
    | .error _ => 0
    | .ok raw =>
      match TopupModuleCall.decodeReturn raw with
      | .error _ => 0
      | .ok allocations => (TopupRouterContinuation.values allocations).sum

/-- Source `totalLimits` (`TopUpGateway.sol:227`): the witness loop's
accumulated wei limits; `0` when the loop fails. -/
def totalLimits (gateway : Address) (b : Batch) (w : World) : Nat :=
  match loop b.precompile b.oracle b.scratch b.gi (TopupGatewayConfigWords.readConfig gateway w)
      b.beacon b.divisor b.credentials none 0 b.rows with
  | .error _ => 0
  | .ok out => out.total

/-- `_isBlockDistancePassed` (`TopUpGateway.sol:324-329`) on the packed
gateway word, at an explicit block number. This is the first conjunct of
`TopupTimingHistory.Admitted` with `block.number` made explicit. -/
def DistancePassed (gateway : Address) (blockNumber : Nat) (w : World) : Prop :=
  TopupTimingHistory.lastBlock gateway w = 0 ∨
    (TopupTimingHistory.lastBlock gateway w ≤ blockNumber ∧
      TopupTimingHistory.minDistance gateway w ≤ blockNumber - TopupTimingHistory.lastBlock gateway w)

instance (gateway : Address) (blockNumber : Nat) (w : World) :
    Decidable (DistancePassed gateway blockNumber w) :=
  inferInstanceAs (Decidable (_ ∨ _))

theorem distance_of_admitted (e : TopupGatewayRootCalls.Environment)
    (h : TopupTimingHistory.Admitted e) :
    DistancePassed e.gateway e.before.core.blockNumber.val e.before :=
  h.1

/-- `_setLastTopUpData` (`TopUpGateway.sol:340-345`): the packed write of
`TopupTimingHistory.update`, at an explicit block number and timestamp. -/
def lock (gateway : Address) (blockNumber timestamp : Nat) (w : World) : World :=
  let core := w.core.writeContractSlot gateway.val TopupGatewayConfigWords.gatewayRoot
    (TopupTimingHistory.packed (TopupTimingHistory.stored gateway w) timestamp blockNumber)
  {w with core := core}

theorem lock_core_eq_update (gateway : Address) (w : World) :
    (lock gateway w.core.blockNumber.val w.core.blockTimestamp.val w).core =
      (TopupTimingHistory.update gateway w).core := rfl

/-- One gateway call: distance gate, the registered consumer, then the history
write iff `totalLimits > 0`. A reverted call returns the entry world. -/
def step (gateway : Address) (ctx : Context) (blockNumber timestamp : Nat) (b : Batch)
    (w : World) : Nat × World :=
  if DistancePassed gateway blockNumber w then
    match consume gateway ctx b w with
    | .error _ => (0, w)
    | .ok r =>
      match r.outcome with
      | .error _ => (0, w)
      | .ok _ =>
        (allocated gateway ctx b w,
          if 0 < totalLimits gateway b w then lock gateway blockNumber timestamp r.world
          else r.world)
  else (0, w)

/-- Sequential same-block calls, each consuming the world the previous one
returned. -/
def runMany (gateway : Address) (ctx : Context) (blockNumber timestamp : Nat) :
    World → List Batch → List Nat × World
  | w, [] => ([], w)
  | w, b :: bs =>
    let s := step gateway ctx blockNumber timestamp b w
    let rest := runMany gateway ctx blockNumber timestamp s.2 bs
    (s.1 :: rest.1, rest.2)

/-- A successful batch leaves the gateway's `minBlockDistance` field and the
router's packed block cap unchanged (see the module docstring). -/
def ConfigStable (gateway : Address) (ctx : Context) (b : Batch) : Prop :=
  ∀ (w : World) (r : Result Unit), consume gateway ctx b w = .ok r → r.outcome = .ok () →
    TopupTimingHistory.minDistance gateway r.world = TopupTimingHistory.minDistance gateway w ∧
    (blockCap ctx.sender r.world).val = (blockCap ctx.sender w).val

private theorem bind_success {ε α β : Type} {first : Except ε α}
    {next : α → Except ε β} {value : β} (h : (first >>= next) = .ok value) :
    ∃ x, first = .ok x ∧ next x = .ok value := by
  cases first with
  | «error» e => cases h
  | ok x => exact ⟨x, rfl, h⟩

/-- A successful call exposes its loop output, module reply and decoded
allocations; the allocated wei is bounded by the packed router cap and by the
loop's `totalLimits`. -/
theorem consume_success (gateway : Address) (ctx : Context) (b : Batch) (w : World)
    (r : Result Unit) (h : consume gateway ctx b w = .ok r) (hs : r.outcome = .ok ()) :
    ∃ out raw afterModule trace allocations,
      loop b.precompile b.oracle b.scratch b.gi (TopupGatewayConfigWords.readConfig gateway w)
        b.beacon b.divisor b.credentials none 0 b.rows = .ok out ∧
      TopupModuleCall.call b.hash b.moduleExternal
        (LidoSRv3.Audit.Verity.TopupBeaconFundedTx.routerContext ctx)
        (moduleInput out b.moduleId b.keyIndices b.operatorIds ctx.sender b.moduleAllocation w) w =
          ⟨.ok raw, afterModule, trace⟩ ∧
      TopupModuleCall.decodeReturn raw = .ok allocations ∧
      (TopupRouterContinuation.values allocations).sum ≤ (blockCap ctx.sender w).val * 10^9 ∧
      (TopupRouterContinuation.values allocations).sum ≤ out.total := by
  let cfg := TopupGatewayConfigWords.readConfig gateway w
  unfold consume TopupBatchConsumer.run at h
  dsimp only at h
  obtain ⟨u, hc, h⟩ := bind_success h
  cases u
  obtain ⟨out, hl, h⟩ := bind_success h
  change Except.ok _ = Except.ok r at h
  cases h
  have hcount : b.rows.length ≤ cfg.maxValidators.val :=
    ((checkLengths_iff cfg _ _ _ _ _).mp hc).2.2.2.2.2
  obtain ⟨ns, heval, _, hlimits, htotal⟩ :=
    loop_spec b.precompile b.oracle b.scratch b.gi cfg b.beacon b.divisor b.credentials b.rows
      none 0 out hl
  obtain ⟨raw, afterModule, trace, allocations, total, hcall, hdecode, hguard, htarget, _, _, _⟩ :=
    TopupRouterCommitted.module_execute_success b.hash b.moduleExternal b.withdrawalExternal ctx
      b.depositContract
      (moduleInput out b.moduleId b.keyIndices b.operatorIds ctx.sender b.moduleAllocation w) w hs
  have hwords : TopupRouterContinuation.values
      (moduleInput out b.moduleId b.keyIndices b.operatorIds ctx.sender b.moduleAllocation w).limits =
      TopupWeiBounds.weiLimits ns := by
    change TopupRouterContinuation.values (out.limits.map word) = _
    rw [hlimits, wei_word_values]
  obtain ⟨hguards, hsum⟩ := TopupRouterContinuation.guardSum_spec _ _ _ _ hguard
  rw [hwords] at hguards
  have hcount' : (b.rows.map fields).length ≤ cfg.maxValidators.val := by simpa using hcount
  have he := TopupWeiBounds.router_unchecked_sum_exact cfg (b.rows.map fields) ns
    (TopupRouterContinuation.values allocations) hcount' heval hguards
  have ht : total = (TopupRouterContinuation.values allocations).sum := hsum.trans he
  have hle : (TopupRouterContinuation.values allocations).sum ≤ (TopupWeiBounds.weiLimits ns).sum :=
    TopupWeiBounds.allocations_sum_le _ _ hguards
  have hexact := (TopupWeiBounds.gateway_wei_bounds cfg (b.rows.map fields) ns hcount' heval).2.2
  have htot : out.total = (TopupWeiBounds.weiLimits ns).sum := by
    rw [htotal, hlimits, hexact]
  refine ⟨out, raw, afterModule, trace, allocations, hl, hcall, hdecode, ?_, ?_⟩
  · rw [← ht]
    exact Nat.le_trans htarget
      (TopupBatchConsumer.target_bound ctx.sender b.moduleAllocation w)
  · rw [htot]
    exact hle

theorem allocated_le_cap (gateway : Address) (ctx : Context) (b : Batch) (w : World)
    (r : Result Unit) (h : consume gateway ctx b w = .ok r) (hs : r.outcome = .ok ()) :
    allocated gateway ctx b w ≤ (blockCap ctx.sender w).val * 10^9 := by
  obtain ⟨out, raw, afterModule, trace, allocations, hl, hcall, hdecode, hcap, _⟩ :=
    consume_success gateway ctx b w r h hs
  unfold allocated
  simpa only [hl, hcall, hdecode] using hcap

theorem allocated_le_totalLimits (gateway : Address) (ctx : Context) (b : Batch) (w : World)
    (r : Result Unit) (h : consume gateway ctx b w = .ok r) (hs : r.outcome = .ok ()) :
    allocated gateway ctx b w ≤ totalLimits gateway b w := by
  obtain ⟨out, raw, afterModule, trace, allocations, hl, hcall, hdecode, _, htot⟩ :=
    consume_success gateway ctx b w r h hs
  unfold allocated totalLimits
  simpa only [hl, hcall, hdecode] using htot

/-- Same-slot write of the packed word: the stored word after the lock is the
packed word (`TopupTimingHistory.update_word` at explicit block and time). -/
theorem lock_stored (gateway : Address) (blockNumber timestamp : Nat) (w : World) :
    TopupTimingHistory.stored gateway (lock gateway blockNumber timestamp w) =
      TopupTimingHistory.packed (TopupTimingHistory.stored gateway w) timestamp blockNumber := by
  by_cases hg : gateway.val = 0 <;>
    simp [TopupTimingHistory.stored, lock, Verity.ContractState.readContractSlot,
      Verity.ContractState.writeContractSlot, Verity.ContractState.readSlot,
      Verity.ContractState.writeSlot, Verity.ContractState.storage,
      Verity.ContractState.contractStorage, hg]

theorem lock_lastBlock (gateway : Address) (blockNumber timestamp : Nat) (w : World) :
    TopupTimingHistory.lastBlock gateway (lock gateway blockNumber timestamp w) =
      blockNumber % 2^32 := by
  unfold TopupTimingHistory.lastBlock
  rw [lock_stored]
  exact (TopupTimingHistory.packed_fields _ _ _).2.2.1

theorem lock_minDistance (gateway : Address) (blockNumber timestamp : Nat) (w : World) :
    TopupTimingHistory.minDistance gateway (lock gateway blockNumber timestamp w) =
      TopupTimingHistory.minDistance gateway w := by
  unfold TopupTimingHistory.minDistance
  rw [lock_stored, (TopupTimingHistory.packed_fields _ _ _).2.2.2]

/-- Reading any other slot of any account is unchanged by a slot write
(`TrioReserve1.Pipeline.read_other_slot`, restated to keep this module's
imports on the batch consumer). -/
theorem read_other_slot (core : Verity.ContractState) (writer reader written key : Nat)
    (value : Word) (h : key ≠ written) :
    (core.writeContractSlot writer written value).readContractSlot reader key =
      core.readContractSlot reader key := by
  by_cases hw : writer = 0 <;> by_cases hr : reader = 0 <;>
    simp [Verity.ContractState.writeContractSlot, Verity.ContractState.readContractSlot,
      Verity.ContractState.writeSlot, Verity.ContractState.readSlot,
      Verity.ContractState.storage, Verity.ContractState.contractStorage, hw, hr, h]

theorem routerCapSlot_ne_gatewayRoot :
    TopupRouterCredentials.routerRoot + 5 ≠ TopupGatewayConfigWords.gatewayRoot := by
  decide

/-- The history write touches the gateway's timing word only; the router's
packed block cap is read from another slot. -/
theorem lock_blockCap (gateway router : Address) (blockNumber timestamp : Nat) (w : World) :
    (blockCap router (lock gateway blockNumber timestamp w)).val = (blockCap router w).val := by
  simp only [blockCap, lock]
  rw [read_other_slot _ _ _ _ _ _ routerCapSlot_ne_gatewayRoot]

theorem step_blocked (gateway : Address) (ctx : Context) (blockNumber timestamp : Nat)
    (b : Batch) (w : World) (h : ¬ DistancePassed gateway blockNumber w) :
    step gateway ctx blockNumber timestamp b w = (0, w) := by
  unfold step
  rw [if_neg h]

/-- After the block is written, the gate refuses every later call of the same
block: the distance is `0 < minBlockDistance` (`TopUpGateway.sol:327-328`). -/
theorem locked_blocks (gateway : Address) (blockNumber : Nat) (w : World)
    (hl : TopupTimingHistory.lastBlock gateway w = blockNumber) (hb : blockNumber ≠ 0)
    (hd : 0 < TopupTimingHistory.minDistance gateway w) :
    ¬ DistancePassed gateway blockNumber w := by
  intro h
  rcases h with h0 | ⟨_, hle⟩
  · exact hb (hl.symm.trans h0)
  · rw [hl, Nat.sub_self] at hle
    omega

theorem runMany_locked (gateway : Address) (ctx : Context) (blockNumber timestamp : Nat)
    (hb : blockNumber ≠ 0) :
    ∀ (calls : List Batch) (w : World), TopupTimingHistory.lastBlock gateway w = blockNumber →
      0 < TopupTimingHistory.minDistance gateway w →
      (runMany gateway ctx blockNumber timestamp w calls).1.sum = 0
  | [], _, _, _ => by simp [runMany]
  | b :: bs, w, hl, hd => by
    have hs := step_blocked gateway ctx blockNumber timestamp b w (locked_blocks gateway blockNumber w hl hb hd)
    simp only [runMany, hs, List.sum_cons, Nat.zero_add]
    exact runMany_locked gateway ctx blockNumber timestamp hb bs w hl hd

/-- **Same-block bound on the actual consumer.** On an initialized gateway
(`minBlockDistance ≥ 1`), at a nonzero uint32 block, `n` sequential calls of
`TopupBatchConsumer.run` through the gateway's distance gate and history write
allocate in total at most the packed router block cap (in wei) read at the
first call. At most one call commits a positive allocation: it writes
`lastTopUpBlock`, and every later call of the block fails the gate.

Premises: `blockNumber ≠ 0` (sentinel), `blockNumber < 2^32` (uint32 field),
`0 < minBlockDistance` at entry, and `ConfigStable` for every call (the
batch's callees leave the gateway's `minBlockDistance` field and the router's
cap word unchanged). No `lastTopUpBlock ≤ blockNumber` premise is needed. -/
theorem same_block_actual_batches_le_cap_chain (gateway : Address) (ctx : Context)
    (blockNumber timestamp cap : Nat) (hBlock : blockNumber ≠ 0) (hWidth : blockNumber < 2^32) :
    ∀ (calls : List Batch) (w : World),
      0 < TopupTimingHistory.minDistance gateway w →
      (blockCap ctx.sender w).val = cap →
      (∀ b ∈ calls, ConfigStable gateway ctx b) →
      (runMany gateway ctx blockNumber timestamp w calls).1.sum ≤ cap * 10^9
  | [], _, _, _, _ => by simp [runMany]
  | b :: bs, w, hDist, hCap, hStable => by
    have hb : ConfigStable gateway ctx b := hStable b (List.mem_cons.mpr (Or.inl rfl))
    have hbs : ∀ b' ∈ bs, ConfigStable gateway ctx b' :=
      fun b' hm => hStable b' (List.mem_cons.mpr (Or.inr hm))
    by_cases hp : DistancePassed gateway blockNumber w
    · cases hc : consume gateway ctx b w with
      | «error» e =>
        have hs : step gateway ctx blockNumber timestamp b w = (0, w) := by
          unfold step
          rw [if_pos hp]
          simp only [hc]
        simp only [runMany, hs, List.sum_cons, Nat.zero_add]
        exact same_block_actual_batches_le_cap_chain gateway ctx blockNumber timestamp cap hBlock hWidth
          bs w hDist hCap hbs
      | ok r =>
        cases ho : r.outcome with
        | «error» e =>
          have hs : step gateway ctx blockNumber timestamp b w = (0, w) := by
            unfold step
            rw [if_pos hp]
            simp only [hc, ho]
          simp only [runMany, hs, List.sum_cons, Nat.zero_add]
          exact same_block_actual_batches_le_cap_chain gateway ctx blockNumber timestamp cap hBlock hWidth
            bs w hDist hCap hbs
        | ok u =>
          cases u
          obtain ⟨hkeepDist, hkeepCap⟩ := hb w r hc ho
          have hcap : allocated gateway ctx b w ≤ cap * 10^9 := by
            rw [← hCap]
            exact allocated_le_cap gateway ctx b w r hc ho
          have hDist' : 0 < TopupTimingHistory.minDistance gateway r.world := by
            rw [hkeepDist]
            exact hDist
          have hCap' : (blockCap ctx.sender r.world).val = cap := hkeepCap.trans hCap
          by_cases hlim : 0 < totalLimits gateway b w
          · have hs : step gateway ctx blockNumber timestamp b w =
                (allocated gateway ctx b w, lock gateway blockNumber timestamp r.world) := by
              unfold step
              rw [if_pos hp]
              simp only [hc, ho, if_pos hlim]
            have hlocked : TopupTimingHistory.lastBlock gateway
                (lock gateway blockNumber timestamp r.world) = blockNumber := by
              rw [lock_lastBlock]
              exact Nat.mod_eq_of_lt hWidth
            have hDist'' : 0 < TopupTimingHistory.minDistance gateway
                (lock gateway blockNumber timestamp r.world) := by
              rw [lock_minDistance]
              exact hDist'
            have hrest := runMany_locked gateway ctx blockNumber timestamp hBlock bs
              (lock gateway blockNumber timestamp r.world) hlocked hDist''
            simp only [runMany, hs, List.sum_cons]
            rw [hrest]
            simpa using hcap
          · have hzero : allocated gateway ctx b w = 0 := by
              have h1 := allocated_le_totalLimits gateway ctx b w r hc ho
              omega
            have hs : step gateway ctx blockNumber timestamp b w =
                (allocated gateway ctx b w, r.world) := by
              unfold step
              rw [if_pos hp]
              simp only [hc, ho, if_neg hlim]
            simp only [runMany, hs, List.sum_cons, hzero, Nat.zero_add]
            exact same_block_actual_batches_le_cap_chain gateway ctx blockNumber timestamp cap hBlock hWidth
              bs r.world hDist' hCap' hbs
    · have hs := step_blocked gateway ctx blockNumber timestamp b w hp
      simp only [runMany, hs, List.sum_cons, Nat.zero_add]
      exact same_block_actual_batches_le_cap_chain gateway ctx blockNumber timestamp cap hBlock hWidth
        bs w hDist hCap hbs

/-- **Same-block bound on the actual consumer.** On an initialized gateway
(`minBlockDistance ≥ 1`), at a nonzero uint32 block, `n` sequential calls of
`TopupBatchConsumer.run` through the gateway's distance gate and history write
allocate in total at most the packed router block cap (in wei) read at the
first call. At most one call commits a positive allocation: it writes
`lastTopUpBlock`, and every later call of the block fails the gate.

Premises: `blockNumber ≠ 0` (sentinel), `blockNumber < 2^32` (uint32 field),
`0 < minBlockDistance` at entry, and `ConfigStable` for every call (the
batch's callees leave the gateway's `minBlockDistance` field and the router's
cap word unchanged). No `lastTopUpBlock ≤ blockNumber` premise is needed. -/
theorem same_block_actual_batches_le_cap (gateway : Address) (ctx : Context)
    (blockNumber timestamp cap : Nat) (hBlock : blockNumber ≠ 0) (hWidth : blockNumber < 2^32)
    (calls : List Batch) (w : World) (hDist : 0 < TopupTimingHistory.minDistance gateway w)
    (hCap : (blockCap ctx.sender w).val = cap) (hStable : ∀ b ∈ calls, ConfigStable gateway ctx b) :
    (runMany gateway ctx blockNumber timestamp w calls).1.sum ≤ cap * 10^9 :=
  same_block_actual_batches_le_cap_chain gateway ctx blockNumber timestamp cap hBlock hWidth
    calls w hDist hCap hStable

/-- The chain's cap is the registered per-batch cap: with the router cap read
at entry, the bound is `blockCap * GWEI` in the units of
`PTopup2.actual_module_batch_bound`. -/
theorem same_block_actual_batches_le_blockCap (gateway : Address) (ctx : Context)
    (blockNumber timestamp : Nat) (hBlock : blockNumber ≠ 0) (hWidth : blockNumber < 2^32)
    (calls : List Batch) (w : World) (hDist : 0 < TopupTimingHistory.minDistance gateway w)
    (hStable : ∀ b ∈ calls, ConfigStable gateway ctx b) :
    (runMany gateway ctx blockNumber timestamp w calls).1.sum ≤
      (blockCap ctx.sender w).val * PTopup2.GWEI :=
  same_block_actual_batches_le_cap gateway ctx blockNumber timestamp _ hBlock hWidth calls w
    hDist rfl hStable

#print axioms consume_success
#print axioms allocated_le_cap
#print axioms allocated_le_totalLimits
#print axioms lock_stored
#print axioms lock_lastBlock
#print axioms lock_minDistance
#print axioms lock_blockCap
#print axioms locked_blocks
#print axioms runMany_locked
#print axioms same_block_actual_batches_le_cap_chain
#print axioms same_block_actual_batches_le_cap
#print axioms same_block_actual_batches_le_blockCap
#print axioms distance_of_admitted
#print axioms lock_core_eq_update

end LidoSRv3.Audit.Guarantees.PTopup2SameBlock
