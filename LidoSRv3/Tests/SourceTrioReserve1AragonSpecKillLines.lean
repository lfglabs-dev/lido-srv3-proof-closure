import LidoSRv3.Audit.Source.TrioReserve1.AragonSpec

/-!
Kill-lines pinning `TrioReserve1.AragonSpec` initialization/kernel
admission prefix Describes shape and exclusive law.
-/

namespace LidoSRv3.Tests.SourceTrioReserve1AragonSpecKillLines

open LidoSRv3.Audit.Source.TrioReserve1.AragonSpec

/-! ## `Prefix` two-arm enum distinctness. -/

theorem prefix_deny_ne_query :
    Prefix.deny ≠ Prefix.query := by decide

/-! ## `Describes` deny branch — unfolds to three disjuncts. -/

theorem describes_deny_reduces
    (initBlock blockNum kernel : Nat) :
    Describes initBlock blockNum kernel .deny =
      (initBlock = 0 ∨ blockNum < initBlock ∨ kernel = 0) := rfl

/-! ## `Describes` query branch — unfolds to three conjuncts. -/

theorem describes_query_reduces
    (initBlock blockNum kernel : Nat) :
    Describes initBlock blockNum kernel .query =
      (initBlock ≠ 0 ∧ initBlock ≤ blockNum ∧ kernel ≠ 0) := rfl

/-! ## `exclusive` — restated. -/

theorem exclusive_restated
    (initBlock blockNum kernel : Nat) :
    ¬ (Describes initBlock blockNum kernel .deny ∧
      Describes initBlock blockNum kernel .query) :=
  exclusive initBlock blockNum kernel

/-! ## Concrete deny witness (initBlock = 0). -/

theorem describes_deny_when_init_zero (blockNum kernel : Nat) :
    Describes 0 blockNum kernel .deny := Or.inl rfl

/-! ## Concrete query witness (all three conditions positive). -/

theorem describes_query_when_all_positive :
    Describes 1 5 42 .query :=
  ⟨by decide, by decide, by decide⟩

end LidoSRv3.Tests.SourceTrioReserve1AragonSpecKillLines
