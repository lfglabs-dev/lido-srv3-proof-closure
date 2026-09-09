// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {CLValidatorVerifier} from "../../lido-core/contracts/0.8.25/CLValidatorVerifier.sol";
import {ValidatorWitness} from "../../lido-core/contracts/common/interfaces/ValidatorWitness.sol";
import {BLS12_381} from "../../lido-core/contracts/common/lib/BLS.sol";
import {pack} from "../../lido-core/contracts/common/lib/GIndex.sol";

contract SszValidatorLeafHarness is CLValidatorVerifier {
    constructor() CLValidatorVerifier(pack(150 * (1 << 40), 40), pack(150 * (1 << 40), 40), 0) {}

    function leaf(ValidatorWitness calldata witness, bytes32 expectedCredentials) external view returns (bytes32) {
        return _validatorHashTreeRoot(witness, expectedCredentials);
    }

    function keyRoot(bytes calldata key) external view returns (bytes32) {
        return BLS12_381.pubkeyRoot(key);
    }
}

contract SszValidatorLeafTest {
    SszValidatorLeafHarness harness = new SszValidatorLeafHarness();

    // Independent octet serialization, not the SSZ helper's swap/mask expression.
    function chunk(uint64 value) internal pure returns (bytes32 out) {
        for (uint256 i; i < 8; ++i) out |= bytes32(uint256(uint8(value >> (8 * i))) << (248 - 8 * i));
    }

    // Generic level reduction over semantic fields, unlike the source's seven
    // individually named pair calls. Credentials come from the caller argument.
    function referenceLeaf(ValidatorWitness memory w, bytes32 wc) internal pure returns (bytes32) {
        require(w.pubkey.length == 48, "reference key length");
        bytes32[8] memory nodes = [
            sha256(abi.encodePacked(w.pubkey, bytes16(0))), wc,
            chunk(w.effectiveBalance), chunk(w.slashed ? 1 : 0),
            chunk(w.activationEligibilityEpoch), chunk(w.activationEpoch),
            chunk(w.exitEpoch), chunk(w.withdrawableEpoch)
        ];
        for (uint256 count = 8; count > 1; count /= 2) {
            for (uint256 i; i < count / 2; ++i) nodes[i] = sha256(abi.encodePacked(nodes[2 * i], nodes[2 * i + 1]));
        }
        return nodes[0];
    }

    function fixture() internal pure returns (ValidatorWitness memory w) {
        w.pubkey = abi.encodePacked(bytes32(uint256(123)), bytes16(type(uint128).max));
        w.effectiveBalance = 32000000000;
        w.activationEligibilityEpoch = 11;
        w.activationEpoch = 22;
        w.exitEpoch = 33;
        w.withdrawableEpoch = 44;
        w.slashed = true;
        w.proofValidator = new bytes32[](0);
    }

    function testFuzz_allWitnessFields(bytes32 first, bytes16 last, bytes32 credentials,
        uint64 balance, uint64 eligible, uint64 active, uint64 exited, uint64 withdrawable, bool slashed) public view {
        ValidatorWitness memory w = ValidatorWitness(new bytes32[](0), abi.encodePacked(first, last),
            balance, eligible, active, exited, withdrawable, slashed);
        require(harness.leaf(w, credentials) == referenceLeaf(w, credentials), "validator field root");
    }

    function testFuzz_pubkeyPadding(bytes32 first, bytes16 last) public view {
        bytes memory key = abi.encodePacked(first, last);
        require(harness.keyRoot(key) == sha256(abi.encodePacked(first, last, bytes16(0))), "48 plus 16 zero bytes");
    }

    function testFuzz_badPubkeyLength(uint8 lengthSeed) public view {
        uint256 n = lengthSeed < 48 ? lengthSeed : uint256(lengthSeed) + 1;
        ValidatorWitness memory w = fixture();
        w.pubkey = new bytes(n);
        try harness.leaf(w, bytes32(0)) { revert("invalid key admitted"); }
        catch (bytes memory reason) {
            require(keccak256(reason) == keccak256(abi.encodeWithSelector(BLS12_381.InvalidPubkeyLength.selector)), "key length error");
        }
    }

    function test_allIntegerBoundariesAndBothBooleans() public view {
        ValidatorWitness memory w = fixture();
        for (uint256 edge; edge < 2; ++edge) {
            uint64 value = edge == 0 ? 0 : type(uint64).max;
            w.effectiveBalance = value;
            w.activationEligibilityEpoch = value;
            w.activationEpoch = value;
            w.exitEpoch = value;
            w.withdrawableEpoch = value;
            for (uint256 flag; flag < 2; ++flag) {
                w.slashed = flag == 1;
                require(harness.leaf(w, bytes32(type(uint256).max)) == referenceLeaf(w, bytes32(type(uint256).max)), "uint64 and boolean edge");
            }
        }
    }

    function test_fieldOrderAndCredentialMutants() public view {
        ValidatorWitness memory w = fixture();
        bytes32 wc = bytes32(uint256(0x02010203));
        bytes32 expected = referenceLeaf(w, wc);
        require(harness.leaf(w, wc) == expected, "baseline");
        (w.activationEligibilityEpoch, w.activationEpoch) = (w.activationEpoch, w.activationEligibilityEpoch);
        require(harness.leaf(w, wc) != expected, "epoch-order mutant survived");
        require(harness.leaf(w, wc) == referenceLeaf(w, wc), "mutated epoch reference");
        w = fixture();
        require(harness.leaf(w, bytes32(uint256(wc) ^ 1)) != expected, "credential mutant survived");
        w.slashed = false;
        require(harness.leaf(w, wc) != expected, "boolean mutant survived");
        w = fixture();
        w.pubkey[47] = bytes1(uint8(w.pubkey[47]) ^ 1);
        require(harness.leaf(w, wc) != expected, "last pubkey byte ignored");
    }

    function test_paddingAndProofIndependence() public view {
        ValidatorWitness memory w = fixture();
        bytes32 keyRoot = harness.keyRoot(w.pubkey);
        require(keyRoot == sha256(abi.encodePacked(w.pubkey, bytes16(0))), "correct padding");
        require(keyRoot != sha256(w.pubkey), "missing padding mutant survived");
        require(keyRoot != sha256(abi.encodePacked(w.pubkey, bytes16(type(uint128).max))), "dirty padding mutant survived");
        bytes32 root = harness.leaf(w, bytes32(0));
        w.proofValidator = new bytes32[](3);
        w.proofValidator[1] = bytes32(type(uint256).max);
        require(harness.leaf(w, bytes32(0)) == root, "proof array leaked into validator leaf");
    }
}
