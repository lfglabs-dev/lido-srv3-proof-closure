import LidoSRv3.Audit.Source.ReserveCorrespondence

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

end LidoSRv3.Audit.Guarantees.PReserve1LidoStoragePremise
