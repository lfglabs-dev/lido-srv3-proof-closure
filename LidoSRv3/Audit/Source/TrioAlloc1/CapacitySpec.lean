import LidoSRv3.Audit.Source.TrioAlloc1.Properties

/-! Independent unbounded arithmetic view of the successful second pass.
This specification does not call `checked`, `rowCapacity`, or either execution loop.
Success implies these equations; arbitrary external responses may still revert.
-/
namespace LidoSRv3.Audit.Source.TrioAlloc1

namespace CapacitySpec

def available (input : CapacityInput) (row : CachedRow) : Nat :=
  if input.isTopUp && row.stored.wcType.val == 2 then
    row.active.val * input.config.maxEBType2.val / input.config.maxEBType1.val
  else row.allocation.val + row.summary.depositable.val

def target (total : Word) (row : CachedRow) : Nat :=
  row.stored.share.val * total.val / 10000

def capacity (input : CapacityInput) (total : Word) (row : CachedRow) : Nat :=
  if row.stored.status.val = 0 then min (target total row) (available input row)
  else row.allocation.val

end CapacitySpec

theorem checked_success {n : Nat} {w : Word} (h : checked n = .ok w) :
    w.val = n ∧ n < 2^256 := by
  unfold checked at h
  split at h
  · cases h; exact ⟨rfl, ‹n < 2^256›⟩
  · cases h

/-- Checked total accumulation is tied to the returned allocation of each live row. -/
theorem firstRow_total (l : Layout) (s : Storage) (oracle : StaticOracle)
    (input : CapacityInput) (i : Nat) (total : Word) (before after : Transcript)
    (row : CachedRow) (next : Word)
    (h : firstRow l s oracle input i total before = (.ok (row, next), after)) :
    next.val = total.val + row.allocation.val := by
  unfold firstRow at h
  simp only [bind, pure] at h
  split at h
  · simp [failExec] at h
  · repeat first
      | (split at h)
      | (simp only [bindExec, pureExec, liftChecked] at h)
      | (simp at h)
      | (obtain ⟨⟨rfl, rfl⟩, _⟩ := h; exact (checked_success (congrArg Prod.fst ‹(checked _, _) = (Except.ok _, _)›)).1)

theorem checkedDiv_success {a b w : Word} (h : checkedDiv a b = .ok w) :
    w.val = a.val / b.val ∧ b.val ≠ 0 := by
  unfold checkedDiv at h
  split at h
  · cases h
  · cases h
    exact ⟨Nat.mod_eq_of_lt (Nat.lt_of_le_of_lt (Nat.div_le_self _ _) a.isLt), ‹b.val ≠ 0›⟩

