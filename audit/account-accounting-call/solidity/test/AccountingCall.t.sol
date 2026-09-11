pragma solidity 0.8.9;
import "../src/DistributionHarness.sol";
import "contracts/0.8.9/LidoLocator.sol";
import "contracts/0.8.9/proxy/OssifiableProxy.sol";
interface Vm {
 function getCode(string calldata) external returns(bytes memory);
 function store(address,bytes32,bytes32) external;
 function load(address,bytes32) external view returns(bytes32);
}
contract RawLocator {
 bytes public raw; bool public fail; uint256 public calls; address public token;
 constructor(bytes memory r,bool f,address t){raw=r;fail=f;token=t;}
 fallback() external payable {
  require(msg.sender==token&&msg.value==0&&msg.data.length==4&&msg.sig==bytes4(0x9624e83e),"CALL_SHAPE");
  ++calls; bytes memory r=raw;
  if(fail){assembly{revert(add(r,32),mload(r))}}
  assembly{return(add(r,32),mload(r))}
 }
}
contract AccountingCallTest {
 Vm constant vm=Vm(address(uint160(uint256(keccak256("hevm cheat code")))));
 bytes32 constant PAUSE=0x644132c4ddd5bb6f0655d5fe2870dcec7870e6be4758890f366b83441f9fdece;
 bytes32 constant TOTAL=0x6038150aecaa250d524370a0fdcdec13f2690e0723eaf277f41d7cae26b359e6;
 bytes32 constant BUFFER=0x81a11fa1111afa59b50051f60ccf604a39d96acb484dc467ad8eadb4a63f0a5f;
 bytes32 constant LOCATOR=0xd92bc31601d11a10411d08f59b7146d8a5915af253cde25f8e66b67beb4be223;
 ILidoShares t; DistributionHarness d; OssifiableProxy proxy;
 function config(address accounting,address treasury) internal pure returns(LidoLocator.Config memory c){
  c.accountingOracle=address(1);c.depositSecurityModule=address(1);c.elRewardsVault=address(1);c.lido=address(1);
  c.oracleReportSanityChecker=address(1);c.postTokenRebaseReceiver=address(1);c.burner=address(1);c.stakingRouter=address(1);
  c.treasury=treasury;c.validatorsExitBusOracle=address(1);c.withdrawalQueue=address(1);c.withdrawalVault=address(1);
  c.oracleDaemonConfig=address(1);c.validatorExitDelayVerifier=address(1);c.triggerableWithdrawalsGateway=address(1);
  c.consolidationGateway=address(1);c.accounting=accounting;c.predepositGuarantee=address(1);c.wstETH=address(1);
  c.vaultHub=address(1);c.vaultFactory=address(1);c.lazyOracle=address(1);c.operatorGrid=address(1);c.topUpGateway=address(1);
 }
 function upgrade(address accounting,address treasury) internal {proxy.proxy__upgradeTo(address(new LidoLocator(config(accounting,treasury))));}
 function setUp() public {
  bytes memory code=vm.getCode("artifacts/Lido.json");address a;assembly{a:=create(0,add(code,32),mload(code))}require(a!=address(0));t=ILidoShares(a);
  proxy=new OssifiableProxy(address(new LidoLocator(config(address(this),address(500)))),address(this),"");
  d=new DistributionHarness(t,ILocatorTreasury(address(proxy)));upgrade(address(d),address(500));
  vm.store(a,LOCATOR,bytes32((uint256(123)<<160)|uint256(uint160(address(proxy)))));
  vm.store(a,TOTAL,bytes32((uint256(4)<<128)+10));vm.store(a,BUFFER,bytes32(uint256(100)));vm.store(a,PAUSE,bytes32(uint256(2)));
  vm.store(a,keccak256(abi.encode(address(d),uint256(0))),bytes32(uint256(5)));
 }
 function attempt(uint256 mint) internal returns(bool,bytes memory){address[] memory rs=new address[](2);rs[0]=address(170);rs[1]=address(190);uint256[] memory ps=new uint256[](2);ps[0]=2;ps[1]=2;return address(d).call(abi.encodeWithSelector(d.mintAndDistribute.selector,mint,rs,ps,uint256(6)));}
 function errorIs(bytes memory got,string memory reason) internal pure {require(keccak256(got)==keccak256(abi.encodeWithSignature("Error(string)",reason)),"ERROR_BYTES");}
 function rollback() internal view {require(vm.load(address(t),TOTAL)==bytes32((uint256(4)<<128)+10)&&t.sharesOf(address(d))==5&&t.sharesOf(address(170))==0&&t.sharesOf(address(500))==0,"ROLLBACK");}
 function rawTarget(bytes memory raw,bool fail) internal returns(RawLocator r){r=new RawLocator(raw,fail,address(t));vm.store(address(t),LOCATOR,bytes32(uint256(uint160(address(r)))));}
 function testPinnedLocatorKeccak() public pure {require(LOCATOR==keccak256("lido.Lido.lidoLocatorAndMaxExternalRatio"));}
 function testRealImmutableGetterViaRealProxy() public {require(LidoLocator(address(proxy)).accounting()==address(d));(bool ok,)=attempt(10);require(ok&&t.sharesOf(address(170))==2&&t.sharesOf(address(500))==6&&t.sharesOf(address(d))==5);require(vm.load(address(t),LOCATOR)==bytes32((uint256(123)<<160)|uint256(uint160(address(proxy)))));}
 function testFuzzPhysicalTargetHigh96(uint96 high) public {vm.store(address(t),LOCATOR,bytes32((uint256(high)<<160)|uint256(uint160(address(proxy)))));(bool ok,)=attempt(10);require(ok);}
 function testActualImplementationChangeConsumedByAuth() public {upgrade(address(777),address(500));vm.store(address(t),PAUSE,bytes32(0));(bool ok,bytes memory ret)=attempt(10);require(!ok);errorIs(ret,"APP_AUTH_FAILED");rollback();}
 function testAccountingAuthThenPhysicalPause() public {vm.store(address(t),PAUSE,bytes32(0));(bool ok,bytes memory ret)=attempt(10);require(!ok);errorIs(ret,"CONTRACT_IS_STOPPED");rollback();}
 function testNoCodeRejectsBeforePause() public {vm.store(address(t),LOCATOR,bytes32(uint256(999999)));vm.store(address(t),PAUSE,bytes32(0));(bool ok,bytes memory ret)=attempt(10);require(!ok&&ret.length==0);rollback();}
 function testZeroFeeSkipsAbsentAccountingAndPause() public {vm.store(address(t),LOCATOR,bytes32(uint256(999999)));vm.store(address(t),PAUSE,bytes32(0));(bool ok,)=attempt(0);require(ok);rollback();}
 function testLegacyDirtyAddressHighBitsAccepted() public {RawLocator r=rawTarget(abi.encode((uint256(1)<<255)|uint256(uint160(address(d)))),false);(bool ok,)=attempt(10);require(ok&&r.calls()==1);}
 function testLegacyTrailingByteAccepted() public {RawLocator r=rawTarget(abi.encodePacked(abi.encode(address(d)),hex"ab"),false);(bool ok,)=attempt(10);require(ok&&r.calls()==1);}
 function testLegacyShortReturnRejected() public {RawLocator r=rawTarget(new bytes(31),false);(bool ok,bytes memory ret)=attempt(10);require(!ok&&ret.length==0&&r.calls()==0);rollback();}
 function testLegacyEmptyReturnRejected() public {rawTarget(new bytes(0),false);(bool ok,bytes memory ret)=attempt(10);require(!ok&&ret.length==0);rollback();}
 function testLegacyRevertBytesBubbled() public {rawTarget(hex"deadbeef01",true);(bool ok,bytes memory ret)=attempt(10);require(!ok&&keccak256(ret)==keccak256(hex"deadbeef01"));rollback();}
 function testCallAllowsMutableCalleeOutsideSpecializedProof() public {RawLocator r=rawTarget(abi.encode(address(d)),false);(bool ok,)=attempt(10);require(ok&&r.calls()==1);}
 function testRealProxyLateTreasuryGuardRollsBack() public {upgrade(address(d),address(t));(bool ok,bytes memory ret)=attempt(10);require(!ok);errorIs(ret,"TRANSFER_TO_STETH_CONTRACT");rollback();}
 function testFuzzLegacyDirtyHigh96(uint96 high) public {RawLocator r=rawTarget(abi.encode((uint256(high)<<160)|uint256(uint160(address(d)))),false);(bool ok,)=attempt(10);require(ok&&r.calls()==1);}
}
