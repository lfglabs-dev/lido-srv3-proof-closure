import pathlib,json
r=pathlib.Path(__file__).resolve().parent
vs=json.loads((r/'vectors.json').read_text())
s='''// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;
// Generated from vectors.json; independent ChainSafe/Node fixture, actual pinned verifier.
import {CLValidatorVerifier} from "pinned-lido/contracts/0.8.25/CLValidatorVerifier.sol";
import {pack} from "contracts/common/lib/GIndex.sol";
interface EntryVm { function mockCall(address target, bytes calldata payload, bytes calldata reply) external; }
contract SszVerifierEntryHarness is CLValidatorVerifier {
    constructor() CLValidatorVerifier(pack(150 * (1 << 40), 40), pack(150 * (1 << 40), 40), 0) {}
    function verify(BeaconRootData calldata b, ValidatorWitness calldata w, uint256 i, bytes32 wc) external view { _verifyValidator(b,w,i,wc); }
}
import {ValidatorWitness, BeaconRootData} from "contracts/common/interfaces/ValidatorWitness.sol";
import {SSZ} from "contracts/common/lib/SSZ.sol";
contract SszStatePlacementReferenceTest {
    EntryVm constant vm = EntryVm(address(uint160(uint256(keccak256("hevm cheat code")))));
    SszVerifierEntryHarness harness = new SszVerifierEntryHarness();
    address constant ROOTS = 0x000F3df6D732807Ef1319fB7B8bB8522d0Beac02;
    function reject(BeaconRootData memory b, ValidatorWitness memory w, uint256 i, bytes32 wc) internal view {
        try harness.verify(b,w,i,wc) { revert("mutated canonical proof admitted"); }
        catch(bytes memory reason) { require(keccak256(reason)==keccak256(abi.encodeWithSelector(SSZ.InvalidProof.selector)),"wrong rejection"); }
    }
'''
for v in vs:
 w=v['witness']; proof=''.join(x[2:] for x in v['proof'])
 s+=f'''    function test_{v['fork']}_length{v['registryLength']}_index{v['index']}() public {{
        BeaconRootData memory b=BeaconRootData({v['timestamp']},{v['slot']},{v['proposer']});
        bytes memory packed=hex"{proof}";
        bytes32[] memory branch=new bytes32[](50);
        for(uint256 j;j<50;j++) {{ bytes32 sibling; assembly {{ sibling := mload(add(add(packed,32),mul(j,32))) }} branch[j]=sibling; }}
        ValidatorWitness memory w=ValidatorWitness(branch,hex"{w['pubkey'][2:]}",{w['effective_balance']},{w['activation_eligibility_epoch']},{w['activation_epoch']},{w['exit_epoch']},{w['withdrawable_epoch']},{str(w['slashed']).lower()});
        bytes32 wc={w['withdrawal_credentials']};
        vm.mockCall(ROOTS,abi.encode(b.childBlockTimestamp),abi.encode(bytes32({v['root']})));
        harness.verify(b,w,{v['index']},wc);
        bytes32 saved=w.proofValidator[40]; w.proofValidator[40]=saved^bytes32(uint256(1)<<248);
        reject(b,w,{v['index']},wc); w.proofValidator[40]=saved;
        w.proofValidator[39]=bytes32(0); reject(b,w,{v['index']},wc);
    }}
'''
s+='}\n'
(r/'SszStatePlacement.t.sol').write_text(s)
