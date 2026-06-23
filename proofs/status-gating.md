# SRV3-P6 Status Gating

Source references:

- `contracts/0.8.25/sr/SRTypes.sol::StakingModuleStatus`
- `contracts/0.8.25/sr/StakingRouter.sol::deposit`
- `contracts/0.8.25/sr/StakingRouter.sol::getStakingRewardsDistribution`

Model artifact:

- `LidoSRv3/Model.lean::allocatedDeposits`
- `LidoSRv3/Model.lean::moduleReward`
- `LidoSRv3/SpecProofs.lean::P6_deposit_status_gating`
- `LidoSRv3/SpecProofs.lean::P6_stopped_module_reward_zero`

Math statement:

```text
status(m) != Active or depositsPaused(m) => allocatedDeposits_m = 0
status(m) = Stopped => moduleRewardPaid_m = 0
```

Proof command:

```sh
lake build LidoSRv3
```

Result:

```text
SRV3-P6 Lean-checked, recorded in proofs/logs/proof-report.json
```

Assumptions:

- `A-EXT-01`
- `A-ID-04`
