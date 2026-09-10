// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;
import {CLValidatorVerifier} from "contracts/0.8.25/CLValidatorVerifier.sol";
import {BeaconRootData,ValidatorWitness} from "contracts/common/interfaces/ValidatorWitness.sol";
import {GIndex,pack} from "contracts/common/lib/GIndex.sol";
import {SSZ} from "contracts/common/lib/SSZ.sol";
import {BLS12_381} from "contracts/common/lib/BLS.sol";

interface RootVm {
    function etch(address target,bytes calldata code) external;
    function expectCall(address target,bytes calldata data,uint64 count) external;
}

// Calls the complete unmodified pinned internal source function.
contract SszRootCallHarness is CLValidatorVerifier {
    constructor() CLValidatorVerifier(pack(150<<40,40),pack(150<<40,40),0) {}
    function verify(BeaconRootData calldata b,ValidatorWitness calldata w,uint256 index,bytes32 wc) external view {
        _verifyValidator(b,w,index,wc);
    }
}

// A finite external-interpreter fixture, not the EIP-4788 storage implementation.
// It rejects any non-ABI timestamp payload and exercises actual STATICCALL.
contract RootReplyFixture {
    bytes32 immutable root;
    uint64 immutable timestamp;
    uint8 immutable mode;
    constructor(bytes32 r,uint64 t,uint8 m) {root=r;timestamp=t;mode=m;}
    fallback(bytes calldata data) external returns(bytes memory) {
        require(keccak256(data)==keccak256(abi.encode(timestamp)),"exact timestamp payload");
        if(mode==1) revert("callee rejected");
        if(mode==2) return new bytes(0);
        if(mode==3) return new bytes(31);
        if(mode==4) return abi.encodePacked(root,hex"aabb");
        if(mode==5) { assembly { sstore(0,1) } }
        return abi.encode(root);
    }
}

contract SszRootCallTest {
    RootVm constant vm=RootVm(address(uint160(uint256(keccak256("hevm cheat code")))));
    address constant ROOTS=0x000F3df6D732807Ef1319fB7B8bB8522d0Beac02;
    SszRootCallHarness h=new SszRootCallHarness();
    function chunk(uint64 v) internal pure returns(bytes32 out) {
        for(uint256 i;i<8;i++) out|=bytes32(uint256(uint8(v>>(8*i))))<<(248-8*i);
    }
    function fixture() internal pure returns(BeaconRootData memory b,ValidatorWitness memory w,bytes32 wc,bytes32 root) {
        b=BeaconRootData(0x0102030405060708,123,17);
        w=ValidatorWitness(new bytes32[](50),abi.encodePacked(keccak256("key"),bytes16(keccak256("tail"))),
            32000000000,11,22,33,44,true);
        wc=keccak256("withdrawal credentials");
        bytes32[8] memory nodes=[sha256(abi.encodePacked(w.pubkey,bytes16(0))),wc,chunk(w.effectiveBalance),
            chunk(1),chunk(11),chunk(22),chunk(33),chunk(44)];
        for(uint256 count=8;count>1;count/=2) {
            for(uint256 i;i<count/2;i++) nodes[i]=sha256(abi.encodePacked(nodes[2*i],nodes[2*i+1]));
        }
        for(uint256 i;i<50;i++) w.proofValidator[i]=keccak256(abi.encode("sibling",i));
        w.proofValidator[48]=sha256(abi.encodePacked(chunk(b.slot),chunk(b.proposerIndex)));
        uint256 index=(11<<47)+(150<<40)-(1<<47);
        root=nodes[0];
        for(uint256 i;i<50;i++) {
            root=index%2==0 ? sha256(abi.encodePacked(root,w.proofValidator[i])) : sha256(abi.encodePacked(w.proofValidator[i],root));
            index/=2;
        }
        require(index==1,"reference full depth");
    }
    function install(bytes32 root,uint64 timestamp,uint8 mode) internal {
        RootReplyFixture responder=new RootReplyFixture(root,timestamp,mode);
        vm.etch(ROOTS,address(responder).code);
    }
    function reject(BeaconRootData memory b,ValidatorWitness memory w,uint256 index,bytes32 wc,bytes memory expected) internal view {
        (bool ok,bytes memory why)=address(h).staticcall(abi.encodeCall(h.verify,(b,w,index,wc)));
        require(!ok && keccak256(why)==keccak256(expected),"source rejection bytes/order");
    }
    function test_realRootCallFeedsFullVerifier() public {
        (BeaconRootData memory b,ValidatorWitness memory w,bytes32 wc,bytes32 root)=fixture();
        install(root,b.childBlockTimestamp,0);
        vm.expectCall(ROOTS,abi.encode(b.childBlockTimestamp),1);
        h.verify(b,w,0,wc);
    }
    function test_onlyReturnedRootMutationFailsProof() public {
        (BeaconRootData memory b,ValidatorWitness memory w,bytes32 wc,bytes32 root)=fixture();
        install(root^bytes32(uint256(1)),b.childBlockTimestamp,0);
        reject(b,w,0,wc,abi.encodeWithSelector(SSZ.InvalidProof.selector));
    }
    function test_trailingRootBytesAccepted() public {
        (BeaconRootData memory b,ValidatorWitness memory w,bytes32 wc,bytes32 root)=fixture();
        install(root,b.childBlockTimestamp,4);h.verify(b,w,0,wc);
    }
    function test_invalidSlotBeforeRejectedRoot() public {
        (BeaconRootData memory b,ValidatorWitness memory w,bytes32 wc,bytes32 root)=fixture();
        install(root,b.childBlockTimestamp,1);w.proofValidator[48]^=bytes32(uint256(1));
        reject(b,w,0,wc,abi.encodeWithSelector(CLValidatorVerifier.InvalidSlot.selector));
    }
    function test_rootRejectionBeforeIndexAndLeaf() public {
        (BeaconRootData memory b,ValidatorWitness memory w,bytes32 wc,bytes32 root)=fixture();
        install(root,b.childBlockTimestamp,1);w.pubkey=new bytes(0);
        reject(b,w,1<<40,wc,abi.encodeWithSelector(CLValidatorVerifier.RootNotFound.selector));
    }
    function test_emptyReplyRootNotFound() public {
        (BeaconRootData memory b,ValidatorWitness memory w,bytes32 wc,bytes32 root)=fixture();
        install(root,b.childBlockTimestamp,2);
        reject(b,w,0,wc,abi.encodeWithSelector(CLValidatorVerifier.RootNotFound.selector));
    }
    function test_shortReplyAbiFailureBeforeIndex() public {
        (BeaconRootData memory b,ValidatorWitness memory w,bytes32 wc,bytes32 root)=fixture();
        install(root,b.childBlockTimestamp,3);
        reject(b,w,1<<40,wc,hex"");
    }
    function test_staticWriteRejected() public {
        (BeaconRootData memory b,ValidatorWitness memory w,bytes32 wc,bytes32 root)=fixture();
        install(root,b.childBlockTimestamp,5);
        reject(b,w,0,wc,abi.encodeWithSelector(CLValidatorVerifier.RootNotFound.selector));
    }
    function test_noCodeSuccessEmptyRootNotFound() public {
        (BeaconRootData memory b,ValidatorWitness memory w,bytes32 wc,)=fixture();
        vm.etch(ROOTS,hex"");
        reject(b,w,0,wc,abi.encodeWithSelector(CLValidatorVerifier.RootNotFound.selector));
    }
}
