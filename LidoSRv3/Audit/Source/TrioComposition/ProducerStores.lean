import LidoSRv3.Audit.Source.TrioComposition.MemoryTransport
import LidoSRv3.Audit.Source.TrioComposition.RowMemory

/-! Producer stores execute per row, not after constructing a ghost final output.
Memory here is an internal source word view; allocation guards and byte-level
primitive refinement are composed separately. Failed results discard internal
memory while preserving the original attempted-call transcript. -/
namespace LidoSRv3.Audit.Source.TrioComposition.ProducerStores
open TrioAlloc1
open MemoryTransport

def firstLoop (l : Layout) (s : Storage) (input : CapacityInput) (ap : Nat) :
    Nat → Nat → Word → MemoryWords → CallTree.Program ((List CachedRow × Word) × MemoryWords)
  | 0, _, total, memory => pure (([],total),memory)
  | n+1, i, total, memory => do
    let (row,total') ← CallTree.firstRow l s input i total
    let next := storeElement memory ap i row.allocation
    let ((rows,finalTotal),after) ← firstLoop l s input ap n (i+1) total' next
    pure ((row::rows,finalTotal),after)

theorem firstLoop_exact (l : Layout) (s : Storage) (input : CapacityInput) (ap n i : Nat)
    (total : Word) (memory : MemoryWords) :
    firstLoop l s input ap n i total memory =
      (do let (rows,last) ← CallTree.firstLoop l s input n i total
          pure ((rows,last),storeWords memory (ap+32*(i+1)) (rows.map CachedRow.allocation))) := by
  induction n generalizing i total memory with
  | zero => rfl
  | succ n ih =>
    simp only [firstLoop, CallTree.firstLoop, ih, RowMemory.bind_assoc, RowMemory.pure_bind,
      List.map_cons, storeWords, storeElement]
    have address : ap+32*(i+1)+32 = ap+32*(i+1+1) := by omega
    rw [address]

def secondLoop (input : CapacityInput) (total : Word) (cp : Nat) :
    List CachedRow → Nat → MemoryWords → Except Failure (List Bucket × MemoryWords)
  | [], _, memory => .ok ([],memory)
  | row::rows, i, memory => do
    let capacity ← rowCapacity input total row
    let next := storeElement memory cp i capacity
    let (buckets,after) ← secondLoop input total cp rows (i+1) next
    pure ({row,capacity}::buckets,after)

theorem secondLoop_exact (input : CapacityInput) (total : Word) (cp : Nat)
    (rows : List CachedRow) (i : Nat) (memory : MemoryWords) :
    secondLoop input total cp rows i memory =
      (TrioAlloc1.secondLoop input total rows).map
        (fun buckets => (buckets,storeWords memory (cp+32*(i+1)) (buckets.map Bucket.capacity))) := by
  induction rows generalizing i memory with
  | nil => rfl
  | cons row rows ih =>
    simp only [secondLoop, TrioAlloc1.secondLoop, ih]
    cases current : rowCapacity input total row with
    | error reason => simp [bind, Except.bind, Except.map]
    | ok capacity =>
      cases rest : TrioAlloc1.secondLoop input total rows with
      | error reason => simp [bind, Except.bind, Except.map]
      | ok buckets =>
        simp only [bind, Except.bind, Except.map, pure, Except.pure,
          List.map_cons, storeWords, storeElement]
        have address : cp+32*(i+1)+32 = cp+32*(i+1+1) := by omega
        rw [address]

def producer (memory : MemoryWords) (ap cp : Nat) (l : Layout) (s : Storage)
    (input : CapacityInput) : CallTree.Program (CapacityOutput × MemoryWords) := do
  let initial := zeroArray memory ap (s (countSlot l)).val
  let ((rows,total),allocated) ← firstLoop l s input ap (s (countSlot l)).val 0
    input.depositsToAllocate initial
  let capacities := zeroArray allocated cp (s (countSlot l)).val
  let (buckets,after) ← CallTree.check (secondLoop input total cp rows 0 capacities)
  pure (outputOfBuckets buckets,after)

private theorem check_map_bind (result : Except Failure α) (f : α → β)
    (next : β → CallTree.Program γ) :
    (CallTree.check (result.map f) >>= next) =
      (CallTree.check result >>= fun value => next (f value)) := by
  cases result <;> rfl

/-- The per-row memory instrumentation preserves every original source failure
and call continuation, not only successful final arrays. -/
theorem projection (memory : MemoryWords) (ap cp : Nat) (l : Layout) (s : Storage)
    (input : CapacityInput) :
    (do let (output,_) ← producer memory ap cp l s input; pure output) =
      CallTree.producer l s input := by
  simp only [producer,firstLoop_exact,RowMemory.bind_assoc,RowMemory.pure_bind,
    secondLoop_exact,check_map_bind,CallTree.producer]


/-- Sequential element writes derive the array relation from the retained header. -/
theorem element_writes_related (memory : MemoryWords) (pointer : Nat) (values : List Word)
    (header : (memory pointer).val = values.length) :
    ArrayAt (storeWords memory (pointer+32) values) pointer values := by
  constructor
  · rw [storeWords_outside _ _ _ pointer (Or.inl (by omega))]
    exact header
  · intro i
    have address : pointer+32*(i.val+1) = pointer+32+32*i.val := by omega
    rw [address]
    exact storeWords_read memory (pointer+32) values i

theorem element_writes_frame (memory : MemoryWords) (pointer : Nat) (values : List Word) :
    OutsideUnchanged memory (storeWords memory (pointer+32) values) pointer values.length := by
  intro address outside
  apply storeWords_outside
  simp only [InRegion] at outside
  omega

/-- Successful first-pass writes followed by capacity allocation and second-pass
writes establish both actual array regions. The old array is preserved by
separation, not by reconstructing a final heap from the completed output. -/
theorem arrays_related (memory : MemoryWords) (ap cp n : Nat)
    (allocations capacities : List Word)
    (alength : allocations.length = n) (clength : capacities.length = n)
    (separate : Disjoint ap n cp n) (aend : ap+32*(n+1) ≤ 2^256)
    (cend : cp+32*(n+1) ≤ 2^256) :
    let first := storeWords (zeroArray memory ap n) (ap+32) allocations
    let second := storeWords (zeroArray first cp n) (cp+32) capacities
    ArrayAt second ap allocations ∧ ArrayAt second cp capacities := by
  have small : n < 2^256 := by omega
  have initA := zeroArray_related memory ap n small
  have firstA : ArrayAt (storeWords (zeroArray memory ap n) (ap+32) allocations) ap allocations :=
    element_writes_related _ ap allocations (by simpa only [List.length_replicate,alength] using initA.1)
  have initC := zeroArray_related (storeWords (zeroArray memory ap n) (ap+32) allocations) cp n small
  have frameC : OutsideUnchanged
      (storeWords (zeroArray memory ap n) (ap+32) allocations)
      (zeroArray (storeWords (zeroArray memory ap n) (ap+32) allocations) cp n) cp n := by
    simpa only [zeroArray,List.length_replicate] using
      storeArray_outside (storeWords (zeroArray memory ap n) (ap+32) allocations) cp (List.replicate n (word 0))
  have keepA := frame_array _ _ cp n ap allocations frameC
    (by simpa only [Disjoint,alength] using Or.symm separate) firstA
  have finalC : ArrayAt
      (storeWords (zeroArray (storeWords (zeroArray memory ap n) (ap+32) allocations) cp n)
        (cp+32) capacities) cp capacities :=
    element_writes_related _ cp capacities (by simpa only [List.length_replicate,clength] using initC.1)
  constructor
  · exact frame_array _ _ cp capacities.length ap allocations (element_writes_frame _ cp capacities)
      (by simpa only [Disjoint,alength,clength] using Or.symm separate) keepA
  · exact finalC

/-- Exact successful result and attempted calls of the uninstrumented producer,
with two memory relations derived from the writes actually performed. -/
theorem success (memory : MemoryWords) (ap cp : Nat) (l : Layout) (s : Storage)
    (oracle : StaticOracle) (input : CapacityInput) (before after : Transcript)
    (output : CapacityOutput) (final : MemoryWords)
    (executed : CallTree.evaluate oracle (producer memory ap cp l s input) before =
      (.ok (output,final),after))
    (separate : Disjoint ap (s (countSlot l)).val cp (s (countSlot l)).val)
    (aend : ap+32*((s (countSlot l)).val+1) ≤ 2^256)
    (cend : cp+32*((s (countSlot l)).val+1) ≤ 2^256) :
    produce l s oracle input before = (.ok output,after) ∧
    MemoryArraysRelated final ap cp output := by
  simp only [producer,firstLoop_exact,RowMemory.bind_assoc,RowMemory.pure_bind,
    CallTree.evaluate_monad_bind,CallTree.firstLoop_correspondence,
    CallTree.evaluate_check,CallTree.evaluate_pure] at executed
  obtain ⟨⟨rows,total⟩,middle,first,rest⟩ := bindExec_success _ _ _ _ _ executed
  obtain ⟨⟨buckets,next⟩,ending,second,result⟩ := bindExec_success _ _ _ _ _ rest
  change (secondLoop input total cp rows 0 _,middle) = (.ok (buckets,next),ending) at second
  have secondRun := congrArg Prod.fst second
  have endingEq := congrArg Prod.snd second
  change middle = ending at endingEq
  subst ending
  rw [secondLoop_exact] at secondRun
  cases original : TrioAlloc1.secondLoop input total rows with
  | error reason => simp [original,Except.map] at secondRun
  | ok actual =>
    simp only [original,Except.map,Except.ok.injEq,Prod.mk.injEq] at secondRun
    obtain ⟨rfl,rfl⟩ := secondRun
    change (Except.ok (outputOfBuckets actual,_),middle) = (.ok (output,final),after) at result
    simp only [Prod.mk.injEq,Except.ok.injEq] at result
    obtain ⟨⟨rfl,rfl⟩,rfl⟩ := result
    have ordered := firstLoop_order l s oracle input (s (countSlot l)).val 0
      input.depositsToAllocate total before middle rows first
    have rowsLength : rows.length = (s (countSlot l)).val := by
      simpa only [List.length_map,List.length_range'] using congrArg List.length ordered
    have bucketRows := secondLoop_rows input total rows actual original
    have length : actual.length = (s (countSlot l)).val := by
      have h := congrArg List.length bucketRows
      simpa only [List.length_map,rowsLength] using h
    have allocations : actual.map (fun b => b.row.allocation) = rows.map CachedRow.allocation := by
      simpa only [List.map_map,Function.comp_def] using congrArg (List.map CachedRow.allocation) bucketRows
    constructor
    · simp only [produce,bind,bindExec,first,liftChecked,original,pure,pureExec]
    · have both := arrays_related memory ap cp (s (countSlot l)).val
        (rows.map CachedRow.allocation) (actual.map Bucket.capacity)
        (by simpa using rowsLength) (by simpa using length) separate aend cend
      simp only [Nat.reduceAdd,Nat.mul_one] at both ⊢
      refine ⟨?_,?_,?_,?_,?_⟩
      · simpa only [outputOfBuckets,allocations] using both.1
      · exact both.2
      · simpa only [outputOfBuckets,List.length_map,length] using aend
      · simpa only [outputOfBuckets,List.length_map,length] using cend
      · simpa only [outputOfBuckets,List.length_map,length,Disjoint] using separate

#print axioms projection
#print axioms success

#print axioms firstLoop_exact
#print axioms secondLoop_exact
end LidoSRv3.Audit.Source.TrioComposition.ProducerStores
