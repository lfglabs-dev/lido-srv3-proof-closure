pragma solidity 0.8.25;

import {StakingRouter} from "contracts/0.8.25/sr/StakingRouter.sol";

// The receiver, its immutable LIDO binding, auth check and event are inherited
// unchanged. This forwarder is fixture admission, not production router logic.
contract RouterHarness is StakingRouter {
    constructor(address lido, address locator)
        StakingRouter(address(1), lido, locator, 32 ether, 2048 ether) {}

    function forward(address target, bytes calldata payload) external {
        (bool ok, bytes memory result) = target.call(payload);
        if (!ok) assembly ("memory-safe") { revert(add(result, 32), mload(result)) }
    }
}
