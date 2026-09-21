import LidoSRv3.Audit.MinFirstAllocation
import LidoSRv3.Audit.Source.MinFirstProportionalStep
import LidoSRv3.Audit.Source.TrioAlloc1.VerityProducer

/-!
# ALLOC-1 to ALLOC-2 seam: the produced arrays are ALLOC-2's inputs

`SRLib._getDepositAllocations` (`SRLib.sol:391-431`) hands the arrays
returned by `_getModulesAllocationAndCapacity` to
`MinFirstAllocationStrategy.allocate(allocated, capacities, depositsToAllocate)`.
P-ALLOC-1's registered `account_allocation_result` derives those arrays from
the executed producer (`VerityProducer.executeAccount`); P-ALLOC-2's step and
loop theorems consume rows `(allocation, capacity)` under `RowsCorrespond`, a
selected open candidate and the array-length bound.

This module builds the rows from a successful producer output
(`sourceRows`, `modelRows`) and proves the premises P-ALLOC-2 asks for:

* `rows_correspond` — the model rows correspond to the source rows;
* `candidate_agrees` — the model and source candidate searches agree;
* `selected_open` — a selected candidate is one of the rows and is open;
* `rows_length_lt_modulus` — the number of rows is the router's module
  count, a stored word, hence below `2^256`;
* `account_rows_seam` — all of the above from the executed producer;
* `account_step_bounded` — the registered P-ALLOC-2 step theorem instantiated
  on the produced rows: the checked proportional amount is positive, bounded by
  the remaining demand and capacity-safe, for every successful checked step.

The proportional-step fact itself lives in the source layer
(`LidoSRv3.Audit.Source.MinFirstProportionalStep`, re-stated with an
identical statement by `LidoSRv3.Audit.Guarantees.PAlloc2`), so this module
needs no Source → Guarantees edge.

The producer's words are `Fin (2^256)`; ALLOC-2's are Verity words. The
conversion `toWord` is value-preserving (`toWord_val`).

Pinned `lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`.
-/

set_option autoImplicit false

namespace LidoSRv3.Audit.Source.TrioComposition.AllocSeam
open LidoSRv3.Audit.Source.TrioAlloc1

/-- Producer word to Verity word, value-preserving. -/
def toWord (x : Fin (2 ^ 256)) : MinFirstAllocation.Source.Word :=
  Verity.Core.Uint256.ofNat x.val

theorem toWord_val (x : Fin (2 ^ 256)) : (toWord x).val = x.val := by
  show x.val % 2 ^ 256 = x.val
  exact Nat.mod_eq_of_lt x.isLt

theorem modulus_eq : Verity.Core.Uint256.modulus = 2 ^ 256 := rfl

/-- The rows the router hands to `MinFirstAllocationStrategy.allocate`: the
produced allocation and capacity arrays paired by index. -/
def sourceRows (o : CapacityOutput) : List MinFirstAllocation.Source.Row :=
  (o.allocations.zip o.capacities).map fun p => ⟨toWord p.1, toWord p.2⟩

/-- The same rows in the independent `Nat` model. -/
def modelRows (o : CapacityOutput) : List MinFirstAllocation.Model.Bucket :=
  (sourceRows o).map fun r => ⟨r.allocation.val, r.capacity.val⟩

theorem rows_correspond_map :
    ∀ (rows : List MinFirstAllocation.Source.Row),
      MinFirstAllocation.RowsCorrespond
        (rows.map fun r => ⟨r.allocation.val, r.capacity.val⟩) rows
  | [] => List.Forall₂.nil
  | r :: rs => List.Forall₂.cons ⟨rfl, rfl⟩ (rows_correspond_map rs)

theorem rows_correspond (o : CapacityOutput) :
    MinFirstAllocation.RowsCorrespond (modelRows o) (sourceRows o) :=
  rows_correspond_map (sourceRows o)

