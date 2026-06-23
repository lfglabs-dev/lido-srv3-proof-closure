# SRV3-P5 Reward Correctness

Source references:

- `contracts/0.8.25/sr/StakingRouter.sol::getStakingRewardsDistribution`
- `contracts/0.8.25/sr/StakingRouter.sol::_computeModuleFee`

Model artifact:

- `LidoSRv3/Model.lean::moduleRewardUpperBound`
- `LidoSRv3/Model.lean::moduleReward`
- `LidoSRv3/Model.lean::rewardRows`
- `LidoSRv3/Model.lean::RewardDistributionRow`
- `LidoSRv3/Model.lean::rewardShare`
- `LidoSRv3/Model.lean::computedModuleFee`
- `LidoSRv3/Model.lean::computedTreasuryFee`
- `LidoSRv3/Model.lean::rewardDistributionRow`
- `LidoSRv3/Model.lean::rewardDistributionLoop`
- `LidoSRv3/Model.lean::stakingRewardsDistributionRows`
- `LidoSRv3/Model.lean::rewardDistributionTotalFee`
- `LidoSRv3/SpecProofs.lean::P5_reward_bound`
- `LidoSRv3/SpecProofs.lean::P5_reward_recipient_alignment`
- `LidoSRv3/SpecProofs.lean::P5_rewards_distribution_rows_aligned`
- `LidoSRv3/SpecProofs.lean::P5_rewards_distribution_zero_total_empty`
- `LidoSRv3/SpecProofs.lean::P5_rewards_distribution_zero_total_empty_module_ids`
- `LidoSRv3/SpecProofs.lean::P5_rewards_distribution_row_nonzero_balance`
- `LidoSRv3/SpecProofs.lean::P5_rewards_distribution_paid_module_fee_bound`
- `LidoSRv3/SpecProofs.lean::P5_rewards_distribution_stopped_module_zero`
- `LidoSRv3/SpecProofs.lean::P5_rewards_distribution_total_fee_sum`

Math statement:

```text
moduleFee_m = floor(floor(balance_m * precision / totalBalance) * moduleFeeBps_m / 10000)
treasuryFee_m = floor(floor(balance_m * precision / totalBalance) * treasuryFeeBps_m / 10000)
moduleFee_m <= floor(precision * moduleFeeBps_m / 10000)
totalBalance == 0 => rewardDistributionRows == []
totalBalance == 0 => map(row.moduleId, rewardDistributionRows) == []
balance_m == 0 => m is skipped by the distribution loop
row in rewardDistributionRows => row.validatorsBalanceGwei != 0
row_m.rewardRecipient == moduleRecipient_m
row_m.paidModuleFee <= row_m.moduleFee
stopped(m) => moduleRewardPaid_m = 0
totalFee = sum(row.moduleFee + row.treasuryFee)
```

The total-fee equality is exposed as a standalone checked target over
arbitrary finite emitted row arrays, matching the row accumulator modeled in
`rewardDistributionTotalFee`.

Proof command:

```sh
lake build LidoSRv3
```

Result:

```text
SRV3-P5 Lean-checked, recorded in proofs/logs/proof-report.json
```

Assumptions:

- `A-ORC-03`
- `A-ARITH-05`
- `A-REWARD-09`
