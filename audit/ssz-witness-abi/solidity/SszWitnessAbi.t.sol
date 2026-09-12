// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;
import {SszBlsCompositionTest} from "../../ssz-bls-composition/solidity/SszBlsComposition.t.sol";
import {ValidatorWitness} from "contracts/common/interfaces/ValidatorWitness.sol";
import {pack} from "contracts/common/lib/GIndex.sol";

// Raw calldata against the unchanged inherited leaf/verifier harness.
// This tests its compiler decoder, not the full CLValidatorVerifier prefix.
contract SszWitnessAbiTest is SszBlsCompositionTest {
    function writeWord(bytes memory raw,uint256 offset,uint256 value) internal pure {
        require(offset+32<=raw.length,"test write extent");
        assembly { mstore(add(add(raw,32),offset),value) }
    }
    function validRaw() internal view returns(bytes memory raw,ValidatorWitness memory w,bytes[8] memory inputs) {
        w=fixture();w.proofValidator=new bytes32[](1);w.proofValidator[0]=keccak256("abi sibling");
        bytes32 wc=keccak256("abi credentials");bytes32 leaf;
        (leaf,inputs)=referenceLeaf(w,wc);
        bytes32 root=fold(leaf,w.proofValidator,2);
        raw=abi.encodeCall(h.verify,(w,wc,root,pack(2,1)));
    }
    function rejectedRaw(bytes memory raw,bytes memory expected) internal view {
        (bool ok,bytes memory why)=address(h).staticcall(raw);
        require(!ok && keccak256(why)==keccak256(expected),"raw rejection bytes/order");
    }
    function test_wrappedNegativePubkeyOffsetStillExecutes() public view {
        (bytes memory original,ValidatorWitness memory w,)=validRaw();
        bytes memory raw=new bytes(original.length+128);
        // Shift only the witness body/tails by128; retain the outer static args.
        for(uint256 i;i<132;i++) raw[i]=original[i];
        for(uint256 i=132;i<original.length;i++) raw[i+128]=original[i];
        writeWord(raw,4,256); // witness body now at calldata260
        // Signed relative tail -128 wraps the actual pointer back to calldata132.
        writeWord(raw,292,type(uint256).max-127);
        writeWord(raw,132,48);
        for(uint256 i;i<48;i++) raw[164+i]=w.pubkey[i];
        (bool ok,bytes memory why)=address(h).staticcall(raw);
        require(ok && why.length==0,"compiled wrapped-offset witness rejected");
    }
    function test_keyShaFailurePrecedesDirtyUint64() public {
        (bytes memory raw,,bytes[8] memory inputs)=validRaw();
        writeWord(raw,196,1<<64); // effectiveBalance: witness132+64
        rejectedRaw(raw,hex"");
        vm.mockCall(address(2),inputs[0],new bytes(31));
        rejectedRaw(raw,hex"dd5cab3e");
        vm.clearMockedCalls();
    }
    function test_dirtyBoolPrecedesFirstPairCall() public {
        (bytes memory raw,,bytes[8] memory inputs)=validRaw();
        writeWord(raw,356,2); // slashed: witness132+224
        vm.mockCallRevert(address(2),inputs[1],hex"");
        rejectedRaw(raw,hex"");
        vm.clearMockedCalls();
    }
    function test_lastPairFailurePrecedesMalformedProofTail() public {
        (bytes memory raw,,bytes[8] memory inputs)=validRaw();
        writeWord(raw,132,type(uint64).max); // proof relative pointer, out of range
        rejectedRaw(raw,hex"");
        vm.mockCallRevert(address(2),inputs[7],hex"");
        rejectedRaw(raw,hex"dd5cab3e");
        vm.clearMockedCalls();
    }
}
