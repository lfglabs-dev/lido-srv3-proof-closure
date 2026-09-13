import LidoSRv3.Audit.Source.AuthorizedRouterViaOracleSource
import LidoSRv3.Audit.Source.LidoBunkerViaOracleSource

/-!
Kill-lines pinning `AuthorizedRouterViaOracleSource` +
`LidoBunkerViaOracleSource` oracle-backed derivations: the role-name
constant, the definition-unfold identities, and the theorem
restatements.
-/

namespace LidoSRv3.Tests.SourceOracleDerivationsKillLines

open LidoSRv3.Audit.Source.AuthorizedRouterViaOracleSource
open LidoSRv3.Audit.Source.LidoBunkerViaOracleSource
open LidoSRv3.Audit.Source.KeccakConcreteCommitmentSource
open LidoSRv3.Audit.Source.ACLRoleMappingViaOracleSource
open LidoSRv3.Audit.Source.MappingSlotViaOracleSource

/-! ## `stakingRouterRoleName` pinned string constant. -/

theorem stakingRouterRoleName_val :
    stakingRouterRoleName = "STAKING_ROUTER_ROLE" := rfl

/-! ## `isAuthorizedRouterFromOracle` unfolds to `hasRoleFromOracle`. -/

theorem isAuthorizedRouterFromOracle_reduces
    (oracle : KeccakOracle) (aclBaseSlot : Nat) :
    isAuthorizedRouterFromOracle oracle aclBaseSlot =
      hasRoleFromOracle oracle aclBaseSlot stakingRouterRoleName := rfl

/-! ## `isAuthorizedRouterFromOracle_true_of_nonzero` restated. -/

theorem isAuthorizedRouterFromOracle_true_of_nonzero_restated
    {oracle : KeccakOracle}
    {aclBaseSlot : Nat}
    (hNonzero : (realMappingStorage oracle aclBaseSlot).slotAt
                  (LidoSRv3.Audit.Source.AragonACLSource.roleKeyEncoding
                     stakingRouterRoleName) ≠ 0) :
    isAuthorizedRouterFromOracle oracle aclBaseSlot = true :=
  isAuthorizedRouterFromOracle_true_of_nonzero hNonzero

/-! ## `isBunkerActiveFromOracle` unfolds to `isBunkerActiveFromStorage`
    of the shared oracle-backed mapping. -/

theorem isBunkerActiveFromOracle_reduces
    (oracle : KeccakOracle) (bunkerBaseSlot bunkerSlotKey : Nat) :
    isBunkerActiveFromOracle oracle bunkerBaseSlot bunkerSlotKey =
      LidoSRv3.Audit.Source.LidoStakingStateStorage.isBunkerActiveFromStorage
        (realMappingStorage oracle bunkerBaseSlot) bunkerSlotKey := rfl

/-! ## `isBunkerActiveFromOracle_false_of_zero` restated. -/

theorem isBunkerActiveFromOracle_false_of_zero_restated
    {oracle : KeccakOracle}
    {bunkerBaseSlot bunkerSlotKey : Nat}
    (hSlot : (realMappingStorage oracle bunkerBaseSlot).slotAt bunkerSlotKey = 0) :
    isBunkerActiveFromOracle oracle bunkerBaseSlot bunkerSlotKey = false :=
  isBunkerActiveFromOracle_false_of_zero hSlot

end LidoSRv3.Tests.SourceOracleDerivationsKillLines
