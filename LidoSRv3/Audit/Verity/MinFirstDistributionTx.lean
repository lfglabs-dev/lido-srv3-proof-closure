import LidoSRv3.Audit.Source.MinFirstAmountCorrespondence
import Verity.Core.Model.Denote

/-!
# P-ALLOC-2 faithful memory-array transaction

This transaction models `MinFirstAllocationStrategy.allocate` /
`allocateToBestCandidate` from
`lidofinance/core@af095e48bbc1c3841c2c9936219c8461af01056b`, lines 30--107.
Unlike the earlier selected-row slice, both input arrays are read through the
compilation-model denotation of memory-backed `uint256[]` values.  The loop
is the source `while (allocated < allocationSize)` over
`allocateToBestCandidate`: scan, count, bound, `ceilDiv`, then
`buckets[bestCandidateIndex] += allocated`.  Successful buckets persist
through `writeArray`; totals use `writeSlot`.
-/

namespace LidoSRv3.Audit.Verity.MinFirstDistributionTx

open _root_.Verity
open Compiler.CompilationModel
open Compiler.CompilationModel.Denote
open LidoSRv3.Audit.MinFirstAllocation

abbrev Word := Source.Word

def bucketsBase : Nat := 0x1000
def capacitiesBase : Nat := 0x2000
def bucketsSlot : Nat := 20
def allocatedSlot : Nat := 21
def remainingSlot : Nat := 22

private def oracle : DenoteOracle where
  mappingSlot := fun _ _ => 0
  keccakMemorySlice := fun _ _ _ => 0

def arrayState (state : ContractState) (name : String) (base length : Nat) : DenoteState :=
  { world := state
    bindings := [(name ++ "_data_offset", base), (name ++ "_length", length)] }

def readWord (state : ContractState) (name : String) (base length index : Nat) : Option Word :=
  (evalExpr oracle [] (arrayState state name base length)
    (.memoryArrayElement name (.literal index))).map Verity.Core.Uint256.ofNat

def readArray (state : ContractState) (name : String) (base length : Nat) : Option (List Word) :=
  (List.range length).mapM (readWord state name base length)

def memoryFor (buckets capacities : List Word) : Nat → Word := fun offset =>
  if bucketsBase ≤ offset ∧ offset < bucketsBase + 32 * buckets.length ∧
      (offset - bucketsBase) % 32 = 0 then
    buckets.getD ((offset - bucketsBase) / 32) 0
  else if capacitiesBase ≤ offset ∧ offset < capacitiesBase + 32 * capacities.length ∧
      (offset - capacitiesBase) % 32 = 0 then
    capacities.getD ((offset - capacitiesBase) / 32) 0
  else 0

def stateFor (buckets capacities : List Word) (base : ContractState) : ContractState :=
  { base with memory := memoryFor buckets capacities }

/-- `buckets[bestCandidateIndex] += allocated` (source line 106). -/
def setAllocation (rows : List Source.Row) (i : Nat) (newAlloc : Word) :
    List Source.Row :=
  match rows[i]? with
  | none => rows
  | some r => rows.set i { r with allocation := newAlloc }

theorem setAllocation_length (rows : List Source.Row) (i : Nat) (w : Word) :
    (setAllocation rows i w).length = rows.length := by
  unfold setAllocation
  split <;> simp

theorem setAllocation_idxOf_eq_replaceFirst
    (rows : List Source.Row) (target : Source.Row) (updated : Word) (i : Nat)
    (hidx : rows.idxOf? target = some i) :
    setAllocation rows i updated = Source.replaceFirst target updated rows := by
  induction rows generalizing i with
  | nil => simp at hidx
  | cons r rs ih =>
      rw [List.idxOf?_eq_some_iff] at hidx
      rcases hidx with ⟨hi, hget, hfirst⟩
      cases i with
      | zero =>
          simp only [List.getElem_cons_zero] at hget
          subst r
          simp [setAllocation, Source.replaceFirst]
      | succ i =>
          have hiTail : i < rs.length := by simpa using hi
          have hgetTail : rs[i] = target := by simpa using hget
          have hr : r ≠ target := by
            intro h
            exact hfirst 0 (Nat.zero_lt_succ i) (by simpa [h])
          have htail : rs.idxOf? target = some i := by
            rw [List.idxOf?_eq_some_iff]
            refine ⟨hiTail, hgetTail, ?_⟩
            intro j hj heq
            exact hfirst (j + 1) (by omega) (by simpa using heq)
          have hopt : rs[i]? = some target := by
            rw [List.getElem?_eq_getElem hiTail, hgetTail]
          have hih := ih i htail
          simp only [setAllocation, hopt] at hih
          simpa [setAllocation, List.getElem?_cons_succ, hopt,
            Source.replaceFirst, hr] using congrArg (r :: ·) hih

