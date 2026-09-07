// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.25;

import {SRLib} from "contracts/0.8.25/sr/SRLib.sol";
import {SRStorage} from "contracts/0.8.25/sr/SRStorage.sol";

/// Test-only physical seeding and external exposure of the unmodified pinned helper.
contract ParentHarness {
    function writeSlot(uint256 slot, uint256 value) external {
        assembly { sstore(slot, value) }
    }

    function routerSlot() external pure returns (uint256 slot) {
        // Spell the pinned ERC-7201 expression independently for the test runner.
        return uint256(keccak256(abi.encode(uint256(keccak256(
            abi.encodePacked("lido.StakingRouter.routerStorage"))) - 1))) & ~uint256(0xff);
    }

    function parent(SRLib.Config calldata cfg, uint256 amount, bool topup)
        external view returns (uint256, uint256[] memory, uint256[] memory)
    {
        return SRLib._getDepositAllocations(cfg, amount, topup);
    }

    event BeforeParent(uint256 value);

    /// Test-only enclosing transaction with observable effects before the real helper.
    function parentWithPriorEffects(SRLib.Config calldata cfg, uint256 amount, bool topup,
        address payable recipient) external returns (uint256, uint256[] memory, uint256[] memory)
    {
        assembly { sstore(0x123456, 42) }
        emit BeforeParent(42);
        (bool sent,) = recipient.call{value: 1}("");
        require(sent);
        return SRLib._getDepositAllocations(cfg, amount, topup);
    }

    function capacity(SRLib.Config calldata cfg, uint256 demand, bool topup)
        external view returns (uint256[] memory, uint256[] memory)
    {
        return SRLib._getModulesAllocationAndCapacity(cfg, demand, topup);
    }
}

/// An adversarial callee: raw revert bytes, short and trailing responses are allowed.
contract RawModule {
    bytes summary;
    bytes stake;
    bool rejectSummary;
    bool rejectStake;

    function configure(bytes calldata s, bytes calldata t, bool rs, bool rt) external {
        summary = s;
        stake = t;
        rejectSummary = rs;
        rejectStake = rt;
    }

    fallback() external {
        bytes memory result = msg.sig == 0x9abddf09 ? summary : stake;
        bool reject = msg.sig == 0x9abddf09 ? rejectSummary : rejectStake;
        assembly {
            let start := add(result, 32)
            let length := mload(result)
            if reject { revert(start, length) }
            return(start, length)
        }
    }
}
