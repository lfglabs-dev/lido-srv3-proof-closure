import LidoSRv3.Audit.Source.TopupGatewayConfigWords
import LidoSRv3.Audit.Source.SszStatePlacement
import LidoSRv3.Audit.Source.TopupRouterContinuation

/-! TopUpGateway.sol:163–175 and 204–228 at core pin 17005714.
The length checkLengths and witness loop are separate entry points: role/pause checks
precede the checkLengths; timing, locator and credential checks intervene before the
loop. Typed aligned rows model the loop's array reads, not arbitrary calldata
pointers. Standard SHA and the canonical root response retain their existing
explicit trust boundaries. No module call or timing write is executed here. -/
set_option maxHeartbeats 200000
set_option maxRecDepth 2048

namespace LidoSRv3.Audit.Source.TopupGatewayWitnessBatch
open SszValidatorLeaf SszVerifierEntry SszWrapperIndex SszStatePlacement

abbrev Index := Fin (2^256)

structure Row where
  index : Index
  witness : Witness
  proof : List Digest
  pending : Index
  deriving DecidableEq, Repr

inductive GatewayFault where
  | wrongArrayLength | maxValidatorsExceeded | wrongPubkeyLength
  | invalidSortOrder | divisionByZero | notActivated | pendingOverflow
  | verifier (cause : SszVerifierEntry.Error)
  deriving DecidableEq, Repr

/-- Inputs are the five actual array lengths. Intervening checks are deliberately
not collapsed into a fictitious full-entry composition with `loop`. -/
def checkLengths (cfg : TopupWeiBounds.GatewayConfig) (indices keys operators witnesses pending : Nat) :
    Except GatewayFault Unit :=
  if indices = 0 then .error .wrongArrayLength
  else if keys ≠ indices ∨ operators ≠ indices ∨ witnesses ≠ indices ∨ pending ≠ indices
    then .error .wrongArrayLength
  else if indices > cfg.maxValidators.val then .error .maxValidatorsExceeded
  else .ok ()

theorem checkLengths_iff (cfg : TopupWeiBounds.GatewayConfig) (n k o w p : Nat) :
    checkLengths cfg n k o w p = .ok () ↔
      n ≠ 0 ∧ k = n ∧ o = n ∧ w = n ∧ p = n ∧ n ≤ cfg.maxValidators.val := by
  simp only [checkLengths]
  split <;> rename_i h
  · simp [h]
  · by_cases hk : k = n <;> by_cases ho : o = n <;>
      by_cases hw : w = n <;> by_cases hp : p = n <;>
      simp [h,hk,ho,hw,hp]

def fields (r : Row) : TopupWeiBounds.ValidatorInput :=
  { effective := ⟨r.witness.effectiveBalance.toNat, r.witness.effectiveBalance.isLt⟩
    pending := r.pending
    exitEpoch := ⟨r.witness.exitEpoch.toNat, r.witness.exitEpoch.isLt⟩
    slashed := r.witness.slashed }

/-- An independent natural-number headroom specification; it contains neither
checked arithmetic execution nor a verifier result. -/
def headroom (cfg : TopupWeiBounds.GatewayConfig) (r : Row) : Nat :=
  if r.witness.exitEpoch.toNat ≠ 2^64-1 ∨ r.witness.slashed = true then 0
  else let remaining := cfg.target.val - (r.witness.effectiveBalance.toNat + r.pending.val)
       if remaining < cfg.minTopUp.val then 0 else remaining

def PendingSafe (r : Row) : Prop :=
  r.witness.exitEpoch.toNat = 2^64-1 → r.witness.slashed = false →
    r.witness.effectiveBalance.toNat + r.pending.val < 2^256

instance (r : Row) : Decidable (PendingSafe r) := inferInstanceAs (Decidable (_ → _ → _))

/-- No constructor guard excludes zero SLOTS_PER_EPOCH. Division panic therefore
belongs to execution; the uint64 cast is represented explicitly. -/
def activated (beaconSlot : BitVec 64) (slotsPerEpoch : Index) (w : Witness) : Except GatewayFault Unit :=
  if slotsPerEpoch.val = 0 then .error .divisionByZero
  else if w.activationEpoch.toNat > (beaconSlot.toNat / slotsPerEpoch.val) % (2^64)
    then .error .notActivated else .ok ()