/-- One `allocateToBestCandidate` step: scan, compute the share, then mutate
the best index. A zero amount is the Solidity `break`. -/
def allocateToBestCandidate (rows : List Source.Row) (remaining : Word) :
    Option (List Source.Row × Word) :=
  match Source.candidate? rows with
  | none => some (rows, 0)
  | some best => do
      let amount ← Source.checkedAmount rows remaining best
      if amount = 0 then some (rows, 0) else
      let updated ← Verity.Stdlib.Math.safeAdd best.allocation amount
      match rows.idxOf? best with
      | none => none
      | some i => some (setAllocation rows i updated, amount)

theorem allocateToBestCandidate_length
    {rows after : List Source.Row} {remaining amount : Word}
    (h : allocateToBestCandidate rows remaining = some (after, amount)) :
    after.length = rows.length := by
  unfold allocateToBestCandidate at h
  split at h
  · simp_all
  · rename_i best hs
    cases ha : Source.checkedAmount rows remaining best with
    | none => simp [ha, Option.bind_eq_bind] at h
    | some w =>
        simp only [ha, Option.bind_eq_bind, Option.bind_some] at h
        split at h
        · simp_all
        · cases hu : Verity.Stdlib.Math.safeAdd best.allocation w with
          | none => simp [hu] at h
          | some updated =>
              simp only [hu, Option.bind_some] at h
              split at h
              · simp_all
              · have hEq := Option.some.inj h
                have hAfter : setAllocation rows _ updated = after :=
                  congrArg Prod.fst hEq
                rw [← hAfter]
                exact setAllocation_length rows _ updated

/-- Independent unbounded proportional model step.  It copies the candidate,
amount, zero-break, and first-row mutation equations without referring to the
source step or its checked-word result. -/
def modelAllocateToBestCandidate (rows : List Model.Bucket) (remaining : Nat) :
    Option (List Model.Bucket × Nat) :=
  match Model.candidate? rows with
  | none => some (rows, 0)
  | some best =>
      let amount := Model.amount rows remaining best
      if amount = 0 then some (rows, 0)
      else some (Model.replaceFirst best amount rows, amount)

/-- Independent proportional `Nat` model loop.  This is intentionally not the
separate +1-per-iteration `MinFirst` strategy model. -/
def modelAllocateLoop : Nat → List Model.Bucket → Nat → Nat →
    Option (List Model.Bucket × Nat × Nat)
  | 0, rows, remaining, total =>
      if remaining = 0 then some (rows, total, remaining) else none
  | fuel + 1, rows, remaining, total =>
      if remaining = 0 then some (rows, total, remaining) else
      match modelAllocateToBestCandidate rows remaining with
      | none => none
      | some (after, amount) =>
          if amount = 0 then some (rows, total, remaining)
          else modelAllocateLoop fuel after (remaining - amount) (total + amount)

/-- `while (allocated < allocationSize)` over `allocateToBestCandidate`.
`fuel` is the initial demand value: positivity of every successful amount
makes it a sufficient structural bound. -/
def allocateLoop : Nat → List Source.Row → Word → Word →
    Option (List Source.Row × Word × Word)
  | 0, rows, remaining, total => if remaining = 0 then some (rows, total, remaining) else none
  | fuel + 1, rows, remaining, total =>
      if remaining = 0 then some (rows, total, remaining) else
      match allocateToBestCandidate rows remaining with
      | none => none
      | some (after, amount) =>
          if amount = 0 then some (rows, total, remaining) else do
            let newTotal ← Verity.Stdlib.Math.safeAdd total amount
            let newRemaining ← Verity.Stdlib.Math.safeSub remaining amount
            allocateLoop fuel after newRemaining newTotal

