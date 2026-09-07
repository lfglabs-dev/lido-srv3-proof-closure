// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.25;
import {StakingRouter} from "contracts/0.8.25/sr/StakingRouter.sol";
/// Test-only seeding; public share and admission writers are inherited unmodified.
contract WriterHarness is StakingRouter {
    constructor() StakingRouter(address(1), address(2), address(3), 32, 2048) {}
    function writeSlot(uint256 slot, uint256 value) external { assembly { sstore(slot, value) } }
}
