# SRV3-P5 Reward Correctness

Source references:

- `contracts/0.8.25/sr/StakingRouter.sol::getStakingRewardsDistribution`
- `contracts/0.8.25/sr/StakingRouter.sol::_computeModuleFee`
- `contracts/0.8.25/sr/SRLib.sol::_reportRewardsMinted`

Model artifact:

- `LidoSRv3/Model.lean::moduleRewardUpperBound`
- `LidoSRv3/Model.lean::moduleReward`
- `LidoSRv3/Model.lean::rewardRows`
- `LidoSRv3/SpecProofs.lean::P5_reward_bound`
- `LidoSRv3/SpecProofs.lean::P5_reward_recipient_alignment`

Math statement:

```text
moduleFee_m = floor(floor(balance_m * precision / totalBalance) * moduleFeeBps_m / 10000)
moduleFee_m <= floor(precision * moduleFeeBps_m / 10000)
stopped(m) => moduleRewardPaid_m = 0
nonzero reportRewardsMinted shares require an existing module id
```

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