/-- Independently stated source-side loop.  This deliberately copies the
pinned equations instead of aliasing `allocateLoop`, so transaction/source
agreement is a proved equation rather than definitional sharing. -/
def sourceAllocateLoop : Nat → List Source.Row → Word → Word →
    Option (List Source.Row × Word × Word)
  | 0, rows, remaining, total =>
      if remaining = 0 then some (rows, total, remaining) else none
  | fuel + 1, rows, remaining, total =>
      if remaining = 0 then some (rows, total, remaining) else
      match allocateToBestCandidate rows remaining with
      | none => none
      | some (after, amount) =>
          if amount = 0 then some (rows, total, remaining) else do
            let newTotal ← Verity.Stdlib.Math.safeAdd total amount
            let newRemaining ← Verity.Stdlib.Math.safeSub remaining amount
            sourceAllocateLoop fuel after newRemaining newTotal

theorem sourceAllocateLoop_eq_allocateLoop :
    ∀ fuel rows remaining total,
      sourceAllocateLoop fuel rows remaining total =
        allocateLoop fuel rows remaining total
  | 0, _, _, _ => rfl
  | fuel + 1, rows, remaining, total => by
      simp only [sourceAllocateLoop, allocateLoop]
      split
      · rfl
      · cases hStep : allocateToBestCandidate rows remaining with
        | none => rfl
        | some step =>
            rcases step with ⟨after, amount⟩
            simp only
            split
            · rfl
            · simp [sourceAllocateLoop_eq_allocateLoop fuel]

/-- One successful checked source step is matched by the independently defined
unbounded proportional model step, and its row mutation preserves
`RowsCorrespond`.  The zero-amount and exhausted-capacity exits are included. -/
theorem modelAllocateToBestCandidate_corresponds
    {model : List Model.Bucket} {source : List Source.Row} {remaining : Word}
    (hRows : RowsCorrespond model source)
    (hLen : source.length < Verity.Core.Uint256.modulus) :
    ∀ after amount,
      allocateToBestCandidate source remaining = some (after, amount) →
      ∃ modelAfter,
        modelAllocateToBestCandidate model remaining.val =
          some (modelAfter, amount.val) ∧
        RowsCorrespond modelAfter after := by
  intro after amount hStep
  unfold allocateToBestCandidate at hStep
  cases hs : Source.candidate? source with
  | none =>
      simp only [hs] at hStep
      simp only [Option.some.injEq, Prod.mk.injEq] at hStep
      rcases hStep with ⟨rfl, rfl⟩
      have hm : Model.candidate? model = none := by
        have h := candidate_correspondence hRows
        rw [hs] at h
        cases hmodel : Model.candidate? model <;> simp_all
      exact ⟨model, by simp [modelAllocateToBestCandidate, hm], hRows⟩
  | some best =>
      simp only [hs] at hStep
      have hOpen := (source_candidate_mem_and_open hs).2
      have hm := model_candidate_eq_of_source hRows hs
      cases hw : Source.checkedAmount source remaining best with
      | none =>
          rw [hw] at hStep
          simp only [Option.bind_eq_bind, Option.bind_none] at hStep
          cases hStep
      | some w =>
          rw [hw] at hStep
          simp only [Option.bind_eq_bind, Option.bind_some] at hStep
          have hAmount : Model.amount model remaining.val
              ⟨best.allocation.val, best.capacity.val⟩ = w.val :=
            amount_correspondence hRows hLen rfl rfl hw
          by_cases hz : w = 0
          · subst w
            simp at hStep
            rcases hStep with ⟨rfl, rfl⟩
            exact ⟨model, by
              simp [modelAllocateToBestCandidate, hm, hAmount], hRows⟩
          · rw [if_neg hz] at hStep
            cases hu : Verity.Stdlib.Math.safeAdd best.allocation w with
            | none =>
                rw [hu] at hStep
                simp at hStep
            | some updated =>
                rw [hu] at hStep
                cases hi : source.idxOf? best with
                | none =>
                    rw [hi] at hStep
                    simp at hStep
                | some i =>
                    rw [hi] at hStep
                    have hp :
                        (setAllocation source i updated, w) = (after, amount) :=
                      Option.some.inj hStep
                    have hAfter : setAllocation source i updated = after :=
                      congrArg Prod.fst hp
                    have hOut : w = amount := congrArg Prod.snd hp
                    subst after
                    subst amount
                    have hwval : w.val ≠ 0 := by
                      intro hv
                      apply hz
                      apply Verity.Core.Uint256.ext
                      simpa using hv
                    have hUpdatedWord : best.allocation + w = updated := by
                      exact Option.some.inj ((checkedAmount_safeAdd hOpen hw).symm.trans hu)
                    have hAddLt :
                        best.allocation.val + w.val < Verity.Core.Uint256.modulus := by
                      exact Nat.lt_of_le_of_lt
                        (checkedAmount_le_headroom hOpen hw) best.capacity.isLt
                    have hUpdated :
                        best.allocation.val + w.val = updated.val := by
                      rw [← hUpdatedWord]
                      exact (Verity.Core.Uint256.add_eq_of_lt hAddLt).symm
                    refine ⟨Model.replaceFirst
                      ⟨best.allocation.val, best.capacity.val⟩ w.val model, ?_, ?_⟩
                    · simp [modelAllocateToBestCandidate, hm, hAmount, hwval]
                    · rw [setAllocation_idxOf_eq_replaceFirst source best updated i hi]
                      exact replaceFirst_correspondence hRows
                        ⟨best.allocation.val, best.capacity.val⟩ best rfl rfl
                        w.val updated hUpdated

