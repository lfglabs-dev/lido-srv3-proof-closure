import LidoSRv3.Audit.Source.Reserve1CompositeGateSource

/-! # Kill-lines for `Reserve1CompositeGateSource`

**Chantier 2 (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the composite canDeposit gate derivation.** -/

namespace LidoSRv3.Tests.Reserve1CompositeGateKillLines

open LidoSRv3.Audit.Source.Reserve1CompositeGateSource
open LidoSRv3.Audit.Source.AuthorizedRouterViaOracleSource
open LidoSRv3.Audit.Source.KeccakConcreteCommitmentSource
open LidoSRv3.Audit.Source.KeccakMappingStorageSource
open LidoSRv3.Audit.Source.StakeLimitStructDecoderSource
open LidoSRv3.Audit.Source.LidoBunkerViaOracleSource

/-- **Kill-line: canDepositFromOracleAndPacked is a three-way AND.**

Definitionally, `canDepositFromOracleAndPacked` is
`isAuthorizedRouterFromOracle ∧ !isStakingPausedFromStakeLimitStruct
∧ !isBunkerActiveFromOracle`.  A mutant that changed the composition
(dropped a guard) would fail this. -/
theorem canDepositFromOracleAndPacked_composition
    (oracle : KeccakOracle) (aclBase bunkerBase bunkerKey : Nat)
    (decoder : PackedSlotDecoder) :
    canDepositFromOracleAndPacked oracle aclBase bunkerBase bunkerKey decoder =
      (isAuthorizedRouterFromOracle oracle aclBase &&
        !isStakingPausedFromStakeLimitStruct
          decoder &&
        !isBunkerActiveFromOracle oracle bunkerBase bunkerKey) :=
  rfl

#print axioms canDepositFromOracleAndPacked_composition

end LidoSRv3.Tests.Reserve1CompositeGateKillLines
