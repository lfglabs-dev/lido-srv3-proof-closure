# SRV3-P2 Deposit Conservation

Source references:

- `contracts/0.8.25/sr/StakingRouter.sol::deposit`
- `contracts/0.4.24/Lido.sol::withdrawDepositableEther`
- `contracts/0.8.25/lib/BeaconChainDepositor.sol::makeBeaconChainDeposits32ETH`

Model artifact:

- `LidoSRv3/Legacy/Model.lean::depositPullWei`
- `LidoSRv3/Legacy/Model.lean::depositMaxCount`
- `LidoSRv3/Legacy/Model.lean::depositTransition`
- `LidoSRv3/Legacy/Model.lean::allocatedDeposits`
- `LidoSRv3/Legacy/Model.lean::depositAllocationWellFormed`
- `LidoSRv3/Legacy/Model.lean::totalAllocatedDeposits`
- `LidoSRv3/Legacy/SpecProofs.lean::P2_deposit_exact_pull`
- `LidoSRv3/Legacy/SpecProofs.lean::P2_deposit_transition_router_eth_unchanged`
- `LidoSRv3/Legacy/SpecProofs.lean::P2_deposit_transition_beacon_sink_exact`
- `LidoSRv3/Legacy/SpecProofs.lean::P2_deposit_transition_buffered_exact`
- `LidoSRv3/Legacy/SpecProofs.lean::P2_deposit_transition_positive_requires_depositable`
- `LidoSRv3/Legacy/SpecProofs.lean::P2_deposit_transition_zero_external_value_unchanged`
- `LidoSRv3/Legacy/SpecProofs.lean::P2_deposit_transition_withdrawal_reserve_unchanged`
- `LidoSRv3/Legacy/SpecProofs.lean::P2_deposit_transition_deposit_reserve_spent`
- `LidoSRv3/Legacy/SpecProofs.lean::P2_deposit_transition_requires_active_module_and_capacity`
- `LidoSRv3/Legacy/SpecProofs.lean::P2_deposit_transition_modules_exact`
- `LidoSRv3/Legacy/SpecProofs.lean::P2_deposit_transition_records_last_deposit`
- `LidoSRv3/Legacy/SpecProofs.lean::P2_deposit_transition_preserves_module_length`
- `LidoSRv3/Legacy/SpecProofs.lean::P2_deposit_transition_preserves_module_balance_sum`
- `LidoSRv3/Legacy/SpecProofs.lean::P2_deposit_transition_preserves_report_state`
- `LidoSRv3/Legacy/SpecProofs.lean::P2_total_allocated_deposits`

Math statement:

```text
pulledWei = 32 ETH * actualDeposits
totalAllocatedDeposits(rows) = sum(count for (module, count) in rows), when the allocation is well-formed (only active modules carry a positive count); the one router deposit budget is split across module rows rather than every active module receiving the full count
routerEthAfter = routerEthBefore
pulledWei <= depositableEtherBefore, when actualDeposits > 0
bufferedEtherAfter = bufferedEtherBefore - pulledWei, when actualDeposits > 0
beaconSinkAfter = beaconSinkBefore + pulledWei, when actualDeposits > 0
bufferedEtherAfter = bufferedEtherBefore, when actualDeposits = 0
beaconSinkAfter = beaconSinkBefore, when actualDeposits = 0
withdrawalReserveAfter = withdrawalReserveBefore
depositReserveAfter = depositReserveBefore - pulledWei, when actualDeposits > 0
selectedModule.status = active
maxDepositsCount = min(maxDepositsPerBlock, moduleAllocationWei / 32 ETH)
maxDepositsCount != 0
actualDeposits <= maxDepositsCount
modulesAfter = recordModuleLastDeposit(stakingModuleId, pulledWei, modulesBefore)
selectedModule.lastDepositWeiAfter = pulledWei
modulesAfter.length = modulesBefore.length
sum(validatorsBalanceGwei(modulesAfter)) = sum(validatorsBalanceGwei(modulesBefore))
routerBalanceGweiAfter = routerBalanceGweiBefore
lastAcceptedReportAfter = lastAcceptedReportBefore
```

Proof command:

```sh
lake build LidoSRv3
```

Result:

```text
SRV3-P2 Lean-checked, recorded in proofs/logs/proof-report.json
```

Assumptions:

- `A-DEP-02`
- `A-EXT-01`
- `A-ID-04`
- `A-ARITH-05`