private theorem safeAdd_val {a b c : Word}
    (h : Verity.Stdlib.Math.safeAdd a b = some c) :
    c.val = a.val + b.val := by
  by_cases hOverflow : a.val + b.val > Verity.Core.MAX_UINT256
  · have hNone : Verity.Stdlib.Math.safeAdd a b = none := by
      simp [Verity.Stdlib.Math.safeAdd, hOverflow]
    rw [hNone] at h
    cases h
  · have hSome : Verity.Stdlib.Math.safeAdd a b = some (a + b) := by
      simp [Verity.Stdlib.Math.safeAdd, hOverflow]
    rw [hSome] at h
    obtain rfl := Option.some.inj h
    apply Verity.Core.Uint256.add_eq_of_lt
    rw [← Verity.Core.Uint256.max_uint256_succ_eq_modulus]
    omega

private theorem safeSub_val {a b c : Word}
    (h : Verity.Stdlib.Math.safeSub a b = some c) :
    c.val = a.val - b.val ∧ b.val ≤ a.val := by
  unfold Verity.Stdlib.Math.safeSub at h
  split at h
  · cases h
  · rename_i hLe
    obtain rfl := Option.some.inj h
    have hLe' : b.val ≤ a.val := by omega
    exact ⟨Verity.Core.Uint256.sub_eq_of_le hLe', hLe'⟩

