import LidoSRv3.Audit.Source.TrioAlloc1.Properties

/-!
Kill-lines pinning `TrioAlloc1.Properties` second-loop
identity/preservation theorems and `bindExec_success` unfolding
identity.
-/

namespace LidoSRv3.Tests.SourceTrioAlloc1PropertiesKillLines

open LidoSRv3.Audit.Source.TrioAlloc1

/-! ## `secondLoop_rows` — second pass neither filters nor reorders. -/

theorem secondLoop_rows_restated
    (input : CapacityInput) (total : Word)
    (rows : List CachedRow) (buckets : List Bucket)
    (h : secondLoop input total rows = .ok buckets) :
    buckets.map Bucket.row = rows :=
  secondLoop_rows input total rows buckets h

/-! ## `secondLoop_capacities` — every bucket certified. -/

theorem secondLoop_capacities_restated
    (input : CapacityInput) (total : Word)
    (rows : List CachedRow) (buckets : List Bucket)
    (h : secondLoop input total rows = .ok buckets) :
    ∀ b ∈ buckets, rowCapacity input total b.row = .ok b.capacity :=
  secondLoop_capacities input total rows buckets h

/-! ## `bindExec_success` — successful bind decomposes. -/

theorem bindExec_success_restated {α β : Type}
    (action : Execution α) (next : α → Execution β)
    (before after : Transcript) (value : β)
    (h : bindExec action next before = (.ok value, after)) :
    ∃ a middle, action before = (.ok a, middle) ∧
      next a middle = (.ok value, after) :=
  bindExec_success action next before after value h

end LidoSRv3.Tests.SourceTrioAlloc1PropertiesKillLines
