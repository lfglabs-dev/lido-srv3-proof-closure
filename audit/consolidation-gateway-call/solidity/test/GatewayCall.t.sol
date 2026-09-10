pragma solidity 0.8.25;
interface Vm {
 function deal(address,uint256) external;
 function getCode(string calldata) external returns(bytes memory);
}
interface IWithdrawalVault { function addConsolidationRequests(bytes[] calldata,bytes[] calldata) external payable; }
contract Inbox {
 uint256 public count;
 bytes32 public first;
 bytes32 public second;
 bool public rejectSecond;
 function setRejectSecond() external {rejectSecond=true;}
 fallback() external payable {
  if(msg.data.length==0){assembly{mstore(0,2) return(0,32)}}
  require(msg.data.length==96 && msg.value==2);
  if(rejectSecond && count==1) revert();
  if(count==0)first=keccak256(msg.data);else second=keccak256(msg.data);
  ++count;
 }
}
contract GatewayCallTest {
 Vm constant vm=Vm(address(uint160(uint256(keccak256("hevm cheat code")))));
 function key(uint8 b) internal pure returns(bytes memory k){k=new bytes(48);for(uint i;i<48;++i)k[i]=bytes1(b);}
 function arrays() internal pure returns(bytes[] memory s,bytes[] memory t){s=new bytes[](2);t=new bytes[](2);s[0]=key(1);s[1]=key(3);t[0]=key(2);t[1]=key(2);}
 function vault(address gateway,Inbox inbox) internal returns(IWithdrawalVault v){
  bytes memory code=abi.encodePacked(vm.getCode("VaultHarness.sol:VaultHarness"),abi.encode(gateway,address(inbox)));
  address deployed;assembly{deployed:=create(0,add(code,32),mload(code))}require(deployed!=address(0));
  vm.deal(deployed,7);v=IWithdrawalVault(deployed);
 }
 // Exact high-level call expression from ConsolidationGateway.sol:220.
 function dispatch(IWithdrawalVault withdrawalVault,bytes[] memory sourcePubkeys,bytes[] memory targetPubkeys,uint256 totalFee) external {
  withdrawalVault.addConsolidationRequests{value: totalFee}(sourcePubkeys, targetPubkeys);
 }
 function testTwoPairsExactPayloadValueAndVaultBalance() external {
  vm.deal(address(this),100);Inbox inbox=new Inbox();IWithdrawalVault v=vault(address(this),inbox);(bytes[] memory s,bytes[] memory t)=arrays();
  this.dispatch(v,s,t,4);
  require(address(this).balance==96 && address(v).balance==7 && address(inbox).balance==4);
  require(inbox.count()==2 && inbox.first()==keccak256(bytes.concat(key(1),key(2))) && inbox.second()==keccak256(bytes.concat(key(3),key(2))));
 }
 function testIndependentGatewayAuthorization() external {
  vm.deal(address(this),100);Inbox inbox=new Inbox();IWithdrawalVault v=vault(address(123),inbox);(bytes[] memory s,bytes[] memory t)=arrays();
  (bool ok,bytes memory errorData)=address(this).call(abi.encodeCall(this.dispatch,(v,s,t,4)));
  require(!ok && keccak256(errorData)==keccak256(hex"b7d22932"));require(address(this).balance==100 && inbox.count()==0);
 }
 function testIncorrectFeeBytesAndRollback() external {
  vm.deal(address(this),100);Inbox inbox=new Inbox();IWithdrawalVault v=vault(address(this),inbox);(bytes[] memory s,bytes[] memory t)=arrays();
  (bool ok,bytes memory errorData)=address(this).call(abi.encodeCall(this.dispatch,(v,s,t,3)));
  require(!ok && keccak256(errorData)==keccak256(abi.encodeWithSelector(bytes4(0xdcf6afcb),uint256(4),uint256(3))));
  require(address(v).balance==7 && address(this).balance==100 && inbox.count()==0);
 }
 function testSecondCallFailureRestoresFirstEffectsAndCarriesPayload() external {
  vm.deal(address(this),100);Inbox inbox=new Inbox();inbox.setRejectSecond();IWithdrawalVault v=vault(address(this),inbox);(bytes[] memory s,bytes[] memory t)=arrays();
  (bool ok,bytes memory errorData)=address(this).call(abi.encodeCall(this.dispatch,(v,s,t,4)));
  require(!ok && keccak256(errorData)==keccak256(abi.encodeWithSelector(bytes4(0xef36228e),bytes.concat(key(3),key(2)))));
  require(address(v).balance==7 && address(this).balance==100 && address(inbox).balance==0 && inbox.count()==0 && inbox.first()==bytes32(0));
 }
 function testHighLevelNoCodeRejects() external {
  vm.deal(address(this),100);(bytes[] memory s,bytes[] memory t)=arrays();
  (bool ok,bytes memory errorData)=address(this).call(abi.encodeCall(this.dispatch,(IWithdrawalVault(address(456)),s,t,4)));
  require(!ok && errorData.length==0 && address(this).balance==100);
 }
}