/-- Multi-step simulation of the independently copied proportional model loop
against the independently copied source loop.  Every successful source run has
a model run with the same mathematical totals and `RowsCorrespond` final rows. -/
theorem sourceAllocateLoop_model_correspondence :
    ∀ fuel model source remaining total after finalTotal finalRemaining,
      RowsCorrespond model source →
      source.length < Verity.Core.Uint256.modulus →
      sourceAllocateLoop fuel source remaining total =
        some (after, finalTotal, finalRemaining) →
      ∃ modelAfter,
        modelAllocateLoop fuel model remaining.val total.val =
          some (modelAfter, finalTotal.val, finalRemaining.val) ∧
        RowsCorrespond modelAfter after
  | 0, model, source, remaining, total, after, finalTotal, finalRemaining => by
      intro hRows _ hRun
      by_cases hz : remaining = 0
      · subst remaining
        simp [sourceAllocateLoop] at hRun
        rcases hRun with ⟨rfl, rfl, rfl⟩
        exact ⟨model, by simp [modelAllocateLoop], hRows⟩
      · have hzv : remaining.val ≠ 0 := by
          intro hv
          apply hz
          apply Verity.Core.Uint256.ext
          simpa using hv
        simp [sourceAllocateLoop, hz] at hRun
  | fuel + 1, model, source, remaining, total, after, finalTotal, finalRemaining => by
      intro hRows hLen hRun
      by_cases hz : remaining = 0
      · subst remaining
        simp [sourceAllocateLoop] at hRun
        rcases hRun with ⟨rfl, rfl, rfl⟩
        exact ⟨model, by simp [modelAllocateLoop], hRows⟩
      · have hzv : remaining.val ≠ 0 := by
          intro hv
          apply hz
          apply Verity.Core.Uint256.ext
          simpa using hv
        rw [sourceAllocateLoop, if_neg hz] at hRun
        rw [modelAllocateLoop, if_neg hzv]
        cases hStep : allocateToBestCandidate source remaining with
        | none =>
            simp only [hStep] at hRun
            simp at hRun
        | some step =>
            rcases step with ⟨nextSource, amount⟩
            simp only [hStep] at hRun
            obtain ⟨nextModel, hModelStep, hNextRows⟩ :=
              modelAllocateToBestCandidate_corresponds hRows hLen
                nextSource amount hStep
            by_cases ha : amount = 0
            · subst amount
              simp at hRun
              rcases hRun with ⟨rfl, rfl, rfl⟩
              exact ⟨model, by
                simp [modelAllocateLoop, hModelStep, hzv], hRows⟩
            · have hav : amount.val ≠ 0 := by
                intro hv
                apply ha
                apply Verity.Core.Uint256.ext
                simpa using hv
              rw [if_neg ha] at hRun
              simp only [modelAllocateLoop, if_neg hzv, hModelStep, if_neg hav]
              cases hAdd : Verity.Stdlib.Math.safeAdd total amount with
              | none =>
                  rw [hAdd] at hRun
                  simp at hRun
              | some newTotal =>
                  rw [hAdd] at hRun
                  cases hSub : Verity.Stdlib.Math.safeSub remaining amount with
                  | none =>
                      rw [hSub] at hRun
                      simp at hRun
                  | some newRemaining =>
                      rw [hSub] at hRun
                      simp only [Option.bind_eq_bind, Option.bind_some] at hRun
                      have hLenNext : nextSource.length <
                          Verity.Core.Uint256.modulus := by
                        rw [allocateToBestCandidate_length hStep]
                        exact hLen
                      obtain ⟨modelAfter, hModelRun, hFinalRows⟩ :=
                        sourceAllocateLoop_model_correspondence fuel nextModel
                          nextSource newRemaining newTotal after finalTotal
                          finalRemaining hNextRows hLenNext hRun
                      have hAddVal := safeAdd_val hAdd
                      have hSubVal := (safeSub_val hSub).1
                      refine ⟨modelAfter, ?_, hFinalRows⟩
                      simpa [hAddVal, hSubVal] using hModelRun

/-- Every successful fuel-bounded execution of the full proportional allocation
loop conserves demand: the final allocated total plus the final remainder is the
initial total plus the initial remainder.  This covers every number of
successful mutation steps, as well as the zero-demand and zero-amount exits. -/
theorem allocateLoop_conserves_total :
    ∀ fuel rows remaining total after finalTotal finalRemaining,
      allocateLoop fuel rows remaining total =
        some (after, finalTotal, finalRemaining) →
      finalTotal.val + finalRemaining.val = total.val + remaining.val
  | 0, rows, remaining, total, after, finalTotal, finalRemaining => by
      simp only [allocateLoop]
      split
      · intro h
        simp only [Option.some.injEq, Prod.mk.injEq] at h
        rcases h with ⟨rfl, rfl, rfl⟩
        rfl
      · simp
  | fuel + 1, rows, remaining, total, after, finalTotal, finalRemaining => by
      simp only [allocateLoop]
      split
      · intro h
        simp only [Option.some.injEq, Prod.mk.injEq] at h
        rcases h with ⟨rfl, rfl, rfl⟩
        rfl
      · cases hStep : allocateToBestCandidate rows remaining with
        | none => simp
        | some step =>
            rcases step with ⟨nextRows, amount⟩
            simp only
            split
            · intro h
              simp only [Option.some.injEq, Prod.mk.injEq] at h
              rcases h with ⟨rfl, rfl, rfl⟩
              rfl
            · cases hAdd : Verity.Stdlib.Math.safeAdd total amount with
              | none => simp
              | some newTotal =>
                  cases hSub : Verity.Stdlib.Math.safeSub remaining amount with
                  | none => simp
                  | some newRemaining =>
                      simp only [Option.bind_eq_bind, Option.bind_some]
                      intro hRun
                      have hConserve := allocateLoop_conserves_total fuel nextRows
                        newRemaining newTotal after finalTotal finalRemaining hRun
                      have hAddVal := safeAdd_val hAdd
                      have hSubVal := safeSub_val hSub
                      omega

/-- Persist allocated buckets as a `uint256[]`-shaped storage array. -/
def persistBuckets (buckets : List Word) (state : ContractState) : ContractState :=
  state.writeArray bucketsSlot buckets

structure Result where
  buckets : List Word
  allocated : Word
  remaining : Word
  deriving DecidableEq, Repr