theorem epoch_cast_exact (beaconSlot : BitVec 64) (divisor : Index) :
    (beaconSlot.toNat / divisor.val) % (2^64) = beaconSlot.toNat / divisor.val := by
  apply Nat.mod_eq_of_lt
  exact lt_of_le_of_lt (Nat.div_le_self _ _) beaconSlot.isLt

def ordered (previous : Option Index) (index : Index) : Bool :=
  match previous with | none => true | some p => decide (p.val < index.val)

def rowLimit (precompile : Precompile) (oracle : RootOracle) (scratch : Fin 32 → Byte)
    (gi : Configuration) (cfg : TopupWeiBounds.GatewayConfig) (beacon : BeaconData)
    (slotsPerEpoch : Index) (credentials : Digest) (previous : Option Index) (r : Row) :
    Except GatewayFault Nat :=
  if r.witness.pubkey.length ≠ 48 then .error .wrongPubkeyLength
  else if ordered previous r.index = false then .error .invalidSortOrder
  else do
    activated beacon.slot slotsPerEpoch r.witness
    (sourceEntry precompile oracle scratch gi beacon r.witness r.proof r.index credentials).mapError GatewayFault.verifier
    match TopupWeiBounds.evaluate cfg (fields r) with
    | none => .error .pendingOverflow
    | some n => .ok n

structure Output where
  pubkeys : List (List Byte)
  limits : List Nat
  total : Nat
  deriving DecidableEq, Repr

/-- The accumulator is updated before the next row, exactly as the source's
unchecked loop. Output arrays retain input order. -/
def loop (precompile : Precompile) (oracle : RootOracle) (scratch : Fin 32 → Byte)
    (gi : Configuration) (cfg : TopupWeiBounds.GatewayConfig) (beacon : BeaconData)
    (slotsPerEpoch : Index) (credentials : Digest) : Option Index → Nat → List Row → Except GatewayFault Output
  | _, acc, [] => .ok ⟨[], [], acc⟩
  | previous, acc, r::rs => do
    let n ← rowLimit precompile oracle scratch gi cfg beacon slotsPerEpoch credentials previous r
    let wei := n * TopupWeiBounds.gwei % TopupWeiBounds.wordModulus
    let tail ← loop precompile oracle scratch gi cfg beacon slotsPerEpoch credentials
      (some r.index) ((acc + wei) % TopupWeiBounds.wordModulus) rs
    .ok ⟨r.witness.pubkey :: tail.pubkeys, wei :: tail.limits, tail.total⟩

def Increasing : Option Index → List Row → Prop
  | _, [] => True
  | p, r::rs => ordered p r.index = true ∧ Increasing (some r.index) rs

instance (p : Option Index) (rs : List Row) : Decidable (Increasing p rs) := by
  induction rs generalizing p with
  | nil => exact isTrue trivial
  | cons r rs ih => exact inferInstanceAs (Decidable (_ ∧ _))

theorem evaluate_headroom (cfg : TopupWeiBounds.GatewayConfig) (r : Row) (h : PendingSafe r) :
    TopupWeiBounds.evaluate cfg (fields r) = some (headroom cfg r) := by
  have hp := h
  unfold PendingSafe at hp
  by_cases he : r.witness.exitEpoch.toNat = 2^64-1 <;>
    cases hs : r.witness.slashed <;>
    by_cases hc : cfg.target.val ≤ r.witness.effectiveBalance.toNat + r.pending.val <;>
    by_cases hm : cfg.target.val - (r.witness.effectiveBalance.toNat + r.pending.val) < cfg.minTopUp.val <;>
    simp_all [TopupWeiBounds.evaluate,fields,headroom,TopupWeiBounds.uint64Modulus,
      TopupWeiBounds.wordModulus,Nat.sub_eq_zero_of_le]
  all_goals
    split_ifs <;> simp_all

