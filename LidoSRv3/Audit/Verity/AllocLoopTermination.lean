import LidoSRv3.Audit.Verity.MinFirstDistributionTx
import LidoSRv3.Audit.Source.MinFirstAmountCorrespondence

/-!
# P-ALLOC-2 — unconditional `sourceAllocateLoop` termination

Pinned source: `lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`,
`contracts/common/lib/MinFirstAllocationStrategy.sol:30-44` (`allocate`)
and `:106` (`buckets[bestCandidateIndex] += allocated`).

The registered parent conserves only those `sourceAllocateLoop` runs that
already returned `some` under a caller-supplied fuel bound. This module does
not rename that fuel parameter. It takes the decreasing measure from the
Solidity mutation: each successful nonzero step fills at least one wei of
some open bucket (`:106`), so the sum of remaining capacities strictly
decreases.

Solidity also has a real loop bound: `while (allocated < allocationSize)`
(`:36`) and `allocated += allocatedToBestCandidate` (`:41`) with a
zero-amount `break` (`:38-40`). `allocated` is a `uint256` that strictly
increases, so the live loop runs at most `allocationSize` iterations. That
bound is cited; the Lean totality theorem uses the capacity-residue measure.

This file does not touch the +1 `MinFirst` child or the known
proportional/+1 spec gap.
-/

namespace LidoSRv3.Audit.Spec.AllocLoopTermination

open LidoSRv3.Audit.MinFirstAllocation
open LidoSRv3.Audit.Verity.MinFirstDistributionTx

abbrev Word := Source.Word

/-- Remaining headroom of one bucket. `Nat` subtraction is zero when the row
is already over capacity, matching the `buckets[i] >= capacities[i]` skip at
source lines 77-78. -/
def remainingCapacity (r : Source.Row) : Nat :=
  r.capacity.val - r.allocation.val

/-- Decreasing measure drawn from `MinFirstAllocationStrategy.sol:106`. -/
def remainingCapacitySum : List Source.Row → Nat
  | [] => 0
  | r :: rs => remainingCapacity r + remainingCapacitySum rs

/-- Sufficient fuel derived from the measure: one extra step covers the
zero-amount `break` after every open row is full while demand remains
(`MinFirstAllocationStrategy.sol:38-40`). -/
def residueFuel (rows : List Source.Row) : Nat :=
  remainingCapacitySum rows + 1

/-- Live Solidity bound cited at `:36-41`: a strictly increasing `uint256`
`allocated` cannot take more than `allocationSize` successful iterations. -/
def solidityAllocateBound (allocationSize : Word) : Nat :=
  allocationSize.val

theorem remainingCapacitySum_cons (r : Source.Row) (rs : List Source.Row) :
    remainingCapacitySum (r :: rs) =
      remainingCapacity r + remainingCapacitySum rs :=
  rfl

theorem idxOf?_of_mem {α : Type} [BEq α] [LawfulBEq α] {a : α}
    {l : List α} (h : a ∈ l) : ∃ i, l.idxOf? a = some i :=
  Option.isSome_iff_exists.mp (List.isSome_idxOf?.mpr h)

theorem checkedAmount_isSome
    {rs : List Source.Row} {allocationSize : Word} {best : Source.Row}
    (hOpen : Source.hasFreeSpace best = true) :
    ∃ w, Source.checkedAmount rs allocationSize best = some w := by
  have hcap : best.allocation.val < best.capacity.val := of_decide_eq_true hOpen
  have hsubCap : Verity.Stdlib.Math.safeSub best.capacity best.allocation =
      some (best.capacity - best.allocation) :=
    safeSub_isSome_of_le (Nat.le_of_lt hcap)
  unfold Source.checkedAmount
  cases hnext : Source.nextLevel? rs best.allocation with
  | none =>
      simp [Bind.bind, Option.bind, hsubCap]
  | some next =>
      have hgt : best.allocation.val < next.val := nextLevel_gt hnext
      have hsubLv : Verity.Stdlib.Math.safeSub next best.allocation =
          some (next - best.allocation) :=
        safeSub_isSome_of_le (Nat.le_of_lt hgt)
      simp [Bind.bind, Option.bind, hsubLv, hsubCap]