/-- Executable transaction. A length mismatch or checked-arithmetic failure
reverts. `failAfterWrites` is a test hook placed after all bucket writes; it
proves rollback even after intermediate effects. -/
def allocate (bucketCount capacityCount : Nat) (allocationSize : Word)
    (failAfterWrites : Bool := false) : Contract Result := fun snapshot =>
  if bucketCount != capacityCount then .revert "ARRAY_LENGTH_MISMATCH" snapshot else
  match readArray snapshot "buckets" bucketsBase bucketCount,
      readArray snapshot "capacities" capacitiesBase capacityCount with
  | some buckets, some capacities =>
      let rows := (buckets.zip capacities).map fun p => Source.Row.mk p.1 p.2
      match allocateLoop allocationSize.val rows allocationSize 0 with
      | none => .revert "MIN_FIRST_ARITHMETIC" snapshot
      | some (afterRows, total, remaining) =>
          let after := afterRows.map Source.Row.allocation
          let dirty := persistBuckets after snapshot
          let dirty := (dirty.writeSlot allocatedSlot total).writeSlot remainingSlot remaining
          if failAfterWrites then .revert "INJECTED_AFTER_WRITES" dirty
          else .success ⟨after, total, remaining⟩ dirty
  | _, _ => .revert "MEMORY_ARRAY_DECODE" snapshot

inductive Status where | committed | reverted deriving DecidableEq, Repr

structure View where
  status : Status
  buckets : List Word
  allocated : Word
  remaining : Word
  deriving DecidableEq, Repr

def observe (before : List Word) : ContractResult Result → View
  | .success _ state =>
      ⟨.committed, state.readArray bucketsSlot, state.readSlot allocatedSlot,
        state.readSlot remainingSlot⟩
  | .revert _ _ => ⟨.reverted, before, 0, 0⟩

def sourceView (buckets capacities : List Word) (allocationSize : Word) : View :=
  if buckets.length != capacities.length then ⟨.reverted, buckets, 0, 0⟩ else
  let rows := (buckets.zip capacities).map fun p => Source.Row.mk p.1 p.2
  match sourceAllocateLoop allocationSize.val rows allocationSize 0 with
  | none => ⟨.reverted, buckets, 0, 0⟩
  | some (after, total, remaining) =>
      ⟨.committed, after.map Source.Row.allocation, total, remaining⟩

/-- Composed faithful-plane theorem: the real memory-array transaction has the
same outcome observables as the independently stated pinned-source loop. -/
theorem verity_tx_simulates_pinned_source
    (buckets capacities : List Word) (allocationSize : Word) (state : ContractState)
    (hBuckets : readArray state "buckets" bucketsBase buckets.length = some buckets)
    (hCapacities : readArray state "capacities" capacitiesBase capacities.length = some capacities) :
    observe buckets ((allocate buckets.length capacities.length allocationSize).run
      state) = sourceView buckets capacities allocationSize := by
  by_cases hLen : buckets.length = capacities.length
  · have hBne : (buckets.length != capacities.length) = false := by simp [hLen]
    unfold Contract.run allocate sourceView
    simp only [hBne, Bool.false_eq_true, ↓reduceIte, hBuckets, hCapacities]
    rw [sourceAllocateLoop_eq_allocateLoop]
    cases hRun : allocateLoop allocationSize.val
        (List.map (fun p => Source.Row.mk p.1 p.2) (buckets.zip capacities))
        allocationSize 0 <;>
      simp [observe, persistBuckets, allocatedSlot, remainingSlot,
        ContractState.readArray, ContractState.writeArray,
        ContractState.readSlot_writeSlot_same,
        ContractState.readSlot_writeSlot_other,
        ContractState.storageArray_writeSlot]
  · unfold Contract.run allocate sourceView
    simp [hLen, observe]

/-- Any failure, including the injected failure after all intermediate writes,
returns the exact pre-transaction snapshot. -/
theorem revert_restores_snapshot
    (bucketCount capacityCount : Nat) (allocationSize : Word) (inject : Bool)
    (state rollback : ContractState) (reason : String)
    (h : (allocate bucketCount capacityCount allocationSize inject).run state =
      .revert reason rollback) : rollback = state := by
  unfold Contract.run at h
  split at h <;> simp_all

end LidoSRv3.Audit.Verity.MinFirstDistributionTx