theorem evaluated_list (cfg : TopupWeiBounds.GatewayConfig) (rows : List Row)
    (hsafe : ∀ r ∈ rows, PendingSafe r) :
    TopupWeiBounds.limits cfg (rows.map fields) = some (rows.map (headroom cfg)) := by
  induction rows with
  | nil => rfl
  | cons r rs ih =>
    simp [TopupWeiBounds.limits,evaluate_headroom cfg r (hsafe r (by simp)),
      ih (fun x hx => hsafe x (by simp [hx]))]

theorem rowLimit_run (precompile : Precompile) (oracle : RootOracle) (scratch : Fin 32 → Byte)
    (gi : Configuration) (cfg : TopupWeiBounds.GatewayConfig) (beacon : BeaconData)
    (divisor : Index) (credentials : Digest) (previous : Option Index) (r : Row)
    (hkey : r.witness.pubkey.length = 48) (horder : ordered previous r.index = true)
    (hd : divisor.val ≠ 0) (ha : r.witness.activationEpoch.toNat ≤ beacon.slot.toNat / divisor.val)
    (hv : sourceEntry precompile oracle scratch gi beacon r.witness r.proof r.index credentials = .ok ())
    (hsafe : PendingSafe r) :
    rowLimit precompile oracle scratch gi cfg beacon divisor credentials previous r = .ok (headroom cfg r) := by
  have hact : activated beacon.slot divisor r.witness = .ok () := by
    unfold activated
    rw [epoch_cast_exact]
    simp [hd,Nat.not_lt.mpr ha]
  simp [rowLimit,hkey,horder,hact,hv,evaluate_headroom cfg r hsafe,Except.mapError,bind,Except.bind]


/-- Generic execution lemma. The canonical consumer below derives its verifier
premise from the registry, rather than making it a final success assumption. -/
theorem loop_run (precompile : Precompile) (oracle : RootOracle) (scratch : Fin 32 → Byte)
    (gi : Configuration) (cfg : TopupWeiBounds.GatewayConfig) (beacon : BeaconData)
    (divisor : Index) (credentials : Digest) (rows : List Row)
    (hd : divisor.val ≠ 0)
    (hrows : ∀ r ∈ rows, r.witness.pubkey.length = 48 ∧
      r.witness.activationEpoch.toNat ≤ beacon.slot.toNat / divisor.val ∧
      sourceEntry precompile oracle scratch gi beacon r.witness r.proof r.index credentials = .ok () ∧
      PendingSafe r) :
    ∀ previous acc, Increasing previous rows →
      loop precompile oracle scratch gi cfg beacon divisor credentials previous acc rows =
        .ok ⟨rows.map (fun r => r.witness.pubkey),
          TopupWeiBounds.weiLimits (rows.map (headroom cfg)),
          TopupWeiBounds.uncheckedSum acc (TopupWeiBounds.weiLimits (rows.map (headroom cfg)))⟩ := by
  induction rows with
  | nil => intros; rfl
  | cons r rs ih =>
    intro previous acc ho
    obtain ⟨hk,ha,hv,hs⟩ := hrows r (by simp)
    have hr := rowLimit_run precompile oracle scratch gi cfg beacon divisor credentials previous r hk ho.1 hd ha hv hs
    have ht := ih (fun x hx => hrows x (by simp [hx])) (some r.index)
      ((acc + headroom cfg r * TopupWeiBounds.gwei % TopupWeiBounds.wordModulus) % TopupWeiBounds.wordModulus) ho.2
    simp only [loop,hr,bind,Except.bind]
    rw [ht]
    rfl

/-- A member selection retains the caller's unrestricted uint256 pending word. -/
structure Selection (values : List ValidatorValue) where
  member : Fin values.length
  pending : Index
  deriving DecidableEq

def canonicalHeader (sha : Sha) (schema : Schema) (values : List ValidatorValue)
    (other : OtherFieldRoots) (beacon : BeaconData) (parentRoot bodyRoot : Digest) : SszWrapperIndex.Tree Digest :=
  headerTree (SszLittleEndianCorrespondence.uint64Chunk beacon.slot)
    (SszLittleEndianCorrespondence.uint64Chunk beacon.proposerIndex)
    parentRoot bodyRoot 0 (stateTree sha schema values other)

