pragma solidity 0.6.12;
import "../src/core/WstETH.sol";
interface Vm {function store(address,bytes32,bytes32) external;function load(address,bytes32) external view returns(bytes32);}
contract TokenReply {
 uint256 public amount=123;uint256 public size=32;uint256 public b;uint256 public transferSize=32;uint256 public calls;
 function configure(uint256 n,uint256 s,uint256 v,uint256 ts) external {amount=n;size=s;b=v;transferSize=ts;}
 fallback() external {
  if(msg.sig==bytes4(0x7a28fb88)){uint256 n=amount;uint256 s=size;assembly{mstore(0,n) return(0,s)}}
  require(msg.sig==bytes4(0xa9059cbb));calls++;uint256 v=b;uint256 s=transferSize;assembly{mstore(0,v) return(0,s)}
 }
}
contract TokenTest {
 Vm constant vm=Vm(address(uint160(uint256(keccak256("hevm cheat code")))));
 function setup() internal returns(WstETH w,TokenReply t){t=new TokenReply();w=new WstETH(IStETH(address(t)));vm.store(address(w),keccak256(abi.encode(address(this),uint256(0))),bytes32(uint256(7)));vm.store(address(w),bytes32(uint256(2)),bytes32(uint256(7)));}
 function testBoolTwo() public { (WstETH w,TokenReply t)=setup();t.configure(123,32,2,32);require(w.unwrap(7)==123);require(t.calls()==1); }
 function testFalseBoolAndTrailing() public {(WstETH w,TokenReply t)=setup();t.configure(123,64,0,64);require(w.unwrap(7)==123 && w.balanceOf(address(this))==0 && w.totalSupply()==0);}
 function testShortTransfer() public {(WstETH w,TokenReply t)=setup();t.configure(123,32,0,31);(bool ok,)=address(w).call(abi.encodeWithSelector(w.unwrap.selector,7));require(!ok&&w.balanceOf(address(this))==7&&w.totalSupply()==7&&t.calls()==0);}
}
