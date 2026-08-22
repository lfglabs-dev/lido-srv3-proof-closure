# Pack W2-SCOPE brief — pause, VaultHub exclusion, P-DEREF pin

One node, one branch. No new guarantee IDs. Do not promote P-DEREF-1.
Three small unregistered children.

## Frozen interfaces used

`Spec.ApprovedDestination` from Wave 0 / G0 (`consolidationRequest` |
`refundRecipient` | `beaconDeposit` | `lidoPull`). Pinned-source pause
admission in `LidoSRv3.Audit.SolidityAddress`. Supplemental
`PDeref1.closure` on `AllGuarantees.supplemental`.

## Work

1. Unregistered child `request_or_unwrap_pause_balance_is_permissionless`:
   re-export of `SolidityAddress.pause_balance_admitted_is_permissionless`.
   `requestWithdrawals` / `unwrap` admission is pause plus caller
   balance/allowance flags. No fixed owner gate.
2. Unregistered child `approved_destination_cases`: inductive cases of
   `ApprovedDestination`. Four constructors, none named VaultHub.
   `no_vaulthub_ctor` records that VaultHub owner withdraw is not a Spec
   dest. Do not add constructors.
3. Unregistered child `deref_closure_exists_shape`: citation of
   `PDeref1.closure`. `deref_remains_supplemental` records that P-DEREF-1
   stays supplemental and is not promoted into the minimal-11 facade.

## Kill-lines

- Pause: eligible `requestWithdrawals` / `unwrap` inputs use
  `permissionlessAdmission` (positive).
- VaultHub: a complete match on `ApprovedDestination` has four arms;
  `decide` on that match. A fifth (VaultHub) constructor would fail it.
- Deref: re-export of
  `DereferenceMutants.packed_config_clobber_kill_line_refutes_parent`.

## Out of scope

New guarantee IDs. Promoting P-DEREF-1. Adding `ApprovedDestination`
constructors. Editing `Spec.lean`, `PAddress1.lean`, `PDeref1.lean`,
`LidoSRv3.lean`, `Trust.lean`, receipt, or yaml.
