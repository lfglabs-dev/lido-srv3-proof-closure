import LidoSRv3.Audit.Source.AuthorizedRouterViaOracleSource
import LidoSRv3.Audit.Source.LidoBunkerViaOracleSource
import LidoSRv3.Audit.Source.StakeLimitStructDecoderSource

/-! # P-RESERVE-1 composite entry-gate source model

**General rule (Thomas 2026-09-13): compose the three P-RESERVE-1
general-rule (a)/(b)/(c) source models (authorizedRouter via
STAKING_ROUTER_ROLE + isStakingPaused via packed StakeLimitStruct +
isBunkerActive via MappingStorage) into a single named composite.**

Under the pinned entry-gate premises (msg.sender has
STAKING_ROUTER_ROLE, staking is NOT paused, bunker is NOT active),
the composite `canDeposit` derivation returns true.

**Status:** first real composition of the three P-RESERVE-1
general-rule (a)/(b)/(c) source models. -/

namespace LidoSRv3.Audit.Source.Reserve1CompositeGateSource

open LidoSRv3.Audit.Source.KeccakConcreteCommitmentSource
open LidoSRv3.Audit.Source.KeccakMappingStorageSource
open LidoSRv3.Audit.Source.MappingSlotViaOracleSource
open LidoSRv3.Audit.Source.AuthorizedRouterViaOracleSource
open LidoSRv3.Audit.Source.LidoBunkerViaOracleSource
open LidoSRv3.Audit.Source.StakeLimitStructDecoderSource

/-- Composite P-RESERVE-1 canDeposit derivation: caller has
STAKING_ROUTER_ROLE, staking not paused, bunker not active. -/
def canDepositFromOracleAndPacked
    (oracle : KeccakOracle)
    (aclBaseSlot bunkerBaseSlot bunkerSlotKey : Nat)
    (stakeLimitDecoder : PackedSlotDecoder) : Bool :=
  isAuthorizedRouterFromOracle oracle aclBaseSlot
    && !isStakingPausedFromStakeLimitStruct stakeLimitDecoder
    && !isBunkerActiveFromOracle oracle bunkerBaseSlot bunkerSlotKey

/-- Under all three pinned premises, canDeposit is true. Real
derivation. -/
theorem canDepositFromOracleAndPacked_true_of_all_premises
    {oracle : KeccakOracle}
    {aclBaseSlot bunkerBaseSlot bunkerSlotKey : Nat}
    {stakeLimitDecoder : PackedSlotDecoder}
    (hRole : isAuthorizedRouterFromOracle oracle aclBaseSlot = true)
    (hNotPaused : isStakingPausedFromStakeLimitStruct stakeLimitDecoder
                    = false)
    (hNotBunker : isBunkerActiveFromOracle oracle bunkerBaseSlot
                    bunkerSlotKey = false) :
    canDepositFromOracleAndPacked oracle aclBaseSlot bunkerBaseSlot
      bunkerSlotKey stakeLimitDecoder = true := by
  simp [canDepositFromOracleAndPacked, hRole, hNotPaused, hNotBunker]

end LidoSRv3.Audit.Source.Reserve1CompositeGateSource
