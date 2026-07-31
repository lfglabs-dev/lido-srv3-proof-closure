# SRV3-P8 Top-Up Conservation

Source references:

- `contracts/0.8.25/sr/StakingRouter.sol::topUp`
- `contracts/0.8.25/sr/StakingRouter.sol::_validateTopUpInputs`
- `contracts/0.8.25/sr/StakingRouter.sol::_getModuleDepositAllocation`
- `contracts/0.8.25/sr/StakingRouter.sol::setMaxTopUpPerBlockGwei`
- `contracts/0.4.24/Lido.sol::canDeposit`
- `contracts/0.8.25/lib/BeaconChainDepositor.sol::makeBeaconChainTopUp`
- `contracts/common/interfaces/IStakingModuleV2.sol::allocateDeposits`

Model artifact:

- `LidoSRv3/Legacy/Model.lean::roundDownToGwei`
- `LidoSRv3/Legacy/Model.lean::maxTopUpPerBlockWei`
- `LidoSRv3/Legacy/Model.lean::topUpTargetWei`
- `LidoSRv3/Legacy/Model.lean::allocationsGweiAligned`
- `LidoSRv3/Legacy/Model.lean::allocationsWithinLimits`
- `LidoSRv3/Legacy/Model.lean::topUpAllocationsWellFormed`
- `LidoSRv3/Legacy/Model.lean::topUpTransition`
- `LidoSRv3/Legacy/SpecProofs.lean::P8_topup_transition_requires_active_topup_module`
- `LidoSRv3/Legacy/SpecProofs.lean::P8_topup_transition_requires_input_shape`
- `LidoSRv3/Legacy/SpecProofs.lean::P8_topup_transition_requires_well_formed_allocations`
- `LidoSRv3/Legacy/SpecProofs.lean::P8_topup_transition_allocation_sum_bounded_by_module_allocation`
- `LidoSRv3/Legacy/SpecProofs.lean::P8_topup_transition_router_eth_unchanged`
- `LidoSRv3/Legacy/SpecProofs.lean::P8_topup_transition_modules_unchanged`
- `LidoSRv3/Legacy/SpecProofs.lean::P8_topup_transition_preserves_report_state`
- `LidoSRv3/Legacy/SpecProofs.lean::P8_topup_transition_beacon_sink_exact`
- `LidoSRv3/Legacy/SpecProofs.lean::P8_topup_transition_buffered_exact`
- `LidoSRv3/Legacy/SpecProofs.lean::P8_topup_transition_withdrawal_reserve_unchanged`
- `LidoSRv3/Legacy/SpecProofs.lean::P8_topup_transition_deposit_reserve_spent`
- `LidoSRv3/Legacy/SpecProofs.lean::P8_topup_transition_positive_requires_depositable`
- `LidoSRv3/Legacy/SpecProofs.lean::P8_topup_transition_zero_sum_noop`
- `LidoSRv3/Legacy/SpecProofs.lean::P8_topup_transition_respects_per_block_cap`
- `LidoSRv3/Legacy/SpecProofs.lean::P8_topup_transition_zero_target_requires_lido_can_deposit`

Math statement:

```text
keyCount > 0
nodeOperatorCount = keyCount
len(topUpLimits) = keyCount
pubkeyCount = keyCount
len(allocations) = keyCount
forall i. allocations[i] % 1 gwei = 0
forall i. allocations[i] <= topUpLimits[i]
topUpTarget = roundDownToGwei(min(moduleAllocationWei, maxTopUpPerBlockGwei * 1 gwei))
sum(allocations) <= topUpTarget
sum(allocations) <= moduleAllocationWei
sum(allocations) <= maxTopUpPerBlockGwei * 1 gwei
topUpTarget = 0 => lidoCanDeposit = true
sum(allocations) > 0 => sum(allocations) <= depositableEther
sum(allocations) > 0 => bufferedEther' = bufferedEther - sum(allocations)
sum(allocations) > 0 => beaconTopUpSink' = beaconTopUpSink + sum(allocations)
sum(allocations) = 0 => state' = state
routerEthBalance' = routerEthBalance
modules' = modules
routerBalanceGwei' = routerBalanceGwei
lastAcceptedReport' = lastAcceptedReport
withdrawalReserve' = withdrawalReserve
depositReserve' = depositReserve - sum(allocations), when sum(allocations) > 0
```

Proof command:

```sh
lake build LidoSRv3
```

Result:

```text
SRV3-P8 Lean-checked, recorded in proofs/logs/proof-report.json
```

Assumptions:

- `A-LIDO-06`
- `A-DEP-02`
- `A-MOD-10`
- `A-ARITH-05`