/-- The proof is obtained by traversal of the canonical tree, not by selecting a
successful verifier result. The default is unreachable for actual members. -/
def canonicalRow (sha : Sha) (schema : Schema) (values : List ValidatorValue)
    (other : OtherFieldRoots) (hcap : values.length ≤ capacity)
    (beacon : BeaconData) (parentRoot bodyRoot : Digest) (s : Selection values) : Row :=
  { index := memberOffset values hcap s.member
    witness := values[s.member].witness
    proof := (treeBranch (pair sha) (canonicalHeader sha schema values other beacon parentRoot bodyRoot)
      ([false,true,true] ++ statePath s.member.val)).getD []
    pending := s.pending }

theorem canonical_row_entry (sha : Sha) (oracle : RootOracle) (scratch : Fin 32 → Byte)
    (schema : Schema) (values : List ValidatorValue) (other : OtherFieldRoots)
    (hcap : values.length ≤ capacity) (pivot : Fin (2^64)) (beacon : BeaconData)
    (parentRoot bodyRoot credentials : Digest) (suffix : List Byte) (s : Selection values)
    (hwc : values[s.member].withdrawalCredentials = credentials)
    (hresponse : oracle beaconRootsAddress (timestampPayload beacon.childBlockTimestamp) =
      ⟨true,digestBytes (treeDigest (pair sha)
        (canonicalHeader sha schema values other beacon parentRoot bodyRoot)) ++ suffix⟩) :
    let r := canonicalRow sha schema values other hcap beacon parentRoot bodyRoot s
    r.proof.length = 50 ∧ sourceEntry (standardSha sha) oracle scratch (pinnedConfiguration pivot)
      beacon r.witness r.proof r.index credentials = .ok () := by
  obtain ⟨proof,hbranch,hlen,hentry⟩ := canonical_validator_entry sha oracle scratch schema values other
    hcap s.member pivot beacon parentRoot bodyRoot suffix hresponse
  change treeBranch (pair sha) (canonicalHeader sha schema values other beacon parentRoot bodyRoot)
    ([false,true,true] ++ statePath s.member.val) = some proof at hbranch
  simp only [canonicalRow,hbranch,Option.getD_some]
  exact ⟨hlen,hwc ▸ hentry⟩

theorem increasing_of_pairwise (rows : List Row)
    (hs : rows.Pairwise (fun a b => a.index.val < b.index.val)) :
    ∀ previous, (∀ p, previous = some p → ∀ r ∈ rows, p.val < r.index.val) →
      Increasing previous rows := by
  induction rows with
  | nil => intros; trivial
  | cons r rs ih =>
    intro previous hp
    obtain ⟨hr,ht⟩ := List.pairwise_cons.mp hs
    constructor
    · cases previous with
      | none => rfl
      | some p => simpa [ordered] using hp p rfl r (by simp)
    · exact ih ht (some r.index) (by intro p he x hx; cases he; exact hr x hx)

