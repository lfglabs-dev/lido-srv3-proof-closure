import LidoSRv3.Audit.Source.TrioReserve1.CalleeBalance

namespace LidoSRv3.Tests.TrioReserve1CalleeBalancePreservesKillLines

open LidoSRv3.Audit.Source.TrioReserve1.CalleeBalance
open LidoSRv3.Audit.Source.TrioReserve1 Live

/-- Pin `locator`: `Locator.dispatch` preserves the callee-balance
invariant under a preserving fallback. -/
theorem locator_restated (address : Address) (config : Locator.Config) (other : External)
    (h : Preserves other) : Preserves (Locator.dispatch address config other) :=
  locator address config other h

/-- Pin `queue`: `Queue.dispatch` preserves the callee-balance invariant
under a preserving fallback. -/
theorem queue_restated (k : Queue.Keccak) (address : Address) (other : External)
    (h : Preserves other) : Preserves (Queue.dispatch k address other) :=
  queue k address other h

/-- Pin `router`: `Router.dispatch` preserves the callee-balance
invariant under a preserving fallback. -/
theorem router_restated (address lido : Address) (other : External)
    (h : Preserves other) : Preserves (Router.dispatch address lido other) :=
  router address lido other h

/-- Pin `pipeline`: the composite `Pipeline.external` (locator ∘ queue ∘
oracle ∘ router) preserves the callee-balance invariant. -/
theorem pipeline_restated (k : Queue.Keccak) (config : Pipeline.Config)
    (staticOther : StaticCall.External) (other : External) (h : Preserves other) :
    Preserves (Pipeline.external k config staticOther other) :=
  pipeline k config staticOther other h

end LidoSRv3.Tests.TrioReserve1CalleeBalancePreservesKillLines
