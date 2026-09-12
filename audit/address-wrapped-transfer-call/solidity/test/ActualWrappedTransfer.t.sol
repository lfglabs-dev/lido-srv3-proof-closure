pragma solidity 0.8.9;
import "./ActualWrappedToken.t.sol";
interface TransferToken {function transferFrom(address,address,uint256) external returns(bool);}
interface TraceVm {
 struct Log {bytes32[] topics;bytes data;address emitter;}
 function recordLogs() external;
 function getRecordedLogs() external returns(Log[] memory);
}
// Inherits and FRESHLY executes the eight full actual queue/token tests,
// including arbitrary stETH callback, decode/late-amount rollback and fuzz1024.
contract ActualWrappedTransferTest is ActualWrappedTokenTest {
 TraceVm constant traceVm=TraceVm(address(uint160(uint256(keccak256("hevm cheat code")))));
 function approvalSlot(address owner,address spender) internal pure returns(bytes32) {
  return keccak256(abi.encode(spender,keccak256(abi.encode(owner,uint256(1)))));
 }
 function testSelfTransferFreshRecipientAndNestedAllowance() public {
  (,ActualWstETH w,)=setup();
  vm.store(address(w),approvalSlot(address(this),address(this)),bytes32(uint256(7)));
  bytes32 decoy=approvalSlot(address(9),address(this));vm.store(address(w),decoy,bytes32(uint256(555)));
  traceVm.recordLogs();
  require(TransferToken(address(w)).transferFrom(address(this),address(this),7));
  require(w.balanceOf(address(this))==7&&w.allowance(address(this),address(this))==0,"self-transfer fresh recipient");
  require(w.allowance(address(9),address(this))==555,"unrelated nested entry");
  TraceVm.Log[] memory logs=traceVm.getRecordedLogs();require(logs.length==2,"two source events");
  require(logs[0].emitter==address(w)&&logs[0].topics[0]==keccak256("Transfer(address,address,uint256)")&&abi.decode(logs[0].data,(uint256))==7);
  require(logs[1].topics[0]==keccak256("Approval(address,address,uint256)")&&abi.decode(logs[1].data,(uint256))==0);
 }
 function testInsufficientAllowanceRollsBackPrecedingTransfer() public {
  (WrappedRequestHarness q,ActualWstETH w,TokenDouble t)=setup();
  vm.store(address(w),approvalSlot(address(this),address(q)),bytes32(uint256(6)));
  (bool ok,bytes memory data)=address(q).call(abi.encodeWithSelector(q.one.selector,7,address(0)));
  require(!ok&&keccak256(data)==keccak256(abi.encodeWithSignature("Error(string)","ERC20: transfer amount exceeds allowance")));
  require(w.balanceOf(address(this))==7&&w.balanceOf(address(q))==0&&w.allowance(address(this),address(q))==6&&t.transfers()==0&&q.getLastRequestId()==0);
 }
 function testBalanceErrorPrecedesAllowance() public {
  (,ActualWstETH w,)=setup();
  (bool ok,bytes memory data)=address(w).call(abi.encodeWithSelector(TransferToken.transferFrom.selector,address(this),address(9),8));
  require(!ok&&keccak256(data)==keccak256(abi.encodeWithSignature("Error(string)","ERC20: transfer amount exceeds balance")));
 }
 function testRecipientOverflowPrecedesAllowance() public {
  (,ActualWstETH w,)=setup();
  vm.store(address(w),keccak256(abi.encode(address(9),uint256(0))),bytes32(type(uint256).max));
  (bool ok,bytes memory data)=address(w).call(abi.encodeWithSelector(TransferToken.transferFrom.selector,address(this),address(9),7));
  require(!ok&&keccak256(data)==keccak256(abi.encodeWithSignature("Error(string)","SafeMath: addition overflow")));
  require(w.balanceOf(address(this))==7&&w.balanceOf(address(9))==type(uint256).max,"debit rollback");
 }
 function testZeroAddressGuardPriorityAndZeroAmountAllowed() public {
  (,ActualWstETH w,)=setup();
  (bool ok,bytes memory data)=address(w).call(abi.encodeWithSelector(TransferToken.transferFrom.selector,address(0),address(0),7));
  require(!ok&&keccak256(data)==keccak256(abi.encodeWithSignature("Error(string)","ERC20: transfer from the zero address")));
  (ok,data)=address(w).call(abi.encodeWithSelector(TransferToken.transferFrom.selector,address(this),address(0),7));
  require(!ok&&keccak256(data)==keccak256(abi.encodeWithSignature("Error(string)","ERC20: transfer to the zero address")));
  traceVm.recordLogs();require(TransferToken(address(w)).transferFrom(address(this),address(9),0));
  require(w.balanceOf(address(this))==7&&w.balanceOf(address(9))==0&&traceVm.getRecordedLogs().length==2);
 }
}
