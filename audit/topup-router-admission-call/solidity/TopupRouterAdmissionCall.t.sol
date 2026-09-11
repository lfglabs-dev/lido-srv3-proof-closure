// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;
import {BatchRouter, BatchModule} from "audit/topup-batch-consumer/solidity/TopupBatchConsumer.t.sol";
interface AdmissionVm { function store(address,bytes32,bytes32) external; function etch(address,bytes calldata) external; }
// Raw ABI endpoint checks the actual router caller and selector. A writable
// fallback deliberately demonstrates that the production invocation is static.
contract AdmissionEndpoint {
    address public expected;
    bytes public response;
    uint256 public mode;
    uint256 public depositable;
    uint256 public writes;
    function set(address caller, bytes memory data, uint256 how, uint256 amount) external {
        expected=caller;response=data;mode=how;depositable=amount;
    }
    fallback() external {
        require(msg.sender==expected,"caller");
        if (msg.sig==bytes4(keccak256("getDepositableEther()"))) {
            uint256 n=depositable;assembly { mstore(0,n) return(0,32) }
        }
        require(msg.sig==0x644862de || msg.sig==0xe78a5875,"selector");
        bytes memory data=response;
        if(mode==1) assembly { revert(add(data,32),mload(data)) }
        if(mode==2) writes++;
        assembly { return(add(data,32),mload(data)) }
    }
}
contract TopupRouterAdmissionCallTest {
    AdmissionVm constant vm=AdmissionVm(address(uint160(uint256(keccak256("hevm cheat code")))));
    bytes32 constant ROOT=0x5648d366b9f342bdcc64be95cdcf5f05da808509be70eaa548a8795901d5d000;
    AdmissionEndpoint locator;
    AdmissionEndpoint lido;
    BatchModule module;
    BatchRouter router;
    function setUp() public {
        locator=new AdmissionEndpoint();lido=new AdmissionEndpoint();module=new BatchModule();
        router=new BatchRouter(address(lido),address(locator),address(module));
        locator.set(address(router),abi.encode(address(this)),0,0);
        lido.set(address(router),abi.encode(true),0,0);
    }
    function invoke(uint256 id,uint256 n,uint256 operatorsLength,uint256 pubkeyLength) internal returns(bool,bytes memory) {
        uint256[] memory keys=new uint256[](n);
        uint256[] memory operators=new uint256[](operatorsLength);
        bytes[] memory pubkeys=new bytes[](n);
        uint256[] memory limits=new uint256[](n);
        for(uint256 i;i<n;i++){pubkeys[i]=new bytes(pubkeyLength);limits[i]=32 ether;}
        return address(router).call(abi.encodeCall(router.topUp,(id,keys,operators,pubkeys,limits)));
    }
    function check(bytes memory wanted,uint256 id,uint256 n,uint256 op,uint256 pk) internal {
        (bool ok,bytes memory data)=invoke(id,n,op,pk);
        require(!ok && keccak256(data)==keccak256(wanted),"wrong failure");
        require(module.calls()==0,"module side effect survived");
    }
    function errorBytes(string memory signature) internal pure returns(bytes memory){return abi.encodeWithSignature(signature);}
    function config(uint256 state,uint256 typ) internal {
        vm.store(address(router),keccak256(abi.encode(uint256(7),ROOT)),bytes32(uint256(uint160(address(module)))|(uint256(10000)<<192)|(state<<224)|(typ<<232)));
    }
    function test_authBubbleBeforeEmpty() public { locator.set(address(router),hex"deadbeef01",1,0);check(hex"deadbeef01",7,0,0,48); }
    function test_authStaticWriteRejected() public { locator.set(address(router),abi.encode(address(this)),2,0);check(hex"",7,1,1,48);require(locator.writes()==0); }
    function test_authCanonicalAddress() public { locator.set(address(router),abi.encode((uint256(1)<<160)|uint160(address(this))),0,0);check(hex"",7,1,1,48); }
    function test_authShort() public { locator.set(address(router),new bytes(31),0,0);check(hex"",7,1,1,48); }
    function test_authOrdinaryNoCode() public { vm.etch(address(locator),hex"");check(hex"",7,1,1,48); }
    function test_authDecodedCaller() public { locator.set(address(router),abi.encode(address(99)),0,0);check(errorBytes("NotAuthorized()"),7,0,0,48); }
    function test_inputOrder() public { check(errorBytes("EmptyKeysList()"),99,0,0,47);check(errorBytes("ArraysLengthMismatch()"),99,1,0,47);check(errorBytes("WrongPubkeyLength()"),99,1,1,47);check(errorBytes("StakingModuleUnregistered()"),99,1,1,48); }
    function test_statusAndTypeOrder() public { config(255,1);check(abi.encodeWithSignature("Panic(uint256)",0x21),7,1,1,48);config(1,1);check(errorBytes("StakingModuleNotActive()"),7,1,1,48);config(0,1);check(errorBytes("WrongWithdrawalCredentialsType()"),7,1,1,48); }
    function testFuzz_statusByte(uint8 state) public { config(state,2); if(state==0){(bool ok,)=invoke(7,1,1,48);require(ok);}else{check(state>=3?abi.encodeWithSignature("Panic(uint256)",0x21):errorBytes("StakingModuleNotActive()"),7,1,1,48);} }
    function test_zeroTargetFalseBeforeModule() public { lido.set(address(router),abi.encode(false),0,0);check(errorBytes("LidoDepositsPaused()"),7,1,1,48); }
    function test_zeroTargetNoncanonicalBool() public { lido.set(address(router),abi.encode(uint256(2)),0,0);check(hex"",7,1,1,48); }
    function test_zeroTargetShortBool() public { lido.set(address(router),new bytes(31),0,0);check(hex"",7,1,1,48); }
    function test_zeroTargetBubble() public { lido.set(address(router),hex"cafe01",1,0);check(hex"cafe01",7,1,1,48); }
    function test_zeroTargetStaticWrite() public { lido.set(address(router),abi.encode(true),2,0);check(hex"",7,1,1,48);require(lido.writes()==0); }
    function test_positiveTargetSkipsBoolCall() public { lido.set(address(router),hex"cafe",1,64 ether);(bool ok,)=invoke(7,1,1,48);require(ok&&module.calls()==1); }
    function test_zeroTargetTrueTrailingDataCommitsModule() public { locator.set(address(router),bytes.concat(abi.encode(address(this)),hex"abcd"),0,0);lido.set(address(router),bytes.concat(abi.encode(true),hex"ffaa"),0,0);(bool ok,)=invoke(7,1,1,48);require(ok&&module.calls()==1); }
    function test_lateFailureRollsBackModule() public { module.configure(1 gwei);check(errorBytes("ModuleReturnExceedTarget()"),7,1,1,48);require(module.received().length==0); }
}
