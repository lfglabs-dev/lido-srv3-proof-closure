import LidoSRv3.Audit.Source.TrioAlloc1.Determinism

/-!
Kill-lines pinning `TrioAlloc1.Relational.Deterministic` primitive
step determinism (`Done`, `Abort`, `Check`).
-/

namespace LidoSRv3.Tests.SourceTrioAlloc1DeterminismKillLines

open LidoSRv3.Audit.Source.TrioAlloc1
open LidoSRv3.Audit.Source.TrioAlloc1.Relational

/-! ## `done_deterministic` restated. -/

theorem done_deterministic_restated {α : Type} (value : α) :
    Deterministic (Done value) :=
  done_deterministic value

/-! ## `abort_deterministic` restated. -/

theorem abort_deterministic_restated {α : Type} (error : Failure) :
    Deterministic (Abort (α := α) error) :=
  abort_deterministic error

/-! ## `check_deterministic` restated. -/

theorem check_deterministic_restated {α : Type}
    (relation : Except Failure α → Prop) (unique : Unique relation) :
    Deterministic (Check relation) :=
  check_deterministic relation unique

/-! ## `then_deterministic` restated. -/

theorem then_deterministic_restated {α β : Type}
    (first : Step α) (next : α → Step β)
    (hf : Deterministic first) (hn : ∀ value, Deterministic (next value)) :
    Deterministic (Then first next) :=
  then_deterministic first next hf hn

end LidoSRv3.Tests.SourceTrioAlloc1DeterminismKillLines
