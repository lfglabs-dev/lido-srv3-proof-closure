pragma solidity 0.8.9;
import "../src/BatchHarness.sol";
interface Vm {function getCode(string calldata) external returns(bytes memory);function store(address,bytes32,bytes32) external;}
interface W {function balanceOf(address) external view returns(uint256);function totalSupply() external view returns(uint256);function allowance(address,address) external view returns(uint256);}
contract StDouble {
 BatchHarness public queue;address public wrapper;uint256 public transfers;uint256 public lastAmount;
 bool public pauseOnTransfer;bool public badEight;
 function configure(BatchHarness q,address w,bool p,bool b) external {queue=q;wrapper=w;pauseOnTransfer=p;badEight=b;}
 function getPooledEthByShares(uint256 x) external view returns(uint256){require(msg.sender==wrapper);return badEight&&x==8?99:x*100;}
 function getSharesByPooledEth(uint256 x) external view returns(uint256){require(msg.sender==address(queue));return x+1;}
 function transfer(address to,uint256 amount) external returns(bool){require(msg.sender==wrapper&&to==address(queue));return moved(amount);}
 function transferFrom(address from,address to,uint256 amount) external returns(bool){require(msg.sender==address(queue)&&from!=address(0)&&to==address(queue));return moved(amount);}
 function moved(uint256 amount) internal returns(bool){transfers++;lastAmount=amount;if(pauseOnTransfer)queue.setResume(type(uint256).max);return true;}
}
contract BatchTest {
 Vm constant vm=Vm(address(uint160(uint256(keccak256("hevm cheat code")))));
 function setup(bool pauseCb,bool badEight) internal returns(BatchHarness q,W w,StDouble t){
  t=new StDouble();bytes memory code=abi.encodePacked(vm.getCode("artifacts/WstETH.json"),abi.encode(address(t)));address token;assembly{token:=create(0,add(code,32),mload(code))}require(token!=address(0));w=W(token);
  q=new BatchHarness(IWstETH(token));q.seed(0,0,0,9);q.setResume(0);t.configure(q,token,pauseCb,badEight);
  vm.store(token,keccak256(abi.encode(address(this),uint256(0))),bytes32(uint256(15)));
  vm.store(token,bytes32(uint256(2)),bytes32(uint256(15)));
  vm.store(token,keccak256(abi.encode(address(q),keccak256(abi.encode(address(this),uint256(1))))),bytes32(uint256(15)));
 }
 function two(uint256 a,uint256 b) internal pure returns(uint256[] memory xs){xs=new uint256[](2);xs[0]=a;xs[1]=b;}
 function errorBytes(bytes memory got,bytes memory expected) internal pure {require(keccak256(got)==keccak256(expected),"error bytes");}
 function testPauseBeforeEmptyBoth() public {
  (BatchHarness q,,)=setup(false,false);q.setResume(type(uint256).max);uint256[] memory xs=new uint256[](0);
  (bool ok,bytes memory data)=address(q).call(abi.encodeWithSelector(q.requestWithdrawals.selector,xs,address(0)));require(!ok);errorBytes(data,abi.encodeWithSignature("ResumedExpected()"));
  (ok,data)=address(q).call(abi.encodeWithSelector(q.requestWithdrawalsWstETH.selector,xs,address(0)));require(!ok);errorBytes(data,abi.encodeWithSignature("ResumedExpected()"));
 }
 function testEmptyAtResumeEquality() public {
  (BatchHarness q,,StDouble t)=setup(false,false);q.setResume(block.timestamp);uint256[] memory xs=new uint256[](0);
  require(q.requestWithdrawals(xs,address(0)).length==0&&q.requestWithdrawalsWstETH(xs,address(0)).length==0&&t.transfers()==0&&q.getLastRequestId()==0);
 }
 function testStETHOrderedOwnerAndIds() public {
  (BatchHarness q,,StDouble t)=setup(false,false);uint256[] memory ids=q.requestWithdrawals(two(100,200),address(0));
  require(ids.length==2&&ids[0]==1&&ids[1]==2&&t.transfers()==2&&t.lastAmount()==200);
  require(q.metadata(1).owner==address(this)&&q.metadata(2).owner==address(this));
  require(q.metadata(1).cumulativeStETH==100&&q.metadata(2).cumulativeStETH==300&&q.metadata(2).cumulativeShares==302);
 }
 function testStETHLaterAmountRollback() public {
  (BatchHarness q,,StDouble t)=setup(false,false);
  (bool ok,bytes memory data)=address(q).call(abi.encodeWithSelector(q.requestWithdrawals.selector,two(100,99),address(0)));
  require(!ok);errorBytes(data,abi.encodeWithSignature("RequestAmountTooSmall(uint256)",99));require(q.getLastRequestId()==0&&t.transfers()==0);
 }
 function testStETHGuardBeforeCall() public {
  (BatchHarness q,,StDouble t)=setup(false,false);
  (bool ok,bytes memory data)=address(q).call(abi.encodeWithSelector(q.requestWithdrawals.selector,two(99,100),address(0)));
  require(!ok);errorBytes(data,abi.encodeWithSignature("RequestAmountTooSmall(uint256)",99));require(t.transfers()==0);
 }
 function testActualWrappedTwoItems() public {
  (BatchHarness q,W w,StDouble t)=setup(false,false);uint256[] memory ids=q.requestWithdrawalsWstETH(two(7,8),address(9));
  require(ids.length==2&&ids[0]==1&&ids[1]==2&&q.metadata(2).cumulativeStETH==1500&&q.metadata(2).cumulativeShares==1502);
  require(q.metadata(1).owner==address(9)&&q.metadata(2).owner==address(9)&&t.transfers()==2);
  require(w.balanceOf(address(this))==0&&w.balanceOf(address(q))==0&&w.totalSupply()==0&&w.allowance(address(this),address(q))==0);
 }
 function testActualWrappedLaterAllowanceRollback() public {
  (BatchHarness q,W w,StDouble t)=setup(false,false);
  vm.store(address(w),keccak256(abi.encode(address(q),keccak256(abi.encode(address(this),uint256(1))))),bytes32(uint256(7)));
  (bool ok,bytes memory data)=address(q).call(abi.encodeWithSelector(q.requestWithdrawalsWstETH.selector,two(7,8),address(0)));
  require(!ok);errorBytes(data,abi.encodeWithSignature("Error(string)","ERC20: transfer amount exceeds allowance"));
  require(w.balanceOf(address(this))==15&&w.totalSupply()==15&&w.allowance(address(this),address(q))==7&&q.getLastRequestId()==0&&t.transfers()==0);
 }
 function testActualWrappedLaterAmountRollback() public {
  (BatchHarness q,W w,StDouble t)=setup(false,true);
  (bool ok,bytes memory data)=address(q).call(abi.encodeWithSelector(q.requestWithdrawalsWstETH.selector,two(7,8),address(0)));
  require(!ok);errorBytes(data,abi.encodeWithSignature("RequestAmountTooSmall(uint256)",99));
  require(w.balanceOf(address(this))==15&&w.totalSupply()==15&&w.allowance(address(this),address(q))==15&&q.getLastRequestId()==0&&t.transfers()==0);
 }
 function testPauseCallbackNotRecheckedStETH() public {
  (BatchHarness q,,StDouble t)=setup(true,false);require(q.requestWithdrawals(two(100,200),address(0)).length==2);
  require(q.isPaused()&&q.getLastRequestId()==2&&t.transfers()==2);
 }
 function testPauseCallbackNotRecheckedWrapped() public {
  (BatchHarness q,,StDouble t)=setup(true,false);require(q.requestWithdrawalsWstETH(two(7,8),address(0)).length==2);
  require(q.isPaused()&&q.getLastRequestId()==2&&t.transfers()==2);
 }
 function testFuzzStETHOrderedBatch(uint8 count,uint64 value) public {
  (BatchHarness q,,StDouble t)=setup(false,false);uint256 n=uint256(count)%4+1;uint256[] memory xs=new uint256[](n);uint256 sum;
  for(uint256 j;j<n;++j){xs[j]=100+uint256(value)+j;sum+=xs[j];}
  uint256[] memory ids=q.requestWithdrawals(xs,address(9));require(ids.length==n&&t.transfers()==n);
  for(uint256 j;j<n;++j)require(ids[j]==j+1&&q.metadata(ids[j]).owner==address(9));
  require(q.metadata(n).cumulativeStETH==sum&&q.metadata(n).cumulativeShares==sum+n);
 }
}
