# SRV3-P8 Top-Up Conservation

Source references:

- [`StakingRouter.sol:717-750`](https://github.com/lidofinance/core/blob/af095e48bbc1c3841c2c9936219c8461af01056b/contracts/0.8.25/sr/StakingRouter.sol#L717-L750)
- [`BeaconChainDepositor.sol:66-75`](https://github.com/lidofinance/core/blob/af095e48bbc1c3841c2c9936219c8461af01056b/contracts/0.8.25/lib/BeaconChainDepositor.sol#L66-L75)
- `contracts/0.8.25/sr/StakingRouter.sol::_validateTopUpInputs`
- `contracts/0.8.25/sr/StakingRouter.sol::_getModuleDepositAllocation`
- `contracts/0.8.25/sr/StakingRouter.sol::setMaxTopUpPerBlockGwei`
- `contracts/0.4.24/Lido.sol::canDeposit`
- `contracts/0.8.25/lib/BeaconChainDepositor.sol::makeBeaconChainTopUp`
- `contracts/common/interfaces/IStakingModuleV2.sol::allocateDeposits`

Model artifact:

- `LidoSRv3/Model.lean::roundDownToGwei`
- `LidoSRv3/Model.lean::maxTopUpPerBlockWei`
- `LidoSRv3/Model.lean::topUpTargetWei`
- `LidoSRv3/Model.lean::allocationsGweiAligned`
- `LidoSRv3/Model.lean::allocationsWithinLimits`
- `LidoSRv3/Model.lean::topUpAllocationsWellFormed`
- `LidoSRv3/Model.lean::topUpTransition`
- `LidoSRv3/SpecProofs.lean::P8_topup_transition_requires_active_topup_module`
- `LidoSRv3/SpecProofs.lean::P8_topup_transition_requires_input_shape`
- `LidoSRv3/SpecProofs.lean::P8_topup_transition_requires_well_formed_allocations`
- `LidoSRv3/SpecProofs.lean::P8_topup_transition_allocation_sum_bounded_by_module_allocation`
- `LidoSRv3/SpecProofs.lean::P8_topup_transition_router_eth_unchanged`
- `LidoSRv3/SpecProofs.lean::P8_topup_transition_modules_unchanged`
- `LidoSRv3/SpecProofs.lean::P8_topup_transition_preserves_report_state`
- `LidoSRv3/SpecProofs.lean::P8_topup_transition_beacon_sink_exact`
- `LidoSRv3/SpecProofs.lean::P8_topup_transition_buffered_exact`
- `LidoSRv3/SpecProofs.lean::P8_topup_transition_withdrawal_reserve_unchanged`
- `LidoSRv3/SpecProofs.lean::P8_topup_transition_deposit_reserve_spent`
- `LidoSRv3/SpecProofs.lean::P8_topup_transition_positive_requires_depositable`
- `LidoSRv3/SpecProofs.lean::P8_topup_transition_zero_sum_noop`
- `LidoSRv3/SpecProofs.lean::P8_topup_transition_respects_per_block_cap`
- `LidoSRv3/SpecProofs.lean::P8_topup_transition_zero_target_requires_lido_can_deposit`
- `LidoSRv3/SpecProofs.lean::P8_topup_transition_short_zero_sum_permitted`
- `LidoSRv3/SpecProofs.lean::P8_topup_transition_positive_requires_exact_return_length`
- `LidoSRv3/SpecProofs.lean::P8_topup_transition_short_positive_rejects`
- `LidoSRv3/SpecProofs.lean::P8_topup_transition_long_return_rejects`
- `LidoSRv3/TopUpShapeTests.lean` (seven-case boundary/mutation matrix)

Math statement:

```text
keyCount > 0
nodeOperatorCount = keyCount
len(topUpLimits) = keyCount
pubkeyCount = keyCount
len(allocations) <= keyCount
sum(allocations) > 0 => len(allocations) = pubkeyCount = keyCount
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

Source-fidelity correction:

- A return longer than the request reverts in the router loop when
  `_topUpLimits[i]` is indexed (`StakingRouter.sol:723-729`).
- A shorter positive return reaches the beacon helper and reverts because
  `_publicKeys.length != _amount.length`
  (`StakingRouter.sol:741-750`, `BeaconChainDepositor.sol:72-75`).
- A shorter zero-sum return can succeed because the positive-only helper call is
  skipped (`StakingRouter.sol:741-750`).

At baseline `7dedaf0d5fb4ce7c8734792d47dbf774ed570c0c`, reduction of the old
`topUpTransition` rejected the empty and one-element zero-sum returns solely at
its unconditional `allocations.length = keyCount` guard. The focused examples
now accept those source-valid cases and reject short-positive and both long
cases. Restoring the old equality makes the first two examples fail.

`Option.none` establishes rejection and absence of a committed modeled state.
The pure model has no intermediate call trace, so EVM rollback of the module
call, Lido pull, and beacon call is not claimed here; that trace theorem remains
deferred to the planned `LidoSRv3.Audit` layer.

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
