pragma solidity 0.8.25;
import {AdmissionHarness} from "../src/AdmissionHarness.sol";
interface Vm {function store(address,bytes32,bytes32) external;}
contract AdmissionTest {
 Vm constant vm=Vm(address(uint160(uint256(keccak256("hevm cheat code")))));
 AdmissionHarness q=new AdmissionHarness();
 bytes32 constant ROOT=0x5648d366b9f342bdcc64be95cdcf5f05da808509be70eaa548a8795901d5d000;
 function cfg(uint256 id) internal pure returns(bytes32) {return keccak256(abi.encode(id,ROOT));}
 function member(uint256 id) internal pure returns(bytes32) {return keccak256(abi.encode(id,uint256(ROOT)+2));}
 function put(uint256 id,bytes32 config,bytes32 raw,uint256 position) internal {
  vm.store(address(q),cfg(id),config);vm.store(address(q),bytes32(uint256(ROOT)+4),raw);
  vm.store(address(q),member(id),bytes32(position));
 }
 function checkError(uint256 id,address dsm,bytes memory expected) internal {
  (bool ok,bytes memory result)=address(q).staticcall(abi.encodeWithSelector(q.admitted.selector,id,dsm));
  require(!ok && keccak256(result)==keccak256(expected),"error/order");
 }
 function testRootAndNon32Immutable() public view {
  bytes32 expected=bytes32(uint256(keccak256(abi.encode(uint256(keccak256(bytes("lido.StakingRouter.routerStorage")))-1)))&~uint256(255));
  require(q.root()==ROOT && ROOT==expected,"ERC7201");
  require(q.MAX_EFFECTIVE_BALANCE_WC_TYPE_01()==7 && q.MAX_EFFECTIVE_BALANCE_WC_TYPE_02()==11,"constructor values");
 }
 function testAuthorizationBeforeMembershipAndEnum() public {
  put(1,bytes32(uint256(255)<<224),0,0);
  checkError(1,address(123),abi.encodeWithSignature("NotAuthorized()"));
  checkError(1,address(this),abi.encodeWithSignature("StakingModuleUnregistered()"));
 }
 function testLastModuleIdIsNotMembership() public {
  vm.store(address(q),bytes32(uint256(ROOT)+5),bytes32(type(uint256).max));
  checkError(1,address(this),abi.encodeWithSignature("StakingModuleUnregistered()"));
  put(type(uint256).max,0,bytes32(uint256(17)),9);
  vm.store(address(q),bytes32(uint256(ROOT)+5),0);
  require(q.admitted(type(uint256).max,address(this))==bytes32(uint256(17)),"position alone");
 }
 function testEveryStatusByteAndEveryCredentialType() public {
  for(uint256 n=0;n<256;n++) {
   put(7,bytes32(n<<224),0,1);
   if(n==0) require(q.admitted(7,address(this))==0);
   else if(n<3) checkError(7,address(this),abi.encodeWithSignature("StakingModuleNotActive()"));
   else checkError(7,address(this),abi.encodeWithSignature("Panic(uint256)",0x21));
   put(7,bytes32(n<<232),bytes32(type(uint256).max),1);
   require(q.admitted(7,address(this))==bytes32((type(uint256).max>>8)|(n<<248)),"all uint8 WC types");
  }
 }
 function testFuzzPhysicalReads(uint256 id,bytes32 config,bytes32 raw,uint256 position) public {
  uint256 cleaned=uint256(config)&~(uint256(255)<<224);
  put(id,bytes32(cleaned),raw,position);
  if(position==0) checkError(id,address(this),abi.encodeWithSignature("StakingModuleUnregistered()"));
  else require(q.admitted(id,address(this))==bytes32((uint256(raw)&type(uint248).max)|((cleaned>>232&255)<<248)),"word packing");
 }
 function testFuzzOtherConfigFieldsCannotChangeAdmissionType(uint256 id,uint8 kind,uint224 low,uint16 high) public {
  put(id,bytes32(uint256(low)|(uint256(kind)<<232)|(uint256(high)<<240)),bytes32(uint256(123)),1);
  require(q.admitted(id,address(this))==bytes32(uint256(123)|(uint256(kind)<<248)),"other fields");
 }
}
