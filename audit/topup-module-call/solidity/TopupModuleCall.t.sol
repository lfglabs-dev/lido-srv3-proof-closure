// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {SRStorage} from "contracts/0.8.25/sr/SRStorage.sol";
import {IStakingModuleV2} from "contracts/common/interfaces/IStakingModuleV2.sol";
import {ModuleVectors} from "./ModuleVectors.sol";

interface ModuleVm {
    function store(address, bytes32, bytes32) external;
    function deal(address, uint256) external;
}

// Exercises the imported physical getter/interface and the compiler's real
// five-argument CALL/return decoder. This is a callsite harness, not execution
// of StakingRouter's authorization/allocation preamble or beacon continuation.
contract ModuleCallHarness {
    function invoke(uint256 id, uint256 target, bytes[] calldata keys,
        uint256[] calldata indices, uint256[] calldata operators, uint256[] calldata limits)
        external returns (uint256[] memory)
    {
        return IStakingModuleV2(SRStorage.getModuleState(id).config.moduleAddress)
            .allocateDeposits(target, keys, indices, operators, limits);
    }
}

contract RawModule {
    bytes public reply;
    bytes public received;
    uint256 public calls;
    uint256 public value;
    address public caller;
    bool public reject;
    function configure(bytes memory data, bool fail) external { reply=data; reject=fail; }
    fallback() external payable {
        received=msg.data; calls++; value=msg.value; caller=msg.sender;
        bytes memory data=reply;
        if (reject) { assembly { revert(add(data,32),mload(data)) } }
        assembly { return(add(data,32),mload(data)) }
    }
}

