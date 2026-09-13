import LidoSRv3.Audit.Source.TrioReserve1.CallData

namespace LidoSRv3.Tests.TrioReserve1CalldataSelectorKillLines

open LidoSRv3.Audit.Source.TrioReserve1.CallData
open LidoSRv3.Audit.Source.TrioReserve1 Live

/-- Pin `selector_call`: `CallData.invoke` on an ABI-encoded 4-byte
selector reduces to the shared `Live.call` primitive. This is the
argument-complete → selector-only bridge for high-level CALLs. -/
theorem selector_call_restated (external : External) (ctx : Context) (target : Address)
    (selector : Nat) (value : Word) :
    invoke external ctx target (encode 4 selector) value =
      Live.call external ctx target selector value :=
  selector_call external ctx target selector value

end LidoSRv3.Tests.TrioReserve1CalldataSelectorKillLines
