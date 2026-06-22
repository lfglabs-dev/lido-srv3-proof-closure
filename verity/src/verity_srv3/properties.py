from __future__ import annotations

from dataclasses import dataclass
from typing import Any, Callable

from .model import (
    BASIS_POINTS,
    FEE_PRECISION_POINTS,
    VALIDATOR_DEPOSIT_WEI,
    AcceptedReport,
    SRv3State,
    StakingModuleStatus,
    buffered_allocation,
    deposit,
    get_module_deposit_allocations,
    report_rewards_minted,
    staking_rewards_distribution,
)


@dataclass(frozen=True)
class CheckResult:
    target_id: str
    name: str
    status: str
    assumptions: tuple[str, ...]
    details: dict[str, Any]

    def as_json(self) -> dict[str, Any]:
        return {
            "id": self.target_id,
            "name": self.name,
            "status": self.status,
            "assumptions": list(self.assumptions),
            "details": self.details,
        }


def _result(target_id: str, name: str, assumptions: tuple[str, ...], ok: bool, **details: Any) -> CheckResult:
    return CheckResult(target_id, name, "pass" if ok else "fail", assumptions, details)


def reserve_separation(state: SRv3State, spend_wei: int = 0) -> CheckResult:
    before = buffered_allocation(state.reserves)
    ok = before["depositable"] == before["deposits_reserve"] + before["unreserved"]
    ok = ok and before["depositable"] + before["withdrawals_reserve"] == before["total"]
    ok = ok and spend_wei <= before["depositable"]
    if ok:
        after_buffer = state.reserves.buffered_wei - spend_wei
        ok = after_buffer >= before["withdrawals_reserve"] or state.reserves.unfinalized_withdrawal_wei > after_buffer
    return _result(
        "SRV3-P1",
        "reserve_separation",
        ("A-EXT-01", "A-ARITH-05"),
        ok,
        buffered_wei=state.reserves.buffered_wei,
        depositable_wei=before["depositable"],
        withdrawals_reserve_wei=before["withdrawals_reserve"],
        spend_wei=spend_wei,
    )


def deposit_conservation(state: SRv3State, module_id: int, returned_pubkeys_count: int) -> CheckResult:
    _, transition = deposit(state, module_id, returned_pubkeys_count)
    ok = transition.pulled_wei == VALIDATOR_DEPOSIT_WEI * transition.actual_deposits_count
    ok = ok and transition.router_eth_before == transition.router_eth_after
    ok = ok and transition.pulled_wei <= transition.allocations[module_id]
    return _result(
        "SRV3-P2",
        "deposit_conservation",
        ("A-DEP-02", "A-ID-04", "A-ARITH-05"),
        ok,
        actual_deposits_count=transition.actual_deposits_count,
        pulled_wei=transition.pulled_wei,
        router_eth_before=transition.router_eth_before,
        router_eth_after=transition.router_eth_after,
    )


def module_balance_conservation(state: SRv3State) -> CheckResult:
    report = state.latest_report
    ok = report is not None
    module_sum = sum(module.validators_balance_gwei for module in state.modules)
    if ok:
        ok = module_sum == state.router_validators_balance_gwei == sum(report.validator_balances_gwei)
    return _result(
        "SRV3-P3",
        "module_balance_conservation",
        ("A-ORC-03", "A-ID-04", "A-ARITH-05"),
        ok,
        router_validators_balance_gwei=state.router_validators_balance_gwei,
        module_sum_gwei=module_sum,
    )


def report_before_reward_consistency(state: SRv3State) -> CheckResult:
    report = state.latest_report
    rows = staking_rewards_distribution(state)
    balances_by_id = {module.module_id: module.validators_balance_gwei for module in state.modules}
    ok = report is not None
    if ok:
        report_by_id = dict(zip(report.module_ids, report.validator_balances_gwei, strict=True))
        ok = all(balances_by_id[row.module_id] == report_by_id[row.module_id] for row in rows)
    return _result(
        "SRV3-P4",
        "report_before_reward_consistency",
        ("A-ORC-03", "A-ID-04"),
        ok,
        rewarded_module_ids=[row.module_id for row in rows],
        report_sequence=None if report is None else report.sequence,
    )


def reward_correctness(state: SRv3State) -> CheckResult:
    rows = staking_rewards_distribution(state)
    ok = True
    row_details: list[dict[str, Any]] = []
    for row in rows:
        module = next(module for module in state.modules if module.module_id == row.module_id)
        upper_bound = FEE_PRECISION_POINTS * module.module_fee_bps // BASIS_POINTS
        expected_paid = 0 if module.status is StakingModuleStatus.STOPPED else row.module_fee
        row_ok = row.module_fee <= upper_bound and row.module_reward_paid == expected_paid
        ok = ok and row_ok
        row_details.append(
            {
                "module_id": row.module_id,
                "recipient": row.recipient,
                "module_fee": row.module_fee,
                "upper_bound": upper_bound,
                "module_reward_paid": row.module_reward_paid,
            }
        )

    calls = report_rewards_minted(state, tuple(row.module_id for row in rows), tuple(row.module_reward_paid for row in rows))
    ok = ok and all(calls[module_id] > 0 for module_id in calls)
    return _result(
        "SRV3-P5",
        "reward_correctness",
        ("A-ORC-03", "A-ARITH-05"),
        ok,
        rows=row_details,
        rewards_minted_calls=calls,
    )


def status_gating(state: SRv3State) -> CheckResult:
    allocations = get_module_deposit_allocations(state, buffered_allocation(state.reserves)["depositable"])
    rows = staking_rewards_distribution(state)
    reward_by_id = {row.module_id: row.module_reward_paid for row in rows}
    ok = True
    for module in state.modules:
        if module.status is not StakingModuleStatus.ACTIVE or module.deposits_paused:
            ok = ok and allocations[module.module_id] == 0
        if module.status is StakingModuleStatus.STOPPED:
            ok = ok and reward_by_id.get(module.module_id, 0) == 0
    return _result(
        "SRV3-P6",
        "status_gating",
        ("A-EXT-01", "A-ID-04"),
        ok,
        allocations=allocations,
        module_rewards=reward_by_id,
    )


PROPERTY_FUNCTIONS: dict[str, Callable[..., CheckResult]] = {
    "reserve_separation": reserve_separation,
    "deposit_conservation": deposit_conservation,
    "module_balance_conservation": module_balance_conservation,
    "report_before_reward_consistency": report_before_reward_consistency,
    "reward_correctness": reward_correctness,
    "status_gating": status_gating,
}
