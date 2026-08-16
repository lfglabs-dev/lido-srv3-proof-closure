import LidoSRv3.Audit.Guarantees.PTopup2

/-! Source-shaped scaffold for `TopUpGateway.topUp` and `_evaluateTopUpLimit` at
`lidofinance/core@af095e48`.  This is not promoted SOURCE correspondence:
`evaluated_topup_limit` uses total `Nat` addition, while the pinned Solidity
checked `uint256` addition can revert on overflow.  A future correspondence
must add explicit word bounds and match that revert behavior. -/

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

/-- Conditional bound for the source-shaped scaffold.  This theorem does not
establish Solidity correspondence for overflowing effective-plus-pending
balances and therefore does not promote the SOURCE layer. -/
theorem source_aggregate_bounded_by_block_cap
    (provenance : RuntimeProvenance) (_hProvenance : provenance.Valid)
    (batch : TopupBatch) (cfg : TopupConfig) (hBatch : well_formed_batch batch cfg) :
    (execute batch cfg).sum ≤ cfg.maxTopUpPerBlockGwei := by
  rw [execute_matches_pinned_transition]
  rw [← hBatch.2.2.2.2.2.2.2.2.2]
  exact aggregate_bounded_by_block_cap batch cfg hBatch

end LidoSRv3.Audit.Source.Topup2
