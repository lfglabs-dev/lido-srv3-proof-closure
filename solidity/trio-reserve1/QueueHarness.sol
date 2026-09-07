pragma solidity 0.8.9;
import "lido-core/contracts/0.8.9/WithdrawalQueueBase.sol";

// Exercises the actual pinned unfinalizedStETH body with physical queue storage.
// Bunker behavior remains a boundary fixture until the full queue is composed.
contract QueueHarness is WithdrawalQueueBase {
    bool public bunker;
    function isBunkerModeActive() external view returns (bool) { return bunker; }
    function fixtureBunker(bool value) external { bunker = value; }
    function fixtureStore(bytes32 slot, uint256 value) external {
        assembly { sstore(slot, value) }
    }
    function fixtureEnqueue(uint128 amount, uint128 shares, address owner) external returns (uint256) {
        return _enqueue(amount, shares, owner);
    }
    function fixtureFinalize(uint256 lastId, uint256 amount, uint256 rate) external {
        _finalize(lastId, amount, rate);
    }
}
