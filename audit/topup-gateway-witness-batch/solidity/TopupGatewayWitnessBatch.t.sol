// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {TopUpGateway} from "contracts/0.8.25/TopUpGateway.sol";
import {TopUpData, BeaconRootData, ValidatorWitness} from "contracts/common/interfaces/TopUpWitness.sol";
import {pack} from "contracts/common/lib/GIndex.sol";
import {SSZ} from "contracts/common/lib/SSZ.sol";

interface GatewayVm {
    function mockCall(address, bytes calldata, bytes calldata) external;
    function warp(uint256) external;
    function roll(uint256) external;
    function store(address,bytes32,bytes32) external;
}

// The real gateway/verifier are inherited without overriding any operation.
// Internal setters and role grant prepare a standalone fixture, not a proxy deployment.
contract GatewayWitnessHarness is TopUpGateway {
    Storage private layoutOnly; // Compiler type-layout witness; real reads use the namespace.
    constructor(address locator, uint256 epochSize)
        TopUpGateway(locator, pack(150 * (1 << 40),40), pack(150 * (1 << 40),40),0,epochSize)
    {
        _grantRole(TOP_UP_ROLE,msg.sender);
        _setMaxValidatorsPerTopUp(8);
        _setMinBlockDistance(1);
        _setMaxRootAge(100);
        _setTopUpBalanceLimits(64_000_000_000,1_000_000_000);
    }
}

// Only the router boundary is a recorder; no funding or module effect is claimed.
contract GatewayRouterRecorder {
    bytes32 public credentials;
    bytes32 public captured;
    uint256 public calls;
    function setCredentials(bytes32 value) external { credentials=value; }
    function getStakingModuleWithdrawalCredentials(uint256) external view returns(bytes32) { return credentials; }
    function topUp(uint256 moduleId,uint256[] calldata keys,uint256[] calldata operators,bytes[] calldata pubkeys,uint256[] calldata limits) external {
        calls++;
        captured=keccak256(abi.encode(moduleId,keys,operators,pubkeys,limits));
    }
}
contract GatewayLocatorFixture {
    address public immutable stakingRouter;
    constructor(address router) { stakingRouter=router; }
}

