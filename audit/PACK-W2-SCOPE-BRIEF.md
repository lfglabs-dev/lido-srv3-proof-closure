# Pack W2-SCOPE brief — pause, VaultHub exclusion

One node, one branch. No new guarantee IDs.
Two small unregistered children.

## Frozen interfaces used

`Spec.ApprovedDestination` from Wave 0 / G0 (`consolidationRequest` |
`refundRecipient` | `beaconDeposit` | `lidoPull`). Pinned-source pause
admission in `LidoSRv3.Audit.SolidityAddress`.

## Work

1. Unregistered child `request_or_unwrap_pause_balance_is_permissionless`:
   re-export of `SolidityAddress.pause_balance_admitted_is_permissionless`.
   `requestWithdrawals` / `unwrap` admission is pause plus caller
   balance/allowance flags. No fixed owner gate.
2. Unregistered child `approved_destination_cases`: inductive cases of
   `ApprovedDestination`. Four constructors, none named VaultHub.
   `no_vaulthub_ctor` records that VaultHub owner withdraw is not a Spec
   dest. Do not add constructors.

## Kill-lines

- Pause: eligible `requestWithdrawals` / `unwrap` inputs use
  `permissionlessAdmission` (positive).
- VaultHub: a complete match on `ApprovedDestination` has four arms;
  `decide` on that match. A fifth (VaultHub) constructor would fail it.

## Out of scope

New guarantee IDs. Adding `ApprovedDestination`
constructors. Editing `Spec.lean`, `PAddress1.lean`,
`LidoSRv3.lean`, `Trust.lean`, receipt, or yaml.
