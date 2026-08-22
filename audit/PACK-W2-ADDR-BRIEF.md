# Pack W2-ADDR brief — three-item live claim-batch correspondence

One node, one PR. Not Best-of-N. No new guarantee IDs. No global-pause
versus selective-block row. Pack D remains the two-item read→payout
naming.

## Frozen interfaces used

`AddressClaimBatchTx.executeClaimWithdrawalsTo`, `observe`,
`readRequest`, `claimableEther`, and `every_revert_restores_snapshot`.
`ContractState.mapUint` remains Verity's keyed mapping abstraction.

## Work

1. Unregistered child: a three-item witness packed like Pack D's
   `twoClaimState` (request 3 payout 10, locked ETH 80). Observe of
   `executeClaimWithdrawalsTo [1,2,3]` journals three payouts equal to
   pre-state `claimableEther` reads, all claimed, in loop order.
2. `length_mismatch_reverts`: `executeClaimWithdrawalsTo [1,2] [1]`
   reverts `ArraysLengthMismatch` and restores the snapshot.
3. Re-export `every_revert_restores_snapshot`. The transaction
   boundary is already universal; this node does not re-prove it.

This is a bounded three-item receipt. It does not claim unbounded
source equivariance or keccak/machine-storage slot derivation. Pack D
stays two-item. The four registered address writers are not called
permissionless.

## Kill-lines

- Swapped payout order `[40, 30, 10]` disagrees with the honest
  three-item observe journal `[30, 40, 10]`.

## Out of scope

Pause row, VaultHub, keccak slot derivation, unbounded list
equivariance, EnumerableSet/events, singleton-actor helpers,
permissionless admission of all four address writers.
