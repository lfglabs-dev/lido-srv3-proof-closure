/-! # StakingRouter.topUp prefix-guard source model

**General rule (Thomas 2026-09-13, real derivation naming the pinned
StakingRouter.topUp:686-716 prefix guards
`NotAuthorized()` / `EmptyKeysList()` /
`WrongWithdrawalCredentialsType()` as source-level functions.)**

Chantier: grok differential #414 flags D-AUTH-1, D-WC-1, D-EMPTY-1
— the Verity plane `Verity.TopupTx.executeGuarded` starts at the
`allocateDeposits` call (line 717), so the source-line 686-716
prefix guards are not exercised on the executable plane.

This composition names each of the three prefix guards as a source-
level function of the pinned inputs:

- `callerIsTopupGateway` (D-AUTH-1): `caller = topupGatewayAddress`.
- `keysListNonEmpty` (D-EMPTY-1): `keyIndices.length ≠ 0`.
- `wcTypeIsType2` (D-WC-1): the withdrawal-credentials type byte is 2.

Pinned Solidity (17005714):

- `StakingRouter.sol:686`: `if (msg.sender != TOPUP_GATEWAY) revert NotAuthorized();`
- `StakingRouter.sol:695`: `if (keyIndices.length == 0) revert EmptyKeysList();`
- `StakingRouter.sol:702`: `if (wc[0] != WC_TYPE_2) revert WrongWithdrawalCredentialsType();`

**Status:** first real derivation naming the three D-* prefix-guard
divergences (grok #414) as source-level guards. -/

namespace LidoSRv3.Audit.Source.TopupPrefixGuardsSource

/-- Source-level definition of the pinned line-686 caller check. -/
def callerIsTopupGateway (caller topupGateway : Nat) : Bool :=
  decide (caller = topupGateway)

/-- Under the pinned caller premise, the caller-is-gateway guard
passes. -/
theorem callerIsTopupGateway_true_of_eq
    {caller topupGateway : Nat} (hEq : caller = topupGateway) :
    callerIsTopupGateway caller topupGateway = true := by
  simp [callerIsTopupGateway, hEq]

/-- Source-level definition of the pinned line-695 empty-keys check. -/
def keysListNonEmpty (keyIndices : List Nat) : Bool :=
  decide (keyIndices.length ≠ 0)

/-- Under the pinned non-empty premise, the keys-list guard passes. -/
theorem keysListNonEmpty_true_of_ne
    {keyIndices : List Nat} (hNonEmpty : keyIndices.length ≠ 0) :
    keysListNonEmpty keyIndices = true := by
  simp [keysListNonEmpty, hNonEmpty]

/-- Withdrawal-credentials type-2 byte constant. -/
def wcType2Byte : Nat := 2

/-- Source-level definition of the pinned line-702 WC-type check. -/
def wcTypeIsType2 (wcTypeByte : Nat) : Bool :=
  decide (wcTypeByte = wcType2Byte)

/-- Under the pinned WC-type premise, the wc-type-2 guard passes. -/
theorem wcTypeIsType2_true_of_eq_two
    {wcTypeByte : Nat} (hEq : wcTypeByte = wcType2Byte) :
    wcTypeIsType2 wcTypeByte = true := by
  simp [wcTypeIsType2, hEq]

/-- Composite prefix-guard: all three prefix checks pass together. -/
def allPrefixGuardsPass
    (caller topupGateway wcTypeByte : Nat) (keyIndices : List Nat) : Bool :=
  callerIsTopupGateway caller topupGateway
    && keysListNonEmpty keyIndices
    && wcTypeIsType2 wcTypeByte

/-- Under all three pinned premises, the composite prefix guard
passes. Real derivation. -/
theorem allPrefixGuardsPass_true_of_premises
    {caller topupGateway wcTypeByte : Nat} {keyIndices : List Nat}
    (hCaller : caller = topupGateway)
    (hKeys : keyIndices.length ≠ 0)
    (hWc : wcTypeByte = wcType2Byte) :
    allPrefixGuardsPass caller topupGateway wcTypeByte keyIndices = true := by
  simp [allPrefixGuardsPass,
        callerIsTopupGateway_true_of_eq hCaller,
        keysListNonEmpty_true_of_ne hKeys,
        wcTypeIsType2_true_of_eq_two hWc]

end LidoSRv3.Audit.Source.TopupPrefixGuardsSource
