import LidoSRv3.Audit.Source.Reserve1CompositeGateSource

/-!
Kill-lines pinning `Source.Reserve1CompositeGateSource` composite
canDeposit derivation. Pins the three-conjunct decomposition (staking
router role + not paused + not bunker) and the kernel-checked
witness theorem.
-/

namespace LidoSRv3.Tests.SourceReserve1CompositeGateKillLines

open LidoSRv3.Audit.Source.Reserve1CompositeGateSource
open LidoSRv3.Audit.Source.AuthorizedRouterViaOracleSource
open LidoSRv3.Audit.Source.LidoBunkerViaOracleSource
open LidoSRv3.Audit.Source.StakeLimitStructDecoderSource
open LidoSRv3.Audit.Source.KeccakMappingStorageSource

/-! ## `canDepositFromOracleAndPacked` — three-conjunct composition. -/

theorem canDepositFromOracleAndPacked_restated
    (oracle : LidoSRv3.Audit.Source.KeccakConcreteCommitmentSource.KeccakOracle)
    (aclBaseSlot bunkerBaseSlot bunkerSlotKey : Nat)
    (stakeLimitDecoder : PackedSlotDecoder) :
    canDepositFromOracleAndPacked oracle aclBaseSlot bunkerBaseSlot
        bunkerSlotKey stakeLimitDecoder =
      (isAuthorizedRouterFromOracle oracle aclBaseSlot &&
        !isStakingPausedFromStakeLimitStruct stakeLimitDecoder &&
        !isBunkerActiveFromOracle oracle bunkerBaseSlot bunkerSlotKey) := rfl

/-! ## Wave witness — all three premises hold, composite is true. -/

theorem canDepositFromOracleAndPacked_true_of_all_premises_restated
    {oracle : LidoSRv3.Audit.Source.KeccakConcreteCommitmentSource.KeccakOracle}
    {aclBaseSlot bunkerBaseSlot bunkerSlotKey : Nat}
    {stakeLimitDecoder : PackedSlotDecoder}
    (hRole : isAuthorizedRouterFromOracle oracle aclBaseSlot = true)
    (hNotPaused : isStakingPausedFromStakeLimitStruct stakeLimitDecoder = false)
    (hNotBunker : isBunkerActiveFromOracle oracle bunkerBaseSlot
                    bunkerSlotKey = false) :
    canDepositFromOracleAndPacked oracle aclBaseSlot bunkerBaseSlot
      bunkerSlotKey stakeLimitDecoder = true :=
  canDepositFromOracleAndPacked_true_of_all_premises hRole hNotPaused hNotBunker

/-! ## Each premise is load-bearing: negating any one drives the
    composite to false (kill-line negation witnesses). -/

theorem canDepositFromOracleAndPacked_false_if_role_false
    {oracle : LidoSRv3.Audit.Source.KeccakConcreteCommitmentSource.KeccakOracle}
    {aclBaseSlot bunkerBaseSlot bunkerSlotKey : Nat}
    {stakeLimitDecoder : PackedSlotDecoder}
    (hRoleFalse : isAuthorizedRouterFromOracle oracle aclBaseSlot = false) :
    canDepositFromOracleAndPacked oracle aclBaseSlot bunkerBaseSlot
      bunkerSlotKey stakeLimitDecoder = false := by
  simp [canDepositFromOracleAndPacked, hRoleFalse]

theorem canDepositFromOracleAndPacked_false_if_paused
    {oracle : LidoSRv3.Audit.Source.KeccakConcreteCommitmentSource.KeccakOracle}
    {aclBaseSlot bunkerBaseSlot bunkerSlotKey : Nat}
    {stakeLimitDecoder : PackedSlotDecoder}
    (hPaused : isStakingPausedFromStakeLimitStruct stakeLimitDecoder = true) :
    canDepositFromOracleAndPacked oracle aclBaseSlot bunkerBaseSlot
      bunkerSlotKey stakeLimitDecoder = false := by
  simp [canDepositFromOracleAndPacked, hPaused]

theorem canDepositFromOracleAndPacked_false_if_bunker
    {oracle : LidoSRv3.Audit.Source.KeccakConcreteCommitmentSource.KeccakOracle}
    {aclBaseSlot bunkerBaseSlot bunkerSlotKey : Nat}
    {stakeLimitDecoder : PackedSlotDecoder}
    (hBunker : isBunkerActiveFromOracle oracle bunkerBaseSlot
                bunkerSlotKey = true) :
    canDepositFromOracleAndPacked oracle aclBaseSlot bunkerBaseSlot
      bunkerSlotKey stakeLimitDecoder = false := by
  simp [canDepositFromOracleAndPacked, hBunker]

end LidoSRv3.Tests.SourceReserve1CompositeGateKillLines
