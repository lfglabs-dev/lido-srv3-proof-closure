pragma solidity 0.8.9;
import "../src/WrappedRequestHarness.sol";
interface Vm {function getCode(string calldata) external returns(bytes memory);function store(address,bytes32,bytes32) external;}
interface ActualWstETH {function balanceOf(address) external view returns(uint256);function totalSupply() external view returns(uint256);function allowance(address,address) external view returns(uint256);function wrap(uint256) external returns(uint256);}
contract TokenDouble {
 address public wst;WrappedRequestHarness public queue;
 uint256 public converted=123;uint256 public conversionSize=32;uint256 public boolWord=2;uint256 public transferSize=32;
 uint256 public transfers;uint256 public recipient;uint256 public transferredAmount;bool public callbackMint;
 function setup(address w,WrappedRequestHarness q) external {wst=w;queue=q;}
 function configure(uint256 n,uint256 ns,uint256 b,uint256 bs,bool cb) external {converted=n;conversionSize=ns;boolWord=b;transferSize=bs;callbackMint=cb;}
 fallback() external {
  if(msg.sig==bytes4(0x7a28fb88)) {
   require(msg.sender==wst&&ActualWstETH(wst).balanceOf(address(queue))==7,"conversion before burn");
   uint256 n=converted;uint256 s=conversionSize;assembly {mstore(0,n) return(0,s)}
  }
  if(msg.sig==bytes4(0xa9059cbb)) {
   require(msg.sender==wst&&ActualWstETH(wst).balanceOf(address(queue))==0&&ActualWstETH(wst).totalSupply()==0,"burn before transfer");
   (address to,uint256 amount)=abi.decode(msg.data[4:],(address,uint256));require(to==address(queue)&&amount==converted,"actual transfer payload");
   transfers++;recipient=uint160(to);transferredAmount=amount;
   if(callbackMint) ActualWstETH(wst).wrap(1);
   uint256 b=boolWord;uint256 s=transferSize;assembly {mstore(0,b) return(0,s)}
  }
  if(msg.sig==bytes4(0x19208451)) {
   uint256 x=abi.decode(msg.data[4:],(uint256));
   if(msg.sender==address(queue)) require(x==converted&&transfers==1,"same actual unwrap return");
   else require(msg.sender==wst&&x==1,"callback conversion");
   uint256 sh=msg.sender==wst?5:(uint256(1)<<128)+5;assembly {mstore(0,sh) return(0,32)}
  }
  require(msg.sig==bytes4(0x23b872dd)&&msg.sender==wst,"unexpected stETH transferFrom");
  assembly {mstore(0,1) return(0,32)}
 }
}
contract ActualWrappedTokenTest {
 Vm constant vm=Vm(address(uint160(uint256(keccak256("hevm cheat code")))));
 function setup() internal returns(WrappedRequestHarness q,ActualWstETH w,TokenDouble t){
  t=new TokenDouble();bytes memory code=abi.encodePacked(vm.getCode("artifacts/WstETH.json"),abi.encode(address(t)));address deployed;assembly{deployed:=create(0,add(code,32),mload(code))}require(deployed!=address(0));w=ActualWstETH(deployed);
  q=new WrappedRequestHarness(IWstETH(deployed));q.seed(0,0,0,9);t.setup(deployed,q);
  vm.store(deployed,keccak256(abi.encode(address(this),uint256(0))),bytes32(uint256(7)));
  vm.store(deployed,bytes32(uint256(2)),bytes32(uint256(7)));
  vm.store(deployed,keccak256(abi.encode(address(q),keccak256(abi.encode(address(this),uint256(1))))),bytes32(uint256(7)));
 }
 function failure(WrappedRequestHarness q,ActualWstETH w,TokenDouble t,bytes memory expected) internal {
  (bool ok,bytes memory data)=address(q).call(abi.encodeWithSelector(q.one.selector,7,address(0)));
  require(!ok&&keccak256(data)==keccak256(expected),"error category/bytes");
  require(w.balanceOf(address(this))==7&&w.balanceOf(address(q))==0&&w.allowance(address(this),address(q))==7,"actual token rollback");
  require(t.transfers()==0&&q.getLastRequestId()==0,"callee queue rollback");
 }
 function testActualTokenCallerEnqueueAndBoolTwo() public {
  (WrappedRequestHarness q,ActualWstETH w,TokenDouble t)=setup();require(q.one(7,address(0))==1);
  require(w.balanceOf(address(this))==0&&w.balanceOf(address(q))==0&&w.totalSupply()==0&&w.allowance(address(this),address(q))==0);
  WithdrawalQueueBase.WithdrawalRequest memory r=q.metadata(1);require(r.cumulativeStETH==123&&r.cumulativeShares==5&&r.owner==address(this));
  require(t.transfers()==1&&t.transferredAmount()==123&&t.recipient()==uint160(address(q)));
 }
 function testArbitraryStETHCanChangeSupplyAfterBurn() public {
  (WrappedRequestHarness q,ActualWstETH w,TokenDouble t)=setup();t.configure(123,32,2,32,true);require(q.one(7,address(0))==1);
  require(w.totalSupply()==5&&w.balanceOf(address(t))==5,"actual callback mint after burn");
 }
 function testFalseAndTrailingTransferAccepted() public {
  (WrappedRequestHarness q,,TokenDouble t)=setup();t.configure(123,64,0,64,false);require(q.one(7,address(0))==1);
 }
 function testConversionDecodeFailureBeforeBurn() public {
  (WrappedRequestHarness q,ActualWstETH w,TokenDouble t)=setup();t.configure(123,31,0,32,false);failure(q,w,t,"");require(w.totalSupply()==7);
 }
 function testTransferDecodeFailureRollsBackBurn() public {
  (WrappedRequestHarness q,ActualWstETH w,TokenDouble t)=setup();t.configure(123,32,0,31,false);failure(q,w,t,"");require(w.totalSupply()==7);
 }
 function testSupplySafeMathFailureAfterBalanceWrite() public {
  (WrappedRequestHarness q,ActualWstETH w,TokenDouble t)=setup();vm.store(address(w),bytes32(uint256(2)),bytes32(uint256(6)));
  failure(q,w,t,abi.encodeWithSignature("Error(string)","SafeMath: subtraction overflow"));require(w.totalSupply()==6);
 }
 function testLateCallerAmountFailureRollsBackActualToken() public {
  (WrappedRequestHarness q,ActualWstETH w,TokenDouble t)=setup();t.configure(99,32,2,32,false);failure(q,w,t,abi.encodeWithSignature("RequestAmountTooSmall(uint256)",99));require(w.totalSupply()==7);
 }
 function testFuzzConvertedAmountDrivesSameEnqueue(uint96 n,uint256 boolReturn) public {
  (WrappedRequestHarness q,,TokenDouble t)=setup();uint256 amount=100+uint256(n)%(1000e18-99);t.configure(amount,33,boolReturn,33,false);require(q.one(7,address(0))==1);
  require(q.metadata(1).cumulativeStETH==amount&&t.transferredAmount()==amount);
 }
}