contract TopupModuleCallTest {
    ModuleVm constant vm=ModuleVm(address(uint160(uint256(keccak256("hevm cheat code")))));
    bytes32 constant ROOT=0x5648d366b9f342bdcc64be95cdcf5f05da808509be70eaa548a8795901d5d000;
    ModuleCallHarness h=new ModuleCallHarness();
    RawModule m=new RawModule();

    function install(uint256 id, uint96 high) internal {
        vm.store(address(h),keccak256(abi.encode(id,ROOT)),
            bytes32(uint256(uint160(address(m)))|(uint256(high)<<160)));
    }
    function args(uint256 seed, uint256 n) internal pure returns
        (bytes[] memory keys,uint256[] memory indices,uint256[] memory operators,uint256[] memory limits)
    {
        keys=new bytes[](n); indices=new uint256[](n); operators=new uint256[](n); limits=new uint256[](n);
        for(uint256 j;j<n;j++) {
            keys[j]=new bytes(48);
            for(uint256 k;k<48;k++) keys[j][k]=bytes1(uint8(uint256(keccak256(abi.encode(seed,j,k)))));
            indices[j]=uint256(keccak256(abi.encode(seed,j,"index")));
            operators[j]=uint256(keccak256(abi.encode(seed,j,"operator")));
            limits[j]=uint256(keccak256(abi.encode(seed,j,"limit")));
        }
    }
    function testFuzz_actualCallAndReturn(uint256 id,uint256 target,uint256 seed,uint96 high,uint8 count) public {
        uint256 n=uint256(count)%9; install(id,high);
        (bytes[] memory keys,uint256[] memory indices,uint256[] memory operators,uint256[] memory limits)=args(seed,n);
        uint256[] memory reply=new uint256[](n);
        for(uint256 j;j<n;j++) reply[j]=uint256(keccak256(abi.encode(seed,j,"reply")));
        m.configure(bytes.concat(abi.encode(reply),hex"decafbad"),false);
        uint256 previous=m.calls();
        uint256[] memory actual=h.invoke(id,target,keys,indices,operators,limits);
        require(keccak256(abi.encode(actual))==keccak256(abi.encode(reply)),"raw reply order/value");
        require(keccak256(m.received())==keccak256(abi.encodeWithSelector(
            IStakingModuleV2.allocateDeposits.selector,target,keys,indices,operators,limits)),"five argument bytes");
        require(m.calls()==previous+1 && m.value()==0 && m.caller()==address(h),"actual callee effects and zero value");
    }
    function rawCall(bytes memory reply,bool reject) internal returns(bool ok,bytes memory data) {
        install(7,0);m.configure(reply,reject);
        (bytes[] memory keys,uint256[] memory indices,uint256[] memory operators,uint256[] memory limits)=args(1,2);
        return address(h).call(abi.encodeCall(h.invoke,(7,0,keys,indices,operators,limits)));
    }
    function test_zeroTargetStillCallsAndCommits() public {
        uint256[] memory reply=new uint256[](2);
        uint256 old=m.calls(); (bool ok,)=rawCall(abi.encode(reply),false);
        require(ok && m.calls()==old+1,"zero target must execute module");
    }
    function test_malformedReturnRollsBackCalleeEffects() public {
        bytes[6] memory bad=[bytes(hex"010203"),abi.encode(uint256(2**64)),abi.encode(uint256(64),uint256(0)),
            abi.encode(uint256(32),uint256(2**64)),abi.encode(uint256(32),uint256(2),uint256(9)),bytes(new bytes(31))];
        uint256 old=m.calls();
        for(uint256 j;j<bad.length;j++) {
            (bool ok,bytes memory data)=rawCall(bad[j],false);
            require(!ok && m.calls()==old,"decoder failure must roll back callee writes");
            if(j==3) require(keccak256(data)==keccak256(abi.encodeWithSignature("Panic(uint256)",0x41)),"uint64 count guard panic");
        }
    }
    function test_revertBubblesExactBytes() public {
        uint256 old=m.calls(); (bool ok,bytes memory data)=rawCall(hex"deadbeef0102",true);
        require(!ok && keccak256(data)==keccak256(hex"deadbeef0102") && m.calls()==old,"bubble+rollback");
    }
    function test_noncanonicalOffsetsAndTrailingBytes() public {
        (bool ok,bytes memory data)=rawCall(abi.encode(uint256(0)),false);
        require(ok && abi.decode(data,(uint256[])).length==0,"zero offset accepted");
        (ok,data)=rawCall(bytes.concat(abi.encode(uint256(33)),hex"ff",abi.encode(uint256(1),uint256(7))),false);
        uint256[] memory decoded=abi.decode(data,(uint256[]));
        require(ok && decoded.length==1 && decoded[0]==7,"unaligned offset accepted");
    }
    function test_noCodeTarget() public {
        vm.store(address(h),keccak256(abi.encode(uint256(7),ROOT)),bytes32(uint256(0x1234)));
        (bytes[] memory keys,uint256[] memory indices,uint256[] memory operators,uint256[] memory limits)=args(1,1);
        (bool ok,)=address(h).call(abi.encodeCall(h.invoke,(7,0,keys,indices,operators,limits)));
        require(!ok,"missing code rejected");
    }
    function test_memoryAllocationBoundaryRemainsExplicit() public {
        (bool ok,bytes memory data)=rawCall(abi.encode(uint256(32),uint256(2**59)),false);
        require(!ok && keccak256(data)==keccak256(abi.encodeWithSignature("Panic(uint256)",0x41)),
            "compiler allocation panic precedes logical byte-extent rejection");
    }
    function test_exactLeanByteVectors() public {
        install(7,0);
        for(uint256 seed;seed<64;seed++) {
            uint256 n=seed%5;
            bytes[] memory keys=new bytes[](n);
            uint256[] memory indices=new uint256[](n);
            uint256[] memory operators=new uint256[](n);
            uint256[] memory limits=new uint256[](n);
            for(uint256 j;j<n;j++) {
                keys[j]=new bytes(48);
                for(uint256 k;k<48;k++) keys[j][k]=bytes1(uint8(seed*37+j*19+k));
                indices[j]=2**255+seed*11+j;operators[j]=seed*13+j;
                limits[j]=(seed*17+j)*1 gwei;
            }
            (bytes memory expectedPayload,bytes memory expectedReply)=ModuleVectors.get(seed);
            m.configure(expectedReply,false);
            uint256[] memory actual=h.invoke(7,seed*1 gwei,keys,indices,operators,limits);
            require(keccak256(m.received())==keccak256(expectedPayload),"actual calldata vs Lean bytes");
            require(keccak256(abi.encode(actual))==keccak256(abi.encode(indices)),"Lean reply vs compiler decoder");
            require(keccak256(abi.encode(indices))==keccak256(expectedReply),"Lean return encoder vs Solidity");
        }
    }
}
