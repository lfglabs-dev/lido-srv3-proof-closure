// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;
import {TopupGatewayWitnessBatchTest} from "audit/topup-gateway-witness-batch/solidity/TopupGatewayWitnessBatch.t.sol";
import {TopUpData} from "contracts/common/interfaces/TopUpWitness.sol";
import {TopUpGateway} from "contracts/0.8.25/TopUpGateway.sol";
contract TopupEntryAdmissionTest is TopupGatewayWitnessBatchTest {
    bytes32 constant ACCESS=0x02dd7bc7dec4dceedda775e58dd541e08a116c6c53815c0bd028192f7b626800;
    bytes32 constant RESUME=0xe8b012900cb200ee5dfc3b895a32791b67d12891b09f117814f167a237783a02;
    function memberSlot(address who) internal pure returns(bytes32) {
        return keccak256(abi.encode(who,keccak256(abi.encode(keccak256("TOP_UP_ROLE"),ACCESS))));
    }
    function denial() internal view returns(bytes memory) {return abi.encodeWithSignature("AccessControlUnauthorizedAccount(address,bytes32)",address(this),keccak256("TOP_UP_ROLE"));}
    function validData() internal returns(TopUpData memory d) {
        bytes32 root;(d,root)=fixture(bytes32(uint256(77)),32_000_000_000,40_000_000_000,false,false);anchor(d,root);
    }
    function test_entry_roleBeforePauseAndLengths() public {
        vm.store(address(gateway),memberSlot(address(this)),bytes32(0));
        vm.store(address(gateway),RESUME,bytes32(type(uint256).max));
        TopUpData memory d;reject(d,denial());
    }
    function test_entry_highBitsDoNotGrantRole() public {
        vm.store(address(gateway),memberSlot(address(this)),bytes32(uint256(1)<<255));
        reject(validData(),denial());
    }
    function test_entry_noncanonicalLowByteAccepted() public {
        vm.store(address(gateway),memberSlot(address(this)),bytes32((uint256(1)<<255)|2));
        gateway.topUp(validData());require(router.calls()==1 && gateway.getLastTopUpTimestamp()==1000,"complete suffix missing");
    }
    function test_entry_pauseBeforeLengths() public {
        vm.store(address(gateway),RESUME,bytes32(uint256(1001)));
        TopUpData memory d;reject(d,abi.encodeWithSignature("ResumedExpected()"));
    }
    function test_entry_resumeEquality() public {
        vm.store(address(gateway),RESUME,bytes32(uint256(1000)));
        gateway.topUp(validData());require(router.calls()==1,"equality must resume");
    }
    function test_entry_fullWidthPause() public {
        vm.store(address(gateway),RESUME,bytes32((uint256(1)<<255)|1));
        reject(validData(),abi.encodeWithSignature("ResumedExpected()"));
    }
    function test_entry_wrongCallerMappingNotUsed() public {
        vm.store(address(gateway),memberSlot(address(this)),bytes32(0));
        vm.store(address(gateway),memberSlot(address(11)),bytes32(uint256(1)));
        reject(validData(),denial());
    }
    function testFuzz_entry_rawRoleAndResume(uint256 roleWord,uint256 resume) public {
        vm.store(address(gateway),memberSlot(address(this)),bytes32(roleWord));
        vm.store(address(gateway),RESUME,bytes32(resume));
        TopUpData memory d;
        if(uint8(roleWord)==0) reject(d,denial());
        else if(1000<resume) reject(d,abi.encodeWithSignature("ResumedExpected()"));
        else reject(d,abi.encodeWithSelector(TopUpGateway.WrongArrayLength.selector));
    }
}
