// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;
import {DepositModuleVectors} from "./DepositModuleVectors.sol";
import {SRStorage} from "contracts/0.8.25/sr/SRStorage.sol";
import {IStakingModule} from "contracts/common/interfaces/IStakingModule.sol";

// Source-shaped bounded callsite; allocation/admission precede this harness.
contract DepositModuleCallHarness {
    error ZeroDeposits();
    error WrongPubkeyLength();
    error ModuleReturnExceedTarget();
    event StakingRouterETHDeposited(uint256 indexed stakingModuleId, uint256 amount);
    function invoke(uint256 id, uint256 selected, uint256 maxEB, bytes calldata data)
        external returns(bytes memory keys, bytes memory sigs)
    {
        address moduleAddress = SRStorage.getModuleState(id).config.moduleAddress;
        uint256 cap = SRStorage.getModuleState(id).deposits.maxDepositsPerBlock;
        uint256 target = selected / maxEB;
        if(cap < target) target=cap;
        if(target==0) revert ZeroDeposits();
        (keys,sigs)=IStakingModule(moduleAddress).obtainDepositData(target,data);
        if(keys.length%48!=0) revert WrongPubkeyLength();
        uint256 actual=keys.length/48;
        if(actual>target) revert ModuleReturnExceedTarget();
        uint256 depositsValue=actual*maxEB;
        SRStorage.getModuleState(id).deposits.lastDepositAt=uint64(block.timestamp);
        SRStorage.getModuleState(id).deposits.lastDepositBlock=uint64(block.number);
        emit StakingRouterETHDeposited(id,depositsValue);
    }
    // Isolate compiler ABI behavior from subsequent pubkey guards.
    function decodeCall(address target, uint256 count, bytes calldata data)
        external returns(bytes memory,bytes memory)
    { return IStakingModule(target).obtainDepositData(count,data); }
}

