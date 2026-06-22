import unittest

from verity_srv3.model import (
    ETHER,
    GWEI,
    VALIDATOR_DEPOSIT_WEI,
    AcceptedReport,
    Module,
    ReserveState,
    SRv3State,
    StakingModuleStatus,
    accept_balance_report,
    buffered_allocation,
    deposit,
    get_module_deposit_allocations,
    report_rewards_minted,
    spend_depositable,
    staking_rewards_distribution,
)
from verity_srv3.runner import run_targets


def module(module_id=1, status=StakingModuleStatus.ACTIVE, paused=False, balance=0):
    return Module(
        module_id=module_id,
        status=status,
        deposits_paused=paused,
        validators_balance_gwei=balance,
        depositable_validators=4,
        max_deposits_per_block=4,
        stake_share_limit_bps=10_000,
        module_fee_bps=500,
        treasury_fee_bps=500,
        reward_recipient=f"module-{module_id}",
    )


class SRv3ModelTests(unittest.TestCase):
    def test_reserve_split_prioritizes_deposit_then_withdrawal(self):
        allocation = buffered_allocation(ReserveState(96 * ETHER, 32 * ETHER, 50 * ETHER))
        self.assertEqual(allocation["deposits_reserve"], 32 * ETHER)
        self.assertEqual(allocation["withdrawals_reserve"], 50 * ETHER)
        self.assertEqual(allocation["unreserved"], 14 * ETHER)
        self.assertEqual(allocation["depositable"], 46 * ETHER)

    def test_spend_depositable_does_not_spend_withdrawal_reserve(self):
        reserves = ReserveState(96 * ETHER, 32 * ETHER, 50 * ETHER)
        next_reserves = spend_depositable(reserves, 32 * ETHER)
        self.assertEqual(next_reserves.stored_deposit_reserve_wei, 0)
        self.assertEqual(buffered_allocation(next_reserves)["withdrawals_reserve"], 50 * ETHER)

    def test_deposit_exact_pull_and_router_balance_conservation(self):
        state = SRv3State((module(),), ReserveState(128 * ETHER, 64 * ETHER, 32 * ETHER))
        _, result = deposit(state, 1, 2)
        self.assertEqual(result.pulled_wei, 2 * VALIDATOR_DEPOSIT_WEI)
        self.assertEqual(result.router_eth_before, result.router_eth_after)

    def test_deposit_rejects_stopped_or_paused_modules(self):
        stopped = SRv3State((module(status=StakingModuleStatus.STOPPED),), ReserveState(128 * ETHER, 64 * ETHER, 0))
        with self.assertRaisesRegex(ValueError, "StakingModuleNotActive"):
            deposit(stopped, 1, 1)
        paused = SRv3State((module(paused=True),), ReserveState(128 * ETHER, 64 * ETHER, 0))
        with self.assertRaisesRegex(ValueError, "StakingModuleDepositsPaused"):
            deposit(paused, 1, 1)

    def test_accepted_report_sets_module_and_router_balances(self):
        state = SRv3State((module(1), module(2)), ReserveState(0, 0, 0))
        next_state = accept_balance_report(state, AcceptedReport((1, 2), (10, 20), 1))
        self.assertEqual([m.validators_balance_gwei for m in next_state.modules], [10, 20])
        self.assertEqual(next_state.router_validators_balance_gwei, 30)

    def test_accepted_report_requires_router_order_and_uint64_domain(self):
        state = SRv3State((module(1), module(2)), ReserveState(0, 0, 0))
        with self.assertRaisesRegex(ValueError, "UnexpectedModuleId"):
            accept_balance_report(state, AcceptedReport((2, 1), (10, 20), 1))
        with self.assertRaisesRegex(ValueError, "uint64 overflow"):
            accept_balance_report(state, AcceptedReport((1, 2), (2**64, 20), 1))

    def test_rewards_use_accepted_report_balances_and_stop_stopped_payment(self):
        modules = (
            module(1, balance=0),
            module(2, status=StakingModuleStatus.DEPOSITS_PAUSED, balance=0),
            module(3, status=StakingModuleStatus.STOPPED, balance=0),
        )
        state = accept_balance_report(SRv3State(modules, ReserveState(0, 0, 0)), AcceptedReport((1, 2, 3), (10, 20, 30), 1))
        rewards = staking_rewards_distribution(state)
        self.assertEqual([row.module_id for row in rewards], [1, 2, 3])
        self.assertEqual(rewards[2].module_reward_paid, 0)
        self.assertGreater(rewards[1].module_reward_paid, 0)

    def test_report_rewards_minted_skips_zero_and_requires_existing_module(self):
        state = SRv3State((module(1), module(2)), ReserveState(0, 0, 0))
        self.assertEqual(report_rewards_minted(state, (1, 2), (0, 10)), {2: 10})
        with self.assertRaisesRegex(ValueError, "unknown module id"):
            report_rewards_minted(state, (3,), (10,))

    def test_gwei_and_basis_point_rounding(self):
        self.assertEqual((123456789123 * GWEI) % GWEI, 0)
        modules = (
            module(1, paused=False),
            module(2, status=StakingModuleStatus.DEPOSITS_PAUSED),
            module(3, status=StakingModuleStatus.STOPPED),
        )
        state = SRv3State(modules, ReserveState(100 * ETHER, 100 * ETHER, 0))
        allocations = get_module_deposit_allocations(state, 100 * ETHER)
        self.assertEqual(allocations[2], 0)
        self.assertEqual(allocations[3], 0)
        self.assertEqual(allocations[1] % VALIDATOR_DEPOSIT_WEI, 0)

    def test_all_manifest_targets_pass(self):
        report = run_targets(
            targets_path=__import__("pathlib").Path("verity/targets/srv3-proof-targets.json"),
            fixtures_dir=__import__("pathlib").Path("tests/verity/fixtures"),
        )
        self.assertEqual(report["status"], "pass")
        self.assertEqual([target["id"] for target in report["targets"]], [f"SRV3-P{i}" for i in range(1, 7)])


if __name__ == "__main__":
    unittest.main()
