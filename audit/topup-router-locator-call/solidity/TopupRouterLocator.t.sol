// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;
import {TopupGatewayWitnessBatchTest, GatewayWitnessHarness, GatewayRouterRecorder} from "audit/topup-gateway-witness-batch/solidity/TopupGatewayWitnessBatch.t.sol";
import {TopUpData} from "contracts/common/interfaces/TopUpWitness.sol";
import {TopUpGateway} from "contracts/0.8.25/TopUpGateway.sol";

// The locator is an arbitrary transport fixture, not a deployed-locator proof.
// Its fallback verifies the actual gateway caller and exact four-byte payload.
contract ExactRouterLocator {
    address public expectedCaller;
    bytes private raw;
    bool private rejectReply;
    function configure(address caller, bytes memory reply, bool rejected) external {
        expectedCaller=caller;raw=reply;rejectReply=rejected;
    }
    fallback() external {
        require(msg.sender==expectedCaller,"wrong gateway caller");
        require(msg.data.length==4 && msg.sig==bytes4(0xef6c064c),"wrong locator payload");
        bytes memory reply=raw;
        if(rejectReply) assembly { revert(add(reply,32),mload(reply)) }
        assembly { return(add(reply,32),mload(reply)) }
    }
}

// Inherits the independent SHA fixture and the unmodified GatewayWitnessHarness.
// No gateway/verifier operation is overridden, and the router remains a recorder.
contract TopupRouterLocatorTest is TopupGatewayWitnessBatchTest {
    function select(bytes memory raw,bool rejected) internal {
        ExactRouterLocator locator=new ExactRouterLocator();
        gateway=new GatewayWitnessHarness(address(locator),32);
        locator.configure(address(gateway),raw,rejected);
    }
    function data() internal returns(TopUpData memory d) {
        bytes32 root;
        (d,root)=fixture(bytes32(uint256(77)),32_000_000_000,40_000_000_000,false,false);
        anchor(d,root);
    }
    function test_locator_exactCallerSelectorAddressConsumed() public {
        GatewayRouterRecorder selected=new GatewayRouterRecorder();selected.setCredentials(WC);
        select(abi.encode(address(selected)),false);
        gateway.topUp(data());
        require(selected.calls()==1 && router.calls()==0,"locator address not consumed");
        require(gateway.getLastTopUpTimestamp()==1000,"positive history");
    }
    function test_locator_trailingBytesIgnored() public {
        select(bytes.concat(abi.encode(address(router)),hex"ff99"),false);
        gateway.topUp(data());
        require(router.calls()==1 && gateway.getLastTopUpTimestamp()==1000,"trailing scalar reply");
    }
    function test_locator_shortReplyRejected() public {
        select(new bytes(31),false);reject(data(),hex"");
    }
    function test_locator_noncanonicalAddressRejected() public {
        select(abi.encode(uint256(uint160(address(router))) | (uint256(1)<<160)),false);
        reject(data(),hex"");
    }
    function test_locator_failureBytesBubble() public {
        select(hex"deadbeef",true);reject(data(),hex"deadbeef");
    }
    function test_locator_ordinaryNoCodeRejected() public {
        gateway=new GatewayWitnessHarness(address(0x123456),32);
        reject(data(),hex"");
    }
    function test_locator_temporalGuardBeforeLookup() public {
        select(hex"deadbeef",true);
        vm.store(address(gateway),0x22e512057841e2bc1e6d80030c8bb8b4935377af2e64ba9bf8e6a3e88fb32200,
            bytes32(uint256(8)|(uint256(101)<<96)|(uint256(1)<<128)|(uint256(100)<<144)|(uint256(64_000_000_000)<<160)));
        reject(data(),abi.encodeWithSignature("Panic(uint256)",0x11));
    }
    function test_locator_lengthsBeforeTimingAndLookup() public {
        select(hex"deadbeef",true);
        vm.store(address(gateway),0x22e512057841e2bc1e6d80030c8bb8b4935377af2e64ba9bf8e6a3e88fb32200,
            bytes32(uint256(8)|(uint256(101)<<96)|(uint256(1)<<128)|(uint256(100)<<144)|(uint256(64_000_000_000)<<160)));
        TopUpData memory d=data();d.pendingBalanceGwei=new uint256[](1);
        reject(d,abi.encodeWithSelector(TopUpGateway.WrongArrayLength.selector));
    }
}
