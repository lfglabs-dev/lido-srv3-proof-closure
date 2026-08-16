import LidoSRv3.Audit.MinFirstAllocation

/-!
# Proportional allocation amount correspondence

`MinFirstAllocationStrategy.allocateToBestCandidate` at
`lidofinance/core@af095e48bbc1c3841c2c9936219c8461af01056b`, lines 88--106:
the best-candidate count, the next-level upper bound, and

```solidity
allocated = Math256.min(
    bestCandidatesCount > 1 ? Math256.ceilDiv(allocationSize, bestCandidatesCount) : allocationSize,
    Math256.min(allocationSizeUpperBound, capacities[bestCandidateIndex]) - bestCandidateAllocation
);
```

The pinned source subtracts once, after the inner `min`; `Source.checkedAmount`
distributes the subtraction over the `min`.  That difference is discharged
rather than assumed.
-/

namespace LidoSRv3.Audit.MinFirstAllocation

open Verity.Core Verity.Stdlib.Math

/-! ## Word-level bridging -/

theorem val_sub_of_le {a b : Uint256} (h : b ≤ a) : (a - b).val = a.val - b.val := by
  have hle : b.val ≤ a.val := h
  have hlt : a.val - b.val < Uint256.modulus :=
    Nat.lt_of_le_of_lt (Nat.sub_le _ _) a.isLt
  show (Uint256.sub a b).val = a.val - b.val
  simp [Uint256.sub, hle, Uint256.ofNat, Nat.mod_eq_of_lt hlt]

theorem val_minWord (a b : Source.Word) :
    (Source.minWord a b).val = min a.val b.val := by
  unfold Source.minWord
  by_cases h : a ≤ b
  · have hv : a.val ≤ b.val := h
    simp [h, Nat.min_eq_left hv]
  · have hv : b.val ≤ a.val := Nat.le_of_lt (Nat.lt_of_not_le h)
    simp [h, Nat.min_eq_right hv]

/-- `min` distributes over a subtraction that is defined on both branches.
This is the shape difference between the pinned source and `checkedAmount`. -/
theorem min_sub_distrib {x y c : Nat} (hx : c ≤ x) (hy : c ≤ y) :
    min x y - c = min (x - c) (y - c) := by
  omega

theorem val_of_safeSub {a b w : Uint256} (h : safeSub a b = some w) :
    w.val = a.val - b.val := by
  unfold safeSub at h
  by_cases hlt : b.val > a.val
  · simp [hlt] at h
  · simp only [hlt, if_false, Option.some.injEq] at h
    subst h
    exact val_sub_of_le (Nat.le_of_not_lt hlt)

theorem safeSub_isSome_of_le {a b : Uint256} (h : b.val ≤ a.val) :
    safeSub a b = some (a - b) := by
  unfold safeSub
  simp [Nat.not_lt.mpr h]

theorem val_div {a b : Uint256} (hb : b.val ≠ 0) : (a / b).val = a.val / b.val := by
  have hlt : a.val / b.val < Uint256.modulus :=
    Nat.lt_of_le_of_lt (Nat.div_le_self _ _) a.isLt
  show (Uint256.div a b).val = a.val / b.val
  rw [Uint256.div, if_neg hb]
  simp [Uint256.ofNat, Nat.mod_eq_of_lt hlt]

theorem val_add_of_lt {a b : Uint256} (h : a.val + b.val < Uint256.modulus) :
    (a + b).val = a.val + b.val := by
  show (Uint256.add a b).val = a.val + b.val
  simp [Uint256.add, Uint256.ofNat, Nat.mod_eq_of_lt h]

theorem val_ofNat_of_lt {d : Nat} (h : d < Uint256.modulus) :
    (Uint256.ofNat d).val = d := by
  simp [Uint256.ofNat, Nat.mod_eq_of_lt h]

