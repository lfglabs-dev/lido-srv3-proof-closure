import audit.trio.alloc2.composition.Composition
import LidoSRv3.Audit.Source.TrioAlloc1.Memory

/-! Writes into existing byte-addressed word memory. This is the v0 word-memory
boundary, not overlapping EVM byte-store semantics or compiler store-trace
refinement. Array writeback preserves arbitrary memory outside element slots;
it never rebuilds memory from the returned arrays. -/
namespace LidoSRv3.Audit.Source.TrioAlloc2.MemoryWrite
open _root_.LidoSRv3.Audit.Source.TrioAlloc1 (MemoryWords ArrayAt)

def store (memory : MemoryWords) (address : Nat) (value : Word) : MemoryWords :=
  fun location => if location = address then value else memory location

def writeWords (memory : MemoryWords) (start : Nat) : List Word → MemoryWords
  | [] => memory
  | value :: rest => writeWords (store memory start value) (start+32) rest

theorem outside (values : List Word) (memory : MemoryWords) (start address : Nat)
    (h : address < start ∨ start+32*values.length ≤ address) :
    writeWords memory start values address = memory address := by
  induction values generalizing memory start with
  | nil => rfl
  | cons value rest ih =>
    simp only [List.length_cons] at h
    rw [writeWords, ih _ _ (by omega)]
    simp [store, show address ≠ start by omega]

theorem element (values : List Word) (memory : MemoryWords) (start : Nat)
    (i : Fin values.length) :
    writeWords memory start values (start+32*i.val) = values[i] := by
  induction values generalizing memory start with
  | nil => exact Fin.elim0 i
  | cons value rest ih =>
    rcases i with ⟨i, bound⟩
    cases i with
    | zero =>
      simp only [writeWords, Nat.mul_zero, Nat.add_zero]
      rw [outside rest _ (start+32) start (Or.inl (by omega))]
      simp [store]
    | succ i =>
      have inside : i < rest.length := by simpa using Nat.lt_of_succ_lt_succ bound
      have addr : start+32*(i+1) = (start+32)+32*i := by omega
      change writeWords (store memory start value) (start+32) rest (start+32*(i+1)) = rest[i]
      rw [addr]
      exact ih (store memory start value) (start+32) ⟨i, inside⟩

def writeArray (memory : MemoryWords) (pointer : Nat) (values : List Word) : MemoryWords :=
  writeWords memory (pointer+32) values

theorem writeArray_related (memory : MemoryWords) (pointer : Nat) (old values : List Word)
    (related : ArrayAt memory pointer old) (length : values.length = old.length) :
    ArrayAt (writeArray memory pointer values) pointer values := by
  refine ⟨?_, ?_⟩
  · rw [writeArray, outside values memory (pointer+32) pointer (Or.inl (by omega))]
    exact related.1.trans length.symm
  · intro i
    have addr : pointer+32*(i.val+1) = (pointer+32)+32*i.val := by omega
    rw [addr]
    exact element values memory (pointer+32) i

/-- Both region orders are admitted; no fixed 0x1000/0x2000 toy addresses. -/
def ArraysAt (memory : MemoryWords) (ap cp : Nat) (buckets capacities : List Word) : Prop :=
  ArrayAt memory ap buckets ∧ ArrayAt memory cp capacities ∧
  (ap+32*(buckets.length+1) ≤ cp ∨ cp+32*(capacities.length+1) ≤ ap)

theorem writeArray_preserves (memory : MemoryWords) (ap cp : Nat) (buckets capacities next : List Word)
    (related : ArraysAt memory ap cp buckets capacities)
    (length : next.length = buckets.length) :
    ArraysAt (writeArray memory ap next) ap cp next capacities := by
  rcases related with ⟨b, c, separated⟩
  have frame : ∀ address, cp ≤ address → address < cp+32*(capacities.length+1) →
      writeArray memory ap next address = memory address := by
    intro address lower upper
    apply outside
    rcases separated with left | right <;> simp only [length] <;> omega
  refine ⟨writeArray_related memory ap buckets next b length, ⟨?_, ?_⟩, ?_⟩
  · rw [frame cp (by omega) (by omega)]
    exact c.1
  · intro i
    rw [frame _ (by omega) (by have := i.isLt; omega)]
    exact c.2 i
  · simpa only [length] using separated

def readArray (memory : MemoryWords) (pointer : Nat) : List Word :=
  List.ofFn fun i : Fin (memory pointer).val => memory (pointer+32*(i.val+1))

theorem readArray_eq (memory : MemoryWords) (pointer : Nat) (values : List Word)
    (related : ArrayAt memory pointer values) : readArray memory pointer = values := by
  apply List.ext_getElem
  · simpa only [readArray, List.length_ofFn] using related.1
  · intro i h₁ h₂
    simpa [readArray] using related.2 ⟨i, h₂⟩

/-- The executable adapter reads the current memory and writes into that same
memory. It is an array-observation boundary; it does not claim the compiler
performs this complete writeback rather than its indexed step stores. -/
def run (memory : MemoryWords) (ap cp : Nat) (demand : Word) : Result (Word × MemoryWords) := do
  let out ← allocate (readArray memory ap) (readArray memory cp) demand
  pure (out.amount, writeArray memory ap out.buckets)

