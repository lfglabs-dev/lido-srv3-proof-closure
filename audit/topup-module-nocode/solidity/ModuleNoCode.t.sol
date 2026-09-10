// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;
import {TopupBatchConsumerTest} from "../../topup-batch-consumer/solidity/TopupBatchConsumer.t.sol";
interface NoCodeVm {
    function etch(address,bytes calldata) external;
    function mockCall(address,bytes calldata,bytes calldata) external;
    function expectCall(address,bytes calldata) external;
}
// Inherits the unchanged pinned router and existing fixture initialization.
// Only preceding module view replies are mocked; allocateDeposits is NOT mocked.
contract ModuleNoCodeTest is TopupBatchConsumerTest {
    event Observed(bool ok,bytes reason);
    NoCodeVm constant check=NoCodeVm(address(uint160(uint256(keccak256("hevm cheat code")))));
    function test_actualPinnedModuleEOACallThenEmptyDecodeRevert() public {
        check.mockCall(address(module),abi.encodeWithSignature("getStakingModuleSummary()"),abi.encode(uint256(0),uint256(1),uint256(0)));
        check.mockCall(address(module),abi.encodeWithSignature("getTotalModuleStake()"),abi.encode(uint256(32 ether)));
        // Clear after mock setup as cheat-code versions may insert code on mock registration.
        check.etch(address(module),"");
        require(address(module).code.length==0,"module must be ordinary no-code");
        (uint256[] memory keys,uint256[] memory operators,bytes[] memory pubkeys,uint256[] memory limits)=args();
        bytes memory expected=abi.encodeCall(module.allocateDeposits,(20 ether,pubkeys,keys,operators,limits));
        check.expectCall(address(module),expected);
        uint256 beforeBalance=address(router).balance;
        (bool ok,bytes memory reason)=invoke();
        emit Observed(ok,reason);
        require(!ok,"empty ABI decode must reject");
        require(address(router).balance==beforeBalance,"router balance changed");
        require(address(module).code.length==0,"module acquired code");
    }
}