/-- The pinned-source `ceilDiv` word agrees with the model's `Nat` `ceilDiv`
whenever the divisor is a non-zero in-range count. -/
theorem val_ceilDiv {a : Uint256} {d : Nat} (hd : 0 < d) (hdlt : d < Uint256.modulus) :
    (Verity.Stdlib.Math.ceilDiv a (Uint256.ofNat d)).val = Model.ceilDiv a.val d := by
  have hdval : (Uint256.ofNat d).val = d := val_ofNat_of_lt hdlt
  by_cases ha : a = 0
  · subst ha
    simp [Verity.Stdlib.Math.ceilDiv, Model.ceilDiv]
  · have haval : a.val ≠ 0 := fun h => ha (Uint256.ext (by simpa using h))
    have hone : (1 : Uint256).val ≤ a.val := by
      simpa using Nat.one_le_iff_ne_zero.mpr haval
    have hsub : (a - 1).val = a.val - 1 := by
      have h := val_sub_of_le (a := a) (b := 1) hone
      simpa using h
    have hdz : (Uint256.ofNat d).val ≠ 0 := by rw [hdval]; omega
    have hdiv : ((a - 1) / Uint256.ofNat d).val = (a.val - 1) / d := by
      rw [val_div hdz, hsub, hdval]
    have hbound : ((a - 1) / Uint256.ofNat d).val + (1 : Uint256).val
        < Uint256.modulus := by
      have h1 : (a.val - 1) / d ≤ a.val - 1 := Nat.div_le_self _ _
      have h2 : 0 < a.val := Nat.pos_of_ne_zero haval
      have h3 : a.val < Uint256.modulus := a.isLt
      have h4 : (1 : Uint256).val = 1 := by simp
      rw [hdiv, h4]
      omega
    have hne : ¬ (a == 0) = true := by simp [ha]
    rw [Verity.Stdlib.Math.ceilDiv_def, if_neg hne, val_add_of_lt hbound, hdiv,
      Model.ceilDiv, if_neg haval]
    simp

/-! ## Best-candidate count (source lines 76--86, `bestCandidatesCount`) -/

theorem leastCount_correspondence {model : List Model.Bucket} {source : List Source.Row}
    (hRows : RowsCorrespond model source) (w : Source.Word) :
    Model.leastCount model w.val = Source.countBest source w := by
  unfold Model.leastCount Source.countBest
  induction hRows with
  | nil => rfl
  | @cons m s ms ss hms _ ih =>
      obtain ⟨ha, hc⟩ := hms
      have hopen : Model.isOpen m = Source.hasFreeSpace s := by
        simp [Model.isOpen, Source.hasFreeSpace, ha, hc]
      have heq : decide (m.allocation = w.val) = decide (s.allocation = w) := by
        by_cases h : s.allocation = w
        · simp [h, ha]
        · have hne : m.allocation ≠ w.val := by
            rw [ha]; exact fun hv => h (Uint256.ext hv)
          simp [h, hne]
      simp only [List.filter_cons, hopen, heq]
      cases Source.hasFreeSpace s && decide (s.allocation = w) <;> simp [ih]

/-! ## Next-level upper bound (source lines 93--100, `allocationSizeUpperBound`) -/

theorem nextLevel_filterMap_correspondence {model : List Model.Bucket}
    {source : List Source.Row} (hRows : RowsCorrespond model source) (w : Source.Word) :
    (model.filterMap fun b =>
        if Model.isOpen b && decide (w.val < b.allocation) then some b.allocation else none) =
      (source.filterMap fun r =>
        if Source.hasFreeSpace r && decide (w < r.allocation) then some r.allocation
        else none).map Uint256.val := by
  induction hRows with
  | nil => rfl
  | @cons m s ms ss hms _ ih =>
      obtain ⟨ha, hc⟩ := hms
      have hopen : Model.isOpen m = Source.hasFreeSpace s := by
        simp [Model.isOpen, Source.hasFreeSpace, ha, hc]
      have hlt : decide (w.val < m.allocation) = decide (w < s.allocation) := by
        simp [ha]
      simp only [List.filterMap_cons, hopen, hlt]
      cases hcond : Source.hasFreeSpace s && decide (w < s.allocation)
      · simpa [hcond] using ih
      · simpa [hcond, ha] using congrArg (fun l => s.allocation.val :: l) ih

theorem foldl_minWord_some (l : List Source.Word) (m : Source.Word) :
    l.foldl (fun found value => some ((found.map (Source.minWord value)).getD value))
        (some m) =
      some (l.foldl (fun acc value => Source.minWord value acc) m) := by
  induction l generalizing m with
  | nil => rfl
  | cons v vs ih => simp [ih]