/-- Canonical batch consumer. All verifier calls use one header, one registry,
and one expected credential argument. Mathematical activation/order and checked
pending domains remain explicit; no proof-success or evaluated-limit premise
is accepted. Prefix success is separate from the post-credential loop. -/
theorem canonical_batch (sha : Sha) (oracle : RootOracle) (scratch : Fin 32 → Byte)
    (schema : Schema) (values : List ValidatorValue) (other : OtherFieldRoots)
    (hcap : values.length ≤ capacity) (pivot : Fin (2^64)) (beacon : BeaconData)
    (parentRoot bodyRoot credentials : Digest) (suffix : List Byte)
    (cfg : TopupWeiBounds.GatewayConfig) (divisor : Index) (selected : List (Selection values))
    (hn : selected.length ≠ 0) (hc : selected.length ≤ cfg.maxValidators.val)
    (hd : divisor.val ≠ 0)
    (hsort : selected.Pairwise (fun a b => a.member.val < b.member.val))
    (hactive : ∀ s ∈ selected, values[s.member].witness.activationEpoch.toNat ≤ beacon.slot.toNat / divisor.val)
    (hwc : ∀ s ∈ selected, values[s.member].withdrawalCredentials = credentials)
    (hsafe : ∀ s ∈ selected,
      values[s.member].witness.exitEpoch.toNat = 2^64-1 → values[s.member].witness.slashed = false →
        values[s.member].witness.effectiveBalance.toNat + s.pending.val < 2^256)
    (hresponse : oracle beaconRootsAddress (timestampPayload beacon.childBlockTimestamp) =
      ⟨true,digestBytes (treeDigest (pair sha)
        (canonicalHeader sha schema values other beacon parentRoot bodyRoot)) ++ suffix⟩) :
    let rows := selected.map (canonicalRow sha schema values other hcap beacon parentRoot bodyRoot)
    let ns := rows.map (headroom cfg)
    checkLengths cfg selected.length selected.length selected.length selected.length selected.length = .ok () ∧
    loop (standardSha sha) oracle scratch (pinnedConfiguration pivot) cfg beacon divisor credentials none 0 rows =
      .ok ⟨rows.map (fun r => r.witness.pubkey),TopupWeiBounds.weiLimits ns,(TopupWeiBounds.weiLimits ns).sum⟩ ∧
    TopupWeiBounds.limits cfg (rows.map fields) = some ns ∧
    (TopupWeiBounds.weiLimits ns).sum < 2^256 ∧
    (TopupWeiBounds.weiLimits ns).length = selected.length ∧
    (∀ n ∈ ns, n ≤ cfg.target.val ∧ (n * TopupWeiBounds.gwei % TopupWeiBounds.wordModulus) / TopupWeiBounds.gwei = n) := by
  dsimp only
  let rows := selected.map (canonicalRow sha schema values other hcap beacon parentRoot bodyRoot)
  have hr : ∀ r ∈ rows, r.witness.pubkey.length = 48 ∧
      r.witness.activationEpoch.toNat ≤ beacon.slot.toNat / divisor.val ∧
      sourceEntry (standardSha sha) oracle scratch (pinnedConfiguration pivot) beacon r.witness r.proof r.index credentials = .ok () ∧
      PendingSafe r := by
    intro r hmem
    obtain ⟨s,hs,rfl⟩ := List.mem_map.mp hmem
    exact ⟨values[s.member].pubkeyLength,hactive s hs,
      (canonical_row_entry sha oracle scratch schema values other hcap pivot beacon parentRoot bodyRoot credentials suffix s (hwc s hs) hresponse).2,
      hsafe s hs⟩
  have ho : Increasing none rows := by
    apply increasing_of_pairwise rows
    · have hi : ∀ s : Selection values,
          (canonicalRow sha schema values other hcap beacon parentRoot bodyRoot s).index.val = s.member.val := fun _ => rfl
      simpa only [rows,List.pairwise_map,hi] using hsort
    · intro p he; contradiction
  have hlen : rows.length = selected.length := List.length_map ..
  have heval := evaluated_list cfg rows (fun r h => (hr r h).2.2.2)
  have hcount : (rows.map fields).length ≤ cfg.maxValidators.val := by simpa [hlen] using hc
  obtain ⟨hrt,hfit,hexact⟩ := TopupWeiBounds.gateway_wei_bounds cfg (rows.map fields) (rows.map (headroom cfg)) hcount heval
  have hrun := loop_run (standardSha sha) oracle scratch (pinnedConfiguration pivot) cfg beacon divisor credentials rows hd hr none 0 ho
  rw [hexact] at hrun
  refine ⟨(checkLengths_iff ..).mpr ⟨hn,rfl,rfl,rfl,rfl,hc⟩,hrun,heval,hfit,?_,?_⟩
  · simp only [TopupWeiBounds.weiLimits,List.length_map]
  · intro n hmem
    exact ⟨(TopupWeiBounds.limits_bounds cfg _ _ heval).2 n hmem,hrt n hmem⟩