theorem candidate_agrees (o : CapacityOutput) :
    Option.map (fun b => (b.allocation, b.capacity))
        (MinFirstAllocation.Model.candidate? (modelRows o)) =
      Option.map (fun r => (r.allocation.val, r.capacity.val))
        (MinFirstAllocation.Source.candidate? (sourceRows o)) :=
  MinFirstAllocation.candidate_correspondence (rows_correspond o)

theorem selected_open (o : CapacityOutput) (best : MinFirstAllocation.Source.Row)
    (h : MinFirstAllocation.Source.candidate? (sourceRows o) = some best) :
    best ∈ sourceRows o ∧ MinFirstAllocation.Source.hasFreeSpace best = true :=
  MinFirstAllocation.source_candidate_mem_and_open h

theorem sourceRows_length (o : CapacityOutput) :
    (sourceRows o).length = o.allocations.length := by
  simp [sourceRows, List.length_zip, output_lengths_equal o]

/-- The first pass returns exactly the enumerated number of rows. -/
theorem firstLoop_length (l : Layout) (s : Storage) (oracle : StaticOracle)
    (input : CapacityInput) :
    ∀ (n i : Nat) (total finalTotal : TrioAlloc1.Word) (before after : Transcript) (rows : List CachedRow),
      firstLoop l s oracle input n i total before = (.ok (rows, finalTotal), after) →
      rows.length = n
  | 0, i, total, finalTotal, before, after, rows, h => by
    simp [firstLoop, pure, pureExec] at h
    rcases h with ⟨⟨rfl, rfl⟩, _⟩
    rfl
  | n + 1, i, total, finalTotal, before, after, rows, h => by
    change bindExec (firstRow l s oracle input i total) _ before = _ at h
    obtain ⟨⟨row, nextTotal⟩, middle, hr, h⟩ := bindExec_success _ _ _ _ _ h
    change bindExec (firstLoop l s oracle input n (i+1) nextTotal) _ middle = _ at h
    obtain ⟨⟨rest, lastTotal⟩, ending, hs, h⟩ := bindExec_success _ _ _ _ _ h
    change (Except.ok (row :: rest, lastTotal), ending) = _ at h
    simp only [Prod.mk.injEq, Except.ok.injEq] at h
    rcases h with ⟨⟨rfl, rfl⟩, rfl⟩
    have ht := firstLoop_length l s oracle input n (i+1) nextTotal _ middle _ rest hs
    simp [ht]

/-- A successful producer returns one row per enumerated module: the row count
is the stored module count, a word below `2^256`. -/
theorem produce_rows_length (l : Layout) (s : Storage) (oracle : StaticOracle)
    (input : CapacityInput) (before after : Transcript) (o : CapacityOutput)
    (h : produce l s oracle input before = (.ok o, after)) :
    (sourceRows o).length = (s (countSlot l)).val := by
  obtain ⟨rows, total, middle, hloop, _, hcap, _⟩ := producer_math_view l s oracle input before after o h
  have hlen := firstLoop_length l s oracle input _ 0 _ total before middle rows hloop
  have hc : o.capacities.length = rows.length := by
    have := congrArg List.length hcap
    simpa using this
  rw [sourceRows_length, output_lengths_equal o, hc, hlen]

theorem rows_length_lt_modulus (l : Layout) (s : Storage) (oracle : StaticOracle)
    (input : CapacityInput) (before after : Transcript) (o : CapacityOutput)
    (h : produce l s oracle input before = (.ok o, after)) :
    (sourceRows o).length < Verity.Core.Uint256.modulus := by
  rw [produce_rows_length l s oracle input before after o h, modulus_eq]
  exact (s (countSlot l)).isLt

