pragma solidity 0.8.9;
import "contracts/0.8.9/WithdrawalQueueERC721.sol";

contract FinalizeWstETHFixture {
    function stETH() external view returns (address) { return address(this); }
}

// Setup/read helpers only. Production finalize, pause and role methods are inherited unchanged.
contract QueueFinalizeHarness is WithdrawalQueueERC721 {
    constructor() WithdrawalQueueERC721(address(new FinalizeWstETHFixture()), "Queue", "Q") {}
    function fixtureStore(bytes32 slot, uint256 value) external {
        assembly { sstore(slot, value) }
    }
    function fixtureLoad(bytes32 slot) external view returns (uint256 value) {
        assembly { value := sload(slot) }
    }
}
