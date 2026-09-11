// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.25;
import {PhysicalQuotaHarness} from "./PhysicalQuotaHarness.sol";
import {ConsolidationGateway,IWithdrawalVault} from "contracts/0.8.25/consolidation/ConsolidationGateway.sol";
interface Vm {
 function warp(uint256) external;
 function deal(address,uint256) external;
 function getCode(string calldata) external returns(bytes memory);
}
contract QuotaInbox {
 PhysicalQuotaHarness public gateway;
 uint256 public expected;
 uint256 public calls;
 bytes32 public lastPayload;
 constructor(PhysicalQuotaHarness g,uint256 e){gateway=g;expected=e;}
 fallback() external payable {
  require(gateway.rawQuota()==expected,"quote/inbox must see quota");
  if(msg.data.length==0){assembly{mstore(0,2) return(0,32)}}
  require(msg.data.length==96 && msg.value==2);
  ++calls;lastPayload=keccak256(msg.data);
 }
}
contract QuotaRefund {
 PhysicalQuotaHarness public gateway;
 QuotaInbox public inbox;
 uint256 public expected;
 uint256 public mode;
 uint256 public seen;
 constructor(PhysicalQuotaHarness g,QuotaInbox i,uint256 e,uint256 m){gateway=g;inbox=i;expected=e;mode=m;}
 receive() external payable {
  require(gateway.rawQuota()==expected && inbox.calls()==2 && address(inbox).balance==4 && msg.value==2);
  seen=2;
  if(mode==1)revert("late refund");
  if(mode==2)gateway.setRaw(123); // Explicit fixture mutability; no final frame.
 }
}
contract PhysicalQuotaTest {
 Vm constant vm=Vm(address(uint160(uint256(keccak256("hevm cheat code")))));
 function raw(uint32 maximum,uint32 previous,uint32 timestamp,uint32 duration,uint32 items) internal pure returns(uint256){
  return uint256(maximum)|(uint256(previous)<<32)|(uint256(timestamp)<<64)|(uint256(duration)<<96)|(uint256(items)<<128)|(uint256(1)<<255);
 }
 function make(uint256 value,uint256 time) internal returns(PhysicalQuotaHarness g){vm.warp(time);g=new PhysicalQuotaHarness();g.setRaw(value);}
 function reject(PhysicalQuotaHarness g,uint256 count,bytes memory expected) internal {
  uint256 old=g.rawQuota();(bool ok,bytes memory data)=address(g).call(abi.encodeCall(g.consume,(count)));
  require(!ok && keccak256(data)==keccak256(expected) && g.rawQuota()==old,"error/rollback");
 }
 function panic(uint256 code) internal pure returns(bytes memory){return abi.encodeWithSignature("Panic(uint256)",code);}
 function testDisabledSkipsRawBadState() external {uint256 r=raw(0,99,100,0,10);PhysicalQuotaHarness g=make(r,0);g.consume(type(uint256).max);require(g.rawQuota()==r);}
 function testBackwardTimestamp() external {reject(make(raw(10,6,100,10,0),99),2,panic(0x11));}
 function testZeroDurationBothPaths() external {
  reject(make(raw(10,6,0,0,1),100),2,panic(0x12));
  reject(make(raw(10,6,0,0,0),100),2,panic(0x12));
 }
 function testCountBeforeUpdateDivisionAndMaxGuard() external {
  reject(make(raw(10,6,0,0,0),100),7,abi.encodeWithSignature("ConsolidationRequestsLimitExceeded(uint256,uint256)",7,6));
  reject(make(raw(3,10,0,1,0),1),2,abi.encodeWithSignature("LimitExceeded()"));
 }
 function testCheckedReplenishmentOverflow() external {
  reject(make(raw(10,1,0,1,2),type(uint256).max),1,panic(0x11));
  reject(make(raw(10,1,0,1,1),type(uint256).max),1,panic(0x11));
 }
 function testCheckedUint32ProductAndAddition() external {
  reject(make(raw(10,6,0,3,0),2**32+2),2,panic(0x11));
  reject(make(raw(10,6,2,3,0),2**32+1),2,panic(0x11));
 }
 function testFramesCastBeforeProduct() external {PhysicalQuotaHarness g=make(raw(10,6,0,1,0),2**32+5);g.consume(2);require(g.rawQuota()==raw(10,4,5,1,0));}
 function testReplenishCapPreservesUpper96() external {PhysicalQuotaHarness g=make(raw(10,6,90,10,100),109);g.consume(2);require(g.rawQuota()==raw(10,8,100,10,100));}
 function key(uint8 b) internal pure returns(bytes memory k){k=new bytes(48);for(uint256 i;i<48;++i)k[i]=bytes1(b);}
 function groups() internal pure returns(ConsolidationGateway.ConsolidationWitnessGroup[] memory g){
  g=new ConsolidationGateway.ConsolidationWitnessGroup[](1);g[0].sourcePubkeys=new bytes[](2);
  g[0].sourcePubkeys[0]=key(1);g[0].sourcePubkeys[1]=key(3);g[0].targetWitness.pubkey=key(2);
 }
 function setup(uint256 mode) internal returns(PhysicalQuotaHarness g,QuotaInbox i,IWithdrawalVault v,QuotaRefund f){
  vm.deal(address(this),100);g=make(raw(10,6,90,10,1),100);vm.deal(address(g),4);
  uint256 expected=raw(10,5,100,10,1);i=new QuotaInbox(g,expected);f=new QuotaRefund(g,i,expected,mode);
  bytes memory code=abi.encodePacked(vm.getCode("legacy/SettlementVaultHarness.json"),abi.encode(address(g),address(i)));
  address deployed;assembly{deployed:=create(0,add(code,32),mload(code))}require(deployed!=address(0));v=IWithdrawalVault(deployed);vm.deal(deployed,7);
 }
 function testSameQuotaQuoteVaultInboxRefund() external {
  (PhysicalQuotaHarness g,QuotaInbox i,IWithdrawalVault v,QuotaRefund f)=setup(0);
  g.settle{value:6}(v,groups(),address(f));
  require(g.rawQuota()==raw(10,5,100,10,1) && i.calls()==2 && f.seen()==2 && address(g).balance==4 && address(v).balance==7);
  require(i.lastPayload()==keccak256(abi.encodePacked(key(3),key(2))));
 }
 function testLateRefundRestoresQuotaAndAllPriorEffects() external {
  (PhysicalQuotaHarness g,QuotaInbox i,IWithdrawalVault v,QuotaRefund f)=setup(1);
  (bool ok,bytes memory data)=address(g).call{value:6}(abi.encodeCall(g.settle,(v,groups(),address(f))));
  require(!ok && keccak256(data)==keccak256(abi.encodeWithSignature("FeeRefundFailed()")));
  require(g.rawQuota()==raw(10,6,90,10,1) && i.calls()==0 && f.seen()==0 && address(g).balance==4 && address(v).balance==7 && address(i).balance==0 && address(this).balance==100);
 }
 function testAcceptedCallbackCanChangeFinalQuota() external {
  (PhysicalQuotaHarness g,QuotaInbox i,IWithdrawalVault v,QuotaRefund f)=setup(2);
  g.settle{value:6}(v,groups(),address(f));require(g.rawQuota()==123 && i.calls()==2);
 }
 function testFuzzBoundedPhysicalReplenishment(uint32 maximumSeed,uint32 previousSeed,uint32 itemsSeed,uint32 durationSeed,uint32 elapsedSeed,uint32 countSeed,uint96 upper) external {
  uint32 maximum=maximumSeed%100000+1;uint32 previous=previousSeed%(maximum+1);uint32 items=itemsSeed%(maximum+1);uint32 duration=durationSeed%1000+1;uint32 elapsed=elapsedSeed%1000000;
  uint256 current=previous+uint256(elapsed/duration)*items;if(current>maximum)current=maximum;
  uint256 count=countSeed%(current+1);uint256 initial=(raw(maximum,previous,100,duration,items)&((uint256(1)<<160)-1))|(uint256(upper)<<160);
  PhysicalQuotaHarness g=make(initial,100+elapsed);g.consume(count);
  uint256 expected=(raw(maximum,uint32(current-count),100+(elapsed/duration)*duration,duration,items)&((uint256(1)<<160)-1))|(uint256(upper)<<160);
  require(g.rawQuota()==expected,"physical packed transition");
 }
}
