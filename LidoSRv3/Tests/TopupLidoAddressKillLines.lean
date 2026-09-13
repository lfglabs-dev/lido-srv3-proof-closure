import LidoSRv3.Audit.Source.TopupLidoAddressSource

/-! # Kill-lines for `TopupLidoAddressSource`

**Chantier 1 (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the pinned StakingRouter LIDO immutable target-identity predicate
(grok #414 D-ADDR-1 disclosure).** -/

namespace LidoSRv3.Tests.TopupLidoAddressKillLines

open LidoSRv3.Audit.Source.TopupLidoAddressSource

/-- **Kill-line: `lidoAddressMatches` = decide (deploy.lidoAddress = target).**

A mutant that swapped fields or dropped the equality check would
refute this. -/
theorem lidoAddressMatches_composition
    (deploy : StakingRouterDeployment) (target : Nat) :
    lidoAddressMatches deploy target =
      decide (deploy.lidoAddress = target) :=
  rfl

/-- Deployment fixture at the pinned Lido proxy address (Mainnet). -/
def mainnetDeployment : StakingRouterDeployment :=
  { lidoAddress := 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84 }

/-- **Kill-line: matching mainnet target address gives true.** -/
theorem mainnet_matches :
    lidoAddressMatches mainnetDeployment
      0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84 = true :=
  lidoAddressMatches_true_of_eq rfl

/-- **Kill-line: a non-matching address gives false.** -/
theorem mainnet_no_match :
    lidoAddressMatches mainnetDeployment 0xDEADBEEF = false := by
  decide

/-- **Kill-line: `lidoAddressMatches` is symmetric in the equality
witness (rfl reflection).** -/
theorem lidoAddressMatches_self
    (deploy : StakingRouterDeployment) :
    lidoAddressMatches deploy deploy.lidoAddress = true :=
  lidoAddressMatches_true_of_eq rfl

#print axioms lidoAddressMatches_composition
#print axioms mainnet_matches
#print axioms mainnet_no_match
#print axioms lidoAddressMatches_self

end LidoSRv3.Tests.TopupLidoAddressKillLines
