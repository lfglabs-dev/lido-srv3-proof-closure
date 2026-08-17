import LidoSRv3.Audit.Source.ReserveRelationalCorrespondence

namespace LidoSRv3.Audit.Guarantees.PReserveRelational

open LidoSRv3.Audit.ReserveRelational

/-- First parent-closure slice: the independent abstract theorem. -/
theorem abstract_reserve_does_not_change_finalization
    (inputs : Inputs) (left right : State) (h : differOnlyInReserve left right) :
    outcomeObservables (spec inputs left) = outcomeObservables (spec inputs right) :=
  reserve_relational inputs left right h

/-- The separately defined pinned-source interpreter has the same property. -/
theorem source_reserve_does_not_change_finalization
    (inputs : Inputs) (left right : State) (h : differOnlyInReserve left right) :
    outcomeObservables (sourceRun inputs left) =
      outcomeObservables (sourceRun inputs right) :=
  source_reserve_relational inputs left right h

end LidoSRv3.Audit.Guarantees.PReserveRelational
