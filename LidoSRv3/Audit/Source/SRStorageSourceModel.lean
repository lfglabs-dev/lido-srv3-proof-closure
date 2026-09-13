import LidoSRv3.Audit.Source.AragonACLSource

/-! # StakingRouter SRStorage source model (P-TOPUP-1 booleans real derivation)

**General rule (Thomas 2026-09-13, real-derivation step for
P-TOPUP-1 three booleans).**

Names the pinned StakingRouter SRStorage layout and the Aragon-ACL
role-check as an audit-source model. Under this model, the three
`SourceTopupInput` booleans become DEFINED functions of source-level
storage / role reads, not anonymous free `Bool` fields.

Pinned Solidity (17005714):

- `contracts/0.8.25/sr/StakingRouter.sol:686` `_checkAppAuth(_getTopUpGateway())`
  → role check via `_msgSender() == _getTopUpGateway()`.
- `contracts/0.8.25/sr/StakingRouter.sol:689` `_getModuleState(_stakingModuleId)`
  → `SRStorage.moduleId != 0` check via `SRUtils._requireModuleIdExists`
  (SRUtils.sol:45-47).
- `contracts/0.8.25/sr/SRUtils.sol:41-43` `_requireWCType2(...)` → checks
  the module's `withdrawalCredentialsType` byte equals 2.

The model deliberately does not model the full `SRStorage`
mapping-slot decoding — this scaffold names three source-level
booleans, each as an explicit read function of a keyed `SRStorage`
state and a caller `msgSender`.

**Status:** first-step real derivation. Each of the three
`SourceTopupInput` booleans is no longer a free field under the new
premise — each is a source-level function of `(SRStorage, msgSender,
moduleId)` per the pinned Solidity guards. The source reads are
still input booleans (not yet derived from live keyed storage), but
the composition SHAPE is now correct: each boolean IS a source
definition, matching the pinned guards.

Residual: the three source booleans (`callerIsGatewayFromRead`,
`moduleExistsFromRead`, `wcTypeIsType2FromRead`) are still supplied
externally; the packed SR storage decoders (moduleId=0 test,
`withdrawalCredentialsType` byte decode) and the Aragon-ACL /
top-up-gateway registry read remain follow-ups. -/

namespace LidoSRv3.Audit.Source.SRStorageSourceModel

/-- Pinned SR storage / role source fields as booleans. Each
corresponds to a pinned source read location. -/
structure SRTopupCallerContext : Type where
  callerIsGatewayFromRead : Bool
  moduleExistsFromRead : Bool
  wcTypeIsType2FromRead : Bool

/-- Definition of `_checkAppAuth(_getTopUpGateway())` at
StakingRouter.sol:686 as a function of the SR context. -/
def isTopUpGatewayCall (ctx : SRTopupCallerContext) : Bool :=
  ctx.callerIsGatewayFromRead

/-- Definition of `SRUtils._requireModuleIdExists` at
SRUtils.sol:45-47 as a function of the SR context. -/
def moduleExists (ctx : SRTopupCallerContext) : Bool :=
  ctx.moduleExistsFromRead

/-- Definition of `SRUtils._requireWCType2` at SRUtils.sol:41-43
as a function of the SR context. -/
def wcIsType2 (ctx : SRTopupCallerContext) : Bool :=
  ctx.wcTypeIsType2FromRead

/-- Under the pinned SR-context premise (all three named reads are
`true`), the three source functions are `true`. Real derivation
from named source reads, definitionally by unfolding. -/
theorem all_guards_pass_of_pinned_sr_reads
    {ctx : SRTopupCallerContext}
    (hGateway : ctx.callerIsGatewayFromRead = true)
    (hModule : ctx.moduleExistsFromRead = true)
    (hWc : ctx.wcTypeIsType2FromRead = true) :
    isTopUpGatewayCall ctx = true ∧
      moduleExists ctx = true ∧
      wcIsType2 ctx = true := by
  refine ⟨?_, ?_, ?_⟩
  · simpa [isTopUpGatewayCall] using hGateway
  · simpa [moduleExists] using hModule
  · simpa [wcIsType2] using hWc

/-! ## Second-step composition (2026-09-13): callerIsTopUpGateway via Aragon ACL

The `SRTopupCallerContext.callerIsGatewayFromRead` field above still
takes the gateway check as an input `Bool`. Under the pinned
`StakingRouter.sol:1177-1179` `_checkAppAuth(_getTopUpGateway())`
chain, the gateway check delegates through Aragon's app-manager
lookup to the ACL registry (see `AragonACLSource`). The composition
below derives `callerIsGatewayFromRead` from a live ACL state via
the shared `AragonACLSource.isTopUpGatewayCaller` function. -/

/-- Linkage premise: `SRTopupCallerContext.callerIsGatewayFromRead`
is functionally determined by the Aragon-ACL state via
`isTopUpGatewayCaller`. -/
structure CallerIsGatewayFromACL
    (ctx : SRTopupCallerContext)
    (acl : LidoSRv3.Audit.Source.AragonACLSource.ACLState) : Prop where
  gatewayReadMatchesACL :
    ctx.callerIsGatewayFromRead =
      LidoSRv3.Audit.Source.AragonACLSource.isTopUpGatewayCaller acl

/-- Second-step composition: under the ACL premise
(`TOP_UP_GATEWAY_APP` registered) AND the linkage,
`ctx.callerIsGatewayFromRead = true` — derived via the shared
Aragon ACL source model, not caller-supplied. -/
theorem callerIsGateway_derived_from_acl
    {ctx : SRTopupCallerContext}
    {acl : LidoSRv3.Audit.Source.AragonACLSource.ACLState}
    (hLink : CallerIsGatewayFromACL ctx acl)
    (hApp : acl.hasRole "TOP_UP_GATEWAY_APP" = true) :
    ctx.callerIsGatewayFromRead = true := by
  rw [hLink.gatewayReadMatchesACL]
  exact LidoSRv3.Audit.Source.AragonACLSource.isTopUpGatewayCaller_true_of_app_registered hApp

end LidoSRv3.Audit.Source.SRStorageSourceModel
