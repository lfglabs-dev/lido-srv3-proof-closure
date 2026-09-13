import LidoSRv3.Audit.Guarantees.PReserveRelational

/-!
Kill-lines pinning `Guarantees.PReserveRelational` two-plane
closure theorems (abstract + pinned-source) and the guarantee-plane
declaration.
-/

namespace LidoSRv3.Tests.GuaranteesPReserveRelationalKillLines

open LidoSRv3.Audit.Guarantees.PReserveRelational
open LidoSRv3.Audit.Guarantees
open LidoSRv3.Audit.ReserveRelational

/-! ## Guarantee-plane declaration. -/

theorem guarantee_id : guarantee.id = Id.pReserveRelational := rfl

theorem guarantee_checkedLayers :
    guarantee.checkedLayers =
      [CheckedLayer.model, CheckedLayer.source, CheckedLayer.verityTx] := rfl

/-! ## Abstract-plane closure. -/

theorem abstract_reserve_does_not_change_finalization_restated
    (inputs : Inputs) (left right : State)
    (h : differOnlyInReserve left right) :
    outcomeObservables (spec inputs left) =
      outcomeObservables (spec inputs right) :=
  abstract_reserve_does_not_change_finalization inputs left right h

/-! ## Pinned-source-plane closure. -/

theorem source_reserve_does_not_change_finalization_restated
    (inputs : Inputs) (left right : State)
    (h : differOnlyInReserve left right) :
    outcomeObservables (sourceRun inputs left) =
      outcomeObservables (sourceRun inputs right) :=
  source_reserve_does_not_change_finalization inputs left right h

end LidoSRv3.Tests.GuaranteesPReserveRelationalKillLines
