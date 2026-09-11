pragma solidity 0.8.9;
import "../src/RequestHarness.sol";
interface Vm { struct Log { bytes32[] topics; bytes data; address emitter; } function store(address,bytes32,bytes32) external; function load(address,bytes32) external view returns(bytes32); function recordLogs() external; function getRecordedLogs() external returns(Log[] memory); }
contract TokenDouble {
    RequestHarness public queue; uint256 public calls; uint256 public quote=10;
    uint256 public boolWord; uint256 public size=32; bool public mutate; bool public writeQuote;
    function configure(RequestHarness q,uint256 b,uint256 n,uint256 sh,bool m,bool w) external { queue=q;boolWord=b;size=n;quote=sh;mutate=m;writeQuote=w; }
    fallback() external {
        if(msg.sig==bytes4(0x23b872dd)) {
            calls++;
            if(mutate) queue.seed(7,30,40,999);
            uint256 b=boolWord;uint256 n=size;
            assembly { mstore(0,b) return(0,n) }
        }
        require(msg.sig==bytes4(0x19208451));
        if(writeQuote) calls++;
        uint256 sh=quote;assembly { mstore(0,sh) return(0,32) }
    }
}
contract WrapperDouble { address public stETH; constructor(address t) {stETH=t;} }
contract RequestTest {
    Vm constant vm=Vm(address(uint160(uint256(keccak256("hevm cheat code")))));
    function setup() internal returns(RequestHarness q,TokenDouble t) {
        t=new TokenDouble();q=new RequestHarness(IWstETH(address(new WrapperDouble(address(t)))));
        q.seed(0,0,0,9);t.configure(q,0,32,10,false,false);
    }
    function ownerBase(address o) internal pure returns(bytes32) { return keccak256(abi.encode(o,keccak256("lido.WithdrawalQueue.requestsByOwner"))); }
    function indexSlot(address o,uint256 id) internal pure returns(bytes32) { return keccak256(abi.encode(id,uint256(ownerBase(o))+1)); }
    function metaSlot(uint256 id) internal pure returns(bytes32) { return bytes32(uint256(keccak256(abi.encode(id,keccak256("lido.WithdrawalQueue.queue"))))+1); }
    function failure(RequestHarness q,TokenDouble t,uint256 amount) internal {
        (bool ok,)=address(q).call(abi.encodeWithSelector(q.one.selector,amount,address(this)));
        require(!ok && t.calls()==0 && q.getLastRequestId()==0);
    }
    function testFalseBoolAndOrderedEvents() public {
        (RequestHarness q,TokenDouble t)=setup();vm.recordLogs();require(q.one(100,address(0))==1);
        Vm.Log[] memory logs=vm.getRecordedLogs();require(logs.length==2);
        require(logs[0].topics[0]==keccak256("WithdrawalRequested(uint256,address,address,uint256,uint256)"));
        require(logs[1].topics[0]==keccak256("Transfer(address,address,uint256)"));
        require(logs[0].topics[1]==bytes32(uint256(1)) && logs[1].topics[3]==bytes32(uint256(1)));
        require(t.calls()==1 && q.metadata(1).owner==address(this));
    }
    function testNoncanonicalBoolRollback() public { (RequestHarness q,TokenDouble t)=setup();t.configure(q,2,32,10,false,false);failure(q,t,100); }
    function testShortBoolRollback() public { (RequestHarness q,TokenDouble t)=setup();t.configure(q,0,31,10,false,false);failure(q,t,100); }
    function testStaticGetterRejectsWriteRollback() public { (RequestHarness q,TokenDouble t)=setup();t.configure(q,0,32,10,false,true);failure(q,t,100); }
    function testPostTransferWorldAndTruncatedShares() public {
        (RequestHarness q,TokenDouble t)=setup();t.configure(q,0,32,(uint256(1)<<128)+7,true,false);
        require(q.one(100,address(0))==8); WithdrawalQueueBase.WithdrawalRequest memory r=q.metadata(8);
        require(r.cumulativeStETH==130 && r.cumulativeShares==47 && r.reportTimestamp==999);
    }
    function testOccupiedHighBytePreserved() public {
        (RequestHarness q,)=setup();vm.store(address(q),metaSlot(1),bytes32(uint256(0xab)<<248));
        q.one(100,address(0));require(uint256(vm.load(address(q),metaSlot(1)))>>248==0xab);
        require(!q.metadata(1).claimed);
    }
    function testMaximumSetLengthWrapsLegacy() public {
        (RequestHarness q,)=setup();vm.store(address(q),ownerBase(address(this)),bytes32(type(uint256).max));
        require(q.one(100,address(this))==1);
        require(vm.load(address(q),ownerBase(address(this)))==bytes32(0));
        require(vm.load(address(q),indexSlot(address(this),1))==bytes32(0));
    }
    function testDuplicateOwnerSetLateRollback() public {
        (RequestHarness q,TokenDouble t)=setup();vm.store(address(q),indexSlot(address(this),1),bytes32(uint256(3)));failure(q,t,100);
    }
    function testAmountGuards() public { (RequestHarness q,TokenDouble t)=setup();failure(q,t,99);failure(q,t,1000e18+1); }
    function testCumulativeOverflowRollback() public {
        (RequestHarness q,TokenDouble t)=setup();q.seed(0,type(uint128).max,0,9);failure(q,t,100);
        q.seed(0,0,type(uint128).max,9);failure(q,t,100);
    }
    function testIdOverflowRollback() public {
        (RequestHarness q,TokenDouble t)=setup();q.seed(type(uint256).max,0,0,9);
        (bool ok,)=address(q).call(abi.encodeWithSelector(q.one.selector,100,address(this)));
        require(!ok&&t.calls()==0&&q.getLastRequestId()==type(uint256).max);
    }
    function testFuzzOwnerAmountAndShares(uint160 owner,uint128 sh,uint96 amount) public {
        (RequestHarness q,TokenDouble t)=setup();uint256 a=100+uint256(amount)%(1000e18-99);t.configure(q,1,32,sh,false,false);
        require(q.one(a,address(owner))==1);WithdrawalQueueBase.WithdrawalRequest memory r=q.metadata(1);
        require(r.owner==(owner==0?address(this):address(owner))&&r.cumulativeStETH==a&&r.cumulativeShares==sh);
    }
}
