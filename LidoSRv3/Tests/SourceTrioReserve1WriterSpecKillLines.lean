import LidoSRv3.Audit.Source.TrioReserve1.WriterSpec

/-!
Kill-lines pinning `TrioReserve1.WriterSpec` `Target` and
`Rebalance` transition-relation shapes.
-/

namespace LidoSRv3.Tests.SourceTrioReserve1WriterSpecKillLines

open LidoSRv3.Audit.Source.TrioReserve1.WriterSpec

private def zeroState : State :=
  { buffer := 0, reserve := 0, target := 0 }

/-! ## `State` three-field extraction. -/

theorem state_buffer :
    ({ buffer := 100, reserve := 50, target := 30 } : State).buffer = 100 := rfl

theorem state_reserve :
    ({ buffer := 100, reserve := 50, target := 30 } : State).reserve = 50 := rfl

theorem state_target :
    ({ buffer := 100, reserve := 50, target := 30 } : State).target = 30 := rfl

/-! ## `Target` — restated as three conjuncts. -/

theorem target_reduces
    (before : State) (requested : Nat) (after : State) :
    Target before requested after =
      (after.buffer = before.buffer ∧ after.target = requested ∧
        after.reserve = min before.reserve requested) := rfl

/-! ## `Rebalance` — restated as three conjuncts. -/

theorem rebalance_reduces (before after : State) :
    Rebalance before after =
      (after.buffer = before.buffer ∧ after.target = before.target ∧
        after.reserve = max before.reserve before.target) := rfl

/-! ## Concrete Target witness (reduce reserve to requested). -/

private def before1 : State := { buffer := 100, reserve := 50, target := 40 }
private def after1 : State := { buffer := 100, reserve := 30, target := 30 }

theorem target_witness :
    Target before1 30 after1 := by
  refine ⟨rfl, rfl, ?_⟩
  simp [before1, after1]

/-! ## Concrete Rebalance witness. -/

private def before2 : State := { buffer := 100, reserve := 20, target := 50 }
private def after2 : State := { buffer := 100, reserve := 50, target := 50 }

theorem rebalance_witness :
    Rebalance before2 after2 := by
  refine ⟨rfl, rfl, ?_⟩
  simp [before2, after2]

end LidoSRv3.Tests.SourceTrioReserve1WriterSpecKillLines
