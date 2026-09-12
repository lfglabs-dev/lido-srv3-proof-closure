// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.25;
import {PhysicalEntryHarness} from "./PhysicalEntryHarness.sol";
import {ConsolidationGateway,IWithdrawalVault} from "contracts/0.8.25/consolidation/ConsolidationGateway.sol";
interface Vm {function warp(uint256) external;function deal(address,uint256) external;function getCode(string calldata) external returns(bytes memory);}
interface QuotaInbox {function calls() external view returns(uint256);function lastPayload() external view returns(bytes32);}
interface QuotaRefund {function seen() external view returns(uint256);}
contract PhysicalEntryTest {
 Vm constant vm=Vm(address(uint160(uint256(keccak256("hevm cheat code")))));
 function raw(uint32 maximum,uint32 previous,uint32 timestamp,uint32 duration,uint32 items) internal pure returns(uint256){return uint256(maximum)|(uint256(previous)<<32)|(uint256(timestamp)<<64)|(uint256(duration)<<96)|(uint256(items)<<128)|(uint256(1)<<255);}
 function make(uint256 value,uint256 time) internal returns(PhysicalEntryHarness g){vm.warp(time);g=new PhysicalEntryHarness();g.setRaw(value);g.setResume(time);g.seedRole(address(this),(uint256(1)<<255)+2);}
 function deploy(string memory path,bytes memory args) internal returns(address deployed){bytes memory code=abi.encodePacked(vm.getCode(path),args);assembly{deployed:=create(0,add(code,32),mload(code))}require(deployed!=address(0));}
 function denied(PhysicalEntryHarness g,bytes memory payload,uint256 value,bytes memory expected) internal { (bool ok,bytes memory data)=address(g).call{value:value}(payload);require(!ok && keccak256(data)==keccak256(expected),"exact competing guard"); }
 function unauth(PhysicalEntryHarness g) internal view returns(bytes memory){return abi.encodeWithSignature("AccessControlUnauthorizedAccount(address,bytes32)",address(this),g.ADD_CONSOLIDATION_REQUEST_ROLE());}
 function empty(PhysicalEntryHarness g) internal pure returns(bytes memory){ConsolidationGateway.ConsolidationWitnessGroup[] memory a=new ConsolidationGateway.ConsolidationWitnessGroup[](0);return abi.encodeCall(g.addConsolidationRequests,(a,address(0)));}
 function testActualRoleBeforePauseAndZero() external {PhysicalEntryHarness g=make(0,100);g.seedRole(address(this),uint256(1)<<255);g.setResume(101);denied(g,empty(g),0,unauth(g));}
 function testActualPauseBeforeZeroAndEquality() external {PhysicalEntryHarness g=make(0,100);g.setResume(101);denied(g,empty(g),0,abi.encodeWithSignature("ResumedExpected()"));g.setResume(100);denied(g,empty(g),0,abi.encodeWithSignature("ZeroArgument(string)","msg.value"));}
 function testFullPauseWordAndMaxBoundary() external {PhysicalEntryHarness g=make(0,100);g.setResume(type(uint256).max);denied(g,empty(g),0,abi.encodeWithSignature("ResumedExpected()"));vm.warp(type(uint256).max);denied(g,empty(g),0,abi.encodeWithSignature("ZeroArgument(string)","msg.value"));}
 function testActualCallerKey() external {PhysicalEntryHarness g=make(0,100);g.seedRole(address(this),0);g.seedRole(address(17),2);denied(g,empty(g),0,unauth(g));}
 function testInstrumentedBalancePriority() external {vm.deal(address(this),10);PhysicalEntryHarness g=make(0,100);g.setResume(101);g.seedRole(address(this),0);denied(g,abi.encodeCall(g.charged,()),1,unauth(g));g.seedRole(address(this),2);denied(g,abi.encodeCall(g.charged,()),1,abi.encodeWithSignature("Panic(uint256)",0x11));}
 function key(uint8 b) internal pure returns(bytes memory k){k=new bytes(48);for(uint256 i;i<48;++i)k[i]=bytes1(b);}
 function groups() internal pure returns(ConsolidationGateway.ConsolidationWitnessGroup[] memory g){
  g=new ConsolidationGateway.ConsolidationWitnessGroup[](1);g[0].sourcePubkeys=new bytes[](2);
  g[0].sourcePubkeys[0]=key(1);g[0].sourcePubkeys[1]=key(3);g[0].targetWitness.pubkey=key(2);
 }
 function setup(uint256 mode) internal returns(PhysicalEntryHarness g,QuotaInbox i,IWithdrawalVault v,QuotaRefund f){
  vm.deal(address(this),100);g=make(raw(10,6,90,10,1),100);vm.deal(address(g),4);
  uint256 expected=raw(10,5,100,10,1);i=QuotaInbox(deploy("legacy/QuotaInbox.json",abi.encode(address(g),expected)));f=QuotaRefund(deploy("legacy/QuotaRefund.json",abi.encode(address(g),address(i),expected,mode)));
  bytes memory code=abi.encodePacked(vm.getCode("legacy/SettlementVaultHarness.json"),abi.encode(address(g),address(i)));
  address deployed;assembly{deployed:=create(0,add(code,32),mload(code))}require(deployed!=address(0));v=IWithdrawalVault(deployed);vm.deal(deployed,7);
 }
 function testSameQuotaQuoteVaultInboxRefund() external {
  (PhysicalEntryHarness g,QuotaInbox i,IWithdrawalVault v,QuotaRefund f)=setup(0);
  g.entry{value:6}(v,groups(),address(f));
  require(g.rawQuota()==raw(10,5,100,10,1) && i.calls()==2 && f.seen()==2 && address(g).balance==4 && address(v).balance==7);
  require(i.lastPayload()==keccak256(abi.encodePacked(key(3),key(2))));
 }
 function testLateRefundRestoresQuotaAndAllPriorEffects() external {
  (PhysicalEntryHarness g,QuotaInbox i,IWithdrawalVault v,QuotaRefund f)=setup(1);
  (bool ok,bytes memory data)=address(g).call{value:6}(abi.encodeCall(g.entry,(v,groups(),address(f))));
  require(!ok && keccak256(data)==keccak256(abi.encodeWithSignature("FeeRefundFailed()")));
  require(g.rawQuota()==raw(10,6,90,10,1) && i.calls()==0 && f.seen()==0 && address(g).balance==4 && address(v).balance==7 && address(i).balance==0 && address(this).balance==100);
 }
 function testAcceptedCallbackCanChangeFinalQuota() external {
  (PhysicalEntryHarness g,QuotaInbox i,IWithdrawalVault v,QuotaRefund f)=setup(2);
  g.entry{value:6}(v,groups(),address(f));require(g.rawQuota()==123 && i.calls()==2);
 }
 function testFuzzRawRoleAndResume(uint256 roleWord,uint256 resume) external {PhysicalEntryHarness g=make(0,1000);g.seedRole(address(this),roleWord);g.setResume(resume);bytes memory expected=roleWord%256==0?unauth(g):(resume>1000?abi.encodeWithSignature("ResumedExpected()"):abi.encodeWithSignature("ZeroArgument(string)","msg.value"));denied(g,empty(g),0,expected);}
}
