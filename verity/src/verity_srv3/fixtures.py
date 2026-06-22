from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from .model import AcceptedReport, Module, ReserveState, SRv3State, StakingModuleStatus, accept_balance_report


def module_from_json(data: dict[str, Any]) -> Module:
    return Module(
        module_id=int(data["module_id"]),
        status=StakingModuleStatus(data["status"]),
        deposits_paused=bool(data.get("deposits_paused", False)),
        validators_balance_gwei=int(data.get("validators_balance_gwei", 0)),
        depositable_validators=int(data.get("depositable_validators", 0)),
        max_deposits_per_block=int(data.get("max_deposits_per_block", 0)),
        stake_share_limit_bps=int(data.get("stake_share_limit_bps", 0)),
        module_fee_bps=int(data.get("module_fee_bps", 0)),
        treasury_fee_bps=int(data.get("treasury_fee_bps", 0)),
        reward_recipient=str(data.get("reward_recipient", f"module-{data['module_id']}")),
    )


def state_from_json(data: dict[str, Any]) -> SRv3State:
    reserves = data["reserves"]
    state = SRv3State(
        modules=tuple(module_from_json(module) for module in data["modules"]),
        reserves=ReserveState(
            buffered_wei=int(reserves["buffered_wei"]),
            stored_deposit_reserve_wei=int(reserves["stored_deposit_reserve_wei"]),
            unfinalized_withdrawal_wei=int(reserves["unfinalized_withdrawal_wei"]),
        ),
    )
    report = data.get("accepted_report")
    if report is not None:
        state = accept_balance_report(
            state,
            AcceptedReport(
                module_ids=tuple(int(value) for value in report["module_ids"]),
                validator_balances_gwei=tuple(int(value) for value in report["validator_balances_gwei"]),
                sequence=int(report.get("sequence", 0)),
            ),
        )
    return state


def load_fixture(path: Path) -> tuple[SRv3State, dict[str, Any]]:
    data = json.loads(path.read_text())
    return state_from_json(data["state"]), data.get("args", {})