/-- Success discharges every checked second-pass arithmetic obligation locally. -/
theorem rowCapacity_matches_spec (input : CapacityInput) (total : Word)
    (row : CachedRow) (cap : Word) (h : rowCapacity input total row = .ok cap) :
    cap.val = CapacitySpec.capacity input total row := by
  unfold rowCapacity at h
  by_cases active : row.stored.status.val = 0
  · simp only [active, ne_eq, not_true_eq_false, ↓reduceIte] at h
    simp only [bind, Except.bind] at h
    unfold CapacitySpec.capacity
    simp only [active, ↓reduceIte]
    by_cases topup : (input.isTopUp && row.stored.wcType.val == 2) = true
    · simp only [topup, ↓reduceIte] at h
      cases hm : checked (row.active.val * input.config.maxEBType2.val) with
      | error e => simp [hm] at h
      | ok product =>
        simp only [hm] at h
        cases hd : checkedDiv product input.config.maxEBType1 with
        | error e => simp [hd] at h
        | ok avail =>
          simp only [hd] at h
          cases ht : checked (row.stored.share.val * total.val) with
          | error e => simp [ht] at h
          | ok targetProduct =>
            simp [ht, pure, Except.pure] at h
            subst cap
            have hm' := (checked_success hm).1
            have hd' := (checkedDiv_success hd).1
            have ht' := (checked_success ht).1
            have bound : min (targetProduct.val / 10000) avail.val < 2^256 :=
              Nat.lt_of_le_of_lt (Nat.min_le_right _ _) avail.isLt
            simp only [word, Nat.mod_eq_of_lt bound]
            simp [CapacitySpec.target, CapacitySpec.available, topup, ← hm', ← hd', ← ht']
    · simp only [Bool.not_eq_true] at topup
      simp only [topup, Bool.false_eq_true, ↓reduceIte] at h
      cases ha : checked (row.allocation.val + row.summary.depositable.val) with
      | error e => simp [ha] at h
      | ok avail =>
        simp only [ha] at h
        cases ht : checked (row.stored.share.val * total.val) with
        | error e => simp [ht] at h
        | ok targetProduct =>
          simp [ht, pure, Except.pure] at h
          subst cap
          have ha' := (checked_success ha).1
          have ht' := (checked_success ht).1
          have bound : min (targetProduct.val / 10000) avail.val < 2^256 :=
            Nat.lt_of_le_of_lt (Nat.min_le_right _ _) avail.isLt
          simp only [word, Nat.mod_eq_of_lt bound]
          simp [CapacitySpec.target, CapacitySpec.available, topup, ← ha', ← ht']
  · simp [active, pure, Except.pure] at h
    subst cap
    simp [CapacitySpec.capacity, active]

/-- The clamp bound follows for the executor's returned word, not just a min definition. -/
theorem successful_active_capacity_bounds (input : CapacityInput) (total : Word)
    (row : CachedRow) (cap : Word) (active : row.stored.status.val = 0)
    (h : rowCapacity input total row = .ok cap) :
    cap.val ≤ CapacitySpec.target total row ∧ cap.val ≤ CapacitySpec.available input row := by
  rw [rowCapacity_matches_spec input total row cap h]
  simp only [CapacitySpec.capacity, active, ↓reduceIte]
  exact ⟨Nat.min_le_left _ _, Nat.min_le_right _ _⟩

/-- The public producer's actual capacity column agrees with the independent
arithmetic view of its own storage/call-derived rows, without a caller row premise. -/
theorem producer_capacity_correspondence (l : Layout) (s : Storage) (oracle : StaticOracle)
    (input : CapacityInput) (before after : Transcript) (output : CapacityOutput)
    (h : produce l s oracle input before = (.ok output, after)) :
    ∃ rows total middle,
      firstLoop l s oracle input (s (countSlot l)).val 0 input.depositsToAllocate before =
        (.ok (rows, total), middle) ∧
      output.capacities.map Fin.val = rows.map (CapacitySpec.capacity input total) ∧
      RouterOrderRelated (routerOrder l s) output := by
  have order := producer_router_order l s oracle input before after output h
  change bindExec (firstLoop l s oracle input (s (countSlot l)).val 0
    input.depositsToAllocate) _ before = _ at h
  obtain ⟨⟨rows, total⟩, middle, hr, h⟩ := bindExec_success _ _ _ _ _ h
  change bindExec (liftChecked (secondLoop input total rows)) _ middle = _ at h
  obtain ⟨buckets, ending, hb, h⟩ := bindExec_success _ _ _ _ _ h
  change (secondLoop input total rows, middle) = (.ok buckets, ending) at hb
  have hbs := congrArg Prod.fst hb
  change (Except.ok (outputOfBuckets buckets), ending) = (.ok output, after) at h
  simp only [Prod.mk.injEq, Except.ok.injEq] at h
  rcases h with ⟨rfl, _⟩
  refine ⟨rows, total, middle, hr, ?_, order⟩
  have hp := secondLoop_rows input total rows buckets hbs
  have hc := secondLoop_capacities input total rows buckets hbs
  change (buckets.map (fun b => b.capacity)).map Fin.val = _
  calc
    _ = buckets.map (fun b => (CapacitySpec.capacity input total b.row)) := by
      simp only [List.map_map]
      apply List.map_congr_left
      intro b hb
      exact rowCapacity_matches_spec input total b.row b.capacity (hc b hb)
    _ = rows.map (CapacitySpec.capacity input total) := by
      simpa only [List.map_map, Function.comp_def] using
        congrArg (List.map (CapacitySpec.capacity input total)) hp

/-- The source total is demand plus the actual returned allocations, without overflow. -/
theorem firstLoop_total (l : Layout) (s : Storage) (oracle : StaticOracle)
    (input : CapacityInput) (n i : Nat) (total finalTotal : Word)
    (before after : Transcript) (rows : List CachedRow)
    (h : firstLoop l s oracle input n i total before = (.ok (rows, finalTotal), after)) :
    finalTotal.val = total.val + (rows.map (fun r => r.allocation.val)).sum := by
  induction n generalizing i total before rows with
  | zero =>
    simp [firstLoop, pure, pureExec] at h
    rcases h with ⟨⟨rfl, rfl⟩, _⟩
    simp
  | succ n ih =>
    change bindExec (firstRow l s oracle input i total) _ before = _ at h
    obtain ⟨⟨row, nextTotal⟩, middle, hr, h⟩ := bindExec_success _ _ _ _ _ h
    change bindExec (firstLoop l s oracle input n (i+1) nextTotal) _ middle = _ at h
    obtain ⟨⟨rest, lastTotal⟩, ending, hs, h⟩ := bindExec_success _ _ _ _ _ h
    change (Except.ok (row :: rest, lastTotal), ending) = _ at h
    simp only [Prod.mk.injEq, Except.ok.injEq] at h
    rcases h with ⟨⟨rfl, rfl⟩, rfl⟩
    have hi := firstRow_total l s oracle input i total before middle row nextTotal hr
    have ht := ih (i+1) nextTotal middle rest hs
    simp only [List.map_cons, List.sum_cons]
    omega

theorem producer_math_view (l : Layout) (s : Storage) (oracle : StaticOracle)
    (input : CapacityInput) (before after : Transcript) (output : CapacityOutput)
    (h : produce l s oracle input before = (.ok output, after)) :
    ∃ rows total middle,
      firstLoop l s oracle input (s (countSlot l)).val 0 input.depositsToAllocate before =
        (.ok (rows, total), middle) ∧
      total.val = input.depositsToAllocate.val + (rows.map (fun r => r.allocation.val)).sum ∧
      output.capacities.map Fin.val = rows.map (CapacitySpec.capacity input total) ∧
      RouterOrderRelated (routerOrder l s) output := by
  obtain ⟨rows, total, middle, hr, hc, ho⟩ := producer_capacity_correspondence l s oracle input before after output h
  exact ⟨rows, total, middle, hr,
    firstLoop_total l s oracle input _ 0 input.depositsToAllocate total before middle rows hr, hc, ho⟩

/-- A consumer-usable arithmetic bound derived from successful live execution. -/
theorem producer_total_bound (l : Layout) (s : Storage) (oracle : StaticOracle)
    (input : CapacityInput) (before after : Transcript) (output : CapacityOutput)
    (h : produce l s oracle input before = (.ok output, after)) :
    input.depositsToAllocate.val + (output.allocations.map Fin.val).sum < 2^256 := by
  change bindExec (firstLoop l s oracle input (s (countSlot l)).val 0
    input.depositsToAllocate) _ before = _ at h
  obtain ⟨⟨rows, total⟩, middle, hr, h⟩ := bindExec_success _ _ _ _ _ h
  change bindExec (liftChecked (secondLoop input total rows)) _ middle = _ at h
  obtain ⟨buckets, ending, hb, h⟩ := bindExec_success _ _ _ _ _ h
  change (secondLoop input total rows, middle) = (.ok buckets, ending) at hb
  have hbs := congrArg Prod.fst hb
  change (Except.ok (outputOfBuckets buckets), ending) = (.ok output, after) at h
  simp only [Prod.mk.injEq, Except.ok.injEq] at h
  rcases h with ⟨rfl, _⟩
  have hp := secondLoop_rows input total rows buckets hbs
  have hs : ((outputOfBuckets buckets).allocations.map Fin.val).sum =
      (rows.map (fun r => r.allocation.val)).sum := by
    simpa only [outputOfBuckets, List.map_map, Function.comp_def] using
      congrArg (fun rs => (rs.map (fun r : CachedRow => r.allocation.val)).sum) hp
  rw [hs, ← firstLoop_total l s oracle input _ 0 input.depositsToAllocate total before middle rows hr]
  exact total.isLt

end LidoSRv3.Audit.Source.TrioAlloc1
