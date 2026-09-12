pragma solidity 0.8.9;
import "../src/BatchHarness.sol";
interface Vm {function getCode(string calldata) external returns(bytes memory);function store(address,bytes32,bytes32) external;function load(address,bytes32) external view returns(bytes32);function addr(uint256) external returns(address);function sign(uint256,bytes32) external returns(uint8,bytes32,bytes32);function prank(address) external;function etch(address,bytes calldata) external;}
interface L {function getPooledEthByShares(uint256) external view returns(uint256);function configure(address) external;}
interface W {function DOMAIN_SEPARATOR() external view returns(bytes32);function nonces(address) external view returns(uint256);function balanceOf(address) external view returns(uint256);function totalSupply() external view returns(uint256);function allowance(address,address) external view returns(uint256);}
contract ConversionTest {
 Vm constant vm=Vm(address(uint160(uint256(keccak256("hevm cheat code")))));
 bytes32 constant S=0x6038150aecaa250d524370a0fdcdec13f2690e0723eaf277f41d7cae26b359e6;
 bytes32 constant B=0x81a11fa1111afa59b50051f60ccf604a39d96acb484dc467ad8eadb4a63f0a5f;
 bytes32 constant C=0x096e465397f38e659238ccd5d5a2c434ced54a63fd8d694045bfb058ab9d8112;
 BatchHarness q;W w;L qToken;L firstToken;L secondToken;uint256 public moves;bool badSecond;bool allowZero;
 function deploy(string memory name,bytes memory args) internal returns(address t){bytes memory code=abi.encodePacked(vm.getCode(name),args);assembly{t:=create(0,add(code,32),mload(code))}require(t!=address(0));}
 function seed(address t,uint256 s,uint256 b,uint256 c) internal {vm.store(t,S,bytes32(s));vm.store(t,B,bytes32(b));vm.store(t,C,bytes32(c));}
 function raw(L t,uint256 a) internal returns(bool,bytes memory){return address(t).call(abi.encodeWithSelector(t.getPooledEthByShares.selector,a));}
 function testFullLidoPackedReverse() public {L t=L(deploy("artifacts/Lido.json",hex""));seed(address(t),100|(uint256(20)<<128),100|(uint256(200)<<128),300|(uint256(400)<<128));require(t.getPooledEthByShares(8)==100);}
 function testStrictMaxBeforeZeroDivisor() public {L t=L(deploy("artifacts/Lido.json",hex""));(bool ok,bytes memory ret)=raw(t,type(uint128).max);require(!ok&&keccak256(ret)==keccak256(abi.encodeWithSignature("Error(string)","SHARES_TOO_LARGE")));seed(address(t),1,1,0);require(t.getPooledEthByShares(uint256(type(uint128).max)-1)==uint256(type(uint128).max)-1);}
 function testZeroSharesDivisorInvalidEmpty() public {L t=L(deploy("artifacts/Lido.json",hex""));seed(address(t),0,1,0);(bool ok,bytes memory ret)=raw(t,0);require(!ok&&ret.length==0);}
 function testZeroEtherSuccessfulZero() public {L t=L(deploy("artifacts/Lido.json",hex""));seed(address(t),1,0,0);require(t.getPooledEthByShares(7)==0);}
 function testRawUnderflowDivisor() public {L t=L(deploy("artifacts/Lido.json",hex""));seed(address(t),uint256(1)<<128,1,0);require(t.getPooledEthByShares(2)==0);}
 function testRawMultiplyOverflowAndOversizedReturn() public {L t=L(deploy("artifacts/Lido.json",hex""));seed(address(t),1,type(uint256).max,type(uint256).max);uint256 a=uint256(type(uint128).max)-1;uint256 expected;unchecked{expected=a*(4*uint256(type(uint128).max));}require(expected>type(uint128).max&&t.getPooledEthByShares(a)==expected);}
 function testFuzzFullPinnedLidoReverse(uint128 t,uint128 e,uint128 b,uint128 d,uint128 v,uint128 p,uint128 amount) public {L token=L(deploy("artifacts/Lido.json",hex""));seed(address(token),uint256(t)|(uint256(e)<<128),uint256(b)|(uint256(d)<<128),uint256(v)|(uint256(p)<<128));uint256 a=uint256(amount)%uint256(type(uint128).max);uint256 i=uint256(b)+d+v+p;uint256 s;unchecked{s=uint256(t)-e;}if(s==0){(bool ok,bytes memory ret)=raw(token,a);require(!ok&&ret.length==0);}else{uint256 expected;unchecked{expected=(a*i)/s;}require(token.getPooledEthByShares(a)==expected);}}
 function setup(bool bad) internal returns(address user){
  qToken=L(deploy("artifacts/ConversionHarness.json",hex""));firstToken=L(deploy("artifacts/ConversionHarness.json",hex""));secondToken=L(deploy("artifacts/ConversionHarness.json",hex""));
  qToken.configure(address(this));firstToken.configure(address(this));secondToken.configure(address(this));
  w=W(deploy("artifacts/WstETH.json",abi.encode(address(qToken))));q=new BatchHarness(IWstETH(address(w)));q.seed(0,0,0,9);q.setResume(0);
  seed(address(qToken),15,1500,0);seed(address(firstToken),20,2000,0);seed(address(secondToken),20,4000,0);
  vm.store(address(w),bytes32(uint256(7)),bytes32(uint256(uint160(address(firstToken)))|(uint256(1)<<200)));
  user=vm.addr(1);vm.store(address(w),keccak256(abi.encode(user,uint256(0))),bytes32(uint256(15)));vm.store(address(w),bytes32(uint256(2)),bytes32(uint256(15)));badSecond=bad;
 }
 // Explicit arbitrary mutable-callee boundary hook. No claim that real Lido
 // transfer itself performs these writes. Conversion bodies are inherited Lido.
 function moved(address sender,address to,uint256 amount) external {
  require(sender==address(w)&&to==address(q));require(msg.sender==(moves==0?address(firstToken):address(secondToken)));
  require(amount==(allowZero?0:(moves==0?700:1600)));moves++;
  vm.store(address(w),bytes32(uint256(7)),bytes32(uint256(uint160(address(secondToken)))|(uint256(1)<<200)));
  vm.store(address(qToken),B,bytes32(moves==1?uint256(3000):uint256(6000)));
  if(badSecond)vm.store(address(secondToken),S,bytes32(0));
 }
 function xs() internal pure returns(uint256[] memory z){z=new uint256[](2);z[0]=7;z[1]=8;}
 function signed(address user) internal returns(WithdrawalQueue.PermitInput memory p){p.value=15;p.deadline=type(uint256).max;bytes32 h=keccak256(abi.encode(keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),user,address(q),p.value,w.nonces(user),p.deadline));(p.v,p.r,p.s)=vm.sign(1,keccak256(abi.encodePacked(hex"1901",w.DOMAIN_SEPARATOR(),h)));}
 function testDynamicTargetsRatesRealPermitAndCapturedAmounts() public {address user=setup(false);WithdrawalQueue.PermitInput memory p=signed(user);vm.prank(user);uint256[] memory ids=q.requestWithdrawalsWstETHWithPermit(xs(),address(0),p);require(ids[0]==1&&ids[1]==2&&moves==2&&q.metadata(1).cumulativeStETH==700&&q.metadata(2).cumulativeStETH==2300&&q.metadata(1).cumulativeShares==3&&q.metadata(2).cumulativeShares==7&&w.nonces(user)==1&&w.allowance(user,address(q))==0&&w.totalSupply()==0);}
 function testLaterReverseInvalidRestoresEarlierItemRealPermitAndTarget() public {address user=setup(true);WithdrawalQueue.PermitInput memory p=signed(user);vm.prank(user);(bool ok,bytes memory ret)=address(q).call(abi.encodeWithSelector(q.requestWithdrawalsWstETHWithPermit.selector,xs(),address(0),p));require(!ok&&ret.length==0&&moves==0&&q.getLastRequestId()==0&&w.nonces(user)==0&&w.allowance(user,address(q))==0&&w.balanceOf(user)==15&&w.totalSupply()==15&&uint160(uint256(vm.load(address(w),bytes32(uint256(7)))))==uint160(address(firstToken))&&vm.load(address(qToken),B)==bytes32(uint256(1500))&&vm.load(address(secondToken),S)==bytes32(uint256(20)));}
 function testZeroConversionCapturedBeforeCallbackQueueGuard() public {address user=setup(false);seed(address(firstToken),20,0,0);allowZero=true;WithdrawalQueue.PermitInput memory p=signed(user);uint256[] memory z=new uint256[](1);z[0]=7;vm.prank(user);(bool ok,bytes memory ret)=address(q).call(abi.encodeWithSelector(q.requestWithdrawalsWstETHWithPermit.selector,z,address(0),p));require(!ok&&keccak256(ret)==keccak256(abi.encodeWithSignature("RequestAmountTooSmall(uint256)",0))&&moves==0&&w.nonces(user)==0&&w.totalSupply()==15);}
 function testDynamicTargetNoCodeRollsBackRealPermit() public {address user=setup(false);vm.etch(address(firstToken),hex"");WithdrawalQueue.PermitInput memory p=signed(user);vm.prank(user);(bool ok,bytes memory ret)=address(q).call(abi.encodeWithSelector(q.requestWithdrawalsWstETHWithPermit.selector,xs(),address(0),p));require(!ok&&ret.length==0&&w.nonces(user)==0&&moves==0&&w.totalSupply()==15);}
}
