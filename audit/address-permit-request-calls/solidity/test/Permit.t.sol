pragma solidity 0.8.9;
import "./Batches.t.sol";
interface SignatureVm {function addr(uint256) external returns(address);function sign(uint256,bytes32) external returns(uint8,bytes32,bytes32);function prank(address) external;function etch(address,bytes calldata) external;}
interface PermitW is W {function DOMAIN_SEPARATOR() external view returns(bytes32);function nonces(address) external view returns(uint256);}
// Explicit void permit double: records transport, does not authenticate signatures.
contract PermitSt is StDouble {
 uint256 public permitValue;uint256 public permitDeadline;uint8 public permitV;bytes32 public permitR;bytes32 public permitS;address public permitOwner;
 bool public failPermit;uint256 public returnSize=1;
 event PermitObserved(address owner,address spender,uint256 value);
 function mode(bool fail,uint256 size) external {failPermit=fail;returnSize=size;}
 function permit(address owner,address spender,uint256 value,uint256 deadline,uint8 v,bytes32 r,bytes32 s) external {
  require(msg.sender==address(queue)&&spender==address(queue)&&owner!=address(0)&&msg.data.length==228,"actual transport");
  if(failPermit)assembly{mstore(0,0xaabb) revert(30,2)}
  permitOwner=owner;permitValue=value;permitDeadline=deadline;permitV=v;permitR=r;permitS=s;emit PermitObserved(owner,spender,value);
  uint256 n=returnSize;assembly{mstore(0,not(0)) return(0,n)}
 }
}
contract PermitTest {
 Vm constant vm=Vm(address(uint160(uint256(keccak256("hevm cheat code")))));
 SignatureVm constant sigVm=SignatureVm(address(uint160(uint256(keccak256("hevm cheat code")))));
 function setup(address user) internal returns(BatchHarness q,PermitW w,PermitSt t){
  t=new PermitSt();bytes memory code=abi.encodePacked(vm.getCode("artifacts/WstETH.json"),abi.encode(address(t)));address token;assembly{token:=create(0,add(code,32),mload(code))}require(token!=address(0));w=PermitW(token);
  q=new BatchHarness(IWstETH(token));q.seed(0,0,0,9);q.setResume(0);t.configure(q,token,false,false);
  vm.store(token,keccak256(abi.encode(user,uint256(0))),bytes32(uint256(15)));vm.store(token,bytes32(uint256(2)),bytes32(uint256(15)));
 }
 function xs(uint256 a,uint256 b) internal pure returns(uint256[] memory z){z=new uint256[](2);z[0]=a;z[1]=b;}
 function data() internal pure returns(WithdrawalQueue.PermitInput memory){return WithdrawalQueue.PermitInput(15,500,255,bytes32(uint256(8)),bytes32(uint256(9)));}
 function signed(BatchHarness q,PermitW w,address user) internal returns(WithdrawalQueue.PermitInput memory p){
  p.value=15;p.deadline=type(uint256).max;
  bytes32 h=keccak256(abi.encode(keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),user,address(q),p.value,w.nonces(user),p.deadline));
  (p.v,p.r,p.s)=sigVm.sign(1,keccak256(abi.encodePacked(hex"1901",w.DOMAIN_SEPARATOR(),h)));
 }
 function testVoidMalformedSuccessThenActualStBatch() public {
  (BatchHarness q,,PermitSt t)=setup(address(this));uint256[] memory ids=q.requestWithdrawalsWithPermit(xs(100,200),address(0),data());
  require(ids.length==2&&ids[0]==1&&ids[1]==2&&t.permitValue()==15&&t.permitOwner()==address(this)&&t.transfers()==2);
 }
 function testPermitFailureBeforePause() public {
  (BatchHarness q,,PermitSt t)=setup(address(this));q.setResume(type(uint256).max);t.mode(true,0);
  (bool ok,bytes memory ret)=address(q).call(abi.encodeWithSelector(q.requestWithdrawalsWithPermit.selector,new uint256[](0),address(0),data()));require(!ok&&keccak256(ret)==keccak256(hex"aabb"));
 }
 function testNoCodeBeforePause() public {
  (BatchHarness q,,PermitSt t)=setup(address(this));q.setResume(type(uint256).max);sigVm.etch(address(t),hex"");
  (bool ok,bytes memory ret)=address(q).call(abi.encodeWithSelector(q.requestWithdrawalsWithPermit.selector,new uint256[](0),address(0),data()));require(!ok&&ret.length==0);
 }
 function testPausedEmptyRestoresPermit() public {
  (BatchHarness q,,PermitSt t)=setup(address(this));q.setResume(type(uint256).max);
  (bool ok,bytes memory ret)=address(q).call(abi.encodeWithSelector(q.requestWithdrawalsWithPermit.selector,new uint256[](0),address(0),data()));require(!ok&&keccak256(ret)==keccak256(abi.encodeWithSignature("ResumedExpected()"))&&t.permitValue()==0);
 }
 function testLaterStItemRestoresPermit() public {
  (BatchHarness q,,PermitSt t)=setup(address(this));
  (bool ok,bytes memory ret)=address(q).call(abi.encodeWithSelector(q.requestWithdrawalsWithPermit.selector,xs(100,99),address(0),data()));require(!ok&&keccak256(ret)==keccak256(abi.encodeWithSignature("RequestAmountTooSmall(uint256)",99))&&t.permitValue()==0&&t.transfers()==0&&q.getLastRequestId()==0);
 }
 function testRealTokenPermitConsumedByTwoItems() public {
  address user=sigVm.addr(1);(BatchHarness q,PermitW w,)=setup(user);WithdrawalQueue.PermitInput memory p=signed(q,w,user);sigVm.prank(user);uint256[] memory ids=q.requestWithdrawalsWstETHWithPermit(xs(7,8),address(0),p);
  require(ids.length==2&&ids[1]==2&&w.nonces(user)==1&&w.allowance(user,address(q))==0&&w.balanceOf(user)==0&&w.totalSupply()==0);
 }
 function testRealTokenPermitLaterItemRollback() public {
  address user=sigVm.addr(1);(BatchHarness q,PermitW w,PermitSt t)=setup(user);WithdrawalQueue.PermitInput memory p=signed(q,w,user);sigVm.prank(user);
  (bool ok,)=address(q).call(abi.encodeWithSelector(q.requestWithdrawalsWstETHWithPermit.selector,xs(7,9),address(0),p));require(!ok&&w.nonces(user)==0&&w.allowance(user,address(q))==0&&w.balanceOf(user)==15&&w.totalSupply()==15&&q.getLastRequestId()==0&&t.transfers()==0);
 }
 function testRealPermitPausedEmptyRollback() public {
  address user=sigVm.addr(1);(BatchHarness q,PermitW w,)=setup(user);WithdrawalQueue.PermitInput memory p=signed(q,w,user);q.setResume(type(uint256).max);sigVm.prank(user);
  (bool ok,bytes memory ret)=address(q).call(abi.encodeWithSelector(q.requestWithdrawalsWstETHWithPermit.selector,new uint256[](0),address(0),p));require(!ok&&keccak256(ret)==keccak256(abi.encodeWithSignature("ResumedExpected()"))&&w.nonces(user)==0&&w.allowance(user,address(q))==0);
 }
 function testFuzzSevenFieldsIgnoredVoid(uint256 value,uint256 deadline,uint8 v,bytes32 r,bytes32 s,uint8 n) public {
  (BatchHarness q,,PermitSt t)=setup(address(this));t.mode(false,uint256(n)%65);q.requestWithdrawalsWithPermit(new uint256[](0),address(9),WithdrawalQueue.PermitInput(value,deadline,v,r,s));
  require(t.permitOwner()==address(this)&&t.permitValue()==value&&t.permitDeadline()==deadline&&t.permitV()==v&&t.permitR()==r&&t.permitS()==s);
 }
}
