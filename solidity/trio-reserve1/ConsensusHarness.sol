pragma solidity 0.8.9;
import {HashConsensus} from "contracts/0.8.9/oracle/HashConsensus.sol";

contract ConsensusHarness is HashConsensus {
    constructor(uint256 slotsPerEpoch, uint256 secondsPerSlot, uint256 genesisTime,
        address admin, address processor)
        HashConsensus(slotsPerEpoch, secondsPerSlot, genesisTime, 8, 0, admin, processor) {}
    function fixtureStore(bytes32 slot, uint256 value) external {
        assembly { sstore(slot, value) }
    }
    function fixtureFrameSlot() external pure returns (uint256 slot) {
        assembly { slot := _frameConfig.slot }
    }
}

// STATICCALL must reject this actual SSTORE instead of erasing its effects.
contract StaticWriteFixture {
    uint256 public touched;
    function getCurrentFrame() external returns (uint256, uint256) {
        touched = 1;
        return (7, 8);
    }
}
