# SRV3-P4 Report-Before-Reward Consistency

Source references:

- `contracts/0.8.9/oracle/AccountingOracle.sol::submitReportData`
- `contracts/0.8.25/sr/SRLib.sol::_reportValidatorBalancesByStakingModule`
- `contracts/0.8.25/sr/StakingRouter.sol::getStakingRewardsDistribution`

Model artifact:

- `LidoSRv3/Legacy/Model.lean::acceptReport`
- `LidoSRv3/Legacy/Model.lean::reportValidatorBalancesTransition`
- `LidoSRv3/Legacy/Model.lean::rewardsUseAcceptedReport`
- `LidoSRv3/Legacy/SpecProofs.lean::P4_report_before_reward_consistency`
- `LidoSRv3/Legacy/SpecProofs.lean::P4_report_transition_before_reward_consistency`

Math statement:

```text
rewardStep(state) => exists acceptedReport r:
  reward balances for every rewarded module equal balances(r)
```

Proof command:

```sh
lake build LidoSRv3
```

Result:

```text
SRV3-P4 Lean-checked, recorded in proofs/logs/proof-report.json
```

Assumptions:

- `A-ORC-03`
- `A-ID-04`
