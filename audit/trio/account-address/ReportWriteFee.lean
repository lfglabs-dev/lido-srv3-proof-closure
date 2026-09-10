import PAccount1

/-!
# ACCOUNT physical slots into the fee getter

Independent slice at pinned `lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`.

* `SRLib.sol:873-892` `_reportValidatorBalancesByStakingModule`: the uint64 cast
  (884), the low-uint64 write on the physical `ModuleStateAccounting` word
  (886), the checked uint64 total (888), and the router accounting write (891).
  Validation (853-870) is the `PAccount1` model.
* `StakingRouter.sol:808-873` `getStakingRewardsDistribution` and `885-893`
  `_computeModuleFee`: total from the router word (819), empty success when the
  total is zero (820, 828-829), registered-id lookup in registration order
  (835), allocation from the module word (836), zero-allocation skip (839),
  config decoded from the physical config word (843-844), uint96 casts
  (892-893), Stopped modules paying only the treasury (851-853), the checked
  uint96 total (854), and the post-loop `assert` (862).
* `Accounting.sol:265-301` `_calculateProtocolFees`, `306-333`
  `_calculateTotalProtocolFeeShares`, `335-358` `_calculateFeeDistribution`.

The report writer and the fee getter use the same `Core.read` / `Core.write`
on the same `Layout` slot keys, so the getter consumes exactly the words the
report wrote.  `Layout.moduleBase` stands for the keccak-derived `moduleStates`
mapping key; the hash is not computed, so its collision-freedom
(`Layout.Separated`) is a caller premise.  P-ACCOUNT stays OPEN: this is
source-level Lean evidence, not compiler, EVM, or deployment correspondence.
-/

namespace AccountAddress.ReportWriteFee

open AccountAddress.PAccount1

/-! ## Constants (StakingRouter 56, SRUtils 17, SRTypes 40-44) -/

def FEE_PRECISION_POINTS : Nat := 10 ^ 20
def TOTAL_BASIS_POINTS : Nat := 10000
def STATUS_STOPPED : Nat := 2
def STATUS_COUNT : Nat := 3

def two16 : Nat := 2 ^ 16
def two96 : Nat := 2 ^ 96
def two160 : Nat := 2 ^ 160
def two176 : Nat := 2 ^ 176
def two224 : Nat := 2 ^ 224
def two256 : Nat := 2 ^ 256

/-- SRUtils `_fromGwei`: gwei to wei on uint256. -/
def fromGwei (gwei : Nat) : Nat := gwei * 1000000000

/-- Solidity `uint64(x)` truncating cast (SRLib 884). -/
def uint64 (x : Nat) : Nat := x % two64

/-- Solidity `uint96(x)` truncating cast (StakingRouter 892-893). -/
def uint96 (x : Nat) : Nat := x % two96

/-! ## Physical storage -/

/-- Storage slot keys are uint256 words; `Nat` keeps `omega` applicable. -/
abbrev StorageWord := Fin two256

def zeroWord : StorageWord := ⟨0, by simp [two256]⟩

/-- Contract storage as a slot map. Unwritten slots read zero (EVM default). -/
structure Core where
  slots : List (Nat × StorageWord)
  deriving Repr, DecidableEq

namespace Core

def read (c : Core) (s : Nat) : StorageWord :=
  match c.slots.find? (fun p => p.1 == s) with
  | some p => p.2
  | none => zeroWord

def write (c : Core) (s : Nat) (w : StorageWord) : Core := ⟨(s, w) :: c.slots⟩

theorem read_write_same (c : Core) (s : Nat) (w : StorageWord) :
    (c.write s w).read s = w := by
  simp [read, write]

theorem read_write_other (c : Core) {s t : Nat} (w : StorageWord) (h : s ≠ t) :
    (c.write s w).read t = c.read t := by
  have hb : (s == t) = false := by simp [h]
  simp [read, write, hb]

end Core

/-- Pinned router slot keys (SRStorage 14-31, SRTypes 175-195). `moduleBase id`
stands for `keccak256(abi.encode(id, routerBase))`, the `moduleStates` mapping
key at router slot 0. A `ModuleState` occupies four consecutive words: config
(+0), deposits (+1), accounting (+2), name (+3). Router accounting is router
slot 3. The hash is not computed here. -/
structure Layout where
  routerBase : Nat
  moduleBase : Nat → Nat

namespace Layout

def routerAccountingSlot (L : Layout) : Nat := L.routerBase + 3
def moduleConfigSlot (L : Layout) (id : Nat) : Nat := L.moduleBase id
def moduleAccountingSlot (L : Layout) (id : Nat) : Nat := L.moduleBase id + 2

/-- Collision-freedom of the keccak-derived keys over the registered ids and
the six-word router struct. This caller premise stands in for the uncomputed
hash and keeps P-ACCOUNT OPEN. -/
structure Separated (L : Layout) (ids : List Nat) : Prop where
  module_gap : ∀ a ∈ ids, ∀ b ∈ ids, a ≠ b →
    L.moduleBase a + 4 ≤ L.moduleBase b ∨ L.moduleBase b + 4 ≤ L.moduleBase a
  router_gap : ∀ a ∈ ids,
    L.moduleBase a + 4 ≤ L.routerBase ∨ L.routerBase + 6 ≤ L.moduleBase a

