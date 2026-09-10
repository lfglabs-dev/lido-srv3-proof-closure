// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.25;
import "../src/SettlementHarness.sol";
interface Vm {
 function deal(address,uint256) external;
 function getCode(string calldata) external returns(bytes memory);
}
contract SettlementInbox {
 uint256 public count;
 bytes32 public lastPayload;
 uint256 public fee=2;
 uint256 public mode;
 address public gateway;
 function configure(uint256 f,uint256 m,address g) external {fee=f;mode=m;gateway=g;}
 fallback() external payable {
  if(msg.data.length==0){
   if(mode==1){assembly{mstore(0,1) return(31,1)}}
   if(mode==2)revert();
   uint256 f=mode==3?(gateway.balance==10?2:3):fee;
   assembly{mstore(0,f) return(0,32)}
  }
  require(msg.data.length==96 && msg.value==fee);
  lastPayload=keccak256(msg.data);++count;
 }
}
contract ObservingRecipient {
 SettlementInbox public inbox;
 bool public reject;
 uint256 public seen;
 constructor(SettlementInbox i,bool r){inbox=i;reject=r;}
 receive() external payable {
  require(inbox.count()==2 && address(inbox).balance==4 && msg.value==2);
  seen=inbox.count();if(reject)revert();
 }
}
contract ForceBack {
 constructor(address payable target) payable {selfdestruct(target);}
}
contract ReturningRecipient {
 receive() external payable {new ForceBack{value:msg.value}(payable(msg.sender));}
}
contract SettlementTest {
 Vm constant vm=Vm(address(uint160(uint256(keccak256("hevm cheat code")))));
 receive() external payable {}
 function key(uint8 b) internal pure returns(bytes memory k){k=new bytes(48);for(uint i;i<48;++i)k[i]=bytes1(b);}
 function groups() internal pure returns(SettlementHarness.ConsolidationWitnessGroup[] memory g){
  g=new SettlementHarness.ConsolidationWitnessGroup[](1);g[0].sourcePubkeys=new bytes[](2);
  g[0].sourcePubkeys[0]=key(1);g[0].sourcePubkeys[1]=key(3);g[0].targetWitness.pubkey=key(2);
 }
 function setup() internal returns(SettlementHarness g,SettlementInbox i,IWithdrawalVault v){
  vm.deal(address(this),100);g=new SettlementHarness();vm.deal(address(g),4);i=new SettlementInbox();
  bytes memory code=abi.encodePacked(vm.getCode("SettlementVaultHarness.sol:SettlementVaultHarness"),abi.encode(address(g),address(i)));
  address deployed;assembly{deployed:=create(0,add(code,32),mload(code))}require(deployed!=address(0));
  vm.deal(deployed,7);v=IWithdrawalVault(deployed);
 }
 function testRefundSeesPriorVaultEffects() external {
  (SettlementHarness g,SettlementInbox i,IWithdrawalVault v)=setup();ObservingRecipient r=new ObservingRecipient(i,false);
  g.settle{value:6}(v,groups(),address(r));
  require(address(g).balance==4 && address(v).balance==7 && address(i).balance==4 && address(r).balance==2 && r.seen()==2 && i.count()==2);
 }
 function testRefundFailureRollsBackVaultStorageAndTransfers() external {
  (SettlementHarness g,SettlementInbox i,IWithdrawalVault v)=setup();ObservingRecipient r=new ObservingRecipient(i,true);
  (bool ok,bytes memory data)=address(g).call{value:6}(abi.encodeCall(g.settle,(v,groups(),address(r))));
  require(!ok && keccak256(data)==keccak256(abi.encodeWithSelector(SettlementHarness.FeeRefundFailed.selector)));
  require(address(this).balance==100 && address(g).balance==4 && address(v).balance==7 && address(i).balance==0 && i.count()==0 && i.lastPayload()==bytes32(0) && r.seen()==0);
 }
 function testZeroRefundSkipsRejectingRecipient() external {
  (SettlementHarness g,SettlementInbox i,IWithdrawalVault v)=setup();ObservingRecipient r=new ObservingRecipient(i,true);
  g.settle{value:4}(v,groups(),address(r));require(i.count()==2 && r.seen()==0 && address(g).balance==4);
 }
 function testEOARefundAndZeroRecipientFallback() external {
  (SettlementHarness g,SettlementInbox i,IWithdrawalVault v)=setup();address recipient=address(0xfeed);
  g.settle{value:6}(v,groups(),recipient);require(recipient.balance==2 && i.count()==2 && address(g).balance==4);
  g.settle{value:6}(v,groups(),address(0));require(address(this).balance==90 && i.count()==4 && address(g).balance==4);
 }
 function testFeeRequotedOnVaultCreditedWorld() external {
  (SettlementHarness g,SettlementInbox i,IWithdrawalVault v)=setup();i.configure(2,3,address(g));
  (bool ok,bytes memory data)=address(g).call{value:6}(abi.encodeCall(g.settle,(v,groups(),address(0xfeed))));
  require(!ok && keccak256(data)==keccak256(abi.encodeWithSelector(bytes4(0xdcf6afcb),uint256(6),uint256(4))));
  require(i.count()==0 && address(g).balance==4);
 }
 function testCheckedProductOverflowBeforeVault() external {
  (SettlementHarness g,SettlementInbox i,IWithdrawalVault v)=setup();i.configure(2**255,0,address(g));
  (bool ok,bytes memory data)=address(g).call{value:6}(abi.encodeCall(g.settle,(v,groups(),address(0xfeed))));
  require(!ok && keccak256(data)==keccak256(abi.encodeWithSelector(bytes4(0x4e487b71),uint256(0x11))) && i.count()==0);
 }
 function testShortFeeAndFeeReadFailure() external {
  (SettlementHarness g,SettlementInbox i,IWithdrawalVault v)=setup();i.configure(2,1,address(g));
  (bool ok,bytes memory data)=address(g).call{value:6}(abi.encodeCall(g.settle,(v,groups(),address(0xfeed))));
  require(!ok && keccak256(data)==keccak256(hex"8235fc55") && i.count()==0);
  i.configure(2,2,address(g));
  (ok,data)=address(g).call{value:6}(abi.encodeCall(g.settle,(v,groups(),address(0xfeed))));
  require(!ok && keccak256(data)==keccak256(hex"03045050") && i.count()==0);
 }
 function testAcceptedRefundCallbackCannotEvadeGatewayBalanceAssertion() external {
  (SettlementHarness g,SettlementInbox i,IWithdrawalVault v)=setup();ReturningRecipient r=new ReturningRecipient();
  (bool ok,bytes memory data)=address(g).call{value:6}(abi.encodeCall(g.settle,(v,groups(),address(r))));
  require(!ok && keccak256(data)==keccak256(abi.encodeWithSelector(bytes4(0x4e487b71),uint256(1))));
  require(address(this).balance==100 && address(g).balance==4 && address(v).balance==7 && address(i).balance==0 && i.count()==0);
 }
 function testCodeLessVaultFailsTypedReturnDecode() external {
  (SettlementHarness g,,)=setup();
  (bool ok,bytes memory data)=address(g).call{value:6}(abi.encodeCall(g.settle,(IWithdrawalVault(address(0xfeed)),groups(),address(0))));
  require(!ok && data.length==0 && address(g).balance==4 && address(this).balance==100);
 }
}
