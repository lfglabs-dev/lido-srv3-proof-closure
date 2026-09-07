pragma solidity 0.4.24;

import "lido-core/contracts/0.4.24/Lido.sol";

// Fixture-only storage initialization and helper entrypoints. The production
// withdrawDepositableEther and its complete inherited helper bodies are unchanged.
contract LidoHarness is Lido {
    function fixtureStore(bytes32 slot, uint256 value) external {
        assembly { sstore(slot, value) }
    }
    function fixtureLoad(bytes32 slot) external view returns (uint256 value) {
        assembly { value := sload(slot) }
    }
    function fixtureRebalance() external { _updateBufferedEtherAllocation(); }
    function fixtureSetTarget(uint256 target) external { _setDepositsReserveTarget(target); }
}

// Adversarial boundary fixture, not a model of locator/oracle correctness.
// Arbitrary bytes and rejection are selected per actual call selector.
contract CallFixture {
    mapping(bytes4 => bytes) private answers;
    mapping(bytes4 => bool) private rejects;
    function configure(bytes4 selector, bytes answer, bool rejectsCall) external {
        answers[selector] = answer;
        rejects[selector] = rejectsCall;
    }
    function forward(address target, bytes payload) external payable {
        require(target.call.value(msg.value)(payload));
    }
    function () external payable {
        bytes memory answer = answers[msg.sig];
        bool rejected = rejects[msg.sig];
        assembly {
            let ptr := add(answer, 32)
            let size := mload(answer)
            switch rejected
            case 0 { return(ptr, size) }
            default { revert(ptr, size) }
        }
    }
}
