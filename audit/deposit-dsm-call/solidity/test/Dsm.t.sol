pragma solidity 0.8.25;
import {DsmHarness,RawLocator} from "../src/DsmHarness.sol";
interface Vm {function store(address,bytes32,bytes32) external;}
contract DsmTest {
 Vm constant vm=Vm(address(uint160(uint256(keccak256("hevm cheat code")))));
 bytes32 constant ROOT=0x5648d366b9f342bdcc64be95cdcf5f05da808509be70eaa548a8795901d5d000;
 RawLocator locator=new RawLocator();
 DsmHarness q=new DsmHarness(address(locator));
 function configure(bytes memory data,uint256 mode) internal {locator.configure(data,mode,address(q));}
 function registered() internal {
  vm.store(address(q),keccak256(abi.encode(uint256(7),uint256(ROOT)+2)),bytes32(uint256(1)));
  vm.store(address(q),keccak256(abi.encode(uint256(7),ROOT)),bytes32(uint256(255)<<232));
  vm.store(address(q),bytes32(uint256(ROOT)+4),bytes32(uint256(99)));
 }
 function expectError(bytes memory expected) internal view {
  (bool ok,bytes memory data)=address(q).staticcall(abi.encodeCall(q.admitted,(7)));
  require(!ok && keccak256(data)==keccak256(expected),"error/order");
 }
 function testActualRequestAndPhysicalAdmission() public {
  configure(abi.encode(address(this)),0);registered();
  require(q.admitted(7)==bytes32((uint256(255)<<248)|99),"physical WC");
 }
 function testRevertBeforeAuthorizationAndMembership() public {
  configure(hex"deadbeef",1);expectError(hex"deadbeef");
 }
 function testNoCodeSuccessThenDecoderRejection() public {
  DsmHarness noCode=new DsmHarness(address(0x123456));
  (bool ok,bytes memory data)=address(noCode).staticcall(abi.encodeCall(noCode.admitted,(7)));
  require(!ok && data.length==0,"no code/short return");
 }
 function testForbiddenWriteFailsStaticCall() public {
  configure(abi.encode(address(this)),2);expectError("");require(locator.written()==0,"static changed state");
 }
 function testAllShortLengthsRejectBeforeAuthorization() public {
  for(uint256 n=0;n<32;n++) {configure(new bytes(n),0);expectError("");}
 }
 function testCanonicalZeroThenAuthorization() public {
  configure(abi.encode(address(0)),0);require(q.resolved()==address(0),"zero decoder");
  expectError(abi.encodeWithSignature("NotAuthorized()"));
 }
 function testDecodedAddressControlsAuthorization() public {
  configure(abi.encode(address(123)),0);expectError(abi.encodeWithSignature("NotAuthorized()"));
  configure(abi.encode(address(this)),0);expectError(abi.encodeWithSignature("StakingModuleUnregistered()"));
 }
 function testFuzzCanonicalAndTrailing(address dsm,bytes calldata trailing) public {
  configure(bytes.concat(abi.encode(dsm),trailing),0);require(q.resolved()==dsm,"decoded address");
 }
 function testFuzzDirtyHighBitsReject(uint96 high,address dsm) public {
  if(high==0) high=1;
  configure(abi.encode((uint256(high)<<160)|uint160(dsm)),0);expectError("");
 }
}
