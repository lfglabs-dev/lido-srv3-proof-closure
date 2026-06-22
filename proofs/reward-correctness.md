# SRV3-P5 Reward Correctness

Source references:

- `contracts/0.8.25/sr/StakingRouter.sol::getStakingRewardsDistribution`
- `contracts/0.8.25/sr/StakingRouter.sol::_computeModuleFee`
- `contracts/0.8.25/sr/SRLib.sol::_reportRewardsMinted`

Model artifact:

- `verity/src/verity_srv3/model.py::staking_rewards_distribution`
- `verity/src/verity_srv3/model.py::report_rewards_minted`
- `verity/src/verity_srv3/properties.py::reward_correctness`
- `tests/verity/fixtures/p5_reward_correctness.json`

Math statement:

```text
moduleFee_m = floor(floor(balance_m * precision / totalBalance) * moduleFeeBps_m / 10000)
moduleFee_m <= floor(precision * moduleFeeBps_m / 10000)
stopped(m) => moduleRewardPaid_m = 0
nonzero reportRewardsMinted shares require an existing module id
```

Proof command:

```sh
PYTHONPATH=verity/src python3 -m verity_srv3.runner --targets verity/targets/srv3-proof-targets.json --fixtures tests/verity/fixtures --output proofs/logs/proof-report.json
```

Result:

```text
SRV3-P5 pass, recorded in proofs/logs/proof-report.json
```

Assumptions:

- `A-ORC-03`
- `A-ARITH-05`
