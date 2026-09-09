// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;
import {BLS12_381} from "contracts/common/lib/BLS.sol";
import {SSZ} from "contracts/common/lib/SSZ.sol";
import {pack} from "contracts/common/lib/GIndex.sol";

interface ShaVm {
    function mockCall(address,bytes calldata,bytes calldata) external;
    function mockCallRevert(address,bytes calldata,bytes calldata) external;
    function clearMockedCalls() external;
}
contract ShaSourceHarness {
    function pubkey(bytes calldata key) external view returns(bytes32) { return BLS12_381.pubkeyRoot(key); }
    function hashPair(bytes32 a,bytes32 b) external view returns(bytes32) { return BLS12_381.sha256Pair(a,b); }
    function verify(bytes32[] calldata siblings,bytes32 expected,bytes32 leaf) external view { SSZ.verifyProof(siblings,expected,leaf,pack(2,1)); }
    // Separate generic output-buffer fixture using actual identity precompile4.
    // This duplicates a CALL shape, not a BLS source function or SHA implementation.
    function identity(bytes calldata input,bytes32 dirty0,bytes32 dirty1)
        external view returns(bool flag,uint256 size,bytes32 first,bytes32 second)
    {
        assembly {
            mstore(0,dirty0)
            mstore(32,dirty1)
            // Supply identity's input away from the observed output scratch region.
            let p:=mload(64)
            calldatacopy(p,input.offset,input.length)
            flag:=staticcall(gas(),4,p,input.length,0,32)
            size:=returndatasize()
            first:=mload(0)
            second:=mload(32)
        }
    }
}
contract SszShaCallMemoryTest {
    ShaVm constant vm=ShaVm(address(uint160(uint256(keccak256("hevm cheat code")))));
    ShaSourceHarness h=new ShaSourceHarness();
    function bytesOf(bytes32 a,bytes32 b,uint256 count) internal pure returns(bytes memory out) {
        bytes memory all=abi.encodePacked(a,b);out=new bytes(count);
        for(uint256 i;i<count;i++)out[i]=all[i];
    }
    function overwrite(bytes32 initial,bytes memory reply) internal pure returns(bytes32 out) {
        bytes memory bytes_=abi.encodePacked(initial);
        for(uint256 i;i<reply.length&&i<32;i++)bytes_[i]=reply[i];
        assembly {out:=mload(add(bytes_,32))}
    }
    function requireShaResult(bool ok,bytes memory result,uint256 size,bytes32 expected) internal pure {
        if(size==32)require(ok&&abi.decode(result,(bytes32))==expected,"full return/mload");
        else require(!ok&&keccak256(result)==keccak256(hex"dd5cab3e"),"BLS exact-size guard");
    }
    function testFuzz_actualBlsSizeGuardAndSszResidualBytes(bytes32 a,bytes32 b,bytes32 replyA,bytes32 replyB,uint8 sizeSeed) public {
        uint256 size=uint256(sizeSeed)%65;
        bytes memory reply=bytesOf(replyA,replyB,size);
        bytes memory input=abi.encodePacked(a,b);
        vm.mockCall(address(2),input,reply);
        (bool ok,bytes memory result)=address(h).staticcall(abi.encodeCall(h.hashPair,(a,b)));
        requireShaResult(ok,result,size,replyA);
        bytes32[] memory branch=new bytes32[](1);branch[0]=b;
        bytes32 residual=overwrite(a,reply);
        h.verify(branch,residual,a);
        (ok,result)=address(h).staticcall(abi.encodeCall(h.verify,(branch,residual^bytes32(uint256(1)),a)));
        require(!ok&&keccak256(result)==keccak256(hex"09bde339"),"SSZ final comparison");
        vm.clearMockedCalls();

        bytes memory key=abi.encodePacked(a,bytes16(b));
        vm.mockCall(address(2),abi.encodePacked(key,bytes16(0)),reply);
        (ok,result)=address(h).staticcall(abi.encodeCall(h.pubkey,(key)));
        requireShaResult(ok,result,size,replyA);
        vm.clearMockedCalls();
    }
    function testFuzz_actualIdentityOutputCopy(bytes32 a,bytes32 b,bytes32 dirty0,bytes32 dirty1,uint8 sizeSeed) public view {
        uint256 size=uint256(sizeSeed)%65;bytes memory input=bytesOf(a,b,size);
        (bool flag,uint256 returned,bytes32 first,bytes32 second)=h.identity(input,dirty0,dirty1);
        require(flag&&returned==size&&first==overwrite(dirty0,input)&&second==dirty1,"identity copy/frame");
    }
    function test_failureFlagsUseDifferentSourceReverts() public {
        bytes32 a=bytes32(uint256(123));bytes32 b=bytes32(uint256(456));
        vm.mockCallRevert(address(2),abi.encodePacked(a,b),hex"abcdef");
        (bool ok,bytes memory result)=address(h).staticcall(abi.encodeCall(h.hashPair,(a,b)));
        require(!ok&&keccak256(result)==keccak256(hex"dd5cab3e"),"BLS flag rejection");
        bytes32[] memory branch=new bytes32[](1);branch[0]=b;
        (ok,result)=address(h).staticcall(abi.encodeCall(h.verify,(branch,bytes32(0),a)));
        require(!ok&&result.length==0,"SSZ flag rejection");vm.clearMockedCalls();
    }
    function test_unmodifiedRealShaOverlap() public view {
        bytes32 a=keccak256("left");bytes32 b=keccak256("right");
        require(h.hashPair(a,b)==sha256(abi.encodePacked(a,b)),"real pair SHA");
        bytes memory key=abi.encodePacked(a,bytes16(b));
        require(h.pubkey(key)==sha256(abi.encodePacked(key,bytes16(0))),"real pubkey SHA");
    }
}
