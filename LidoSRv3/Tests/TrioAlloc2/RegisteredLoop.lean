import LidoSRv3.Audit.Guarantees.PAlloc2

namespace LidoSRv3.Tests.TrioAlloc2.RegisteredLoop
open LidoSRv3.Audit.Source.TrioAlloc2

private def w (n : Nat) : Word := ⟨n % 2^256, Nat.mod_lt _ (by decide)⟩

/-- Removing the second scan's closed-bucket filter would cap this step at 4.
The pinned executor must ignore that closed row and advance to the open level 5. -/
theorem closed_bucket_does_not_cap_step :
    step [w 0, w 4, w 5] [w 10, w 4, w 10] (w 6) =
      .ok ⟨w 5, [w 5, w 4, w 5]⟩ := by rfl

/- Tie sharing and capacity exhaustion must use mutations from prior steps:
first bucket fills to 2, then only the second remains open for the last 3. -/
#eval do
  match allocate [w 0, w 0] [w 2, w 100] (w 5) with
  | .ok out =>
    unless out = ({ amount := w 5, buckets := [w 2, w 3] } : StepOutput) do
      throw (IO.userError s!"incorrect interleaved allocation: {repr out}")
  | .error reason => throw (IO.userError s!"unexpected panic: {repr reason}")

/-- This test uses the registered parent, not a detached library helper. -/
theorem registered_loop_consumed :
    LidoSRv3.Audit.Guarantees.PAlloc2.UnboundedProportionalLoop :=
  LidoSRv3.Audit.Guarantees.PAlloc2.step_correspondence_and_full_loop_conservation.2.2.2

#print axioms registered_loop_consumed
#print axioms closed_bucket_does_not_cap_step
end LidoSRv3.Tests.TrioAlloc2.RegisteredLoop