theorem Separated.acc_ne_acc {L : Layout} {ids : List Nat} (h : L.Separated ids)
    {a b : Nat} (ha : a ∈ ids) (hb : b ∈ ids) (hab : a ≠ b) :
    L.moduleAccountingSlot a ≠ L.moduleAccountingSlot b := by
  have := h.module_gap a ha b hb hab
  intro heq
  simp only [moduleAccountingSlot] at heq
  omega

theorem Separated.acc_ne_router {L : Layout} {ids : List Nat} (h : L.Separated ids)
    {a : Nat} (ha : a ∈ ids) : L.moduleAccountingSlot a ≠ L.routerAccountingSlot := by
  have := h.router_gap a ha
  intro heq
  simp only [moduleAccountingSlot, routerAccountingSlot] at heq
  omega

theorem Separated.config_ne_acc {L : Layout} {ids : List Nat} (h : L.Separated ids)
    {a b : Nat} (ha : a ∈ ids) (hb : b ∈ ids) :
    L.moduleConfigSlot a ≠ L.moduleAccountingSlot b := by
  intro heq
  simp only [moduleConfigSlot, moduleAccountingSlot] at heq
  by_cases hab : a = b
  · subst hab
    omega
  · have := h.module_gap a ha b hb hab
    omega

theorem Separated.config_ne_router {L : Layout} {ids : List Nat} (h : L.Separated ids)
    {a : Nat} (ha : a ∈ ids) : L.moduleConfigSlot a ≠ L.routerAccountingSlot := by
  have := h.router_gap a ha
  intro heq
  simp only [moduleConfigSlot, routerAccountingSlot] at heq
  omega

end Layout

/-! ## Packed low-uint64 write on a physical word -/

def writeLow64Storage (w : StorageWord) (v : Nat) : StorageWord :=
  ⟨writeLow64 w.val v % two256, Nat.mod_lt _ (by simp [two256])⟩

theorem writeLow64_lt_two256 (w : StorageWord) (v : Nat) (hv : v < two64) :
    writeLow64 w.val v < two256 := by
  have hw := w.isLt
  change w.val < 115792089237316195423570985008687907853269984665640564039457584007913129639936 at hw
  change v < 18446744073709551616 at hv
  simp only [writeLow64, aboveLow64, two64, two256]
  omega

theorem writeLow64Storage_exact (w : StorageWord) (v : Nat) (hv : v < two64) :
    (writeLow64Storage w v).val = writeLow64 w.val v := by
  simp [writeLow64Storage, Nat.mod_eq_of_lt (writeLow64_lt_two256 w v hv)]

theorem low64_writeLow64Storage (w : StorageWord) (v : Nat) (hv : v < two64) :
    low64 (writeLow64Storage w v).val = v := by
  rw [writeLow64Storage_exact w v hv]
  exact low64_writeLow64 w.val v hv

theorem aboveLow64_writeLow64Storage (w : StorageWord) (v : Nat) (hv : v < two64) :
    aboveLow64 (writeLow64Storage w v).val = aboveLow64 w.val := by
  rw [writeLow64Storage_exact w v hv]
  exact aboveLow64_writeLow64 w.val v hv

theorem uint64_lt (x : Nat) : uint64 x < two64 := Nat.mod_lt _ (by simp [two64])

theorem uint64_eq_of_le_max (x : Nat) (h : x ≤ maxValueGwei) : uint64 x = x := by
  apply Nat.mod_eq_of_lt
  have : maxValueGwei < two64 := by decide
  omega

theorem sum_map_uint64_of_valid (amounts : List Nat)
    (h : ∀ a ∈ amounts, a ≤ maxValueGwei) : (amounts.map uint64).sum = amounts.sum := by
  induction amounts with
  | nil => rfl
  | cons a as ih =>
    simp only [List.map_cons, List.sum_cons]
    rw [uint64_eq_of_le_max a (h a (by simp)), ih (fun x hx => h x (by simp [hx]))]

/-! ## Report writer (SRLib 873-892) -/

/-- SRLib 881-889: per reported id, the uint64 cast, the low-uint64 write on
the physical accounting word, then the checked uint64 accumulation. -/
def writeReportRows (L : Layout) : List Nat → List Nat → Nat → Core → Except Error (Core × Nat)
  | [], [], total, core => .ok (core, total)
  | id :: ids, amount :: amounts, total, core =>
      let value := uint64 amount
      let slot := L.moduleAccountingSlot id
      let core' := core.write slot (writeLow64Storage (core.read slot) value)
      match checkedAdd64 total value with
      | .error e => .error e
      | .ok next => writeReportRows L ids amounts next core'
  | _, _, _, _ => .error .arraysLengthMismatch

theorem checkedAdd64_ok {a b n : Nat} (h : checkedAdd64 a b = .ok n) :
    n = a + b ∧ a + b < two64 := by
  unfold checkedAdd64 at h
  split at h
  · exact ⟨(Except.ok.inj h).symm, by assumption⟩
  · cases h

