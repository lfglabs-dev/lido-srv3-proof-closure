// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {CLValidatorVerifier} from "../../lido-core/contracts/0.8.25/CLValidatorVerifier.sol";
import {ValidatorWitness, BeaconRootData} from "../../lido-core/contracts/common/interfaces/ValidatorWitness.sol";
import {BLS12_381} from "../../lido-core/contracts/common/lib/BLS.sol";
import {SSZ} from "../../lido-core/contracts/common/lib/SSZ.sol";
import {pack, IndexOutOfRange} from "../../lido-core/contracts/common/lib/GIndex.sol";

interface EntryVm {
    function mockCall(address target, bytes calldata payload, bytes calldata reply) external;
    function mockCallRevert(address target, bytes calldata payload, bytes calldata reply) external;
    function clearMockedCalls() external;
}

contract SszVerifierEntryHarness is CLValidatorVerifier {
    constructor() CLValidatorVerifier(pack(150 * (1 << 40), 40), pack(150 * (1 << 40), 40), 0) {}
    function verify(BeaconRootData calldata b, ValidatorWitness calldata w, uint256 i, bytes32 wc) external view {
        _verifyValidator(b, w, i, wc);
    }
    function parent(uint64 timestamp) external view returns (bytes32) { return _getParentBlockRoot(timestamp); }
}

contract SszVerifierEntryTest {
    EntryVm constant vm = EntryVm(address(uint160(uint256(keccak256("hevm cheat code")))));
    SszVerifierEntryHarness harness = new SszVerifierEntryHarness();
    address constant ROOTS = 0x000F3df6D732807Ef1319fB7B8bB8522d0Beac02;

    function chunk(uint64 n) internal pure returns (bytes32 out) {
        for (uint256 i; i < 8; i++) out |= bytes32(uint256(uint8(n >> (i*8))) << (248-i*8));
    }
    function leaf(ValidatorWitness memory w, bytes32 wc) internal pure returns (bytes32) {
        bytes32[8] memory level = [sha256(abi.encodePacked(w.pubkey,bytes16(0))), wc,
            chunk(w.effectiveBalance), chunk(w.slashed ? 1 : 0), chunk(w.activationEligibilityEpoch),
            chunk(w.activationEpoch),chunk(w.exitEpoch),chunk(w.withdrawableEpoch)];
        for (uint256 n=8; n>1; n/=2)
            for (uint256 i; i<n/2; i++) level[i]=sha256(abi.encodePacked(level[2*i],level[2*i+1]));
        return level[0];
    }
    // Arbitrary sibling fixture with the required slot/proposer sibling. The
    // mocked anchor is explicitly constructed from it, not authenticated CL state.
    function fixture(BeaconRootData memory b, uint40 offset, bytes32 wc, bytes32 seed)
        internal pure returns (ValidatorWitness memory w, bytes32 root) {
        w = ValidatorWitness(new bytes32[](50),abi.encodePacked(seed,bytes16(seed)),32e9,1,2,3,4,false);
        for (uint256 i; i<50; i++) w.proofValidator[i]=keccak256(abi.encode(seed,i));
        w.proofValidator[48]=sha256(abi.encodePacked(chunk(b.slot),chunk(b.proposerIndex)));
        root=leaf(w,wc);
        uint256 index=1430*(1<<40)+uint256(offset);
        for (uint256 i; i<50; i++) {
            root = index%2==0 ? sha256(abi.encodePacked(root,w.proofValidator[i])) : sha256(abi.encodePacked(w.proofValidator[i],root));
            index/=2;
        }
        require(index==1,"fixture index");
    }
    function failure(BeaconRootData memory b, ValidatorWitness memory w, uint256 i, bytes32 wc)
        internal view returns (bytes memory) {
        try harness.verify(b,w,i,wc) { revert("unexpected admission"); }
        catch (bytes memory reason) { return reason; }
    }
    function isError(bytes memory actual, bytes4 expected) internal pure {
        require(keccak256(actual)==keccak256(abi.encodeWithSelector(expected)),"wrong ordered error");
    }
    function testFuzz_fullEntryUsesTimestampRootAndWitness(uint64 timestamp,uint64 slot,uint64 proposer,uint40 offset,bytes32 wc,bytes32 seed) public {
        BeaconRootData memory b=BeaconRootData(timestamp,slot,proposer);
        (ValidatorWitness memory w,bytes32 root)=fixture(b,offset,wc,seed);
        vm.mockCall(ROOTS,abi.encode(timestamp),abi.encodePacked(root));
        harness.verify(b,w,offset,wc);
        // A distinct timestamp has no mocked response; the actual lookup fails.
        b.childBlockTimestamp=timestamp^1;
        isError(failure(b,w,offset,wc),CLValidatorVerifier.RootNotFound.selector);
        b.childBlockTimestamp=timestamp;
        vm.mockCall(ROOTS,abi.encode(timestamp),abi.encodePacked(bytes32(uint256(root)^1)));
        isError(failure(b,w,offset,wc),SSZ.InvalidProof.selector);
    }
    function testFuzz_rootReturnWidths(uint64 timestamp,bytes32 root,uint8 size) public {
        bytes memory data=new bytes(size);
        for (uint256 i; i<size; i++) data[i]=i<32 ? root[i] : bytes1(uint8(i));
        vm.mockCall(ROOTS,abi.encode(timestamp),data);
        if(size>=32) require(harness.parent(timestamp)==root,"root decode/trailing bytes");
        else {
            try harness.parent(timestamp) returns(bytes32) { revert("short response admitted"); }
            catch(bytes memory reason) {
                if(size==0) isError(reason,CLValidatorVerifier.RootNotFound.selector);
                else require(reason.length==0,"short ABI decoder revert");
            }
        }
    }
    function test_sourceFailureOrder() public {
        BeaconRootData memory b=BeaconRootData(0x0102030405060708,9,10);
        (ValidatorWitness memory w,bytes32 root)=fixture(b,0,0,bytes32(uint256(1)));
        vm.mockCallRevert(ROOTS,abi.encode(b.childBlockTimestamp),hex"1234");
        w.proofValidator[48]=bytes32(0);
        isError(failure(b,w,type(uint256).max,0),CLValidatorVerifier.InvalidSlot.selector);
        w.proofValidator[48]=sha256(abi.encodePacked(chunk(b.slot),chunk(b.proposerIndex)));
        w.pubkey=new bytes(47);
        isError(failure(b,w,type(uint256).max,0),CLValidatorVerifier.RootNotFound.selector);
        vm.clearMockedCalls();
        vm.mockCall(ROOTS,abi.encode(b.childBlockTimestamp),hex"01");
        require(failure(b,w,type(uint256).max,0).length==0,"root decoding before index and key");
        vm.mockCall(ROOTS,abi.encode(b.childBlockTimestamp),abi.encode(root));
        isError(failure(b,w,type(uint256).max,0),IndexOutOfRange.selector);
        isError(failure(b,w,0,0),BLS12_381.InvalidPubkeyLength.selector);
        w.proofValidator=new bytes32[](1);
        require(keccak256(failure(b,w,0,0))==keccak256(abi.encodeWithSignature("Panic(uint256)",0x11)),"slot subtraction first");
    }
    function test_rootReturnBoundaryWidths() public {
        uint8[6] memory sizes=[uint8(0),1,31,32,33,255];
        for(uint256 i;i<sizes.length;i++) testFuzz_rootReturnWidths(type(uint64).max,bytes32(type(uint256).max),sizes[i]);
    }
}