theorem val_foldl_minWord (l : List Source.Word) (m : Source.Word) :
    (l.foldl (fun acc value => Source.minWord value acc) m).val =
      (l.map Uint256.val).foldl min m.val := by
  induction l generalizing m with
  | nil => rfl
  | cons v vs ih =>
      simp only [List.foldl_cons, List.map_cons, ih, val_minWord]
      rw [Nat.min_comm]

theorem foldl_minWord_eq_min? (l : List Source.Word) :
    Option.map Uint256.val
        (l.foldl (fun found value => some ((found.map (Source.minWord value)).getD value))
          none) =
      (l.map Uint256.val).min? := by
  cases l with
  | nil => rfl
  | cons v vs =>
      have hmin : ((v :: vs).map Uint256.val).min? =
          some ((vs.map Uint256.val).foldl min v.val) := rfl
      rw [hmin]
      simp only [List.foldl_cons, Option.map_none, Option.getD_none, foldl_minWord_some,
        Option.map_some]
      exact congrArg some (val_foldl_minWord vs v)

theorem nextLevel_correspondence {model : List Model.Bucket} {source : List Source.Row}
    (hRows : RowsCorrespond model source) (w : Source.Word) :
    Option.map Uint256.val (Source.nextLevel? source w) = Model.nextLevel? model w.val := by
  unfold Source.nextLevel? Model.nextLevel?
  rw [foldl_minWord_eq_min?, ← nextLevel_filterMap_correspondence hRows w]

theorem foldl_minWord_gt (l : List Source.Word) (w : Source.Word) :
    ∀ m : Source.Word, (∀ x ∈ l, w.val < x.val) → w.val < m.val →
      w.val < (l.foldl (fun acc value => Source.minWord value acc) m).val := by
  induction l with
  | nil => intro m _ hm; exact hm
  | cons v vs ih =>
      intro m hl hm
      refine ih _ (fun x hx => hl x (by simp [hx])) ?_
      have hv : w.val < v.val := hl v (by simp)
      rw [val_minWord]
      exact Nat.lt_min.mpr ⟨hv, hm⟩

/-- Every next-level upper bound really is above the selected allocation.  This
is what makes the pinned source's single subtraction total. -/
theorem nextLevel_gt {rs : List Source.Row} {w next : Source.Word}
    (h : Source.nextLevel? rs w = some next) : w.val < next.val := by
  unfold Source.nextLevel? at h
  set l := rs.filterMap fun r =>
    if Source.hasFreeSpace r && decide (w < r.allocation) then some r.allocation else none
    with hl
  have hall : ∀ x ∈ l, w.val < x.val := by
    intro x hx
    rw [hl] at hx
    obtain ⟨r, _, hrz⟩ := List.mem_filterMap.mp hx
    by_cases hcond : (Source.hasFreeSpace r && decide (w < r.allocation)) = true
    · rw [if_pos hcond] at hrz
      have hlt : w < r.allocation :=
        of_decide_eq_true ((Bool.and_eq_true _ _).mp hcond).2
      rw [← Option.some.inj hrz]
      exact hlt
    · rw [if_neg hcond] at hrz
      exact absurd hrz (by simp)
  cases hcase : l with
  | nil => rw [hcase] at h; simp at h
  | cons v vs =>
      rw [hcase] at h
      simp only [List.foldl_cons, Option.map_none, Option.getD_none, foldl_minWord_some,
        Option.some.injEq] at h
      subst h
      exact foldl_minWord_gt vs w v
        (fun x hx => hall x (by rw [hcase]; simp [hx])) (hall v (by rw [hcase]; simp))

/-! ## Proportional amount (source lines 102--105) -/

theorem countBest_le_length (rs : List Source.Row) (w : Source.Word) :
    Source.countBest rs w ≤ rs.length :=
  List.length_filter_le _ _

/-- Source line 103: `bestCandidatesCount > 1 ? ceilDiv(allocationSize, count) :
allocationSize`. -/
def sourceShare (rs : List Source.Row) (allocationSize : Source.Word)
    (best : Source.Row) : Source.Word :=
  if 1 < Source.countBest rs best.allocation then
    Verity.Stdlib.Math.ceilDiv allocationSize
      (Uint256.ofNat (Source.countBest rs best.allocation))
  else allocationSize