theorem writeReportRows_frame (L : Layout) (ids : List Nat) :
    ∀ (amounts : List Nat) (total : Nat) (core core' : Core) (total' : Nat),
      writeReportRows L ids amounts total core = .ok (core', total') →
      ∀ s : Nat, (∀ id ∈ ids, s ≠ L.moduleAccountingSlot id) → core'.read s = core.read s := by
  induction ids with
  | nil =>
    intro amounts total core core' total' h s _
    cases amounts with
    | nil =>
      simp only [writeReportRows, Except.ok.injEq, Prod.mk.injEq] at h
      obtain ⟨rfl, rfl⟩ := h
      rfl
    | cons _ _ => simp [writeReportRows] at h
  | cons id ids ih =>
    intro amounts total core core' total' h s hs
    cases amounts with
    | nil => simp [writeReportRows] at h
    | cons amount amounts =>
      simp only [writeReportRows] at h
      split at h
      · cases h
      · rename_i next _
        have hrest := ih amounts next _ core' total' h s (fun i hi => hs i (by simp [hi]))
        rw [hrest]
        exact Core.read_write_other _ _ (Ne.symm (hs id (by simp)))

theorem writeReportRows_total (L : Layout) (ids : List Nat) :
    ∀ (amounts : List Nat) (total : Nat) (core core' : Core) (total' : Nat),
      writeReportRows L ids amounts total core = .ok (core', total') →
      total' = total + (amounts.map uint64).sum ∧ (total < two64 → total' < two64) := by
  induction ids with
  | nil =>
    intro amounts total core core' total' h
    cases amounts with
    | nil =>
      simp only [writeReportRows, Except.ok.injEq, Prod.mk.injEq] at h
      obtain ⟨rfl, rfl⟩ := h
      simp
    | cons _ _ => simp [writeReportRows] at h
  | cons id ids ih =>
    intro amounts total core core' total' h
    cases amounts with
    | nil => simp [writeReportRows] at h
    | cons amount amounts =>
      simp only [writeReportRows] at h
      split at h
      · cases h
      · rename_i next hnext
        obtain ⟨hn, hlt⟩ := checkedAdd64_ok hnext
        obtain ⟨h1, h2⟩ := ih amounts next _ core' total' h
        refine ⟨?_, fun _ => h2 (by omega)⟩
        simp only [List.map_cons, List.sum_cons]
        omega