theorem allocateToBestCandidate_isSome
    (rows : List Source.Row) (remaining : Word) :
    ∃ result, allocateToBestCandidate rows remaining = some result := by
  cases hs : Source.candidate? rows with
  | none =>
      refine ⟨(rows, 0), ?_⟩
      simp [allocateToBestCandidate, hs]
  | some best =>
      have hOpen := (source_candidate_mem_and_open hs).2
      have hMem := (source_candidate_mem_and_open hs).1
      obtain ⟨w, hw⟩ :=
        checkedAmount_isSome (rs := rows) (allocationSize := remaining) hOpen
      obtain ⟨i, hi⟩ := idxOf?_of_mem (a := best) hMem
      have hadd := checkedAmount_safeAdd (rs := rows) hOpen hw
      have hfun :
          allocateToBestCandidate rows remaining =
            (Source.checkedAmount rows remaining best).bind fun amount =>
              if amount = 0 then some (rows, 0)
              else
                (Verity.Stdlib.Math.safeAdd best.allocation amount).bind fun updated =>
                  match rows.idxOf? best with
                  | none => none
                  | some i => some (setAllocation rows i updated, amount) := by
        simp [allocateToBestCandidate, hs]; rfl
      rw [hfun, hw]
      by_cases hz : w = 0
      · exact ⟨(rows, 0), by simp [hz]⟩
      · refine ⟨(setAllocation rows i (best.allocation + w), w), ?_⟩
        simp [hz, hadd, hi]