/-- The same demand share in the unbounded model. -/
def modelShare (rows : List Model.Bucket) (requested : Nat) (best : Model.Bucket) : Nat :=
  if 1 < Model.leastCount rows best.allocation then
    Model.ceilDiv requested (Model.leastCount rows best.allocation)
  else requested

theorem model_amount_eq (rows : List Model.Bucket) (requested : Nat) (best : Model.Bucket) :
    Model.amount rows requested best =
      min (modelShare rows requested best)
        (min (((Model.nextLevel? rows best.allocation).map
                (fun next => next - best.allocation)).getD (modelShare rows requested best))
          (best.capacity - best.allocation)) := rfl

theorem source_checkedAmount_none {rs : List Source.Row} {allocationSize : Source.Word}
    {best : Source.Row} (h : Source.nextLevel? rs best.allocation = none) :
    Source.checkedAmount rs allocationSize best =
      (safeSub best.capacity best.allocation).bind (fun capacityHeadroom =>
        some (Source.minWord (sourceShare rs allocationSize best)
          (Source.minWord (sourceShare rs allocationSize best) capacityHeadroom))) := by
  unfold Source.checkedAmount sourceShare
  rw [h]
  rfl

theorem source_checkedAmount_some {rs : List Source.Row} {allocationSize : Source.Word}
    {best : Source.Row} {next : Source.Word}
    (h : Source.nextLevel? rs best.allocation = some next) :
    Source.checkedAmount rs allocationSize best =
      (safeSub next best.allocation).bind (fun levelHeadroom =>
        (safeSub best.capacity best.allocation).bind fun capacityHeadroom =>
          some (Source.minWord (sourceShare rs allocationSize best)
            (Source.minWord levelHeadroom capacityHeadroom))) := by
  unfold Source.checkedAmount sourceShare
  rw [h]
  rfl

/--
Under row correspondence the unbounded `Nat` model amount is exactly the value
of the checked pinned-source word, whenever the source arithmetic succeeds.
The array-length premise is what lets a Solidity `uint256` candidate count be
reflected back into `Nat`; an EVM memory array cannot reach `2^256` entries.
-/
theorem amount_correspondence {model : List Model.Bucket} {source : List Source.Row}
    {mbest : Model.Bucket} {sbest : Source.Row} {allocationSize w : Source.Word}
    (hRows : RowsCorrespond model source)
    (hLen : source.length < Uint256.modulus)
    (hAlloc : mbest.allocation = sbest.allocation.val)
    (hCap : mbest.capacity = sbest.capacity.val)
    (hAmount : Source.checkedAmount source allocationSize sbest = some w) :
    Model.amount model allocationSize.val mbest = w.val := by
  have hCount : Model.leastCount model sbest.allocation.val =
      Source.countBest source sbest.allocation :=
    leastCount_correspondence hRows sbest.allocation
  have hCountLt : Source.countBest source sbest.allocation < Uint256.modulus :=
    Nat.lt_of_le_of_lt (countBest_le_length _ _) hLen
  have hShare : (sourceShare source allocationSize sbest).val =
      modelShare model allocationSize.val mbest := by
    unfold sourceShare modelShare
    rw [hAlloc, hCount]
    by_cases hc : 1 < Source.countBest source sbest.allocation
    · rw [if_pos hc, if_pos hc]
      exact val_ceilDiv (Nat.lt_of_lt_of_le Nat.zero_lt_one (Nat.le_of_lt hc)) hCountLt
    · rw [if_neg hc, if_neg hc]
  have hLevel := nextLevel_correspondence hRows sbest.allocation
  rw [model_amount_eq, hAlloc, hCap]
  cases hnext : Source.nextLevel? source sbest.allocation with
  | none =>
      have hmodel : Model.nextLevel? model sbest.allocation.val = none := by
        rw [← hLevel, hnext]; rfl
      rw [source_checkedAmount_none hnext] at hAmount
      rw [hmodel]
      simp only [Option.map_none, Option.getD_none]
      cases hcap : safeSub sbest.capacity sbest.allocation with
      | none => rw [hcap] at hAmount; simp at hAmount
      | some ch =>
          rw [hcap] at hAmount
          simp only [Option.bind_some, Option.some.injEq] at hAmount
          subst hAmount
          rw [val_minWord, val_minWord, val_of_safeSub hcap, hShare]
  | some next =>
      have hmodel : Model.nextLevel? model sbest.allocation.val = some next.val := by
        rw [← hLevel, hnext]; rfl
      rw [source_checkedAmount_some hnext] at hAmount
      rw [hmodel]
      simp only [Option.map_some, Option.getD_some]
      cases hlvl : safeSub next sbest.allocation with
      | none => rw [hlvl] at hAmount; simp at hAmount
      | some lh =>
          rw [hlvl] at hAmount
          simp only [Option.bind_some] at hAmount
          cases hcap : safeSub sbest.capacity sbest.allocation with
          | none => rw [hcap] at hAmount; simp at hAmount
          | some ch =>
              rw [hcap] at hAmount
              simp only [Option.bind_some, Option.some.injEq] at hAmount
              subst hAmount
              rw [val_minWord, val_minWord, val_of_safeSub hlvl, val_of_safeSub hcap,
                hShare]

