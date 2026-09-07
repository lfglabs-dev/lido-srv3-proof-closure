pragma solidity 0.8.9;
import {LidoLocator} from "contracts/0.8.9/LidoLocator.sol";

// No callable fixture surfaces: constructor and getters are the pinned source.
contract LocatorHarness is LidoLocator {
    constructor(Config memory config) LidoLocator(config) {}
}
