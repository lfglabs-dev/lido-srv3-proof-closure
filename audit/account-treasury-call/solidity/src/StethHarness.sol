pragma solidity 0.4.24;
import {StETH} from "contracts/0.4.24/StETH.sol";
// Setup/virtual rate overrides only; inherited transferShares/_transferShares
// and event conversion are unmodified pinned source.
contract StethHarness is StETH {
    uint256 internal rateNumerator;
    constructor() public { _resume(); rateNumerator = 100; }
    function _getTotalPooledEther() internal view returns (uint256) { return rateNumerator; }
    function _getShareRateDenominator() internal view returns (uint256) {
        bytes32 pos = TOTAL_SHARES_POSITION_LOW128;
        uint256 packed;
        assembly { packed := sload(pos) }
        return _getTotalShares() - (packed >> 128);
    }
    function setRate(uint256 value) external { rateNumerator = value; }
    function setPacked(uint256 value) external {
        bytes32 pos = TOTAL_SHARES_POSITION_LOW128;
        assembly { sstore(pos,value) }
    }
    function getPacked() external view returns (uint256 packed) {
        bytes32 pos = TOTAL_SHARES_POSITION_LOW128;
        assembly { packed := sload(pos) }
    }
    // Fixture setup of private StETH mapping at slot0; runtime sharesOf
    // assertions verify the setup. No formal mapping-layout claim is added.
    function setShares(address holder, uint256 value) external {
        assembly { mstore(0,holder) mstore(32,0) sstore(keccak256(0,64),value) }
    }
    function setStopped() external { _stop(); }
    function mintSetup(address recipient, uint256 amount) external {
        _mintShares(recipient,amount);
        _emitTransferAfterMintingShares(recipient,amount);
    }
}
