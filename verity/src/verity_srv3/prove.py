from __future__ import annotations

from dataclasses import replace

from .model import (
    AcceptedReport,
    ETHER,
    VALIDATOR_DEPOSIT_WEI,
    Module,
    ReserveState,
    SRv3State,
    StakingModuleStatus,
    accept_balance_report,
    buffered_allocation,
)
from .properties import (
    deposit_conservation,
    module_balance_conservation,
    report_before_reward_consistency,
    reserve_separation,
    reward_correctness,
    status_gating,
)


def base_modules() -> tuple[Module, Module, Module]:
    return (
        Module(1, StakingModuleStatus.ACTIVE, False, 0, 6, 4, 6_000, 500, 500, "nor"),
        Module(2, StakingModuleStatus.ACTIVE, True, 0, 6, 4, 3_000, 700, 300, "csm"),
        Module(3, StakingModuleStatus.STOPPED, False, 0, 6, 4, 1_000, 800, 200, "legacy"),
    )


def prove() -> list[str]:
    failures: list[str] = []
    for buffered in (0, 8 * ETHER, 32 * ETHER, 65 * ETHER, 128 * ETHER):
        for deposit_reserve in (0, 32 * ETHER, 64 * ETHER):
            for withdrawals in (0, 16 * ETHER, 64 * ETHER):
                state = SRv3State(base_modules(), ReserveState(buffered, deposit_reserve, withdrawals))
                spend = min(buffered_allocation(state.reserves)["depositable"], VALIDATOR_DEPOSIT_WEI)
                result = reserve_separation(state, spend)
                if result.status != "pass":
                    failures.append(f"{result.target_id}: {result.details}")

    deposit_state = SRv3State(base_modules(), ReserveState(128 * ETHER, 64 * ETHER, 32 * ETHER))
    for returned in (1,):
        result = deposit_conservation(deposit_state, 1, returned)
        if result.status != "pass":
            failures.append(f"{result.target_id}: {result.details}")

    for balances in ((32_000_000_000, 16_000_000_000, 8_000_000_000), (1, 2, 3), (0, 0, 0)):
        state = SRv3State(base_modules(), ReserveState(128 * ETHER, 64 * ETHER, 0))
        reported = accept_balance_report(
            state,
            report=AcceptedReport((1, 2, 3), balances, 11),
        )
        for check in (
            module_balance_conservation(reported),
            report_before_reward_consistency(reported),
            reward_correctness(reported),
            status_gating(reported),
        ):
            if check.status != "pass":
                failures.append(f"{check.target_id}: {check.details}")

    paused_variant = SRv3State(
        tuple(replace(module, deposits_paused=True) if module.module_id == 1 else module for module in base_modules()),
        ReserveState(128 * ETHER, 64 * ETHER, 0),
    )
    paused_reported = accept_balance_report(
        paused_variant,
        report=AcceptedReport((1, 2, 3), (10, 20, 30), 12),
    )
    result = status_gating(paused_reported)
    if result.status != "pass":
        failures.append(f"{result.target_id}: {result.details}")
    return failures


def main() -> int:
    failures = prove()
    if failures:
        print("FAIL")
        for failure in failures:
            print(failure)
        return 1
    print("PASS SRV3-P1 reserve separation")
    print("PASS SRV3-P2 deposit conservation")
    print("PASS SRV3-P3 module balance conservation")
    print("PASS SRV3-P4 report-before-reward consistency")
    print("PASS SRV3-P5 reward correctness")
    print("PASS SRV3-P6 status gating")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
