// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;
import {CLValidatorVerifier} from "contracts/0.8.25/CLValidatorVerifier.sol";
import {ValidatorWitness} from "contracts/common/interfaces/ValidatorWitness.sol";
import {SSZ} from "contracts/common/lib/SSZ.sol";
import {BLS12_381} from "contracts/common/lib/BLS.sol";
import {GIndex, pack} from "contracts/common/lib/GIndex.sol";

interface CompositionVm {
    function mockCall(address, bytes calldata, bytes calldata) external;
    function mockCallRevert(address, bytes calldata, bytes calldata) external;
    function clearMockedCalls() external;
}

// Exposes the unmodified leaf -> verifier suffix of _verifyValidator.
// Root retrieval, slot check and gindex construction are outside this harness.
contract BlsCompositionHarness is CLValidatorVerifier {
    constructor() CLValidatorVerifier(pack(150 << 40,40),pack(150 << 40,40),0) {}
    function verify(ValidatorWitness calldata w, bytes32 wc, bytes32 root, GIndex gi) external view {
        bytes32 leaf = _validatorHashTreeRoot(w,wc);
        SSZ.verifyProof(w.proofValidator,root,leaf,gi);
    }
}

contract SszBlsCompositionTest {
    CompositionVm constant vm = CompositionVm(address(uint160(uint256(keccak256("hevm cheat code")))));
    BlsCompositionHarness h = new BlsCompositionHarness();
    function chunk(uint64 v) internal pure returns(bytes32 out) {
        for(uint256 i;i<8;i++) out |= bytes32(uint256(uint8(v>>(8*i))) << (248-8*i));
    }
    function fixture() internal pure returns(ValidatorWitness memory w) {
        w.pubkey=abi.encodePacked(keccak256("asymmetric first"),bytes16(keccak256("last")));
        w.effectiveBalance=32_000_000_000; w.slashed=true;
        w.activationEligibilityEpoch=11; w.activationEpoch=22; w.exitEpoch=33; w.withdrawableEpoch=44;
        w.proofValidator=new bytes32[](0);
    }
    // Octet serialization and generic level reduction, independent of named source pairs.
    // Retain all eight exact inputs for isolated source fault injection below.
    function referenceLeaf(ValidatorWitness memory w,bytes32 wc) internal pure
        returns(bytes32 leaf,bytes[8] memory inputs)
    {
        inputs[0]=abi.encodePacked(w.pubkey,bytes16(0));
        bytes32[8] memory nodes=[sha256(inputs[0]),wc,chunk(w.effectiveBalance),chunk(w.slashed?1:0),
            chunk(w.activationEligibilityEpoch),chunk(w.activationEpoch),chunk(w.exitEpoch),chunk(w.withdrawableEpoch)];
        uint256 callIndex=1;
        for(uint256 count=8;count>1;count/=2) {
            for(uint256 i;i<count/2;i++) {
                inputs[callIndex]=abi.encodePacked(nodes[2*i],nodes[2*i+1]);
                nodes[i]=sha256(inputs[callIndex++]);
            }
        }
        return(nodes[0],inputs);
    }
    function fold(bytes32 leaf,bytes32[] memory proof,uint256 index) internal pure returns(bytes32) {
        for(uint256 i;i<proof.length;i++) {
            leaf=index%2==0 ? sha256(abi.encodePacked(leaf,proof[i])) : sha256(abi.encodePacked(proof[i],leaf));
            index/=2;
        }
        require(index==1,"reference depth"); return leaf;
    }
    function reject(ValidatorWitness memory w,bytes32 wc,bytes32 root,GIndex gi,bytes memory expected) internal view {
        (bool ok,bytes memory why)=address(h).staticcall(abi.encodeCall(h.verify,(w,wc,root,gi)));
        require(!ok && keccak256(why)==keccak256(expected),"source rejection bytes/order");
    }
    function testFuzz_realLeafFeedsRealProof(bytes32 first,bytes16 last,bytes32 wc,uint64 balance,
        uint64 eligible,uint64 active,uint64 exited,uint64 withdrawable,bool slashed,uint16 position,uint8 seed) public view
    {
        ValidatorWitness memory w=ValidatorWitness(new bytes32[](1+uint256(seed)%12),abi.encodePacked(first,last),
            balance,eligible,active,exited,withdrawable,slashed);
        for(uint256 i;i<w.proofValidator.length;i++) w.proofValidator[i]=keccak256(abi.encode(first,last,i));
        uint256 index=(1<<w.proofValidator.length)+(uint256(position)%(1<<w.proofValidator.length));
        (bytes32 leaf,)=referenceLeaf(w,wc);
        bytes32 root=fold(leaf,w.proofValidator,index);
        h.verify(w,wc,root,pack(index,seed));
        // Metadata low byte must not affect the decoded path.
        h.verify(w,wc,root,pack(index,seed^0xff));
        reject(w,wc,root^bytes32(uint256(1)),pack(index,seed),abi.encodeWithSelector(SSZ.InvalidProof.selector));
        w.proofValidator[w.proofValidator.length-1]^=bytes32(uint256(1));
        reject(w,wc,root,pack(index,seed),abi.encodeWithSelector(SSZ.InvalidProof.selector));
    }
    function test_eachBlsCallRejectsBeforeEmptyProof() public {
        ValidatorWitness memory w=fixture(); bytes32 wc=keccak256("credentials");
        (,bytes[8] memory inputs)=referenceLeaf(w,wc);
        for(uint256 i;i<8;i++) {
            // Establish that fault input i cannot accidentally match an earlier pair.
            for(uint256 j;j<i;j++) require(keccak256(inputs[i])!=keccak256(inputs[j]),"distinct fault inputs");
            for(uint256 size=31;size<=33;size+=2) {
                vm.mockCall(address(2),inputs[i],new bytes(size));
                reject(w,wc,0,pack(2,1),abi.encodeWithSelector(BLS12_381.Sha256PrecompileFailed.selector));
                vm.clearMockedCalls();
            }
            vm.mockCallRevert(address(2),inputs[i],hex"abcd");
            reject(w,wc,0,pack(2,1),abi.encodeWithSelector(BLS12_381.Sha256PrecompileFailed.selector));
            vm.clearMockedCalls();
        }
        // All eight real SHA calls now succeed; the next source guard is reached.
        reject(w,wc,0,pack(2,1),abi.encodeWithSelector(SSZ.InvalidProof.selector));
    }
    function test_pubkeyLengthPrecedesFaultAndEmptyProof() public {
        ValidatorWitness memory w=fixture();
        vm.mockCallRevert(address(2),hex"",hex"abcd");
        w.pubkey=new bytes(47);
        reject(w,0,0,pack(2,1),abi.encodeWithSelector(BLS12_381.InvalidPubkeyLength.selector));
        w.pubkey=new bytes(49);
        reject(w,0,0,pack(2,1),abi.encodeWithSelector(BLS12_381.InvalidPubkeyLength.selector));
        vm.clearMockedCalls();
    }
    function test_finalProofCallKeepsItsOwnError() public {
        ValidatorWitness memory w=fixture(); bytes32 wc=keccak256("credentials");
        (bytes32 leaf,)=referenceLeaf(w,wc);
        w.proofValidator=new bytes32[](1); w.proofValidator[0]=keccak256("sibling");
        bytes32 root=fold(leaf,w.proofValidator,2);
        h.verify(w,wc,root,pack(2,1));
        vm.mockCallRevert(address(2),abi.encodePacked(leaf,w.proofValidator[0]),hex"abcd");
        reject(w,wc,root,pack(2,1),hex"");
        vm.clearMockedCalls();
    }
    function test_fieldMutationsReachRootComparison() public view {
        ValidatorWitness memory w=fixture(); bytes32 wc=keccak256("credentials");
        (bytes32 leaf,)=referenceLeaf(w,wc);
        w.proofValidator=new bytes32[](1); w.proofValidator[0]=keccak256("sibling");
        bytes32 root=fold(leaf,w.proofValidator,3);
        h.verify(w,wc,root,pack(3,255));
        w.pubkey[47]^=0x01;
        reject(w,wc,root,pack(3,0),abi.encodeWithSelector(SSZ.InvalidProof.selector));
        w.pubkey[47]^=0x01; w.slashed=false;
        reject(w,wc,root,pack(3,0),abi.encodeWithSelector(SSZ.InvalidProof.selector));
        w.slashed=true;
        (w.activationEligibilityEpoch,w.activationEpoch)=(w.activationEpoch,w.activationEligibilityEpoch);
        reject(w,wc,root,pack(3,0),abi.encodeWithSelector(SSZ.InvalidProof.selector));
        (w.activationEligibilityEpoch,w.activationEpoch)=(w.activationEpoch,w.activationEligibilityEpoch);
        reject(w,wc^bytes32(uint256(1)),root,pack(3,0),abi.encodeWithSelector(SSZ.InvalidProof.selector));
    }
}