/-- **Seam from the executed producer.** A successful `executeAccount` run
yields rows on which P-ALLOC-2's premises hold: correspondence, candidate
agreement, openness of a selected candidate, and the length bound. -/
theorem account_rows_seam (layout : Layout) (input : CapacityInput)
    (adversary : Compiler.CompilationModel.DenoteExternalCalls.AdversaryModel)
    (state : Compiler.CompilationModel.DenoteExternalCalls.CallState)
    (before after : Transcript) (o : CapacityOutput)
    (h : (VerityProducer.executeAccount layout input adversary state before).1 = (.ok o, after)) :
    MinFirstAllocation.RowsCorrespond (modelRows o) (sourceRows o) ∧
    Option.map (fun b => (b.allocation, b.capacity))
        (MinFirstAllocation.Model.candidate? (modelRows o)) =
      Option.map (fun r => (r.allocation.val, r.capacity.val))
        (MinFirstAllocation.Source.candidate? (sourceRows o)) ∧
    (∀ best, MinFirstAllocation.Source.candidate? (sourceRows o) = some best →
      best ∈ sourceRows o ∧ MinFirstAllocation.Source.hasFreeSpace best = true) ∧
    (sourceRows o).length =
      (VerityProducer.accountStorage state.world (countSlot layout)).val ∧
    (sourceRows o).length < Verity.Core.Uint256.modulus := by
  have hp : produce layout (VerityProducer.accountStorage state.world)
      (VerityProducer.sourceOracle adversary state.world) input before = (.ok o, after) := by
    rw [← (VerityProducer.account_producer_correspondence layout input adversary state before).1]
    exact h
  exact ⟨rows_correspond o, candidate_agrees o, selected_open o,
    produce_rows_length _ _ _ input before after o hp,
    rows_length_lt_modulus _ _ _ input before after o hp⟩

/-- **P-ALLOC-2's registered step theorem on the produced rows.** For every
selected candidate, nonzero remaining demand and successful checked amount on
the rows of a successful producer run, the model and source candidates agree,
the checked amount is the model amount, and it is positive, bounded by the
remaining demand and capacity-safe. -/
theorem account_step_bounded (layout : Layout) (input : CapacityInput)
    (adversary : Compiler.CompilationModel.DenoteExternalCalls.AdversaryModel)
    (state : Compiler.CompilationModel.DenoteExternalCalls.CallState)
    (before after : Transcript) (o : CapacityOutput)
    (h : (VerityProducer.executeAccount layout input adversary state before).1 = (.ok o, after))
    (best : MinFirstAllocation.Source.Row) (allocationSize w : MinFirstAllocation.Source.Word)
    (hSelected : MinFirstAllocation.Source.candidate? (sourceRows o) = some best)
    (hSize : allocationSize.val ≠ 0)
    (hAmount : MinFirstAllocation.Source.checkedAmount (sourceRows o) allocationSize best = some w) :
    (Option.map (fun b => (b.allocation, b.capacity))
        (MinFirstAllocation.Model.candidate? (modelRows o)) =
      some (best.allocation.val, best.capacity.val)) ∧
    MinFirstAllocation.Model.amount (modelRows o) allocationSize.val
      ⟨best.allocation.val, best.capacity.val⟩ = w.val ∧
    0 < w.val ∧ w.val ≤ allocationSize.val ∧
      best.allocation.val + w.val ≤ best.capacity.val := by
  obtain ⟨hRows, _, hOpen, _, hLen⟩ :=
    account_rows_seam layout input adversary state before after o h
  exact LidoSRv3.Audit.Source.MinFirstProportionalStep.forall_proportional_step_correspondence_and_bounded
    (modelRows o) (sourceRows o) best allocationSize w hRows hSelected
    (hOpen best hSelected).2 hLen hSize hAmount

#print axioms toWord_val
#print axioms rows_correspond
#print axioms candidate_agrees
#print axioms selected_open
#print axioms firstLoop_length
#print axioms produce_rows_length
#print axioms rows_length_lt_modulus
#print axioms account_rows_seam
#print axioms account_step_bounded

end LidoSRv3.Audit.Source.TrioComposition.AllocSeam
