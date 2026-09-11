pragma solidity 0.8.9;
import "../src/BatchHarness.sol";
interface Vm {
 struct Log {bytes32[] topics;bytes data;address emitter;}
 function getCode(string calldata) external returns(bytes memory);function store(address,bytes32,bytes32) external;function load(address,bytes32) external view returns(bytes32);function addr(uint256) external returns(address);function sign(uint256,bytes32) external returns(uint8,bytes32,bytes32);function prank(address) external;function etch(address,bytes calldata) external;function recordLogs() external;function getRecordedLogs() external returns(Log[] memory);
}
interface L {function transfer(address,uint256) external returns(bool);function sharesOf(address) external view returns(uint256);function getSharesByPooledEth(uint256) external view returns(uint256);}
interface W {function DOMAIN_SEPARATOR() external view returns(bytes32);function nonces(address) external view returns(uint256);function balanceOf(address) external view returns(uint256);function totalSupply() external view returns(uint256);function allowance(address,address) external view returns(uint256);}
contract TransferTest {
 Vm constant vm=Vm(address(uint160(uint256(keccak256("hevm cheat code")))));
 bytes32 constant S=0x6038150aecaa250d524370a0fdcdec13f2690e0723eaf277f41d7cae26b359e6;
 bytes32 constant B=0x81a11fa1111afa59b50051f60ccf604a39d96acb484dc467ad8eadb4a63f0a5f;
 bytes32 constant C=0x096e465397f38e659238ccd5d5a2c434ced54a63fd8d694045bfb058ab9d8112;
 bytes32 constant ACTIVE=0x644132c4ddd5bb6f0655d5fe2870dcec7870e6be4758890f366b83441f9fdece;
 BatchHarness q;W w;L qToken;L token;
 function deploy(string memory name,bytes memory args) internal returns(address t){bytes memory code=abi.encodePacked(vm.getCode(name),args);assembly{t:=create(0,add(code,32),mload(code))}require(t!=address(0));}
 function seed(L t,uint256 s,uint256 b,uint256 c) internal {vm.store(address(t),S,bytes32(s));vm.store(address(t),B,bytes32(b));vm.store(address(t),C,bytes32(c));}
 function slot(address a) internal pure returns(bytes32){return keccak256(abi.encode(a,uint256(0)));}
 function balance(L t,address a,uint256 n) internal {vm.store(address(t),slot(a),bytes32(n));}
 function fresh() internal returns(L t){t=L(deploy("artifacts/Lido.json",hex""));seed(t,20,2000,0);vm.store(address(t),ACTIVE,bytes32(uint256(1)));balance(t,address(this),20);balance(t,address(99),5);}
 function raw(L t,address from,address to,uint256 amount) internal returns(bool,bytes memory){vm.prank(from);return address(t).call(abi.encodeWithSelector(t.transfer.selector,to,amount));}
 function error(L t,address from,address to,uint256 amount,string memory reason) internal { (bool ok,bytes memory data)=raw(t,from,to,amount);require(!ok&&keccak256(data)==keccak256(abi.encodeWithSignature("Error(string)",reason)));}
 function checkLogs(Vm.Log[] memory logs,address emitter,address from,address to,uint256 amount,uint256 shares) internal pure {
  require(logs.length==2&&logs[0].emitter==emitter&&logs[1].emitter==emitter);
  require(logs[0].topics.length==3&&logs[1].topics.length==3&&logs[0].topics[0]==keccak256("Transfer(address,address,uint256)")&&logs[1].topics[0]==keccak256("TransferShares(address,address,uint256)"));
  require(logs[0].topics[1]==bytes32(uint256(uint160(from)))&&logs[0].topics[2]==bytes32(uint256(uint160(to)))&&logs[1].topics[1]==logs[0].topics[1]&&logs[1].topics[2]==logs[0].topics[2]);
  require(keccak256(logs[0].data)==keccak256(abi.encode(amount))&&keccak256(logs[1].data)==keccak256(abi.encode(shares)));
 }
 function testActualFullLidoTransferReturnAndEvents() public {L t=fresh();vm.recordLogs();(bool ok,bytes memory ret)=raw(t,address(this),address(99),700);require(ok&&ret.length==32&&abi.decode(ret,(uint256))==1&&t.sharesOf(address(this))==13&&t.sharesOf(address(99))==12);checkLogs(vm.getRecordedLogs(),address(t),address(this),address(99),700,7);}
 function testWholePauseWordNonzero() public {L t=fresh();vm.store(address(t),ACTIVE,bytes32(uint256(2)));require(t.transfer(address(99),100));vm.store(address(t),ACTIVE,bytes32(uint256(1)<<255));require(t.transfer(address(99),100));require(t.sharesOf(address(this))==18&&t.sharesOf(address(99))==7);}
 function testConversionAndGuardPriority() public {L t=fresh();vm.store(address(t),ACTIVE,bytes32(0));error(t,address(0),address(0),type(uint128).max,"ETH_TOO_LARGE");seed(t,20,0,0);(bool ok,bytes memory ret)=raw(t,address(0),address(0),1);require(!ok&&ret.length==0);seed(t,20,2000,0);error(t,address(0),address(0),1,"TRANSFER_FROM_ZERO_ADDR");error(t,address(this),address(0),1,"TRANSFER_TO_ZERO_ADDR");error(t,address(this),address(t),1,"TRANSFER_TO_STETH_CONTRACT");error(t,address(this),address(99),1,"CONTRACT_IS_STOPPED");}
 function testInsufficientAndRecipientOverflowRollback() public {L t=fresh();error(t,address(this),address(99),2100,"BALANCE_EXCEEDED");balance(t,address(99),type(uint256).max);error(t,address(this),address(99),700,"MATH_ADD_OVERFLOW");require(t.sharesOf(address(this))==20&&t.sharesOf(address(99))==type(uint256).max);}
 function testAliasFreshReadAndZeroEvents() public {L t=fresh();vm.recordLogs();require(t.transfer(address(this),700)&&t.sharesOf(address(this))==20);checkLogs(vm.getRecordedLogs(),address(t),address(this),address(this),700,7);vm.recordLogs();require(t.transfer(address(99),0)&&t.sharesOf(address(this))==20&&t.sharesOf(address(99))==5);checkLogs(vm.getRecordedLogs(),address(t),address(this),address(99),0,0);}
 function testZeroSharesNonzeroEtherStillTransfersZero() public {L t=fresh();seed(t,0,2000,0);vm.recordLogs();require(t.transfer(address(99),700)&&t.sharesOf(address(this))==20&&t.sharesOf(address(99))==5);checkLogs(vm.getRecordedLogs(),address(t),address(this),address(99),700,0);}
 function testFuzzFullLidoPhysicalTransfer(uint64 n,uint64 senderExtra,uint64 recipientBalance,bool same) public {L t=fresh();uint256 shares=uint256(n);address to=same?address(this):address(99);balance(t,address(this),shares+uint256(senderExtra));balance(t,address(99),uint256(recipientBalance));require(t.transfer(to,shares*100));require(t.sharesOf(address(this))==(same?shares+uint256(senderExtra):uint256(senderExtra)));if(!same)require(t.sharesOf(to)==uint256(recipientBalance)+shares);}
 function setup(uint256 funding) internal returns(address user){
  qToken=L(deploy("artifacts/Lido.json",hex""));token=L(deploy("artifacts/Lido.json",hex""));
  w=W(deploy("artifacts/WstETH.json",abi.encode(address(qToken))));q=new BatchHarness(IWstETH(address(w)));q.seed(0,0,0,9);q.setResume(0);
  seed(qToken,15,1500,0);seed(token,20,2000,0);vm.store(address(token),ACTIVE,bytes32(uint256(256)));
  balance(token,address(w),funding);balance(token,address(q),5);
  vm.store(address(w),bytes32(uint256(7)),bytes32(uint256(uint160(address(token)))|(uint256(1)<<200)));
  user=vm.addr(1);vm.store(address(w),slot(user),bytes32(uint256(15)));vm.store(address(w),bytes32(uint256(2)),bytes32(uint256(15)));
 }
 function xs() internal pure returns(uint256[] memory z){z=new uint256[](2);z[0]=7;z[1]=8;}
 function signed(address user) internal returns(WithdrawalQueue.PermitInput memory p){p.value=15;p.deadline=type(uint256).max;bytes32 h=keccak256(abi.encode(keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),user,address(q),p.value,w.nonces(user),p.deadline));(p.v,p.r,p.s)=vm.sign(1,keccak256(abi.encodePacked(hex"1901",w.DOMAIN_SEPARATOR(),h)));}
 function testActualSignedWrappedBatchDistinctLidoTargets() public {address user=setup(20);WithdrawalQueue.PermitInput memory p=signed(user);vm.prank(user);uint256[] memory ids=q.requestWithdrawalsWstETHWithPermit(xs(),address(0),p);require(ids[0]==1&&ids[1]==2&&q.metadata(1).cumulativeStETH==700&&q.metadata(2).cumulativeStETH==1500&&q.metadata(1).cumulativeShares==7&&q.metadata(2).cumulativeShares==15);require(token.sharesOf(address(w))==5&&token.sharesOf(address(q))==20&&qToken.sharesOf(address(q))==0&&w.nonces(user)==1&&w.allowance(user,address(q))==0&&w.totalSupply()==0);}
 function testLateActualTransferFailureRestoresRealPermitBurnAndEarlierItem() public {address user=setup(10);WithdrawalQueue.PermitInput memory p=signed(user);vm.prank(user);(bool ok,bytes memory ret)=address(q).call(abi.encodeWithSelector(q.requestWithdrawalsWstETHWithPermit.selector,xs(),address(0),p));require(!ok&&keccak256(ret)==keccak256(abi.encodeWithSignature("Error(string)","BALANCE_EXCEEDED")));require(q.getLastRequestId()==0&&token.sharesOf(address(w))==10&&token.sharesOf(address(q))==5&&w.nonces(user)==0&&w.allowance(user,address(q))==0&&w.balanceOf(user)==15&&w.totalSupply()==15);}
 function testPhysicalPauseAfterReverseBeforeMovementRestoresPermit() public {address user=setup(20);vm.store(address(token),ACTIVE,bytes32(0));WithdrawalQueue.PermitInput memory p=signed(user);vm.prank(user);(bool ok,bytes memory ret)=address(q).call(abi.encodeWithSelector(q.requestWithdrawalsWstETHWithPermit.selector,xs(),address(0),p));require(!ok&&keccak256(ret)==keccak256(abi.encodeWithSignature("Error(string)","CONTRACT_IS_STOPPED"))&&w.nonces(user)==0&&w.totalSupply()==15&&token.sharesOf(address(w))==20);}
 function testSelectedActualTargetNoCode() public {address user=setup(20);vm.etch(address(token),hex"");WithdrawalQueue.PermitInput memory p=signed(user);vm.prank(user);(bool ok,bytes memory ret)=address(q).call(abi.encodeWithSelector(q.requestWithdrawalsWstETHWithPermit.selector,xs(),address(0),p));require(!ok&&ret.length==0&&w.nonces(user)==0&&w.totalSupply()==15);}
}
