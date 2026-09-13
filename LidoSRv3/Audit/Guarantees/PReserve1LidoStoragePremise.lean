import LidoSRv3.Audit.Source.ReserveCorrespondence
import LidoSRv3.Audit.Source.LidoStakingStateStorage
import LidoSRv3.Audit.Source.AragonACLSource

/-! # P-RESERVE-1 canDeposit/authorizedRouter naming scaffold

**General rule (Thomas 2026-09-12), applied to RESERVE-1 booleans
`canDeposit` / `authorizedRouter`.**

The `WithdrawInputs` structure at
`LidoSRv3/Audit/Source/ReserveCorrespondence.lean:197-199` carries
two free-boolean fields corresponding to two pinned Lido reads:

- `canDeposit : Bool` — the return of `Lido.canDeposit()` at
  `Lido.sol:815-816`:
  `return !STAKING_STATE_POSITION.getStorageStakeLimitStruct().isStakingPaused()
      && !_isBunkerActive()`.
- `authorizedRouter : Bool` — the return of the Aragon-ACL role
  check `hasPermission(msg.sender, address(this),
  STAKING_ROUTER_ROLE)`, reached from `Lido.sol:872`
  (`_auth(address(stakingRouter))` in `withdrawDepositableEther`).

**Status: naming scaffold, not a full composition.** The two
`*_derived_under_pinned_lido_shape` theorems are straight-line
projections of the structure's fields onto the two `WithdrawInputs`
booleans. A full derivation requires: (a) a live
`STAKING_STATE_POSITION.getStorageStakeLimitStruct().isStakingPaused()`
source model; (b) an `_isBunkerActive` source model; (c) the
Aragon-ACL `hasPermission(msg.sender, address(this),
STAKING_ROUTER_ROLE)` chain. None are tree-resident yet.

**The scaffold's composition value** is naming each pinned Lido/ACL
read explicitly and making the composition ENTRY POINT for the
future live-storage derivation obvious. Downstream P-RESERVE-1
consumers can supply a `PinnedLidoReserveCallShape` bundle once the
live source models are added.

Residual (in `fidelity.missing`): live Lido storage + Aragon-ACL
source models are the remaining follow-up. -/

namespace LidoSRv3.Audit.Guarantees.PReserve1LidoStoragePremise

open LidoSRv3.Audit.SolidityReserve

/-- Pinned Lido storage / Aragon-ACL premise on the two
`WithdrawInputs` booleans, naming each pinned source read. -/
structure PinnedLidoReserveCallShape (inputs : WithdrawInputs) : Prop where
  canDepositBecausePinned : inputs.canDeposit = true
  authorizedRouterBecausePinned : inputs.authorizedRouter = true

/-- Straight-line derivation of `inputs.canDeposit = true` from the
pinned Lido storage shape premise. **Scaffold only** — a future
live-storage source model would fill in per-conjunct fields
(`stakingNotPaused`, `bunkerNotActive`) and DERIVE
`canDepositBecausePinned` from them. -/
theorem canDeposit_derived_under_pinned_lido_shape
    {inputs : WithdrawInputs}
    (hPinned : PinnedLidoReserveCallShape inputs) :
    inputs.canDeposit = true :=
  hPinned.canDepositBecausePinned

/-- Straight-line derivation of `inputs.authorizedRouter = true`
from the pinned Aragon-ACL premise. **Scaffold only** — a future
Aragon-ACL source model would fill in the role-check field and
DERIVE `authorizedRouterBecausePinned` from it. -/
theorem authorizedRouter_derived_under_pinned_lido_shape
    {inputs : WithdrawInputs}
    (hPinned : PinnedLidoReserveCallShape inputs) :
    inputs.authorizedRouter = true :=
  hPinned.authorizedRouterBecausePinned

/-! ## Real-derivation composition (2026-09-13, first step)

