# SRV3-P4 Report-Before-Reward Consistency

Source references:

- `contracts/0.8.9/oracle/AccountingOracle.sol::submitReportData`
- `contracts/0.8.25/sr/SRLib.sol::_reportValidatorBalancesByStakingModule`
- `contracts/0.8.25/sr/StakingRouter.sol::getStakingRewardsDistribution`

Model artifact:

- `verity/src/verity_srv3/model.py::accept_balance_report`
- `verity/src/verity_srv3/model.py::staking_rewards_distribution`
- `verity/src/verity_srv3/properties.py::report_before_reward_consistency`
- `tests/verity/fixtures/p4_report_before_reward_consistency.json`

Math statement:

```text
rewardStep(state) => exists acceptedReport r:
  reward balances for every rewarded module equal balances(r)
```

Proof command:

```sh
PYTHONPATH=verity/src python3 -m verity_srv3.runner --targets verity/targets/srv3-proof-targets.json --fixtures tests/verity/fixtures --output proofs/logs/proof-report.json
```

Result:

```text
SRV3-P4 pass, recorded in proofs/logs/proof-report.json
```

Assumptions:

- `A-ORC-03`
- `A-ID-04`
