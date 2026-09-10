pragma solidity 0.8.9;
import "../src/DistributionHarness.sol";
interface ISteth is ILidoShares {
    function setShares(address,uint256) external;
    function setPacked(uint256) external;
    function getPacked() external view returns(uint256);
    function setRate(uint256) external;
    function setStopped() external;
}
interface Vm {
    struct Log {bytes32[] topics;bytes data;address emitter;}
    function getCode(string calldata) external returns(bytes memory);
    function recordLogs() external;
    function getRecordedLogs() external returns(Log[] memory);
    function prank(address) external;
}
contract Locator {
    ISteth public token; address public accounting; address public recipient; bool public reject;
    bool public checkEffects;
    function setup(ISteth t,address a,address r,bool bad,bool check) external {
        token=t;accounting=a;recipient=r;reject=bad;checkEffects=check;
    }
    function treasury() external view returns(address) {
        require(!reject,"NO_TREASURY_READ");
        if(checkEffects) {
            require(msg.sender==accounting,"CALLER");
            require(token.sharesOf(accounting)==11 && token.sharesOf(address(170))==2 && token.sharesOf(address(190))==2,"POST_MODULE_STATE");
        }
        return recipient;
    }
}
contract DistributionTest {
    Vm constant vm=Vm(address(uint160(uint256(keccak256("hevm cheat code")))));
    ISteth t;Locator loc;DistributionHarness d;
    function setUp() public {
        bytes memory code=vm.getCode("StethHarness.sol:StethHarness");address deployed;
        assembly {deployed:=create(0,add(code,32),mload(code))}
        require(deployed!=address(0));t=ISteth(deployed);loc=new Locator();d=new DistributionHarness(t,ILocatorTreasury(address(loc)));
        t.setPacked((uint256(4)<<128)+10);t.setShares(address(d),5);
        require(t.sharesOf(address(d))==5,"SETUP");
        loc.setup(t,address(d),address(500),false,true);
    }
    function arrays() internal pure returns(address[] memory rs,uint256[] memory ps) {
        rs=new address[](3);ps=new uint256[](3);rs[0]=address(170);rs[1]=address(180);rs[2]=address(190);ps[0]=2;ps[2]=2;
    }
    function testActualOrderAmountsAndEvents() public {
        (address[] memory rs,uint256[] memory ps)=arrays();vm.recordLogs();d.mintAndDistribute(10,rs,ps,6);
        require(t.sharesOf(address(d))==5 && t.sharesOf(address(170))==2 && t.sharesOf(address(180))==0 && t.sharesOf(address(190))==2 && t.sharesOf(address(500))==6,"BALANCES");
        require(t.getPacked()==(uint256(4)<<128)+20,"PACKED");
        Vm.Log[] memory logs=vm.getRecordedLogs();require(logs.length==8,"LOG_COUNT");
        uint256[4] memory pooled=[uint256(62),12,12,37];uint256[4] memory amounts=[uint256(10),2,2,6];
        address[4] memory recipients=[address(d),address(170),address(190),address(500)];
        for(uint256 i;i<4;++i) {
            require(logs[2*i].topics[0]==keccak256("Transfer(address,address,uint256)") && logs[2*i+1].topics[0]==keccak256("TransferShares(address,address,uint256)"),"EVENT_ORDER");
            require(abi.decode(logs[2*i].data,(uint256))==pooled[i] && abi.decode(logs[2*i+1].data,(uint256))==amounts[i],"EVENT_VALUES");
            require(address(uint160(uint256(logs[2*i].topics[2])))==recipients[i],"EVENT_RECIPIENT");
        }
    }
    function testSelfAndDuplicateRecipients() public {
        (address[] memory rs,uint256[] memory ps)=arrays();rs[0]=address(d);rs[2]=address(d);
        loc.setup(t,address(d),address(d),false,false);d.mintAndDistribute(10,rs,ps,6);
        require(t.sharesOf(address(d))==15,"ALIAS_FRESH_READ");
    }
    function testLateOverflowRollsBackMintAndPriorTransfer() public {
        (address[] memory rs,uint256[] memory ps)=arrays();t.setShares(address(190),type(uint256).max);
        (bool ok,)=address(d).call(abi.encodeWithSelector(d.mintAndDistribute.selector,10,rs,ps,6));require(!ok,"REJECT");
        require(t.sharesOf(address(d))==5 && t.sharesOf(address(170))==0 && t.sharesOf(address(190))==type(uint256).max,"ROLLBACK");
        require(t.getPacked()==(uint256(4)<<128)+10,"MINT_ROLLBACK");
    }
    function testZeroTreasurySkipsResolver() public {
        (address[] memory rs,uint256[] memory ps)=arrays();ps[2]=3;loc.setup(t,address(d),address(500),true,false);
        d.distribute(rs,ps,0);require(t.sharesOf(address(d))==0,"ZERO_TREASURY");
    }
    function testZeroMintSkipsDistribution() public {
        (address[] memory rs,uint256[] memory ps)=arrays();loc.setup(t,address(d),address(500),true,false);
        d.mintAndDistribute(0,rs,ps,6);require(t.sharesOf(address(d))==5,"ZERO_MINT");
    }
    function testFromZeroPrecedesPaused() public {
        t.setStopped();vm.prank(address(0));(bool ok,bytes memory reason)=address(t).call(abi.encodeWithSelector(t.transferShares.selector,address(0),1));
        require(!ok && keccak256(reason)==keccak256(abi.encodeWithSignature("Error(string)","TRANSFER_FROM_ZERO_ADDR")),"GUARD_ORDER");
    }
    function testConversionRevertRestoresDebit() public {
        uint256 amount=type(uint128).max;t.setShares(address(this),amount);
        (bool ok,bytes memory reason)=address(t).call(abi.encodeWithSelector(t.transferShares.selector,address(170),amount));
        require(!ok && keccak256(reason)==keccak256(abi.encodeWithSignature("Error(string)","SHARES_TOO_LARGE")),"RATE_GUARD");
        require(t.sharesOf(address(this))==amount && t.sharesOf(address(170))==0,"DEBIT_ROLLBACK");
    }
    function testRawMultiplicationWraps() public {
        uint256 amount=uint256(1)<<127;uint256 numerator=2*(uint256(type(uint128).max));
        t.setShares(address(this),amount);t.setRate(numerator);
        uint256 expected;unchecked {expected=amount*numerator/6;}
        uint256 pooled=t.transferShares(address(170),amount);
        require(pooled==expected && t.sharesOf(address(this))==0 && t.sharesOf(address(170))==amount,"RAW_WRAP");
    }
}
