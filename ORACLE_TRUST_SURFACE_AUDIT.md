# PR #1811: oracle trust-surface finding

- Status: open
- Severity: **High under a corrupt HashConsensus quorum**
- Reviewed commit: `f19aab6d6b3857fa2b9a8a04edd6daf8fe867341`

## Answer

PR #1811 changes the numerator of module reward weights from router-maintained
validator counts to oracle-reported balances.

V2 derived each module's weight from validator counts recorded by the
`StakingRouter`. PR #1811 instead uses balances reported by the
oracle committee. A corrupt quorum can therefore redistribute reward weight
between modules while keeping Lido's total reported CL balance correct.

At the pinned mainnet block, HashConsensus required 5 of 9 members.

~~~text
Honest balances:  [80, 15, 5]   total = 100
False balances:   [ 0, 100, 0]  total = 100
~~~

Global CL checks see the same total. The false partition can still reach the
reward calculation.

This authority affects protocol-fee recipients and module
`onRewardsMinted` callbacks. It does not directly let the quorum
steal staker principal, choose arbitrary recipients, or control deposits and
exits.

## Cases and recommendations

At block `25,567,397`, the reported global validator balance `C` was
`8,500,321.556178167 ETH`.

- **Case - committee-reported weights:** the quorum supplies the balance vector
  used for rewards. Global checks cannot detect a false partition with the same
  total `C`. **Recommendation:** `ModuleBalanceVerifier` must accept an
  aggregate CL validity proof before a new vector can replace reward weights.
- **Case - first migration report:** the checker verifies only that module
  balances sum to `C`, so one module can receive all reward weight.
  **Recommendation:** use a proof-gated migration that sets the completion flag
  only after `ModuleBalanceVerifier` accepts the migrated vector.
- **Case - zero-state module:** a module with zero stored balance and zero exits
  can be assigned all of `C`. Reporting it back to zero reopens the bypass.
  **Recommendation:** store `balanceInitialized[moduleId]`, set it only after a
  proved initial balance, and never clear it when the balance returns to zero.
- **Case - normal report:** with no activations, the accepted positive movement
  is `95,703.855220870730684931 ETH/day`, or `1.125885116090%` of `C`.
  `93,375 ETH/day`, about 97.6%, comes from an allowance not tied to a real
  consolidation. **Recommendation:** use a `ConsolidationLedger` that records
  the authorized source, target and amount, then releases that exact allowance
  only after proof of CL completion.

## Economic impact

All configured modules had the same 10% module-plus-treasury fee total at the
snapshot. A false vector therefore changes who receives the fee while leaving
the total protocol fee almost unchanged. Global rebase monitoring is unlikely
to catch the redistribution.

Example: assigning all balance to SimpleDVT changes its share of report rewards
from:

~~~text
0.139833248850745486% -> 8%
~~~

That is an increase of `78.601667511492545140 ETH` per
`1,000 ETH` of report rewards, before the final integer share floors.
The treasury receives the remaining 2%.

## Why it happens

The relevant path is:

~~~text
HashConsensus report
  -> module-balance sanity check
  -> balances stored in StakingRouter
  -> balances used as reward weights
  -> fee shares minted and module callbacks called
~~~

Code anchors:

- [module-balance checks](https://github.com/lidofinance/core/blob/f19aab6d6b3857fa2b9a8a04edd6daf8fe867341/contracts/0.8.9/sanity_checks/OracleReportSanityChecker.sol#L912-L1068)
- [reported balances stored](https://github.com/lidofinance/core/blob/f19aab6d6b3857fa2b9a8a04edd6daf8fe867341/contracts/0.8.25/sr/SRLib.sol#L853-L892)
- [stored balances used for rewards](https://github.com/lidofinance/core/blob/f19aab6d6b3857fa2b9a8a04edd6daf8fe867341/contracts/0.8.25/sr/StakingRouter.sol#L808-L894)
- [fee shares distributed](https://github.com/lidofinance/core/blob/f19aab6d6b3857fa2b9a8a04edd6daf8fe867341/contracts/0.8.9/Accounting.sol#L265-L357)

## Shared CL proof mechanism

Lido does not need to change the Consensus Layer. The CL already commits its
state in SSZ trees, and [EIP-4788](https://eips.ethereum.org/EIPS/eip-4788)
exposes recent beacon block roots to contracts on the Execution Layer.

~~~text
standard BeaconState
  -> EIP-4788 beacon root
  -> off-chain aggregate validity proof
  -> Lido on-chain verifier
  -> StakingRouter reward weights
~~~

Lido must maintain a complete validator-to-module registry. The prover reads
the standard
[`BeaconState.validators` and `BeaconState.balances`](https://ethereum.github.io/consensus-specs/phase0/beacon-chain/#beaconstate)
lists and proves that every registry entry was processed exactly once. It then
outputs the ordered module sums and their global sum. A small root-cache
contract preserves the reference root if proof generation exceeds EIP-4788's
history window.

Ordinary Merkle membership proofs are insufficient: they cannot prove the sum
or detect an omitted, duplicated or wrongly assigned validator. The existing
`CLValidatorVerifier` is also insufficient by itself because it proves
`effective_balance`, not the live value in `BeaconState.balances`.

The aggregate prover should be benchmarked at Lido's validator count. Until it
meets the reporting deadline, unproved balance vectors must not change reward
weights.

## Minimum acceptance tests

- A proof for an unknown or expired uncached CL root is rejected.
- A wrong balance or module assignment invalidates the proof.
- Omitting or processing a registry entry twice invalidates the proof.
- The proved module sums must equal both the reported vector and global CL sum.
- The migration flag cannot be set before its balance vector is proved.
- Returning a module balance to zero does not clear its initialization state.
- Consolidation allowance cannot be created without a Lido-authorized record or
  consumed without a matching CL completion proof.
- Without a valid proof, `[0, C, 0, ...]` cannot replace reward weights.
- Module callbacks receive shares derived only from verified weights.

## Scope

The measurements above use this pinned snapshot:

~~~text
PR base:          eb4ff801ddbaa728397bc249ba6884500024d490
reviewed head:    f19aab6d6b3857fa2b9a8a04edd6daf8fe867341
mainnet block:    25,567,397
timestamp:        2026-07-19T14:37:11Z
members / quorum: 9 / 5
~~~

The formal proof package treats oracle truthfulness as assumption
`A-ORC-03`. It proves that an accepted vector is stored and consumed
consistently, not that the module attribution is true. This finding measures
the authority hidden behind that assumption.
