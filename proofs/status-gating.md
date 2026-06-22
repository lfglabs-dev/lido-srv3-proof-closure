# SRV3-P6 Status Gating

Source references:

- `contracts/0.8.25/sr/SRTypes.sol::StakingModuleStatus`
- `contracts/0.8.25/sr/StakingRouter.sol::deposit`
- `contracts/0.8.25/sr/StakingRouter.sol::getStakingRewardsDistribution`

Model artifact:

- `verity/src/verity_srv3/model.py::get_module_deposit_allocations`
- `verity/src/verity_srv3/model.py::staking_rewards_distribution`
- `verity/src/verity_srv3/properties.py::status_gating`
- `tests/verity/fixtures/p6_status_gating.json`

Math statement:

```text
status(m) != Active or depositsPaused(m) => allocatedDeposits_m = 0
status(m) = Stopped => moduleRewardPaid_m = 0
```

Proof command:

```sh
PYTHONPATH=verity/src python3 -m verity_srv3.runner --targets verity/targets/srv3-proof-targets.json --fixtures tests/verity/fixtures --output proofs/logs/proof-report.json
```

Result:

```text
SRV3-P6 pass, recorded in proofs/logs/proof-report.json
```

Assumptions:

- `A-EXT-01`
- `A-ID-04`