interface DepositVm {
    function store(address, bytes32, bytes32) external;
    function load(address, bytes32) external view returns(bytes32);
}
contract DepositRawModule {
    bytes public reply;
    bytes public received;
    uint256 public calls;
    uint256 public value;
    address public caller;
    bool public reject;
    function configure(bytes memory r,bool fail) external {reply=r;reject=fail;}
    fallback() external payable {
        received=msg.data; calls++;value=msg.value;caller=msg.sender;
        bytes memory data=reply;
        if(reject) {assembly {revert(add(data,32),mload(data))}}
        assembly {return(add(data,32),mload(data))}
    }
}
contract DepositModuleCallTest {
    DepositVm constant vm=DepositVm(address(uint160(uint256(keccak256("hevm cheat code")))));
    bytes32 constant ROOT=0x5648d366b9f342bdcc64be95cdcf5f05da808509be70eaa548a8795901d5d000;
    DepositModuleCallHarness h=new DepositModuleCallHarness();
    DepositRawModule m=new DepositRawModule();
    function install(uint256 id,uint64 cap) internal returns(bytes32 slot) {
        slot=keccak256(abi.encode(id,ROOT));
        vm.store(address(h),slot,bytes32(uint256(uint160(address(m)))|(uint256(0x1234567890)<<160)));
        vm.store(address(h),bytes32(uint256(slot)+1),bytes32(uint256(7)|(uint256(8)<<64)|(uint256(cap)<<128)|(uint256(99)<<192)));
    }
    function raw(bytes memory r) internal returns(bool ok,bytes memory data) {
        m.configure(r,false);
        return address(h).call(abi.encodeCall(h.decodeCall,(address(m),3,hex"123456")));
    }
    function scalarAllocator(uint256 cursor,uint256 size) external pure returns(uint256 next) {
        assembly {
            next := add(cursor,and(add(size,31),not(31)))
            if or(gt(next,0xffffffffffffffff),lt(next,cursor)) {
                mstore(0,shl(224,0x4e487b71)) mstore(4,0x41) revert(0,36)
            }
        }
    }
    function scalarHead(uint256 base,uint256 size) external pure returns(bool accepted) {
        assembly { accepted := iszero(slt(sub(add(base,size),base),64)) }
    }
    function test_scalarMemoryProjectionWrapAndSignedGuards() public {
        require(this.scalarAllocator(128,type(uint256).max)==128,"rounded size wraps");
        require(!this.scalarHead(128,type(uint256).max),"signed head rejects near-modulus size");
        require(!this.scalarHead(128,2**255),"signed head rejects high bit");
        require(this.scalarHead(128,64),"ordinary head");
        (bool ok,bytes memory r)=address(this).call(abi.encodeCall(this.scalarAllocator,(2**64-32,64)));
        require(!ok&&keccak256(r)==keccak256(abi.encodeWithSignature("Panic(uint256)",0x41)),"pointer ceiling");
        (ok,r)=address(this).call(abi.encodeCall(this.scalarAllocator,(type(uint256).max,32)));
        require(!ok&&keccak256(r)==keccak256(abi.encodeWithSignature("Panic(uint256)",0x41)),"pointer wrap");
    }
    function test_selectorLiteral() public pure {
        require(IStakingModule.obtainDepositData.selector==bytes4(keccak256("obtainDepositData(uint256,bytes)")));
    }
    function testFuzz_payloadAndReturn(uint256 count, bytes memory data, bytes memory keys, bytes memory sigs) public {
        m.configure(bytes.concat(abi.encode(keys,sigs),hex"ffee"),false);
        (bytes memory k,bytes memory s)=h.decodeCall(address(m),count,data);
        require(keccak256(k)==keccak256(keys)&&keccak256(s)==keccak256(sigs),"reply order/data");
        require(keccak256(m.received())==keccak256(abi.encodeWithSelector(IStakingModule.obtainDepositData.selector,count,data)),"payload");
        require(m.value()==0&&m.caller()==address(h),"actual zero CALL");
    }
    function test_noncanonicalDualBytes() public {
        // Both offsets alias the first head word; zero length is legal.
        (bool ok,bytes memory r)=raw(abi.encode(uint256(0),uint256(0)));
        require(ok,"head alias");
        (bytes memory k,bytes memory s)=abi.decode(r,(bytes,bytes));require(k.length==0&&s.length==0);
        // Unaligned offsets, reversed tails, unpadded final tail and trailing garbage.
        (ok,r)=raw(bytes.concat(abi.encode(uint256(100),uint256(65)),hex"ff",abi.encode(uint256(3)),hex"aabbcc",abi.encode(uint256(2)),hex"ddee"));
        require(ok,"noncanonical");(k,s)=abi.decode(r,(bytes,bytes));
        require(keccak256(k)==keccak256(hex"ddee")&&keccak256(s)==keccak256(hex"aabbcc"),"raw ordering");
    }
    function test_decoderFaultOrderAndRollback() public {
        bytes[7] memory bad=[bytes(hex"010203"),abi.encode(uint256(2**64),uint256(0)),
            abi.encode(uint256(64),uint256(0)),abi.encode(uint256(64),uint256(2**64),uint256(2**64)),
            abi.encode(uint256(64),uint256(0),uint256(2**64-1)),
            abi.encode(uint256(64),uint256(0),uint256(1)),
            abi.encode(uint256(0),uint256(2**64))];
        uint256 old=m.calls();
        for(uint256 j;j<bad.length;j++) {
            (bool ok,bytes memory r)=raw(bad[j]);require(!ok&&m.calls()==old,"reject+rollback");
            if(j==3||j==4) require(keccak256(r)==keccak256(abi.encodeWithSignature("Panic(uint256)",0x41)),"first decode allocation precedes second offset");
            else require(r.length==0,"empty bounds failure");
        }
    }
    function test_noCodeEmptyDecodeAndExactBubble() public {
        (bool ok,bytes memory r)=address(h).call(abi.encodeCall(h.decodeCall,(address(0x1234),1,bytes(""))));
        require(!ok&&r.length==0,"no code empty decode");
        m.configure(hex"deadbeef1234",true);
        (ok,r)=address(h).call(abi.encodeCall(h.decodeCall,(address(m),1,bytes(""))));
        require(!ok&&keccak256(r)==keccak256(hex"deadbeef1234"),"bubble");
    }
    function test_64ActualLeanByteVectors() public {
        for(uint256 seed;seed<64;seed++) {
            bytes memory data=new bytes(seed%35);
            bytes memory keys=new bytes(seed%4*48);
            bytes memory sigs=new bytes(seed%3*96);
            for(uint256 j;j<data.length;j++) data[j]=bytes1(uint8(seed*13+j));
            for(uint256 j;j<keys.length;j++) keys[j]=bytes1(uint8(seed*37+j));
            for(uint256 j;j<sigs.length;j++) sigs[j]=bytes1(uint8(seed*19+j));
            (bytes memory expectedPayload,bytes memory expectedReply)=DepositModuleVectors.get(seed);
            m.configure(expectedReply,false);
            (bytes memory actualKeys,bytes memory actualSigs)=h.decodeCall(address(m),2**255+seed*17,data);
            require(keccak256(m.received())==keccak256(expectedPayload),"Lean calldata vs compiler");
            require(keccak256(abi.encode(keys,sigs))==keccak256(expectedReply),"Lean return vs compiler");
            require(keccak256(keys)==keccak256(actualKeys)&&keccak256(sigs)==keccak256(actualSigs),"actual compiler decode");
        }
    }
    function test_targetCapShorterZeroAndGuards() public {
        bytes32 slot=install(7,3);m.configure(abi.encode(new bytes(48),new bytes(96)),false);
        h.invoke(7,20*32 ether,32 ether,hex"aabb");
        require(keccak256(m.received())==keccak256(abi.encodeWithSelector(IStakingModule.obtainDepositData.selector,uint256(3),hex"aabb")),"physical cap");
        uint256 packed=uint256(vm.load(address(h),bytes32(uint256(slot)+1)));
        require(uint64(packed)==uint64(block.timestamp)&&uint64(packed>>64)==uint64(block.number)&&uint64(packed>>128)==3&&uint64(packed>>192)==99,"packed metadata");
        m.configure(abi.encode(bytes(""),hex"12"),false);uint256 old=m.calls();h.invoke(7,32 ether,32 ether,hex"");require(m.calls()==old+1,"zero returned keys commits");
        m.configure(abi.encode(new bytes(96),new bytes(192)),false);old=m.calls();
        (bool ok,bytes memory r)=address(h).call(abi.encodeCall(h.invoke,(7,32 ether,32 ether,bytes(""))));
        require(!ok&&bytes4(r)==DepositModuleCallHarness.ModuleReturnExceedTarget.selector&&m.calls()==old,"over target rollback");
        m.configure(abi.encode(new bytes(49),bytes("")),false);
        (ok,r)=address(h).call(abi.encodeCall(h.invoke,(7,32 ether,32 ether,bytes(""))));
        require(!ok&&bytes4(r)==DepositModuleCallHarness.WrongPubkeyLength.selector,"alignment");
        (ok,r)=address(h).call(abi.encodeCall(h.invoke,(7,0,32 ether,bytes(""))));
        require(!ok&&bytes4(r)==DepositModuleCallHarness.ZeroDeposits.selector&&m.calls()==old,"zero target no CALL");
    }
}
