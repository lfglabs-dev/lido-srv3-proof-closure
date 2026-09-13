import LidoSRv3.Audit.Source.TopupPointerOrigin

namespace LidoSRv3.Tests.TopupPointerOriginAllocPrimitivesKillLines

open LidoSRv3.Audit.Source.TopupPointerOrigin
open LidoSRv3.Audit.Source.TrioReserve1 Live

/-- Pin `disjoint_comm`: interval non-aliasing is symmetric. -/
theorem disjoint_comm_restated (a b : AllocatedZone) :
    Disjoint a b ↔ Disjoint b a :=
  disjoint_comm a b

/-- Pin `sequential_disjoint`: chained allocations (b.origin = a.next) do
not alias. This captures the `TopUpGateway.sol:185` IR512-538 pointer
chaining shape. -/
theorem sequential_disjoint_restated (a b : AllocatedZone) (h : b.origin = a.next) :
    Disjoint a b :=
  sequential_disjoint a b h

end LidoSRv3.Tests.TopupPointerOriginAllocPrimitivesKillLines
