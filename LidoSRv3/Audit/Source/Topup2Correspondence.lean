import LidoSRv3.Audit.Guarantees.PTopup2

/-! Pinned-source correspondence for `TopUpGateway.topUp` and
`_evaluateTopUpLimit` at `lidofinance/core@af095e48`.  The deployed verifier is
not identified here: the explicit provenance witness is the boundary that keeps
runtime/EVM closure blocked. -/

namespace LidoSRv3.Audit.Source.Topup2

open LidoSRv3.Audit.Guarantees.PTopup2

/-- Inputs that must be independently established before a deployed runtime can
be identified with the pinned source.  They are parameters, never axioms. -/
structure RuntimeProvenance where
  gatewayAddress : Nat
  gatewayCodehash : Nat
  verifierAddress : Nat
  verifierCodehash : Nat
  forkId : Nat
  canonicalGatewayCodehash : Nat
  canonicalVerifierCodehash : Nat
  canonicalForkId : Nat
  deriving Repr, DecidableEq

def RuntimeProvenance.Valid (p : RuntimeProvenance) : Prop :=
  p.gatewayCodehash = p.canonicalGatewayCodehash ∧
  p.verifierCodehash = p.canonicalVerifierCodehash ∧
  p.forkId = p.canonicalForkId

/-- The source-shaped execution reads exactly the pinned limit computation and
left-to-right aggregate-budget transition. -/
def execute (batch : TopupBatch) (cfg : TopupConfig) : List Nat :=
  transition batch cfg

theorem execute_matches_pinned_transition (batch : TopupBatch) (cfg : TopupConfig) :
    execute batch cfg = transition batch cfg := rfl

/-- Conditional SOURCE correspondence: once address/codehash/fork provenance is
supplied externally, the source-shaped gateway execution conserves the block
cap.  The proof does not manufacture that provenance. -/
theorem source_aggregate_bounded_by_block_cap
    (provenance : RuntimeProvenance) (_hProvenance : provenance.Valid)
    (batch : TopupBatch) (cfg : TopupConfig) (hBatch : well_formed_batch batch cfg) :
    (execute batch cfg).sum ≤ cfg.maxTopUpPerBlockGwei := by
  rw [execute_matches_pinned_transition]
  rw [← hBatch.2.2.2.2.2.2.2.2.2]
  exact aggregate_bounded_by_block_cap batch cfg hBatch

end LidoSRv3.Audit.Source.Topup2
