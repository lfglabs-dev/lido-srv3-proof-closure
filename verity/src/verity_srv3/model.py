from __future__ import annotations

from dataclasses import dataclass, replace
from enum import Enum
from typing import Iterable

GWEI = 10**9
ETHER = 10**18
VALIDATOR_DEPOSIT_WEI = 32 * ETHER
BASIS_POINTS = 10_000
FEE_PRECISION_POINTS = 10**20
UINT64_MAX = 2**64 - 1


class StakingModuleStatus(str, Enum):
    ACTIVE = "active"
    DEPOSITS_PAUSED = "deposits_paused"
    STOPPED = "stopped"


@dataclass(frozen=True)
class ReserveState:
    buffered_wei: int
    stored_deposit_reserve_wei: int
    unfinalized_withdrawal_wei: int


@dataclass(frozen=True)
class Module:
    module_id: int
    status: StakingModuleStatus
    deposits_paused: bool
    validators_balance_gwei: int
    depositable_validators: int
    max_deposits_per_block: int
    stake_share_limit_bps: int
    module_fee_bps: int
    treasury_fee_bps: int
    reward_recipient: str

    def active_for_deposits(self) -> bool:
        return self.status is StakingModuleStatus.ACTIVE and not self.deposits_paused


@dataclass(frozen=True)
class AcceptedReport:
    module_ids: tuple[int, ...]
    validator_balances_gwei: tuple[int, ...]
    sequence: int = 0


@dataclass(frozen=True)
class SRv3State:
    modules: tuple[Module, ...]
    reserves: ReserveState
    router_validators_balance_gwei: int = 0
    latest_report: AcceptedReport | None = None


@dataclass(frozen=True)
class AllocationResult:
    requested_module_id: int
    max_deposits_count: int
    actual_deposits_count: int
    pulled_wei: int
    router_eth_before: int
    router_eth_after: int
    allocations: dict[int, int]


@dataclass(frozen=True)
class RewardRow:
    module_id: int
    recipient: str
    validators_balance_wei: int
    module_fee: int
    treasury_fee: int
    total_fee: int
    module_reward_paid: int


def require_non_negative(*values: int) -> None:
    if any(value < 0 for value in values):
        raise ValueError("negative integer outside modeled uint domain")


def require_gwei_aligned(value_wei: int) -> None:
    require_non_negative(value_wei)
    if value_wei % GWEI != 0:
        raise ValueError("amount is not aligned to gwei")


def to_wei(gwei: int) -> int:
    require_non_negative(gwei)
    return gwei * GWEI


def buffered_allocation(reserves: ReserveState) -> dict[str, int]:
    """Mirror Lido._getBufferedEtherAllocation priority order.

    Sources:
    - contracts/0.4.24/Lido.sol lines 603-614 at PR #1811 commit d088bbc2...
    - contracts/0.4.24/Lido.sol lines 819-820 for depositable ether
    """

    require_non_negative(
        reserves.buffered_wei,
        reserves.stored_deposit_reserve_wei,
        reserves.unfinalized_withdrawal_wei,
    )
    remaining = reserves.buffered_wei
    deposits_reserve = min(remaining, reserves.stored_deposit_reserve_wei)
    remaining -= deposits_reserve
    withdrawals_reserve = min(remaining, reserves.unfinalized_withdrawal_wei)
    remaining -= withdrawals_reserve
    return {
        "total": reserves.buffered_wei,
        "deposits_reserve": deposits_reserve,
        "withdrawals_reserve": withdrawals_reserve,
        "unreserved": remaining,
        "depositable": deposits_reserve + remaining,
    }


def spend_depositable(reserves: ReserveState, amount_wei: int) -> ReserveState:
    """Spend depositable buffer and decrement stored deposit reserve first."""

    require_non_negative(amount_wei)
    allocation = buffered_allocation(reserves)
    if amount_wei > allocation["depositable"]:
        raise ValueError("NOT_ENOUGH_ETHER")
    stored = reserves.stored_deposit_reserve_wei
    return ReserveState(
        buffered_wei=reserves.buffered_wei - amount_wei,
        stored_deposit_reserve_wei=max(0, stored - amount_wei),
        unfinalized_withdrawal_wei=reserves.unfinalized_withdrawal_wei,
    )


def module_by_id(state: SRv3State, module_id: int) -> Module:
    for module in state.modules:
        if module.module_id == module_id:
            return module
    raise ValueError(f"unknown module id {module_id}")


def module_ids(state: SRv3State) -> tuple[int, ...]:
    return tuple(module.module_id for module in state.modules)


def validate_unique_module_ids(modules: Iterable[Module]) -> None:
    ids = [module.module_id for module in modules]
    if len(ids) != len(set(ids)):
        raise ValueError("duplicate module ids")


def get_module_deposit_allocations(state: SRv3State, depositable_wei: int) -> dict[int, int]:
    """Deterministic share-limit allocation used by the executable harness.

    The Solidity implementation delegates the exact queue math to SRLib. This
    model preserves the P0 gate and conservation obligations: non-active or
    paused modules receive zero, each active module is capped by capacity and
    share-limit, and total allocation never exceeds depositable ETH.
    """

    require_non_negative(depositable_wei)
    validate_unique_module_ids(state.modules)
    allocations: dict[int, int] = {}
    remaining = depositable_wei
    for module in state.modules:
        if not module.active_for_deposits():
            allocations[module.module_id] = 0
            continue
        share_cap = depositable_wei * module.stake_share_limit_bps // BASIS_POINTS
        capacity = module.depositable_validators * VALIDATOR_DEPOSIT_WEI
        amount = min(remaining, share_cap, capacity)
        amount -= amount % VALIDATOR_DEPOSIT_WEI
        allocations[module.module_id] = amount
        remaining -= amount
    return allocations