/-- Every successful row evaluates the fields of the very witness verified by
that row; this observation lemma imposes no canonical-membership assumption. -/
theorem rowLimit_evaluated (precompile : Precompile) (oracle : RootOracle) (scratch : Fin 32 → Byte)
    (gi : Configuration) (cfg : TopupWeiBounds.GatewayConfig) (beacon : BeaconData)
    (divisor : Index) (credentials : Digest) (previous : Option Index) (r : Row) (n : Nat)
    (hr : rowLimit precompile oracle scratch gi cfg beacon divisor credentials previous r = .ok n) :
    TopupWeiBounds.evaluate cfg (fields r) = some n := by
  by_cases hk : r.witness.pubkey.length = 48
  · by_cases ho : ordered previous r.index = false
    · simp [rowLimit,hk,ho] at hr
    · simp only [rowLimit,hk,ne_eq,not_true_eq_false,if_false,ho,bind,Except.bind] at hr
      cases ha : activated beacon.slot divisor r.witness with
      | «error» cause => simp [ha] at hr
      | ok u =>
        cases hv : sourceEntry precompile oracle scratch gi beacon r.witness r.proof r.index credentials with
        | «error» cause => simp [ha,hv,Except.mapError] at hr
        | ok v =>
          cases he : TopupWeiBounds.evaluate cfg (fields r) with
          | none => simp [ha,hv,he,Except.mapError] at hr
          | some m => simpa [ha,hv,he,Except.mapError] using hr
  · simp [rowLimit,hk] at hr

/-- Successful execution exposes the computed arrays and accumulator, rather
than trusting separately supplied limits. Failures have no output record. -/
theorem loop_spec (precompile : Precompile) (oracle : RootOracle) (scratch : Fin 32 → Byte)
    (gi : Configuration) (cfg : TopupWeiBounds.GatewayConfig) (beacon : BeaconData)
    (divisor : Index) (credentials : Digest) (rows : List Row) :
    ∀ previous acc out,
      loop precompile oracle scratch gi cfg beacon divisor credentials previous acc rows = .ok out →
      ∃ ns, TopupWeiBounds.limits cfg (rows.map fields) = some ns ∧
        out.pubkeys = rows.map (fun r => r.witness.pubkey) ∧
        out.limits = TopupWeiBounds.weiLimits ns ∧
        out.total = TopupWeiBounds.uncheckedSum acc out.limits := by
  induction rows with
  | nil =>
    intro previous acc out hr
    simp only [loop,Except.ok.injEq] at hr
    subst out
    exact ⟨[],rfl,rfl,rfl,rfl⟩
  | cons r rs ih =>
    intro previous acc out hr
    cases he : rowLimit precompile oracle scratch gi cfg beacon divisor credentials previous r with
    | «error» cause => simp [loop,he,bind,Except.bind] at hr
    | ok n =>
      have hv := rowLimit_evaluated precompile oracle scratch gi cfg beacon divisor credentials previous r n he
      simp only [loop,he,bind,Except.bind] at hr
      cases ht : loop precompile oracle scratch gi cfg beacon divisor credentials (some r.index)
          ((acc + n * TopupWeiBounds.gwei % TopupWeiBounds.wordModulus) % TopupWeiBounds.wordModulus) rs with
      | «error» cause => rw [ht] at hr; contradiction
      | ok tail =>
        simp only [ht,Except.ok.injEq] at hr
        subst out
        obtain ⟨ns,hns,hkeys,hlimits,htotal⟩ := ih _ _ tail ht
        refine ⟨n::ns,?_,?_,?_,?_⟩
        · simp [TopupWeiBounds.limits,hv,hns]
        · simp [hkeys]
        · simp [TopupWeiBounds.weiLimits,hlimits]
        · exact htotal

open TrioReserve1.Live in
/-- These are the exact copied keys and computed limit words sent to the router.
The module's returned allocation words remain arbitrary. -/
def routerInput (out : Output) (moduleId roundedTarget : Word) (allocations : List Word) :
    TopupRouterContinuation.Input :=
  { moduleId, roundedTarget, allocations
    pubkeys := out.pubkeys.map (List.map (fun b => UInt8.ofNat b.toNat))
    limits := out.limits.map word }

