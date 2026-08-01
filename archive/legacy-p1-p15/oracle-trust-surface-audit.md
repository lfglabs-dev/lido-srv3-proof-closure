# PR #1811: oracle trust-surface note

> **Finding:** High if a HashConsensus quorum is corrupt
>
> **Reviewed commit:** `f19aab6d6b3857fa2b9a8a04edd6daf8fe867341`

## Finding

PR #1811 changes module reward weights from validator counts maintained by the
`StakingRouter` to balances reported by the oracle committee. A corrupt quorum
can keep Lido's global CL balance correct while assigning that balance to the
wrong modules.

At mainnet block `25,567,397`, HashConsensus required 5 of 9 members and the
reported global validator balance `C` was `8,500,321.556178167 ETH`.

~~~text
Honest balances:  [80, 15, 5]   total = 100
False balances:   [ 0, 100, 0]  total = 100
~~~

The false vector changes protocol-fee recipients and module
`onRewardsMinted` callbacks. It does not directly give the quorum access to
staker principal, arbitrary recipients, deposits, or exits.

## Cases and recommendations

### 1. First post-upgrade report

- **Case:** While `isPostMigrationFirstReportDone` is false, any complete,
  ordered, nonnegative gwei partition whose sum is `C` passes the module
  attribution check. The global report checks still apply, but they cannot
  detect a false partition with the correct total. An active module can
  therefore receive 100% of the balance weight.
- **Recommendation:** Before `AccountingOracle` stores or uses the vector,
  require an aggregate validity proof anchored to a finalized
  [EIP-4788](https://eips.ethereum.org/EIPS/eip-4788) root. Bind the proof to
  the current `refSlot`, `C`, ordered module IDs, and vector. It must sum every
  validator in Lido's complete registry exactly once, using its live CL balance
  and fixed module assignment. Store the vector and mark the first report done
  atomically after verification. Consume each proof once to prevent replay.

### 2. Recurrent zero-state skip

- **Case:** The limiter treats a module as initialized only when its stored
  balance is nonzero or its `exitedValidatorsCount` is nonzero. If both are
  zero, the module's positive delta is omitted; decreases from donor modules
  are also ignored. The bypass can recur after another accepted state leaves
  both fields at zero.
- **Recommendation:** Add a monotonic `balanceInitialized[moduleId]` flag. Set
  it atomically after the first proof-verified complete vector, including when
  the proved balance is zero. Use the flag instead of the balance/exits
  heuristic and never clear it. The aggregate proof remains the primary
  control; this flag is defense in depth for the delta limiter.

### 3. Normal report and consolidation corridor

- **Case:** With no activations, the internal one-day positive-delta limit is
  `95,703.855220870730684931 ETH`. Reports use whole gwei, so the largest
  reportable movement is `95,703.855220870 ETH`, approximately
  `1.125885116091%` of `C`. Of this, `93,375 ETH` is a blanket consolidation
  allowance that requires no evidence of a real consolidation.
- **Recommendation:** Replace the blanket allowance with replay-protected
  source-to-target consolidation credits. Create a credit only after an
  EIP-4788-anchored validity/transition proof binds a Lido-submitted pair to
  the processed CL transition and outputs the transferred gwei. Consume that
  exact credit once. A request record or ordinary Merkle membership proof is
  insufficient. The aggregate balance verifier closes the remaining APR
  corridor.

## Economic impact

At the snapshot, each module's module-plus-treasury fee totaled 10%. A false
vector therefore changes who receives the fee while leaving its total almost
unchanged, making global rebase monitoring unlikely to detect it.

Assigning all balance to SimpleDVT changes its share of total report rewards
from `0.139833248850745486%` to `8%`: an increase of
`78.601667511492545140 ETH` per `1,000 ETH` of report rewards, before integer
share floors. The treasury receives the remaining 2%.

## Proof boundary

Lido can implement these controls without changing the Consensus Layer. The
CL already commits `BeaconState.validators` and live `BeaconState.balances`,
and EIP-4788 exposes beacon roots to Execution Layer contracts.

Lido still needs a complete, append-only validator-to-module registry and an
aggregate prover. Ordinary membership proofs cannot prove the sum or detect an
omitted, duplicated, or wrongly assigned validator. The existing
`CLValidatorVerifier` proves `Validator.effective_balance`, not the live
`BeaconState.balances` value. The prover must be benchmarked at Lido's validator
count; unproved vectors must not replace reward weights.

## Source anchors

- [first-report and module-delta checks](https://github.com/lidofinance/core/blob/f19aab6d6b3857fa2b9a8a04edd6daf8fe867341/contracts/0.8.9/sanity_checks/OracleReportSanityChecker.sol#L719-L758)
- [zero-state heuristic and consolidation corridor](https://github.com/lidofinance/core/blob/f19aab6d6b3857fa2b9a8a04edd6daf8fe867341/contracts/0.8.9/sanity_checks/OracleReportSanityChecker.sol#L976-L1068)
- [reported balances stored](https://github.com/lidofinance/core/blob/f19aab6d6b3857fa2b9a8a04edd6daf8fe867341/contracts/0.8.25/sr/SRLib.sol#L853-L892)
- [stored balances used for rewards](https://github.com/lidofinance/core/blob/f19aab6d6b3857fa2b9a8a04edd6daf8fe867341/contracts/0.8.25/sr/StakingRouter.sol#L808-L894)
- [existing EIP-4788 validator verifier](https://github.com/lidofinance/core/blob/f19aab6d6b3857fa2b9a8a04edd6daf8fe867341/contracts/0.8.25/CLValidatorVerifier.sol#L18-L107)

## Scope

Snapshot: mainnet block `25,567,397`, timestamp `2026-07-19T14:37:11Z`,
HashConsensus members/quorum `9/5`. PR base:
`eb4ff801ddbaa728397bc249ba6884500024d490`.

The formal proof package treats oracle truthfulness as assumption `A-ORC-03`.
It proves consistent storage and consumption of an accepted vector, not correct
module attribution.
