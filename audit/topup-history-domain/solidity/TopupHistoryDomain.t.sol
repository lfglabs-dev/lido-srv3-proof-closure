// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;
import {TopupGatewayWitnessBatchTest} from "../../topup-gateway-witness-batch/solidity/TopupGatewayWitnessBatch.t.sol";
import {TopUpGateway} from "contracts/0.8.25/TopUpGateway.sol";
import {TopUpData} from "contracts/common/interfaces/TopUpWitness.sol";

// Diagnostic for the existing uint32 history domain, not an ETH-cap proof.
// Reuses actual public gateway/verifier execution and the explicitly mocked
// oracle/router from #278. No gateway guard or storage write is overridden.
contract TopupHistoryDomainTest is TopupGatewayWitnessBatchTest {
    function atTime(uint256 number) internal returns(TopUpData memory d) {
        uint256 timestamp=1_606_824_023+12*number;
        vm.roll(number); vm.warp(timestamp);
        bytes32 root;
        (d,root)=fixture(bytes32(uint256(7)),32_000_000_000,40_000_000_000,false,false);
        d.beaconRootData.childBlockTimestamp=uint64(timestamp);
        // The independent synthetic header retains slot4096 and opaque state
        // fields; the root mock is not an authenticated consensus history.
        anchor(d,root);
    }
    function test_history_lastRepresentableBlockRejectsRepeat() public {
        TopUpData memory d=atTime(type(uint32).max);
        gateway.topUp(d);
        require(!gateway.isBlockDistancePassed(),"same block rejected within uint32");
        (bool ok,bytes memory why)=address(gateway).call(abi.encodeCall(gateway.topUp,(d)));
        require(!ok && keccak256(why)==keccak256(abi.encodeWithSelector(TopUpGateway.MinBlockDistanceNotMet.selector)),"exact guard");
        require(router.calls()==1,"one committed router call");
    }
    function test_history_firstTruncatingBlockAdmitsRepeat() public {
        TopUpData memory d=atTime(uint256(1)<<32);
        require(gateway.getMinBlockDistance()==1,"positive configured distance");
        gateway.topUp(d);
        require(gateway.getLastTopUpTimestamp()==uint32(block.timestamp),"actual timestamp truncation");
        require(gateway.isBlockDistancePassed(),"last block truncates to zero sentinel");
        gateway.topUp(d);
        require(router.calls()==2,"two committed actual gateway-to-router calls");
    }
    function test_history_nonzeroTruncatedBlockAlsoAdmitsRepeat() public {
        TopUpData memory d=atTime((uint256(1)<<32)+123);
        gateway.topUp(d);
        require(gateway.isBlockDistancePassed(),"full block minus truncated prior exceeds delay");
        gateway.topUp(d);
        require(router.calls()==2,"two committed actual gateway-to-router calls");
    }
}