theorem writeReportRows_read (L : Layout) (ids : List Nat) :
    ∀ (amounts : List Nat) (total : Nat) (core core' : Core) (total' : Nat),
      writeReportRows L ids amounts total core = .ok (core', total') →
      ids.Nodup →
      (∀ a ∈ ids, ∀ b ∈ ids, a ≠ b → L.moduleAccountingSlot a ≠ L.moduleAccountingSlot b) →
      ∀ id amount, (id, amount) ∈ ids.zip amounts →
        (core'.read (L.moduleAccountingSlot id)).val =
          writeLow64 (core.read (L.moduleAccountingSlot id)).val (uint64 amount) := by
  induction ids with
  | nil =>
    intro amounts total core core' total' _ _ _ id amount hmem
    simp at hmem
  | cons i is ih =>
    intro amounts total core core' total' h hnodup hsep id amount hmem
    cases amounts with
    | nil => simp at hmem
    | cons a as =>
      simp only [writeReportRows] at h
      split at h
      · cases h
      · rename_i next _
        simp only [List.zip_cons_cons, List.mem_cons, Prod.mk.injEq] at hmem
        simp only [List.nodup_cons] at hnodup
        obtain ⟨hnotin, hnodup'⟩ := hnodup
        rcases hmem with ⟨hid, ha⟩ | hmem
        · rw [hid, ha]
          have hframe := writeReportRows_frame L is as next _ core' total' h
            (L.moduleAccountingSlot i)
            (fun j hj => hsep i (by simp) j (by simp [hj]) (fun hij => hnotin (hij ▸ hj)))
          rw [hframe, Core.read_write_same]
          exact writeLow64Storage_exact _ _ (uint64_lt a)
        · have hsep' : ∀ a ∈ is, ∀ b ∈ is, a ≠ b →
              L.moduleAccountingSlot a ≠ L.moduleAccountingSlot b :=
            fun a ha b hb hab => hsep a (by simp [ha]) b (by simp [hb]) hab
          rw [ih as next _ core' total' h hnodup' hsep' id amount hmem]
          have hid : id ∈ is := (List.of_mem_zip hmem).1
          have hne : L.moduleAccountingSlot i ≠ L.moduleAccountingSlot id :=
            hsep i (by simp) id (by simp [hid]) (fun hii => hnotin (hii ▸ hid))
          rw [Core.read_write_other _ _ hne]

inductive ReportOutcome where
  | reverted (error : Error) (rollback : Core)
  | committed (post : Core)
  deriving Repr, DecidableEq

/-- SRLib 873-892 over physical storage: source length guard, interleaved
id/amount validation (`PAccount1.validateInterleaved`), per-module physical
writes with the checked uint64 total, then the router accounting write. Every
error rolls the storage back to the supplied snapshot. -/
def reportValidatorBalances (L : Layout) (registeredIds reportedIds balancesGwei : List Nat)
    (core : Core) : ReportOutcome :=
  if reportedIds.length != registeredIds.length ||
      balancesGwei.length != registeredIds.length then
    .reverted .arraysLengthMismatch core
  else
    match validateInterleaved registeredIds reportedIds balancesGwei with
    | .error e => .reverted e core
    | .ok _ =>
      match writeReportRows L reportedIds balancesGwei 0 core with
      | .error e => .reverted e core
      | .ok (core', total) =>
        .committed (core'.write L.routerAccountingSlot
          (writeLow64Storage (core'.read L.routerAccountingSlot) total))

theorem validateInterleaved_ok (registered reported amounts : List Nat)
    (h : validateInterleaved registered reported amounts = .ok ()) :
    reported = registered ∧ ∀ a ∈ amounts, a ≤ maxValueGwei := by
  induction registered generalizing reported amounts with
  | nil =>
    cases reported with
    | cons _ _ => cases amounts <;> simp [validateInterleaved] at h
    | nil =>
      cases amounts with
      | cons _ _ => simp [validateInterleaved] at h
      | nil => exact ⟨rfl, by simp⟩
  | cons e es ih =>
    cases reported with
    | nil => cases amounts <;> simp [validateInterleaved] at h
    | cons r rs =>
      cases amounts with
      | nil => simp [validateInterleaved] at h
      | cons a as =>
        simp only [validateInterleaved] at h
        split at h
        · cases h
        · split at h
          · cases h
          · rename_i hne hle
            obtain ⟨h1, h2⟩ := ih rs as h
            have her : e = r := by simpa using hne
            refine ⟨by rw [h1, her], ?_⟩
            intro x hx
            simp only [List.mem_cons] at hx
            rcases hx with rfl | hx
            · omega
            · exact h2 x hx

theorem report_reverted_restores (L : Layout) (reg rep bal : List Nat) (core rollback : Core)
    (e : Error) (h : reportValidatorBalances L reg rep bal core = .reverted e rollback) :
    rollback = core := by
  unfold reportValidatorBalances at h
  split at h
  · cases h; rfl
  · split at h
    · cases h; rfl
    · split at h
      · cases h; rfl
      · cases h

theorem report_committed_spec (L : Layout) (reg rep bal : List Nat) (core post : Core)
    (h : reportValidatorBalances L reg rep bal core = .committed post) :
    rep = reg ∧ (∀ a ∈ bal, a ≤ maxValueGwei) ∧ bal.length = reg.length ∧
    ∃ core' total, writeReportRows L rep bal 0 core = .ok (core', total) ∧
      post = core'.write L.routerAccountingSlot
        (writeLow64Storage (core'.read L.routerAccountingSlot) total) := by
  unfold reportValidatorBalances at h
  split at h
  · cases h
  · rename_i hlen
    split at h
    · cases h
    · rename_i hval
      split at h
      · cases h
      · rename_i hrows
        cases h
        obtain ⟨h1, h2⟩ := validateInterleaved_ok reg rep bal hval
        simp at hlen
        exact ⟨h1, h2, hlen.2, _, _, hrows, rfl⟩

/-- Router accounting word after a committed report: the low uint64 is the
gwei sum (SRLib 891) and the upper bits are untouched. -/
theorem report_committed_router (L : Layout) (reg rep bal : List Nat) (core post : Core)
    (hsep : L.Separated reg)
    (h : reportValidatorBalances L reg rep bal core = .committed post) :
    low64 (post.read L.routerAccountingSlot).val = bal.sum ∧
    aboveLow64 (post.read L.routerAccountingSlot).val =
      aboveLow64 (core.read L.routerAccountingSlot).val ∧
    bal.sum < two64 := by
  obtain ⟨hrep, hval, _, core', total, hrows, hpost⟩ := report_committed_spec L reg rep bal core post h
  obtain ⟨htot, hlt⟩ := writeReportRows_total L rep bal 0 core core' total hrows
  rw [sum_map_uint64_of_valid bal hval] at htot
  have hpos : 0 < two64 := by simp [two64]
  have htlt : total < two64 := hlt hpos
  have hsum : bal.sum = total := by omega
  have hframe : core'.read L.routerAccountingSlot = core.read L.routerAccountingSlot :=
    writeReportRows_frame L rep bal 0 core core' total hrows L.routerAccountingSlot
      (fun id hid => (hsep.acc_ne_router (hrep ▸ hid)).symm)
  subst hpost
  rw [Core.read_write_same, low64_writeLow64Storage _ _ htlt,
    aboveLow64_writeLow64Storage _ _ htlt, hframe]
  exact ⟨hsum.symm, rfl, hsum ▸ htlt⟩

/-- Module accounting words after a committed report: the low uint64 of the
registered id's word is its reported gwei (SRLib 886) and the upper bits,
including `exitedValidatorsCount`, are untouched. -/
theorem report_committed_module (L : Layout) (reg rep bal : List Nat) (core post : Core)
    (hsep : L.Separated reg) (hnodup : reg.Nodup)
    (h : reportValidatorBalances L reg rep bal core = .committed post) :
    ∀ id amount, (id, amount) ∈ reg.zip bal →
      low64 (post.read (L.moduleAccountingSlot id)).val = amount ∧
      aboveLow64 (post.read (L.moduleAccountingSlot id)).val =
        aboveLow64 (core.read (L.moduleAccountingSlot id)).val := by
  intro id amount hmem
  obtain ⟨hrep, hval, _, core', total, hrows, hpost⟩ := report_committed_spec L reg rep bal core post h
  subst hrep
  have hid : id ∈ rep := (List.of_mem_zip hmem).1
  have hamount : amount ∈ bal := (List.of_mem_zip hmem).2
  have hread := writeReportRows_read L rep bal 0 core core' total hrows hnodup
    (fun a ha b hb hab => hsep.acc_ne_acc ha hb hab) id amount hmem
  have hne : L.routerAccountingSlot ≠ L.moduleAccountingSlot id := (hsep.acc_ne_router hid).symm
  subst hpost
  rw [Core.read_write_other _ _ hne, hread, uint64_eq_of_le_max amount (hval amount hamount)]
  have hlt : amount < two64 := by
    have : maxValueGwei < two64 := by decide
    have := hval amount hamount
    omega
  exact ⟨low64_writeLow64 _ _ hlt, aboveLow64_writeLow64 _ _ hlt⟩

/-- Every slot outside the router accounting word and the registered
accounting words is untouched by a committed report. -/
theorem report_committed_frame (L : Layout) (reg rep bal : List Nat) (core post : Core)
    (h : reportValidatorBalances L reg rep bal core = .committed post) :
    ∀ s : Nat, s ≠ L.routerAccountingSlot → (∀ id ∈ reg, s ≠ L.moduleAccountingSlot id) →
      post.read s = core.read s := by
  intro s hrouter hacc
  obtain ⟨hrep, _, _, core', total, hrows, hpost⟩ := report_committed_spec L reg rep bal core post h
  subst hrep
  subst hpost
  rw [Core.read_write_other _ _ (Ne.symm hrouter)]
  exact writeReportRows_frame L rep bal 0 core core' total hrows s hacc

/-- The physical config words the fee getter decodes are untouched by the report. -/
theorem report_committed_config (L : Layout) (reg rep bal : List Nat) (core post : Core)
    (hsep : L.Separated reg)
    (h : reportValidatorBalances L reg rep bal core = .committed post) :
    ∀ id ∈ reg, post.read (L.moduleConfigSlot id) = core.read (L.moduleConfigSlot id) := by
  intro id hid
  exact report_committed_frame L reg rep bal core post h _ (hsep.config_ne_router hid)
    (fun j hj => hsep.config_ne_acc hid hj)

/-! ## Fee getter (StakingRouter 808-873, 885-893) -/

structure ModuleConfig where
  moduleAddress : Nat
  moduleFee : Nat
  treasuryFee : Nat
  status : Nat
  deriving Repr, DecidableEq

/-- SRTypes 118-135 packed `ModuleStateConfig`: address bits 0..159, moduleFee
160..175, treasuryFee 176..191, stakeShareLimit 192..207,
priorityExitShareThreshold 208..223, status 224..231, wc type 232..239. -/
def decodeConfig (w : StorageWord) : ModuleConfig :=
  { moduleAddress := w.val % two160
    moduleFee := w.val / two160 % two16
    treasuryFee := w.val / two176 % two16
    status := w.val / two224 % 256 }

/-- SRUtils 62-64 through StakingRouter 836. -/
def moduleAllocationWei (L : Layout) (core : Core) (id : Nat) : Nat :=
  fromGwei (low64 (core.read (L.moduleAccountingSlot id)).val)

/-- SRUtils 67-69 through StakingRouter 819. -/
def routerTotalWei (L : Layout) (core : Core) : Nat :=
  fromGwei (low64 (core.read L.routerAccountingSlot).val)

structure ModuleFee where
  moduleFee : Nat
  treasuryFee : Nat
  deriving Repr, DecidableEq

/-- StakingRouter 885-893: one floor for the share, two independent floors for
the fees, each truncated by the uint96 cast. -/
def computeModuleFee (allocationWei totalWei : Nat) (cfg : ModuleConfig) : ModuleFee :=
  let share := allocationWei * FEE_PRECISION_POINTS / totalWei
  { moduleFee := uint96 (share * cfg.moduleFee / TOTAL_BASIS_POINTS)
    treasuryFee := uint96 (share * cfg.treasuryFee / TOTAL_BASIS_POINTS) }

/-- Source-visible panics of the getter, in the order the pinned code can
produce them. -/
inductive GetterError where
  /-- 843: loading an out-of-range enum byte from storage, Panic(0x21). -/
  | statusOutOfRange (id status : Nat)
  /-- 854: checked uint96 addition, Panic(0x11). -/
  | totalFeeOverflow
  /-- 862: `assert(totalFee <= precisionPoints)`, Panic(0x01). -/
  | totalFeeAboveCap
  deriving Repr, DecidableEq

structure Distribution where
  recipients : List Nat
  stakingModuleIds : List Nat
  stakingModuleFees : List Nat
  totalFee : Nat
  precisionPoints : Nat
  deriving Repr, DecidableEq

/-- StakingRouter 834-856 in registration order. Zero-allocation modules are
skipped (839); Stopped modules record no module fee but still add to the total
(851-854). Arrays are returned already shrunk (865-870). -/
def rewardedRows (L : Layout) (core : Core) (totalWei : Nat) :
    List Nat → Nat → Except GetterError (List Nat × List Nat × List Nat × Nat)
  | [], totalFee => .ok ([], [], [], totalFee)
  | id :: ids, totalFee =>
      if moduleAllocationWei L core id = 0 then rewardedRows L core totalWei ids totalFee
      else
        let cfg := decodeConfig (core.read (L.moduleConfigSlot id))
        if STATUS_COUNT ≤ cfg.status then .error (.statusOutOfRange id cfg.status)
        else
          let fee := computeModuleFee (moduleAllocationWei L core id) totalWei cfg
          let recorded := if cfg.status = STATUS_STOPPED then 0 else fee.moduleFee
          if two96 ≤ totalFee + fee.treasuryFee + fee.moduleFee then .error .totalFeeOverflow
          else
            match rewardedRows L core totalWei ids (totalFee + fee.treasuryFee + fee.moduleFee) with
            | .error e => .error e
            | .ok (recipients, moduleIds, fees, total) =>
              .ok (cfg.moduleAddress :: recipients, id :: moduleIds, recorded :: fees, total)

/-- StakingRouter 820: no modules are considered while the router total is zero. -/
def stakingModulesCount (L : Layout) (registeredIds : List Nat) (core : Core) : Nat :=
  if routerTotalWei L core = 0 then 0 else registeredIds.length

/-- StakingRouter 808-873. -/
def getStakingRewardsDistribution (L : Layout) (registeredIds : List Nat) (core : Core) :
    Except GetterError Distribution :=
  if stakingModulesCount L registeredIds core = 0 then .ok ⟨[], [], [], 0, FEE_PRECISION_POINTS⟩
  else
    match rewardedRows L core (routerTotalWei L core) registeredIds 0 with
    | .error e => .error e
    | .ok (recipients, moduleIds, fees, totalFee) =>
      if totalFee ≤ FEE_PRECISION_POINTS then
        .ok ⟨recipients, moduleIds, fees, totalFee, FEE_PRECISION_POINTS⟩
      else .error .totalFeeAboveCap

theorem rewardedRows_shape (L : Layout) (core : Core) (totalWei : Nat) (ids : List Nat) :
    ∀ (totalFee : Nat) (rs is fs : List Nat) (t : Nat),
      rewardedRows L core totalWei ids totalFee = .ok (rs, is, fs, t) →
      rs.length = is.length ∧ is.length = fs.length ∧ fs.sum + totalFee ≤ t ∧
      (∀ id ∈ is, id ∈ ids ∧ moduleAllocationWei L core id ≠ 0) := by
  induction ids with
  | nil =>
    intro totalFee rs is fs t h
    simp only [rewardedRows, Except.ok.injEq, Prod.mk.injEq] at h
    obtain ⟨rfl, rfl, rfl, rfl⟩ := h
    simp
  | cons id ids ih =>
    intro totalFee rs is fs t h
    simp only [rewardedRows] at h
    split at h
    · obtain ⟨h1, h2, h3, h4⟩ := ih totalFee rs is fs t h
      exact ⟨h1, h2, h3, fun j hj => ⟨by simp [(h4 j hj).1], (h4 j hj).2⟩⟩
    · rename_i halloc
      split at h
      · cases h
      · split at h
        · cases h
        · split at h
          · cases h
          · rename_i hrec
            simp only [Except.ok.injEq, Prod.mk.injEq] at h
            obtain ⟨rfl, rfl, rfl, rfl⟩ := h
            obtain ⟨h1, h2, h3, h4⟩ := ih _ _ _ _ _ hrec
            refine ⟨by simp [h1], by simp [h2], ?_, ?_⟩
            · simp only [List.sum_cons]
              split <;> omega
            · intro j hj
              simp only [List.mem_cons] at hj
              rcases hj with rfl | hj
              · exact ⟨by simp, halloc⟩
              · exact ⟨by simp [(h4 j hj).1], (h4 j hj).2⟩

/-- 820, 828-829: a zero router total is the empty success. -/
theorem getter_empty_success (L : Layout) (reg : List Nat) (core : Core)
    (h : routerTotalWei L core = 0) :
    getStakingRewardsDistribution L reg core = .ok ⟨[], [], [], 0, FEE_PRECISION_POINTS⟩ := by
  simp [getStakingRewardsDistribution, stakingModulesCount, h]

/-- Every successful distribution has equal-length arrays (the Accounting
279-280 asserts), a module-fee sum inside the total, the total inside the
precision cap (862), and only registered nonzero-allocation ids (835, 839). -/
theorem getter_ok_spec (L : Layout) (reg : List Nat) (core : Core) (d : Distribution)
    (h : getStakingRewardsDistribution L reg core = .ok d) :
    d.recipients.length = d.stakingModuleIds.length ∧
    d.stakingModuleIds.length = d.stakingModuleFees.length ∧
    d.stakingModuleFees.sum ≤ d.totalFee ∧
    d.totalFee ≤ d.precisionPoints ∧
    d.precisionPoints = FEE_PRECISION_POINTS ∧
    (∀ id ∈ d.stakingModuleIds, id ∈ reg ∧ moduleAllocationWei L core id ≠ 0) := by
  unfold getStakingRewardsDistribution at h
  split at h
  · cases h
    simp
  · split at h
    · cases h
    · rename_i hrec
      split at h
      · cases h
        obtain ⟨h1, h2, h3, h4⟩ := rewardedRows_shape L core _ reg 0 _ _ _ _ hrec
        exact ⟨h1, h2, by simpa using h3, by assumption, rfl, h4⟩
      · cases h

/-! ## Report words consumed by the getter -/

/-- The getter's total (819) after a committed report is the reported sum in wei. -/
theorem report_then_routerTotalWei (L : Layout) (reg rep bal : List Nat) (core post : Core)
    (hsep : L.Separated reg)
    (h : reportValidatorBalances L reg rep bal core = .committed post) :
    routerTotalWei L post = fromGwei bal.sum := by
  unfold routerTotalWei
  rw [(report_committed_router L reg rep bal core post hsep h).1]

/-- The getter's per-module allocation (836) after a committed report is that
module's reported balance in wei. -/
theorem report_then_moduleAllocationWei (L : Layout) (reg rep bal : List Nat) (core post : Core)
    (hsep : L.Separated reg) (hnodup : reg.Nodup)
    (h : reportValidatorBalances L reg rep bal core = .committed post) :
    ∀ id amount, (id, amount) ∈ reg.zip bal →
      moduleAllocationWei L post id = fromGwei amount := by
  intro id amount hmem
  unfold moduleAllocationWei
  rw [(report_committed_module L reg rep bal core post hsep hnodup h id amount hmem).1]

/-! ## Accounting consumer (Accounting 265-301, 306-333, 335-358) -/

structure ReportWei where
  clValidatorsBalance : Nat
  clPendingBalance : Nat
  withdrawalsVaultTransfer : Nat
  principalClBalance : Nat
  elRewardsVaultTransfer : Nat
  postInternalEther : Nat
  internalSharesBeforeFees : Nat
  deriving Repr, DecidableEq

inductive FeeError where
  | getter (e : GetterError)
  /-- 331: checked `postInternalEther - feeEther`, Panic(0x11). -/
  | feeExceedsPostEther (feeEther postInternalEther : Nat)
  /-- 331: division by zero, Panic(0x12). -/
  | zeroDenominator
  deriving Repr, DecidableEq

/-- Accounting 306-333 with the LIP-12 non-profitable guard (322). uint256
overflow of the two products is not modeled. -/
def totalProtocolFeeShares (r : ReportWei) (totalFee precisionPoints : Nat) : Except FeeError Nat :=
  let unifiedClBalance := r.clValidatorsBalance + r.clPendingBalance + r.withdrawalsVaultTransfer
  if r.principalClBalance < unifiedClBalance then
    let totalRewards := unifiedClBalance - r.principalClBalance + r.elRewardsVaultTransfer
    let feeEther := totalRewards * totalFee / precisionPoints
    if r.postInternalEther < feeEther then .error (.feeExceedsPostEther feeEther r.postInternalEther)
    else if r.postInternalEther = feeEther then .error .zeroDenominator
    else .ok (feeEther * r.internalSharesBeforeFees / (r.postInternalEther - feeEther))
  else .ok 0

theorem shares_zero_of_totalFee_zero (r : ReportWei) (p n : Nat)
    (h : totalProtocolFeeShares r 0 p = .ok n) : n = 0 := by
  simp only [totalProtocolFeeShares] at h
  split at h
  · split at h
    · cases h
    · split at h
      · cases h
      · simp at h
        omega
  · exact (Except.ok.inj h).symm

/-- The 340 `assert(_totalFee > 0)` holds on every path that reaches it. -/
theorem totalFee_pos_of_shares_pos (r : ReportWei) (tf p n : Nat)
    (h : totalProtocolFeeShares r tf p = .ok n) (hn : 0 < n) : 0 < tf := by
  rcases Nat.eq_zero_or_pos tf with rfl | htf
  · have := shares_zero_of_totalFee_zero r p n h
    omega
  · exact htf

/-- Accounting 345-354: per-module floor shares, zero for zero fees. -/
def moduleShares (fees : List Nat) (totalFee shares : Nat) : List Nat :=
  fees.map fun f => if 0 < f then shares * f / totalFee else 0

theorem add_div_le_add_div (a b c : Nat) : a / c + b / c ≤ (a + b) / c := by
  rcases Nat.eq_zero_or_pos c with rfl | hc
  · simp
  · rw [Nat.le_div_iff_mul_le hc, Nat.add_mul]
    exact Nat.add_le_add (Nat.div_mul_le_self a c) (Nat.div_mul_le_self b c)

theorem moduleShares_sum_le_div (fees : List Nat) (totalFee shares : Nat) :
    (moduleShares fees totalFee shares).sum ≤ shares * fees.sum / totalFee := by
  induction fees with
  | nil => simp [moduleShares]
  | cons f fs ih =>
    simp only [moduleShares, List.map_cons, List.sum_cons] at ih ⊢
    have h1 : (if 0 < f then shares * f / totalFee else 0) ≤ shares * f / totalFee := by
      split <;> simp
    have h2 := add_div_le_add_div (shares * f) (shares * fs.sum) totalFee
    rw [← Nat.mul_add] at h2
    omega

/-- 351 never overflows and 356 never underflows: the module shares stay inside
the minted total whenever the module fees stay inside the total fee. -/
theorem moduleShares_sum_le (fees : List Nat) (totalFee shares : Nat) (hT : 0 < totalFee)
    (hle : fees.sum ≤ totalFee) : (moduleShares fees totalFee shares).sum ≤ shares := by
  have h1 := moduleShares_sum_le_div fees totalFee shares
  have h2 : shares * fees.sum / totalFee ≤ shares * totalFee / totalFee :=
    Nat.div_le_div_right (Nat.mul_le_mul_left shares hle)
  rw [Nat.mul_div_cancel _ hT] at h2
  omega

structure FeeResult where
  sharesToMintAsFees : Nat
  moduleFeeRecipients : List Nat
  moduleIds : List Nat
  moduleSharesToMint : List Nat
  treasurySharesToMint : Nat
  deriving Repr, DecidableEq

/-- Accounting 290-301: on a positive mint the 335-358 distribution, otherwise
the default (empty) `FeeDistribution`. -/
def feeResultOf (d : Distribution) (shares : Nat) : FeeResult :=
  if 0 < shares then
    ⟨shares, d.recipients, d.stakingModuleIds, moduleShares d.stakingModuleFees d.totalFee shares,
      shares - (moduleShares d.stakingModuleFees d.totalFee shares).sum⟩
  else ⟨0, [], [], [], 0⟩

/-- Accounting 265-301: the getter result, the minted fee shares, then the
distribution. The 279-280 length asserts and the 340 positivity assert are
theorems (`getter_ok_spec`, `totalFee_pos_of_shares_pos`), so no assertion
branch is modeled. -/
def feeProductsFromCommittedGetter (r : ReportWei) (d : Distribution) :
    Except FeeError FeeResult :=
  totalProtocolFeeShares r d.totalFee d.precisionPoints >>= fun shares =>
  pure (feeResultOf d shares)

/-- Accounting 265-301: the getter result, the minted fee shares, then the
distribution.  Keeping the post-getter continuation named lets the composed
transaction consume the exact `Distribution` it just read, instead of
performing a second getter call or accepting a caller-provided fee record. -/
def calculateProtocolFees (L : Layout) (registeredIds : List Nat) (core : Core) (r : ReportWei) :
    Except FeeError FeeResult :=
  (getStakingRewardsDistribution L registeredIds core).mapError FeeError.getter >>= fun d =>
  feeProductsFromCommittedGetter r d

theorem except_bind_eq_ok {ε α β : Type} (x : Except ε α) (f : α → Except ε β) (b : β) :
    (x >>= f) = .ok b ↔ ∃ a, x = .ok a ∧ f a = .ok b := by
  cases x <;> simp [Bind.bind, Except.bind]

theorem except_mapError_eq_ok {ε ε' α : Type} (x : Except ε α) (g : ε → ε') (a : α) :
    x.mapError g = .ok a ↔ x = .ok a := by
  cases x <;> simp [Except.mapError]

theorem feeResultOf_ok (d : Distribution) (shares : Nat)
    (h1 : d.recipients.length = d.stakingModuleIds.length)
    (h2 : d.stakingModuleIds.length = d.stakingModuleFees.length)
    (h3 : d.stakingModuleFees.sum ≤ d.totalFee)
    (htf : 0 < shares → 0 < d.totalFee) :
    (feeResultOf d shares).moduleFeeRecipients.length = (feeResultOf d shares).moduleIds.length ∧
    (feeResultOf d shares).moduleIds.length = (feeResultOf d shares).moduleSharesToMint.length ∧
    (feeResultOf d shares).moduleSharesToMint.sum + (feeResultOf d shares).treasurySharesToMint =
      (feeResultOf d shares).sharesToMintAsFees := by
  unfold feeResultOf
  split
  · rename_i hpos
    have hsum := moduleShares_sum_le d.stakingModuleFees d.totalFee shares (htf hpos) h3
    refine ⟨h1, ?_, ?_⟩
    · simp [moduleShares, h2]
    · dsimp only
      omega
  · simp

/-- A successful fee calculation is a successful getter, a successful mint
computation on its total fee, and the distribution of that pair. -/
theorem calculateProtocolFees_spec (L : Layout) (reg : List Nat) (core : Core) (r : ReportWei)
    (res : FeeResult) (h : calculateProtocolFees L reg core r = .ok res) :
    ∃ d shares, getStakingRewardsDistribution L reg core = .ok d ∧
      totalProtocolFeeShares r d.totalFee d.precisionPoints = .ok shares ∧
      res = feeResultOf d shares := by
  unfold calculateProtocolFees at h
  rw [except_bind_eq_ok] at h
  obtain ⟨d, hd, h⟩ := h
  rw [except_mapError_eq_ok] at hd
  unfold feeProductsFromCommittedGetter at h
  rw [except_bind_eq_ok] at h
  obtain ⟨shares, hs, h⟩ := h
  exact ⟨d, shares, hd, hs, (Except.ok.inj h).symm⟩

/-- Every successful fee calculation returns aligned recipient/id/share arrays
and conserves the minted total between modules and treasury. -/
theorem calculateProtocolFees_ok (L : Layout) (reg : List Nat) (core : Core) (r : ReportWei)
    (res : FeeResult) (h : calculateProtocolFees L reg core r = .ok res) :
    res.moduleFeeRecipients.length = res.moduleIds.length ∧
    res.moduleIds.length = res.moduleSharesToMint.length ∧
    res.moduleSharesToMint.sum + res.treasurySharesToMint = res.sharesToMintAsFees := by
  obtain ⟨d, shares, hd, hs, hres⟩ := calculateProtocolFees_spec L reg core r res h
  subst hres
  obtain ⟨h1, h2, h3, _, _, _⟩ := getter_ok_spec L reg core d hd
  exact feeResultOf_ok d shares h1 h2 h3
    (fun hp => totalFee_pos_of_shares_pos r d.totalFee d.precisionPoints shares hs hp)

end AccountAddress.ReportWriteFee
