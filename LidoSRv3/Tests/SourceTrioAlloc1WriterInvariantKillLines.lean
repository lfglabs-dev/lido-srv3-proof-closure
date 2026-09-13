import LidoSRv3.Audit.Source.TrioAlloc1.WriterInvariant

/-!
Kill-lines pinning `TrioAlloc1.WriterInvariant` `Holds` predicate,
`empty` base case, `replacement_address` field-preservation, and
`identity_preserved` frame lemma.
-/

namespace LidoSRv3.Tests.SourceTrioAlloc1WriterInvariantKillLines

open LidoSRv3.Audit.Source.TrioAlloc1
open LidoSRv3.Audit.Source.TrioAlloc1.WriterInvariant

/-! ## `empty` — Holds is vacuously true when count = 0. -/

theorem empty_restated (l : Layout) (s : Storage)
    (h : (s (countSlot l)).val = 0) :
    Holds l s :=
  empty l s h

/-! ## `replacement_address` — replacing share bits preserves the
    packed address field (bits 0..160). -/

theorem replacement_address_restated
    (original : Word) (share threshold : Fin (2^16)) :
    field (ShareWriter.replaceShares original share threshold) 0 160 =
      field original 0 160 :=
  replacement_address original share threshold

/-! ## `identity_preserved` — ShareWriter frame preserves module
    identity when slots are separate. -/

theorem identity_preserved_restated
    (l : Layout) (s : Storage) (input : ShareWriter.Input) (i : Nat)
    (separate : idSlot l i ≠ moduleSlot l input.moduleId) :
    (readModule l (ShareWriter.execute l s input).storage i).identity =
      (readModule l s i).identity :=
  identity_preserved l s input i separate

end LidoSRv3.Tests.SourceTrioAlloc1WriterInvariantKillLines