The scaffold above still routes both booleans through
straight-line projections of `PinnedLidoReserveCallShape`. The
composition below takes a REAL Lido storage state (via
`LidoStakingStateStorage.LidoStakingState`) and derives
`inputs.canDeposit = true` from a source-level function
`canDepositFromStorage`, not from a caller-supplied constant.

The premise now names two separate booleans (`isStakingPaused`,
`isBunkerActive`) — each an EXPLICIT source read from a pinned
Solidity slot — instead of one anonymous `canDeposit` field. This
is a first step toward eliminating the free-boolean-in-parent
condition, though the two component booleans are still supplied
externally (their full derivation from live storage / packed word
decoding / bunker slot reads is the next follow-up). -/

/-- Real-derivation premise: the `inputs.canDeposit` field is
functionally determined by a source-level `LidoStakingState` via
the source-defined `canDepositFromStorage`. -/
structure CanDepositFromLidoState
    (inputs : WithdrawInputs)
    (state : LidoSRv3.Audit.Source.LidoStakingStateStorage.LidoStakingState) : Prop where
  canDepositMatchesSource :
    inputs.canDeposit =
      LidoSRv3.Audit.Source.LidoStakingStateStorage.canDepositFromStorage state

/-- Real-derivation composition: under the pinned storage premise
(`!isStakingPaused ∧ !isBunkerActive`) AND the state-linkage
premise `CanDepositFromLidoState`, the input's `canDeposit` boolean
is `true` — derived via the source-defined function
`canDepositFromStorage`, not caller-supplied. -/
theorem canDeposit_derived_from_lido_state
    {inputs : WithdrawInputs}
    {state : LidoSRv3.Audit.Source.LidoStakingStateStorage.LidoStakingState}
    (hLink : CanDepositFromLidoState inputs state)
    (hStakingNotPaused : state.isStakingPaused = false)
    (hBunkerNotActive : state.isBunkerActive = false) :
    inputs.canDeposit = true := by
  rw [hLink.canDepositMatchesSource]
  exact LidoSRv3.Audit.Source.LidoStakingStateStorage.canDeposit_true_of_pinned_storage
    hStakingNotPaused hBunkerNotActive

/-! ## Second-step composition (2026-09-13): authorizedRouter via Aragon ACL

`PinnedLidoReserveCallShape.authorizedRouterBecausePinned` above
takes the router-authorization check as an input. Under the pinned
`Lido.sol:872` `_auth(address(stakingRouter))` chain, this delegates
to Aragon's ACL registry (see `AragonACLSource`). The composition
below derives `inputs.authorizedRouter` from a live ACL state via
the shared `AragonACLSource.isAuthorizedRouter` function. -/

/-- Linkage premise: `inputs.authorizedRouter` is functionally
determined by the Aragon-ACL state via `isAuthorizedRouter`. -/
structure AuthorizedRouterFromACL
    (inputs : WithdrawInputs)
    (acl : LidoSRv3.Audit.Source.AragonACLSource.ACLState) : Prop where
  authorizedRouterMatchesACL :
    inputs.authorizedRouter =
      LidoSRv3.Audit.Source.AragonACLSource.isAuthorizedRouter acl

/-- Second-step composition: under the ACL premise
(`STAKING_ROUTER_ROLE` granted) AND the linkage,
`inputs.authorizedRouter = true` — derived via the shared Aragon
ACL source model, not caller-supplied. -/
theorem authorizedRouter_derived_from_acl
    {inputs : WithdrawInputs}
    {acl : LidoSRv3.Audit.Source.AragonACLSource.ACLState}
    (hLink : AuthorizedRouterFromACL inputs acl)
    (hRole : acl.hasRole "STAKING_ROUTER_ROLE" = true) :
    inputs.authorizedRouter = true := by
  rw [hLink.authorizedRouterMatchesACL]
  exact LidoSRv3.Audit.Source.AragonACLSource.isAuthorizedRouter_true_of_role_granted hRole

end LidoSRv3.Audit.Guarantees.PReserve1LidoStoragePremise
