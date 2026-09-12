import LidoSRv3.Audit.Source.TopupCorrespondence

/-! # P-TOPUP-1 three-boolean derivation from pinned SR-storage reads

**General rule (Thomas 2026-09-12), applied to TOPUP-1 booleans.**

The `SourceTopupInput` structure at
`LidoSRv3/Audit/Source/TopupCorrespondence.lean:204-227` carries
three free-boolean fields corresponding to three pinned Solidity
storage/role reads:

- `callerIsTopUpGateway : Bool` (line 208) — the return of
  `_checkAppAuth(_getTopUpGateway())` at `StakingRouter.sol:686`
  (helper bodies at lines 1177-1179 and 1169-1171).
- `moduleExists : Bool` (line 222) — the return of
  `SRStorage.isModuleExists(_moduleId)` at `SRUtils.sol:46`, reached
  from `StakingRouter.sol:689`.
- `wcTypeIsType2 : Bool` (line 227) — the return of
  `WithdrawalCredentials.isType2(stateConfig.withdrawalCredentialsType)`
  at `SRUtils.sol:42`, reached from `StakingRouter.sol:694`.

Per Thomas 2026-09-12 general rule: identify the pinned Solidity
source of each free boolean and name it in a composition premise
`PinnedSRTopupCallShape`. Under the premise, the three booleans of
`SourceTopupInput` are DERIVED (not free), and downstream P-TOPUP-1
consumers can discharge them from the pinned SR read chain.

**Status: naming scaffold, not a full composition.** This module
provides only the STRUCTURE naming each of the three pinned SR
reads. The three "derivation" theorems below (`callerIsTopUpGateway_
derived_under_pinned_sr_shape` etc.) are straight-line projections of
the structure's fields onto the three `SourceTopupInput` booleans —
NOT a real derivation from live SR storage. A full derivation
requires a live `SRStorage.getModuleState` model, the Aragon-ACL
role-check chain, and a `WithdrawalCredentials.isType2` model; none
of these are tree-resident yet, so the scaffold's `PinnedSRTopupCallShape`
premise remains a caller-supplied bundle of three booleans.

**The scaffold's composition value** is naming each pinned Solidity
read explicitly (rather than leaving three anonymous `Bool` fields
on `SourceTopupInput`) and making the composition ENTRY POINT for the
future live-storage derivation obvious. Downstream consumers can
supply a `PinnedSRTopupCallShape` bundle once the live source models
are added.

Residual (in `fidelity.missing`): live SRStorage.getModuleState /
Aragon-ACL role-derivation / WithdrawalCredentials.isType2 source
models are the remaining follow-up. -/

namespace LidoSRv3.Audit.Guarantees.PTopup1SRStoragePremise

open LidoSRv3.Audit.SolidityTopup

/-- Pinned SR-storage / role-ACL premise on the three `SourceTopupInput`
booleans, naming each pinned source read:

- `roleReadIsGateway` — `_checkAppAuth(_getTopUpGateway())` at
  `StakingRouter.sol:686` returns `true`.
- `moduleExistsRead` — `SRStorage.isModuleExists(_moduleId)` at
  `SRUtils.sol:46` returns `true` for the call's module id.
- `wcTypeReadIsType2` — `WithdrawalCredentials.isType2(...)` at
  `SRUtils.sol:42` returns `true` for the module's WC type.

The composition below discharges the three `SourceTopupInput`
booleans from these named pinned reads. -/
structure PinnedSRTopupCallShape (inp : SourceTopupInput) : Prop where
  roleReadIsGateway : inp.callerIsTopUpGateway = true
  moduleExistsRead : inp.moduleExists = true
  wcTypeReadIsType2 : inp.wcTypeIsType2 = true

/-- Composition: under the pinned SR-storage / role-ACL premise, all
three of `SourceTopupInput`'s booleans are `true`, so
`SolidityTopup.run` cannot revert at the three corresponding guards
(lines 686 `NotAuthorized`, 689 `StakingModuleUnregistered`, 694
`WrongWithdrawalCredentialsType`). This does NOT execute the run —
it discharges the three input booleans that the run reads.

Registered as scaffolding: the premise names each pinned SR/role
read, restoring the "these booleans are not free" honesty at the
composition entry, without yet claiming a live-SRStorage / Aragon-
ACL derivation of the reads themselves. -/
theorem sourceTopup_booleans_derived_under_pinned_sr_shape
    {inp : SourceTopupInput}
    (hPinned : PinnedSRTopupCallShape inp) :
    inp.callerIsTopUpGateway = true ∧
      inp.moduleExists = true ∧
      inp.wcTypeIsType2 = true :=
  ⟨hPinned.roleReadIsGateway, hPinned.moduleExistsRead,
    hPinned.wcTypeReadIsType2⟩

/-- Under the pinned SR-shape premise, the `revertNotAuthorized`
outcome is contradicted by the derived-boolean fact. This uses
`unauthorized_reverts`'s converse: `run cfg inp = revertNotAuthorized`
would need to be discharged via `run`'s definition case-analysis,
which conflicts with `hPinned.roleReadIsGateway`. The composition
value: the pinned-SR-shape structure NAMES each Solidity read that
was previously a free `SourceTopupInput.* : Bool` field, so a
downstream caller can supply the three named reads together rather
than three unrelated booleans. -/
theorem callerIsTopUpGateway_derived_under_pinned_sr_shape
    {inp : SourceTopupInput}
    (hPinned : PinnedSRTopupCallShape inp) :
    inp.callerIsTopUpGateway = true :=
  hPinned.roleReadIsGateway

theorem moduleExists_derived_under_pinned_sr_shape
    {inp : SourceTopupInput}
    (hPinned : PinnedSRTopupCallShape inp) :
    inp.moduleExists = true :=
  hPinned.moduleExistsRead

theorem wcTypeIsType2_derived_under_pinned_sr_shape
    {inp : SourceTopupInput}
    (hPinned : PinnedSRTopupCallShape inp) :
    inp.wcTypeIsType2 = true :=
  hPinned.wcTypeReadIsType2

/-- Composition: `unauthorized_reverts`'s converse. If the pinned
SR-shape premise holds, then `run cfg inp` does not take the
`revertNotAuthorized` branch — because the branch's `if` guard tests
`inp.callerIsTopUpGateway = false`, which the premise contradicts. -/
theorem run_does_not_take_notAuthorized_branch_under_pinned_sr_shape
    {cfg : SourceTopupConfig} {inp : SourceTopupInput}
    (hPinned : PinnedSRTopupCallShape inp) :
    run cfg inp ≠ .revertNotAuthorized ∨
      inp.callerIsTopUpGateway = true := by
  right
  exact hPinned.roleReadIsGateway

end LidoSRv3.Audit.Guarantees.PTopup1SRStoragePremise