/-! ## Literal pinned-source expression shape (source lines 93--105)

`Source.checkedAmount` distributes the subtraction over the inner `min`, while
the pinned source performs a single subtraction after it.  The two are proved
equal here for an open best candidate; nothing about the shape is assumed.
-/

theorem val_maxUint : (Uint256.ofNat Verity.Core.MAX_UINT256).val = Verity.Core.MAX_UINT256 :=
  val_ofNat_of_lt (by
    have h := Uint256.max_uint256_succ_eq_modulus
    omega)

theorem minWord_max (a : Source.Word) :
    Source.minWord (Uint256.ofNat Verity.Core.MAX_UINT256) a = a := by
  unfold Source.minWord
  by_cases h : (Uint256.ofNat Verity.Core.MAX_UINT256) ≤ a
  · have hge : Verity.Core.MAX_UINT256 ≤ a.val := by
      have : (Uint256.ofNat Verity.Core.MAX_UINT256).val ≤ a.val := h
      rwa [val_maxUint] at this
    have hle := Uint256.val_le_max a
    exact (if_pos h).trans (Uint256.ext (by rw [val_maxUint]; omega))
  · exact if_neg h

theorem minWord_idem_left (a b : Source.Word) :
    Source.minWord a (Source.minWord a b) = Source.minWord a b := by
  unfold Source.minWord
  by_cases h : a ≤ b <;> simp [h]

/-- `allocationSizeUpperBound`, initialised to `MAX_UINT256` at source line 93
and lowered only by open buckets strictly above the best candidate. -/
def upperBound (rs : List Source.Row) (best : Source.Row) : Source.Word :=
  (Source.nextLevel? rs best.allocation).getD (Uint256.ofNat Verity.Core.MAX_UINT256)

/-- The pinned source expression at lines 102--105: one inner `min`, one
subtraction, one outer `min`. -/
def pinnedAmount (rs : List Source.Row) (allocationSize : Source.Word)
    (best : Source.Row) : Option Source.Word :=
  (safeSub (Source.minWord (upperBound rs best) best.capacity) best.allocation).map
    (Source.minWord (sourceShare rs allocationSize best))

/-- The pinned source shape and `Source.checkedAmount` agree for every open best
candidate, so the distributed-subtraction presentation is sound. -/
theorem pinnedAmount_eq_checkedAmount {rs : List Source.Row}
    {allocationSize : Source.Word} {best : Source.Row}
    (hOpen : Source.hasFreeSpace best = true) :
    pinnedAmount rs allocationSize best = Source.checkedAmount rs allocationSize best := by
  have hlt : best.allocation.val < best.capacity.val := of_decide_eq_true hOpen
  unfold pinnedAmount upperBound
  cases hnext : Source.nextLevel? rs best.allocation with
  | none =>
      rw [source_checkedAmount_none hnext]
      simp only [Option.getD_none]
      rw [minWord_max, safeSub_isSome_of_le (Nat.le_of_lt hlt)]
      simp only [Option.map_some, Option.bind_some]
      exact congrArg some (minWord_idem_left _ _).symm
  | some next =>
      have hgt : best.allocation.val < next.val := nextLevel_gt hnext
      have hminle : best.allocation.val ≤ (Source.minWord next best.capacity).val := by
        rw [val_minWord]; omega
      rw [source_checkedAmount_some hnext]
      simp only [Option.getD_some]
      rw [safeSub_isSome_of_le hminle, safeSub_isSome_of_le (Nat.le_of_lt hgt),
        safeSub_isSome_of_le (Nat.le_of_lt hlt)]
      simp only [Option.map_some, Option.bind_some]
      refine congrArg some (congrArg _ ?_)
      apply Uint256.ext
      rw [val_sub_of_le hminle, val_minWord, val_minWord,
        val_sub_of_le (Nat.le_of_lt hgt), val_sub_of_le (Nat.le_of_lt hlt)]
      omega

