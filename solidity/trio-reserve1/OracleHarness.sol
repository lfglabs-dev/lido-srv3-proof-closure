pragma solidity 0.8.9;
import {AccountingOracle} from "contracts/0.8.9/oracle/AccountingOracle.sol";

contract OracleHarness is AccountingOracle {
    constructor(address locator, uint256 secondsPerSlot, uint256 genesisTime)
        AccountingOracle(locator, secondsPerSlot, genesisTime) {}
    // Raw test setup bypasses production consensus-contract setter admission.
    function fixtureStore(bytes32 slot, uint256 value) external {
        assembly { sstore(slot, value) }
    }
}
