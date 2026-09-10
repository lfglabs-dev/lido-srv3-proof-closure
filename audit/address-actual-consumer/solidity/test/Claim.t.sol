pragma solidity 0.8.9;
import "../src/ClaimHarness.sol";
interface Vm { function deal(address,uint256) external; }
contract ObservingReceiver {
    ClaimHarness q; uint256 public calls; bool rejectSecond;
    constructor(ClaimHarness queue,bool reject) { q=queue; rejectSecond=reject; }
    receive() external payable {
        require(q.claimed(1));
        calls++;
        if(calls==1) { require(msg.value==30); require(q.getLockedEtherAmount()==40); }
        else { require(msg.value==40); require(q.getLockedEtherAmount()==0); if(rejectSecond) revert("later"); }
    }
}
contract ClaimTest {
    Vm constant vm=Vm(address(uint160(uint256(keccak256("hevm cheat code")))));
    function setup() internal returns(ClaimHarness q) { q=new ClaimHarness();q.seed(address(this));vm.deal(address(q),70); }
    function ids(bool duplicate) internal pure returns(uint256[] memory a,uint256[] memory h) { a=new uint256[](2);h=new uint256[](2);a[0]=1;a[1]=duplicate?1:2;h[0]=1;h[1]=1; }
    function testTwoActualBaseClaims() public { ClaimHarness q=setup();ObservingReceiver r=new ObservingReceiver(q,false);(uint256[] memory a,uint256[] memory h)=ids(false);q.claimWithdrawalsTo(a,h,address(r));require(r.calls()==2&&address(r).balance==70&&address(q).balance==0&&q.claimed(1)&&q.claimed(2)); }
    function testLaterCallbackRollback() public { ClaimHarness q=setup();ObservingReceiver r=new ObservingReceiver(q,true);(uint256[] memory a,uint256[] memory h)=ids(false);(bool ok,)=address(q).call(abi.encodeWithSelector(q.claimWithdrawalsTo.selector,a,h,address(r)));require(!ok&&r.calls()==0&&address(r).balance==0&&address(q).balance==70&&!q.claimed(1)&&!q.claimed(2)&&q.getLockedEtherAmount()==70); }
    function testDuplicateRollback() public { ClaimHarness q=setup();ObservingReceiver r=new ObservingReceiver(q,false);(uint256[] memory a,uint256[] memory h)=ids(true);(bool ok,)=address(q).call(abi.encodeWithSelector(q.claimWithdrawalsTo.selector,a,h,address(r)));require(!ok&&r.calls()==0&&!q.claimed(1)&&address(q).balance==70); }
    function testFundingRollback() public { ClaimHarness q=setup();vm.deal(address(q),0);(uint256[] memory a,uint256[] memory h)=ids(false);(bool ok,)=address(q).call(abi.encodeWithSelector(q.claimWithdrawalsTo.selector,a,h,address(1002)));require(!ok&&!q.claimed(1)&&q.getLockedEtherAmount()==70); }
    function testCodeLessRecipient() public { ClaimHarness q=setup();(uint256[] memory a,uint256[] memory h)=ids(false);q.claimWithdrawalsTo(a,h,address(1002));require(address(1002).balance==70&&q.claimed(1)&&q.claimed(2)); }
}
