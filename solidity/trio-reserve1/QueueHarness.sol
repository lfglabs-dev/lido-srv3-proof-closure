pragma solidity 0.8.9;
import "lido-core/contracts/0.8.9/WithdrawalQueue.sol";

contract WstETHFixture {
    function stETH() external view returns (address) { return address(this); }
}

// Exercises the actual pinned unfinalizedStETH body with physical queue storage.
// Inherits the actual bunker getter too; initialization bypasses production ACL.
contract QueueHarness is WithdrawalQueue {
    using UnstructuredStorage for bytes32;
    constructor() WithdrawalQueue(IWstETH(address(new WstETHFixture()))) {
        BUNKER_MODE_SINCE_TIMESTAMP_POSITION.setStorageUint256(type(uint256).max);
    }
    event Transfer(address indexed from, address indexed to, uint256 indexed id);
    function _emitTransfer(address from, address to, uint256 id) internal override {
        emit Transfer(from, to, id);
    }
    function fixtureBunker(bool value) external {
        BUNKER_MODE_SINCE_TIMESTAMP_POSITION.setStorageUint256(value ? 0 : type(uint256).max);
    }
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