contract TopupGatewayWitnessBatchTest {
    GatewayVm constant vm=GatewayVm(address(uint160(uint256(keccak256("hevm cheat code")))));
    address constant ROOTS=0x000F3df6D732807Ef1319fB7B8bB8522d0Beac02;
    bytes32 constant WC=bytes32((uint256(2)<<248)|12345);
    GatewayRouterRecorder router;
    GatewayWitnessHarness gateway;

    function setUp() public {
        vm.warp(1000); vm.roll(100);
        router=new GatewayRouterRecorder(); router.setCredentials(WC);
        gateway=new GatewayWitnessHarness(address(new GatewayLocatorFixture(address(router))),32);
    }
    function pair(bytes32 a,bytes32 b) internal pure returns(bytes32) { return sha256(abi.encodePacked(a,b)); }
    function le(uint256 n) internal pure returns(bytes32 out) {
        for(uint256 j;j<32;j++) out|=bytes32(((n>>(8*j))&255)<<(248-8*j));
    }
    function pubkey(bytes32 seed,uint256 i) internal pure returns(bytes memory) {
        return abi.encodePacked(keccak256(abi.encode(seed,i)),bytes16(keccak256(abi.encode(i,seed))));
    }
    function leaf(ValidatorWitness memory w) internal pure returns(bytes32) {
        bytes32[8] memory nodes=[sha256(abi.encodePacked(w.pubkey,bytes16(0))),WC,le(w.effectiveBalance),le(w.slashed?1:0),le(w.activationEligibilityEpoch),le(w.activationEpoch),le(w.exitEpoch),le(w.withdrawableEpoch)];
        for(uint256 width=8;width>1;width/=2) for(uint256 i;i<width/2;i++) nodes[i]=pair(nodes[2*i],nodes[2*i+1]);
        return nodes[0];
    }
    // Independent sparse validator list of length2/capacity2^40; named state slot11,
    // opaque other state roots, then header state slot3. No Lido SSZ helper is used.
    function fixture(bytes32 seed,uint64 effective0,uint64 effective1,bool slashed0,bool exited1)
        internal pure returns(TopUpData memory d,bytes32 root)
    {
        d.moduleId=7;
        d.beaconRootData=BeaconRootData(1000,4096,18);
        d.keyIndices=new uint256[](2); d.keyIndices[0]=17;d.keyIndices[1]=33;
        d.operatorIds=new uint256[](2); d.operatorIds[0]=4;d.operatorIds[1]=8;
        d.validatorIndices=new uint256[](2);d.validatorIndices[1]=1;
        d.pendingBalanceGwei=new uint256[](2);
        d.validatorWitness=new ValidatorWitness[](2);
        for(uint256 i;i<2;i++) d.validatorWitness[i]=ValidatorWitness(new bytes32[](50),pubkey(seed,i),i==0?effective0:effective1,0,1,(i==1&&exited1)?2:type(uint64).max,type(uint64).max,i==0&&slashed0);
        bytes32[2] memory leaves=[leaf(d.validatorWitness[0]),leaf(d.validatorWitness[1])];
        d.validatorWitness[0].proofValidator[0]=leaves[1];d.validatorWitness[1].proofValidator[0]=leaves[0];
        bytes32 registry=pair(leaves[0],leaves[1]); bytes32 zero=pair(bytes32(0),bytes32(0));
        for(uint256 depth=1;depth<40;depth++) {
            d.validatorWitness[0].proofValidator[depth]=zero;d.validatorWitness[1].proofValidator[depth]=zero;
            registry=pair(registry,zero);zero=pair(zero,zero);
        }
        bytes32[64] memory state;
        for(uint256 i;i<37;i++) state[i]=sha256(abi.encode("opaque Electra field",i));
        state[11]=pair(registry,le(2));
        for(uint256 i;i<2;i++) d.validatorWitness[i].proofValidator[40]=le(2);
        uint256 pos=11;
        for(uint256 depth;depth<6;depth++) {
            for(uint256 i;i<2;i++) d.validatorWitness[i].proofValidator[41+depth]=state[pos^1];
            uint256 width=64>>depth;
            for(uint256 j;j<width/2;j++) state[j]=pair(state[2*j],state[2*j+1]);
            pos/=2;
        }
        bytes32[8] memory header=[le(4096),le(18),sha256("parent"),state[0],sha256("body"),bytes32(0),bytes32(0),bytes32(0)];
        pos=3;
        for(uint256 depth;depth<3;depth++) {
            for(uint256 i;i<2;i++) d.validatorWitness[i].proofValidator[47+depth]=header[pos^1];
            uint256 width=8>>depth;
            for(uint256 j;j<width/2;j++) header[j]=pair(header[2*j],header[2*j+1]);
            pos/=2;
        }
        root=header[0];
    }
    function anchor(TopUpData memory d,bytes32 root) internal { vm.mockCall(ROOTS,abi.encode(d.beaconRootData.childBlockTimestamp),abi.encode(root)); }
    function reject(TopUpData memory d,bytes memory expected) internal {
        (bool ok,bytes memory reason)=address(gateway).call(abi.encodeCall(gateway.topUp,(d)));
        require(!ok&&keccak256(reason)==keccak256(expected),"wrong rejection");
        require(router.calls()==0,"router entered on rejected batch");
    }
    function err(bytes4 selector) internal pure returns(bytes memory) { return abi.encodeWithSelector(selector); }
    function headroom(uint256 effective,uint256 pending,bool excluded) internal pure returns(uint256) {
        if(excluded) return 0;
        uint256 total=effective+pending;
        if(total>=64_000_000_000) return 0;
        uint256 room=64_000_000_000-total;
        return room<1_000_000_000?0:room*1 gwei;
    }
    function testFuzz_actualWitnessesProduceRouterArguments(bytes32 seed,uint64 e0,uint64 e1,uint64 p0,uint64 p1,bool slashed,bool exited) public {
        (TopUpData memory d,bytes32 root)=fixture(seed,e0,e1,slashed,exited);
        d.pendingBalanceGwei[0]=p0;d.pendingBalanceGwei[1]=p1;anchor(d,root);
        uint256[] memory limits=new uint256[](2);
        limits[0]=headroom(e0,p0,slashed);limits[1]=headroom(e1,p1,exited);
        bytes[] memory keys=new bytes[](2);keys[0]=d.validatorWitness[0].pubkey;keys[1]=d.validatorWitness[1].pubkey;
        gateway.topUp(d);
        require(router.calls()==1&&router.captured()==keccak256(abi.encode(d.moduleId,d.keyIndices,d.operatorIds,keys,limits)),"wrong produced arrays");
        require(gateway.getLastTopUpTimestamp()==((limits[0]+limits[1]>0)?1000:0),"limits timing");
    }
    function test_positiveLimitsAndPendingPairs() public {
        (TopUpData memory d,bytes32 root)=fixture(bytes32(uint256(7)),32_000_000_000,40_000_000_000,false,false);
        d.pendingBalanceGwei[0]=2_000_000_000;d.pendingBalanceGwei[1]=3_000_000_000;anchor(d,root);
        uint256[] memory limits=new uint256[](2);limits[0]=30 ether;limits[1]=21 ether;
        bytes[] memory keys=new bytes[](2);keys[0]=d.validatorWitness[0].pubkey;keys[1]=d.validatorWitness[1].pubkey;
        gateway.topUp(d);
        require(router.captured()==keccak256(abi.encode(d.moduleId,d.keyIndices,d.operatorIds,keys,limits)),"units/pairing");
        require(gateway.getLastTopUpTimestamp()==1000,"positive limits write");
    }
    function testFuzz_headroomAndMinimum(bytes32 seed,uint64 effectiveSeed,uint64 pendingSeed) public {
        uint64 effective=effectiveSeed%64_000_000_001;
        uint64 pending=pendingSeed%16_000_000_001;
        (TopUpData memory d,bytes32 root)=fixture(seed,effective,63_000_000_001,false,false);
        d.pendingBalanceGwei[0]=pending;anchor(d,root);
        uint256[] memory limits=new uint256[](2);limits[0]=headroom(effective,pending,false);
        bytes[] memory keys=new bytes[](2);keys[0]=d.validatorWitness[0].pubkey;keys[1]=d.validatorWitness[1].pubkey;
        gateway.topUp(d);
        require(router.captured()==keccak256(abi.encode(d.moduleId,d.keyIndices,d.operatorIds,keys,limits)),"headroom/minimum");
        require(gateway.getLastTopUpTimestamp()==(limits[0]>0?1000:0),"threshold timing");
    }
    function test_guardPriorityAndVerifiedFields() public {
        (TopUpData memory d,bytes32 root)=fixture(bytes32(0),32_000_000_000,32_000_000_000,false,false);anchor(d,root);
        d.validatorWitness[1].pubkey=new bytes(47);d.validatorIndices[1]=0;
        reject(d,err(TopUpGateway.WrongPubkeyLength.selector));
        d.validatorWitness[1].pubkey=pubkey(bytes32(0),1);
        reject(d,err(TopUpGateway.InvalidValidatorIndicesSortOrder.selector));d.validatorIndices[1]=1;
        d.validatorWitness[0].activationEpoch=129;d.validatorWitness[0].proofValidator[0]^=bytes32(uint256(1));
        reject(d,err(TopUpGateway.ValidatorIsNotActivated.selector));d.validatorWitness[0].activationEpoch=1;
        d.pendingBalanceGwei[0]=type(uint256).max;
        reject(d,err(SSZ.InvalidProof.selector));d.validatorWitness[0].proofValidator[0]^=bytes32(uint256(1));
        reject(d,abi.encodeWithSignature("Panic(uint256)",0x11));
        d.pendingBalanceGwei[0]=0;router.setCredentials(bytes32((uint256(2)<<248)|6789));
        reject(d,err(SSZ.InvalidProof.selector));
    }
    function test_excludedStillVerifiedButSkipPendingOverflow() public {
        (TopUpData memory d,bytes32 root)=fixture(bytes32(0),32_000_000_000,32_000_000_000,true,true);anchor(d,root);
        d.pendingBalanceGwei[0]=type(uint256).max;d.pendingBalanceGwei[1]=type(uint256).max;
        d.validatorWitness[0].proofValidator[0]^=bytes32(uint256(1));reject(d,err(SSZ.InvalidProof.selector));
        d.validatorWitness[0].proofValidator[0]^=bytes32(uint256(1));gateway.topUp(d);
        require(router.calls()==1&&gateway.getLastTopUpTimestamp()==0,"excluded amount/timing");
    }
    function test_arrayAdmissionAndZeroEpochDivisor() public {
        (TopUpData memory d,bytes32 root)=fixture(bytes32(0),32_000_000_000,32_000_000_000,false,false);anchor(d,root);
        d.pendingBalanceGwei=new uint256[](1);reject(d,err(TopUpGateway.WrongArrayLength.selector));
        d.pendingBalanceGwei=new uint256[](2);
        gateway=new GatewayWitnessHarness(address(new GatewayLocatorFixture(address(router))),0);
        reject(d,abi.encodeWithSignature("Panic(uint256)",0x12));
    }
    function testFuzz_actualConfigWordReads(uint256 first,uint256 second) public {
        bytes32 position=0x22e512057841e2bc1e6d80030c8bb8b4935377af2e64ba9bf8e6a3e88fb32200;
        vm.store(address(gateway),position,bytes32(first));
        vm.store(address(gateway),bytes32(uint256(position)+1),bytes32(second));
        require(gateway.getMaxValidatorsPerTopUp()==uint64(first),"count word");
        require(gateway.getTargetBalanceGwei()==uint64(first>>160),"target word");
        require(gateway.getMinTopUpGwei()==uint64(second),"minimum word");
    }
}