/-! ## Totality, positivity and headroom bounds

These discharge the premises that `Source.Execute.mutate` currently carries as
hypotheses: that the checked arithmetic of lines 102--106 cannot revert for an
open best candidate, that it makes strict progress, and that it never exceeds
either the remaining demand or the bucket capacity.
-/

theorem allocation_le_upperBound (rs : List Source.Row) (best : Source.Row) :
    best.allocation.val ≤ (upperBound rs best).val := by
  unfold upperBound
  cases hnext : Source.nextLevel? rs best.allocation with
  | none =>
      rw [Option.getD_none, val_maxUint]
      exact Uint256.val_le_max _
  | some next =>
      rw [Option.getD_some]
      exact Nat.le_of_lt (nextLevel_gt hnext)

theorem allocation_lt_upperBound {rs : List Source.Row} {best : Source.Row}
    (hOpen : Source.hasFreeSpace best = true) :
    best.allocation.val < (upperBound rs best).val := by
  have hlt : best.allocation.val < best.capacity.val := of_decide_eq_true hOpen
  unfold upperBound
  cases hnext : Source.nextLevel? rs best.allocation with
  | none =>
      rw [Option.getD_none, val_maxUint]
      have := Uint256.val_le_max best.capacity
      omega
  | some next =>
      rw [Option.getD_some]
      exact nextLevel_gt hnext

theorem allocation_le_minUpper {rs : List Source.Row} {best : Source.Row}
    (hOpen : Source.hasFreeSpace best = true) :
    best.allocation.val ≤ (Source.minWord (upperBound rs best) best.capacity).val := by
  have hlt : best.allocation.val < best.capacity.val := of_decide_eq_true hOpen
  have hup := allocation_lt_upperBound (rs := rs) hOpen
  rw [val_minWord]
  omega

/-- The pinned checked arithmetic never reverts for an open best candidate. -/
theorem checkedAmount_isSome (rs : List Source.Row) (allocationSize : Source.Word)
    {best : Source.Row} (hOpen : Source.hasFreeSpace best = true) :
    Source.checkedAmount rs allocationSize best =
      some (Source.minWord (sourceShare rs allocationSize best)
        (Source.minWord (upperBound rs best) best.capacity - best.allocation)) := by
  rw [← pinnedAmount_eq_checkedAmount hOpen]
  unfold pinnedAmount
  rw [safeSub_isSome_of_le (allocation_le_minUpper hOpen)]
  rfl

/-- Closed form of the allocated word. -/
theorem checkedAmount_val {rs : List Source.Row} {allocationSize : Source.Word}
    {best : Source.Row} {w : Source.Word} (hOpen : Source.hasFreeSpace best = true)
    (h : Source.checkedAmount rs allocationSize best = some w) :
    w.val = min (sourceShare rs allocationSize best).val
      (min (upperBound rs best).val best.capacity.val - best.allocation.val) := by
  rw [checkedAmount_isSome rs allocationSize hOpen, Option.some.injEq] at h
  subst h
  rw [val_minWord, val_sub_of_le (allocation_le_minUpper hOpen), val_minWord]

theorem sourceShare_le (rs : List Source.Row) (allocationSize : Source.Word)
    (best : Source.Row) (hLen : rs.length < Uint256.modulus) :
    (sourceShare rs allocationSize best).val ≤ allocationSize.val := by
  unfold sourceShare
  by_cases hc : 1 < Source.countBest rs best.allocation
  · rw [if_pos hc, val_ceilDiv (by omega)
      (Nat.lt_of_le_of_lt (countBest_le_length _ _) hLen)]
    unfold Model.ceilDiv
    by_cases ha : allocationSize.val = 0
    · rw [if_pos ha]; omega
    · rw [if_neg ha]
      have h1 : (allocationSize.val - 1) / Source.countBest rs best.allocation
          ≤ allocationSize.val - 1 := Nat.div_le_self _ _
      have h2 : 1 ≤ allocationSize.val := Nat.one_le_iff_ne_zero.mpr ha
      exact Nat.le_trans (Nat.succ_le_succ h1) (by omega)
  · rw [if_neg hc]
    exact Nat.le_refl _