theorem run_success (memory : MemoryWords) (ap cp : Nat) (buckets capacities : List Word)
    (demand : Word) (related : ArraysAt memory ap cp buckets capacities)
    (lengths : buckets.length ≤ capacities.length) :
    ∃ out, allocate buckets capacities demand = .ok out ∧
      run memory ap cp demand = .ok (out.amount, writeArray memory ap out.buckets) ∧
      ArraysAt (writeArray memory ap out.buckets) ap cp out.buckets capacities ∧
      bucketTotal out.buckets = bucketTotal buckets + out.amount.val ∧
      Spec.Distributes (decodedRows buckets capacities) demand.val out.amount.val
        (decodedRows out.buckets capacities) := by
  have bound : buckets.length < 2^256 := related.1.1 ▸ (memory ap).isLt
  obtain ⟨out, executed⟩ := allocate_success buckets capacities demand lengths bound
  refine ⟨out, executed, ?_, ?_, allocate_conserves _ _ _ _ executed, ?_⟩
  · simp only [run, readArray_eq _ _ _ related.1, readArray_eq _ _ _ related.2.1,
      executed, bind, Except.bind, pure, Except.pure]
  · exact writeArray_preserves memory ap cp buckets capacities out.buckets related
      (allocate_preserves_length _ _ _ _ executed)
  · exact allocate_refines buckets capacities demand out executed

/-- The agreed v0 memory relation is sufficient: it supplies lengths, both
region orders, and nonwrapping extents. No toy memory constructor is assumed. -/
theorem interface_run_success (memory : MemoryWords) (ap cp : Nat)
    (produced : TrioAlloc1.CapacityOutput) (demand : Word)
    (related : TrioAlloc1.MemoryArraysRelated memory ap cp produced) :
    ∃ out : StepOutput,
      run memory ap cp demand = .ok (out.amount, writeArray memory ap out.buckets) ∧
      ArraysAt (writeArray memory ap out.buckets) ap cp out.buckets produced.capacities ∧
      ap+32*(out.buckets.length+1) ≤ 2^256 ∧
      cp+32*(produced.capacities.length+1) ≤ 2^256 ∧
      Spec.Distributes (decodedRows produced.allocations produced.capacities)
        demand.val out.amount.val (decodedRows out.buckets produced.capacities) := by
  have arrays : ArraysAt memory ap cp produced.allocations produced.capacities :=
    ⟨related.1, related.2.1, related.2.2.2.2⟩
  obtain ⟨out, executed, ran, preserved, _, specification⟩ := run_success memory ap cp
    produced.allocations produced.capacities demand arrays
    (Nat.le_of_eq (TrioAlloc1.output_lengths_equal produced))
  have length := allocate_preserves_length _ _ _ _ executed
  exact ⟨out, ran, preserved, by rw [length]; exact related.2.2.1,
    related.2.2.2.1, specification⟩

#print axioms interface_run_success

/-- A second allocation reads the first call's written buckets in the same
memory. No state reconstruction or reset is permitted in either run. -/
theorem sequential (memory : MemoryWords) (ap cp : Nat) (buckets capacities : List Word)
    (firstDemand secondDemand : Word) (related : ArraysAt memory ap cp buckets capacities)
    (lengths : buckets.length ≤ capacities.length) :
    ∃ first second : StepOutput,
      run memory ap cp firstDemand = .ok (first.amount, writeArray memory ap first.buckets) ∧
      run (writeArray memory ap first.buckets) ap cp secondDemand =
        .ok (second.amount, writeArray (writeArray memory ap first.buckets) ap second.buckets) ∧
      ArraysAt (writeArray (writeArray memory ap first.buckets) ap second.buckets)
        ap cp second.buckets capacities ∧
      bucketTotal second.buckets = bucketTotal buckets + first.amount.val + second.amount.val ∧
      Spec.Distributes (decodedRows first.buckets capacities) secondDemand.val second.amount.val
        (decodedRows second.buckets capacities) := by
  obtain ⟨first, firstExec, firstRun, firstMemory, firstTotal, _⟩ :=
    run_success memory ap cp buckets capacities firstDemand related lengths
  have firstLength := allocate_preserves_length buckets capacities firstDemand first firstExec
  obtain ⟨second, _, secondRun, secondMemory, secondTotal, secondSpec⟩ :=
    run_success (writeArray memory ap first.buckets) ap cp first.buckets capacities secondDemand
      firstMemory (by omega)
  exact ⟨first, second, firstRun, secondRun, secondMemory, by omega, secondSpec⟩

/-- Omitting writeback violates the same ArrayAt postcondition used by the
consumer theorem, even when lengths and the initial array relation hold. -/
theorem dropped_write_refutes_postcondition :
    ¬ (∀ (memory : MemoryWords) (pointer : Nat) (old values : List Word),
      ArrayAt memory pointer old → values.length = old.length → ArrayAt memory pointer values) := by
  intro claimed
  let memory : MemoryWords := fun address => if address = 128 then one else zero
  have before : ArrayAt memory 128 [zero] := by
    constructor
    · rfl
    · intro i
      have index : i.val = 0 := by have := i.isLt; simp only [List.length_cons, List.length_nil] at this; omega
      simp [memory, index]
  have after := (claimed memory 128 [zero] [one] before rfl).2 ⟨0, by decide⟩
  have impossible : zero = one := by simpa [memory] using after
  exact (by decide : zero ≠ one) impossible

#print axioms dropped_write_refutes_postcondition

#print axioms sequential

#print axioms outside
#print axioms writeArray_preserves
#print axioms run_success
end LidoSRv3.Audit.Source.TrioAlloc2.MemoryWrite
