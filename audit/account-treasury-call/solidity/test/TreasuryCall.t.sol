pragma solidity 0.8.9;
import "../src/DistributionHarness.sol";
interface IStethSetup is ILidoShares {
    function setShares(address,uint256) external;
    function setPacked(uint256) external;
    function getPacked() external view returns(uint256);
}
interface VmTreasury {function getCode(string calldata) external returns(bytes memory);}
contract RawTreasury {
    uint256 public mode; IStethSetup public token; address public accounting;
    function setup(IStethSetup t,address a,uint256 m) external {token=t;accounting=a;mode=m;}
    fallback() external {
        require(msg.sig==bytes4(0x61d027b3) && msg.data.length==4,"REQUEST");
        require(msg.sender==accounting,"CALLER");
        require(token.sharesOf(accounting)==11 && token.sharesOf(address(170))==2 && token.sharesOf(address(190))==2,"POST_MODULE_STATE");
        uint256 m=mode;
        if(m==1) {assembly {mstore(0,500) return(0,31)}}
        if(m==2) {assembly {mstore(0,add(exp(2,160),500)) return(0,32)}}
        if(m==3) {assembly {mstore(0,0xdead) revert(30,2)}}
        if(m==4) {assembly {sstore(99,1)}}
        if(m==5) {assembly {mstore(0,0) return(0,32)}}
        assembly {mstore(0,500) mstore(32,mul(0xab,exp(2,248))) return(0,33)}
    }
}
contract TreasuryCallTest {
    VmTreasury constant vm=VmTreasury(address(uint160(uint256(keccak256("hevm cheat code")))));
    IStethSetup t;RawTreasury loc;DistributionHarness d;
    function setUp() public {
        bytes memory code=vm.getCode("StethHarness.sol:StethHarness");address a;
        assembly {a:=create(0,add(code,32),mload(code))}
        require(a!=address(0));t=IStethSetup(a);loc=new RawTreasury();
        d=new DistributionHarness(t,ILocatorTreasury(address(loc)));
        t.setPacked((uint256(4)<<128)+10);t.setShares(address(d),5);loc.setup(t,address(d),0);
    }
    function arrays() internal pure returns(address[] memory rs,uint256[] memory ps) {
        rs=new address[](3);ps=new uint256[](3);rs[0]=address(170);rs[1]=address(180);rs[2]=address(190);ps[0]=2;ps[2]=2;
    }
    function attempt(uint256 mode) internal returns(bool ok,bytes memory data) {
        loc.setup(t,address(d),mode);(address[] memory rs,uint256[] memory ps)=arrays();
        return address(d).call(abi.encodeWithSelector(d.mintAndDistribute.selector,uint256(10),rs,ps,uint256(6)));
    }
    function rollback() internal view {
        require(t.sharesOf(address(d))==5 && t.sharesOf(address(170))==0 && t.sharesOf(address(190))==0 && t.sharesOf(address(500))==0,"ROLLBACK");
        require(t.getPacked()==(uint256(4)<<128)+10,"MINT_ROLLBACK");
    }
    function testActualRequestAfterModulesAndTrailingBytesPaid() public {
        (bool ok,)=attempt(0);require(ok,"CALL");require(t.sharesOf(address(500))==6 && t.sharesOf(address(d))==5,"DECODED_PAYMENT");
    }
    function testShortReplyRejected() public {(bool ok,bytes memory data)=attempt(1);require(!ok && data.length==0,"SHORT");rollback();}
    function testNoncanonicalAddressRejected() public {(bool ok,bytes memory data)=attempt(2);require(!ok && data.length==0,"ADDRESS");rollback();}
    function testRevertBytesBubbled() public {(bool ok,bytes memory data)=attempt(3);require(!ok && keccak256(data)==keccak256(hex"dead"),"BUBBLED");rollback();}
    function testStateWriteRejectedByActualStaticcall() public {(bool ok,)=attempt(4);require(!ok,"STATIC");rollback();}
    function testZeroDecodedThenTransferRejects() public {(bool ok,bytes memory data)=attempt(5);require(!ok && keccak256(data)==keccak256(abi.encodeWithSignature("Error(string)","TRANSFER_TO_ZERO_ADDR")),"ZERO");rollback();}
    function testNoCodeRejectedAndEarlierTransfersRollback() public {
        d=new DistributionHarness(t,ILocatorTreasury(address(999)));t.setShares(address(d),5);
        (address[] memory rs,uint256[] memory ps)=arrays();
        (bool ok,)=address(d).call(abi.encodeWithSelector(d.mintAndDistribute.selector,uint256(10),rs,ps,uint256(6)));
        require(!ok,"NO_CODE");rollback();
    }
    function testZeroTreasurySkipsRejectingLocator() public {
        loc.setup(t,address(d),4);(address[] memory rs,uint256[] memory ps)=arrays();
        d.mintAndDistribute(10,rs,ps,0);require(t.sharesOf(address(d))==11,"ZERO_SKIP");
    }
    function testZeroMintSkipsLocator() public {
        loc.setup(t,address(d),4);(address[] memory rs,uint256[] memory ps)=arrays();
        d.mintAndDistribute(0,rs,ps,6);rollback();
    }
}