theorem remainingCapacitySum_setAllocation
    {rows : List Source.Row} {i : Nat} {r : Source.Row} {updated : Word}
    (hget : rows[i]? = some r)
    (hLe : r.allocation.val ≤ updated.val)
    (hCap : updated.val ≤ r.capacity.val) :
    remainingCapacitySum (setAllocation rows i updated) +
        (updated.val - r.allocation.val) =
      remainingCapacitySum rows := by
  induction rows generalizing i with
  | nil => simp at hget
  | cons head tail ih =>
      cases i with
      | zero =>
          have hr : head = r := by
            simpa [List.getElem?_cons_zero] using hget
          subst hr
          simp [setAllocation, List.getElem?_cons_zero, remainingCapacitySum,
            remainingCapacity]
          omega
      | succ j =>
          have hget' : tail[j]? = some r := by
            simpa [List.getElem?_cons_succ] using hget
          have hset :
              setAllocation (head :: tail) (j + 1) updated =
                head :: setAllocation tail j updated := by
            simp [setAllocation, List.getElem?_cons_succ, hget']
          rw [hset]
          change remainingCapacity head +
              remainingCapacitySum (setAllocation tail j updated) +
              (updated.val - r.allocation.val) =
            remainingCapacity head + remainingCapacitySum tail
          rw [Nat.add_assoc, ih hget']

theorem idxOf?_getElem? {α : Type} [BEq α] [LawfulBEq α] {a : α}
    {l : List α} {i : Nat} (h : l.idxOf? a = some i) :
    l[i]? = some a := by
  have hiff := (List.idxOf?_eq_some_iff (a := a) (l := l) (i := i)).mp h
  obtain ⟨hi, ha, _⟩ := hiff
  rw [List.getElem?_eq_getElem hi, ha]

theorem allocateToBestCandidate_decreases_residue
    {rows after : List Source.Row} {remaining amount : Word}
    (h : allocateToBestCandidate rows remaining = some (after, amount))
    (hPos : amount ≠ 0)
    (hLen : rows.length < Verity.Core.Uint256.modulus) :
    remainingCapacitySum after + amount.val = remainingCapacitySum rows ∧
      amount.val ≤ remaining.val ∧
      remainingCapacitySum after < remainingCapacitySum rows := by
  unfold allocateToBestCandidate at h
  cases hs : Source.candidate? rows with
  | none =>
      simp [hs] at h
      rcases h with ⟨rfl, rfl⟩
      exact absurd rfl hPos
  | some best =>
      have hOpen := (source_candidate_mem_and_open hs).2
      simp only [hs] at h
      cases hw : Source.checkedAmount rows remaining best with
      | none =>
          simp [hw, Option.bind_eq_bind] at h
      | some w =>
          simp only [hw, Option.bind_eq_bind, Option.bind_some] at h
          have hz : ¬ w = 0 := by
            intro hw0
            simp [hw0] at h
            rcases h with ⟨rfl, rfl⟩
            exact hPos rfl
          simp [hz] at h
          cases hu : Verity.Stdlib.Math.safeAdd best.allocation w with
          | none => simp [hu] at h
          | some updated =>
              simp only [hu, Option.bind_eq_bind, Option.bind_some] at h
              cases hi : rows.idxOf? best with
              | none => simp [hi] at h
              | some i =>
                  simp [hi] at h
                  rcases h with ⟨rfl, rfl⟩
                  have hget : rows[i]? = some best := idxOf?_getElem? hi
                  have hadd := checkedAmount_safeAdd hOpen hw
                  have hUpdated : updated = best.allocation + w := by
                    rw [hadd] at hu
                    exact Option.some.inj hu.symm
                  have hHead := checkedAmount_le_headroom hOpen hw
                  have hAddLt :
                      best.allocation.val + w.val < Verity.Core.Uint256.modulus :=
                    Nat.lt_of_le_of_lt hHead best.capacity.isLt
                  have hVal : updated.val = best.allocation.val + w.val := by
                    rw [hUpdated]
                    exact val_add_of_lt hAddLt
                  have hLe : best.allocation.val ≤ updated.val := by omega
                  have hCap : updated.val ≤ best.capacity.val := by omega
                  have hSum := remainingCapacitySum_setAllocation hget hLe hCap
                  have hSize := checkedAmount_le_size hOpen hLen hw
                  have hRemPos : remaining.val ≠ 0 := by
                    intro hzv
                    have : w.val = 0 := Nat.eq_zero_of_le_zero (by omega)
                    exact hz (Verity.Core.Uint256.ext this)
                  have hAmt : 0 < w.val := checkedAmount_pos hOpen hLen hRemPos hw
                  refine ⟨by
                    rw [hVal] at hSum
                    simpa [Nat.add_comm] using hSum, hSize, ?_⟩
                  omega

theorem safeAdd_of_sum_lt {a b : Word}
    (h : a.val + b.val < Verity.Core.Uint256.modulus) :
    Verity.Stdlib.Math.safeAdd a b = some (a + b) := by
  have hmax : Verity.Core.MAX_UINT256 + 1 = Verity.Core.Uint256.modulus :=
    Verity.Core.Uint256.max_uint256_succ_eq_modulus
  have hle : a.val + b.val ≤ Verity.Core.MAX_UINT256 := by omega
  simp [Verity.Stdlib.Math.safeAdd, Nat.not_lt.mpr hle]

theorem sourceAllocateLoop_total
    (fuel : Nat) (rows : List Source.Row) (remaining total : Word)
    (hLen : rows.length < 2 ^ 256)
    (hInv : total.val + remaining.val < 2 ^ 256)
    (hFuel : remaining = 0 ∨ residueFuel rows ≤ fuel) :
    ∃ after allocated leftover,
      sourceAllocateLoop fuel rows remaining total = some (after, allocated, leftover) := by
  induction fuel generalizing rows remaining total with
  | zero =>
      cases hFuel with
      | inl hz =>
          subst remaining
          exact ⟨rows, total, 0, by simp [sourceAllocateLoop]⟩
      | inr hle =>
          exact False.elim (Nat.not_succ_le_zero _ hle)
  | succ fuel ih =>
      by_cases hz : remaining = 0
      · subst remaining
        exact ⟨rows, total, 0, by simp [sourceAllocateLoop]⟩
      · have hStep? := allocateToBestCandidate_isSome rows remaining
        obtain ⟨step, hStep⟩ := hStep?
        rcases step with ⟨nextRows, amount⟩
        simp only [sourceAllocateLoop, hz, ↓reduceIte, hStep]
        by_cases ha : amount = 0
        · exact ⟨rows, total, remaining, by simp [ha]⟩
        · have hDec := allocateToBestCandidate_decreases_residue hStep ha (by
            simpa [Verity.Core.Uint256.modulus, Verity.Core.UINT256_MODULUS] using
              hLen)
          have hAddBound : total.val + amount.val < 2 ^ 256 := by
            omega
          have hAdd := safeAdd_of_sum_lt (a := total) (b := amount) hAddBound
          have hSub := safeSub_isSome_of_le (a := remaining) (b := amount) hDec.2.1
          simp only [ha, ↓reduceIte, Option.bind_eq_bind, hAdd, hSub, Option.bind_some]
          have hLenNext : nextRows.length < 2 ^ 256 := by
            rw [allocateToBestCandidate_length hStep]
            exact hLen
          have hAddVal := val_add_of_lt (by
            simpa [Verity.Core.Uint256.modulus, Verity.Core.UINT256_MODULUS] using
              hAddBound)
          have hSubVal :=
            val_sub_of_le (a := remaining) (b := amount) hDec.2.1
          have hInvNext :
              (total + amount).val + (remaining - amount).val < 2 ^ 256 := by
            rw [hAddVal, hSubVal]
            omega
          have hFuelNext : residueFuel nextRows ≤ fuel := by
            dsimp [residueFuel] at hFuel ⊢
            have hRes : remainingCapacitySum nextRows + 1 ≤ remainingCapacitySum rows := by
              omega
            have hStart : remainingCapacitySum rows + 1 ≤ fuel + 1 := by
              cases hFuel with
              | inl h0 => exact absurd h0 hz
              | inr hle => exact hle
            omega
          exact ih nextRows (remaining - amount) (total + amount) hLenNext hInvNext
            (Or.inr hFuelNext)

/-- Unconditional termination: the fuel is the capacity-residue measure,
not a caller-supplied bound that can be chosen too small. -/
theorem sourceAllocateLoop_terminates
    (rows : List Source.Row) (allocationSize : Word)
    (hLen : rows.length < 2 ^ 256) :
    ∃ after allocated leftover,
      sourceAllocateLoop (residueFuel rows) rows allocationSize 0 =
        some (after, allocated, leftover) :=
  sourceAllocateLoop_total (residueFuel rows) rows allocationSize 0 hLen
    (by
      have h0 : (0 : Word).val = 0 := rfl
      have hlt : allocationSize.val < 2 ^ 256 := allocationSize.isLt
      omega)
    (Or.inr (Nat.le_refl _))

/-- Conservation with no fuel premise: every well-length row list has a
terminating residue-fuel run whose allocated + remaining equals the
request. -/
theorem source_allocate_conserves_without_fuel
    (rows : List Source.Row) (allocationSize : Word)
    (hLen : rows.length < 2 ^ 256) :
    ∃ after allocated leftover,
      sourceAllocateLoop (residueFuel rows) rows allocationSize 0 =
        some (after, allocated, leftover) ∧
      allocated.val + leftover.val = allocationSize.val := by
  obtain ⟨after, allocated, leftover, hRun⟩ :=
    sourceAllocateLoop_terminates rows allocationSize hLen
  refine ⟨after, allocated, leftover, hRun, ?_⟩
  have hEq :
      sourceAllocateLoop (residueFuel rows) rows allocationSize 0 =
        allocateLoop (residueFuel rows) rows allocationSize 0 :=
    sourceAllocateLoop_eq_allocateLoop _ _ _ _
  rw [hEq] at hRun
  simpa using allocateLoop_conserves_total (residueFuel rows) rows allocationSize 0
    after allocated leftover hRun

#print axioms sourceAllocateLoop_terminates
#print axioms source_allocate_conserves_without_fuel

end LidoSRv3.Audit.Spec.AllocLoopTermination