def deposit(
    state: SRv3State,
    requested_module_id: int,
    returned_pubkeys_count: int,
    router_eth_before: int = 0,
) -> tuple[SRv3State, AllocationResult]:
    """Mirror StakingRouter.deposit economic effects for 32 ETH deposits.

    Sources:
    - contracts/0.8.25/sr/StakingRouter.sol lines 922-980
    - contracts/0.4.24/Lido.sol lines 856-872
    """

    require_non_negative(returned_pubkeys_count, router_eth_before)
    module = module_by_id(state, requested_module_id)
    if module.status is not StakingModuleStatus.ACTIVE:
        raise ValueError("StakingModuleNotActive")
    if module.deposits_paused:
        raise ValueError("StakingModuleDepositsPaused")

    depositable = buffered_allocation(state.reserves)["depositable"]
    allocations = get_module_deposit_allocations(state, depositable)
    max_deposits_count = min(
        module.max_deposits_per_block,
        module.depositable_validators,
        allocations[requested_module_id] // VALIDATOR_DEPOSIT_WEI,
    )
    if max_deposits_count == 0:
        raise ValueError("ZeroDeposits")
    if returned_pubkeys_count > max_deposits_count:
        raise ValueError("ModuleReturnExceedTarget")

    pulled_wei = returned_pubkeys_count * VALIDATOR_DEPOSIT_WEI
    next_reserves = spend_depositable(state.reserves, pulled_wei) if pulled_wei else state.reserves
    next_modules = tuple(
        replace(
            current,
            depositable_validators=current.depositable_validators - returned_pubkeys_count,
        )
        if current.module_id == requested_module_id
        else current
        for current in state.modules
    )
    next_state = replace(state, modules=next_modules, reserves=next_reserves)
    result = AllocationResult(
        requested_module_id=requested_module_id,
        max_deposits_count=max_deposits_count,
        actual_deposits_count=returned_pubkeys_count,
        pulled_wei=pulled_wei,
        router_eth_before=router_eth_before,
        router_eth_after=router_eth_before,
        allocations=allocations,
    )
    return next_state, result


def accept_balance_report(state: SRv3State, report: AcceptedReport) -> SRv3State:
    """Apply the accepted module-balance report in router order.

    Sources:
    - contracts/0.8.25/sr/SRLib.sol lines 853-891
    - contracts/0.8.25/sr/SRTypes.sol lines 156-168
    """

    if report.module_ids != module_ids(state):
        raise ValueError("UnexpectedModuleId")
    if len(report.validator_balances_gwei) != len(state.modules):
        raise ValueError("ArraysLengthMismatch")
    total = 0
    next_modules: list[Module] = []
    for module, balance_gwei in zip(state.modules, report.validator_balances_gwei, strict=True):
        require_non_negative(balance_gwei)
        if balance_gwei > UINT64_MAX:
            raise ValueError("uint64 overflow")
        total += balance_gwei
        if total > UINT64_MAX:
            raise ValueError("router uint64 overflow")
        next_modules.append(replace(module, validators_balance_gwei=balance_gwei))
    return replace(
        state,
        modules=tuple(next_modules),
        router_validators_balance_gwei=total,
        latest_report=report,
    )


def staking_rewards_distribution(state: SRv3State) -> tuple[RewardRow, ...]:
    """Compute module reward distribution from accepted balances.

    Sources:
    - contracts/0.8.25/sr/StakingRouter.sol lines 788-853
    - contracts/0.8.25/sr/StakingRouter.sol lines 865-873
    """

    total_validators_balance_wei = to_wei(state.router_validators_balance_gwei)
    if total_validators_balance_wei == 0:
        return ()

    rows: list[RewardRow] = []
    total_fee = 0
    for module in state.modules:
        allocation = to_wei(module.validators_balance_gwei)
        if allocation == 0:
            continue
        share = allocation * FEE_PRECISION_POINTS // total_validators_balance_wei
        module_fee = share * module.module_fee_bps // BASIS_POINTS
        treasury_fee = share * module.treasury_fee_bps // BASIS_POINTS
        paid = 0 if module.status is StakingModuleStatus.STOPPED else module_fee
        total_fee += module_fee + treasury_fee
        rows.append(
            RewardRow(
                module_id=module.module_id,
                recipient=module.reward_recipient,
                validators_balance_wei=allocation,
                module_fee=module_fee,
                treasury_fee=treasury_fee,
                total_fee=module_fee + treasury_fee,
                module_reward_paid=paid,
            )
        )
    if total_fee > FEE_PRECISION_POINTS:
        raise ValueError("total fee exceeds precision")
    return tuple(rows)


def report_rewards_minted(state: SRv3State, staking_module_ids: tuple[int, ...], total_shares: tuple[int, ...]) -> dict[int, int]:
    """Return the non-zero onRewardsMinted calls made by SRLib.

    Sources:
    - contracts/0.8.25/sr/StakingRouter.sol lines 253-260
    - contracts/0.8.25/sr/SRLib.sol lines 620-638
    """

    if len(staking_module_ids) != len(total_shares):
        raise ValueError("ArraysLengthMismatch")
    calls: dict[int, int] = {}
    known = set(module_ids(state))
    for module_id, shares in zip(staking_module_ids, total_shares, strict=True):
        require_non_negative(shares)
        if shares == 0:
            continue
        if module_id not in known:
            raise ValueError("unknown module id")
        calls[module_id] = shares
    return calls