open TrioReserve1.Live in
theorem router_keys_exact (out : Output) (moduleId roundedTarget : Word) (allocations : List Word) :
    TopupRouterContinuation.keys (routerInput out moduleId roundedTarget allocations).pubkeys =
      out.pubkeys.map (List.map BitVec.toNat) := by
  have hb : ∀ b : Byte, (UInt8.ofNat b.toNat).toNat = b.toNat := by
    intro b
    exact Nat.mod_eq_of_lt b.isLt
  simp only [TopupRouterContinuation.keys,routerInput,List.map_map,Function.comp_def,hb]

open TrioReserve1.Live in
theorem word_value (n : Nat) : (word n).val = n % TopupWeiBounds.wordModulus := rfl

open TrioReserve1.Live in
theorem wei_word_values (ns : List Nat) :
    TopupRouterContinuation.values ((TopupWeiBounds.weiLimits ns).map word) =
      TopupWeiBounds.weiLimits ns := by
  simp only [TopupRouterContinuation.values,TopupWeiBounds.weiLimits,List.map_map,
    Function.comp_def,word_value,Nat.mod_mod]

open TrioReserve1.Live in
/-- A concrete bridge to PR275. The only successful check assumed here is the
observed router admission of its arbitrary returned allocation words. Gateway
limits, count bounds and word conversion are derived from its executed loop.
Minimum nonzero amounts remain an actual later helper success condition. -/
theorem router_checked_from_loop (precompile : Precompile) (oracle : RootOracle) (scratch : Fin 32 → Byte)
    (gi : Configuration) (cfg : TopupWeiBounds.GatewayConfig) (beacon : BeaconData)
    (divisor : Index) (credentials : Digest) (rows : List Row) (out : Output)
    (hc : rows.length ≤ cfg.maxValidators.val)
    (hr : loop precompile oracle scratch gi cfg beacon divisor credentials none 0 rows = .ok out)
    (moduleId roundedTarget : Word) (allocations : List Word) (total : Nat)
    (hcheck : TopupRouterContinuation.guardSum (TopupRouterContinuation.values allocations)
      (TopupRouterContinuation.values (routerInput out moduleId roundedTarget allocations).limits) 0 = .ok total)
    (hmin : ∀ a ∈ TopupRouterContinuation.values allocations, a ≠ 0 → 10^18 ≤ a) :
    out.total = out.limits.sum ∧ out.total < 2^256 ∧
    total = SolidityTopup.allocSum (TopupRouterContinuation.values allocations) ∧ total < 2^256 ∧
      TopupBeaconBatch.AmountsAdmitted (TopupRouterContinuation.values allocations) := by
  obtain ⟨ns,heval,_hkeys,hlimits,htotal⟩ := loop_spec precompile oracle scratch gi cfg beacon divisor credentials rows none 0 out hr
  have hcount : (rows.map fields).length ≤ cfg.maxValidators.val := by simpa using hc
  obtain ⟨_,hfit,hexact⟩ := TopupWeiBounds.gateway_wei_bounds cfg (rows.map fields) ns hcount heval
  have hwords : TopupRouterContinuation.values (routerInput out moduleId roundedTarget allocations).limits = TopupWeiBounds.weiLimits ns := by
    change TopupRouterContinuation.values (out.limits.map word) = _
    exact (congrArg (fun xs => TopupRouterContinuation.values (xs.map word)) hlimits).trans (wei_word_values ns)
  have hc275 := TopupRouterContinuation.checked_fields cfg (rows.map fields) ns
    (routerInput out moduleId roundedTarget allocations) total hcount heval hwords hcheck hmin
  have ht : out.total = (TopupWeiBounds.weiLimits ns).sum :=
    htotal.trans ((congrArg (TopupWeiBounds.uncheckedSum 0) hlimits).trans hexact)
  have heq : out.total = out.limits.sum := ht.trans (congrArg List.sum hlimits).symm
  have houtfit : out.total < 2^256 := ht.symm ▸ hfit
  exact ⟨heq,houtfit,hc275⟩

end LidoSRv3.Audit.Source.TopupGatewayWitnessBatch
