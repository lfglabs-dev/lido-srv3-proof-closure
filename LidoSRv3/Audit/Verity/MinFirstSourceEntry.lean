import LidoSRv3.Audit.Verity.MinFirstDistributionTx

/-!
Additive decoded-array entry for `MinFirstAllocationStrategy.sol:30-44`.
The old transaction rejects all unequal lengths before checking demand. The
source returns immediately on zero demand, ignores extra capacities and only
panics on a short capacity array when its first candidate scan is reached.

This slice corrects those boundary outcomes, using the existing proportional
word loop. It is not an ABI decoder or full Solidity correspondence: byte/memory
layout, the two source scans, and loop-fuel sufficiency remain separate obligations.
There is no Solidity storage for this pure library. Returned arrays carry memory
results; observation counters and injected-failure branches are absent.
-/
namespace LidoSRv3.Audit.Verity.MinFirstSourceEntry

open _root_.Verity
open LidoSRv3.Audit.MinFirstAllocation
abbrev Word := Core.Uint256

inductive Error where
  | indexOutOfBounds
  | loopFailure
  deriving DecidableEq, Repr

structure Result where
  allocated : Word
  buckets : List Word
  deriving DecidableEq, Repr

/-- Rows preserve bucket order; surplus capacities are not read by the loop. -/
def rows (buckets capacities : List Word) : List Source.Row :=
  (buckets.zip capacities).map fun p => ⟨p.1, p.2⟩

/-- Source bounds error is distinct from the unresolved word-loop failure.
The old loop conflates arithmetic and fuel failure; neither is silently assigned
a source panic code here. Exact ABI revert encoding is outside this slice. -/
def errorName : Error → String
  | .indexOutOfBounds => "Panic(0x32)"
  | .loopFailure => "MODEL_LOOP_FAILURE"

/-- Arrays here are already decoded Solidity memory values. -/
def run (buckets capacities : List Word) (demand : Word) : Except Error Result :=
  if demand = 0 then .ok ⟨0, buckets⟩ else
  if capacities.length < buckets.length then .error .indexOutOfBounds else
  match MinFirstDistributionTx.allocateLoop demand.val (rows buckets capacities) demand 0 with
  | none => .error .loopFailure
  | some (after, total, _) => .ok ⟨total, after.map Source.Row.allocation⟩

/-- Pure library entry: no fictitious Solidity storage writes. -/
def allocateDecoded (buckets capacities : List Word) (demand : Word) : Contract Result :=
  fun state => match run buckets capacities demand with
    | .ok result => .success result state
    | .error reason => .revert (errorName reason) state

/-- Arbitrary lengths, including missing capacities, are accepted for zero demand. -/
theorem zero_demand (buckets capacities : List Word) :
    run buckets capacities 0 = .ok ⟨0, buckets⟩ := by simp [run]

/-- A short array panics only after the source's demand guard allows a scan. -/
theorem short_capacity (buckets capacities : List Word) (demand : Word)
    (hDemand : demand ≠ 0) (hShort : capacities.length < buckets.length) :
    run buckets capacities demand = .error .indexOutOfBounds := by
  simp [run, hDemand, hShort]

/-- Every modeled return preserves contract state, not merely a storage projection. -/
theorem success_preserves_state (buckets capacities : List Word) (demand : Word)
    (state after : ContractState) (result : Result)
    (h : (allocateDecoded buckets capacities demand).run state = .success result after) :
    after = state := by
  unfold Contract.run allocateDecoded at h
  cases hr : run buckets capacities demand <;> simp_all

theorem revert_restores_snapshot (buckets capacities : List Word) (demand : Word)
    (state after : ContractState) (reason : String)
    (h : (allocateDecoded buckets capacities demand).run state = .revert reason after) :
    after = state := by
  unfold Contract.run at h
  split at h <;> simp_all

/-- Successful nonzero executions refine the independent unbounded proportional
model, using the existing word-loop theorem. Decoding and row representation are
explicit premises; this is not a full source/ABI correspondence theorem. -/
theorem success_refines_proportional_model
    (buckets capacities : List Word) (demand : Word) (result : Result)
    (model : List Model.Bucket)
    (hDemand : demand ≠ 0)
    (hRows : RowsCorrespond model (rows buckets capacities))
    (hLength : (rows buckets capacities).length < Core.Uint256.modulus)
    (hRun : run buckets capacities demand = .ok result) :
    ∃ modelAfter remaining,
      MinFirstDistributionTx.modelAllocateLoop demand.val model demand.val 0 =
        some (modelAfter, result.allocated.val, remaining) ∧
      modelAfter.map Model.Bucket.allocation = result.buckets.map (·.val) := by
  unfold run at hRun
  simp only [hDemand, if_false] at hRun
  split at hRun
  · contradiction
  · cases hLoop : MinFirstDistributionTx.allocateLoop demand.val (rows buckets capacities) demand 0 with
    | none => simp [hLoop] at hRun
    | some output =>
      rcases output with ⟨after, total, remaining⟩
      simp only [hLoop, Except.ok.injEq] at hRun
      subst result
      have hSource : MinFirstDistributionTx.sourceAllocateLoop demand.val (rows buckets capacities) demand 0 =
          some (after, total, remaining) := by
        rw [MinFirstDistributionTx.sourceAllocateLoop_eq_allocateLoop]; exact hLoop
      obtain ⟨modelAfter, hModel, hAfter⟩ :=
        MinFirstDistributionTx.sourceAllocateLoop_model_correspondence demand.val model
          (rows buckets capacities) demand 0 after total remaining hRows hLength hSource
      refine ⟨modelAfter, remaining.val, hModel, ?_⟩
      change modelAfter.map Model.Bucket.allocation = (after.map Source.Row.allocation).map (·.val)
      rw [List.map_map]
      clear hLoop hSource hModel
      induction hAfter with
      | nil => rfl
      | cons h _ ih => simp only [List.map_cons]; exact congrArg₂ List.cons h.1 ih

/-- The old eager guard disagrees at every unequal-length zero-demand input,
regardless of planted memory. This locates the differential mismatch at the guard. -/
theorem eager_guard_disagrees_on_zero_demand
    (buckets capacities : List Word) (state : ContractState)
    (hLengths : buckets.length ≠ capacities.length) :
    (MinFirstDistributionTx.allocate buckets.length capacities.length 0).run state =
      .revert "ARRAY_LENGTH_MISMATCH" state ∧
    (allocateDecoded buckets capacities 0).run state = .success ⟨0, buckets⟩ state := by
  simp [MinFirstDistributionTx.allocate, Contract.run, hLengths, allocateDecoded, zero_demand]

end LidoSRv3.Audit.Verity.MinFirstSourceEntry
