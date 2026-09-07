import LidoSRv3.Audit.Source.TrioAlloc1.Execution

namespace LidoSRv3.Audit.Source.TrioAlloc1

/-- The second pass neither filters nor reorders first-pass rows. -/
theorem secondLoop_rows (input : CapacityInput) (total : Word)
    (rows : List CachedRow) (buckets : List Bucket)
    (h : secondLoop input total rows = .ok buckets) :
    buckets.map Bucket.row = rows := by
  induction rows generalizing buckets with
  | nil => simp [secondLoop] at h; subst buckets; rfl
  | cons row rows ih =>
    simp only [secondLoop, bind, Except.bind] at h
    cases hc : rowCapacity input total row with
    | error e => simp [hc] at h
    | ok cap =>
      simp only [hc] at h
      cases hs : secondLoop input total rows with
      | error e => simp [hs] at h
      | ok rest =>
        simp [hs, pure, Except.pure] at h
        subst buckets
        simp [ih rest hs]

/-- Every successful second-pass bucket is certified against that pass's input. -/
theorem secondLoop_capacities (input : CapacityInput) (total : Word)
    (rows : List CachedRow) (buckets : List Bucket)
    (h : secondLoop input total rows = .ok buckets) :
    ∀ b ∈ buckets, rowCapacity input total b.row = .ok b.capacity := by
  induction rows generalizing buckets with
  | nil => simp [secondLoop] at h; subst buckets; simp
  | cons row rows ih =>
    simp only [secondLoop, bind, Except.bind] at h
    cases hc : rowCapacity input total row with
    | error e => simp [hc] at h
    | ok cap =>
      simp only [hc] at h
      cases hs : secondLoop input total rows with
      | error e => simp [hs] at h
      | ok rest =>
        simp [hs, pure, Except.pure] at h
        subst buckets
        intro b hb
        simp only [List.mem_cons] at hb
        rcases hb with rfl | hb
        · exact hc
        · exact ih rest hs b hb

/-- A single successful iteration carries precisely the storage identity at i. -/
theorem firstRow_identity (l : Layout) (s : Storage) (oracle : StaticOracle)
    (input : CapacityInput) (i : Nat) (total : Word) (before after : Transcript)
    (row : CachedRow) (next : Word)
    (h : firstRow l s oracle input i total before = (.ok (row, next), after)) :
    row.stored = readModule l s i := by
  unfold firstRow at h
  simp only [bind, pure] at h
  split at h
  · simp [failExec] at h
  · repeat first
      | (split at h)
      | (simp only [bindExec, pureExec, liftChecked] at h)
      | (simp at h)
      | (obtain ⟨⟨rfl, _⟩, _⟩ := h; rfl)

theorem bindExec_success (action : Execution α) (next : α → Execution β)
    (before after : Transcript) (value : β)
    (h : bindExec action next before = (.ok value, after)) :
    ∃ a middle, action before = (.ok a, middle) ∧ next a middle = (.ok value, after) := by
  cases ha : action before with
  | mk result middle =>
    cases result with
    | error e => simp [bindExec, ha] at h
    | ok a => exact ⟨a, middle, rfl, by simpa [bindExec, ha] using h⟩

/-- An arbitrary successful first loop retains the complete router enumeration. -/
theorem firstLoop_order (l : Layout) (s : Storage) (oracle : StaticOracle)
    (input : CapacityInput) (n i : Nat) (total finalTotal : Word)
    (before after : Transcript) (rows : List CachedRow)
    (h : firstLoop l s oracle input n i total before = (.ok (rows, finalTotal), after)) :
    rows.map (fun r => r.stored.identity) =
      (List.range' i n).map (fun j => (readModule l s j).identity) := by
  induction n generalizing i total before rows with
  | zero =>
    simp [firstLoop, pure, pureExec] at h
    rcases h with ⟨⟨rfl, _⟩, _⟩
    rfl
  | succ n ih =>
    change bindExec (firstRow l s oracle input i total) _ before = _ at h
    obtain ⟨⟨row, nextTotal⟩, middle, hr, h⟩ := bindExec_success _ _ _ _ _ h
    change bindExec (firstLoop l s oracle input n (i+1) nextTotal) _ middle = _ at h
    obtain ⟨⟨rest, lastTotal⟩, ending, hs, h⟩ := bindExec_success _ _ _ _ _ h
    change (Except.ok (row :: rest, lastTotal), ending) = _ at h
    simp only [Prod.mk.injEq, Except.ok.injEq] at h
    rcases h with ⟨⟨rfl, rfl⟩, rfl⟩
    have hi := firstRow_identity l s oracle input i total before middle row nextTotal hr
    simp [List.range'_succ, hi, ih (i+1) nextTotal middle rest hs]

/-- Actual successful producer values, without a caller-supplied row binding. -/
theorem producer_router_order (l : Layout) (s : Storage) (oracle : StaticOracle)
    (input : CapacityInput) (before after : Transcript) (output : CapacityOutput)
    (h : produce l s oracle input before = (.ok output, after)) :
    RouterOrderRelated (routerOrder l s) output := by
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
  have ho := firstLoop_order l s oracle input _ 0 input.depositsToAllocate total
    before middle rows hr
  change buckets.map (fun b => b.row.stored.identity) = _
  calc
    _ = rows.map (fun r => r.stored.identity) := by
      simpa only [List.map_map, Function.comp_def] using
        congrArg (List.map (fun r : CachedRow => r.stored.identity)) hp
    _ = _ := by simpa [routerOrder, List.range_eq_range'] using ho

end LidoSRv3.Audit.Source.TrioAlloc1
