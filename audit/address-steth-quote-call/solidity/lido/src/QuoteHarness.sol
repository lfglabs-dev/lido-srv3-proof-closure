pragma solidity 0.4.24;
import "./contracts/0.4.24/Lido.sol";
// Only mutable boundary doubles. All quote/rate functions remain inherited Lido.
contract QuoteHarness is Lido {
 address public queue; address public wrapper; uint256 public moves; uint256 public permitWrites; bool public zeroSecond;
 function configure(address q,address w,bool z) external {queue=q;wrapper=w;zeroSecond=z;}
 function permit(address owner,address spender,uint256,uint256,uint8,bytes32,bytes32) external {
  require(msg.sender==queue&&spender==queue&&owner!=address(0)&&msg.data.length==228); permitWrites++;
  emit Approval(owner,spender,15);
 }
 function transferFrom(address from,address to,uint256) external returns(bool){require(msg.sender==queue&&to==queue&&from!=address(0));return moved();}
 function transfer(address to,uint256) external returns(bool){require(msg.sender==wrapper&&to==queue);return moved();}
 function moved() internal returns(bool){
  moves++;bytes32 slot=0x81a11fa1111afa59b50051f60ccf604a39d96acb484dc467ad8eadb4a63f0a5f;
  uint256 value=(zeroSecond&&moves==2)?0:(moves==1?3000:6000);
  assembly{sstore(slot,value)} return true;
 }
}
