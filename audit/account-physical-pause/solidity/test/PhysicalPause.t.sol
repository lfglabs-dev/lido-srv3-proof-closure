pragma solidity 0.8.9;
import "../src/DistributionHarness.sol";
interface Lido is ILidoShares {function isStopped() external view returns(bool);}
interface Vm {function getCode(string calldata) external returns(bytes memory);function store(address,bytes32,bytes32) external;function load(address,bytes32) external view returns(bytes32);function prank(address) external;}
contract Locator {
 address public accounting;Lido public token;uint256 public mode;
 function setup(address a,Lido t,uint256 m) external {accounting=a;token=t;mode=m;}
 fallback() external {
  require(msg.sig==bytes4(0x61d027b3)&&msg.data.length==4&&msg.sender==accounting,"ACTUAL_REQUEST");
  require(token.sharesOf(accounting)==11&&token.sharesOf(address(170))==2&&token.sharesOf(address(190))==2&&!token.isStopped(),"PHYSICAL_POST_MODULE");
  uint256 m=mode;if(m==1){assembly{mstore(0,0) return(0,32)}}
  if(m==2){assembly{sstore(99,1)}}
  assembly{mstore(0,500) return(0,32)}
 }
}
contract PhysicalPauseTest {
 Vm constant vm=Vm(address(uint160(uint256(keccak256("hevm cheat code")))));
 bytes32 constant PAUSE=0x644132c4ddd5bb6f0655d5fe2870dcec7870e6be4758890f366b83441f9fdece;
 bytes32 constant TOTAL=0x6038150aecaa250d524370a0fdcdec13f2690e0723eaf277f41d7cae26b359e6;
 bytes32 constant BUFFER=0x81a11fa1111afa59b50051f60ccf604a39d96acb484dc467ad8eadb4a63f0a5f;
 bytes32 constant LOCATOR=0xd92bc31601d11a10411d08f59b7146d8a5915af253cde25f8e66b67beb4be223;
 Lido t;Locator loc;DistributionHarness d;
 function setUp() public {bytes memory code=vm.getCode("artifacts/Lido.json");address a;assembly{a:=create(0,add(code,32),mload(code))}require(a!=address(0));t=Lido(a);loc=new Locator();d=new DistributionHarness(t,ILocatorTreasury(address(loc)));loc.setup(address(d),t,0);vm.store(a,LOCATOR,bytes32(uint256(uint160(address(loc)))));vm.store(a,TOTAL,bytes32((uint256(4)<<128)+10));vm.store(a,BUFFER,bytes32(uint256(100)));vm.store(a,PAUSE,bytes32(uint256(2)));vm.store(a,keccak256(abi.encode(address(d),uint256(0))),bytes32(uint256(5)));require(t.sharesOf(address(d))==5,"ACTUAL_SHARE_SETUP");}
 function arrays() internal pure returns(address[] memory rs,uint256[] memory ps){rs=new address[](3);ps=new uint256[](3);rs[0]=address(170);rs[1]=address(180);rs[2]=address(190);ps[0]=2;ps[2]=2;}
 function attempt(uint256 mint) internal returns(bool,bytes memory){(address[] memory rs,uint256[] memory ps)=arrays();return address(d).call(abi.encodeWithSelector(d.mintAndDistribute.selector,mint,rs,ps,uint256(6)));}
 function errorIs(bytes memory got,string memory reason) internal pure {require(keccak256(got)==keccak256(abi.encodeWithSignature("Error(string)",reason)),"ERROR_BYTES");}
 function rollback(uint256 raw) internal view {require(vm.load(address(t),PAUSE)==bytes32(raw)&&vm.load(address(t),TOTAL)==bytes32((uint256(4)<<128)+10)&&t.sharesOf(address(d))==5&&t.sharesOf(address(170))==0&&t.sharesOf(address(500))==0,"ROOT_ROLLBACK");}
 function testPinnedPauseKeccakAndDistinctTotal() public pure {require(PAUSE==keccak256("lido.Pausable.activeFlag")&&PAUSE!=TOTAL);}
 function testFullWordNonzeroNotLowByte() public {vm.store(address(t),PAUSE,bytes32(0));require(t.isStopped());vm.store(address(t),PAUSE,bytes32(uint256(2)));require(!t.isStopped());vm.store(address(t),PAUSE,bytes32(uint256(1)<<255));require(!t.isStopped());}
 function testFuzzActualFullLidoBool(uint256 raw) public {vm.store(address(t),PAUSE,bytes32(raw));require(t.isStopped()==(raw==0));}
 function testNoncanonicalWordMintPaymentsReadonlyTreasury() public {(bool ok,)=attempt(10);require(ok&&t.sharesOf(address(d))==5&&t.sharesOf(address(500))==6&&t.sharesOf(address(170))==2&&vm.load(address(t),PAUSE)==bytes32(uint256(2))&&vm.load(address(t),TOTAL)==bytes32((uint256(4)<<128)+20));}
 function testHighBitMintPaymentsPreserveWord() public {vm.store(address(t),PAUSE,bytes32(uint256(1)<<255));(bool ok,)=attempt(10);require(ok&&vm.load(address(t),PAUSE)==bytes32(uint256(1)<<255));}
 function testPausedMintFailsAndRestores() public {vm.store(address(t),PAUSE,bytes32(0));(bool ok,bytes memory ret)=attempt(10);require(!ok);errorIs(ret,"CONTRACT_IS_STOPPED");rollback(0);}
 function testAuthBeforePause() public {vm.store(address(t),PAUSE,bytes32(0));(bool ok,bytes memory ret)=address(t).call(abi.encodeWithSelector(t.mintShares.selector,address(0),uint256(1)));require(!ok);errorIs(ret,"APP_AUTH_FAILED");}
 function testMintPauseBeforeRecipientGuard() public {vm.store(address(t),PAUSE,bytes32(0));vm.prank(address(d));(bool ok,bytes memory ret)=address(t).call(abi.encodeWithSelector(t.mintShares.selector,address(0),uint256(1)));require(!ok);errorIs(ret,"CONTRACT_IS_STOPPED");}
 function testTransferRecipientGuardBeforePause() public {vm.store(address(t),PAUSE,bytes32(0));(bool ok,bytes memory ret)=address(t).call(abi.encodeWithSelector(t.transferShares.selector,address(0),uint256(1)));require(!ok);errorIs(ret,"TRANSFER_TO_ZERO_ADDR");}
 function testTransferPauseBeforeBalanceGuard() public {vm.store(address(t),PAUSE,bytes32(0));(bool ok,bytes memory ret)=address(t).call(abi.encodeWithSelector(t.transferShares.selector,address(170),uint256(1)));require(!ok);errorIs(ret,"CONTRACT_IS_STOPPED");}
 function testLateTreasuryRecipientFailureWholeRollback() public {loc.setup(address(d),t,1);(bool ok,bytes memory ret)=attempt(10);require(!ok);errorIs(ret,"TRANSFER_TO_ZERO_ADDR");rollback(2);}
 function testForbiddenStaticWriteWholeRollback() public {loc.setup(address(d),t,2);(bool ok,)=attempt(10);require(!ok);rollback(2);}
 function testZeroMintSkipsPhysicalPauseAndStaticCall() public {vm.store(address(t),PAUSE,bytes32(0));loc.setup(address(d),t,2);(bool ok,)=attempt(0);require(ok);rollback(0);}
}
