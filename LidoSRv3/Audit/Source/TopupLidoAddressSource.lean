/-! # StakingRouter LIDO address source model (topUp target-identity)

**General rule (Thomas 2026-09-13, real derivation naming the pinned
StakingRouter LIDO immutable as a source-level target-identity
predicate.)**

Chantier: grok differential #414 flags D-ADDR-1 — Verity
`TopupTx.lidoAddress` is a pure model placeholder `0xF00D` for the
pinned `LIDO` immutable at `StakingRouter.sol:744`, with no
deployment-identity binding. The grok harness deploys a fresh mock
at a different address; target equality between the model literal
and the deployed Lido proxy is not claimed.

This composition names an executable-plane `StakingRouterDeployment`
record that carries the deployed `LIDO` immutable address and
derives a source-level predicate `lidoAddressMatches deploy addr`
= `deploy.lidoAddress = addr`. Downstream consumers of a Verity
`TopupTx.lidoAddress` can now prove target-identity against the
deployed immutable, not a hard-coded literal.

Pinned Solidity (17005714):

- `StakingRouter.sol:744`: `LIDO.withdrawDepositableEther(...)`.
- `StakingRouter.sol` `LIDO` is an `immutable address` set in the
  constructor from the LidoLocator proxy.

**Status:** first real derivation naming the D-ADDR-1 divergence
(grok #414) as a source-level function of a deployed immutable. -/

namespace LidoSRv3.Audit.Source.TopupLidoAddressSource

/-- Executable-plane deployment record: the pinned StakingRouter
constructor-set `LIDO` immutable address. -/
structure StakingRouterDeployment : Type where
  lidoAddress : Nat

/-- Source-level definition of the pinned target-identity predicate:
the caller's target address equals the deployment's LIDO immutable. -/
def lidoAddressMatches
    (deploy : StakingRouterDeployment) (targetAddr : Nat) : Bool :=
  decide (deploy.lidoAddress = targetAddr)

/-- Under the pinned deployment-identity premise (`targetAddr` equals
the deployment's `LIDO` immutable), the target-identity predicate
holds. Real derivation. -/
theorem lidoAddressMatches_true_of_eq
    {deploy : StakingRouterDeployment} {targetAddr : Nat}
    (hEq : deploy.lidoAddress = targetAddr) :
    lidoAddressMatches deploy targetAddr = true := by
  simp [lidoAddressMatches, hEq]

end LidoSRv3.Audit.Source.TopupLidoAddressSource