theorem sourceShare_pos (rs : List Source.Row) {allocationSize : Source.Word}
    (best : Source.Row) (hLen : rs.length < Uint256.modulus)
    (hSize : allocationSize.val ≠ 0) :
    0 < (sourceShare rs allocationSize best).val := by
  unfold sourceShare
  by_cases hc : 1 < Source.countBest rs best.allocation
  · rw [if_pos hc, val_ceilDiv (by omega)
      (Nat.lt_of_le_of_lt (countBest_le_length _ _) hLen)]
    unfold Model.ceilDiv
    rw [if_neg hSize]
    exact Nat.succ_pos _
  · rw [if_neg hc]
    exact Nat.pos_of_ne_zero hSize

/-- Strict progress: a positive remaining demand always allocates at least one
unit to an open best candidate, so the min-first outer loop terminates. -/
theorem checkedAmount_pos {rs : List Source.Row} {allocationSize : Source.Word}
    {best : Source.Row} {w : Source.Word} (hOpen : Source.hasFreeSpace best = true)
    (hLen : rs.length < Uint256.modulus) (hSize : allocationSize.val ≠ 0)
    (h : Source.checkedAmount rs allocationSize best = some w) :
    0 < w.val := by
  have hval := checkedAmount_val hOpen h
  have hshare := sourceShare_pos rs best hLen hSize
  have hlt : best.allocation.val < best.capacity.val := of_decide_eq_true hOpen
  have hup := allocation_lt_upperBound (rs := rs) hOpen
  omega

/-- The allocation never exceeds the remaining demand, so the outer-loop
`allocationSize - allocated` at source line 37 cannot underflow. -/
theorem checkedAmount_le_size {rs : List Source.Row} {allocationSize : Source.Word}
    {best : Source.Row} {w : Source.Word} (hOpen : Source.hasFreeSpace best = true)
    (hLen : rs.length < Uint256.modulus)
    (h : Source.checkedAmount rs allocationSize best = some w) :
    w.val ≤ allocationSize.val := by
  have hval := checkedAmount_val hOpen h
  have hshare := sourceShare_le rs allocationSize best hLen
  omega

/-- The allocation never exceeds the bucket's remaining capacity, so the
`buckets[i] += allocated` at source line 106 both cannot overflow and preserves
the capacity invariant. -/
theorem checkedAmount_le_headroom {rs : List Source.Row} {allocationSize : Source.Word}
    {best : Source.Row} {w : Source.Word} (hOpen : Source.hasFreeSpace best = true)
    (h : Source.checkedAmount rs allocationSize best = some w) :
    best.allocation.val + w.val ≤ best.capacity.val := by
  have hval := checkedAmount_val hOpen h
  have hlt : best.allocation.val < best.capacity.val := of_decide_eq_true hOpen
  omega

theorem checkedAmount_safeAdd {rs : List Source.Row} {allocationSize : Source.Word}
    {best : Source.Row} {w : Source.Word} (hOpen : Source.hasFreeSpace best = true)
    (h : Source.checkedAmount rs allocationSize best = some w) :
    safeAdd best.allocation w = some (best.allocation + w) := by
  have hbound := checkedAmount_le_headroom hOpen h
  have hcap : best.capacity.val < Uint256.modulus := best.capacity.isLt
  have hmax : Verity.Core.MAX_UINT256 + 1 = Uint256.modulus :=
    Uint256.max_uint256_succ_eq_modulus
  have hle : best.allocation.val + w.val ≤ Verity.Stdlib.Math.MAX_UINT256 := by
    show best.allocation.val + w.val ≤ Verity.Core.MAX_UINT256
    omega
  simp [safeAdd, Nat.not_lt.mpr hle]

end LidoSRv3.Audit.MinFirstAllocation
