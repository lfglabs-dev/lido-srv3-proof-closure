import LidoSRv3.Audit.Source.TrioAlloc1.Determinism
import LidoSRv3.Tests.TrioAlloc1.Execution

namespace LidoSRv3.Tests.TrioAlloc1
open LidoSRv3.Audit.Source.TrioAlloc1

set_option maxRecDepth 4096

/-- The independent parent excludes every continuation beyond the underflowing summary. -/
theorem prefetch_trace_refutes_relational_parent (result : CapacityResult) (after : Transcript)
    (extra : 1 < after.length) :
    ¬ Relational.Producer layout
      (storage 2 (packed 21 5000 0 2) (packed 22 5000 0 1)) underflow input [] result after := by
  intro claimed
  have equality := (Relational.producer_iff _ _ _ _ _ _ _).mp claimed
  have length := congrArg (fun execution => execution.2.length) equality
  have actual : (produce layout
      (storage 2 (packed 21 5000 0 2) (packed 22 5000 0 1)) underflow input []).2.length = 1 := by decide
  dsimp only at length
  rw [actual] at length
  omega

/-- A target-only capacity cannot satisfy the parent's result column, for any trace. -/
theorem target_only_refutes_relational_parent (output : CapacityOutput) (after : Transcript)
    (wrongCapacity : output.capacities.map Fin.val = [11]) :
    ¬ Relational.Producer layout (storage 1 (packed 21 10000 0 1) (word 0))
      (fun _ _ => .returned (summary 0 1 0)) input [] (.ok output) after := by
  intro claimed
  have equality := (Relational.producer_iff _ _ _ _ _ _ _).mp claimed
  have observed := congrArg (fun execution => columns execution.1) equality
  have actual : columns (produce layout (storage 1 (packed 21 10000 0 1) (word 0))
      (fun _ _ => .returned (summary 0 1 0)) input []).1 = .ok ([1], [1]) := by decide
  rw [actual] at observed
  simp only [columns, Except.map, wrongCapacity] at observed
  have capacityEquality := congrArg Prod.snd (Except.ok.inj observed)
  simp at capacityEquality

end LidoSRv3.Tests.TrioAlloc1
